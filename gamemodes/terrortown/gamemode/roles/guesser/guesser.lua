AddCSLuaFile()

local util = util
local net = net
local player = player

local GetAllPlayers = player.GetAll

util.AddNetworkString("TTT_Guesser_Select_Role")

-------------------
-- ROLE FEATURES --
-------------------

net.Receive("TTT_Guesser_Select_Role", function(_, ply)
    if ply:IsActiveGuesser() then
        local role = net.ReadInt(8)
        ply:SetNWInt("TTTGuesserSelection", role)
    end
end)

-------------
-- CLEANUP --
-------------

hook.Add("TTTPrepareRound", "Cupid_TTTPrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        v:SetNWInt("TTTGuesserSelection", ROLE_NONE)
    end
end)