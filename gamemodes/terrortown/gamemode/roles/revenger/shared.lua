AddCSLuaFile()

local table = table

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_revenger_radar_timer", "15", FCVAR_REPLICATED, "How often (in seconds) the radar ping for the lover's killer should update", 1, 60)
CreateConVar("ttt_revenger_damage_bonus", "0", FCVAR_REPLICATED, "Extra damage that the revenger deals to their lover's killer (e.g. 0.5 = 50% extra damage)", 0, 1)

ROLE_CONVARS[ROLE_REVENGER] = {}
table.insert(ROLE_CONVARS[ROLE_REVENGER], {
    cvar = "ttt_revenger_radar_timer",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_REVENGER], {
    cvar = "ttt_revenger_damage_bonus",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_REVENGER], {
    cvar = "ttt_revenger_drain_health_to",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_REVENGER], {
    cvar = "ttt_revenger_drain_health_rate",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})