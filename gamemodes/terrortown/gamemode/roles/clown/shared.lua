AddCSLuaFile()

local table = table

-- Initialize role features
ROLE_SHOULD_ACT_LIKE_JESTER[ROLE_CLOWN] = function(ply)
    return not ply:IsRoleActive()
end
ROLE_IS_ACTIVE[ROLE_CLOWN] = function(ply)
    return ply:GetNWBool("KillerClownActive", false)
end

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_clown_hide_when_active", "0", FCVAR_REPLICATED)
CreateConVar("ttt_clown_use_traps_when_active", "0", FCVAR_REPLICATED)
CreateConVar("ttt_clown_show_target_icon", "0", FCVAR_REPLICATED)

ROLE_CONVARS[ROLE_CLOWN] = {}
table.insert(ROLE_CONVARS[ROLE_CLOWN], {
    cvar = "ttt_clown_damage_bonus",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_CLOWN], {
    cvar = "ttt_clown_activation_credits",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_CLOWN], {
    cvar = "ttt_clown_hide_when_active",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_CLOWN], {
    cvar = "ttt_clown_use_traps_when_active",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_CLOWN], {
    cvar = "ttt_clown_show_target_icon",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_CLOWN], {
    cvar = "ttt_clown_heal_on_activate",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_CLOWN], {
    cvar = "ttt_clown_heal_bonus",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})