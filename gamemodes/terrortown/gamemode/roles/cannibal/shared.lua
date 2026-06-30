AddCSLuaFile()

local hook = hook

local AddHook = hook.Add

------------------
-- ROLE CONVARS --
------------------

local cannibal_is_independent = CreateConVar("ttt_cannibal_is_independent", "0", FCVAR_REPLICATED, "Whether Cannibals should be treated as members of the independent team", 0, 1)
CreateConVar("ttt_cannibal_can_see_jesters", "0", FCVAR_REPLICATED)
CreateConVar("ttt_cannibal_update_scoreboard", "0", FCVAR_REPLICATED)

ROLE_CONVARS[ROLE_CANNIBAL] = {
    {
        cvar = "ttt_cannibal_notify_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"None", "Detective and Traitor", "Traitor", "Detective", "Everyone"},
        isNumeric = true
    },
    {
        cvar = "ttt_cannibal_notify_killer",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_cannibal_notify_sound",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_cannibal_notify_confetti",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_cannibal_is_independent",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_cannibal_eat_cooldown",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_cannibal_damage_penalty",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_cannibal_can_see_jesters",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_cannibal_update_scoreboard",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_cannibal_gains_health",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_cannibal_gained_health_percentage",
        type = ROLE_CONVAR_TYPE_NUM
    },
    {
        cvar = "ttt_cannibal_digestion",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_cannibal_digestion_time",
        type = ROLE_CONVAR_TYPE_NUM
    },
    {
        cvar = "ttt_cannibal_digestion_poop",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_cannibal_digestion_poop_sound",
        type = ROLE_CONVAR_TYPE_BOOL
    }
}

-------------------
-- ROLE FEATURES --
-------------------

AddHook("TTTUpdateRoleState", "Cannibal_TTTUpdateRoleState", function()
    local is_independent = cannibal_is_independent:GetBool()
    INDEPENDENT_ROLES[ROLE_CANNIBAL] = is_independent
    JESTER_ROLES[ROLE_CANNIBAL] = not is_independent
end)