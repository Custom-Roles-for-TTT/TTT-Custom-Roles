AddCSLuaFile()

local hook = hook
local IsValid = IsValid
local math = math
local net = net
local pairs = pairs
local player = player
local table = table
local timer = timer
local util = util

local GetAllPlayers = player.GetAll

util.AddNetworkString("TTT_RevengerLoverKillerRadar")

-------------
-- CONVARS --
-------------

local revenger_radar_timer = CreateConVar("ttt_revenger_radar_timer", "15", FCVAR_NONE, "How often (in seconds) the radar ping for the lover's killer should update", 1, 60)
local revenger_damage_bonus = CreateConVar("ttt_revenger_damage_bonus", "0", FCVAR_NONE, "Extra damage that the revenger deals to their lover's killer (e.g. 0.5 = 50% extra damage)", 0, 1)
local revenger_drain_health_to = CreateConVar("ttt_revenger_drain_health_to", "-1", FCVAR_NONE, "The amount of health to drain the revenger down to after their lover has died. Setting to 0 will kill them. Set to -1 to disable", -1, 200)
local revenger_drain_health_rate = CreateConVar("ttt_revenger_drain_health_rate", "3", FCVAR_NONE, "How often, in seconds, health will be drained from a revenger whose lover has died", 1, 60)

hook.Add("TTTSyncGlobals", "Revenger_TTTSyncGlobals", function()
    SetGlobalInt("ttt_revenger_radar_timer", revenger_radar_timer:GetInt())
end)

-----------
-- KARMA --
-----------

-- If the attacker is a revenger, don't reduce thier karma if they killed the person who killed their target
hook.Add("TTTKarmaShouldGivePenalty", "Revenger_TTTKarmaShouldGivePenalty", function(attacker, victim)
    if attacker:IsRevenger() and victim:EnhancedSteamID64() == attacker:GetNWString("RevengerKiller", "") then
        return false
    end
end)

-------------------
-- ROLE FEATURES --
-------------------

-- Clear out the revenger data when the round starts
hook.Add("TTTPrepareRound", "Revenger_RoleFeatures_PrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        v:SetNWString("RevengerLover", "")
        v:SetNWString("RevengerKiller", "")
    end

    net.Start("TTT_RevengerLoverKillerRadar")
    net.WriteBool(false)
    net.Broadcast()
end)

hook.Add("TTTEndRound", "Revenger_RoundFeatures_TTTEndRound", function()
    if timer.Exists("revengerhealthdrain") then timer.Remove("revengerhealthdrain") end
end)

-- Handle revenger lover death
hook.Add("PlayerDeath", "Revenger_PlayerDeath", function(victim, infl, attacker)
    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    for _, v in pairs(GetAllPlayers()) do
        if v:IsRevenger() and v:GetNWString("RevengerLover", "") == victim:EnhancedSteamID64() then
            local message
            if v == attacker then
                message = "Your love has died by your hand."
            else
                if valid_kill then
                    if v:Alive() then
                        message = "Your love has died. Track down their killer."
                    end
                    v:SetNWString("RevengerKiller", attacker:EnhancedSteamID64())
                    timer.Simple(1, function() -- Slight delay needed for NW variables to be sent
                        net.Start("TTT_RevengerLoverKillerRadar")
                        net.WriteBool(true)
                        net.Send(v)
                    end)
                elseif v:Alive() then
                    message = "Your love has died, but you cannot determine the cause."
                end

                -- Use a specific message if the revenger is dead already
                if not v:Alive() then
                    message = "Your love has been killed and joins you in death."
                end
            end

            v:PrintMessage(HUD_PRINTTALK, message)
            v:PrintMessage(HUD_PRINTCENTER, message)
        end
    end
end)

ROLE_MOVE_ROLE_STATE[ROLE_REVENGER] = function(ply, target, keep_on_source)
    local killer = ply:GetNWString("RevengerKiller", "")
    if #killer > 0 then
        if not keep_on_source then ply:SetNWString("RevengerKiller", "") end
        target:SetNWString("RevengerKiller", killer)
    end

    local lover = ply:GetNWString("RevengerLover", "")
    if #lover > 0 then
        if not keep_on_source then ply:SetNWString("RevengerLover", "") end
        target:SetNWString("RevengerLover", lover)

        local revenger_lover = player.GetByEnhancedSteamID64(lover)
        if IsValid(revenger_lover) then
            target:PrintMessage(HUD_PRINTTALK, "You are now in love with " .. revenger_lover:Nick() .. ".")
            target:PrintMessage(HUD_PRINTCENTER, "You are now in love with " .. revenger_lover:Nick() .. ".")

            if not revenger_lover:Alive() or revenger_lover:IsSpec() then
                local message
                if killer == target:EnhancedSteamID64() then
                    message = "Your love has died by your hand."
                elseif killer then
                    message = "Your love has died. Track down their killer."

                    timer.Simple(1, function() -- Slight delay needed for NW variables to be sent
                        net.Start("TTT_RevengerLoverKillerRadar")
                        net.WriteBool(true)
                        net.Send(target)
                    end)
                else
                    message = "Your love has died, but you cannot determine the cause."
                end

                timer.Simple(1, function()
                    target:PrintMessage(HUD_PRINTTALK, message)
                    target:PrintMessage(HUD_PRINTCENTER, message)
                end)
            end
        end
    end
end

ROLE_ON_ROLE_ASSIGNED[ROLE_REVENGER] = function(ply)
    local potentialSoulmates = {}
    for _, p in pairs(GetAllPlayers()) do
        if p:Alive() and not p:IsSpec() and p ~= ply then
            table.insert(potentialSoulmates, p)
        end
    end
    if #potentialSoulmates > 0 then
        local revenger_lover = potentialSoulmates[math.random(#potentialSoulmates)]
        ply:SetNWString("RevengerLover", revenger_lover:EnhancedSteamID64() or "")
        ply:PrintMessage(HUD_PRINTTALK, "You are in love with " .. revenger_lover:Nick() .. ".")
        ply:PrintMessage(HUD_PRINTCENTER, "You are in love with " .. revenger_lover:Nick() .. ".")
    end

    local drain_health = revenger_drain_health_to:GetInt()
    if drain_health >= 0 then
        local drain_health_rate = revenger_drain_health_rate:GetInt()
        timer.Create("revengerhealthdrain", drain_health_rate, 0, function()
            for _, p in pairs(GetAllPlayers()) do
                local lover_sid = p:GetNWString("RevengerLover", "")
                if p:IsActiveRevenger() and lover_sid ~= "" then
                    local lover = player.GetByEnhancedSteamID64(lover_sid)
                    if IsValid(lover) and (not lover:Alive() or lover:IsSpec()) then
                        local hp = p:Health()
                        if hp > drain_health then
                            -- We were going to set them to 0, so just kill them instead
                            if hp == 1 then
                                p:PrintMessage(HUD_PRINTTALK, "You have succumbed to the heartache of losing your lover.")
                                p:PrintMessage(HUD_PRINTCENTER, "You have succumbed to the heartache of losing your lover.")
                                p:Kill()
                            else
                                p:SetHealth(hp - 1)
                            end
                        end
                    end
                end
            end
        end)
    end
end

-- Assign a new lover if they disconnected
hook.Add("PlayerDisconnected", "Revenger_Lover_PlayerDisconnected", function(ply)
    local sid64 = ply:EnhancedSteamID64()
    local potentialSoulmates = {}
    local revenger = nil
    for _, p in pairs(GetAllPlayers()) do
        if p:IsRevenger() then
            if p:GetNWString("RevengerLover", "") == sid64 then
                revenger = p
            end
        elseif p:Alive() and not p:IsSpec() and p ~= ply then
            table.insert(potentialSoulmates, p)
        end
    end

    if not revenger then return end

    local message = "Your lover has disappeared ;_;"
    if #potentialSoulmates > 0 then
        local revenger_lover = potentialSoulmates[math.random(#potentialSoulmates)]
        revenger:SetNWString("RevengerLover", revenger_lover:EnhancedSteamID64() or "")
        message = message .. " You are now in love with " .. revenger_lover:Nick() .. " instead."
    else
        revenger:SetNWString("RevengerLover", "")
    end

    revenger:PrintMessage(HUD_PRINTTALK, message)
    revenger:PrintMessage(HUD_PRINTCENTER, message)
end)

------------------
-- SCALE DAMAGE --
------------------

hook.Add("ScalePlayerDamage", "Revenger_ScalePlayerDamage", function(ply, hitgroup, dmginfo)
    local att = dmginfo:GetAttacker()
    if IsPlayer(att) and GetRoundState() >= ROUND_ACTIVE then
        -- Revengers deal extra damage to their lovers killer
        if att:IsRevenger() and ply:EnhancedSteamID64() == att:GetNWString("RevengerKiller", "") then
            local bonus = revenger_damage_bonus:GetFloat()
            dmginfo:ScaleDamage(1 + bonus)
        end
    end
end)