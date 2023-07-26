local hook = hook

-------------
-- CONVARS --
-------------

local tracker_footstep_time = GetConVar("ttt_tracker_footstep_time")
local tracker_footstep_color = GetConVar("ttt_tracker_footstep_color")

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
        local html = "The " .. ROLE_STRINGS[ROLE_TRACKER] .. " is a " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " and a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose job is to find and eliminate their enemies."

        -- Footsteps
        local footstepTime = tracker_footstep_time:GetInt()
        if footstepTime > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>Instead of getting a DNA Scanner like a vanilla <span style='color: rgb(" .. detectiveColor.r .. ", " .. detectiveColor.g .. ", " .. detectiveColor.b .. ")'>" .. ROLE_STRINGS[ROLE_DETECTIVE] .. "</span>, they have the ability to see player footsteps from the last " .. footstepTime .. " seconds on the ground.</span>"

            if tracker_footstep_color:GetBool() then
                html = html .. "<span style='display: block; margin-top: 10px;'>Each player will have a randomly assigned <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>footstep color</span> allowing the " .. ROLE_STRINGS[ROLE_TRACKER] .. " to follow specific players.</span>"
            end
        end

        html = html .. "<span style='display: block; margin-top: 10px;'>Other players will know you are " .. ROLE_STRINGS_EXT[ROLE_DETECTIVE] .. " just by <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>looking at you</span>"
        local special_detective_mode = GetConVar("ttt_detectives_hide_special_mode"):GetInt()
        if special_detective_mode > SPECIAL_DETECTIVE_HIDE_NONE then
            html = html .. ", but not what specific type of " .. ROLE_STRINGS[ROLE_DETECTIVE]
            if special_detective_mode == SPECIAL_DETECTIVE_HIDE_FOR_ALL then
                html = html .. ". <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Not even you know what type of " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " you are</span>"
            end
        end
        html = html .. ".</span>"

        return html
    end
end)