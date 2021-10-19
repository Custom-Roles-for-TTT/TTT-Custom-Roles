AddCSLuaFile()

-- Initialize role features
ROLE_SELECTION_PREDICATE[ROLE_MADSCIENTIST] = function()
    -- Mad Scientist can only spawn with independent zombies
    return INDEPENDENT_ROLES[ROLE_ZOMBIE]
end