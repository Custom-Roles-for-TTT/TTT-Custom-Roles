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

local phantom_respawn_health = CreateConVar("ttt_phantom_respawn_health", "50", FCVAR_NONE, "The amount of health a phantom will respawn with", 1, 100)
local phantom_weaker_each_respawn = CreateConVar("ttt_phantom_weaker_each_respawn", "0")
local phantom_announce_death = CreateConVar("ttt_phantom_announce_death", "0")
local phantom_killer_smoke = CreateConVar("ttt_phantom_killer_smoke", "0")
local phantom_killer_footstep_time = CreateConVar("ttt_phantom_killer_footstep_time", "0", FCVAR_NONE, "The amount of time a phantom's killer's footsteps should show before fading. Set to 0 to disable", 1, 60)
local phantom_killer_haunt = CreateConVar("ttt_phantom_killer_haunt", "1")
local phantom_killer_haunt_power_max = CreateConVar("ttt_phantom_killer_haunt_power_max", "100", FCVAR_NONE, "The maximum amount of power a phantom can have when haunting their killer", 1, 200)
local phantom_killer_haunt_power_rate = CreateConVar("ttt_phantom_killer_haunt_power_rate", "10", FCVAR_NONE, "The amount of power to regain per second when a phantom is haunting their killer", 1, 25)
local phantom_killer_haunt_power_starting = CreateConVar("ttt_phantom_killer_haunt_power_starting", "0", FCVAR_NONE, "The amount of power to the phantom starts with", 0, 200)
local phantom_killer_haunt_move_cost = CreateConVar("ttt_phantom_killer_haunt_move_cost", "25", FCVAR_NONE, "The amount of power to spend when a phantom is moving their killer via a haunting. Set to 0 to disable", 1, 100)
local phantom_killer_haunt_jump_cost = CreateConVar("ttt_phantom_killer_haunt_jump_cost", "50", FCVAR_NONE, "The amount of power to spend when a phantom is making their killer jump via a haunting. Set to 0 to disable", 1, 100)
local phantom_killer_haunt_drop_cost = CreateConVar("ttt_phantom_killer_haunt_drop_cost", "75", FCVAR_NONE, "The amount of power to spend when a phantom is making their killer drop their weapon via a haunting. Set to 0 to disable", 1, 100)
local phantom_killer_haunt_attack_cost = CreateConVar("ttt_phantom_killer_haunt_attack_cost", "100", FCVAR_NONE, "The amount of power to spend when a phantom is making their killer attack via a haunting. Set to 0 to disable", 1, 100)
local phantom_killer_haunt_without_body = CreateConVar("ttt_phantom_killer_haunt_without_body", "1")

hook.Add("TTTSyncGlobals", "Phantom_TTTSyncGlobals", function()
    SetGlobalBool("ttt_phantom_killer_smoke", phantom_killer_smoke:GetBool())
    SetGlobalBool("ttt_phantom_killer_haunt", phantom_killer_haunt:GetBool())
    SetGlobalInt("ttt_phantom_killer_haunt_power_max", phantom_killer_haunt_power_max:GetInt())
    SetGlobalInt("ttt_phantom_killer_haunt_move_cost", phantom_killer_haunt_move_cost:GetInt())
    SetGlobalInt("ttt_phantom_killer_haunt_attack_cost", phantom_killer_haunt_attack_cost:GetInt())
    SetGlobalInt("ttt_phantom_killer_haunt_jump_cost", phantom_killer_haunt_jump_cost:GetInt())
    SetGlobalInt("ttt_phantom_killer_haunt_drop_cost", phantom_killer_haunt_drop_cost:GetInt())
end)

--------------
-- HAUNTING --
--------------

local deadPhantoms = {}
hook.Add("TTTPrepareRound", "Phantom_TTTPrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        v:SetNWBool("Haunted", false)
        v:SetNWBool("Haunting", false)
        v:SetNWString("HauntingTarget", nil)
        v:SetNWInt("HauntingPower", 0)
        timer.Remove(v:Nick() .. "HauntingPower")
        timer.Remove(v:Nick() .. "HauntingSpectate")
    end
    deadPhantoms = {}
end)

local function ResetPlayer(ply)
    -- If this player is haunting someone else, make sure to clear them of the haunt too
    if ply:GetNWBool("Haunting", false) then
        local sid = ply:GetNWString("HauntingTarget", nil)
        if sid then
            local target = player.GetBySteamID64(sid)
            if IsPlayer(target) then
                target:SetNWBool("Haunted", false)
            end
        end
    end
    ply:SetNWBool("Haunting", false)
    ply:SetNWString("HauntingTarget", nil)
    ply:SetNWInt("HauntingPower", 0)
    timer.Remove(ply:Nick() .. "HauntingPower")
    timer.Remove(ply:Nick() .. "HauntingSpectate")
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
    if tgt:IsPhantom() and tgt:GetNWString("HauntingTarget", nil) == ply:SteamID64() then
        ply:SetNWBool("Haunted", false)
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
    if valid_kill and victim:IsPhantom() and not victim:IsZombifying() then
        attacker:SetNWBool("Haunted", true)

        if phantom_killer_haunt:GetBool() then
            victim:SetNWBool("Haunting", true)
            victim:SetNWString("HauntingTarget", attacker:SteamID64())
            victim:SetNWInt("HauntingPower", phantom_killer_haunt_power_starting:GetInt())
            timer.Create(victim:Nick() .. "HauntingPower", 1, 0, function()
                -- If haunting without a body is disabled, check to make sure the body exists still
                if not phantom_killer_haunt_without_body:GetBool() then
                    local phantomBody = victim.server_ragdoll or victim:GetRagdollEntity()
                    if not IsValid(phantomBody) then
                        timer.Remove(victim:Nick() .. "HauntingPower")
                        timer.Remove(victim:Nick() .. "HauntingSpectate")
                        attacker:SetNWBool("Haunted", false)
                        victim:SetNWBool("Haunting", false)
                        victim:SetNWString("HauntingTarget", nil)
                        victim:SetNWInt("HauntingPower", 0)

                        victim:PrintMessage(HUD_PRINTCENTER, "Your body has been destroyed, removing your tether to the world.")
                        victim:PrintMessage(HUD_PRINTTALK, "Your body has been destroyed, removing your tether to the world.")
                        return
                    end
                end

                -- Make sure the victim is still in the correct spectate mode
                local spec_mode = victim:GetObserverMode()
                if spec_mode ~= OBS_MODE_CHASE and spec_mode ~= OBS_MODE_IN_EYE then
                    victim:Spectate(OBS_MODE_CHASE)
                end

                local power = victim:GetNWInt("HauntingPower", 0)
                local power_rate = phantom_killer_haunt_power_rate:GetInt()
                local new_power = math.Clamp(power + power_rate, 0, phantom_killer_haunt_power_max:GetInt())
                victim:SetNWInt("HauntingPower", new_power)
            end)

            -- Lock the victim's view on their attacker
            timer.Create(victim:Nick() .. "HauntingSpectate", 1, 1, function()
                victim:SetRagdollSpec(false)
                victim:Spectate(OBS_MODE_CHASE)
                victim:SpectateEntity(attacker)
            end)
        end

        -- Delay this message so the player can see the target update message
        if attacker:ShouldDelayAnnouncements() then
            timer.Simple(3, function()
                attacker:PrintMessage(HUD_PRINTCENTER, "You have been haunted.")
            end)
        else
            attacker:PrintMessage(HUD_PRINTCENTER, "You have been haunted.")
        end
        victim:PrintMessage(HUD_PRINTCENTER, "Your attacker has been haunted.")
        if phantom_announce_death:GetBool() then
            for _, v in pairs(GetAllPlayers()) do
                if v ~= attacker and v:IsDetectiveLike() and v:Alive() and not v:IsSpec() then
                    v:PrintMessage(HUD_PRINTCENTER, "The " .. ROLE_STRINGS[ROLE_PHANTOM] .. " has been killed.")
                end
            end
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
    if ply:GetNWBool("Haunting", false) and IsValid(tgt) and tgt:Alive() and not tgt:IsSpec() then
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

        return true, "HauntingPower"
    end
end)

-------------
-- RESPAWN --
-------------

hook.Add("DoPlayerDeath", "Phantom_DoPlayerDeath", function(ply, attacker, dmginfo)
    if ply:IsSpec() then return end

    if ply:GetNWBool("Haunted", false) then
        local respawn = false
        local phantomUsers = table.GetKeys(deadPhantoms)
        for _, key in pairs(phantomUsers) do
            local phantom = deadPhantoms[key]
            if phantom.attacker == ply:SteamID64() and IsValid(phantom.player) then
                local deadPhantom = phantom.player
                deadPhantom:SetNWBool("Haunting", false)
                deadPhantom:SetNWString("HauntingTarget", nil)
                deadPhantom:SetNWInt("HauntingPower", 0)
                timer.Remove(deadPhantom:Nick() .. "HauntingPower")
                timer.Remove(deadPhantom:Nick() .. "HauntingSpectate")
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
                        deadPhantom:PrintMessage(HUD_PRINTCENTER, "Your attacker died and you have been respawned.")
                        deadPhantom:PrintMessage(HUD_PRINTTALK, "Your attacker died and you have been respawned.")
                        respawn = true
                    else
                        deadPhantom:PrintMessage(HUD_PRINTCENTER, "Your attacker died but your body has been destroyed.")
                        deadPhantom:PrintMessage(HUD_PRINTTALK, "Your attacker died but your body has been destroyed.")
                    end
                end
            end
        end

        if respawn and phantom_announce_death:GetBool() then
            for _, v in pairs(GetAllPlayers()) do
                if v:IsDetectiveLike() and v:Alive() and not v:IsSpec() then
                    v:PrintMessage(HUD_PRINTCENTER, "The " .. ROLE_STRINGS[ROLE_PHANTOM] .. " has been respawned.")
                end
            end
        end

        ply:SetNWBool("Haunted", false)
        SendFullStateUpdate()
    end
end)

---------------
-- FOOTSTEPS --
---------------

hook.Add("PlayerFootstep", "Phantom_PlayerFootstep", function(ply, pos, foot, sound, volume, rf)
    if not IsValid(ply) or ply:IsSpec() or not ply:Alive() then return true end
    if ply:WaterLevel() ~= 0 then return end
    if not ply:GetNWBool("Haunted", false) then return end

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
    net.Broadcast()
end)