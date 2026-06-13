AddCSLuaFile()

local hook = hook

local AddHook = hook.Add

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_DETECTIVE] = {
            "weapon_ttt_binoculars",
            "weapon_ttt_defuser",
            "weapon_ttt_health_station",
            "weapon_ttt_stungun",
            "weapon_ttt_cse",
            "weapon_ttt_teleport",
            EQUIP_ARMOR,
            EQUIP_RADAR
        }
    end
end
InitializeEquipment()

AddHook("Initialize", "Detective_Shared_Initialize", InitializeEquipment)
AddHook("TTTPrepareRound", "Detective_Shared_TTTPrepareRound", InitializeEquipment)