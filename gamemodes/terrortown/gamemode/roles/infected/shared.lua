AddCSLuaFile()

local table = table

------------------
-- ROLE CONVARS --
------------------

ROLE_CONVARS[ROLE_INFECTED] = {}
table.insert(ROLE_CONVARS[ROLE_INFECTED], {
    cvar = "ttt_infected_succumb_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_INFECTED], {
    cvar = "ttt_infected_full_health",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_INFECTED], {
    cvar = "ttt_infected_prime",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_INFECTED], {
    cvar = "ttt_infected_respawn_enable",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_INFECTED], {
    cvar = "ttt_infected_show_icon",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_INFECTED], {
    cvar = "ttt_infected_cough_enabled",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_INFECTED], {
    cvar = "ttt_infected_cough_timer_min",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_INFECTED], {
    cvar = "ttt_infected_cough_timer_max",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})