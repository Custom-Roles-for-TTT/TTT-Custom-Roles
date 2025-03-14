AddCSLuaFile()

local hook = hook
local ipairs = ipairs
local IsValid = IsValid
local net = net
local pairs = pairs
local player = player
local table = table
local timer = timer
local util = util

local PlayerIterator = player.Iterator

util.AddNetworkString("TTT_ParasiteInfect")

-------------
-- CONVARS --
-------------

local parasite_infection_warning_time = CreateConVar("ttt_parasite_infection_warning_time", 0, FCVAR_NONE, "The time in seconds after infection to warn the victim with an ambiguous message", 0, 300)
local parasite_infection_saves_lover = CreateConVar("ttt_parasite_infection_saves_lover", "1", FCVAR_NONE, "Whether the parasite's lover should survive if the parasite is infecting a player", 0, 1)
local parasite_infection_transfer_reset = CreateConVar("ttt_parasite_infection_transfer_reset", 1, FCVAR_NONE, "Whether the parasite's infection progress will reset if their infection is transferred to another player", 0, 1)
local parasite_respawn_health = CreateConVar("ttt_parasite_respawn_health", 100, FCVAR_NONE, "The health on which the parasite respawns", 1, 100)
local parasite_respawn_limit = CreateConVar("ttt_parasite_respawn_limit", "0", FCVAR_NONE, "The amount of times a parasite can respawn. Set to 0 to have no limit", 0, 20)

local parasite_infection_time = GetConVar("ttt_parasite_infection_time")
local parasite_infection_transfer = GetConVar("ttt_parasite_infection_transfer")
local parasite_respawn_mode = GetConVar("ttt_parasite_respawn_mode")
local parasite_announce_infection = GetConVar("ttt_parasite_announce_infection")
local parasite_infection_suicide_mode = GetConVar("ttt_parasite_infection_suicide_mode")
local parasite_killer_footstep_time = GetConVar("ttt_parasite_killer_footstep_time")

--------------
-- HAUNTING --
--------------

local function ClearParasiteState(ply)
    ply:SetNWBool("ParasiteInfecting", false)
    ply:SetNWString("ParasiteInfectingTarget", "")
    ply:SetNWInt("ParasiteInfectionProgress", 0)
    timer.Remove(ply:Nick() .. "ParasiteInfectionProgress")
    timer.Remove(ply:Nick() .. "ParasiteInfectingSpectate")
    timer.Remove(ply:Nick() .. "ParasiteInfectingWarning")
end

local function ResetPlayer(ply)
    -- If this player is infecting someone else, make sure to clear them of the infection too
    if ply:GetNWBool("ParasiteInfecting", false) then
        local sid = ply:GetNWString("ParasiteInfectingTarget", "")
        if sid and #sid > 0 then
            local target = player.GetBySteamID64(sid)
            if IsPlayer(target) then
                target:SetNWBool("ParasiteInfected", false)
            end
        end
    end
    ClearParasiteState(ply)
end

local deadParasites = {}
hook.Add("TTTPrepareRound", "Parasite_TTTPrepareRound", function()
    for _, v in PlayerIterator() do
        v:SetNWBool("ParasiteInfected", false)
        ClearParasiteState(v)
    end
    deadParasites = {}
end)

hook.Add("TTTPlayerRoleChanged", "Parasite_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if oldRole == ROLE_PARASITE and oldRole ~= newRole then
        ResetPlayer(ply)
    end
end)

hook.Add("TTTPlayerSpawnForRound", "Parasite_TTTPlayerSpawnForRound", function(ply, dead_only)
    ResetPlayer(ply)
end)

-- Un-haunt the device owner if they used their device on the parasite
hook.Add("TTTPlayerRoleChangedByItem", "Parasite_TTTPlayerRoleChangedByItem", function(ply, tgt, item)
    if tgt:IsParasite() and tgt:GetNWString("ParasiteInfectingTarget", "") == ply:SteamID64() then
        ply:SetNWBool("ParasiteInfected", false)
    end
end)

local function DoParasiteRespawnWithoutBody(parasite, hide_messages)
    if not hide_messages then
        parasite:QueueMessage(MSG_PRINTCENTER, "You have drained your host of energy and created a new body.")
    end
    -- Introduce a slight delay to prevent player getting stuck as a spectator
    timer.Create(parasite:Nick() .. "ParasiteRespawn", 0.1, 1, function()
        local body = parasite.server_ragdoll or parasite:GetRagdollEntity()
        parasite:SpawnForRound(true)
        SafeRemoveEntity(body)

        local health = parasite_respawn_health:GetInt()
        parasite:SetHealth(health)
    end)
end

local function DoParasiteRespawn(parasite, attacker, hide_messages)
    if parasite:IsParasite() and not parasite:Alive() then
        attacker:SetNWBool("ParasiteInfected", false)
        ClearParasiteState(parasite)

        local parasiteBody = parasite.server_ragdoll or parasite:GetRagdollEntity()

        local respawnMode = parasite_respawn_mode:GetInt()
        if respawnMode == PARASITE_RESPAWN_HOST then
            if not hide_messages then
                parasite:QueueMessage(MSG_PRINTCENTER, "You have taken control of your host.")
            end

            parasite:SpawnForRound(true)
            parasite:SetPos(attacker:GetPos())
            parasite:SetEyeAngles(Angle(0, attacker:GetAngles().y, 0))

            local weaps = attacker:GetWeapons()
            local currentWeapon = "weapon_zm_improvised"
            local activeWeap = attacker:GetActiveWeapon()
            if IsValid(activeWeap) then
                currentWeapon = WEPS.GetClass(activeWeap)
            end
            attacker:StripAll()
            parasite:StripAll()
            for _, v in ipairs(weaps) do
                -- Don't give the parastie role weapons
                if v.Category == WEAPON_CATEGORY_ROLE then continue end
                local wep_class = WEPS.GetClass(v)
                parasite:Give(wep_class)
            end
            parasite:SelectWeapon(currentWeapon)
        elseif respawnMode == PARASITE_RESPAWN_BODY then
            if IsValid(parasiteBody) then
                if not hide_messages then
                    parasite:QueueMessage(MSG_PRINTCENTER, "You have drained your host of energy and regenerated your old body.")
                end
                parasite:SpawnForRound(true)
                parasite:SetPos(FindRespawnLocation(parasiteBody:GetPos()) or parasiteBody:GetPos())
                parasite:SetEyeAngles(Angle(0, parasiteBody:GetAngles().y, 0))
            else
                DoParasiteRespawnWithoutBody(parasite, hide_messages)
            end
        elseif respawnMode == PARASITE_RESPAWN_RANDOM then
            DoParasiteRespawnWithoutBody(parasite, hide_messages)
        end

        local health = parasite_respawn_health:GetInt()
        parasite:SetHealth(health)
        SafeRemoveEntity(parasiteBody)
        if attacker:Alive() then
            attacker:Kill()
        end
        if not hide_messages then
            attacker:QueueMessage(MSG_PRINTBOTH, "Your parasite has drained you of your energy.")
        end

        hook.Call("TTTParasiteRespawn", nil, parasite, attacker)
    end
end

local function ShouldParasiteRespawnBySuicide(mode, victim, attacker, dmginfo)
    -- Any cause of suicide
    if mode == PARASITE_SUICIDE_RESPAWN_ALL then
        return victim == attacker
    -- Only if they killed themselves via a command (in this case they would be the inflictor)
    elseif mode == PARASITE_SUICIDE_RESPAWN_CONSOLE then
        local inflictor = dmginfo:GetInflictor()
        return victim == attacker and IsValid(inflictor) and victim == inflictor
    end

    return false
end

local function HandleParasiteInfection(attacker, victim, keep_progress)
    attacker:SetNWBool("ParasiteInfected", true)
    victim:SetNWBool("ParasiteInfecting", true)
    victim:SetNWString("ParasiteInfectingTarget", attacker:SteamID64())

    -- Lock the victim's view on their attacker
    timer.Create(victim:Nick() .. "ParasiteInfectingSpectate", 1, 1, function()
        victim:SetRagdollSpec(false)
        victim:Spectate(OBS_MODE_CHASE)
        victim:SpectateEntity(attacker)
    end)

    local infection_time = parasite_infection_time:GetInt()
    if infection_time <= 0 then
        -- Even though there is no infection progress, use the same timer ID so all the logic that stops it
        -- can be reused. We really just want to make sure they stay locked to their target
        timer.Create(victim:Nick() .. "ParasiteInfectionProgress", 1, 0, function()
            -- Make sure the victim is still in the correct spectate mode
            local spec_mode = victim:GetObserverMode()
            if spec_mode ~= OBS_MODE_CHASE and spec_mode ~= OBS_MODE_IN_EYE then
                victim:Spectate(OBS_MODE_CHASE)
            end
        end)
        return
    end

    if not keep_progress then
        victim:SetNWInt("ParasiteInfectionProgress", 0)
    end
    timer.Create(victim:Nick() .. "ParasiteInfectionProgress", 1, 0, function()
        -- Make sure the victim is still in the correct spectate mode
        local spec_mode = victim:GetObserverMode()
        if spec_mode ~= OBS_MODE_CHASE and spec_mode ~= OBS_MODE_IN_EYE then
            victim:Spectate(OBS_MODE_CHASE)
        end

        local progress = victim:GetNWInt("ParasiteInfectionProgress", 0) + 1
        if progress >= parasite_infection_time:GetInt() then -- respawn the parasite
            DoParasiteRespawn(victim, attacker)
        else
            victim:SetNWInt("ParasiteInfectionProgress", progress)
        end
    end)

    local warning_time = parasite_infection_warning_time:GetInt()
    -- If it's enabled, warn the victim that they are infected
    if warning_time > 0 and warning_time < parasite_infection_time:GetInt() then
        -- Track this timer on the parasite's name since there can only be 1 parasite killer and it's easier to remove later
        timer.Create(victim:Nick() .. "ParasiteInfectingWarning", warning_time, 1, function()
            if not IsPlayer(attacker) or not attacker:Alive() or attacker:IsSpec() then return end

            attacker:QueueMessage(MSG_PRINTBOTH, "You feel a strange wriggling under your skin.")
        end)
    end
end

hook.Add("PlayerDeath", "Parasite_PlayerDeath", function(victim, infl, attacker)
    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    if valid_kill and victim:IsParasite() and not attacker:IsVictimChangingRole(victim) and not victim:IsRoleAbilityDisabled() then
        if not attacker:IsActive() then
            victim:QueueMessage(MSG_PRINTBOTH, "Your attacker is already dead, your infection failed to take hold.")
            return
        end

        local sid = victim:SteamID64()
        -- Keep track of how many times this parasite has been killed and by who
        if not deadParasites[sid] then
            deadParasites[sid] = {times = 1, player = victim, attacker = attacker:SteamID64()}
        else
            deadParasites[sid] = {times = deadParasites[sid].times + 1, player = victim, attacker = attacker:SteamID64()}
        end

        local respawn_limit = parasite_respawn_limit:GetInt()
        if respawn_limit > 0 and deadParasites[sid].times > respawn_limit then
            victim:QueueMessage(MSG_PRINTBOTH, "Your parasite has affected too many, causing players to develop immunity. Your infection failed to take hold.")
            ResetPlayer(victim)
            return
        end

        HandleParasiteInfection(attacker, victim)

        if parasite_announce_infection:GetBool() then
            attacker:QueueMessage(MSG_PRINTCENTER, "You have been infected with a parasite.")
        end
        victim:QueueMessage(MSG_PRINTCENTER, "Your attacker has been infected.")

        if parasite_infection_saves_lover:GetBool() then
            local loverSID = victim:GetNWString("TTTCupidLover", "")
            if #loverSID > 0 then
                local lover = player.GetBySteamID64(loverSID)
                lover:QueueMessage(MSG_PRINTCENTER, "Your lover has died... but they are infecting someone!")
            end
        end

        net.Start("TTT_ParasiteInfect")
        net.WriteString(victim:Nick())
        net.WriteString(attacker:Nick())
        net.Broadcast()
    end
end)

hook.Add("TTTSpectatorHUDKeyPress", "Parasite_TTTSpectatorHUDKeyPress", function(ply, tgt, powers)
    if ply:GetNWBool("ParasiteInfecting", false) then
        return true
    end
end)

---------------
-- FOOTSTEPS --
---------------

hook.Add("PlayerFootstep", "Parasite_PlayerFootstep", function(ply, pos, foot, sound, volume, rf)
    if not IsValid(ply) or ply:IsSpec() or not ply:Alive() then return true end
    if ply:WaterLevel() ~= 0 then return end
    if not ply:GetNWBool("ParasiteInfected", false) then return end

    local killer_footstep_time = parasite_killer_footstep_time:GetInt()
    if killer_footstep_time <= 0 then return end

    -- This player killed a Parasite. Tell everyone where their foot steps should go
    net.Start("TTT_PlayerFootstep")
        net.WritePlayer(ply)
        net.WriteVector(pos)
        net.WriteAngle(ply:GetAimVector():Angle())
        net.WriteBit(foot)
        net.WriteTable(Color(138, 4, 4))
        net.WriteUInt(killer_footstep_time, 8)
        net.WriteFloat(1) -- Scale
    net.Broadcast()
end)

-------------
-- RESPAWN --
-------------

hook.Add("DoPlayerDeath", "Parasite_DoPlayerDeath", function(ply, attacker, dmginfo)
    if ply:IsSpec() then return end

    local parasiteUsers = table.GetKeys(deadParasites)
    for _, key in pairs(parasiteUsers) do
        local parasite = deadParasites[key]
        if parasite.attacker == ply:SteamID64() and IsValid(parasite.player) then
            local deadParasite = parasite.player
            if not deadParasite:IsParasite() or deadParasite:Alive() then continue end

            -- If we're not infecting, but haunting then we just respawning immediately
            if parasite_infection_time:GetInt() <= 0 then
                deadParasite:QueueMessage(MSG_PRINTCENTER, "Your host has been killed, allowing your infection to take over.")
                DoParasiteRespawn(deadParasite, ply, true)
                continue
            end

            local suicideMode = parasite_infection_suicide_mode:GetInt()
            -- Transfer the infection to the new attacker if there is one, they are alive, the parasite is still alive, and the transfer feature is enabled
            if IsPlayer(attacker) and attacker:IsActive() and parasite_infection_transfer:GetBool() then
                deadParasites[key].attacker = attacker:SteamID64()
                HandleParasiteInfection(attacker, deadParasite, not parasite_infection_transfer_reset:GetBool())
                deadParasite:QueueMessage(MSG_PRINTCENTER, "Your host has been killed and your infection has spread to their killer.")
                net.Start("TTT_ParasiteInfect")
                net.WriteString(deadParasite:Nick())
                net.WriteString(attacker:Nick())
                net.Broadcast()
            elseif suicideMode > PARASITE_SUICIDE_NONE and ShouldParasiteRespawnBySuicide(suicideMode, ply, attacker, dmginfo) then
                deadParasite:QueueMessage(MSG_PRINTCENTER, "Your host has killed themselves, allowing your infection to take over.")
                DoParasiteRespawn(deadParasite, attacker, true)
            else
                ClearParasiteState(deadParasite)
                deadParasite:QueueMessage(MSG_PRINTCENTER, "Your host has died.")

                if parasite_infection_saves_lover:GetBool() then
                    local loverSID = deadParasite:GetNWString("TTTCupidLover", "")
                    if #loverSID > 0 then
                        local lover = player.GetBySteamID64(loverSID)
                        lover:PrintMessage(HUD_PRINTTALK, "Your lover's host has died!")
                    end
                end
            end
        end
    end

    ply:SetNWBool("ParasiteInfected", false)
end)

------------------
-- CUPID LOVERS --
------------------

local function IsParasiteInfecting(ply)
    return ply:GetNWBool("ParasiteInfecting", false) and ply:IsParasite() and not ply:Alive()
end

hook.Add("TTTCupidShouldLoverSurvive", "Parasite_TTTCupidShouldLoverSurvive", function(ply, lover)
    if parasite_infection_saves_lover:GetBool() and (IsParasiteInfecting(ply) or IsParasiteInfecting(lover)) then
        return true
    end
end)

hook.Add("PostPlayerDeath", "Parasite_Lovers_PostPlayerDeath", function(ply)
    local loverSID = ply:GetNWString("TTTCupidLover", "")
    if #loverSID == 0 then return end

    local lover = player.GetBySteamID64(loverSID)
    if not IsPlayer(lover) then return end

    if IsParasiteInfecting(lover) then
        lover:QueueMessage(MSG_PRINTBOTH, "Your lover has died and so you will not survive if you respawn!")
    end
end)

----------
-- CURE --
----------

hook.Add("TTTCanPlayerBeCured", "Parasite_TTTCanPlayerBeCured", function(ply)
    if ply:GetNWBool("ParasiteInfected", false) then
        return true
    end
end)

hook.Add("TTTCurePlayer", "Parasite_TTTCurePlayer", function(ply)
    if not ply:GetNWBool("ParasiteInfected", false) then return end

    ply:SetNWBool("ParasiteInfected", false)
    for _, v in PlayerIterator() do
        if v:GetNWString("ParasiteInfectingTarget", "") == ply:SteamID64() then
            ClearParasiteState(v)
            v:QueueMessage(MSG_PRINTCENTER, "Your host has been cured.")

            if GetConVar("ttt_parasite_infection_saves_lover"):GetBool() then
                local loverSID = v:GetNWString("TTTCupidLover", "")
                if #loverSID > 0 then
                    local lover = player.GetBySteamID64(loverSID)
                    lover:PrintMessage(HUD_PRINTTALK, "Your lover's host was cured!")
                end
            end
        end
    end
end)