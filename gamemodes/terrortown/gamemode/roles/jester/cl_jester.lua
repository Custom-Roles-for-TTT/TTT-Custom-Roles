------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Jester_Translations_Initialize", function()
    -- Win conditions
    LANG.AddToLanguage("english", "win_jester", "The {role} has fooled you all!")
    LANG.AddToLanguage("english", "ev_win_jester", "The tricky {role} won the round!")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_jester", [[You are {role}! You want to die but you
deal no damage so you must be killed by some one else.]])
end)

----------------
-- WIN CHECKS --
----------------

hook.Add("TTTScoringWinTitle", "Jester_TTTScoringWinTitle", function(wintype, wintitles, title, secondary_win_role)
    if wintype == WIN_JESTER then
        return { txt = "hilite_win_role_singular", params = { role = ROLE_STRINGS[ROLE_JESTER]:upper() }, c = ROLE_COLORS[ROLE_JESTER] }
    end
end)

------------
-- EVENTS --
------------

hook.Add("TTTEventFinishText", "Jester_TTTEventFinishText", function(e)
    if e.win == WIN_JESTER then
        return LANG.GetParamTranslation("ev_win_jester", { role = ROLE_STRINGS[ROLE_JESTER]:lower() })
    end
end)

hook.Add("TTTEventFinishIconText", "Jester_TTTEventFinishIconText", function(e, win_string, role_string)
    if e.win == WIN_JESTER then
        return win_string, ROLE_STRINGS[ROLE_JESTER]
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Jester_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_JESTER then
        local roleColor = GetRoleTeamColor(ROLE_TEAM_JESTER)
        return "The " .. ROLE_STRINGS[ROLE_JESTER] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>jester</span> role whose goal is to be."
        -- TODO
    end
end)