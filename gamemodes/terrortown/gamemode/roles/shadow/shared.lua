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
SHADOW_BUFF_STEAL_ROLE = 5

-- Shadow notification modes
SHADOW_NOTIFY_NONE = 0
SHADOW_NOTIFY_ANONYMOUS = 1
SHADOW_NOTIFY_IDENTIFY = 2

-- Shadow soul link modes
SHADOW_SOUL_LINK_NONE = 0
SHADOW_SOUL_LINK_BOTH = 1
SHADOW_SOUL_LINK_TARGET = 2

-- Shadow failure modes
SHADOW_FAILURE_KILL = 0
SHADOW_FAILURE_JESTER = 1
SHADOW_FAILURE_SWAPPER = 2

SHADOW_FORCED_PROGRESS_BAR = -2

-- Initialize role features
ROLE_HAS_PASSIVE_WIN[ROLE_SHADOW] = true
ROLE_IS_ACTIVE[ROLE_SHADOW] = function(ply)
    return ply:GetNWBool("ShadowActive", false)
end

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_shadow_start_timer", "30", FCVAR_REPLICATED, "How much time (in seconds) the shadow has to find their target at the start of the round", 1, 90)
CreateConVar("ttt_shadow_buffer_timer", "7", FCVAR_REPLICATED, "How much time (in seconds) the shadow can stay out of their target's radius", 1, 30)
CreateConVar("ttt_shadow_delay_timer_min", "0", FCVAR_REPLICATED, "Minimum time (in seconds) before the shadow is assigned a target at the start of the round", 0, 180)
CreateConVar("ttt_shadow_delay_timer_max", "0", FCVAR_REPLICATED, "Maximum time (in seconds) before the shadow is assigned a target at the start of the round", 0, 180)
CreateConVar("ttt_shadow_dead_radius", "4", FCVAR_REPLICATED, "The radius (in meters) from the death target that the shadow has to stay within", 1, 15)
CreateConVar("ttt_shadow_target_buff", "4", FCVAR_REPLICATED, "The type of buff the shadow should get while near their target for enough time. 0 - None. 1 - Heal over time. 2 - Single respawn. 3 - Damage bonus. 4 - Team join. 5 - Kill target and steal their role.", 0, 5)
CreateConVar("ttt_shadow_target_buff_delay", "90", FCVAR_REPLICATED, "How long (in seconds) the shadow needs to be near their target before the buff takes effect", 1, 120)
CreateConVar("ttt_shadow_target_buff_show_progress", "1", FCVAR_REPLICATED, "Whether to show a progress bar for the when the shadow's buff will be activated", 0, 1)
CreateConVar("ttt_shadow_soul_link", "0", FCVAR_REPLICATED, "Whether the shadow's soul should be linked to their target. 0 - Disable. 1 - Both shadow and target die if either is killed. 2 - The shadow dies if their target is killed.", 0, 2)
CreateConVar("ttt_shadow_weaken_health_to", "0", FCVAR_REPLICATED, "How low to reduce the shadow's health to when they are outside of the target circle instead of killing them. Set to 0 to disable, meaning the shadow will be killed", 0, 100)
CreateConVar("ttt_shadow_weaken_health_to_death", "0", FCVAR_REPLICATED, "Whether to kill the shadow one tick after they reach 1HP when \"ttt_shadow_weaken_health_to\" is set to 1", 0, 1)
CreateConVar("ttt_shadow_target_notify_mode", "0", FCVAR_REPLICATED, "How the shadow's target should be notified they have a shadow. 0 - Don't notify. 1 - Anonymously notify. 2 - Identify the shadow.", 0, 2)
CreateConVar("ttt_shadow_failure_mode", "0", FCVAR_REPLICATED, "How to handle the shadow failing to stay near their target. 0 - Kill them. 1 - Change them to be a jester. 2 - Change them to be a swapper. Not used when \"ttt_shadow_weaken_health_to\" is enabled", 0, 2)

CreateConVar("ttt_sponge_device_for_shadow", "0", FCVAR_REPLICATED, "Whether the shadow should get the spongifier", 0, 1)

local shadow_alive_radius = CreateConVar("ttt_shadow_alive_radius", "10", FCVAR_REPLICATED, "The radius (in meters) from the living target that the shadow has to stay within", 1, 15)
local shadow_speed_mult = CreateConVar("ttt_shadow_speed_mult", "1.1", FCVAR_REPLICATED, "The minimum multiplier to use on the shadow's sprint speed when they are outside of their target radius (e.g. 1.1 = 110% normal speed)", 1, 2)
local shadow_speed_mult_max = CreateConVar("ttt_shadow_speed_mult_max", "1.5", FCVAR_REPLICATED, "The maximum multiplier to use on the shadow's sprint speed when they are FAR outside of their target radius (e.g. 1.5 = 150% normal speed)", 1, 2)
local shadow_sprint_recovery = CreateConVar("ttt_shadow_sprint_recovery", "0.1", FCVAR_REPLICATED, "The minimum amount of stamina to recover per tick when the shadow is outside of their target radius", 0, 1)
local shadow_sprint_recovery_max = CreateConVar("ttt_shadow_sprint_recovery_max", "0.5", FCVAR_REPLICATED, "The maximum amount of stamina to recover per tick when the shadow is FAR outside of their target radius", 0, 1)
local shadow_is_jester = CreateConVar("ttt_shadow_is_jester", "0", FCVAR_REPLICATED, "Whether shadows should be treated as members of the jester team", 0, 1)

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
    cvar = "ttt_shadow_delay_timer_min",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_delay_timer_max",
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
    type = ROLE_CONVAR_TYPE_DROPDOWN,
    choices = {"None", "Heal over time", "Single respawn", "Damage bonus", "Team join", "Kill and role steal"},
    isNumeric = true
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_target_buff_resumable",
    type = ROLE_CONVAR_TYPE_BOOL
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
    cvar = "ttt_shadow_target_buff_show_progress",
    type = ROLE_CONVAR_TYPE_BOOL
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
    cvar = "ttt_shadow_target_traitor",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_target_monster",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_target_notify_mode",
    type = ROLE_CONVAR_TYPE_DROPDOWN,
    choices = {"Don't notify", "Anonymously notify", "Identify the shadow"},
    isNumeric = true
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_soul_link",
    type = ROLE_CONVAR_TYPE_DROPDOWN,
    choices = {"Disable", "Shadow and Target Die Together", "Shadow Dies if Target Killed"},
    isNumeric = true
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_weaken_health_to",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_weaken_health_to_death",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_weaken_timer",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_can_see_jesters",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_update_scoreboard",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_is_jester",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_failure_mode",
    type = ROLE_CONVAR_TYPE_DROPDOWN,
    choices = {"Kill", "Become Jester", "Become Swapper"},
    isNumeric = true
})

-- Add this convar to the Sponge's table so it's with the others
if not ROLE_CONVARS[ROLE_SPONGE] then
    ROLE_CONVARS[ROLE_SPONGE] = {}
end
table.insert(ROLE_CONVARS[ROLE_SPONGE], {
    cvar = "ttt_sponge_device_for_shadow",
    type = ROLE_CONVAR_TYPE_BOOL
})

-------------------
-- ROLE FEATURES --
-------------------

local sprint_regenerate_innocent
local sprint_enabled

local function ShouldHaveSprintBoost(ply)
    -- Cache this
    if not sprint_enabled then
        sprint_enabled = GetConVar("ttt_sprint_enabled")
    end

    -- Just in case we haven't loaded everything yet
    if not sprint_enabled then return false end

    -- We want to buff the shadow's speed and stamina if they are outside of the target radius
    -- When they are outside the radius a timer is shown, so we are just checking the timer status instead of doing distance math again
    return sprint_enabled:GetBool() and IsPlayer(ply) and ply:IsActiveShadow() and ply:GetNWFloat("ShadowTimer", -1) > 0
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

        local recovery_value = shadow_sprint_recovery:GetFloat()
        if recovery_value <= 0 then return end

        local max_recovery = shadow_sprint_recovery_max:GetFloat()
        if max_recovery <= 0 then return end

        -- Sanity check
        if max_recovery < recovery_value then
            max_recovery = recovery_value
        end

        -- Cache this
        if not sprint_regenerate_innocent then
            sprint_regenerate_innocent = GetConVar("ttt_sprint_regenerate_innocent")
        end

        local default_recovery = sprint_regenerate_innocent:GetFloat()
        local distance = ply:GetPos():Distance(target:GetPos())
        local min_distance = shadow_alive_radius:GetFloat() * UNITS_PER_METER
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
        local speed_value = shadow_speed_mult:GetFloat() - 1
        if speed_value <= 0 then return end

        local max_speed = shadow_speed_mult_max:GetFloat()
        if max_speed <= 0 then return end

        -- Sanity check
        if max_speed < speed_value then
            max_speed = speed_value
        end

        local distance = ply:GetPos():Distance(target:GetPos())
        local min_distance = shadow_alive_radius:GetFloat() * UNITS_PER_METER
        local scaled_speed = ScaleSprintValue(speed_value, 1, max_speed, distance, min_distance)
        TableInsert(mults, scaled_speed)
    end
end)

-------------------
-- ROLE FEATURES --
-------------------

hook.Add("TTTUpdateRoleState", "Shadow_TTTUpdateRoleState", function()
    local is_jester = shadow_is_jester:GetBool()
    JESTER_ROLES[ROLE_SHADOW] = is_jester
    INDEPENDENT_ROLES[ROLE_SHADOW] = not is_jester
end)

hook.Add("TTTIsPlayerRespawning", "Shadow_TTTIsPlayerRespawning", function(ply)
    if not IsPlayer(ply) then return end
    if ply:Alive() then return end

    if ply:GetNWBool("ShadowTargetRespawning", false) then
        return true
    end
end)