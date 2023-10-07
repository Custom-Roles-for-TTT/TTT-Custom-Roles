if SERVER then
    AddCSLuaFile("cl_init.lua")
    AddCSLuaFile("shared.lua")
end

local hook = hook
local table = table

EQUIP_TRK_TRACKRADAR = EQUIP_TRK_TRACKRADAR or GenerateNewEquipmentID()
local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_TRACKER] = {
            EQUIP_TRK_TRACKRADAR
        }
    end

    if EquipmentItems then
        if not EquipmentItems[ROLE_TRACKER] then
            EquipmentItems[ROLE_TRACKER] = {}
        end

        -- If we haven't already registered this item, add it to the list
        if not table.HasItemWithPropertyValue(EquipmentItems[ROLE_TRACKER], "id", EQUIP_TRK_TRACKRADAR) then
            table.insert(EquipmentItems[ROLE_TRACKER], {
                id = EQUIP_TRK_TRACKRADAR,
                type = "item_active",
                material = "vgui/ttt/icon_track_radar",
                name = "item_track_radar",
                desc = "item_track_radar_desc"
            })
        end
    end
end
InitializeEquipment()

hook.Add("Initialize", "Tracker_TrackRadar_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Tracker_TrackRadar_TTTPrepareRound", function()
    InitializeEquipment()
end)