AddCSLuaFile()

local hook = hook
local table = table

local AddHook = hook.Add

-- Initialize role features
INFORMANT_UNSCANNED = 0
INFORMANT_SCANNED_TEAM = 1
INFORMANT_SCANNED_ROLE = 2
INFORMANT_SCANNED_TRACKED = 3

INFORMANT_SCANNER_IDLE = 0
INFORMANT_SCANNER_LOCKED = 1
INFORMANT_SCANNER_SEARCHING = 2
INFORMANT_SCANNER_LOST = 3

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_informant_share_scans", "1", FCVAR_REPLICATED)
CreateConVar("ttt_informant_can_scan_jesters", "0", FCVAR_REPLICATED)
CreateConVar("ttt_informant_can_scan_glitches", "0", FCVAR_REPLICATED)
CreateConVar("ttt_informant_scanner_time", "8", FCVAR_REPLICATED, "The amount of time (in seconds) the informant's scanner takes to use", 0, 60)
CreateConVar("ttt_informant_scanner_innocent_mult", "1", FCVAR_REPLICATED, "The multiplier to use with the scanner time when the target is an innocent (e.g. 0.5 = 50% scanner time)", 0, 2)
CreateConVar("ttt_informant_scanner_traitor_mult", "1", FCVAR_REPLICATED, "The multiplier to use with the scanner time when the target is a traitor (e.g. 0.5 = 50% scanner time)", 0, 2)
CreateConVar("ttt_informant_scanner_jester_mult", "1", FCVAR_REPLICATED, "The multiplier to use with the scanner time when the target is a jester (e.g. 0.5 = 50% scanner time)", 0, 2)
CreateConVar("ttt_informant_scanner_independent_mult", "1", FCVAR_REPLICATED, "The multiplier to use with the scanner time when the target is an independent (e.g. 0.5 = 50% scanner time)", 0, 2)
CreateConVar("ttt_informant_scanner_monster_mult", "1", FCVAR_REPLICATED, "The multiplier to use with the scanner time when the target is a monster (e.g. 0.5 = 50% scanner time)", 0, 2)
local informant_requires_scanner = CreateConVar("ttt_informant_requires_scanner", "0", FCVAR_REPLICATED)

ROLE_CONVARS[ROLE_INFORMANT] = {
    {
        cvar = "ttt_informant_share_scans",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_informant_can_scan_jesters",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_informant_can_scan_glitches",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_informant_requires_scanner",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_informant_requires_scanner",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_informant_scanner_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_informant_scanner_innocent_mult",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_informant_scanner_traitor_mult",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_informant_scanner_jester_mult",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_informant_scanner_independent_mult",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_informant_scanner_monster_mult",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_informant_scanner_float_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_informant_scanner_cooldown",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_informant_scanner_distance",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    }
}

-----------------
-- ROLE WEAPON --
-----------------

AddHook("TTTUpdateRoleState", "Informant_TTTUpdateRoleState", function()
    local informant_scanner = weapons.GetStored("weapon_inf_scanner")
    if informant_requires_scanner:GetBool() then
        informant_scanner.InLoadoutFor = table.Copy(informant_scanner.InLoadoutForDefault)
    else
        table.Empty(informant_scanner.InLoadoutFor)
    end
end)