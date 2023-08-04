AddCSLuaFile()

local table = table

-- Initialize role features
ARSONIST_UNDOUSED = 0
ARSONIST_DOUSING = 1
ARSONIST_DOUSING_LOSING = 2
ARSONIST_DOUSING_LOST = 3
ARSONIST_DOUSED = 4

ROLE_CAN_SEE_JESTERS[ROLE_ARSONIST] = true
ROLE_CAN_SEE_MIA[ROLE_ARSONIST] = true

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_arsonist_douse_time", "8", FCVAR_REPLICATED, "The amount of time (in seconds) the arsonist takes to douse someone", 0, 60)
CreateConVar("ttt_arsonist_douse_notify_delay_min", "10", FCVAR_REPLICATED, "The minimum delay before a player is notified they've been doused", 0, 30)
CreateConVar("ttt_arsonist_douse_notify_delay_max", "30", FCVAR_REPLICATED, "The delay delay before a player is notified they've been doused", 3, 60)
CreateConVar("ttt_detectives_search_only_arsonistdouse", "0", FCVAR_REPLICATED)

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
    cvar = "ttt_detectives_search_only_arsonistdouse",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ARSONIST], {
    cvar = "ttt_arsonist_corpse_ignite_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_ARSONIST], {
    cvar = "ttt_arsonist_can_see_jesters",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ARSONIST], {
    cvar = "ttt_arsonist_update_scoreboard",
    type = ROLE_CONVAR_TYPE_BOOL
})