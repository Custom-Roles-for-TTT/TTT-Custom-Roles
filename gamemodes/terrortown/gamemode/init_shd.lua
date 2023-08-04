for role = 0, ROLE_MAX do
    local rolestring = ROLE_STRINGS_RAW[role]

    if not DEFAULT_ROLES[role] then
        CreateConVar("ttt_" .. rolestring .. "_enabled", "0", FCVAR_REPLICATED)
    end

    CreateConVar("ttt_" .. rolestring .. "_name", "", FCVAR_REPLICATED)
    CreateConVar("ttt_" .. rolestring .. "_name_plural", "", FCVAR_REPLICATED)
    CreateConVar("ttt_" .. rolestring .. "_name_article", "", FCVAR_REPLICATED)

    if INDEPENDENT_ROLES[role] then
        local jesterVisible = ROLE_CAN_SEE_JESTERS[role] and "1" or "0"
        CreateConVar("ttt_" .. rolestring .. "_can_see_jesters", jesterVisible, FCVAR_REPLICATED)
        local miaVisible = ROLE_CAN_SEE_MIA[role] and "1" or "0"
        CreateConVar("ttt_" .. rolestring .. "_update_scoreboard", miaVisible, FCVAR_REPLICATED)
    end
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

CreateConVar("ttt_round_summary_tabs", "summary,hilite,events,scores", FCVAR_REPLICATED)

CreateConVar("ttt_roundtime_win_draw", "0", FCVAR_REPLICATED)

CreateConVar("ttt_scoreboard_deaths", "0", FCVAR_REPLICATED)
CreateConVar("ttt_scoreboard_score", "0", FCVAR_REPLICATED)

CreateConVar("ttt_shop_random_percent", "50", FCVAR_REPLICATED, "The percent chance that a weapon in the shop will not be shown by default", 0, 100)
CreateConVar("ttt_shop_random_position", "0", FCVAR_REPLICATED, "Whether to randomize the position of the items in the shop")

-- Shop parameters
CreateConVar("ttt_shop_for_all", 0, FCVAR_REPLICATED)
-- Add any convars that are missing once shop-for-all is enabled
cvars.AddChangeCallback("ttt_shop_for_all", function(convar, oldValue, newValue)
    local enabled = tobool(newValue)
    if enabled then
        for role = 0, ROLE_MAX do
            if not SHOP_ROLES[role] then
                CreateShopConVars(role)
                SHOP_ROLES[role] = true
            end
        end
    end
end)

local shop_roles = GetTeamRoles(SHOP_ROLES)
for _, role in ipairs(shop_roles) do
    CreateShopConVars(role)
end

-- Create the starting credit convar for all roles that have credits but don't have a shop
local shopless_credit_roles = table.UnionedKeys(CAN_LOOT_CREDITS_ROLES, ROLE_STARTING_CREDITS, shop_roles)
for _, role in ipairs(shopless_credit_roles) do
    CreateCreditConVar(role)
end