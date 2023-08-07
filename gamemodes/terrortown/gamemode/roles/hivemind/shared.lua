AddCSLuaFile()

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_hivemind_vision_enable", "1", FCVAR_REPLICATED)

ROLE_CONVARS[ROLE_HIVEMIND] = {}
table.insert(ROLE_CONVARS[ROLE_HIVEMIND], {
    cvar = "ttt_hivemind_vision_enable",
    type = ROLE_CONVAR_TYPE_BOOL
})