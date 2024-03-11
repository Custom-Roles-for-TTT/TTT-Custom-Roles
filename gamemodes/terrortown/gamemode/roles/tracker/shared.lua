AddCSLuaFile()

local hook = hook

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_TRACKER] = {
            EQUIP_ARMOR,
            EQUIP_RADAR
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Tracker_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Tracker_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_tracker_footstep_time", "15", FCVAR_REPLICATED, "The amount of time players' footsteps should show to the tracker before fading. Set to 0 to disable", 0, 60)
CreateConVar("ttt_tracker_footstep_color", "1", FCVAR_REPLICATED)

ROLE_CONVARS[ROLE_TRACKER] = {}
table.insert(ROLE_CONVARS[ROLE_TRACKER], {
    cvar = "ttt_tracker_footstep_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_TRACKER], {
    cvar = "ttt_tracker_footstep_color",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_TRACKER], {
    cvar = "ttt_tracker_radar_loadout",
    type = ROLE_CONVAR_TYPE_BOOL
})