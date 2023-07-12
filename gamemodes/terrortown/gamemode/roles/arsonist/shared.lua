AddCSLuaFile()

local table = table

-- Initialize role features
ARSONIST_UNDOUSED = 0
ARSONIST_DOUSING = 1
ARSONIST_DOUSING_LOSING = 2
ARSONIST_DOUSING_LOST = 3
ARSONIST_DOUSED = 4

------------------
-- ROLE CONVARS --
------------------

ROLE_CONVARS[ROLE_ARSONIST] = {}
table.insert(ROLE_CONVARS[ROLE_ARSONIST], {
    cvar = "ttt_arsonist_douse_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_ARSONIST], {
    cvar = "ttt_arsonist_douse_distance",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_ARSONIST], {
    cvar = "ttt_arsonist_douse_notify_delay_min",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_ARSONIST], {
    cvar = "ttt_arsonist_douse_notify_delay_max",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_ARSONIST], {
    cvar = "ttt_arsonist_damage_penalty",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_ARSONIST], {
    cvar = "ttt_arsonist_burn_damage",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_ARSONIST], {
    cvar = "ttt_arsonist_early_ignite",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ARSONIST], {
    cvar = "ttt_detective_search_only_arsonistdouse",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ARSONIST], {
    cvar = "ttt_arsonist_corpse_ignite_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})