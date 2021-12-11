local hook = hook
local net = net
local surface = surface
local string = string

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Bodysnatcher_Translations_Initialize", function()
    -- Event
    LANG.AddToLanguage("english", "ev_bodysnatch", "{attacker} bodysnatched {role}, {victim}")
    LANG.AddToLanguage("english", "ev_bodysnatch_killed", "The {bodysnatch} ({victim}) was killed by {attacker} but respawned")
    LANG.AddToLanguage("english", "ev_bodysnatch_killed_delay", "The {bodysnatch} ({victim}) was killed by {attacker} but will respawn in {delay} seconds")

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
    local hourglass_go_icon = Material("icon16/hourglass_go.png")
    local heart_add_icon = Material("icon16/heart_add.png")
    local Event = CLSCORE.DeclareEventDisplay
    local PT = LANG.GetParamTranslation
    Event(EVENT_BODYSNATCH, {
        text = function(e)
            return PT("ev_bodysnatch", {victim = e.vic, attacker = e.att, role = e.role})
        end,
        icon = function(e)
            return bodysnatch_icon, "Bodysnatch"
        end})

    Event(EVENT_BODYSNATCHERKILLED, {
        text = function(e)
            if e.delay > 0 then
                return PT("ev_bodysnatch_killed_delay", {attacker = e.att, victim = e.vic, delay = e.delay, bodysnatch = ROLE_STRINGS[ROLE_BODYSNATCHER]})
            end
            return PT("ev_bodysnatch_killed", {attacker = e.att, victim = e.vic, bodysnatch = ROLE_STRINGS[ROLE_BODYSNATCHER]})
        end,
        icon = function(e)
            if e.delay > 0 then
                return hourglass_go_icon, "Respawning"
            end
            return heart_add_icon, "Respawned"
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
net.Receive("TTT_BodysnatcherKilled", function(len)
    local victim = net.ReadString()
    local attacker = net.ReadString()
    local delay = net.ReadUInt(8)
    CLSCORE:AddEvent({
        id = EVENT_BODYSNATCHERKILLED,
        vic = victim,
        att = attacker,
        delay = delay
    })
end)

-- Show the player's starting role icon if they were originally a bodysnatcher
hook.Add("TTTScoringSummaryRender", "Bodysnatcher_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
    if startingRole == ROLE_BODYSNATCHER then
        return ROLE_STRINGS_SHORT[ROLE_BODYSNATCHER]
    end
end)

---------
-- HUD --
---------

hook.Add("TTTHUDInfoPaint", "Bodysnatcher_TTTHUDInfoPaint", function(client, label_left, label_top)
    if client:GetNWBool("WasBodysnatcher", false) then
        local bodysnatcherMode = BODYSNATCHER_REVEAL_ALL
        if client:IsInnocentTeam() then bodysnatcherMode = GetGlobalInt("ttt_bodysnatcher_reveal_innocent", BODYSNATCHER_REVEAL_ALL)
        elseif client:IsTraitorTeam() then bodysnatcherMode = GetGlobalInt("ttt_bodysnatcher_reveal_traitor", BODYSNATCHER_REVEAL_ALL)
        elseif client:IsMonsterTeam() then bodysnatcherMode = GetGlobalInt("ttt_bodysnatcher_reveal_monster", BODYSNATCHER_REVEAL_ALL)
        elseif client:IsIndependentTeam() then bodysnatcherMode = GetGlobalInt("ttt_bodysnatcher_reveal_independent", BODYSNATCHER_REVEAL_ALL) end
        if bodysnatcherMode ~= BODYSNATCHER_REVEAL_ALL then
            surface.SetFont("TabLarge")
            surface.SetTextColor(255, 255, 255, 230)

            if bodysnatcherMode == BODYSNATCHER_REVEAL_NONE then
                text = LANG.GetParamTranslation("bodysnatcher_hidden_all_hud", { bodysnatcher = ROLE_STRINGS_EXT[ROLE_BODYSNATCHER] })
            elseif bodysnatcherMode == BODYSNATCHER_REVEAL_TEAM then
                text = LANG.GetParamTranslation("bodysnatcher_hidden_team_hud", { bodysnatcher = ROLE_STRINGS_EXT[ROLE_BODYSNATCHER] })
            end
            local _, h = surface.GetTextSize(text)

            surface.SetTextPos(label_left, ScrH() - label_top - h)
            surface.DrawText(text)
        end
    end
end)

--------------
-- TUTORIAL --
--------------

local function GetRevealModeString(roleColor, revealMode, teamName, teamColor)
    local modeString = "When joining the <span style='color: rgb(" .. teamColor.r .. ", " .. teamColor.g .. ", " .. teamColor.b .. ")'>" .. string.lower(teamName) .. "</span> team, the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. ROLE_STRINGS[ROLE_BODYSNATCHER] .. "</span>'s new role will be revealed to "
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

        -- Respawn
        if GetGlobalBool("ttt_bodysnatcher_respawn", false) then
            html = html .. "<span style='display: block; margin-top: 10px;'>If the " .. ROLE_STRINGS[ROLE_BODYSNATCHER] .. " is killed before they join a team, <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>they will respawn</span>"

            local respawnLimit = GetGlobalInt("ttt_bodysnatcher_respawn_limit", 0)
            if respawnLimit > 0 then
                html = html .. " up to " .. respawnLimit .. " time(s)"
            end

            local respawnDelay = GetGlobalInt("ttt_bodysnatcher_respawn_delay", 0)
            if respawnDelay > 0 then
                html = html .. " after a " .. respawnDelay .. " second delay"
            end

            html = html .. ".</span>"
        end

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