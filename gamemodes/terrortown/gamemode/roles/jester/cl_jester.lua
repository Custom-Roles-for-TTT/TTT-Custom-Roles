local hook = hook
local string = string

-------------
-- CONVARS --
-------------

local jester_win_by_traitors = GetConVar("ttt_jester_win_by_traitors")
local jester_healthstation_reduce_max = GetConVar("ttt_jester_healthstation_reduce_max")

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Jester_Translations_Initialize", function()
    -- Win conditions
    LANG.AddToLanguage("english", "win_jester", "The {role} has fooled you all!")
    LANG.AddToLanguage("english", "ev_win_jester", "The tricky {role} won the round!")

    -- Scoring
    LANG.AddToLanguage("english", "score_jester_killedby", "Killed by")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_jester", [[You are {role}! You want to die but you
deal no damage so you must be killed by some one else.]])
end)

----------------
-- WIN CHECKS --
----------------

hook.Add("TTTScoringWinTitle", "Jester_TTTScoringWinTitle", function(wintype, wintitles, title, secondary_win_role)
    if wintype == WIN_JESTER then
        return { txt = "hilite_win_role_singular", params = { role = string.upper(ROLE_STRINGS[ROLE_JESTER]) }, c = ROLE_COLORS[ROLE_JESTER] }
    end
end)

------------
-- EVENTS --
------------

hook.Add("TTTEventFinishText", "Jester_TTTEventFinishText", function(e)
    if e.win == WIN_JESTER then
        return LANG.GetParamTranslation("ev_win_jester", { role = string.lower(ROLE_STRINGS[ROLE_JESTER]) })
    end
end)

hook.Add("TTTEventFinishIconText", "Jester_TTTEventFinishIconText", function(e, win_string, role_string)
    if e.win == WIN_JESTER then
        return win_string, ROLE_STRINGS[ROLE_JESTER]
    end
end)

-------------
-- SCORING --
-------------

-- Show who killed the jester (if anyone)
hook.Add("TTTScoringSummaryRender", "Jester_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
    if not IsPlayer(ply) then return end

    if ply:IsJester() then
        local jesterKiller = ply:GetNWString("JesterKiller", "")
        if #jesterKiller > 0 then
            return roleFileName, groupingRole, roleColor, name, jesterKiller, LANG.GetTranslation("score_jester_killedby")
        end
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Jester_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_JESTER then
        local roleColor = GetRoleTeamColor(ROLE_TEAM_JESTER)
        local html =  "The " .. ROLE_STRINGS[ROLE_JESTER] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>jester</span> role whose goal is to be killed by another player."

        if not jester_win_by_traitors:GetBool() then
            local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
            html = html .. "<span style='display: block; margin-top: 10px;'>Be careful! Jesters <span style='text-decoration: underline'>DO NOT</span> win if they are killed by a member of the <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>traitor team</span>!</span>"
        end

        if jester_healthstation_reduce_max:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>When the " .. ROLE_STRINGS[ROLE_JESTER] .. " uses a health station, their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>maximum health is reduced</span> toward their current health instead of them being healed.</span>"
        end

        return html
    end
end)