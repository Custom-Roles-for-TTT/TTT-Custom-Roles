local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_INNOCENT] = {
            EQUIP_ARMOR,
            EQUIP_RADAR
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Innocent_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Innocent_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)