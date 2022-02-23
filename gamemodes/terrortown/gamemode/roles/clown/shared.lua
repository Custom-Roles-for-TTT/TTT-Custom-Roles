AddCSLuaFile()

local table = table

-- Initialize role features
ROLE_SHOULD_ACT_LIKE_JESTER[ROLE_CLOWN] = function(ply)
    if ply:IsClown() then return not ply:IsRoleActive() end
end
ROLE_IS_ACTIVE[ROLE_CLOWN] = function(ply)
    if ply:IsClown() then return ply:GetNWBool("KillerClownActive", false) end
end

------------------
-- ROLE CONVARS --
------------------

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