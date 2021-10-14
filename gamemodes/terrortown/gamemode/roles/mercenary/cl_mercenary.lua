------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Mercenary_Translations_Initialize", function()
    -- Popup
    LANG.AddToLanguage("english", "info_popup_mercenary", [[You are {role}! Try to survive and help your {innocent} friends!

Press {menukey} to receive your equipment!]])
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Mercenary_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_MERCENARY then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local detectiveColor = GetRoleTeamColor(ROLE_TEAM_DETECTIVE)
        local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
        local html = "The " .. ROLE_STRINGS[ROLE_MERCENARY] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose goal is to use their shop to help the player with a <span style='color: rgb(" .. detectiveColor.r .. ", " .. detectiveColor.g .. ", " .. detectiveColor.b .. ")'>" .. ROLE_STRINGS[ROLE_DETECTIVE] .. " role</span> defeat their enemies."

        -- Shop Mode
        html = html .. "<span style='display: block; margin-top: 10px;'>There is an <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>equipment shop</span> available to the " .. ROLE_STRINGS[ROLE_MERCENARY] .. " filled with "
        local shopMode = GetGlobalInt("ttt_mercenary_shop_mode", SHOP_SYNC_MODE_INTERSECT)
        if shopMode == SHOP_SYNC_MODE_UNION then
            html = html .. "all weapons available to either the <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>" .. ROLE_STRINGS[ROLE_TRAITOR] .. "</span> or the <span style='color: rgb(" .. detectiveColor.r .. ", " .. detectiveColor.g .. ", " .. detectiveColor.b .. ")'>" .. ROLE_STRINGS[ROLE_DETECTIVE] .. "</span>"
        elseif shopMode == SHOP_SYNC_MODE_INTERSECT then
            html = html .. "only weapons available to both the <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>" .. ROLE_STRINGS[ROLE_TRAITOR] .. "</span> and the <span style='color: rgb(" .. detectiveColor.r .. ", " .. detectiveColor.g .. ", " .. detectiveColor.b .. ")'>" .. ROLE_STRINGS[ROLE_DETECTIVE] .. "</span>"
        elseif shopMode == SHOP_SYNC_MODE_DETECTIVE then
            html = html .. "all weapons available to the <span style='color: rgb(" .. detectiveColor.r .. ", " .. detectiveColor.g .. ", " .. detectiveColor.b .. ")'>" .. ROLE_STRINGS[ROLE_DETECTIVE] .. "</span>"
        elseif shopMode == SHOP_SYNC_MODE_TRAITOR then
            html = html .. "all weapons available to the <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>" .. ROLE_STRINGS[ROLE_TRAITOR] .. "</span>"
        else
            html = html .. "its own selection of items added by the server administrator(s)"
        end
        html = html .. ".</span>"

        return html
    end
end)