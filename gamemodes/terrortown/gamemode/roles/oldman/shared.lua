AddCSLuaFile()

-- Initialize role features
ROLE_STARTING_HEALTH[ROLE_OLDMAN] = 1
ROLE_HAS_PASSIVE_WIN[ROLE_OLDMAN] = true
ROLE_IS_ACTIVE[ROLE_OLDMAN] = function(ply)
    if ply:IsOldMan() then return ply:GetNWBool("AdrenalineRush", false) end
end