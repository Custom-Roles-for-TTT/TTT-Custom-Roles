for role = 0, ROLE_MAX do
    local rolestring = ROLE_STRINGS_RAW[role]

    if not DEFAULT_ROLES[role] then
        CreateConVar("ttt_" .. rolestring .. "_enabled", "0", FCVAR_REPLICATED)
    end

    CreateConVar("ttt_" .. rolestring .. "_name", "", FCVAR_REPLICATED)
    CreateConVar("ttt_" .. rolestring .. "_name_plural", "", FCVAR_REPLICATED)
    CreateConVar("ttt_" .. rolestring .. "_name_article", "", FCVAR_REPLICATED)
end

CreateConVar("ttt_all_search_binoc", "0", FCVAR_REPLICATED)
CreateConVar("ttt_all_search_postround", "1", FCVAR_REPLICATED)

-- Detective role properties
CreateConVar("ttt_special_detectives_armor_loadout", "1", FCVAR_REPLICATED)
CreateConVar("ttt_detectives_disable_looting", "0", FCVAR_REPLICATED)
CreateConVar("ttt_detectives_hide_special_mode", SPECIAL_DETECTIVE_HIDE_NONE, FCVAR_REPLICATED, "How to handle special detective role information. 0 - Show the special detective's role to everyone. 1 - Hide the special detective's role from everyone (just show detective instead). 2 - Hide the special detective's role for everyone but themselves (only they can see their true role)", SPECIAL_DETECTIVE_HIDE_NONE, SPECIAL_DETECTIVE_HIDE_FOR_OTHERS)
CreateConVar("ttt_detectives_search_only", "1", FCVAR_REPLICATED)
for _, dataType in ipairs(CORPSE_ICON_TYPES) do
    CreateConVar("ttt_detectives_search_only_" .. dataType, "0", FCVAR_REPLICATED)
end

-- Traitor role properties
CreateConVar("ttt_traitors_vision_enable", "0", FCVAR_REPLICATED)

-- Jester role properties
CreateConVar("ttt_jesters_visible_to_traitors", "1", FCVAR_REPLICATED)
CreateConVar("ttt_jesters_visible_to_monsters", "1", FCVAR_REPLICATED)
CreateConVar("ttt_jesters_visible_to_independents", "1", FCVAR_REPLICATED)

-- Independent role properties
CreateConVar("ttt_independents_update_scoreboard", "0", FCVAR_REPLICATED)

CreateConVar("ttt_round_summary_tabs", "summary,hilite,events,scores", FCVAR_REPLICATED)

CreateConVar("ttt_roundtime_win_draw", "0", FCVAR_REPLICATED)

CreateConVar("ttt_scoreboard_deaths", "0", FCVAR_REPLICATED)
CreateConVar("ttt_scoreboard_score", "0", FCVAR_REPLICATED)

CreateConVar("ttt_shop_random_percent", "50", FCVAR_REPLICATED, "The percent chance that a weapon in the shop will not be shown by default", 0, 100)
CreateConVar("ttt_shop_random_position", "0", FCVAR_REPLICATED, "Whether to randomize the position of the items in the shop")
