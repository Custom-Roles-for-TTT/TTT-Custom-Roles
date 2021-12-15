AddCSLuaFile()

local hook = hook
local table = table
local weapons = weapons

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_QUACK] = {
            "weapon_ttt_health_station",
            "weapon_par_cure",
            "weapon_pha_exorcism",
            "weapon_qua_bomb_station",
            "weapon_qua_station_bomb",
            "weapon_qua_fake_cure",
            EQUIP_ARMOR,
            EQUIP_RADAR,
            EQUIP_DISGUISE
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Quack_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Quack_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)

------------------
-- ROLE WEAPONS --
------------------

hook.Add("TTTUpdateRoleState", "Quack_TTTUpdateRoleState", function()
    local phantom_device = weapons.GetStored("weapon_pha_exorcism")
    if GetGlobalBool("ttt_quack_phantom_cure", false) then
        if not table.HasValue(phantom_device.CanBuy, ROLE_QUACK) then
            table.insert(phantom_device.CanBuy, ROLE_QUACK)
        end
    elseif table.HasValue(phantom_device.CanBuy, ROLE_QUACK) then
        table.RemoveByValue(phantom_device.CanBuy, ROLE_QUACK)
    end

    local station_bomb = weapons.GetStored("weapon_qua_station_bomb")
    if GetGlobalBool("ttt_quack_station_bomb", false) then
        if not table.HasValue(station_bomb.CanBuy, ROLE_QUACK) then
            table.insert(station_bomb.CanBuy, ROLE_QUACK)
        end
    elseif table.HasValue(station_bomb.CanBuy, ROLE_QUACK) then
        table.RemoveByValue(station_bomb.CanBuy, ROLE_QUACK)
    end
end)