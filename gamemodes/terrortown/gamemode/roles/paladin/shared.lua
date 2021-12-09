AddCSLuaFile()

local hook = hook

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_PALADIN] = {
            EQUIP_ARMOR,
            EQUIP_RADAR
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Paladin_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Paladin_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)