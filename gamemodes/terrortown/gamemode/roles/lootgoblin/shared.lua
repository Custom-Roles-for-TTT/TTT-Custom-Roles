AddCSLuaFile()

-- Initialize role features
ROLE_STARTING_HEALTH[ROLE_LOOTGOBLIN] = 50
ROLE_MAX_HEALTH[ROLE_LOOTGOBLIN] = 50
ROLE_STARTING_CREDITS[ROLE_LOOTGOBLIN] = 3
ROLE_HAS_PASSIVE_WIN[ROLE_LOOTGOBLIN] = true
ROLE_IS_ACTIVE[ROLE_LOOTGOBLIN] = function(ply)
    if ply:IsLootGoblin() then return ply:GetNWBool("LootGoblinActive", false) end
end