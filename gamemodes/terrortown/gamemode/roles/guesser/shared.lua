AddCSLuaFile()

local table = table

-- Initialize role features
GUESSER_UNSCANNED = 0
GUESSER_SCANNED_TEAM = 1
GUESSER_SCANNED_ROLE = 2

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_guesser_can_guess_detectives", "0", FCVAR_REPLICATED, "Whether the guesser is allowed to guess detectives", 0, 1)
CreateConVar("ttt_guesser_show_team_threshold", "50", FCVAR_REPLICATED, "The amount of damage that needs to be dealt to a guesser before they learn your team", 1, 200)
CreateConVar("ttt_guesser_show_role_threshold", "100", FCVAR_REPLICATED, "The amount of damage that needs to be dealt to a guesser before they learn your role", 1, 200)
CreateConVar("ttt_guesser_warn_all", "0", FCVAR_REPLICATED)

ROLE_CONVARS[ROLE_GUESSER] = {}
table.insert(ROLE_CONVARS[ROLE_GUESSER], {
    cvar = "ttt_guesser_notify_mode",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_GUESSER], {
    cvar = "ttt_guesser_notify_sound",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_GUESSER], {
    cvar = "ttt_guesser_notify_confetti",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_GUESSER], {
    cvar = "ttt_guesser_can_guess_detectives",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_GUESSER], {
    cvar = "ttt_guesser_unguessable_roles",
    type = ROLE_CONVAR_TYPE_TEXT
})
table.insert(ROLE_CONVARS[ROLE_GUESSER], {
    cvar = "ttt_guesser_minimum_radius",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_GUESSER], {
    cvar = "ttt_guesser_show_team_threshold",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_GUESSER], {
    cvar = "ttt_guesser_show_role_threshold",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_GUESSER], {
    cvar = "ttt_guesser_warn_all",
    type = ROLE_CONVAR_TYPE_BOOL
})