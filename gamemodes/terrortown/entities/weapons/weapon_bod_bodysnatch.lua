AddCSLuaFile()

local hook = hook
local net = net
local surface = surface
local string = string
local util = util

local CallHook = hook.Call
local RunHook = hook.Run

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

    function SWEP:OnSuccess(ply, body)
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
        elseif GetConVar("ttt_bodysnatcher_swap_role"):GetBool() then
            ply:SetRole(ROLE_BODYSNATCHER)
            body.was_role = ROLE_BODYSNATCHER

            net.Start("TTT_BodysnatchUpdateCorpseRole")
            net.WriteUInt(ply:EntIndex(), 16)
            net.WriteUInt(body:EntIndex(), 16)
            net.Broadcast()
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
end