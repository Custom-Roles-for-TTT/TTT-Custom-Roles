AddCSLuaFile()

local hook = hook
local table = table
local util = util

-- Plaguemaster body search modes modes
PLAGUEMASTER_SEARCH_DONT_SHOW = 0
PLAGUEMASTER_SEARCH_SHOW_KILLED = 1
PLAGUEMASTER_SEARCH_SHOW_INFECTED = 2

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_plaguemaster_immune", 1, FCVAR_REPLICATED, "Whether the plaguemaster is immune to the plague", 0, 1)
CreateConVar("ttt_plaguemaster_plague_length", 180, FCVAR_REPLICATED, "How long (in seconds) before a player with the plague dies", 1, 300)
CreateConVar("ttt_plaguemaster_spread_distance", 500, FCVAR_REPLICATED, "The maximum distance away a player can be and still be infected", 50, 2000)
CreateConVar("ttt_plaguemaster_spread_require_los", 1, FCVAR_REPLICATED, "Whether players need to be in line-of-sight of a target to spread the plague", 0, 1)
CreateConVar("ttt_plaguemaster_spread_time", 5, FCVAR_REPLICATED, "How long (in seconds) someone with the plague needs to be near someone else before it spreads", 0, 180)
CreateConVar("ttt_plaguemaster_warning_time", 30, FCVAR_REPLICATED, "How long (in seconds) before dying to the plague that the target should be warned. Set to 0 to disable", 0, 180)
CreateConVar("ttt_plaguemaster_body_search_mode", 1, FCVAR_REPLICATED, "Whether dead bodies reveal if they had the plague when searched", 0, 2)
CreateConVar("ttt_plaguemaster_dart_replace_timer", 0, FCVAR_REPLICATED, "How long (in seconds) after the plaguemaster's infection dies out before they should receive another dart gun. Set to 0 to disable", 0, 180)

ROLE_CONVARS[ROLE_PLAGUEMASTER] = {}
table.insert(ROLE_CONVARS[ROLE_PLAGUEMASTER], {
    cvar = "ttt_plaguemaster_plague_length",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PLAGUEMASTER], {
    cvar = "ttt_plaguemaster_warning_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PLAGUEMASTER], {
    cvar = "ttt_plaguemaster_spread_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PLAGUEMASTER], {
    cvar = "ttt_plaguemaster_spread_distance",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PLAGUEMASTER], {
    cvar = "ttt_plaguemaster_spread_require_los",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_PLAGUEMASTER], {
    cvar = "ttt_plaguemaster_immune",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_PLAGUEMASTER], {
    cvar = "ttt_plaguemaster_body_search_mode",
    type = ROLE_CONVAR_TYPE_DROPDOWN,
    choices = {"Don't show", "Show if died from plague", "Show if infected"},
    isNumeric = true
})
table.insert(ROLE_CONVARS[ROLE_PLAGUEMASTER], {
    cvar = "ttt_plaguemaster_dart_replace_timer",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

-------------------
-- ROLE FEATURES --
-------------------

ROLE_CAN_SEE_MIA[ROLE_PLAGUEMASTER] = true

hook.Add("TTTCanCureableRoleSpawn", "Plaguemaster_TTTCanCureableRoleSpawn", function()
    if util.CanRoleSpawn(ROLE_PLAGUEMASTER) then
        return true
    end
end)