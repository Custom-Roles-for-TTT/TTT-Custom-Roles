AddCSLuaFile()

local hook = hook
local util = util

util.AddNetworkString("TTT_TurncoatTeamChange")
-------------
-- CONVARS --
-------------

local turncoat_change_health = CreateConVar("ttt_turncoat_change_health", "10", FCVAR_NONE, "The amount of health to set the turncoat to when they change teams", 1, 200)
CreateConVar("ttt_turncoat_change_max_health", "1", FCVAR_NONE, "Whether to change the turncoat's max health when they change teams", 0, 1)

hook.Add("TTTSyncGlobals", "Turncoat_TTTSyncGlobals", function()
    SetGlobalInt("ttt_turncoat_change_health", turncoat_change_health:GetInt())
end)

-------------------
-- ROLE FEATURES --
-------------------

-- Reset the role back to the innocent team
hook.Add("TTTPrepareRound", "Turncoat_PrepareRound", function()
    SetTurncoatTeam(nil, false)
end)