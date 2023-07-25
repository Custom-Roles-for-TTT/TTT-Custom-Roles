AddCSLuaFile()

local table = table

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_cupid_lover_vision_enable", "1", FCVAR_REPLICATED, "Whether the lovers can see outlines of each other through walls", 0, 1)
local cupid_is_independent = CreateConVar("ttt_cupid_is_independent", "0", FCVAR_REPLICATED, "Whether cupids should be treated as members of the independent team", 0, 1)

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
    cvar = "ttt_cupid_is_independent",
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
table.insert(ROLE_CONVARS[ROLE_CUPID], {
    cvar = "ttt_cupid_lover_vision_enable",
    type = ROLE_CONVAR_TYPE_BOOL
})

-------------------
-- ROLE FEATURES --
-------------------

hook.Add("TTTUpdateRoleState", "Cupid_TTTUpdateRoleState", function()
    INDEPENDENT_ROLES[ROLE_CUPID] = cupid_is_independent:GetBool()
    JESTER_ROLES[ROLE_CUPID] = not cupid_is_independent:GetBool()
end)