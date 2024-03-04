AddCSLuaFile()

local hook = hook

-- Initialize role features
MEDIUM_SCANNED_NONE = 0
MEDIUM_SCANNED_NAME = 1
MEDIUM_SCANNED_TEAM = 2
MEDIUM_SCANNED_ROLE = 3

MEDIUM_SEANCE_IDLE = 0
MEDIUM_SEANCE_LOCKED = 1
MEDIUM_SEANCE_SEARCHING = 2
MEDIUM_SEANCE_LOST = 3

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_MEDIUM] = {
            EQUIP_ARMOR,
            EQUIP_RADAR
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Medium_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Medium_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_medium_spirit_color", "1", FCVAR_REPLICATED)
CreateConVar("ttt_medium_spirit_vision", "1", FCVAR_REPLICATED)
CreateConVar("ttt_medium_dead_notify", "1", FCVAR_REPLICATED)
CreateConVar("ttt_medium_seance_time", "8", FCVAR_REPLICATED, "The amount of time (in seconds) the Medium's seance takes to use", 0, 60)
CreateConVar("ttt_medium_seance_max_info", "0", FCVAR_REPLICATED, "The maximum amount of information the Medium can learn from performing a seance. 0 - None, 1 - Name, 2 - Team, 3 - Role", 0, 3)

ROLE_CONVARS[ROLE_MEDIUM] = {}
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_spirit_color",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_spirit_vision",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_dead_notify",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_seance_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_seance_float_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_seance_cooldown",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_seance_distance",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_seance_max_info",
    type = ROLE_CONVAR_TYPE_DROPDOWN,
    choices = {"None", "Name", "Role", "Team"},
    isNumeric = true
})