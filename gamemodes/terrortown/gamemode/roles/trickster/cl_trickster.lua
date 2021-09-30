------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Trickster_Translations_Initialize", function()
    -- Popup
    LANG.AddToLanguage("english", "info_popup_trickster", [[You are {role}! You are {aninnocent} who can see and
use {traitor} traps throughout the map. Have fun!]])
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Trickster_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_TRICKSTER then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local html = "The " .. ROLE_STRINGS[ROLE_TRICKSTER] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> who can:"

        roleColor = ROLE_COLORS[ROLE_TRAITOR]
        html = html .. "<ul style='position: relative; top: -15px;'>"
            html = html .. "<li>See and use <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>traitor buttons</span>"
            html = html .. "<li>See and use <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>traitor traps</span>"
            html = html .. "<li>Loot credits from corpses"
        return html .. "</ul>"
    end
end)