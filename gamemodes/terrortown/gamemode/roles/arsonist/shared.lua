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