AddCSLuaFile()

local hook = hook
local util = util

local AddHook = hook.Add

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_jester_healthstation_reduce_max", "1", FCVAR_REPLICATED, "Whether the jester's max health should be reduced to match their current health", 0, 1)
CreateConVar("ttt_jester_win_by_traitors", "1", FCVAR_REPLICATED, "Whether the jester will win the round if they are killed by a traitor", 0, 1)

ROLE_CONVARS[ROLE_JESTER] = {
    {
        cvar = "ttt_jester_notify_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"None", "Detective and Traitor", "Traitor", "Detective", "Everyone"},
        isNumeric = true
    },
    {
        cvar = "ttt_jester_notify_killer",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_jester_notify_sound",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_jester_notify_confetti",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_jester_win_by_traitors",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_jester_win_ends_round",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_jester_healthstation_reduce_max",
        type = ROLE_CONVAR_TYPE_BOOL
    }
}

-- Initialize role features
AddHook("TTTPrepareRound", "Jester_Shared_TTTPrepareRound", function()
    -- Add radio sounds
    if not TRADIO.Sounds.jescelebrate and util.CanRoleSpawn(ROLE_JESTER) then
        TRADIO.AddNewSound("jescelebrate", {
            name = "radio_jes_celebrate",
            name_params = { jester = ROLE_STRINGS[ROLE_JESTER] },
            sound = "birthday.wav"
        })
    end
end)