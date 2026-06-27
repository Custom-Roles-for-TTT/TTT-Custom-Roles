if SERVER then
    AddCSLuaFile("cl_init.lua")
    AddCSLuaFile("shared.lua")
end

local hook = hook
local table = table

CreateConVar("ttt_tracker_minimap_range_multiplier",   "1", FCVAR_REPLICATED, "Multiplier for the in-game radius the minimap represents", 0.1, 10)
CreateConVar("ttt_tracker_minimap_show_colors",        "1", FCVAR_REPLICATED, "Whether players' icons are colored", 0, 1)
CreateConVar("ttt_tracker_minimap_show_facing",        "1", FCVAR_REPLICATED, "Whether players are shown as arrows or blips", 0, 1)
CreateConVar("ttt_tracker_minimap_show_outside_range", "1", FCVAR_REPLICATED, "Whether players off the minimap edge are shown", 0, 1)
CreateConVar("ttt_tracker_minimap_show_names",         "0", FCVAR_REPLICATED, "Whether players' names are shown below their icons", 0, 1)
CreateConVar("ttt_tracker_minimap_allow_enlarge",      "1", FCVAR_REPLICATED, "Whether an enlarged minimap is shown beneath the scoreboard", 0, 1)
CreateConVar("ttt_tracker_minimap_show_bodies",        "1", FCVAR_REPLICATED, "Whether dead players show on the minimap", 0, 1)

local tracker_minimap_enabled = CreateConVar("ttt_tracker_minimap_enabled", "1", FCVAR_REPLICATED, "Whether the minimap should be purchasable in the Tracker's shop", 0, 1)
local tracker_minimap_loadout = CreateConVar("ttt_tracker_minimap_loadout", "0", FCVAR_REPLICATED)

EQUIP_TRK_MINIMAP = EQUIP_TRK_MINIMAP or GenerateNewEquipmentID()
EQUIP_TRK_MINIMAP = EQUIP_TRK_MINIMAP or GenerateNewEquipmentID()

local function InitializeEquipment()
    if tracker_minimap_enabled:GetBool() then
        -- === REGISTRATION LOGIC ===
        if DefaultEquipment then
            DefaultEquipment[ROLE_TRACKER] = DefaultEquipment[ROLE_TRACKER] or {}
            if not table.HasValue(DefaultEquipment[ROLE_TRACKER], EQUIP_TRK_MINIMAP) then
                table.insert(DefaultEquipment[ROLE_TRACKER], EQUIP_TRK_MINIMAP)
            end
        end

        if EquipmentItems then
            EquipmentItems[ROLE_TRACKER] = EquipmentItems[ROLE_TRACKER] or {}

            -- If we haven't already registered this item, add it to the list. Otherwise, update it.
            if table.HasItemWithPropertyValue(EquipmentItems[ROLE_TRACKER], "id", EQUIP_TRK_MINIMAP) then
                local item = GetEquipmentItem(ROLE_TRACKER, EQUIP_TRK_MINIMAP)
                if item then
                    item.loadout = tracker_minimap_loadout:GetBool()
                end
            else
                table.insert(EquipmentItems[ROLE_TRACKER], {
                    id = EQUIP_TRK_MINIMAP,
                    loadout = tracker_minimap_loadout:GetBool(),
                    type = "item_active",
                    material = "vgui/ttt/icon_trk_minimap",
                    name = "item_trk_minimap",
                    desc = "item_trk_minimap_desc",
                    norandom = true
                })
            end
        end
    else
        if DefaultEquipment and DefaultEquipment[ROLE_TRACKER] then
            table.RemoveByValue(DefaultEquipment[ROLE_TRACKER], EQUIP_TRK_MINIMAP)
        end

        if EquipmentItems and EquipmentItems[ROLE_TRACKER] then
            for i = #EquipmentItems[ROLE_TRACKER], 1, -1 do
                if EquipmentItems[ROLE_TRACKER][i].id == EQUIP_TRK_MINIMAP then
                    table.remove(EquipmentItems[ROLE_TRACKER], i)
                end
            end
        end
    end
end
InitializeEquipment()

hook.Add("Initialize", "Tracker_Minimap_Initialize", InitializeEquipment)
hook.Add("TTTPrepareRound", "Tracker_Minimap_TTTPrepareRound", InitializeEquipment)
