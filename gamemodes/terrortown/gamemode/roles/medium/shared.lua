AddCSLuaFile()

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_MEDIUM] = {
            EQUIP_ARMOR,
            EQUIP_RADAR
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Medium_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Medium_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)