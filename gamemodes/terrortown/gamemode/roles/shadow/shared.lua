AddCSLuaFile()

local table = table

-- Shadow buff types
SHADOW_BUFF_NONE = 0
SHADOW_BUFF_HEAL = 1
SHADOW_BUFF_RESPAWN = 2
SHADOW_BUFF_DAMAGE = 3

-- Initialize role features
ROLE_HAS_PASSIVE_WIN[ROLE_SHADOW] = true
ROLE_IS_ACTIVE[ROLE_SHADOW] = function(ply)
    return ply:GetNWBool("ShadowActive", false)
end

------------------
-- ROLE CONVARS --
------------------

ROLE_CONVARS[ROLE_SHADOW] = {}
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_start_timer",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_buffer_timer",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_alive_radius",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 1
})
table.insert(ROLE_CONVARS[ROLE_SHADOW], {
    cvar = "ttt_shadow_dead_radius",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 1
})