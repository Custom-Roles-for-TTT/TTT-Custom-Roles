AddCSLuaFile()

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_scout_reveal_jesters", "0", FCVAR_REPLICATED)
CreateConVar("ttt_scout_reveal_independents", "0", FCVAR_REPLICATED)
CreateConVar("ttt_scout_reveal_monsters", "1", FCVAR_REPLICATED)
CreateConVar("ttt_scout_delay_intel", "0", FCVAR_REPLICATED, "How long in seconds to delay the information send to the Scout", 0, 150)

ROLE_CONVARS[ROLE_SCOUT] = {
    {
        cvar = "ttt_scout_reveal_jesters",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_scout_reveal_independents",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_scout_reveal_monsters",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_scout_delay_intel",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_scout_alert_targets",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_scout_hidden_roles",
        type = ROLE_CONVAR_TYPE_TEXT
    }
}