------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Tracker_Translations_Initialize", function()
    -- Popup
    LANG.AddToLanguage("english", "info_popup_tracker", [[You are {role}! As {adetective}, HQ has given you special resources to find the {traitors}.
You can see players' footsteps and follow their trails.
Use your skills to keep an eye on where players have been.

Press {menukey} to receive your equipment!]])
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Tracker_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_TRACKER then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local detectiveColor = GetRoleTeamColor(ROLE_TEAM_DETECTIVE)
        local html = "The " .. ROLE_STRINGS[ROLE_TRACKER] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose job is to find and eliminate their enemies."

        local footstepTime = GetGlobalInt("ttt_tracker_footstep_time", 15)
        if footstepTime > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>Instead of getting a DNA Scanner like a vanilla <span style='color: rgb(" .. detectiveColor.r .. ", " .. detectiveColor.g .. ", " .. detectiveColor.b .. ")'>" .. ROLE_STRINGS[ROLE_DETECTIVE] .. "</span>, they have the ability to see player footsteps from the last " .. footstepTime .. " seconds on the ground.</span>"

            if GetGlobalBool("ttt_tracker_footstep_color", true) then
                html = html .. "<span style='display: block; margin-top: 10px;'>Each player will have a randomly assigned <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>footstep color</span>. The " .. ROLE_STRINGS[ROLE_TRACKER] .. " can use these footsteps to track specific players.</span>"
            end
        end

        return html
    end
end)