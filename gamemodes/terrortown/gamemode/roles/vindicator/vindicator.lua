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
local vindicator_target_suicide_success = GetConVar("ttt_vindicator_target_suicide_success")
local vindicator_kill_on_fail = GetConVar("ttt_vindicator_kill_on_fail")
local vindicator_kill_on_success = GetConVar("ttt_vindicator_kill_on_success")

-------------------
-- ROLE FEATURES --
-------------------

local function ActivateVindicator(vindicator, target)
    if not vindicator:IsVindicator() then return end

    if not target:Alive() then
        vindicator:QueueMessage(MSG_PRINTBOTH, "Your target has already died so you will not be respawned.")
        return
    end

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
    local valid_kill = IsPlayer(attacker) and GetRoundState() == ROUND_ACTIVE
    if valid_kill then
        if victim:IsVindicator() and not victim:IsRoleActive() and attacker ~= victim then
            if victim:IsZombifying() or attacker:IsHiveMind() then return end

            local delay = vindicator_respawn_delay:GetInt()
            if delay == 0 then
                ActivateVindicator(victim, attacker)
            else
                victim:QueueMessage(MSG_PRINTBOTH, "You will be respawned in " .. delay .. " second(s)", math.min(delay, 5))
                timer.Create("VindicatorRespawn" .. victim:SteamID64(), delay, 1, function()
                    ActivateVindicator(victim, attacker)
                end)
            end
        elseif attacker:IsVindicator() and victim:SteamID64() == attacker:GetNWString("VindicatorTarget", "") then
            attacker:GetNWBool("VindicatorSuccess", true)
            attacker:QueueMessage(MSG_PRINTBOTH, "You have successfully killed your target.")
        else
            for _, ply in pairs(GetAllPlayers()) do
                if ply:IsActiveVindicator() and victim:SteamID64() == ply:GetNWString("VindicatorTarget", "") then
                    if attacker == victim and vindicator_target_suicide_success:GetBool() then
                        attacker:GetNWBool("VindicatorSuccess", true)
                        attacker:QueueMessage(MSG_PRINTBOTH, "Your target finished the job for you and has killed themselves.")
                    else
                        attacker:QueueMessage(MSG_PRINTBOTH, "Your target was killed by someone else and you have failed.")
                    end
                end
            end
        end
    end
end)

----------------
-- DEATH LINK --
----------------

hook.Add("TTTBeginRound", "Vindicator_TTTBeginRound", function()
    timer.Create("TTTVindicatorTimer", 0.1, 0, function()
        for _, v in pairs(GetAllPlayers()) do
            if not v:IsActiveVindicator() then continue end

            local target_sid64 = v:GetNWString("VindicatorTarget", "")
            if target_sid64 == "" then continue end

            local target = player.GetBySteamID64(target_sid64)
            if not IsPlayer(target) or target:IsActive() then continue end

            local success = v:GetNWBool("VindicatorSuccess", false)
            if (success and not vindicator_kill_on_success:GetBool()) or (not success and not vindicator_kill_on_fail:GetBool()) then continue end

            v:Kill()
            if success then
                v:QueueMessage(MSG_PRINTBOTH, "You can now rest in peace having achieved your goal.")
            else
                v:QueueMessage(MSG_PRINTBOTH, "Having failed to take revenge, you must return to death.")
            end
        end
    end)
end)

----------------
-- WIN CHECKS --
----------------

local function HandleVindicatorWinBlock(win_type)
    if win_type == WIN_NONE then return win_type end

    if not INDEPENDENT_ROLES[ROLE_VINDICATOR] then return win_type end

    local vindicator = player.GetLivingRole(ROLE_VINDICATOR)
    if not IsPlayer(vindicator) then return win_type end

    local sid64 = vindicator:GetNWString("VindicatorTarget", "")
    local target = player.GetBySteamID64(sid64)
    if not IsPlayer(target) or not target:Alive() then return win_type end

    return WIN_NONE
end

hook.Add("TTTWinCheckBlocks", "Vindicator_TTTWinCheckBlocks", function(win_blocks)
    table.insert(win_blocks, HandleVindicatorWinBlock)
end)

hook.Add("TTTCheckForWin", "Vindicator_TTTCheckForWin", function()
    local vindicator_win = false
    local other_alive = false
    for _, ply in ipairs(GetAllPlayers()) do
        if ply:IsVindicator() then
            if ply:GetNWBool("VindicatorSuccess", false) then
                vindicator_win = true
            end
        elseif ply:IsActive() then
            other_alive = true
        end
    end

    if vindicator_win and not other_alive then
        return WIN_VINDICATOR
    end
end)

hook.Add("TTTPrintResultMessage", "Killer_TTTPrintResultMessage", function(type)
    if type == WIN_VINDICATOR then
        LANG.Msg("win_vindicator", { role = ROLE_STRINGS[ROLE_VINDICATOR] })
        ServerLog("Result: " .. ROLE_STRINGS[ROLE_VINDICATOR] .. " wins.\n")
        return true
    end
end)

-------------
-- CLEANUP --
-------------

hook.Add("TTTPrepareRound", "Vindicator_PrepareRound", function()
    SetVindicatorTeam(false)
    for _, ply in pairs(GetAllPlayers()) do
        ply:SetNWString("VindicatorTarget", "")
        ply:SetNWBool("VindicatorSuccess", false)
        timer.Remove("VindicatorRespawn" .. ply:SteamID64())
    end
    timer.Remove("TTTVindicatorTimer")
end)