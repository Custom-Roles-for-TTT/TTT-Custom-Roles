AddCSLuaFile()

local hook = hook
local table = table

-- Initialize role features
GLITCH_SHOW_AS_TRAITOR = 0
GLITCH_SHOW_AS_SPECIAL_TRAITOR = 1
GLITCH_HIDE_SPECIAL_TRAITOR_ROLES = 2

hook.Add("TTTUpdateRoleState", "Glitch_TTTUpdateRoleState", function()
    local glitch_use_traps = GetConVar("ttt_glitch_use_traps"):GetBool()
    CAN_LOOT_CREDITS_ROLES[ROLE_GLITCH] = glitch_use_traps
    TRAITOR_BUTTON_ROLES[ROLE_GLITCH] = glitch_use_traps
end)

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_glitch_mode", "0", FCVAR_REPLICATED, "The way in which the glitch appears to traitors. 0 - Appears as a regular traitor. 1 - Can appear as a special traitor. 2 - Causes all traitors, regular or special, to appear as regular traitors and appears as a regular traitor themselves.", 0, 2)
CreateConVar("ttt_glitch_use_traps", "0", FCVAR_REPLICATED)

ROLE_CONVARS[ROLE_GLITCH] = {}
table.insert(ROLE_CONVARS[ROLE_GLITCH], {
    cvar = "ttt_glitch_mode",
    type = ROLE_CONVAR_TYPE_DROPDOWN,
    choices = {"Traitor", "Random Special Traitor", "Mask all traitors"},
    isNumeric = true
})
table.insert(ROLE_CONVARS[ROLE_GLITCH], {
    cvar = "ttt_glitch_use_traps",
    type = ROLE_CONVAR_TYPE_BOOL
})