------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Glitch_Translations_Initialize", function()
    -- Popup
    LANG.AddToLanguage("english", "info_popup_glitch", [[You are {role}! The {traitors} think you are one of them.
Try to blend in and don't give yourself away.]])
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Glitch_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_GLITCH then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
        local html = "The " .. ROLE_STRINGS[ROLE_GLITCH] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose goal is to pretend to be a <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>" .. ROLE_STRINGS[ROLE_TRAITOR] .. "</span>."

        -- Role appearance
        html = html .. "<span style='display: block; margin-top: 10px;'>Members of the <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>traitor team</span> will believe the " .. ROLE_STRINGS[ROLE_GLITCH] .. " is one of their own, but the " .. ROLE_STRINGS[ROLE_GLITCH] .. " won't know who the <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>traitor team members</span> are.</span>"

        -- Specific role appearance
        local glitch_mode = GetGlobalInt("ttt_glitch_mode", GLITCH_SHOW_AS_TRAITOR)
        if glitch_mode == GLITCH_HIDE_SPECIAL_TRAITOR_ROLES then
            html = html .. "<span style='display: block; margin-top: 10px;'>Also, having " .. ROLE_STRINGS_EXT[ROLE_GLITCH] .. " in the round causes special traitor roles to appear to their teammates as the normal " .. ROLE_STRINGS[ROLE_TRAITOR] .. " role.</span>"
        else
            html = html .. "<span style='display: block; margin-top: 10px;'>Specifically, the  " .. ROLE_STRINGS[ROLE_GLITCH] .. " will appear to the traitor team as "
            if glitch_mode == GLITCH_SHOW_AS_SPECIAL_TRAITOR then
                html = html .. " either the " .. ROLE_STRINGS[ROLE_TRAITOR] .. " role or a random enabled special traitor role"
            else
                html = html .. " the " .. ROLE_STRINGS[ROLE_TRAITOR] .. " role"
            end
            html = html .. ".</span>"
        end

        -- Communications block
        html = html .. "<span style='display: block; margin-top: 10px;'>When there is " .. ROLE_STRINGS_EXT[ROLE_GLITCH] .. " in the round, team text and voice chat <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>are blocked</span> to make it difficult to communicate and identify the " .. ROLE_STRINGS[ROLE_GLITCH] .. ".</span>"

        -- Traitor traps
        if GetGlobalBool("ttt_glitch_use_traps", false) then
            html = html .. "<span style='display: block; margin-top: 10px;'>To further the illusion of the " .. ROLE_STRINGS[ROLE_GLITCH] .. " being a member of the traitor team, they can <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>see and use traitor traps</span> throughout the map.</span>"
        end

        return html
    end
end)