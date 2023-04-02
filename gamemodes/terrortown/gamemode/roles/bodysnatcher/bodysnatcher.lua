AddCSLuaFile()

local hook = hook
local IsValid = IsValid
local net = net
local pairs = pairs
local timer = timer
local util = util

local GetAllPlayers = player.GetAll

util.AddNetworkString("TTT_BodysnatcherKilled")

-------------
-- CONVARS --
-------------

CreateConVar("ttt_bodysnatcher_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that the bodysnatcher is killed", 0, 4)
CreateConVar("ttt_bodysnatcher_notify_sound", "0", FCVAR_NONE, "Whether to play a cheering sound when a bodysnatcher is killed", 0, 1)
CreateConVar("ttt_bodysnatcher_notify_confetti", "0", FCVAR_NONE, "Whether to throw confetti when a bodysnatcher is a killed", 0, 1)
CreateConVar("ttt_bodysnatcher_destroy_body", "0", FCVAR_NONE, "Whether the bodysnatching device destroys the body it is used on or not", 0, 1)
CreateConVar("ttt_bodysnatcher_show_role", "1", FCVAR_NONE, "Whether the bodysnatching device shows the role of the corpse it is used on or not", 0, 1)
local bodysnatchers_are_independent = CreateConVar("ttt_bodysnatchers_are_independent", "0", FCVAR_NONE, "Whether bodysnatchers should be treated as members of the independent team", 0, 1)
local bodysnatcher_reveal_traitor = CreateConVar("ttt_bodysnatcher_reveal_traitor", "1", FCVAR_NONE, "Who the bodysnatcher is revealed to when they join the traitor team", 0, 2)
local bodysnatcher_reveal_innocent = CreateConVar("ttt_bodysnatcher_reveal_innocent", "1", FCVAR_NONE, "Who the bodysnatcher is revealed to when they join the innocent team", 0, 2)
local bodysnatcher_reveal_monster = CreateConVar("ttt_bodysnatcher_reveal_monster", "1", FCVAR_NONE, "Who the bodysnatcher is revealed to when they join the monster team", 0, 2)
local bodysnatcher_reveal_independent = CreateConVar("ttt_bodysnatcher_reveal_independent", "1", FCVAR_NONE, "Who the bodysnatcher is revealed to when they join the independent team", 0, 2)
local bodysnatcher_respawn = CreateConVar("ttt_bodysnatcher_respawn", "0", FCVAR_NONE, "Whether the bodysnatcher respawns when they are killed before joining another team", 0, 1)
local bodysnatcher_respawn_limit = CreateConVar("ttt_bodysnatcher_respawn_limit", "0", FCVAR_NONE, "The maximum number of times the bodysnatcher can respawn (if \"ttt_bodysnatcher_respawn\" is enabled). Set to 0 to allow infinite respawns", 0, 30)
local bodysnatcher_respawn_delay = CreateConVar("ttt_bodysnatcher_respawn_delay", "3", FCVAR_NONE, "The delay to use when respawning the bodysnatcher (if \"ttt_bodysnatcher_respawn\" is enabled)", 0, 60)

hook.Add("TTTSyncGlobals", "Bodysnatcher_TTTSyncGlobals", function()
    SetGlobalBool("ttt_bodysnatchers_are_independent", bodysnatchers_are_independent:GetBool())
    SetGlobalInt("ttt_bodysnatcher_reveal_traitor", bodysnatcher_reveal_traitor:GetInt())
    SetGlobalInt("ttt_bodysnatcher_reveal_innocent", bodysnatcher_reveal_innocent:GetInt())
    SetGlobalInt("ttt_bodysnatcher_reveal_monster", bodysnatcher_reveal_monster:GetInt())
    SetGlobalInt("ttt_bodysnatcher_reveal_independent", bodysnatcher_reveal_independent:GetInt())
    SetGlobalBool("ttt_bodysnatcher_respawn", bodysnatcher_respawn:GetBool())
    SetGlobalInt("ttt_bodysnatcher_respawn_limit", bodysnatcher_respawn_limit:GetInt())
    SetGlobalInt("ttt_bodysnatcher_respawn_delay", bodysnatcher_respawn_delay:GetInt())
end)

----------------
-- ROLE STATE --
----------------

-- Disable tracking that this player was a bodysnatcher at the start of a new round or if their role changes again (e.g. if they go bodysnatcher -> innocent -> dead -> hypnotist res to traitor)
hook.Add("TTTPrepareRound", "Bodysnatcher_PrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
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
    if ply:IsSpec() then return false end

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
        local delay = bodysnatcher_respawn_limit:GetInt()
        if delay > 0 then
            victim:PrintMessage(HUD_PRINTCENTER, "You were killed but will respawn in " .. delay .. " seconds.")
        else
            victim:PrintMessage(HUD_PRINTCENTER, "You were killed but are about to respawn.")
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

------------------
-- CUPID LOVERS --
------------------

hook.Add("TTTCupidShouldLoverSurvive", "Bodysnatcher_TTTCupidShouldLoverSurvive", function(ply, lover)
    if ply:GetNWBool("BodysnatcherIsRespawning", false) or lover:GetNWBool("BodysnatcherIsRespawning", false) then
        return true
    end
end)