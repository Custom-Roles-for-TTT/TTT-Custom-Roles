AddCSLuaFile()

local table = table

-- Initialize role features
INFORMANT_UNSCANNED = 0
INFORMANT_SCANNED_TEAM = 1
INFORMANT_SCANNED_ROLE = 2
INFORMANT_SCANNED_TRACKED = 3

------------------
-- ROLE CONVARS --
------------------

ROLE_CONVARS[ROLE_INFORMANT] = {}
table.insert(ROLE_CONVARS[ROLE_INFORMANT], {
    cvar = "ttt_informant_share_scans",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_INFORMANT], {
    cvar = "ttt_informant_can_scan_jesters",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_INFORMANT], {
    cvar = "ttt_informant_can_scan_glitches",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_INFORMANT], {
    cvar = "ttt_informant_scanner_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_INFORMANT], {
    cvar = "ttt_informant_scanner_float_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_INFORMANT], {
    cvar = "ttt_informant_scanner_cooldown",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_INFORMANT], {
    cvar = "ttt_informant_scanner_distance",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})