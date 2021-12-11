AddCSLuaFile()

local hook = hook

-------------
-- CONVARS --
-------------

local traitor_phantom_cure = CreateConVar("ttt_traitor_phantom_cure", "0")

hook.Add("TTTSyncGlobals", "Traitor_TTTSyncGlobals", function()
    SetGlobalBool("ttt_traitor_phantom_cure", traitor_phantom_cure:GetBool())
end)
