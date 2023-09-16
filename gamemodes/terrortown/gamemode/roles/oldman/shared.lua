AddCSLuaFile()

local table = table

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_oldman_drain_health_to", "0", FCVAR_REPLICATED, "The amount of health to drain the old man down to. Set to 0 to disable", 0, 200)
CreateConVar("ttt_oldman_adrenaline_rush", "5", FCVAR_REPLICATED, "The time in seconds the old mans adrenaline rush lasts for. Set to 0 to disable", 0, 30)
CreateConVar("ttt_oldman_adrenaline_shotgun", "1", FCVAR_REPLICATED)
CreateConVar("ttt_oldman_adrenaline_ramble", "1", FCVAR_REPLICATED)
local oldman_hide_when_active = CreateConVar("ttt_oldman_hide_when_active", "0", FCVAR_REPLICATED)

ROLE_CONVARS[ROLE_OLDMAN] = {}
table.insert(ROLE_CONVARS[ROLE_OLDMAN], {
    cvar = "ttt_oldman_drain_health_to",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_OLDMAN], {
    cvar = "ttt_oldman_adrenaline_rush",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_OLDMAN], {
    cvar = "ttt_oldman_adrenaline_shotgun",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_OLDMAN], {
    cvar = "ttt_oldman_adrenaline_ramble",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_OLDMAN], {
    cvar = "ttt_oldman_hide_when_active",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_OLDMAN], {
    cvar = "ttt_oldman_adrenaline_shotgun_damage",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_OLDMAN], {
    cvar = "ttt_oldman_can_see_jesters",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_OLDMAN], {
    cvar = "ttt_oldman_update_scoreboard",
    type = ROLE_CONVAR_TYPE_BOOL
})

-- Initialize role features
ROLE_STARTING_HEALTH[ROLE_OLDMAN] = 1
ROLE_HAS_PASSIVE_WIN[ROLE_OLDMAN] = true
ROLE_IS_ACTIVE[ROLE_OLDMAN] = function(ply)
    return ply:GetNWBool("AdrenalineRush", false)
end
ROLE_SHOULD_REVEAL_ROLE_WHEN_ACTIVE[ROLE_OLDMAN] = function()
    return not oldman_hide_when_active:GetBool()
end