AddCSLuaFile()

local hook = hook
local math = math
local timer = timer

local GetAllPlayers = player.GetAll
local MathMin = math.min

util.AddNetworkString("TTT_UpdateShadowWins")
util.AddNetworkString("TTT_ResetShadowWins")

-------------
-- CONVARS --
-------------

local shadow_target_buff_notify = CreateConVar("ttt_shadow_target_buff_notify", "0", FCVAR_NONE, "Whether the shadow's target should be notified when they are buffed", 0, 1)
local shadow_target_buff_heal_amount = CreateConVar("ttt_shadow_target_buff_heal_amount", "5", FCVAR_NONE, "The amount of health the shadow's target should be healed per-interval", 1, 100)
local shadow_target_buff_heal_interval = CreateConVar("ttt_shadow_target_buff_heal_interval", "10", FCVAR_NONE, "How often (in seconds) the shadow's target should be healed", 1, 100)
local shadow_target_buff_respawn_delay = CreateConVar("ttt_shadow_target_buff_respawn_delay", "10", FCVAR_NONE, "How often (in seconds) before the shadow's target should respawn", 1, 120)
local shadow_target_buff_damage_bonus = CreateConVar("ttt_shadow_target_buff_damage_bonus", "0.15", FCVAR_NONE, "Damage bonus the shadow's target should get (e.g. 0.15 = 15% extra damage)", 0.05, 1)
local shadow_target_buff_role_copy = CreateConVar("ttt_shadow_target_buff_role_copy", "0", FCVAR_NONE, "Whether the shadow should instead copy the role of their target if the team join buff is enabled", 0, 1)
local shadow_target_jester = CreateConVar("ttt_shadow_target_jester", "1", FCVAR_NONE, "Whether the shadow should be able to target a member of the jester team", 0, 1)
local shadow_target_independent = CreateConVar("ttt_shadow_target_independent", "1", FCVAR_NONE, "Whether the shadow should be able to target an independent player", 0, 1)
local shadow_weaken_timer = CreateConVar("ttt_shadow_weaken_timer", "3", FCVAR_NONE, "How often (in seconds) to adjust the shadow's health when they are outside of the target circle", 1, 30)

local shadow_start_timer = GetConVar("ttt_shadow_start_timer")
local shadow_buffer_timer = GetConVar("ttt_shadow_buffer_timer")
local shadow_delay_timer = GetConVar("ttt_shadow_delay_timer")
local shadow_alive_radius = GetConVar("ttt_shadow_alive_radius")
local shadow_dead_radius = GetConVar("ttt_shadow_dead_radius")
local shadow_target_buff = GetConVar("ttt_shadow_target_buff")
local shadow_target_buff_delay = GetConVar("ttt_shadow_target_buff_delay")
local shadow_soul_link = GetConVar("ttt_shadow_soul_link")
local shadow_weaken_health_to = GetConVar("ttt_shadow_weaken_health_to")
local shadow_target_notify_mode = GetConVar("ttt_shadow_target_notify_mode")
local shadow_failure_mode = GetConVar("ttt_shadow_failure_mode")

-----------------------
-- TARGET ASSIGNMENT --
-----------------------

local function OnTargetAssigned(ply, tgt)
    if not IsPlayer(ply) or not ply:IsActiveShadow() then return end

    ply:SetNWString("ShadowTarget", tgt:SteamID64())
    ply:QueueMessage(MSG_PRINTBOTH, "Your target is " .. tgt:Nick() .. ".")
    ply:SetNWFloat("ShadowTimer", CurTime() + shadow_start_timer:GetInt())
    local notifyMode = shadow_target_notify_mode:GetInt()
    if notifyMode == SHADOW_NOTIFY_ANONYMOUS then
        tgt:QueueMessage(MSG_PRINTBOTH, "You have a " .. ROLE_STRINGS[ROLE_SHADOW] .. " following you!")
    elseif notifyMode == SHADOW_NOTIFY_IDENTIFY then
        tgt:QueueMessage(MSG_PRINTBOTH, ply:Nick() .. " is your " .. ROLE_STRINGS[ROLE_SHADOW] .. "!")
    end
end

local function FindNewTarget(shadow)
    -- Don't find a target if they already have one
    local targetSid64 = shadow:GetNWString("ShadowTarget", "")
    if targetSid64 and #targetSid64 > 0 then return end

    local delay = shadow_delay_timer:GetInt()
    if delay > 0 then
        shadow:SetNWFloat("ShadowTimer", CurTime() + delay)
    -- Use a slight delay at the very minimum to make sure nothing else is changing this player's role first
    else
        delay = 0.25
    end

    -- Delay this whole thing to make sure all the validity checks are current
    timer.Simple(delay, function()
        if not IsPlayer(shadow) or not shadow:IsActiveShadow() then return end

        -- Keep their existing target, if they have one
        targetSid64 = shadow:GetNWString("ShadowTarget", "")
        local target = player.GetBySteamID64(targetSid64)
        if IsPlayer(target) then return end

        local closestTarget = nil
        local closestDistance = -1
        for _, p in pairs(GetAllPlayers()) do
            if p:Alive() and not p:IsSpec() and p ~= shadow and
                (shadow_target_jester:GetBool() or not p:IsJesterTeam()) and
                (shadow_target_independent:GetBool() or not p:IsIndependentTeam()) then
                local distance = shadow:GetPos():Distance(p:GetPos())
                if closestDistance == -1 or distance < closestDistance then
                    closestTarget = p
                    closestDistance = distance
                end
            end
        end

        if closestTarget ~= nil then
            OnTargetAssigned(shadow, closestTarget)
        end
    end)
end

ROLE_ON_ROLE_ASSIGNED[ROLE_SHADOW] = function(ply)
    FindNewTarget(ply)
end

ROLE_MOVE_ROLE_STATE[ROLE_SHADOW] = function(ply, target, keep_on_source)
    -- Make sure the shadow has a target before we copy it
    local targetSid64 = ply:GetNWString("ShadowTarget", "")
    local shadowTarget = player.GetBySteamID64(targetSid64)
    if not IsPlayer(shadowTarget) then return end

    -- Make sure the shadow's current target isn't the person we're copying state to
    -- We don't want them to shadow themselves
    if shadowTarget == target then return end

    -- Copy the target info and run the post-assignment logic
    if not keep_on_source then ply:SetNWString("ShadowTarget", "") end
    target:SetNWString("ShadowTarget", targetSid64)
    OnTargetAssigned(target, shadowTarget)
end

-------------------
-- ROLE FEATURES --
-------------------

local function ClearShadowState(ply)
    ply.TTTShadowMaxHealth = nil
    ply.TTTShadowLastMaxHealth = nil
    ply.TTTShadowKilledTarget = false
    ply:SetNWBool("ShadowActive", false)
    ply:SetNWString("ShadowTarget", "")
    ply:SetNWFloat("ShadowTimer", -1)
    ply:SetNWFloat("ShadowBuffTimer", -1)
    ply:SetNWBool("ShadowBuffActive", false)
    ply:SetNWBool("ShadowBuffDepleted", false)
    timer.Remove("TTTShadowWeakenTimer_" .. ply:SteamID64())
    timer.Remove("TTTShadowRegenTimer_" .. ply:SteamID64())
end

local buffTimers = {}
local function ClearBuffTimer(shadow, target, sendMessage)
    if not target then return end

    local timerId = "TTTShadowBuffTimer_" .. shadow:SteamID64() .. "_" .. target:SteamID64()
    if buffTimers[timerId] then
        if sendMessage then
            local message = "You got too far from your target and "
            if shadow_target_buff:GetInt() == SHADOW_BUFF_TEAM_JOIN then
                message = message .. "stopped joining their team!"
            else
                message = message .. "stopped buffing them!"
            end
            shadow:QueueMessage(MSG_PRINTBOTH, message)
        end

        shadow:SetNWFloat("ShadowBuffTimer", -1)
        target:SetNWBool("ShadowBuffActive", false)
        timer.Remove(timerId)
        buffTimers[timerId] = nil
    end
end

local function CreateHealTimer(shadow, target, timerId)
    timer.Create(timerId, shadow_target_buff_heal_interval:GetInt(), 0, function()
        if not IsPlayer(target) or not target:Alive() or target:IsSpec() then return end
        local health = target:Health()
        local maxHealth = target:GetMaxHealth()

        target:SetHealth(MathMin(health + shadow_target_buff_heal_amount:GetInt(), maxHealth))
    end)
end

local function CreateBuffTimer(shadow, target)
    local timerId = "TTTShadowBuffTimer_" .. shadow:SteamID64() .. "_" .. target:SteamID64()
    if buffTimers[timerId] then return end

    local buffDelay = shadow_target_buff_delay:GetInt()
    local message = "Stay with your target for " .. buffDelay .. " seconds to "
    if shadow_target_buff:GetInt() == SHADOW_BUFF_TEAM_JOIN then
        message = message .. "join their team!"
    else
        message = message .. "give them a buff!"
    end
    shadow:QueueMessage(MSG_PRINTBOTH, message)

    buffTimers[timerId] = true
    shadow:SetNWFloat("ShadowBuffTimer", CurTime() + buffDelay)
    timer.Create(timerId, buffDelay, 1, function()
        if not IsValid(shadow) or not IsValid(target) then return end
        if not shadow:Alive() or shadow:IsSpec() then return end
        if not target:Alive() or target:IsSpec() then return end

        local buff = shadow_target_buff:GetInt()
        if buff <= SHADOW_BUFF_NONE then return end

        target:SetNWBool("ShadowBuffActive", true)

        if buff == SHADOW_BUFF_TEAM_JOIN then
            local role = ROLE_INNOCENT
            local role_team = target:GetRoleTeam(true)
            -- Copy the player's role if the copy role convar is enabled, or they are on a team that is usually one role by itself
            if shadow_target_buff_role_copy:GetBool() or
                    role_team == ROLE_TEAM_JESTER or
                    role_team == ROLE_TEAM_INDEPENDENT or
                    role_team == ROLE_TEAM_MONSTER then
                role = target:GetRole()
            -- Otherwise, become the basic role of the target team
            elseif role_team == ROLE_TEAM_TRAITOR then
                role = ROLE_TRAITOR
            end

            shadow:QueueMessage(MSG_PRINTBOTH, "You've stayed with your target long enough to join their team! You are now " .. ROLE_STRINGS_EXT[role])

            if shadow_target_buff_notify:GetBool() then
                target:QueueMessage(MSG_PRINTBOTH, "Your " .. ROLE_STRINGS[ROLE_SHADOW] .. " has stayed with you long enough to join your team!")
            end

            shadow:SetRole(role)
            SendFullStateUpdate()

            -- Update the player's health
            SetRoleMaxHealth(shadow)
            if shadow:Health() > shadow:GetMaxHealth() then
                shadow:SetHealth(shadow:GetMaxHealth())
            end

            return
        elseif buff == SHADOW_BUFF_STEAL_ROLE then
            local role = target:GetRole()
            shadow:QueueMessage(MSG_PRINTBOTH, "You've stayed with your target long enough to steal their role! You are now " .. ROLE_STRINGS_EXT[role])

            if shadow_target_buff_notify:GetBool() then
                target:QueueMessage(MSG_PRINTBOTH, "Your " .. ROLE_STRINGS[ROLE_SHADOW] .. " has stayed with you long enough to steal your role!")
            end

            shadow:SetRole(role)
            target:MoveRoleState(shadow)
            target:SetRole(ROLE_SHADOW)
            target:StripRoleWeapons()
            shadow:StripRoleWeapons()

            target:Kill()

            local maxhealth = shadow:GetMaxHealth()
            local health = shadow:Health()
            local healthscale = health / maxhealth
            SetRoleMaxHealth(shadow)

            -- Scale the player's health to match their new max
            -- If they were at 100/100 before, they'll be at 150/150 now
            local newmaxhealth = shadow:GetMaxHealth()
            local newhealth = math.max(math.min(newmaxhealth, math.Round(newmaxhealth * healthscale, 0)), 1)
            shadow:SetHealth(newhealth)

            SendFullStateUpdate()
            return
        end

        shadow:QueueMessage(MSG_PRINTBOTH, "A buff is now active on your target. Stay with them to keep it up!")

        if shadow_target_buff_notify:GetBool() then
            target:QueueMessage(MSG_PRINTBOTH, "Your " .. ROLE_STRINGS[ROLE_SHADOW] .. " is buffing you. Stay with them to keep it up!")
        end

        if buff == SHADOW_BUFF_HEAL then
            CreateHealTimer(shadow, target, timerId)
        end
    end)
end

hook.Add("ScalePlayerDamage", "Shadow_Buff_ScalePlayerDamage", function(ply, hitgroup, dmginfo)
    local att = dmginfo:GetAttacker()
    -- Only apply damage scaling after the round starts
    if not IsPlayer(att) or GetRoundState() < ROUND_ACTIVE then return end

    -- Make sure we're buffing damage and the attacker's buff is active
    if shadow_target_buff:GetInt() ~= SHADOW_BUFF_DAMAGE then return end
    if not att:GetNWBool("ShadowBuffActive", false) then return end

    dmginfo:ScaleDamage(1 + shadow_target_buff_damage_bonus:GetFloat())
end)

hook.Add("DoPlayerDeath", "Shadow_SoulLink_DoPlayerDeath", function(ply, attacker, dmg)
    if shadow_soul_link:GetInt() == SHADOW_SOUL_LINK_NONE or not IsPlayer(ply) then return end

    -- Kill the shadow's target as well
    if ply:IsShadow() then
        -- But only if bi-directional soul link is enabled
        if shadow_soul_link:GetInt() == SHADOW_SOUL_LINK_BOTH then
            local target = player.GetBySteamID64(ply:GetNWString("ShadowTarget", ""))
            if IsPlayer(target) and target:IsActive() then
                target:Kill()
                target:QueueMessage(MSG_PRINTBOTH, ply:Nick() .. " was your " .. ROLE_STRINGS[ROLE_SHADOW] .. " and died!")
            end
        end
    else
        -- Find the shadows that "belong" to this player, and kill them
        for _, p in ipairs(GetAllPlayers()) do
            if p:IsShadow() and p:IsActive() then
                local target = player.GetBySteamID64(p:GetNWString("ShadowTarget", ""))
                if IsPlayer(target) and target == ply then
                    p:Kill()
                    p:QueueMessage(MSG_PRINTBOTH, "Your target died!")
                end
            end
        end
    end
end)

hook.Add("PostPlayerDeath", "Shadow_Buff_PostPlayerDeath", function(ply)
    local vicSid64 = ply:SteamID64()
    -- If the player is going to respawn because they are being buffed by a shadow, start that process
    if shadow_target_buff:GetInt() == SHADOW_BUFF_RESPAWN and ply:GetNWBool("ShadowBuffActive", false) and not ply:GetNWBool("ShadowBuffDepleted", false) then
        -- Find the shadow that "belongs" to this player
        local shadow = nil
        for _, p in ipairs(GetAllPlayers()) do
            if not p:IsShadow() then continue end
            if vicSid64 ~= p:GetNWString("ShadowTarget", "") then continue end

            shadow = p
            break
        end

        -- Just in case
        if not IsPlayer(shadow) then return end

        local respawnDelay = shadow_target_buff_respawn_delay:GetInt()

        -- Let the player know they are going to respawn
        if shadow_target_buff_notify:GetBool() then
            ply:QueueMessage(MSG_PRINTBOTH, "Your " .. ROLE_STRINGS[ROLE_SHADOW] .. " will respawn you in " .. respawnDelay .. " seconds")
        end

        local timerId = "TTTShadowBuffTimer_" .. shadow:SteamID64() .. "_" .. ply:SteamID64()
        timer.Create(timerId, respawnDelay, 1, function()
            if not IsValid(ply) or ply:Alive() or not ply:IsSpec() then return end

            -- Respawn them on their body so the shadow doesn't get screwed over
            local corpse = ply.server_ragdoll or ply:GetRagdollEntity()
            ply:SetNWBool("ShadowBuffDepleted", true)
            ply:SpawnForRound(true)
            ply:SetPos(FindRespawnLocation(corpse:GetPos()) or corpse:GetPos())
            ply:SetEyeAngles(Angle(0, corpse:GetAngles().y, 0))
            SafeRemoveEntity(corpse)

            if IsValid(shadow) then
                shadow:QueueMessage(MSG_PRINTBOTH, "Your target has respawned!")
            end
        end)
    else
        for _, p in ipairs(GetAllPlayers()) do
            if not p:IsShadow() then continue end
            if vicSid64 ~= p:GetNWString("ShadowTarget", "") then continue end
            ClearBuffTimer(p, ply)
        end
    end

    -- Stop weakening or regenerating a dead player
    timer.Remove("TTTShadowWeakenTimer_" .. ply:SteamID64())
    timer.Remove("TTTShadowRegenTimer_" .. ply:SteamID64())
end)

local function CreateWeakenTimer(shadow, weakenTo, weakenTimer)
    if timer.Exists("TTTShadowWeakenTimer_" .. shadow:SteamID64()) then return end

    shadow.TTTShadowMaxHealth = shadow:GetMaxHealth()
    shadow.TTTShadowLastMaxHealth = shadow.TTTShadowMaxHealth
    timer.Create("TTTShadowWeakenTimer_" .. shadow:SteamID64(), weakenTimer, 0, function()
        if not IsValid(shadow) or not shadow:Alive() or shadow:IsSpec() then return end

        local currentMaxHealth = shadow:GetMaxHealth()
        -- Something else changed their max health, this is the new maximum
        if shadow.TTTShadowLastMaxHealth ~= currentMaxHealth then
            shadow.TTTShadowMaxHealth = currentMaxHealth
        end

        if currentMaxHealth <= weakenTo then return end

        local hp = shadow:Health()
        -- Don't kill them
        if hp > 0 then
            shadow:SetHealth(hp - 1)
        end

        shadow.TTTShadowLastMaxHealth = currentMaxHealth - 1
        shadow:SetMaxHealth(shadow.TTTShadowLastMaxHealth)
    end)
end

local function CreateRegenTimer(shadow, weakenTimer)
    if timer.Exists("TTTShadowRegenTimer_" .. shadow:SteamID64()) then return end

    timer.Remove("TTTShadowWeakenTimer_" .. shadow:SteamID64())

    -- Sanity check, just in case
    if not shadow.TTTShadowMaxHealth then return end

    shadow.TTTShadowLastMaxHealth = shadow:GetMaxHealth()
    timer.Create("TTTShadowRegenTimer_" .. shadow:SteamID64(), weakenTimer, 0, function()
        if not IsValid(shadow) or not shadow:Alive() or shadow:IsSpec() then return end

        local currentMaxHealth = shadow:GetMaxHealth()
        -- Something else changed their max health, this is the new maximum
        if shadow.TTTShadowLastMaxHealth ~= currentMaxHealth then
            shadow.TTTShadowMaxHealth = currentMaxHealth
        end

        -- If we've finished regenning, stop the timer
        if currentMaxHealth >= shadow.TTTShadowMaxHealth then
            timer.Remove("TTTShadowRegenTimer_" .. shadow:SteamID64())
            return
        end

        shadow:SetHealth(shadow:Health() + 1)

        shadow.TTTShadowLastMaxHealth = currentMaxHealth + 1
        shadow:SetMaxHealth(shadow.TTTShadowLastMaxHealth)
    end)
end

hook.Add("TTTBeginRound", "Shadow_TTTBeginRound", function()
    local weakenTo = shadow_weaken_health_to:GetInt()
    local weakenTimer = shadow_weaken_timer:GetInt()
    timer.Create("TTTShadowTimer", 0.1, 0, function()
        for _, v in pairs(GetAllPlayers()) do
            if not v:IsShadow() or not v:Alive() or v:IsSpec() then continue end

            local target = player.GetBySteamID64(v:GetNWString("ShadowTarget", ""))
            if not IsPlayer(target) then continue end

            local t = v:GetNWFloat("ShadowTimer", -1)
            if t > 0 and CurTime() > t then
                local message = "You didn't stay close to your target!"
                if weakenTo > 0 then
                    message = message .. " Return to them to slowly regain your lost health!"
                    CreateWeakenTimer(v, weakenTo, weakenTimer)
                    v:SetNWFloat("ShadowTimer", SHADOW_FORCED_PROGRESS_BAR)
                else
                    local failure_mode = shadow_failure_mode:GetInt()
                    if failure_mode == SHADOW_FAILURE_JESTER or failure_mode == SHADOW_FAILURE_SWAPPER then
                        local target_role = ROLE_JESTER
                        if failure_mode == SHADOW_FAILURE_SWAPPER then
                            target_role = ROLE_SWAPPER
                        end

                        message = message .. " As punishment, you have become " .. ROLE_STRINGS_EXT[target_role]
                        v:SetRole(target_role)
                        v:StripRoleWeapons()

                        local maxhealth = v:GetMaxHealth()
                        local health = v:Health()
                        local healthscale = health / maxhealth
                        SetRoleMaxHealth(v)

                        -- Scale the player's health to match their new max
                        -- If they were at 100/100 before, they'll be at 150/150 now
                        local newmaxhealth = v:GetMaxHealth()
                        local newhealth = math.max(math.min(newmaxhealth, math.Round(newmaxhealth * healthscale, 0)), 1)
                        v:SetHealth(newhealth)

                        SendFullStateUpdate()
                    else
                        v:Kill()
                    end
                    v:SetNWBool("ShadowActive", false)
                    v:SetNWFloat("ShadowTimer", -1)
                end
                v:QueueMessage(MSG_PRINTBOTH, message)
                v:SetNWFloat("ShadowBuffTimer", -1)
                ClearBuffTimer(v, target)
            else
                local ent = target
                local radius = shadow_alive_radius:GetFloat() * UNITS_PER_METER
                local targetAlive = target:IsActive()
                if not targetAlive then
                    ent = target.server_ragdoll or target:GetRagdollEntity()
                    radius = shadow_dead_radius:GetFloat() * UNITS_PER_METER
                end

                if not IsValid(ent) then continue end

                if v:GetPos():Distance(ent:GetPos()) <= radius then
                    if not v:GetNWBool("ShadowActive", false) then
                        v:SetNWBool("ShadowActive", true)
                    end
                    v:SetNWFloat("ShadowTimer", -1)

                    -- If the target is alive and buffs are enabled, try to create the buff timer
                    if targetAlive and shadow_target_buff:GetInt() > SHADOW_BUFF_NONE then
                        CreateBuffTimer(v, target)
                    end

                    if weakenTo > 0 then
                        CreateRegenTimer(v, weakenTimer)
                    end
                else
                    ClearBuffTimer(v, target, true)
                    -- Reset the shadow timer if we're not actively weakening the player
                    if not timer.Exists("TTTShadowWeakenTimer_" .. v:SteamID64()) and v:GetNWFloat("ShadowTimer", -1) < 0 then
                        v:SetNWFloat("ShadowTimer", CurTime() + shadow_buffer_timer:GetInt())
                    end
                end
            end
        end
    end)

    net.Start("TTT_ResetShadowWins")
    net.Broadcast()
end)

hook.Add("PlayerSpawn", "Shadow_PlayerSpawn", function(ply, transition)
    if GetRoundState() ~= ROUND_ACTIVE then return end

    if ply:IsShadow() then
        -- If you killed your target, you stay dead!
        if ply.TTTShadowKilledTarget then
            ply:Kill()
            return
        end
        FindNewTarget(ply)
    end
end)

hook.Add("PlayerDeath", "Shadow_KillCheck_PlayerDeath", function(victim, infl, attacker)
    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    if not valid_kill then return end
    if not attacker:IsShadow() then return end
    if shadow_soul_link:GetInt() ~= SHADOW_SOUL_LINK_NONE then return end

    if victim:SteamID64() == attacker:GetNWString("ShadowTarget", "") then
        attacker:Kill()
        attacker:QueueMessage(MSG_PRINTBOTH, "You killed your target!")
        attacker.TTTShadowKilledTarget = true
        ClearBuffTimer(attacker, victim)
        ClearShadowState(attacker)
    end
end)

----------------
-- WIN CHECKS --
----------------

hook.Add("TTTWinCheckComplete", "Shadow_TTTWinCheckComplete", function(win_type)
    if win_type == WIN_NONE then return end
    if not player.IsRoleLiving(ROLE_SHADOW) then return end

    net.Start("TTT_UpdateShadowWins")
    net.WriteBool(true)
    net.Broadcast()
end)

-------------
-- CLEANUP --
-------------

hook.Add("TTTPrepareRound", "Shadow_TTTPrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        ClearShadowState(v)
    end
    timer.Remove("TTTShadowTimer")

    for timerId, _ in pairs(buffTimers) do
        timer.Remove(timerId)
    end
    table.Empty(buffTimers)

    net.Start("TTT_ResetShadowWins")
    net.Broadcast()
end)

hook.Add("TTTPlayerRoleChanged", "Shadow_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if oldRole == ROLE_SHADOW and oldRole ~= newRole then
        local target = player.GetBySteamID64(ply:GetNWString("ShadowTarget", ""))
        ClearBuffTimer(ply, target)
        ClearShadowState(ply)
    end
end)