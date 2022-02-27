AddCSLuaFile()

local hook = hook
local table = table

local TableInsert = table.insert

-- Initialize role features
ROLE_STARTING_HEALTH[ROLE_LOOTGOBLIN] = 50
ROLE_MAX_HEALTH[ROLE_LOOTGOBLIN] = 50
ROLE_STARTING_CREDITS[ROLE_LOOTGOBLIN] = 3
ROLE_HAS_PASSIVE_WIN[ROLE_LOOTGOBLIN] = true
ROLE_IS_ACTIVE[ROLE_LOOTGOBLIN] = function(ply)
    if ply:IsLootGoblin() then return ply:GetNWBool("LootGoblinActive", false) end
end

hook.Add("TTTSpeedMultiplier", "LootGoblin_TTTSpeedMultiplier", function(ply, mults)
    if IsPlayer(ply) and ply:IsActiveLootGoblin() and ply:IsRoleActive() then
        TableInsert(mults, GetGlobalFloat("ttt_lootgoblin_speed_mult", 1.2))
    end
end)

------------------
-- ROLE CONVARS --
------------------

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