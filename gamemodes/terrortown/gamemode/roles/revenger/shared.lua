AddCSLuaFile()

local table = table

------------------
-- ROLE CONVARS --
------------------

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