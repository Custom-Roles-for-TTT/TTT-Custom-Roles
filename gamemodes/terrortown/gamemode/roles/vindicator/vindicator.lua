AddCSLuaFile()

local hook = hook
local timer = timer
local player = player
local math = math

local GetAllPlayers = player.GetAll

util.AddNetworkString("TTT_VindicatorTeamChange")

-------------
-- CONVARS --
-------------

local vindicator_respawn_delay = CreateConVar("ttt_vindicator_respawn_delay", "5", FCVAR_NONE, "Delay between the vindicator dying and respawning in seconds", 0, 30)
local vindicator_respawn_health = CreateConVar("ttt_vindicator_respawn_health", "100", FCVAR_NONE, "The amount of health a vindicator will respawn with", 1, 200)

local vindicator_announcement_mode = GetConVar("ttt_vindicator_announcement_mode")

-------------
-- RESPAWN --
-------------

local function ActivateVindicator(vindicator, target)
    if not vindicator:IsVindicator() then return end

    local body = vindicator.server_ragdoll or vindicator:GetRagdollEntity()
    if IsValid(body) then
        body:Remove()
    end
    vindicator:SpawnForRound(true)
    vindicator:SetHealth(vindicator_respawn_health:GetInt())
    SetVindicatorTeam(true)
    vindicator:SetNWString("VindicatorTarget", target:SteamID64())

    local spawns = GetSpawnEnts(true, false)
    local furthestSpawn = nil
    local furthestDistance = 0
    for _, spawn in ipairs(spawns) do
        local distance = spawn:GetPos():Distance(target:GetPos())
        if distance > furthestDistance then
            furthestSpawn = spawn
            furthestDistance = distance
        end
    end
    if IsValid(furthestSpawn) then
        local respawnPos = FindRespawnLocation(furthestSpawn:GetPos())
        if respawnPos then
            vindicator:SetPos(respawnPos)
        end
    end

    local mode = vindicator_announcement_mode:GetInt()
    if mode >= VINDICATOR_ANNOUNCE_TARGET then
        target:QueueMessage(MSG_PRINTBOTH, ROLE_STRINGS_EXT[ROLE_VINDICATOR] .. " (" .. vindicator:Nick() .. ") has respawned and is hunting you down!")
    end
    if mode == VINDICATOR_ANNOUNCE_ALL then
        for _, ply in pairs(GetAllPlayers()) do
            if ply ~= vindicator and ply ~= target then
                ply:PrintMessage(HUD_PRINTTALK, ROLE_STRINGS_EXT[ROLE_VINDICATOR] .. " (" .. vindicator:Nick() .. ") has respawned and is hunting down " .. target:Nick() .. "!")
            end
        end
    end
end

hook.Add("PlayerDeath", "Vindicator_PlayerDeath", function(victim, infl, attacker)
    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    if valid_kill and victim:IsVindicator() and not victim:IsRoleActive() then
        if victim:IsZombifying() or attacker:IsHiveMind() then return end

        local delay = vindicator_respawn_delay:GetInt()
        if delay == 0 then
            ActivateVindicator(victim, attacker)
        else
            victim:QueueMessage(MSG_PRINTBOTH, "You will be respawned in " .. delay .. " second(s)", math.min(delay, 5))
            timer.Create("VindicatorRespawn", delay, 1, function()
                ActivateVindicator(victim, attacker)
            end)
        end
    end
end)

-------------
-- CLEANUP --
-------------

hook.Add("TTTPrepareRound", "Vindicator_PrepareRound", function()
    SetVindicatorTeam(false)
    for _, ply in pairs(GetAllPlayers()) do
        ply:SetNWString("VindicatorTarget", "")
    end
end)