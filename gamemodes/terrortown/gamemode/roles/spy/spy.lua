AddCSLuaFile()

local hook = hook
local IsValid = IsValid
local GetConVar = GetConVar
local ipairs = ipairs

local GetAllPlayers = player.GetAll
local SetMDL = FindMetaTable("Entity").SetModel

-------------
-- CONVARS --
-------------

local spy_steal_model_hands = CreateConVar("ttt_spy_steal_model_hands", "1")
local spy_steal_model_alert = CreateConVar("ttt_spy_steal_model_alert", "1")

local spy_steal_model = GetConVar("ttt_spy_steal_model")
local spy_steal_name = GetConVar("ttt_spy_steal_name")

------------------
-- ROLE WEAPONS --
------------------

-- Only allow the spy to pick up spy-specific weapons
hook.Add("PlayerCanPickupWeapon", "Spy_Weapons_PlayerCanPickupWeapon", function(ply, wep)
    if not IsValid(wep) or not IsValid(ply) then return end
    if ply:IsSpec() then return false end
    if wep:GetClass() == "weapon_spy_flaregun" then return ply:IsSpy() end
end)

----------------
-- ROLE STATE --
----------------

local playerModels = {}

-- The spy steals the identity of the victim on killing a player
hook.Add("PlayerDeath", "Spy_PlayerDeath", function(victim, inflictor, attacker)
    if not IsPlayer(attacker) or attacker == victim or GetRoundState() ~= ROUND_ACTIVE then return end

    if attacker:IsSpy() and not victim:IsZombifying() then
        local stealModel = spy_steal_model:GetBool()
        local stealHands = spy_steal_model_hands:GetBool()

        -- Stealing model
        if stealModel then
            local attackerSid64 = attacker:SteamID64()

            -- If the spy hasn't swapped models yet, we need to store their original model
            if not playerModels[attackerSid64] then
                playerModels[attackerSid64] = {
                    model = attacker:GetModel(),
                    skin = attacker:GetSkin(),
                    bodygroups = {},
                    color = attacker:GetColor()
                }

                for _, value in pairs(attacker:GetBodyGroups()) do
                    playerModels[attackerSid64].bodygroups[value.id] = attacker:GetBodygroup(value.id)
                end
            end

            SetMDL(attacker, victim:GetModel())
            attacker:SetSkin(victim:GetSkin())
            attacker:SetColor(victim:GetColor())
            for _, value in pairs(victim:GetBodyGroups()) do
                attacker:SetBodygroup(value.id, victim:GetBodygroup(value.id))
            end

            -- Stealing 1st-person hands (There is no point in doing this if stealing model is not enabled)
            if stealHands then
                timer.Simple(0.1, function()
                    if IsValid(attacker) then
                        attacker:SetupHands()
                    end
                end)
            end
        end

        -- Stealing Name
        local stealName = spy_steal_name:GetBool()

        if stealName then
            attacker:SetNWString("TTTSpyDisguiseName", victim:GetName())
        end

        -- Displaying alert message on who the spy is now disguised as
        if spy_steal_model_alert:GetBool() and (stealModel or stealName) then
            attacker:QueueMessage(MSG_PRINTBOTH, "Disguised as " .. victim:Nick())
        end
    end
end)

local function ClearFullState()
    for _, ply in ipairs(GetAllPlayers()) do
        local sid64 = ply:SteamID64()
        local playerModel = playerModels[sid64]
        if playerModel then
            SetMDL(ply, playerModel.model)
            ply:SetSkin(playerModel.skin)
            ply:SetColor(playerModel.color)
            for id, value in pairs(playerModel.bodygroups) do
                ply:SetBodygroup(id, value)
            end

            timer.Simple(0.1, function()
                ply:SetupHands()
            end)
        end

        ply:SetNWString("TTTSpyDisguiseName", nil)
    end

    table.Empty(playerModels)
end

hook.Add("TTTEndRound", "Spy_TTTEndRound", ClearFullState)
hook.Add("TTTPrepareRound", "Spy_TTTPrepareRound", ClearFullState)