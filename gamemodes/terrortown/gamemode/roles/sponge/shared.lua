AddCSLuaFile()

local table = table

-------------------
-- ROLE FEATURES --
-------------------

ROLE_STARTING_HEALTH[ROLE_SPONGE] = 150
ROLE_MAX_HEALTH[ROLE_SPONGE] = 150

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_sponge_aura_radius", "5", FCVAR_REPLICATED, "The radius of the sponge's aura in meters", 1, 30)

ROLE_CONVARS[ROLE_SPONGE] = {}
table.insert(ROLE_CONVARS[ROLE_SPONGE], {
    cvar = "ttt_sponge_aura_radius",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SPONGE], {
    cvar = "ttt_sponge_notify_mode",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SPONGE], {
    cvar = "ttt_sponge_notify_sound",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SPONGE], {
    cvar = "ttt_sponge_notify_confetti",
    type = ROLE_CONVAR_TYPE_BOOL
})