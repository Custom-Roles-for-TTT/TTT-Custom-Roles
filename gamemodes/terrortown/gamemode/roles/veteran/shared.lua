AddCSLuaFile()

-- Initialize role features
ROLE_IS_ACTIVE[ROLE_VETERAN] = function(ply)
    if ply:IsVeteran() then return ply:GetNWBool("VeteranActive", false) end
end