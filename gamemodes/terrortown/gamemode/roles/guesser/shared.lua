AddCSLuaFile()

local table = table

------------------
-- ROLE CONVARS --
------------------

ROLE_CONVARS[ROLE_GUESSER] = {}
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