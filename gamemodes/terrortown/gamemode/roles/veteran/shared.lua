AddCSLuaFile()

local table = table

-- Initialize role features
ROLE_IS_ACTIVE[ROLE_VETERAN] = function(ply)
    if ply:IsVeteran() then return ply:GetNWBool("VeteranActive", false) end
end

------------------
-- ROLE CONVARS --
------------------

ROLE_CONVARS[ROLE_VETERAN] = {}
table.insert(ROLE_CONVARS[ROLE_VETERAN], {
    cvar = "ttt_veteran_damage_bonus",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_VETERAN], {
    cvar = "ttt_veteran_full_heal",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VETERAN], {
    cvar = "ttt_veteran_heal_bonus",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_VETERAN], {
    cvar = "ttt_veteran_announce",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VETERAN], {
    cvar = "ttt_veteran_activation_credits",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})