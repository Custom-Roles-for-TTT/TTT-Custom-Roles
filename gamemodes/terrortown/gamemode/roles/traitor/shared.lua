AddCSLuaFile()

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_TRAITOR] = {
            "weapon_ttt_c4",
            "weapon_ttt_flaregun",
            "weapon_ttt_knife",
            "weapon_ttt_phammer",
            "weapon_ttt_push",
            "weapon_ttt_radio",
            "weapon_ttt_sipistol",
            "weapon_ttt_teleport",
            "weapon_ttt_decoy",
            "weapon_pha_exorcism",
            EQUIP_ARMOR,
            EQUIP_RADAR,
            EQUIP_DISGUISE
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Traitor_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Traitor_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)

------------------
-- ROLE WEAPONS --
------------------

hook.Add("TTTUpdateRoleState", "Traitor_TTTUpdateRoleState", function()
    local phantom_device = weapons.GetStored("weapon_pha_exorcism")
    if GetGlobalBool("ttt_traitor_phantom_cure", false) then
        if not table.HasValue(phantom_device.CanBuy, ROLE_TRAITOR) then
            table.insert(phantom_device.CanBuy, ROLE_TRAITOR)
        end
    elseif table.HasValue(phantom_device.CanBuy, ROLE_TRAITOR) then
        table.RemoveByValue(phantom_device.CanBuy, ROLE_TRAITOR)
    end
end)