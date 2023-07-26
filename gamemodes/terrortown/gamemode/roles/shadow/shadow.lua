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
local shadow_alive_radius = GetConVar("ttt_shadow_alive_radius")
local shadow_dead_radius = GetConVar("ttt_shadow_dead_radius")
local shadow_target_buff = GetConVar("ttt_shadow_target_buff")
local shadow_target_buff_delay = GetConVar("ttt_shadow_target_buff_delay")
local shadow_soul_link = GetConVar("ttt_shadow_soul_link")
local shadow_weaken_health_to = GetConVar("ttt_shadow_weaken_health_to")
local shadow_target_notify_mode = GetConVar("ttt_shadow_target_notify_mode")

-----------------------
-- TARGET ASSIGNMENT --
-----------------------

ROLE_ON_ROLE_ASSIGNED[ROLE_SHADOW] = function(ply)
    local closestTarget = nil
    local closestDistance = -1
    for _, p in pairs(GetAllPlayers()) do
        if p:Alive() and not p:IsSpec() and p ~= ply and
            (shadow_target_jester:GetBool() or not p:IsJesterTeam()) and
            (shadow_target_independent:GetBool() or not p:IsIndependentTeam()) then
            local distance = ply:GetPos():Distance(p:GetPos())
            if closestDistance == -1 or distance < closestDistance then
                closestTarget = p
                closestDistance = distance
            end
        end
    end
    if closestTarget ~= nil then
        ply:SetNWString("ShadowTarget", closestTarget:SteamID64() or "")
        ply:PrintMessage(HUD_PRINTTALK, "Your target is " .. closestTarget:Nick() .. ".")
        ply:PrintMessage(HUD_PRINTCENTER, "Your target is " .. closestTarget:Nick() .. ".")
        ply:SetNWFloat("ShadowTimer", CurTime() + shadow_start_timer:GetInt())
        local notifyMode = shadow_target_notify_mode:GetInt()
        if notifyMode == SHADOW_NOTIFY_ANONYMOUS then
            closestTarget:PrintMessage(HUD_PRINTTALK, "You have a " .. ROLE_STRINGS[ROLE_SHADOW] .. " following you!")
            closestTarget:PrintMessage(HUD_PRINTCENTER, "You have a " .. ROLE_STRINGS[ROLE_SHADOW] .. " following you!")
        elseif notifyMode == SHADOW_NOTIFY_IDENTIFY then
            closestTarget:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " is your " .. ROLE_STRINGS[ROLE_SHADOW] .. "!")
            closestTarget:PrintMessage(HUD_PRINTCENTER, ply:Nick() .. " is your " .. ROLE_STRINGS[ROLE_SHADOW] .. "!")
        end
    end
end

-------------------
-- ROLE FEATURES --
-------------------

local function ClearShadowState(ply)
    ply.TTTShadowMaxHealth = nil
    ply.TTTShadowLastMaxHealth = nil
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
            shadow:PrintMessage(HUD_PRINTCENTER, message)
            shadow:PrintMessage(HUD_PRINTTALK, message)
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
    shadow:PrintMessage(HUD_PRINTCENTER, message)
    shadow:PrintMessage(HUD_PRINTTALK, message)

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

            message = "You've stayed with your target long enough to join their team! You are now " .. ROLE_STRINGS_EXT[role]
            shadow:PrintMessage(HUD_PRINTCENTER, message)
            shadow:PrintMessage(HUD_PRINTTALK, message)

            if shadow_target_buff_notify:GetBool() then
                message = "Your " .. ROLE_STRINGS[ROLE_SHADOW] .. " has stayed with you long enough to join your team!"
                target:PrintMessage(HUD_PRINTCENTER, message)
                target:PrintMessage(HUD_PRINTTALK, message)
            end

            shadow:SetRole(role)
            SendFullStateUpdate()

            -- Update the player's health
            SetRoleMaxHealth(shadow)
            if shadow:Health() > shadow:GetMaxHealth() then
                shadow:SetHealth(shadow:GetMaxHealth())
            end

            return
        end

        message = "A buff is now active on your target. Stay with them to keep it up!"
        shadow:PrintMessage(HUD_PRINTCENTER, message)
        shadow:PrintMessage(HUD_PRINTTALK, message)

        if shadow_target_buff_notify:GetBool() then
            message = "Your " .. ROLE_STRINGS[ROLE_SHADOW] .. " is buffing you. Stay with them to keep it up!"
            target:PrintMessage(HUD_PRINTCENTER, message)
            target:PrintMessage(HUD_PRINTTALK, message)
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
            if IsPlayer(target) and target:Alive() and not target:IsSpec() then
                target:Kill()
                local msg = ply:Nick() .. " was your " .. ROLE_STRINGS[ROLE_SHADOW] .. " and died!"
                target:PrintMessage(HUD_PRINTCENTER, msg)
                target:PrintMessage(HUD_PRINTTALK, msg)
            end
        end
    else
        -- Find the shadows that "belong" to this player, and kill them
        for _, p in ipairs(GetAllPlayers()) do
            if p:IsShadow() and p:Alive() and not p:IsSpec() then
                local target = player.GetBySteamID64(p:GetNWString("ShadowTarget", ""))
                if IsPlayer(target) and target == ply then
                    p:Kill()
                    p:PrintMessage(HUD_PRINTCENTER, "Your target died!")
                    p:PrintMessage(HUD_PRINTTALK, "Your target died!")
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
            local message = "Your " .. ROLE_STRINGS[ROLE_SHADOW] .. " will respawn you in " .. respawnDelay .. " seconds"
            ply:PrintMessage(HUD_PRINTCENTER, message)
            ply:PrintMessage(HUD_PRINTTALK, message)
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
                local message = "Your target has respawned!"
                shadow:PrintMessage(HUD_PRINTCENTER, message)
                shadow:PrintMessage(HUD_PRINTTALK, message)
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
            local t = v:GetNWFloat("ShadowTimer", -1)
            if t > 0 and CurTime() > t then
                local message = "You didn't stay close to your target!"
                if weakenTo > 0 then
                    message = message .. " Return to them to slowly regain your lost health!"
                    CreateWeakenTimer(v, weakenTo, weakenTimer)
                    v:SetNWFloat("ShadowTimer", SHADOW_FORCED_PROGRESS_BAR)
                else
                    v:Kill()
                    v:SetNWBool("ShadowActive", false)
                    v:SetNWFloat("ShadowTimer", -1)
                end
                v:PrintMessage(HUD_PRINTCENTER, message)
                v:PrintMessage(HUD_PRINTTALK, message)
                v:SetNWFloat("ShadowBuffTimer", -1)
                ClearBuffTimer(v, target)
            else
                local ent = target
                local radius = shadow_alive_radius:GetFloat() * UNITS_PER_METER
                local targetAlive = target:Alive() and not target:IsSpec()
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
        if ply:GetNWString("ShadowTarget", "") then
            ply:Kill()
        end
        ply:SetNWFloat("ShadowTimer", CurTime() + shadow_start_timer:GetInt())
    end
end)

hook.Add("PlayerDeath", "Shadow_KillCheck_PlayerDeath", function(victim, infl, attacker)
    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    if not valid_kill then return end
    if not attacker:IsShadow() then return end
    if shadow_soul_link:GetInt() ~= SHADOW_SOUL_LINK_NONE then return end

    if victim:SteamID64() == attacker:GetNWString("ShadowTarget", "") then
        attacker:Kill()
        attacker:PrintMessage(HUD_PRINTCENTER, "You killed your target!")
        attacker:PrintMessage(HUD_PRINTTALK, "You killed your target!")
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