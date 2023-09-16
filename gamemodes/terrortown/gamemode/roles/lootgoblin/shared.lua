AddCSLuaFile()

local hook = hook
local table = table

local TableInsert = table.insert

LOOTGOBLIN_REGEN_MODE_NONE = 0
LOOTGOBLIN_REGEN_MODE_ALWAYS = 1
LOOTGOBLIN_REGEN_MODE_STILL = 2
LOOTGOBLIN_REGEN_MODE_AFTER_DAMAGE = 3

------------------
-- ROLE CONVARS --
------------------

local lootgoblin_speed_mult = CreateConVar("ttt_lootgoblin_speed_mult", "1.2", FCVAR_REPLICATED, "The multiplier to use on the loot goblin's movement speed when they are activated (e.g. 1.2 = 120% normal speed)", 1, 2)
local lootgoblin_sprint_recovery = CreateConVar("ttt_lootgoblin_sprint_recovery", "0.12", FCVAR_REPLICATED, "The amount of stamina to recover per tick when the loot goblin is activated", 0, 1)
CreateConVar("ttt_lootgoblin_regen_mode", "2", FCVAR_REPLICATED, "Whether the loot goblin should regenerate health and using what logic. 0 - No regeneration. 1 - Constant regen while active. 2 - Regen while standing still. 3 - Regen after taking damage", 0, 3)
CreateConVar("ttt_lootgoblin_regen_delay", "0", FCVAR_REPLICATED, "The length of the delay (in seconds) before the loot goblin's health will start to regenerate", 0, 60)
CreateConVar("ttt_lootgoblin_radar_timer", "15", FCVAR_REPLICATED, "How often (in seconds) the radar ping for the loot goblin should update", 1, 60)
local lootgoblin_active_display = CreateConVar("ttt_lootgoblin_active_display", "1", FCVAR_REPLICATED, "Whether to show the loot goblin's information over their head and on the scoreboard once they are activated", 0, 1)
CreateConVar("ttt_lootgoblin_radar_enabled", "0", FCVAR_REPLICATED, "Whether the radar ping for the loot goblin should be enabled or not", 0, 1)
CreateConVar("ttt_lootgoblin_announce", "4", FCVAR_REPLICATED, "The logic to use when notifying players that a loot goblin has been revealed. 0 - Don't notify anyone. 1 - Only notify traitors and detective. 2 - Only notify traitors. 3 - Only notify detective. 4 - Notify everyone", 0, 4)
CreateConVar("ttt_lootgoblin_cackle_enabled", "1", FCVAR_REPLICATED)
CreateConVar("ttt_lootgoblin_jingle_enabled", "1", FCVAR_REPLICATED)
CreateConVar("ttt_lootgoblin_drop_timer", 0, FCVAR_REPLICATED, "How often (in seconds) the loot goblin should drop a piece of loot behind them",  0, 300)

ROLE_CONVARS[ROLE_LOOTGOBLIN] = {}
table.insert(ROLE_CONVARS[ROLE_LOOTGOBLIN], {
    cvar = "ttt_lootgoblin_notify_mode",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_LOOTGOBLIN], {
    cvar = "ttt_lootgoblin_notify_sound",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_LOOTGOBLIN], {
    cvar = "ttt_lootgoblin_notify_confetti",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_LOOTGOBLIN], {
    cvar = "ttt_lootgoblin_activation_timer",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_LOOTGOBLIN], {
    cvar = "ttt_lootgoblin_activation_timer_max",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_LOOTGOBLIN], {
    cvar = "ttt_lootgoblin_announce",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_LOOTGOBLIN], {
    cvar = "ttt_lootgoblin_size",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_LOOTGOBLIN], {
    cvar = "ttt_lootgoblin_cackle_timer_min",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_LOOTGOBLIN], {
    cvar = "ttt_lootgoblin_cackle_timer_max",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_LOOTGOBLIN], {
    cvar = "ttt_lootgoblin_cackle_enabled",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_LOOTGOBLIN], {
    cvar = "ttt_lootgoblin_weapons_dropped",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_LOOTGOBLIN], {
    cvar = "ttt_lootgoblin_jingle_enabled",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_LOOTGOBLIN], {
    cvar = "ttt_lootgoblin_speed_mult",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 1
})
table.insert(ROLE_CONVARS[ROLE_LOOTGOBLIN], {
    cvar = "ttt_lootgoblin_sprint_recovery",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_LOOTGOBLIN], {
    cvar = "ttt_lootgoblin_regen_mode",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_LOOTGOBLIN], {
    cvar = "ttt_lootgoblin_regen_rate",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_LOOTGOBLIN], {
    cvar = "ttt_lootgoblin_regen_delay",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_LOOTGOBLIN], {
    cvar = "ttt_lootgoblin_radar_enabled",
    type = ROLE_CONVAR_TYPE_BOOL,
})
table.insert(ROLE_CONVARS[ROLE_LOOTGOBLIN], {
    cvar = "ttt_lootgoblin_radar_timer",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_LOOTGOBLIN], {
    cvar = "ttt_lootgoblin_radar_delay",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_LOOTGOBLIN], {
    cvar = "ttt_lootgoblin_active_display",
    type = ROLE_CONVAR_TYPE_BOOL,
})
table.insert(ROLE_CONVARS[ROLE_LOOTGOBLIN], {
    cvar = "ttt_lootgoblin_drop_timer",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

-------------------
-- ROLE FEATURES --
-------------------

ROLE_STARTING_HEALTH[ROLE_LOOTGOBLIN] = 50
ROLE_MAX_HEALTH[ROLE_LOOTGOBLIN] = 50
ROLE_STARTING_CREDITS[ROLE_LOOTGOBLIN] = 3
ROLE_HAS_PASSIVE_WIN[ROLE_LOOTGOBLIN] = true
ROLE_IS_ACTIVE[ROLE_LOOTGOBLIN] = function(ply)
    return ply:GetNWBool("LootGoblinActive", false)
end
ROLE_SHOULD_REVEAL_ROLE_WHEN_ACTIVE[ROLE_LOOTGOBLIN] = function()
    return lootgoblin_active_display:GetBool()
end

hook.Add("TTTSprintStaminaRecovery", "LootGoblin_TTTSprintStaminaRecovery", function(ply, recovery)
    if IsPlayer(ply) and ply:IsActiveLootGoblin() and ply:IsRoleActive() then
        return lootgoblin_sprint_recovery:GetFloat()
    end
end)

hook.Add("TTTSpeedMultiplier", "LootGoblin_TTTSpeedMultiplier", function(ply, mults)
    if IsPlayer(ply) and ply:IsActiveLootGoblin() and ply:IsRoleActive() then
        TableInsert(mults, lootgoblin_speed_mult:GetFloat())
    end
end)