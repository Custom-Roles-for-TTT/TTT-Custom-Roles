AddCSLuaFile()

local hook = hook
local player = player

local AddHook = hook.Add
local PlayerIterator = player.Iterator

-----------------------
-- PLAYER VISIBILITY --
-----------------------

-- Add all independents to the PVS for other independents since they can see eachother
-- This sounds counter-intuitive but roles like Zombies and Vampires can duplicate when they are on the Independent team so they aren't really alone
AddHook("SetupPlayerVisibility", "Independents_SetupPlayerVisibility", function(ply)
    if not ply:ShouldBypassCulling() then return end
    if not ply:IsActiveIndependentTeam() then return end

    for _, v in PlayerIterator() do
        if not v:IsActiveIndependentTeam() then continue end
        if ply:TestPVS(v) then continue end

        local pos = v:GetPos()
        if ply:IsOnScreen(pos) then
            AddOriginToPVS(pos)
        end
    end
end)