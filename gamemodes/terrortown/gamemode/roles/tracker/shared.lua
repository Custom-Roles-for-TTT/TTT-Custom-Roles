AddCSLuaFile()

local hook = hook

local AddHook = hook.Add

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_tracker_footstep_time", "15", FCVAR_REPLICATED, "The amount of time players' footsteps should show to the tracker before fading. Set to 0 to disable", 0, 60)
CreateConVar("ttt_tracker_footstep_color", "1", FCVAR_REPLICATED)
local tracker_is_innocent = CreateConVar("ttt_tracker_is_innocent", "0", FCVAR_REPLICATED, "Whether the tracker should be treated as a special innocent", 0, 1)

ROLE_CONVARS[ROLE_TRACKER] = {
    {
        cvar = "ttt_tracker_footstep_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_tracker_footstep_color",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_tracker_radar_loadout",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_tracker_is_innocent",
        type = ROLE_CONVAR_TYPE_BOOL
    }
}

-------------------
-- ROLE FEATURES --
-------------------

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_TRACKER] = {
            EQUIP_ARMOR,
            EQUIP_RADAR
        }
    end
end
InitializeEquipment()

AddHook("Initialize", "Tracker_Shared_Initialize", InitializeEquipment)
AddHook("TTTPrepareRound", "Tracker_Shared_TTTPrepareRound", InitializeEquipment)

AddHook("TTTUpdateRoleState", "Tracker_TTTUpdateRoleState", function()
    local is_innocent = tracker_is_innocent:GetBool()
    DETECTIVE_ROLES[ROLE_TRACKER] = not is_innocent
end)