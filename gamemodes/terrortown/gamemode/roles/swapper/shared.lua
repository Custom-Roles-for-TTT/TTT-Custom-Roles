AddCSLuaFile()

local table = table

-- Swapper weapon modes
SWAPPER_WEAPON_NONE = 0
SWAPPER_WEAPON_ROLE = 1
SWAPPER_WEAPON_ALL = 2

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_swapper_healthstation_reduce_max", "1", FCVAR_REPLICATED, "Whether the swappers's max health should be reduced to match their current health", 0, 1)
CreateConVar("ttt_swapper_killer_health", "100", FCVAR_REPLICATED, "The amount of health the swapper's killer should set to. Set to \"0\" to kill them", 0, 200)

ROLE_CONVARS[ROLE_SWAPPER] = {}
table.insert(ROLE_CONVARS[ROLE_SWAPPER], {
    cvar = "ttt_swapper_notify_mode",
    type = ROLE_CONVAR_TYPE_DROPDOWN,
    choices = {"None", "Detective and Traitor", "Traitor", "Detective", "Everyone"},
    isNumeric = true
})
table.insert(ROLE_CONVARS[ROLE_SWAPPER], {
    cvar = "ttt_swapper_notify_sound",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SWAPPER], {
    cvar = "ttt_swapper_notify_confetti",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SWAPPER], {
    cvar = "ttt_swapper_killer_health",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SWAPPER], {
    cvar = "ttt_swapper_killer_max_health",
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
    type = ROLE_CONVAR_TYPE_DROPDOWN,
    choices = {"Don't swap anything", "Swap role weapons", "Swap all weapons"},
    isNumeric = true
})
table.insert(ROLE_CONVARS[ROLE_SWAPPER], {
    cvar = "ttt_swapper_healthstation_reduce_max",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SWAPPER], {
    cvar = "ttt_swapper_swap_lovers",
    type = ROLE_CONVAR_TYPE_BOOL
})