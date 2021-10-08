-- Initialize role features
ROLE_SHOULD_ACT_LIKE_JESTER[ROLE_CLOWN] = function(ply)
    if ply:IsClown() then return not ply:IsRoleActive() end
end
ROLE_IS_ACTIVE[ROLE_CLOWN] = function(ply)
    if ply:IsClown() then return ply:GetNWBool("KillerClownActive", false) end
end