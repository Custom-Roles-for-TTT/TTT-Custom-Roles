AddCSLuaFile()

local hook = hook
local net = net
local player = player
local surface = surface
local string = string
local util = util

local AddHook = hook.Add
local CallHook = hook.Call
local RunHook = hook.Run
local PlayerIterator = player.Iterator
local SetMDL = FindMetaTable("Entity").SetModel

if CLIENT then
    SWEP.PrintName = "Bodysnatching Device"
    SWEP.Slot = 8

    SWEP.EquipMenuData = {
        type = "item_weapon",
        desc = "Changes your role to that of a corpses."
    }
end

SWEP.Base = "weapon_cr_defibbase"
SWEP.Category = WEAPON_CATEGORY_ROLE
SWEP.InLoadoutFor = {ROLE_BODYSNATCHER}
SWEP.Kind = WEAPON_ROLE

SWEP.FindRespawnLocation = false

if SERVER then
    SWEP.DeviceTimeConVar = CreateConVar("ttt_bodysnatcher_device_time", "5", FCVAR_NONE, "The amount of time (in seconds) the bodysnatcher's device takes to use", 0, 60)
end

if SERVER then
    util.AddNetworkString("TTT_Bodysnatched")
    util.AddNetworkString("TTT_ScoreBodysnatch")
    util.AddNetworkString("TTT_BodysnatchUpdateCorpseRole")
    util.AddNetworkString("TTT_BodysnatcherUnforceDuck")
    util.AddNetworkString("TTT_BodysnatcherForceDuck")

    local playerInfos = {}
    local function SavePlayerInfo(ply)
        local sid64 = ply:SteamID64()
        -- If we already have model information stored for this player, don't overwrite it
        if playerInfos[sid64] then return end

        playerInfos[sid64] = {
            model = ply:GetModel(),
            skin = ply:GetSkin(),
            bodygroups = {},
            color = ply:GetColor(),
            nick = ply:Nick()
        }

        for _, value in pairs(ply:GetBodyGroups()) do
            playerInfos[sid64].bodygroups[value.id] = ply:GetBodygroup(value.id)
        end
    end

    local function ApplyPlayerModelToTarget(sourceSid64, ply)
        local playerInfo = playerInfos[sourceSid64]
        if not playerInfo then return end

        SetMDL(ply, playerInfo.model)
        ply:SetSkin(playerInfo.skin)
        ply:SetColor(playerInfo.color)
        for id, value in pairs(playerInfo.bodygroups) do
            ply:SetBodygroup(id, value)
        end

        timer.Simple(0.1, function()
            ply:SetupHands()
        end)
    end

    local function ApplyPlayerInfoToTarget(sourceSid64, ply)
        local playerInfo = playerInfos[sourceSid64]
        if not playerInfo then return end

        ApplyPlayerModelToTarget(sourceSid64, ply)

        ply:SetNWString("TTTBodysnatcherName", playerInfo.nick)
        ply.TTTBodysnatcherSource = sourceSid64
    end

    local function ClearPlayerInfoOverride(ply)
        local sid64 = ply:SteamID64()
        -- Make the player look like themselves again
        ApplyPlayerModelToTarget(sid64, ply)

        -- Clear the stored data
        ply:SetNWString("TTTBodysnatcherName", "")
        ply.TTTBodysnatcherSource = nil
        playerInfos[sid64] = nil
    end

    function SWEP:OnSuccess(ply, body)
        if not IsValid(body) then return end

        local owner = self:GetOwner()
        CallHook("TTTPlayerRoleChangedByItem", nil, owner, owner, self)

        net.Start("TTT_Bodysnatched")
        net.Send(ply)

        local role = body.was_role or ply:GetRole()
        net.Start("TTT_ScoreBodysnatch")
        net.WriteString(ply:Nick())
        net.WriteString(owner:Nick())
        net.WriteString(ROLE_STRINGS_EXT[role])
        net.WriteString(owner:SteamID64())
        net.Broadcast()

        ply:MoveRoleState(owner, true)
        owner:SetRole(role)
        owner:StripRoleWeapons()
        owner:SelectWeapon("weapon_zm_carry")
        owner:SetNWBool("WasBodysnatcher", true)
        RunHook("PlayerLoadout", owner)

        if GetConVar("ttt_bodysnatcher_destroy_body"):GetBool() then
            SafeRemoveEntity(body)
        else
            local swap_mode = GetConVar("ttt_bodysnatcher_swap_mode"):GetInt()
            if swap_mode > BODYSNATCHER_SWAP_MODE_NOTHING then
                ply:SetRole(ROLE_BODYSNATCHER)
                ply:SetNWString("TTTBodysnatcherSwappedWith", owner:Nick())
                body.was_role = ROLE_BODYSNATCHER
                SetRoleMaxHealth(ply)

                if swap_mode == BODYSNATCHER_SWAP_MODE_IDENTITY then
                    -- Respawn the new bodysnatcher
                    ply:SpawnForRound(true)
                    -- Give them their loadout weapons since SpawnForRound doesn't do that for players being resurrected
                    RunHook("PlayerLoadout", ply)

                    -- Store the former bodysnatcher's position and angles
                    local pos = owner:GetPos()
                    local angles = owner:EyeAngles()

                    -- Swap positions between players
                    owner:SetPos(FindRespawnLocation(body:GetPos()) or body:GetPos())
                    owner:SetEyeAngles(Angle(0, body:GetAngles().y, 0))
                    ply:SetPos(pos)
                    ply:SetEyeAngles(angles)
                    SafeRemoveEntity(body)

                    -- Include whether the player is crouching
                    if owner:Crouching() then
                        ply:SetProperty("TTTBodysnatcherForceDuck", true, ply)
                        net.Start("TTT_BodysnatcherForceDuck")
                        net.ReadBool(true)
                        net.Send(ply)
                        net.Start("TTT_BodysnatcherForceDuck")
                        net.ReadBool(false)
                        net.Send(owner)
                    end

                    -- Swap names and playermodels (skin, color, bodygroups, etc.) between ply and owner
                    SavePlayerInfo(ply)
                    SavePlayerInfo(owner)

                    local ownerSource = owner.TTTBodysnatcherSource or owner:SteamID64()
                    local plySource = ply.TTTBodysnatcherSource or ply:SteamID64()
                    ApplyPlayerInfoToTarget(ownerSource, ply)
                    ApplyPlayerInfoToTarget(plySource, owner)

                    -- Show message to each player explaining what just happened
                    ply:QueueMessage(MSG_PRINTBOTH, string.Capitalize(ROLE_STRINGS_EXT[ROLE_BODYSNATCHER]) .. " has swapped identities with you! You are now " .. ROLE_STRINGS_EXT[ROLE_BODYSNATCHER] .. " and you look like " .. ply:GetNWString("TTTBodysnatcherName", owner:Nick()) .. "!")
                    owner:QueueMessage(MSG_PRINTBOTH, "You have swapped identities with " .. ply:Nick() .. "! You are now " .. ROLE_STRINGS_EXT[owner:GetRole()] .. " and you look like " .. owner:GetNWString("TTTBodysnatcherName", ply:Nick()) .. "!")
                end

                net.Start("TTT_BodysnatchUpdateCorpseRole")
                net.WriteUInt(ply:EntIndex(), 16)
                net.WriteUInt(body:EntIndex(), 16)
                net.Broadcast()
            end
        end
        SetRoleMaxHealth(owner)

        SendFullStateUpdate()
    end

    function SWEP:GetProgressMessage(ply, body, bone)
        local message = "BODYSNATCHING " .. string.upper(ply:Nick())
        if GetConVar("ttt_bodysnatcher_show_role"):GetBool() then
            local role = body.was_role or ply:GetRole()
            message = message .. " [" .. string.upper(ROLE_STRINGS_RAW[role]) .. "]"
        end
        return message
    end

    function SWEP:GetAbortMessage()
        return "BODYSNATCH ABORTED"
    end

    local function ClearFullState()
        for _, ply in PlayerIterator() do
            ClearPlayerInfoOverride(ply)
            ply:ClearProperty("TTTBodysnatcherForceDuck", ply)
        end

        table.Empty(playerInfos)
    end

    AddHook("TTTEndRound", "Bodysnatcher_InfoOverride_TTTEndRound", ClearFullState)
    AddHook("TTTPrepareRound", "Bodysnatcher_InfoOverride_TTTPrepareRound", function()
        for _, ply in PlayerIterator() do
            -- We want this info to show up in the round summary so we can't clear it on round end
            ply:SetNWString("TTTBodysnatcherSwappedWith", "")
        end
        ClearFullState()
    end)

    -- If a client tells us they have stopped being forced to duck, clear the state for them
    net.Receive("TTT_BodysnatcherUnforceDuck", function(len, ply)
        if not IsPlayer(ply) then return end
        if not ply:Alive() or ply:IsSpec() then return end
        if not ply.TTTBodysnatcherForceDuck then return end

        ply:ClearProperty("TTTBodysnatcherForceDuck", ply)
    end)
end

if CLIENT then
    local revived = Sound("items/smallmedkit1.wav")
    net.Receive("TTT_Bodysnatched", function()
        surface.PlaySound(revived)
    end)

    net.Receive("TTT_BodysnatchUpdateCorpseRole", function()
        local plyIndex = net.ReadUInt(16)
        local bodyIndex = net.ReadUInt(16)

        local ply = Entity(plyIndex)
        if IsValid(ply) and ply.search_result and ply.search_result.role then
            ply.search_result.role = ROLE_BODYSNATCHER
        end

        local body = Entity(bodyIndex)
        if IsValid(body) and body.search_result and body.search_result.role then
            body.search_result.role = ROLE_BODYSNATCHER
        end

        -- Force the scoreboard to refresh so the updated role information is shown
        if sboard_panel then
            GAMEMODE:ScoreboardHide()
            sboard_panel:Remove()
            sboard_panel = nil
        end
    end)

    -- If the player has snatched another player's name, show that name to other, non-allied, players
    AddHook("TTTTargetIDPlayerName", "Bodysnatcher_TTTTargetIDPlayerName", function(ply, cli, text, clr)
        local disguiseName = ply:GetNWString("TTTBodysnatcherName", "")
        if not disguiseName or #disguiseName == 0 then return end

        -- Show the overwritten name alongside their real name for non-innocent allies
        if ply == cli or (not cli:IsInnocentTeam() and cli:IsSameTeam(ply)) then
            return LANG.GetParamTranslation("player_name_disguised", { name=ply:Nick(), disguise=disguiseName }), clr
        end

        return disguiseName, clr
    end)

    local client
    AddHook("TTTChatPlayerName", "Bodysnatcher_TTTChatPlayerName", function(ply, team_chat)
        local disguiseName = ply:GetNWString("TTTBodysnatcherName", "")
        if not disguiseName or #disguiseName == 0 then return end

        if not IsPlayer(client) then
            client = LocalPlayer()
        end

        -- Don't override the name for team chat
        if team_chat then return end

        -- Show the overwritten name alongside their real name for allies
        if ply == client or (not client:IsInnocentTeam() and client:IsSameTeam(ply)) then
            return LANG.GetParamTranslation("player_name_disguised", { name=ply:Nick(), disguise=disguiseName })
        end

        return disguiseName
    end)

    -- If the server tells us this player should be ducking, do it
    net.Receive("TTT_BodysnatcherForceDuck", function()
        local ply = LocalPlayer()
        if not IsPlayer(ply) then return end
        if not ply:Alive() or ply:IsSpec() then return end

        local state = net.ReadBool()
        ply:ConCommand((state and "+" or "-") .. "duck")
    end)

    -- Detect the crouching keybinds and tell the server to stop forcing this player to duck
    AddHook("PlayerButtonUp", "Bodysnatcher_DuckReset_PlayerButtonUp", function(ply, button)
        if not IsPlayer(ply) then return end
        if not ply:Alive() or ply:IsSpec() then return end
        if not ply.TTTBodysnatcherForceDuck then return end

        local key = input.LookupKeyBinding(button)
        if key == "+duck" then
            ply:ConCommand("-duck")

            net.Start("TTT_BodysnatcherUnforceDuck")
            net.SendToServer()
        end
    end)
end

-- Override the player's name in radio messages too
hook.Add("TTTRadioPlayerName", "Bodysnatcher_TTTRadioPlayerName", function(sender, target)
    if not IsPlayer(sender) or not IsPlayer(target) then return end

    local disguiseName = target:GetNWString("TTTBodysnatcherName", "")
    if not disguiseName or #disguiseName == 0 then return end

    return disguiseName
end)