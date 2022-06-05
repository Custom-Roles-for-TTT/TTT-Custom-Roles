AddCSLuaFile()

local table = table

-- Initialize role features
ROLE_SELECTION_PREDICATE[ROLE_MADSCIENTIST] = function()
    -- Mad Scientist can only spawn with independent zombies
    return INDEPENDENT_ROLES[ROLE_ZOMBIE]
end

------------------
-- ROLE CONVARS --
------------------

ROLE_CONVARS[ROLE_MADSCIENTIST] = {}
table.insert(ROLE_CONVARS[ROLE_MADSCIENTIST], {
    cvar = "ttt_madscientist_device_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_MADSCIENTIST], {
    cvar = "ttt_madscientist_respawn_enable",
    type = ROLE_CONVAR_TYPE_BOOL
})