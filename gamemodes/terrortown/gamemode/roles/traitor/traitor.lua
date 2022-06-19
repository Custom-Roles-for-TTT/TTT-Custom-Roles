AddCSLuaFile()

local hook = hook

local GetAllPlayers = player.GetAll

-------------
-- CONVARS --
-------------

local traitor_phantom_cure = CreateConVar("ttt_traitor_phantom_cure", "0")

hook.Add("TTTSyncGlobals", "Traitor_TTTSyncGlobals", function()
    SetGlobalBool("ttt_traitor_phantom_cure", traitor_phantom_cure:GetBool())
end)

-----------------------
-- PLAYER VISIBILITY --
-----------------------

-- Add all traitors to the PVS for all players they can see via Target ID with NoZ (Traitors, Glitch)
hook.Add("SetupPlayerVisibility", "Traitors_SetupPlayerVisibility", function(ply)
    if not ply:ShouldBypassCulling() then return end
    if not ply:IsActiveTraitorTeam() then return end

    for _, v in ipairs(GetAllPlayers()) do
        if not v:IsActiveTraitorTeam() and not v:IsActiveGlitch() then continue end
        if ply:TestPVS(v) then continue end

        local pos = v:GetPos()
        if ply:IsOnScreen(pos) then
            AddOriginToPVS(pos)
        end
    end
end)