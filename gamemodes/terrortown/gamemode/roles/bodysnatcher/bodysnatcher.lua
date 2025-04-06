AddCSLuaFile()

local hook = hook
local IsValid = IsValid
local net = net
local player = player
local timer = timer
local util = util

local PlayerIterator = player.Iterator

util.AddNetworkString("TTT_BodysnatcherKilled")

-------------
-- CONVARS --
-------------

CreateConVar("ttt_bodysnatcher_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that a bodysnatcher was killed. Killer is notified unless \"ttt_bodysnatcher_notify_killer\" is disabled", 0, 4)
CreateConVar("ttt_bodysnatcher_notify_killer", "1", FCVAR_NONE, "Whether to notify a bodysnatcher's killer", 0, 1)
CreateConVar("ttt_bodysnatcher_notify_sound", "0", FCVAR_NONE, "Whether to play a cheering sound when a bodysnatcher is killed", 0, 1)
CreateConVar("ttt_bodysnatcher_notify_confetti", "0", FCVAR_NONE, "Whether to throw confetti when a bodysnatcher is a killed", 0, 1)

local bodysnatcher_respawn = GetConVar("ttt_bodysnatcher_respawn")
local bodysnatcher_respawn_delay = GetConVar("ttt_bodysnatcher_respawn_delay")
local bodysnatcher_respawn_limit = GetConVar("ttt_bodysnatcher_respawn_limit")

----------------
-- ROLE STATE --
----------------

-- Disable tracking that this player was a bodysnatcher at the start of a new round or if their role changes again (e.g. if they go bodysnatcher -> innocent -> dead -> hypnotist res to traitor)
hook.Add("TTTPrepareRound", "Bodysnatcher_PrepareRound", function()
    for _, v in PlayerIterator() do
        v:SetNWBool("WasBodysnatcher", false)
        v:SetNWBool("BodysnatcherIsRespawning", false)
        timer.Remove(v:Nick() .. "BodysnatcherRespawn")
    end
end)

hook.Add("TTTPlayerRoleChanged", "Bodysnatcher_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if oldRole ~= ROLE_BODYSNATCHER then
        ply:SetNWBool("WasBodysnatcher", false)

        -- Keep track of how many times they have respawned
        if newRole == ROLE_BODYSNATCHER then
            ply.BodysnatcherRespawn = 0
        end
    end
end)

------------------
-- ROLE WEAPONS --
------------------

-- Only allow the bodysnatcher to pick up bodysnatcher-specific weapons
hook.Add("PlayerCanPickupWeapon", "Bodysnatcher_Weapons_PlayerCanPickupWeapon", function(ply, wep)
    if not IsValid(wep) or not IsValid(ply) then return end
    if ply:IsSpec() then return end

    if wep:GetClass() == "weapon_bod_bodysnatch" then
        return ply:IsBodysnatcher()
    end
end)

-----------------
-- KILL CHECKS --
-----------------

local function BodysnatcherKilledNotification(attacker, victim)
    JesterTeamKilledNotification(attacker, victim,
        -- getkillstring
        function()
            return attacker:Nick() .. " killed the " .. ROLE_STRINGS[ROLE_BODYSNATCHER] .. " before they could snatch a role!"
        end)
end

hook.Add("PlayerDeath", "Bodysnatcher_KillCheck_PlayerDeath", function(victim, infl, attacker)
    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    if not valid_kill then return end
    if not victim:IsBodysnatcher() then return end

    BodysnatcherKilledNotification(attacker, victim)

    local respawnLimit = bodysnatcher_respawn_limit:GetInt()
    if bodysnatcher_respawn:GetBool() and (respawnLimit == 0 or victim.BodysnatcherRespawn < respawnLimit) then
        victim.BodysnatcherRespawn = victim.BodysnatcherRespawn + 1
        local delay = bodysnatcher_respawn_delay:GetInt()
        if delay > 0 then
            victim:QueueMessage(MSG_PRINTCENTER, "You were killed but will respawn in " .. delay .. " seconds.")
        else
            victim:QueueMessage(MSG_PRINTCENTER, "You were killed but are about to respawn.")
            -- Introduce a slight delay to prevent player getting stuck as a spectator
            delay = 0.1
        end
        victim:SetNWBool("BodysnatcherIsRespawning", true)

        timer.Create(victim:Nick() .. "BodysnatcherRespawn", delay, 1, function()
            local body = victim.server_ragdoll or victim:GetRagdollEntity()
            victim:SpawnForRound(true)
            victim:SetHealth(victim:GetMaxHealth())
            SafeRemoveEntity(body)
            victim:SetNWBool("BodysnatcherIsRespawning", false)
        end)

        net.Start("TTT_BodysnatcherKilled")
        net.WriteString(victim:Nick())
        net.WriteString(attacker:Nick())
        net.WriteUInt(delay, 8)
        net.Broadcast()
    end
end)

hook.Add("TTTStopPlayerRespawning", "Bodysnatcher_TTTStopPlayerRespawning", function(ply)
    if not IsPlayer(ply) then return end
    if ply:Alive() then return end

    if ply:GetNWBool("BodysnatcherIsRespawning", false) then
        timer.Remove(ply:Nick() .. "BodysnatcherRespawn")
        ply:SetNWBool("BodysnatcherIsRespawning", false)
    end
end)

------------------
-- CUPID LOVERS --
------------------

hook.Add("TTTCupidShouldLoverSurvive", "Bodysnatcher_TTTCupidShouldLoverSurvive", function(ply, lover)
    if ply:GetNWBool("BodysnatcherIsRespawning", false) or lover:GetNWBool("BodysnatcherIsRespawning", false) then
        return true
    end
end)