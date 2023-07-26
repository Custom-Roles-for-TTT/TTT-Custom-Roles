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

    if attacker:IsSpy() and not victim:GetNWBool("IsZombifying", false) then
        local stealModel = spy_steal_model:GetBool()
        local stealHands = spy_steal_model_hands:GetBool()

        -- Stealing model
        if stealModel then
            local attackerID = attacker:SteamID64()

            -- If the spy hasn't swapped models yet, we need to store their original model
            if not playerModels[attackerID] then
                playerModels[attackerID] = attacker:GetModel()
            end

            SetMDL(attacker, victim:GetModel())

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
            attacker:PrintMessage(HUD_PRINTCENTER, "Disguised as " .. victim:Nick())
            attacker:PrintMessage(HUD_PRINTTALK, "Disguised as " .. victim:Nick())
        end
    end
end)

-- Reset every spy's disguise at the end of the round
hook.Add("TTTEndRound", "Spy_TTTEndRound", function()
    for _, ply in ipairs(GetAllPlayers()) do
        if ply:IsSpy() then
            local plyID = ply:SteamID64()

            if playerModels[plyID] then
                SetMDL(ply, playerModels[plyID])
            end

            timer.Simple(0.1, function()
                ply:SetupHands()
            end)
        end

        ply:SetNWString("TTTSpyDisguiseName", nil)
    end

    table.Empty(playerModels)
end)