AddCSLuaFile()

local table = table

-- Initialize role features
ROLE_STARTING_HEALTH[ROLE_OLDMAN] = 1
ROLE_HAS_PASSIVE_WIN[ROLE_OLDMAN] = true
ROLE_IS_ACTIVE[ROLE_OLDMAN] = function(ply)
    if ply:IsOldMan() then return ply:GetNWBool("AdrenalineRush", false) end
end

------------------
-- ROLE CONVARS --
------------------

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