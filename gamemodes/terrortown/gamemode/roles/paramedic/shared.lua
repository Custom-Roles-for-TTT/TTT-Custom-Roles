AddCSLuaFile()

local hook = hook
local table = table
local weapons = weapons

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
        paramedic_defib.LimitedStock = not GetGlobalBool("ttt_paramedic_device_shop_rebuyable", false)
    else
        paramedic_defib.CanBuy = nil
        paramedic_defib.LimitedStock = true
    end
end)