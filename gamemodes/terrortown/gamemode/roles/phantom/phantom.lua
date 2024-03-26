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

util.AddNetworkString("TTT_PhantomHaunt")

-------------
-- CONVARS --
-------------

local phantom_killer_haunt = GetConVar("ttt_phantom_killer_haunt")
local phantom_killer_haunt_power_max = GetConVar("ttt_phantom_killer_haunt_power_max")
local phantom_killer_haunt_move_cost = GetConVar("ttt_phantom_killer_haunt_move_cost")
local phantom_killer_haunt_attack_cost = GetConVar("ttt_phantom_killer_haunt_attack_cost")
local phantom_killer_haunt_jump_cost = GetConVar("ttt_phantom_killer_haunt_jump_cost")
local phantom_killer_haunt_drop_cost = GetConVar("ttt_phantom_killer_haunt_drop_cost")
local phantom_weaker_each_respawn = GetConVar("ttt_phantom_weaker_each_respawn")
local phantom_announce_death = GetConVar("ttt_phantom_announce_death")
local phantom_killer_footstep_time = GetConVar("ttt_phantom_killer_footstep_time")

local phantom_respawn_health = CreateConVar("ttt_phantom_respawn_health", "50", FCVAR_NONE, "The amount of health a phantom will respawn with", 1, 100)
local phantom_killer_haunt_power_rate = CreateConVar("ttt_phantom_killer_haunt_power_rate", "10", FCVAR_NONE, "The amount of power to regain per second when a phantom is haunting their killer", 1, 25)
local phantom_killer_haunt_power_starting = CreateConVar("ttt_phantom_killer_haunt_power_starting", "0", FCVAR_NONE, "The amount of power to the phantom starts with", 0, 200)
local phantom_killer_haunt_without_body = CreateConVar("ttt_phantom_killer_haunt_without_body", "1")
local phantom_haunt_saves_lover = CreateConVar("ttt_phantom_haunt_saves_lover", "1", FCVAR_NONE, "Whether the phantom's lover should survive if the phantom is haunting a player", 0, 1)

--------------
-- HAUNTING --
--------------

local deadPhantoms = {}
hook.Add("TTTPrepareRound", "Phantom_TTTPrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        v:SetNWBool("PhantomHaunted", false)
        v:SetNWBool("PhantomHaunting", false)
        v:SetNWString("PhantomHauntingTarget", "")
        v:SetNWBool("PhantomPossessing", false)
        v:SetNWInt("PhantomPossessingPower", 0)
        timer.Remove(v:Nick() .. "PhantomPossessingPower")
        timer.Remove(v:Nick() .. "PhantomPossessingSpectate")
    end
    deadPhantoms = {}
end)

local function ResetPlayer(ply)
    -- If this player is haunting someone else, make sure to clear them of the haunt too
    if ply:GetNWBool("PhantomHaunting", false) then
        local sid = ply:GetNWString("PhantomHauntingTarget", "")
        if sid and #sid > 0 then
            local target = player.GetBySteamID64(sid)
            if IsPlayer(target) then
                target:SetNWBool("PhantomHaunted", false)
            end
        end
    end
    ply:SetNWBool("PhantomHaunting", false)
    ply:SetNWString("PhantomHauntingTarget", "")
    ply:SetNWBool("PhantomPossessing", false)
    ply:SetNWInt("PhantomPossessingPower", 0)
    timer.Remove(ply:Nick() .. "PhantomPossessingPower")
    timer.Remove(ply:Nick() .. "PhantomPossessingSpectate")
end

hook.Add("TTTPlayerRoleChanged", "Phantom_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if oldRole == ROLE_PHANTOM and oldRole ~= newRole then
        ResetPlayer(ply)
    end
end)

hook.Add("TTTPlayerSpawnForRound", "Phantom_TTTPlayerSpawnForRound", function(ply, dead_only)
    ResetPlayer(ply)
end)

-- Un-haunt the device owner if they used their device on the phantom
hook.Add("TTTPlayerRoleChangedByItem", "Phantom_TTTPlayerRoleChangedByItem", function(ply, tgt, item)
    if tgt:IsPhantom() and tgt:GetNWString("PhantomHauntingTarget", "") == ply:SteamID64() then
        ply:SetNWBool("PhantomHaunted", false)
    end
end)

-- Hide the role of the player that killed the phantom if haunting is enabled
hook.Add("TTTDeathNotifyOverride", "Phantom_TTTDeathNotifyOverride", function(victim, inflictor, attacker, reason, killerName, role)
    if GetRoundState() ~= ROUND_ACTIVE then return end
    if not IsValid(inflictor) or not IsValid(attacker) then return end
    if not attacker:IsPlayer() then return end
    if victim == attacker then return end
    if not victim:IsPhantom() then return end
    if not phantom_killer_haunt:GetBool() then return end

    return reason, killerName, ROLE_NONE
end)

hook.Add("PlayerDeath", "Phantom_PlayerDeath", function(victim, infl, attacker)
    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    if valid_kill and victim:IsPhantom() then
        local attacker_alive = attacker:IsActive()
        local will_posses = phantom_killer_haunt:GetBool() and not victim:IsZombifying() and attacker_alive

        -- Only bother looking this up if we're going to use it
        local loverSID = ""
        if phantom_haunt_saves_lover:GetBool() and will_posses then
            loverSID = victim:GetNWString("TTTCupidLover", "")
        end

        if phantom_announce_death:GetBool() then
            for _, v in pairs(GetAllPlayers()) do
                if v ~= attacker and v:IsActiveDetectiveLike() and v:SteamID64() ~= loverSID then
                    v:QueueMessage(MSG_PRINTCENTER, "The " .. ROLE_STRINGS[ROLE_PHANTOM] .. " has been killed.")
                end
            end
        end

        if victim:IsZombifying() then return end

        if not attacker_alive then
            victim:QueueMessage(MSG_PRINTBOTH, "Your attacker is already dead so you have nobody to haunt.")
            return
        end

        attacker:SetNWBool("PhantomHaunted", true)
        victim:SetNWBool("PhantomHaunting", true)
        victim:SetNWString("PhantomHauntingTarget", attacker:SteamID64())

        if will_posses then
            victim:SetNWBool("PhantomPossessing", true)
            victim:SetNWInt("PhantomPossessingPower", phantom_killer_haunt_power_starting:GetInt())
            timer.Create(victim:Nick() .. "PhantomPossessingPower", 1, 0, function()
                -- If haunting without a body is disabled, check to make sure the body exists still
                if not phantom_killer_haunt_without_body:GetBool() then
                    local phantomBody = victim.server_ragdoll or victim:GetRagdollEntity()
                    if not IsValid(phantomBody) then
                        timer.Remove(victim:Nick() .. "PhantomPossessingPower")
                        timer.Remove(victim:Nick() .. "PhantomPossessingSpectate")
                        attacker:SetNWBool("PhantomHaunted", false)
                        victim:SetNWBool("PhantomHaunting", false)
                        victim:SetNWString("PhantomHauntingTarget", "")
                        victim:SetNWBool("PhantomPossessing", false)
                        victim:SetNWInt("PhantomPossessingPower", 0)

                        victim:QueueMessage(MSG_PRINTBOTH, "Your body has been destroyed, removing your tether to the world.")

                        if phantom_haunt_saves_lover:GetBool() and #loverSID > 0 then
                            local lover = player.GetBySteamID64(loverSID)
                            lover:PrintMessage(HUD_PRINTTALK, "Your lover's body was destroyed!")
                        end
                        return
                    end
                end

                -- Make sure the victim is still in the correct spectate mode
                local spec_mode = victim:GetObserverMode()
                if spec_mode ~= OBS_MODE_CHASE and spec_mode ~= OBS_MODE_IN_EYE then
                    victim:Spectate(OBS_MODE_CHASE)
                end

                local power = victim:GetNWInt("PhantomPossessingPower", 0)
                local power_rate = phantom_killer_haunt_power_rate:GetInt()
                local new_power = math.Clamp(power + power_rate, 0, phantom_killer_haunt_power_max:GetInt())
                victim:SetNWInt("PhantomPossessingPower", new_power)
            end)

            -- Lock the victim's view on their attacker
            timer.Create(victim:Nick() .. "PhantomPossessingSpectate", 1, 1, function()
                victim:SetRagdollSpec(false)
                victim:Spectate(OBS_MODE_CHASE)
                victim:SpectateEntity(attacker)
            end)
        end

        attacker:QueueMessage(MSG_PRINTCENTER, "You have been haunted.")
        victim:QueueMessage(MSG_PRINTCENTER, "Your attacker has been haunted.")

        if #loverSID > 0 then
            local lover = player.GetBySteamID64(loverSID)
            lover:QueueMessage(MSG_PRINTCENTER, "Your lover has died... but they are haunting someone!")
        end

        local sid = victim:SteamID64()
        -- Keep track of how many times this Phantom has been killed and by who
        if not deadPhantoms[sid] then
            deadPhantoms[sid] = {times = 1, player = victim, attacker = attacker:SteamID64()}
        else
            deadPhantoms[sid] = {times = deadPhantoms[sid].times + 1, player = victim, attacker = attacker:SteamID64()}
        end

        net.Start("TTT_PhantomHaunt")
        net.WriteString(victim:Nick())
        net.WriteString(attacker:Nick())
        net.Broadcast()
    end
end)

hook.Add("TTTSpectatorHUDKeyPress", "Phantom_TTTSpectatorHUDKeyPress", function(ply, tgt, powers)
    if ply:GetNWBool("PhantomPossessing", false) and IsValid(tgt) and tgt:IsActive() then
        powers[IN_ATTACK] = {
            start_command = "+attack",
            end_command = "-attack",
            time = 0.5,
            cost = phantom_killer_haunt_attack_cost:GetInt()
        }
        powers[IN_ATTACK2] = {
            start_command = "+menu",
            end_command = "-menu",
            time = 0.2,
            cost = phantom_killer_haunt_drop_cost:GetInt()
        }
        powers[IN_FORWARD] = {
            start_command = "+forward",
            end_command = "-forward",
            time = 0.5,
            cost = phantom_killer_haunt_move_cost:GetInt()
        }
        powers[IN_BACK] = {
            start_command = "+back",
            end_command = "-back",
            time = 0.5,
            cost = phantom_killer_haunt_move_cost:GetInt()
        }
        powers[IN_MOVELEFT] = {
            start_command = "+moveleft",
            end_command = "-moveleft",
            time = 0.5,
            cost = phantom_killer_haunt_move_cost:GetInt()
        }
        powers[IN_MOVERIGHT] = {
            start_command = "+moveright",
            end_command = "-moveright",
            time = 0.5,
            cost = phantom_killer_haunt_move_cost:GetInt()
        }
        powers[IN_JUMP] = {
            start_command = "+jump",
            end_command = "-jump",
            time = 0.2,
            cost = phantom_killer_haunt_jump_cost:GetInt()
        }

        return true, "PhantomPossessingPower"
    end
end)

-------------
-- RESPAWN --
-------------

hook.Add("DoPlayerDeath", "Phantom_DoPlayerDeath", function(ply, attacker, dmginfo)
    if ply:IsSpec() then return end

    if ply:GetNWBool("PhantomHaunted", false) then
        local respawn = false
        local phantomUsers = table.GetKeys(deadPhantoms)
        for _, key in pairs(phantomUsers) do
            local phantom = deadPhantoms[key]
            if phantom.attacker == ply:SteamID64() and IsValid(phantom.player) then
                local deadPhantom = phantom.player
                deadPhantom:SetNWBool("PhantomHaunting", false)
                deadPhantom:SetNWString("PhantomHauntingTarget", "")
                deadPhantom:SetNWBool("PhantomPossessing", false)
                deadPhantom:SetNWInt("PhantomPossessingPower", 0)
                timer.Remove(deadPhantom:Nick() .. "PhantomPossessingPower")
                timer.Remove(deadPhantom:Nick() .. "PhantomPossessingSpectate")
                if deadPhantom:IsPhantom() and not deadPhantom:Alive() then
                    -- Find the Phantom's corpse
                    local phantomBody = deadPhantom.server_ragdoll or deadPhantom:GetRagdollEntity()
                    if IsValid(phantomBody) then
                        deadPhantom:SpawnForRound(true)
                        deadPhantom:SetPos(FindRespawnLocation(phantomBody:GetPos()) or phantomBody:GetPos())
                        deadPhantom:SetEyeAngles(Angle(0, phantomBody:GetAngles().y, 0))

                        local health = phantom_respawn_health:GetInt()
                        if phantom_weaker_each_respawn:GetBool() then
                            -- Don't reduce them the first time since 50 is already reduced
                            for _ = 1, phantom.times - 1 do
                                health = health / 2
                            end
                            health = math.max(1, math.Round(health))
                        end
                        deadPhantom:SetHealth(health)
                        phantomBody:Remove()
                        deadPhantom:QueueMessage(MSG_PRINTBOTH, "Your attacker died and you have been respawned.")
                        respawn = true
                    else
                        deadPhantom:QueueMessage(MSG_PRINTBOTH, "Your attacker died but your body has been destroyed.")
                    end
                end
            end
        end

        if respawn and phantom_announce_death:GetBool() then
            for _, v in pairs(GetAllPlayers()) do
                if v:IsActiveDetectiveLike() then
                    v:QueueMessage(MSG_PRINTCENTER, "The " .. ROLE_STRINGS[ROLE_PHANTOM] .. " has been respawned.")
                end
            end
        end

        ply:SetNWBool("PhantomHaunted", false)
        SendFullStateUpdate()
    end
end)

---------------
-- FOOTSTEPS --
---------------

hook.Add("PlayerFootstep", "Phantom_PlayerFootstep", function(ply, pos, foot, sound, volume, rf)
    if not IsValid(ply) or ply:IsSpec() or not ply:Alive() then return true end
    if ply:WaterLevel() ~= 0 then return end
    if not ply:GetNWBool("PhantomHaunted", false) then return end

    local killer_footstep_time = phantom_killer_footstep_time:GetInt()
    if killer_footstep_time <= 0 then return end

    -- This player killed a Phantom. Tell everyone where their foot steps should go
    net.Start("TTT_PlayerFootstep")
    net.WriteEntity(ply)
    net.WriteVector(pos)
    net.WriteAngle(ply:GetAimVector():Angle())
    net.WriteBit(foot)
    net.WriteTable(Color(138, 4, 4))
    net.WriteUInt(killer_footstep_time, 8)
    net.WriteFloat(1) -- Scale
    net.Broadcast()
end)

------------------
-- CUPID LOVERS --
------------------

local function IsPhantomHaunting(ply)
    return ply:GetNWBool("PhantomHaunting", false) and ply:IsPhantom() and not ply:Alive()
end

hook.Add("TTTCupidShouldLoverSurvive", "Phantom_TTTCupidShouldLoverSurvive", function(ply, lover)
    if phantom_haunt_saves_lover:GetBool() and (IsPhantomHaunting(ply) or IsPhantomHaunting(lover)) then
        return true
    end
end)

hook.Add("PostPlayerDeath", "Phantom_Lovers_PostPlayerDeath", function(ply)
    local loverSID = ply:GetNWString("TTTCupidLover", "")
    if #loverSID == 0 then return end

    local lover = player.GetBySteamID64(loverSID)
    if not IsPlayer(lover) then return end

    if IsPhantomHaunting(lover) then
        lover:QueueMessage(MSG_PRINTBOTH, "Your lover has died and so you will not survive if you respawn!")
    end
end)