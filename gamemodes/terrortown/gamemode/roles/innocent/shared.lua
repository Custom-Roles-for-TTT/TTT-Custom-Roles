AddCSLuaFile()

local hook = hook

local AddHook = hook.Add

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_INNOCENT] = {
            EQUIP_ARMOR,
            EQUIP_RADAR
        }
    end
end
InitializeEquipment()

AddHook("Initialize", "Innocent_Shared_Initialize", InitializeEquipment)
AddHook("TTTPrepareRound", "Innocent_Shared_TTTPrepareRound", InitializeEquipment)