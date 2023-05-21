AddCSLuaFile()

local hook = hook
local math = math
local timer = timer

local GetAllPlayers = player.GetAll
local MathClamp = math.Clamp

util.AddNetworkString("TTT_UpdateShadowWins")

-------------
-- CONVARS --
-------------

local start_timer = CreateConVar("ttt_shadow_start_timer", "30", FCVAR_NONE, "How much time (in seconds) the shadow has to find their target at the start of the round", 1, 90)
local buffer_timer = CreateConVar("ttt_shadow_buffer_timer", "7", FCVAR_NONE, "How much time (in seconds) the shadow can stay of their target's radius", 1, 30)
local alive_radius = CreateConVar("ttt_shadow_alive_radius", "8", FCVAR_NONE, "The radius (in meters) from the living target that the shadow has to stay within", 1, 15)
local dead_radius = CreateConVar("ttt_shadow_dead_radius", "3", FCVAR_NONE, "The radius (in meters) from the death target that the shadow has to stay within", 1, 15)
local target_buff = CreateConVar("ttt_shadow_target_buff", "1", FCVAR_NONE, "The type of buff to shadow's target should get. 0 - None. 1 - Heal over time. 2 - Single respawn. 3 - Damage bonus", 0, 3)
local target_buff_delay = CreateConVar("ttt_shadow_target_buff_delay", "60", FCVAR_NONE, "How long (in seconds) the shadow needs to be near their target before the buff takes effect", 1, 120)
local target_buff_heal_amount = CreateConVar("ttt_shadow_target_buff_heal_amount", "5", FCVAR_NONE, "The amount of health the shadow's target should be healed per-interval", 1, 100)
local target_buff_heal_interval = CreateConVar("ttt_shadow_target_buff_heal_interval", "10", FCVAR_NONE, "How often (in seconds) the shadow's target should be healed", 1, 100)
local target_buff_respawn_delay = CreateConVar("ttt_shadow_target_buff_respawn_delay", "10", FCVAR_NONE, "How often (in seconds) before the shadow's target should respawn", 1, 120)
local target_buff_damage_bonus = CreateConVar("ttt_shadow_target_buff_damage_bonus", "0.15", FCVAR_NONE, "Damage bonus the shadow's target should get (e.g. 0.15 = 15% extra damage)", 0.05, 1)

hook.Add("TTTSyncGlobals", "Shadow_TTTSyncGlobals", function()
    SetGlobalInt("ttt_shadow_start_timer", start_timer:GetInt())
    SetGlobalInt("ttt_shadow_buffer_timer", buffer_timer:GetInt())
    SetGlobalFloat("ttt_shadow_alive_radius", alive_radius:GetFloat() * UNITS_PER_METER)
    SetGlobalFloat("ttt_shadow_dead_radius", dead_radius:GetFloat() * UNITS_PER_METER)
    SetGlobalInt("ttt_shadow_target_buff", target_buff:GetInt())
    SetGlobalInt("ttt_shadow_target_buff_delay", target_buff_delay:GetInt())
end)

-----------------------
-- TARGET ASSIGNMENT --
-----------------------

ROLE_ON_ROLE_ASSIGNED[ROLE_SHADOW] = function(ply)
    local closestTarget = nil
    local closestDistance = -1
    for _, p in pairs(GetAllPlayers()) do
        if p:Alive() and not p:IsSpec() and p ~= ply then
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
        ply:SetNWFloat("ShadowTimer", CurTime() + GetConVar("ttt_shadow_start_timer"):GetInt())
    end
end

-------------------
-- ROLE FEATURES --
-------------------

local function ClearShadowState(ply)
    ply:SetNWBool("ShadowActive", false)
    ply:SetNWString("ShadowTarget", "")
    ply:SetNWFloat("ShadowTimer", -1)
    ply:SetNWFloat("ShadowBuffTimer", -1)
    ply:SetNWBool("ShadowBuffActive", false)
    ply:SetNWBool("ShadowBuffDepleted", false)
end

local buffTimers = {}
local function ClearBuffTimer(shadow, target, sendMessage)
    if not target then return end

    local timerId = "TTTShadowBuffTimer_" .. shadow:SteamID64() .. "_" .. target:SteamID64()
    if buffTimers[timerId] then
        if sendMessage then
            local message = "You got too far from your target and stopped buffing them!"
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
    timer.Create(timerId, target_buff_heal_interval:GetInt(), 0, function()
        if not IsPlayer(target) or not target:Alive() or target:IsSpec() then return end
        local health = target:Health()
        local maxHealth = target:GetMaxHealth()

        target:SetHealth(MathClamp(health + target_buff_heal_amount:GetInt(), maxHealth))
    end)
end

local function CreateBuffTimer(shadow, target)
    local timerId = "TTTShadowBuffTimer_" .. shadow:SteamID64() .. "_" .. target:SteamID64()
    if buffTimers[timerId] then return end

    local buffDelay = target_buff_delay:GetInt()
    local message = "Stay with your target for " .. buffDelay .. " seconds to give them a buff!"
    shadow:PrintMessage(HUD_PRINTCENTER, message)
    shadow:PrintMessage(HUD_PRINTTALK, message)

    buffTimers[timerId] = true
    shadow:SetNWFloat("ShadowBuffTimer", CurTime() + buffDelay)
    timer.Create(timerId, buffDelay, 1, function()
        if not IsValid(shadow) or not IsValid(target) then return end
        if not shadow:Alive() or shadow:IsSpec() then return end
        if not target:Alive() or target:IsSpec() then return end

        local buff = target_buff:GetInt()
        if buff <= SHADOW_BUFF_NONE then return end

        message = "A buff is now active on your target. Stay with them to keep it up!"
        shadow:PrintMessage(HUD_PRINTCENTER, message)
        shadow:PrintMessage(HUD_PRINTTALK, message)

        message = "Your " .. ROLE_STRINGS[ROLE_SHADOW] .. " is buffing you. Stay with them to keep it up!"
        target:PrintMessage(HUD_PRINTCENTER, message)
        target:PrintMessage(HUD_PRINTTALK, message)

        target:SetNWBool("ShadowBuffActive", true)
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
    if target_buff:GetInt() ~= SHADOW_BUFF_DAMAGE then return end
    if not att:GetNWBool("ShadowBuffActive", false) then return end

    dmginfo:ScaleDamage(1 + target_buff_damage_bonus:GetFloat())
end)

hook.Add("PostPlayerDeath", "Shadow_Buff_PostPlayerDeath", function(ply)
    local vicSid64 = ply:SteamID64()
    -- If the player is going to respawn because they are being buffed by a shadow, start that process
    if target_buff:GetInt() == SHADOW_BUFF_RESPAWN and ply:GetNWBool("ShadowBuffActive", false) and not ply:GetNWBool("ShadowBuffDepleted", false) then
        -- Find the shadow that "belongs" to this player
        local shadow = nil
        for p, _ in ipairs(GetAllPlayers()) do
            if not p:IsShadow() then continue end
            if vicSid64 ~= p:GetNWString("ShadowTarget", "") then continue end

            shadow = p
            break
        end

        -- Just in case
        if not IsPlayer(shadow) then return end

        -- Let the player know they are going to respawn
        local respawnDelay = target_buff_respawn_delay:GetInt()
        local message = "Your " .. ROLE_STRINGS[ROLE_SHADOW] .. " will respawn you in " .. respawnDelay .. " seconds"
        ply:PrintMessage(HUD_PRINTCENTER, message)
        ply:PrintMessage(HUD_PRINTTALK, message)

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
        end)
    else
        for p, _ in ipairs(GetAllPlayers()) do
            if not p:IsShadow() then continue end
            if vicSid64 ~= p:GetNWString("ShadowTarget", "") then continue end
            ClearBuffTimer(p, ply)
        end
    end
end)

hook.Add("TTTBeginRound", "Shadow_TTTBeginRound", function()
    timer.Create("TTTShadowTimer", 0.1, 0, function()
        for _, v in pairs(GetAllPlayers()) do
            if not v:IsActiveShadow() or v:IsSpec() then continue end

            local target = player.GetBySteamID64(v:GetNWString("ShadowTarget", ""))
            local t = v:GetNWFloat("ShadowTimer", -1)
            if t > 0 and CurTime() > t then
                v:Kill()
                v:PrintMessage(HUD_PRINTCENTER, "You didn't stay close to your target!")
                v:PrintMessage(HUD_PRINTTALK, "You didn't stay close to your target!")
                v:SetNWBool("ShadowActive", false)
                v:SetNWFloat("ShadowTimer", -1)
                v:SetNWFloat("ShadowBuffTimer", -1)
                ClearBuffTimer(v, target)
            else
                local ent = target
                local radius = alive_radius:GetFloat() * UNITS_PER_METER
                local targetAlive = target:Alive() and not target:IsSpec()
                if not targetAlive then
                    ent = target.server_ragdoll or target:GetRagdollEntity()
                    radius = dead_radius:GetFloat() * UNITS_PER_METER
                end

                if not IsValid(ent) then continue end

                if v:GetPos():Distance(ent:GetPos()) <= radius then
                    if not v:GetNWBool("ShadowActive", false) then
                        v:SetNWBool("ShadowActive", true)
                    end
                    v:SetNWFloat("ShadowTimer", -1)

                    -- If the target is alive and buffs are enabled, try to create the buff timer
                    if targetAlive and target_buff:GetInt() > SHADOW_BUFF_NONE then
                        CreateBuffTimer(v, target)
                    end
                else
                    ClearBuffTimer(v, target, true)
                    if v:GetNWFloat("ShadowTimer", -1) < 0 then
                        v:SetNWFloat("ShadowTimer", CurTime() + buffer_timer:GetInt())
                    end
                end
            end
        end
    end)
end)

hook.Add("PlayerSpawn", "Shadow_PlayerSpawn", function(ply, transition)
    if ply:IsShadow() then
        ply:SetNWFloat("ShadowTimer", CurTime() + start_timer:GetInt())
    end
end)

hook.Add("PlayerDeath", "Shadow_KillCheck_PlayerDeath", function(victim, infl, attacker)
    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    if not valid_kill then return end
    if attacker:IsShadow() then return end

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

hook.Add("TTTPrepareRound", "Shadow_PrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        ClearShadowState(v)
    end
    timer.Remove("TTTShadowTimer")

    for timerId, _ in pairs(buffTimers) do
        timer.Remove(timerId)
    end
    table.Empty(buffTimers)
end)

hook.Add("TTTPlayerRoleChanged", "Shadow_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if oldRole == ROLE_SHADOW and oldRole ~= newRole then
        local target = player.GetBySteamID64(ply:GetNWString("ShadowTarget", ""))
        ClearBuffTimer(ply, target)
        ClearShadowState(ply)
    end
end)