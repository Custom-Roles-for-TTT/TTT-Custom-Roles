AddCSLuaFile()

local table = table

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_jester_healthstation_reduce_max", "1", FCVAR_REPLICATED, "Whether the jester's max health should be reduced to match their current health", 0, 1)
CreateConVar("ttt_jester_win_by_traitors", "1", FCVAR_REPLICATED, "Whether the jester will win the round if they are killed by a traitor", 0, 1)

ROLE_CONVARS[ROLE_JESTER] = {}
table.insert(ROLE_CONVARS[ROLE_JESTER], {
    cvar = "ttt_jester_notify_mode",
    type = ROLE_CONVAR_TYPE_DROPDOWN,
    choices = {"None", "Detective and Traitor", "Traitor", "Detective", "Everyone"},
    isNumeric = true
})
table.insert(ROLE_CONVARS[ROLE_JESTER], {
    cvar = "ttt_jester_notify_sound",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_JESTER], {
    cvar = "ttt_jester_notify_confetti",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_JESTER], {
    cvar = "ttt_jester_win_by_traitors",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_JESTER], {
    cvar = "ttt_jester_healthstation_reduce_max",
    type = ROLE_CONVAR_TYPE_BOOL
})