AddCSLuaFile()

-- Initialize role features
ROLE_STARTING_CREDITS[ROLE_MERCENARY] = 1
local function InitializeEquipment()
    if EquipmentItems then
        local mat_dir = "vgui/ttt/"
        EquipmentItems[ROLE_MERCENARY] = {
            -- body armor
            { id = EQUIP_ARMOR,
              loadout = true, -- default equipment for mercenaries
              type = "item_passive",
              material = mat_dir .. "icon_armor",
              name = "item_armor",
              desc = "item_armor_desc"
            },

            -- radar
            { id = EQUIP_RADAR,
              type = "item_active",
              material = mat_dir .. "icon_radar",
              name = "item_radar",
              desc = "item_radar_desc"
            }
        }
    end

    if DefaultEquipment then
        DefaultEquipment[ROLE_MERCENARY] = {
            "weapon_ttt_health_station",
            "weapon_ttt_teleport",
            "weapon_ttt_confgrenade",
            "weapon_ttt_m16",
            "weapon_ttt_smokegrenade",
            "weapon_zm_mac10",
            "weapon_zm_molotov",
            "weapon_zm_pistol",
            "weapon_zm_revolver",
            "weapon_zm_rifle",
            "weapon_zm_shotgun",
            "weapon_zm_sledge",
            "weapon_ttt_glock",
            EQUIP_ARMOR,
            EQUIP_RADAR
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Mercenary_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Mercenary_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)