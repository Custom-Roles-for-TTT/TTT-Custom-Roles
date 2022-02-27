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