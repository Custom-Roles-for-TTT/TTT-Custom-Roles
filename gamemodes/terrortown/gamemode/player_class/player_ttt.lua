AddCSLuaFile()
DEFINE_BASECLASS("player_default")

local PLAYER = {}

PLAYER.WalkSpeed            = 220        -- How fast to move when not running
PLAYER.RunSpeed             = 220        -- How fast to move when running
PLAYER.JumpPower            = 160        -- How powerful our jump should be
PLAYER.CrouchedWalkSpeed    = 0.3        -- Multiply move speed by this when crouching

function PLAYER:SetupDataTables()
    self.Player:SetupDataTables()
end

player_manager.RegisterClass("player_ttt", PLAYER, "player_default")