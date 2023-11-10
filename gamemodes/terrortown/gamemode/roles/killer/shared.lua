AddCSLuaFile()

local hook = hook
local table = table

-- Initialize role features
ROLE_STARTING_HEALTH[ROLE_KILLER] = 150
ROLE_MAX_HEALTH[ROLE_KILLER] = 150
ROLE_STARTING_CREDITS[ROLE_KILLER] = 2
ROLE_CAN_SEE_JESTERS[ROLE_KILLER] = true
ROLE_CAN_SEE_MIA[ROLE_KILLER] = true

local function InitializeEquipment()
    if EquipmentItems then
        if not EquipmentItems[ROLE_KILLER] then
            EquipmentItems[ROLE_KILLER] = {}
        end

        local mat_dir = "vgui/ttt/"
        -- If we haven't already registered these items, add them to the list
        if not table.HasItemWithPropertyValue(EquipmentItems[ROLE_KILLER], "id", EQUIP_ARMOR) then
            table.insert(EquipmentItems[ROLE_KILLER], {
                id = EQUIP_ARMOR,
                type = "item_passive",
                material = mat_dir .. "icon_armor",
                name = "item_armor",
                desc = "item_armor_desc"
            })
        end

        if not table.HasItemWithPropertyValue(EquipmentItems[ROLE_KILLER], "id", EQUIP_RADAR) then
            table.insert(EquipmentItems[ROLE_KILLER], {
                id = EQUIP_RADAR,
                type = "item_active",
                material = mat_dir .. "icon_radar",
                name = "item_radar",
                desc = "item_radar_desc"
            })
        end

        if not table.HasItemWithPropertyValue(EquipmentItems[ROLE_KILLER], "id", EQUIP_DISGUISE) then
            table.insert(EquipmentItems[ROLE_KILLER], {
                id = EQUIP_DISGUISE,
                type = "item_active",
                material = mat_dir .. "icon_disguise",
                name = "item_disg",
                desc = "item_disg_desc"
            })
        end
    end

    if DefaultEquipment then
        DefaultEquipment[ROLE_KILLER] = {
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
            "weapon_kil_crowbar",
            "weapon_kil_knife",
            EQUIP_ARMOR,
            EQUIP_RADAR,
            EQUIP_DISGUISE
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Killer_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Killer_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_killer_knife_enabled", "1", FCVAR_REPLICATED)
CreateConVar("ttt_killer_crowbar_enabled", "1", FCVAR_REPLICATED)
CreateConVar("ttt_killer_smoke_enabled", "1", FCVAR_REPLICATED)
CreateConVar("ttt_killer_show_target_icon", "1", FCVAR_REPLICATED)
CreateConVar("ttt_killer_vision_enabled", "1", FCVAR_REPLICATED)
CreateConVar("ttt_killer_update_scoreboard", "1", FCVAR_REPLICATED)
CreateConVar("ttt_killer_warn_all", "0", FCVAR_REPLICATED)

ROLE_CONVARS[ROLE_KILLER] = {}
table.insert(ROLE_CONVARS[ROLE_KILLER], {
    cvar = "ttt_killer_knife_enabled",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_KILLER], {
    cvar = "ttt_killer_crowbar_enabled",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_KILLER], {
    cvar = "ttt_killer_smoke_enabled",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_KILLER], {
    cvar = "ttt_killer_smoke_timer",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_KILLER], {
    cvar = "ttt_killer_show_target_icon",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_KILLER], {
    cvar = "ttt_killer_damage_penalty",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_KILLER], {
    cvar = "ttt_killer_damage_reduction",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_KILLER], {
    cvar = "ttt_killer_warn_all",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_KILLER], {
    cvar = "ttt_killer_vision_enabled",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_KILLER], {
    cvar = "ttt_killer_knife_damage",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_KILLER], {
    cvar = "ttt_killer_knife_delay",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_KILLER], {
    cvar = "ttt_killer_crowbar_damage",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_KILLER], {
    cvar = "ttt_killer_crowbar_thrown_damage",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_KILLER], {
    cvar = "ttt_killer_can_see_jesters",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_KILLER], {
    cvar = "ttt_killer_update_scoreboard",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_KILLER], {
    cvar = "ttt_killer_credits_award_pct",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_KILLER], {
    cvar = "ttt_killer_credits_award_size",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_KILLER], {
    cvar = "ttt_killer_credits_award_repeat",
    type = ROLE_CONVAR_TYPE_BOOL
})