AddCSLuaFile()

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_PARAMEDIC] = {
            "weapon_med_defib"
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Paramedic_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Paramedic_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)

------------------
-- ROLE WEAPONS --
------------------

hook.Add("TTTUpdateRoleState", "Paramedic_TTTUpdateRoleState", function()
    local paramedic_defib = weapons.GetStored("weapon_med_defib")
    if GetGlobalBool("ttt_paramedic_device_loadout", false) then
        paramedic_defib.InLoadoutFor = table.Copy(paramedic_defib.InLoadoutForDefault)
    else
        table.Empty(paramedic_defib.InLoadoutFor)
    end
    if GetGlobalBool("ttt_paramedic_device_shop", false) then
        paramedic_defib.CanBuy = {ROLE_PARAMEDIC}
    else
        paramedic_defib.CanBuy = nil
    end
end)