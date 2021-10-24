AddCSLuaFile()

-- Initialize role features
ROLE_SHOULD_SHOW_SPECTATOR_HUD[ROLE_PHANTOM] = function(ply)
    if ply:GetNWBool("Haunting") then
        return true
    end
end