AddCSLuaFile()

local table = table

-- Swapper weapon modes
SWAPPER_WEAPON_NONE = 0
SWAPPER_WEAPON_ROLE = 1
SWAPPER_WEAPON_ALL = 2

------------------
-- ROLE CONVARS --
------------------

ROLE_CONVARS[ROLE_SWAPPER] = {}
table.insert(ROLE_CONVARS[ROLE_SWAPPER], {
    cvar = "ttt_jester_notify_mode",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SWAPPER], {
    cvar = "ttt_jester_notify_sound",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SWAPPER], {
    cvar = "ttt_jester_notify_confetti",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SWAPPER], {
    cvar = "ttt_swapper_killer_health",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SWAPPER], {
    cvar = "ttt_swapper_respawn_health",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SWAPPER], {
    cvar = "ttt_swapper_weapon_mode",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SWAPPER], {
    cvar = "ttt_swapper_healthstation_reduce_max",
    type = ROLE_CONVAR_TYPE_BOOL
})