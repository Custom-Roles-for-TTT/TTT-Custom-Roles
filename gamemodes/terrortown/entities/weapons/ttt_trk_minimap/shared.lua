if SERVER then
    AddCSLuaFile("cl_init.lua")
    AddCSLuaFile("shared.lua")
end

local hook = hook
local table = table

CreateConVar("ttt_tracker_minimap_range_multiplier",   "1", FCVAR_REPLICATED, "Multiplier for the in-game radius the minimap represents", 0.1, 10)
CreateConVar("ttt_tracker_minimap_show_colours",       "1", FCVAR_REPLICATED, "Whether players' icons are coloured", 0, 1)
CreateConVar("ttt_tracker_minimap_show_facing",        "1", FCVAR_REPLICATED, "Whether players are shown as arrows or blips", 0, 1)
CreateConVar("ttt_tracker_minimap_show_outside_range", "1", FCVAR_REPLICATED, "Whether players off the minimap edge are shown", 0, 1)
CreateConVar("ttt_tracker_minimap_show_names",         "0", FCVAR_REPLICATED, "Whether players' names are shown below their icons", 0, 1)
CreateConVar("ttt_tracker_minimap_allow_enlarge",      "1", FCVAR_REPLICATED, "Whether an enlarged minimap is shown beneath the scoreboard", 0, 1)

local tracker_minimap_loadout = CreateConVar("ttt_tracker_minimap_loadout", "0", FCVAR_REPLICATED)

EQUIP_TRK_MINIMAP = EQUIP_TRK_MINIMAP or GenerateNewEquipmentID()
local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_TRACKER] = DefaultEquipment[ROLE_TRACKER] or {}
        table.insert(DefaultEquipment[ROLE_TRACKER], EQUIP_TRK_MINIMAP)
    end

    if EquipmentItems then
        if not EquipmentItems[ROLE_TRACKER] then
            EquipmentItems[ROLE_TRACKER] = {}
        end

        -- If we haven't already registered this item, add it to the list. Otherwise, update if it should be in the Tracker's loadout or not
        if table.HasItemWithPropertyValue(EquipmentItems[ROLE_TRACKER], "id", EQUIP_TRK_MINIMAP) then
            local item = GetEquipmentItem(ROLE_TRACKER, EQUIP_TRK_MINIMAP)
            item.loadout = tracker_minimap_loadout:GetBool()
        else
            table.insert(EquipmentItems[ROLE_TRACKER], {
                id = EQUIP_TRK_MINIMAP,
                loadout = tracker_minimap_loadout:GetBool(),
                type = "item_active",
                material = "vgui/ttt/icon_minimap",
                name = "item_minimap",
                desc = "item_minimap_desc",
                norandom = true
            })
        end
    end
end
InitializeEquipment()

hook.Add("Initialize", "Tracker_Minimap_Initialize", InitializeEquipment)
hook.Add("TTTPrepareRound", "Tracker_Minimap_TTTPrepareRound", InitializeEquipment)
