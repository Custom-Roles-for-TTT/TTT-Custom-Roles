AddCSLuaFile()

local hook = hook
local timer = timer

local GetAllPlayers = player.GetAll

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
end

local buffTimers = {}
local function GetBuffTimerId(shadowSid64, targetSid64)
    return "TTTShadowBuffTimer_" .. shadowSid64 .. "_" .. targetSid64
end

local function ClearBuffTimerById(shadow, timerId)
    if buffTimers[timerId] then
        shadow:SetNWFloat("ShadowBuffTimer", -1)
        timer.Remove(timerId)
        buffTimers[timerId] = nil
    end
end

local function ClearBuffTimer(shadow, targetSid64)
    local timerId = GetBuffTimerId(shadow:SteamID64(), targetSid64)
    ClearBuffTimerById(shadow, timerId)
end

-- TODO: Show center message when buff timer starts/stops?

local function CreateBuffTimer(shadow, target, timerId)
    local buffDelay = target_buff_delay:GetInt()
    buffTimers[timerId] = true
    shadow:SetNWFloat("ShadowBuffTimer", CurTime() + buffDelay)
    timer.Create(timerId, buffDelay, 1, function()
        if not IsValid(shadow) or not IsValid(target) then return end
        if not shadow:Alive() or shadow:IsSpec() then return end
        if not target:Alive() or target:IsSpec() then return end

        local buff = target_buff:GetInt()
        if buff <= SHADOW_BUFF_NONE then return end

        -- TODO
        print("ACTIVATE BUFF", buff)
        if buff == SHADOW_BUFF_HEAL then
            print("Heal!")
        elseif buff == SHADOW_BUFF_RESPAWN then
            print("Respawn!")
        elseif buff == SHADOW_BUFF_DAMAGE then
            print("Damage!")
        end
    end)
end

hook.Add("TTTBeginRound", "Shadow_TTTBeginRound", function()
    timer.Create("TTTShadowTimer", 0.1, 0, function()
        for _, v in pairs(GetAllPlayers()) do
            if not v:IsActiveShadow() or v:IsSpec() then continue end

            local targetSid64 = v:GetNWString("ShadowTarget", "")
            local timerId = GetBuffTimerId(v:SteamID64(), targetSid64)

            local t = v:GetNWFloat("ShadowTimer", -1)
            if t > 0 and CurTime() > t then
                v:Kill()
                v:PrintMessage(HUD_PRINTCENTER, "You didn't stay close to your target!")
                v:PrintMessage(HUD_PRINTTALK, "You didn't stay close to your target!")
                v:SetNWBool("ShadowActive", false)
                v:SetNWFloat("ShadowTimer", -1)
                v:SetNWFloat("ShadowBuffTimer", -1)
                ClearBuffTimerById(v, timerId)
            else
                local target = player.GetBySteamID64(targetSid64)
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

                    -- If the target is alive and we're not already counting down to buff, do that
                    if targetAlive and not buffTimers[timerId] and target_buff:GetInt() > SHADOW_BUFF_NONE then
                        CreateBuffTimer(v, target, timerId)
                    end
                else
                    ClearBuffTimerById(v, timerId)
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

    local vicSid64 = victim:SteamID64()
    if vicSid64 == attacker:GetNWString("ShadowTarget", "") then
        attacker:Kill()
        attacker:PrintMessage(HUD_PRINTCENTER, "You killed your target!")
        attacker:PrintMessage(HUD_PRINTTALK, "You killed your target!")
        ClearBuffTimer(attacker, vicSid64)
        ClearShadowState(attacker)
    end
end)

hook.Add("PostPlayerDeath", "Shadow_BuffTimer_PostPlayerDeath", function(ply)
    local vicSid64 = ply:SteamID64()
    for p, _ in ipairs(GetAllPlayers()) do
        if not p:IsShadow() then continue end
        if vicSid64 ~= p:GetNWString("ShadowTarget", "") then continue end
        ClearBuffTimer(p, vicSid64)
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
        ClearBuffTimer(ply, ply:GetNWString("ShadowTarget", ""))
        ClearShadowState(ply)
    end
end)