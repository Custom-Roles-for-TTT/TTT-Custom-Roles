AddCSLuaFile()

local hook = hook
local timer = timer
local player = player
local net = net
local math = math

local PlayerIterator = player.Iterator

util.AddNetworkString("TTT_VindicatorTeamChange")
util.AddNetworkString("TTT_VindicatorActive")
util.AddNetworkString("TTT_VindicatorSuccess")
util.AddNetworkString("TTT_VindicatorFail")

-------------
-- CONVARS --
-------------

local vindicator_respawn_delay = CreateConVar("ttt_vindicator_respawn_delay", "5", FCVAR_NONE, "Delay between the vindicator dying and respawning in seconds", 0, 30)
local vindicator_respawn_health = CreateConVar("ttt_vindicator_respawn_health", "100", FCVAR_NONE, "The amount of health a vindicator will respawn with", 1, 200)
local vindicator_announcement_mode = CreateConVar("ttt_vindicator_announcement_mode", "1", FCVAR_NONE, "Who is notified when the vindicator respawns", 0, 2)
local vindicator_prevent_revival = CreateConVar("ttt_vindicator_prevent_revival", "0", FCVAR_NONE)

local vindicator_target_suicide_success = GetConVar("ttt_vindicator_target_suicide_success")
local vindicator_kill_on_fail = GetConVar("ttt_vindicator_kill_on_fail")
local vindicator_kill_on_success = GetConVar("ttt_vindicator_kill_on_success")
local vindicator_reset_on_success = GetConVar("ttt_vindicator_reset_on_success")
local vindicator_reset_win_on_success = GetConVar("ttt_vindicator_reset_win_on_success")

-------------------
-- ROLE FEATURES --
-------------------

local function ActivateVindicator(vindicator, target)
    if not vindicator:IsVindicator() then return end

    -- Change their team and set their target even if the target is already dead
    SetVindicatorTeam(true)
    vindicator:SetNWString("VindicatorTarget", target:SteamID64())
    vindicator:SetNWBool("VindicatorIsRespawning", false)

    net.Start("TTT_VindicatorActive")
    net.WriteString(vindicator:Nick())
    net.WriteString(target:Nick())
    net.Broadcast()

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

    local vect = target:GetPos() - vindicator:GetPos()
    vindicator:SetEyeAngles(vect:Angle())

    vindicator:QueueMessage(MSG_PRINTBOTH, "Hunt down your killer and get your revenge!")
    local mode = vindicator_announcement_mode:GetInt()
    if mode > VINDICATOR_ANNOUNCE_NONE then
        local roleStr = string.Capitalize(ROLE_STRINGS_EXT[ROLE_VINDICATOR])
        target:QueueMessage(MSG_PRINTBOTH, roleStr .. " (" .. vindicator:Nick() .. ") has respawned and is hunting you down!")

        if mode == VINDICATOR_ANNOUNCE_ALL then
            for _, ply in PlayerIterator() do
                if ply ~= vindicator and ply ~= target then
                    ply:PrintMessage(HUD_PRINTTALK, roleStr .. " (" .. vindicator:Nick() .. ") has respawned and is hunting down " .. target:Nick() .. "!")
                end
            end
        end
    end
end

local function OnVindicatorSuccess(vindicator, target, msg)
    if vindicator_reset_on_success:GetBool() and not vindicator_reset_win_on_success:GetBool() then
        vindicator:SetNWBool("VindicatorSuccess", true)
    end
    vindicator:QueueMessage(MSG_PRINTBOTH, msg)
    net.Start("TTT_VindicatorSuccess")
    net.WriteString(vindicator:Nick())
    net.WriteString(target:Nick())
    net.Broadcast()

    if vindicator_reset_on_success:GetBool() then
        vindicator:SetNWString("VindicatorTarget", "")
        SetVindicatorTeam(false)
        vindicator:QueueMessage(MSG_PRINTBOTH, "You have gotten your revenge and will now return to your peaceful existence.")
    elseif not vindicator_prevent_revival:GetBool() and vindicator_kill_on_success:GetBool() then
        vindicator:Kill()
        vindicator:QueueMessage(MSG_PRINTBOTH, "You can now rest in peace having achieved your goal.")
    end
end

hook.Add("PlayerDeath", "Vindicator_PlayerDeath", function(victim, infl, attacker)
    local valid_kill = IsPlayer(attacker) and GetRoundState() == ROUND_ACTIVE
    local handled = false
    if valid_kill then
        if victim:IsVindicator() and not victim:IsRoleActive() and attacker ~= victim then
            if attacker:IsVictimChangingRole(victim) then return end

            victim:SetNWBool("VindicatorIsRespawning", true)

            local delay = vindicator_respawn_delay:GetInt()
            if delay == 0 then
                ActivateVindicator(victim, attacker)
            else
                victim:QueueMessage(MSG_PRINTBOTH, "You will be respawned in " .. delay .. " second(s)", math.min(delay, 5))
                timer.Create("VindicatorRespawn" .. victim:SteamID64(), delay, 1, function()
                    ActivateVindicator(victim, attacker)
                end)
            end
            handled = true
        elseif attacker:IsVindicator() and victim:SteamID64() == attacker:GetNWString("VindicatorTarget", "") then
            OnVindicatorSuccess(attacker, victim, "You have successfully killed your target.")
            handled = true
        end
    end

    -- Either the attacker or the victim was a vindicator and we have handled the logic above
    if handled then return end

    -- If we have already checked the attacker v. victim options, we know neither are a vindicator
    -- Check if the victim is a vindicator's target
    for _, ply in PlayerIterator() do
        if ply:IsActiveVindicator() and victim:SteamID64() == ply:GetNWString("VindicatorTarget", "") then
            if attacker == victim and vindicator_target_suicide_success:GetBool() then
                OnVindicatorSuccess(ply, victim, "Your target finished the job for you and has killed themselves.")
            else
                ply:QueueMessage(MSG_PRINTBOTH, "Your target was killed by someone else and you have failed.")
                net.Start("TTT_VindicatorFail")
                net.WriteString(ply:Nick())
                net.WriteString(victim:Nick())
                net.Broadcast()
                if not vindicator_prevent_revival:GetBool() and vindicator_kill_on_fail:GetBool() then
                    ply:Kill()
                    ply:QueueMessage(MSG_PRINTBOTH, "Having failed to take revenge, you must return to death.")
                end
            end
        end
    end
end)

hook.Add("TTTStopPlayerRespawning", "Vindicator_TTTStopPlayerRespawning", function(ply)
    if not IsPlayer(ply) then return end
    if ply:Alive() then return end

    if ply:GetNWBool("VindicatorIsRespawning", false) then
        timer.Remove("VindicatorRespawn" .. ply:SteamID64())
        ply:SetNWBool("VindicatorIsRespawning", false)
    end
end)

hook.Add("TTTDeathNotifyOverride", "Vindicator_TTTDeathNotifyOverride", function(victim, inflictor, attacker, reason, killerName, role)
    if GetRoundState() ~= ROUND_ACTIVE then return end
    if not IsValid(inflictor) or not IsValid(attacker) then return end
    if not attacker:IsPlayer() then return end
    if victim == attacker then return end
    if not victim:IsVindicator() then return end
    if victim:IsRoleActive() then return end

    return reason, killerName, ROLE_NONE
end)

local function HandleVindicatorMidRound(ply)
    if not IsPlayer(ply) then return end

    local target = player.GetBySteamID64(ply:GetNWString("VindicatorTarget", ""))
    if not IsPlayer(target) then
        if not ply:IsIndependentTeam() then return end
        SetVindicatorTeam(false)
    elseif not ply:IsIndependentTeam() then
        SetVindicatorTeam(true)
    end
end

local unkillable_roles = { ROLE_GUESSER }

hook.Add("TTTPlayerRoleChanged", "Vindicator_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if oldRole == newRole then return end

    -- Do these checks regardless of the current team of the role in case we swap and swap back,
    -- we want the original Vindicator to have their same first target
    if oldRole == ROLE_VINDICATOR then
        local vindicator = player.GetLivingRole(ROLE_VINDICATOR)
        HandleVindicatorMidRound(vindicator)
    elseif newRole == ROLE_VINDICATOR then
        HandleVindicatorMidRound(ply)
    -- If the player has changed to an unkillable role
    elseif table.HasValue(unkillable_roles, newRole) then
        local plySid64 = ply:SteamID64()
        -- Find activated vindicators who have this player as their target
        for _, p in PlayerIterator() do
            if not p:Alive() or p:IsSpec() then continue end
            if not p:IsVindicator() or not p:IsRoleActive() then continue end

            local targetSid64 = p:GetNWString("VindicatorTarget", "")
            -- Then clear their target and swap them back to being innocent
            if plySid64 == targetSid64 then
                p:SetNWString("VindicatorTarget", "")
                SetVindicatorTeam(false)
                p:QueueMessage(MSG_PRINTBOTH, "Your target has changed to a new role that you cannot kill. You have calmed your need for revenge.")
            end
        end
    end
end)

----------------
-- DEATH LINK --
----------------

hook.Add("TTTBeginRound", "Vindicator_TTTBeginRound", function()
    timer.Create("TTTVindicatorTimer", 0.1, 0, function()
        if vindicator_prevent_revival:GetBool() then
            for _, v in PlayerIterator() do
                if not v:IsActiveVindicator() then continue end

                local target_sid64 = v:GetNWString("VindicatorTarget", "")
                if #target_sid64 == 0 then continue end

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
        end
    end)
end)

--------------------------
-- DISCONNECTION CHECKS --
--------------------------

hook.Add("PlayerDisconnected", "Vindicator_PlayerDisconnected", function(ply)
    local sid64 = ply:SteamID64()

    for _, v in PlayerIterator() do
        if v:GetNWString("VindicatorTarget", "") == sid64 and not v:GetNWBool("VindicatorSuccess", false) then
            v:QueueMessage(MSG_PRINTBOTH, "Your target has disconnected so you have rejoined the innocent team!")
            SetVindicatorTeam(false)
            v:SetNWString("VindicatorTarget", "")
        end
    end
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

    -- If the vindicator is paired with their target and they would win together, let that happen
    local lover = vindicator:GetNWString("TTTCupidLover", "")
    if win_type == WIN_CUPID and #lover > 0 and lover == sid64 then return win_type end

    return WIN_NONE
end

hook.Add("TTTWinCheckBlocks", "Vindicator_TTTWinCheckBlocks", function(win_blocks)
    table.insert(win_blocks, HandleVindicatorWinBlock)
end)

hook.Add("TTTCheckForWin", "Vindicator_TTTCheckForWin", function()
    local vindicator_win = false
    local other_alive = false
    for _, ply in PlayerIterator() do
        if ply:IsVindicator() then
            if ply:GetNWBool("VindicatorSuccess", false) then
                vindicator_win = true
            end
        elseif ply:IsActive() and not ply:ShouldActLikeJester() and not ROLE_HAS_PASSIVE_WIN[ply:GetRole()] then
            other_alive = true
        end
    end

    if vindicator_win and not other_alive then
        return WIN_VINDICATOR
    end
end)

hook.Add("TTTPrintResultMessage", "Vindicator_TTTPrintResultMessage", function(type)
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
    for _, ply in PlayerIterator() do
        ply:SetNWString("VindicatorTarget", "")
        ply:SetNWBool("VindicatorSuccess", false)
        ply:SetNWBool("VindicatorIsRespawning", false)
        timer.Remove("VindicatorRespawn" .. ply:SteamID64())
    end
    timer.Remove("TTTVindicatorTimer")
end)