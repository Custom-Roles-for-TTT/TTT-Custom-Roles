------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Detective_Translations_Initialize", function()
    -- Popup
    LANG.AddToLanguage("english", "info_popup_detective", [[You are {role}! HQ has given you special resources to find the {traitors}.
Use them to help the {innocents} survive, but be careful:
the {traitors} will be looking to take you down first!

Press {menukey} to receive your equipment!]])
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Detective_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_DETECTIVE then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local html = "The " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose job is to find and eliminate their enemies."

        if GetGlobalBool("ttt_detective_search_only", true) then
            html = html .. "<span style='display: block; margin-top: 10px;'>" .. ROLE_STRINGS_PLURAL[ROLE_DETECTIVE] .. " are the only roles allowed to <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>search bodies</span> to find information about who they were and how they died."
        end

        return html .. "<span style='display: block; margin-top: 10px;'>Other players will know you are " .. ROLE_STRINGS_EXT[ROLE_DETECTIVE] .. " just by <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>looking at you</span>."
    end
end)