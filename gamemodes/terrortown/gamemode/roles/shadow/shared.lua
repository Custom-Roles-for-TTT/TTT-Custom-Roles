AddCSLuaFile()

local hook = hook
local math = math
local table = table

local MathClamp = math.Clamp
local TableInsert = table.insert

-- Shadow buff types
SHADOW_BUFF_NONE = 0
SHADOW_BUFF_HEAL = 1
SHADOW_BUFF_RESPAWN = 2
SHADOW_BUFF_DAMAGE = 3
SHADOW_BUFF_TEAM_JOIN = 4

-- Shadow notification modes
SHADOW_NOTIFY_NONE = 0
SHADOW_NOTIFY_ANONYMOUS = 1
SHADOW_NOTIFY_IDENTIFY = 2

-- Shadow soul link modes
SHADOW_SOUL_LINK_NONE = 0
SHADOW_SOUL_LINK_BOTH = 1
SHADOW_SOUL_LINK_TARGET = 2

SHADOW_FORCED_PROGRESS_BAR = -2

-- Initialize role features
ROLE_HAS_PASSIVE_WIN[ROLE_SHADOW] = true
ROLE_IS_ACTIVE[ROLE_SHADOW] = function(ply)
    return ply:GetNWBool("ShadowActive", false)
end

-------------------
-- ROLE FEATURES --
-------------------

local function ShouldHaveSprintBoost(ply)
    -- We want to buff the shadow's speed and stamina if they are outside of the target radius
    -- When they are outside the radius a timer is shown, so we are just checking the timer status instead of doing distance math again
    return GetConVar("ttt_sprint_enabled"):GetBool() and IsPlayer(ply) and ply:IsActiveShadow() and ply:GetNWFloat("ShadowTimer", -1) > 0
end

local function ScaleSprintValue(value, min_value, max_value, distance, min_distance)
    local distance_diff = (distance - min_distance) / min_distance
    if distance_diff <= 0 then return value end

    -- Scale the value up based on the distance away from the target the player is
    return MathClamp(min_value + (value * distance_diff), min_value, max_value)
end

hook.Add("TTTSprintStaminaRecovery", "Shadow_TTTSprintStaminaRecovery", function(ply, recovery)
    if ShouldHaveSprintBoost(ply) then
        local target = player.GetBySteamID64(ply:GetNWString("ShadowTarget", ""))
        -- Check to make sure the target is alive
        if not IsPlayer(target) or not target:Alive() or target:IsSpec() then return end

        local recovery_value = GetGlobalFloat("ttt_shadow_sprint_recovery", 0.1)
        if recovery_value <= 0 then return end

        local max_recovery = GetGlobalFloat("ttt_shadow_sprint_recovery_max", 0.5)
        if max_recovery <= 0 then return end

        -- Sanity check
        if max_recovery < recovery_value then
            max_recovery = recovery_value
        end

        local default_recovery = GetConVar("ttt_sprint_regenerate_innocent"):GetFloat()
        local distance = ply:GetPos():Distance(target:GetPos())
        local min_distance = GetGlobalFloat("ttt_shadow_alive_radius", 419.92)
        return ScaleSprintValue(recovery_value, default_recovery, max_recovery, distance, min_distance)
    end
end)

hook.Add("TTTSpeedMultiplier", "Shadow_TTTSpeedMultiplier", function(ply, mults)
    -- Only increase this player's movement speed when they are sprinting (and all the other checks pass)
    if ShouldHaveSprintBoost(ply) and ply:GetSprinting() then
        local target = player.GetBySteamID64(ply:GetNWString("ShadowTarget", ""))
        -- Check to make sure the target is alive
        if not IsPlayer(target) or not target:Alive() or target:IsSpec() then return end

        -- Subtract 1 from the multiplier to get the bonus instead. Using the bonus makes the math easier
        local speed_value = GetGlobalFloat("ttt_shadow_speed_mult", 1.1) - 1
        if speed_value <= 0 then return end

        local max_speed = GetGlobalFloat("ttt_shadow_speed_mult_max", 1.5)
        if max_speed <= 0 then return end

        -- Sanity check
        if max_speed < speed_value then
            max_speed = speed_value
        end

        local distance = ply:GetPos():Distance(target:GetPos())
        local min_distance = GetGlobalFloat("ttt_shadow_alive_radius", 419.92)
        local scaled_speed = ScaleSprintValue(speed_value, 1, max_speed, distance, min_distance)
        TableInsert(mults, scaled_speed)
    end
end)

------------------
-- ROLE CONVARS --
------------------

ROLE_CONVARS[ROLE_SHADOW] = {}
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_start_timer",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_buffer_timer",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_alive_radius",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 1
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_dead_radius",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 1
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_target_buff",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_target_buff_notify",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_target_buff_delay",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_target_buff_heal_amount",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_target_buff_heal_interval",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_target_buff_respawn_delay",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_target_buff_damage_bonus",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_target_buff_role_copy",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_speed_mult",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 1
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_speed_mult_max",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 1
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_sprint_recovery",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_sprint_recovery_max",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_target_jester",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_target_independent",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_target_notify_mode",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_soul_link",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_weaken_health_to",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_weaken_timer",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})