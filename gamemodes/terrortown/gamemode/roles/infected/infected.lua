AddCSLuaFile()

local hook = hook
local ipairs = ipairs
local math = math
local net = net
local pairs = pairs
local player = player
local string = string
local table = table
local timer = timer
local util = util

local GetAllPlayers = player.GetAll
local MathRandom = math.random
local StringFormat = string.format

util.AddNetworkString("TTT_InfectedSuccumbed")

-------------
-- CONVARS --
-------------

local infected_cough_enabled = GetConVar("ttt_infected_cough_enabled")
local infected_respawn_enable = GetConVar("ttt_infected_respawn_enable")
local infected_succumb_time = GetConVar("ttt_infected_succumb_time")
local infected_full_health = GetConVar("ttt_infected_full_health")

local infected_prime = CreateConVar("ttt_infected_prime", "1", FCVAR_NONE, "Whether the infected will become a prime zombie", 0, 1)
local infected_cough_timer_min = CreateConVar("ttt_infected_cough_timer_min", "30", FCVAR_NONE, "The minimum time between infected coughs", 0, 180)
local infected_cough_timer_max = CreateConVar("ttt_infected_cough_timer_max", "60", FCVAR_NONE, "The maximum time between infected coughs", 0, 300)

-----------
-- COUGH --
-----------

local coughCount = 7
local coughs = {}
for i=1, coughCount do
    local coughName = StringFormat("infected/cough%i.wav", i)
    table.insert(coughs, Sound(coughName))
    resource.AddSingleFile("sound/" .. coughName)
end

local function StartCoughTimer()
    -- Cough sometimes so people can tell that this player is infected
    if infected_cough_enabled:GetBool() then
        local min = infected_cough_timer_min:GetInt()
        local max = infected_cough_timer_max:GetInt()
        if max < min then
            max = min
        end
        timer.Create("InfectedCough", MathRandom(min, max), 0, function()
            for _, v in ipairs(GetAllPlayers()) do
                if v:IsActiveInfected() then
                    local idx = MathRandom(1, coughCount)
                    local chosen_sound = coughs[idx]
                    sound.Play(chosen_sound, v:GetPos())
                end
            end
            timer.Adjust("InfectedCough", MathRandom(min, max), 0, nil)
        end)
    end
end

-------------
-- SUCCUMB --
-------------

hook.Add("Initialize", "Infected_RoleChange_Initialize", function()
    SetGlobalFloat("ttt_infected_succumb", -1)
end)

local function InfectedSuccumb(ply, respawn)
    local message = "You have succumbed to your disease and "
    if respawn then
        message = message .. " respawned as "
    else
        message = message .. " become "
    end
    ply:QueueMessage(MSG_PRINTCENTER, message .. ROLE_STRINGS_EXT[ROLE_ZOMBIE])

    net.Start("TTT_InfectedSuccumbed")
    net.WriteString(ply:Nick())
    net.Broadcast()

    local body = ply.server_ragdoll or ply:GetRagdollEntity()
    if respawn then
        ply:SpawnForRound(true)
    end
    ply:SetRole(ROLE_ZOMBIE)
    local prime = infected_prime:GetBool()
    ply:SetZombiePrime(prime)

    SetRoleMaxHealth(ply)
    if infected_full_health:GetBool() then
        SetRoleStartingHealth(ply)
    -- Don't allow infected to have boosted health if zombies have lower max health than they do
    elseif ply:Health() > ply:GetMaxHealth() then
        ply:SetHealth(ply:GetMaxHealth())
    end

    -- Don't strip weapons if this player is allowed to keep them
    if not prime or not GetConVar("ttt_zombie_prime_only_weapons"):GetBool() then
        ply:StripAll()
    end
    ply:Give("weapon_zom_claws")
    if respawn and IsValid(body) then
        ply:SetPos(FindRespawnLocation(body:GetPos()) or body:GetPos())
        ply:SetEyeAngles(Angle(0, body:GetAngles().y, 0))
        body:Remove()
    end
    SendFullStateUpdate()
end

local function StartSuccumbTimer()
    SetGlobalFloat("ttt_infected_succumb", CurTime() + infected_succumb_time:GetInt())
    timer.Create("InfectedSuccumb", infected_succumb_time:GetInt(), 1, function()
        for _, p in pairs(GetAllPlayers()) do
            if p:IsActiveInfected() then
                InfectedSuccumb(p, false)
            elseif p:IsInfected() and not p:Alive() and not timer.Exists("WaitForInfectedRespawn") then
                timer.Create("WaitForInfectedRespawn", 0.1, 0, function()
                    local dead_infected = false
                    for _, p2 in pairs(GetAllPlayers()) do
                        if p2:IsActiveInfected() then
                            InfectedSuccumb(p2, false)
                        elseif p2:IsInfected() and not p2:Alive() then
                            dead_infected = true
                        end
                    end
                    if timer.Exists("WaitForInfectedRespawn") and not dead_infected then timer.Remove("WaitForInfectedRespawn") end
                end)
            end
        end
    end)
end

hook.Add("PlayerDeath", "Infected_KillCheck_PlayerDeath", function(victim, infl, attacker)
    if not infected_respawn_enable:GetBool() then return end
    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    if not valid_kill then return end
    if not victim:IsInfected() then return end
    victim:SetNWBool("InfectedIsZombifying", true)
    timer.Simple(0.25, function()
        InfectedSuccumb(victim, true)
        victim:SetNWBool("InfectedIsZombifying", false)
    end)
end)

-----------------------
-- ROLE CHANGE LOGIC --
-----------------------

ROLE_ON_ROLE_ASSIGNED[ROLE_INFECTED] = function()
    StartSuccumbTimer()
    StartCoughTimer()
end

------------------
-- CUPID LOVERS --
------------------

hook.Add("TTTCupidShouldLoverSurvive", "Infected_TTTCupidShouldLoverSurvive", function(ply, lover)
    if ply:GetNWBool("InfectedIsZombifying", false) or lover:GetNWBool("InfectedIsZombifying", false) then
        return true
    end
end)

-------------
-- CLEANUP --
-------------

hook.Add("TTTEndRound", "Infected_TTTEndRound", function()
    if timer.Exists("InfectedSuccumb") then timer.Remove("InfectedSuccumb") end
    if timer.Exists("WaitForInfectedRespawn") then timer.Remove("WaitForInfectedRespawn") end
    if timer.Exists("InfectedCough") then timer.Remove("InfectedCough") end
end)

hook.Add("TTTPrepareRound", "Infected_PrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        v:SetNWBool("InfectedIsZombifying", false)
    end
end)