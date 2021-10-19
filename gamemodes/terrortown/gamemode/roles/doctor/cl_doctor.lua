------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Doctor_Translations_Initialize", function()
    -- Popup
    LANG.AddToLanguage("english", "info_popup_doctor", [[You are {role}! You're here to keep your teammates alive.
Use your tools to keep fellow {innocents} in the fight!

Press {menukey} to receive your special equipment!]])
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Doctor_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_DOCTOR then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local html = "The " .. ROLE_STRINGS[ROLE_DOCTOR] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose goal is to heal their patients."

        html = html .. "<span style='display: block; margin-top: 10px;'>Use the equipment shop to buy <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>a health station</span> or <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. ROLE_STRINGS[ROLE_PARASITE]:lower() .. " cure</span> to help administer treatments.</span>"

        return html
    end
end)