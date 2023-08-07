AddCSLuaFile()

local hook = hook
local player = player
local timer = timer

local AddHook = hook.Add
local GetAllPlayers = player.GetAll

util.AddNetworkString("TTT_HiveMindChatDupe")

-------------
-- CONVARS --
-------------

local hivemind_vision_enable = GetConVar("ttt_hivemind_vision_enable")

----------------------
-- CHAT DUPLICATION --
----------------------

AddHook("PlayerSay", "HiveMind_PlayerSay", function(ply, text, team_only)
    if team_only then return end

    net.Start("TTT_HiveMindChatDupe")
    net.WriteEntity(ply)
    net.WriteString(text)
    net.Broadcast()
end)

-------------------------
-- ROLE CHANGE ON KILL --
-------------------------

-- Players killed by the hive mind join the hive mind
AddHook("PlayerDeath", "HiveMind_PlayerDeath", function(victim, infl, attacker)
    if not IsValid(victim) or victim:IsHiveMind() then return end
    if not IsValid(attacker) or not attacker:IsHiveMind() then return end

    timer.Create("HiveMindRespawn_" .. victim:SteamID64(), 0.25, 1, function()
        -- Double-check
        if not IsValid(victim) or victim:IsHiveMind() then return end
        if not IsValid(attacker) or not attacker:IsHiveMind() then return end

        local body = victim.server_ragdoll or victim:GetRagdollEntity()
        victim:SpawnForRound(true)
        victim:SetRole(ROLE_HIVEMIND)
        if IsValid(body) then
            victim:SetPos(FindRespawnLocation(body:GetPos()) or body:GetPos())
            victim:SetEyeAngles(Angle(0, body:GetAngles().y, 0))
            body:Remove()
        end
        -- TODO: Health
        -- TODO: Max health

        victim:QueueMessage(MSG_PRINTCENTER, "You have become part of " .. ROLE_STRINGS_EXT[ROLE_HIVEMIND] .. ".")

        SendFullStateUpdate()
    end)
end)

-------------
-- CLEANUP --
-------------

AddHook("TTTPrepareRound", "HiveMind_repareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        timer.Remove("HiveMindRespawn_" .. v:SteamID64())
    end
end)

-----------
-- KARMA --
-----------

-- Hive Mind only loses karma for hurting their own team
AddHook("TTTKarmaShouldGivePenalty", "HiveMind_TTTKarmaShouldGivePenalty", function(ply, reward, victim)
    if IsPlayer(victim) and victim:IsActiveHiveMind() and ply:IsActiveHiveMind() then
        return true
    end
end)

----------------
-- WIN CHECKS --
----------------

AddHook("TTTCheckForWin", "HiveMind_TTTCheckForWin", function()
    local hivemind_alive = false
    local other_alive = false
    for _, v in ipairs(GetAllPlayers()) do
        if v:IsActive() then
            if v:IsHiveMind() then
                hivemind_alive = true
            elseif not v:ShouldActLikeJester() then
                other_alive = true
            end
        end
    end

    if hivemind_alive and not other_alive then
        return WIN_HIVEMIND
    elseif hivemind_alive then
        return WIN_NONE
    end
end)

AddHook("TTTPrintResultMessage", "HiveMind_TTTPrintResultMessage", function(type)
    if type == WIN_HIVEMIND then
        LANG.Msg("win_hivemind", { role = ROLE_STRINGS[ROLE_HIVEMIND] })
        ServerLog("Result: " .. ROLE_STRINGS[ROLE_HIVEMIND] .. " wins.\n")
        return true
    end
end)

-----------------------
-- PLAYER VISIBILITY --
-----------------------

-- Add all hive mind members to the PVS if vision is enabled
AddHook("SetupPlayerVisibility", "HiveMind_SetupPlayerVisibility", function(ply)
    if not ply:ShouldBypassCulling() then return end
    if not ply:IsActiveHiveMind() then return end
    if not hivemind_vision_enable:GetBool() then return end

    for _, v in ipairs(GetAllPlayers()) do
        if ply:TestPVS(v) then continue end
        if not v:IsActiveHiveMind() then continue end

        local pos = v:GetPos()
        if ply:IsOnScreen(pos) then
            AddOriginToPVS(pos)
        end
    end
end)