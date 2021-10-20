AddCSLuaFile()

-- Role features
GLITCH_SHOW_AS_TRAITOR = 0
GLITCH_SHOW_AS_SPECIAL_TRAITOR = 1
GLITCH_HIDE_SPECIAL_TRAITOR_ROLES = 2

hook.Add("TTTUpdateRoleState", "Glitch_TTTUpdateRoleState", function()
    local glitch_use_traps = GetGlobalBool("ttt_glitch_use_traps", false)
    CAN_LOOT_CREDITS_ROLES[ROLE_GLITCH] = glitch_use_traps
    TRAITOR_BUTTON_ROLES[ROLE_GLITCH] = glitch_use_traps
end)