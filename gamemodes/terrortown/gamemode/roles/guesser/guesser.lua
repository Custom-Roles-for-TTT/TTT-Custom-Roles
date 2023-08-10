AddCSLuaFile()

local util = util
local net = net
local player = player

local GetAllPlayers = player.GetAll

util.AddNetworkString("TTT_GuesserSelectRole")
util.AddNetworkString("TTT_GuesserGuessed")

-------------------
-- ROLE FEATURES --
-------------------

net.Receive("TTT_GuesserSelectRole", function(_, ply)
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
        v:SetNWBool("TTTGuesserWasGuesser", false)
        v:SetNWString("TTTGuesserGuessedBy", "")
    end
end)