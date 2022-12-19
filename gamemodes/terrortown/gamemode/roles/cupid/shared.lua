AddCSLuaFile()

local table = table

-- Cupid reveal modes
CUPID_REVEAL_NONE = 0
CUPID_REVEAL_ALL = 1
CUPID_REVEAL_TRAITORS = 2
CUPID_REVEAL_INNOCENTS = 3

-- Update their team
hook.Add("TTTUpdateRoleState", "Cupid_TTTUpdateRoleState", function()
    local cupids_are_independent = GetGlobalBool("ttt_cupids_are_independent", false)
    INDEPENDENT_ROLES[ROLE_CUPID] = cupids_are_independent
    JESTER_ROLES[ROLE_CUPID] = not cupids_are_independent
end)

------------------
-- ROLE CONVARS --
------------------

ROLE_CONVARS[ROLE_CUPID] = {}
table.insert(ROLE_CONVARS[ROLE_CUPID], {
    cvar = "ttt_cupid_notify_mode",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_CUPID], {
    cvar = "ttt_cupid_notify_sound",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_CUPID], {
    cvar = "ttt_cupid_notify_confetti",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_CUPID], {
    cvar = "ttt_cupid_lovers_notify_mode",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_CUPID], {
    cvar = "ttt_cupids_are_independent",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_CUPID], {
    cvar = "ttt_cupid_can_damage_lovers",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_CUPID], {
    cvar = "ttt_cupid_lovers_can_damage_lovers",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_CUPID], {
    cvar = "ttt_cupid_lovers_can_damage_cupid",
    type = ROLE_CONVAR_TYPE_BOOL
})