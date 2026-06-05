AddCSLuaFile()

local hook = hook
local player = player

local AddHook = hook.Add
local PlayerIterator = player.Iterator

-------------------
-- ROLE FEATURES --
-------------------

local function Quartermaster_TTTCanOrderEquipment(ply, id, is_item)
    if ply:IsQuartermaster() then
        -- Create crate
        local crate = ents.Create("ttt_qmr_crate")
        if not crate:IsValid() then return false end

        -- Technically need to check if the quartermaster is actually allowed to buy the item here before loading it but this will only matter if people specifically try to break the role with console commands
        ply:AddCredits(-1)
        ply:AddBought(id)

        local ang = ply:EyeAngles()
        crate:SetPos(ply:GetShootPos() + ang:Forward() * 50 + ang:Right() * 1 - ang:Up() * 1)
        crate:SetItem(id)
        crate:SetPlacer(ply)
        crate:Spawn()

        return false
    end
end

local blockedEvents = {
    ["blackmarket"] = "makes their role unusable",
    ["future"] = "can't consistently work with the dynamic shop events"
}
local function Quartermaster_TTTRandomatCanEventRun(event)
    if not blockedEvents[event.Id] then return end

    for _, ply in PlayerIterator() do
        if ply:IsQuartermaster() then
            return false, "There is " .. ROLE_STRINGS_EXT[ROLE_QUARTERMASTER] .. " in the round and this event " .. blockedEvents[event.Id]
        end
    end
end

-------------
-- CLEANUP --
-------------

AddHook("TTTPrepareRound", "Quartermaster_PrepareRound", function()
    for _, v in PlayerIterator() do
        v:SetNWBool("TTTQuartermasterLooted", false)
    end
end)

------------------
-- REGISTRATION --
------------------

ROLE_REGISTERED_HOOKS[ROLE_QUARTERMASTER] = {
    ["TTTCanOrderEquipment"] = Quartermaster_TTTCanOrderEquipment,
    ["TTTRandomatCanEventRun"] = Quartermaster_TTTRandomatCanEventRun
}