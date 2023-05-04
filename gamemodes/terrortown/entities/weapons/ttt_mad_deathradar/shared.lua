if SERVER then
    AddCSLuaFile("cl_init.lua")
    AddCSLuaFile("shared.lua")
end

local hook = hook

EQUIP_MAD_DEATHRADAR = EQUIP_MAD_DEATHRADAR or GenerateNewEquipmentID()
local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_MADSCIENTIST] = {
            EQUIP_MAD_DEATHRADAR
        }
    end

    if EquipmentItems then
        if not EquipmentItems[ROLE_MADSCIENTIST] then
            EquipmentItems[ROLE_MADSCIENTIST] = {}
        end

        -- If we haven't already registered this item, add it to the list
        if not table.HasItemWithPropertyValue(EquipmentItems[ROLE_MADSCIENTIST], "id", EQUIP_MAD_DEATHRADAR) then
            table.insert(EquipmentItems[ROLE_MADSCIENTIST], {
                id = EQUIP_MAD_DEATHRADAR,
                type = "item_active",
                material = "vgui/ttt/icon_death_radar",
                name = "item_death_radar",
                desc = "item_death_radar_desc"
            })
        end
    end
end
InitializeEquipment()

hook.Add("Initialize", "MadScientist_DeathRadar_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "MadScientist_DeathRadar_TTTPrepareRound", function()
    InitializeEquipment()
end)