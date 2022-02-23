AddCSLuaFile()

local table = table

------------------
-- ROLE CONVARS --
------------------

ROLE_CONVARS[ROLE_JESTER] = {}
table.insert(ROLE_CONVARS[ROLE_JESTER], {
    cvar = "ttt_jester_notify_mode",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
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