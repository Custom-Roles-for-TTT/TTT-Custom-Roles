AddCSLuaFile()

local hook = hook
local ipairs = ipairs
local player = player

local GetAllPlayers = player.GetAll

-----------------------
-- PLAYER VISIBILITY --
-----------------------

-- Add all monsters to the PVS for other monsters since they can see eachother
hook.Add("SetupPlayerVisibility", "Monsters_SetupPlayerVisibility", function(ply)
    if not ply:ShouldBypassCulling() then return end
    if not ply:IsActiveMonsterTeam() then return end

    for _, v in ipairs(GetAllPlayers()) do
        if not v:IsActiveMonsterTeam() then continue end
        if ply:TestPVS(v) then continue end

        local pos = v:GetPos()
        if ply:IsOnScreen(pos) then
            AddOriginToPVS(pos)
        end
    end
end)