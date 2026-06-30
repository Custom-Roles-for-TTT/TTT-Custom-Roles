AddCSLuaFile()

local hook = hook

local AddHook = hook.Add

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_TRICKSTER] = {
            EQUIP_ARMOR,
            EQUIP_RADAR
        }
    end
end
InitializeEquipment()

AddHook("Initialize", "Trickster_Shared_Initialize", InitializeEquipment)
AddHook("TTTPrepareRound", "Trickster_Shared_TTTPrepareRound", InitializeEquipment)