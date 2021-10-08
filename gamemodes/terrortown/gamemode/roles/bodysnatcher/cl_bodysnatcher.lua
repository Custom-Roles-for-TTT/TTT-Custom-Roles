------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Bodysnatcher_Translations_Initialize", function()
    -- Event
    LANG.AddToLanguage("english", "ev_bodysnatch", "{attacker} bodysnatched {role}, {victim}")

    -- HUD
    LANG.AddToLanguage("english", "bodysnatcher_hidden_all_hud", "You still appear as {bodysnatcher} to others")
    LANG.AddToLanguage("english", "bodysnatcher_hidden_team_hud", "Only your team knows you are no longer {bodysnatcher}")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_bodysnatcher", [[You are {role}! {traitors} think you are {ajester} and you
    deal no damage. Use your body snatching device on a corpse
    to take their role and join the fight!]])
end)

-------------
-- SCORING --
-------------

-- Register the scoring events for the swapper
hook.Add("Initialize", "Bodysnatcher_Scoring_Initialize", function()
    local bodysnatch_icon = Material("icon16/user_edit.png")
    local Event = CLSCORE.DeclareEventDisplay
    local PT = LANG.GetParamTranslation
    Event(EVENT_BODYSNATCH, {
        text = function(e)
            return PT("ev_bodysnatch", {victim = e.vic, attacker = e.att, role = e.role})
        end,
        icon = function(e)
            return bodysnatch_icon, "Bodysnatch"
        end})
end)

net.Receive("TTT_ScoreBodysnatch", function(len)
    local victim = net.ReadString()
    local attacker = net.ReadString()
    local role = net.ReadString()
    local vicsid = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_BODYSNATCH,
        vic = victim,
        att = attacker,
        role = role,
        sid64 = vicsid,
        bonus = 2
    })
end)

-- Show the player's starting role icon if they were originally a bodysnatcher
hook.Add("TTTScoringSummaryRender", "Bodysnatcher_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
    if startingRole == ROLE_BODYSNATCHER then
        return ROLE_STRINGS_SHORT[ROLE_BODYSNATCHER]
    end
end)

--------------
-- TUTORIAL --
--------------

local function GetRevealModeString(roleColor, revealMode, teamName, teamColor)
    local modeString = "When joining the <span style='color: rgb(" .. teamColor.r .. ", " .. teamColor.g .. ", " .. teamColor.b .. ")'>" .. teamName:lower() .. "</span> team, the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. ROLE_STRINGS[ROLE_BODYSNATCHER] .. "</span>'s new role will be revealed to "
    if revealMode == BODYSNATCHER_REVEAL_ALL then
        modeString = modeString .. "everyone"
    elseif revealMode == BODYSNATCHER_REVEAL_TEAM then
        modeString = modeString .. "only <span style='color: rgb(" .. teamColor.r .. ", " .. teamColor.g .. ", " .. teamColor.b .. ")'>their new team</span>"
    else
        modeString = modeString .. "nobody"
    end
    return modeString .. "."
end

hook.Add("TTTTutorialRoleText", "Bodysnatcher_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_BODYSNATCHER then
        local roleColor = GetRoleTeamColor(ROLE_TEAM_JESTER)
        local html = "The " .. ROLE_STRINGS[ROLE_BODYSNATCHER] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>jester</span> role whose goal is to steal the role of a dead player using their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>bodysnatching device</span>."

        html = html .. "<span style='display: block; margin-top: 10px;'>After <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>stealing a corpse's role</span>, they take over the goal of their new role.</span>"

        -- Innocent Reveal
        local revealMode = GetGlobalInt("ttt_bodysnatcher_reveal_innocent", BODYSNATCHER_REVEAL_ALL)
        local teamName, teamColor = GetRoleTeamInfo(ROLE_TEAM_INNOCENT, true)
        html = html .. "<span style='display: block; margin-top: 10px;'>" .. GetRevealModeString(roleColor, revealMode, teamName, teamColor) .. "</span>"

        -- Traitor Reveal
        revealMode = GetGlobalInt("ttt_bodysnatcher_reveal_traitor", BODYSNATCHER_REVEAL_ALL)
        teamName, teamColor = GetRoleTeamInfo(ROLE_TEAM_TRAITOR, true)
        html = html .. "<span style='display: block; margin-top: 10px;'>" .. GetRevealModeString(roleColor, revealMode, teamName, teamColor) .. "</span>"

        -- Monster Reveal
        revealMode = GetGlobalInt("ttt_bodysnatcher_reveal_monster", BODYSNATCHER_REVEAL_ALL)
        teamName, teamColor = GetRoleTeamInfo(ROLE_TEAM_MONSTER, true)
        html = html .. "<span style='display: block; margin-top: 10px;'>" .. GetRevealModeString(roleColor, revealMode, teamName, teamColor) .. "</span>"

        -- Independent Reveal
        revealMode = GetGlobalInt("ttt_bodysnatcher_reveal_independent", BODYSNATCHER_REVEAL_ALL)
        teamName, teamColor = GetRoleTeamInfo(ROLE_TEAM_INDEPENDENT, true)
        html = html .. "<span style='display: block; margin-top: 10px;'>" .. GetRevealModeString(roleColor, revealMode, teamName, teamColor) .. "</span>"

        return html
    end
end)