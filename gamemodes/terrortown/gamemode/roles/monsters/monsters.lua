AddCSLuaFile()

local hook = hook
local player = player

local AddHook = hook.Add
local PlayerIterator = player.Iterator

-----------------------
-- PLAYER VISIBILITY --
-----------------------

-- Add all monsters to the PVS for other monsters since they can see eachother
AddHook("SetupPlayerVisibility", "Monsters_SetupPlayerVisibility", function(ply)
    if not ply:ShouldBypassCulling() then return end
    if not ply:IsActiveMonsterTeam() then return end

    for _, v in PlayerIterator() do
        if not v:IsActiveMonsterTeam() then continue end
        if ply:TestPVS(v) then continue end

        local pos = v:GetPos()
        if ply:IsOnScreen(pos) then
            AddOriginToPVS(pos)
        end
    end
end)