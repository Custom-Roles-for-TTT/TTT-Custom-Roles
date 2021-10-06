------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Beggar_Translations_Initialize", function()
    -- Events
    LANG.AddToLanguage("english", "ev_beggar_converted", "The {beggar} ({victim}) was converted to {team} by {attacker}")
    LANG.AddToLanguage("english", "ev_beggar_killed", "The {beggar} ({victim}) was killed by {attacker} but respawned")
    LANG.AddToLanguage("english", "ev_beggar_killed_delay", "The {beggar} ({victim}) was killed by {attacker} but will respawn in {delay} seconds")

    -- HUD
    LANG.AddToLanguage("english", "beggar_hidden_all_hud", "You still appear as {beggar} to others")
    LANG.AddToLanguage("english", "beggar_hidden_innocent_hud", "You still appear as {beggar} to {innocents}")
    LANG.AddToLanguage("english", "beggar_hidden_traitor_hud", "You still appear as {beggar} to {traitors}")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_beggar", [[You are {role}! {traitors} think you are {ajester} and you
deal no damage. However, if you can convince someone to give
you a shop item you will join their team.]])
end)

-------------
-- SCORING --
-------------

-- Register the scoring events for the beggar
hook.Add("Initialize", "Beggar_Scoring_Initialize", function()
    local innocent_icon = Material("icon16/user_green.png")
    local traitor_icon = Material("icon16/user_red.png")
    local hourglass_go_icon = Material("icon16/hourglass_go.png")
    local heart_add_icon = Material("icon16/heart_add.png")
    local Event = CLSCORE.DeclareEventDisplay
    local PT = LANG.GetParamTranslation
    Event(EVENT_BEGGARCONVERTED, {
        text = function(e)
            return PT("ev_beggar_converted", {victim = e.vic, attacker = e.att, team = e.team, beggar = ROLE_STRINGS[ROLE_BEGGAR]})
        end,
        icon = function(e)
            if e.team == ROLE_STRINGS_EXT[ROLE_INNOCENT] then
                return innocent_icon, "Converted"
            else
                return traitor_icon, "Converted"
            end
        end})

    Event(EVENT_BEGGARKILLED, {
       text = function(e)
          if e.delay > 0 then
             return PT("ev_beggar_killed_delay", {attacker = e.att, victim = e.vic, delay = e.delay, beggar = ROLE_STRINGS[ROLE_BEGGAR]})
          end
          return PT("ev_beggar_killed", {attacker = e.att, victim = e.vic, beggar = ROLE_STRINGS[ROLE_BEGGAR]})
      end,
      icon = function(e)
          if e.delay > 0 then
             return hourglass_go_icon, "Respawning"
          end
          return heart_add_icon, "Respawned"
      end})
end)

net.Receive("TTT_BeggarConverted", function(len)
    local victim = net.ReadString()
    local attacker = net.ReadString()
    local team = net.ReadString()
    local vicsid = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_BEGGARCONVERTED,
        vic = victim,
        att = attacker,
        team = team,
        sid64 = vicsid,
        bonus = 2
    })
end)

net.Receive("TTT_BeggarKilled", function(len)
    local victim = net.ReadString()
    local attacker = net.ReadString()
    local delay = net.ReadUInt(8)
    CLSCORE:AddEvent({
        id = EVENT_BEGGARKILLED,
        vic = victim,
        att = attacker,
        delay = delay
    })
end)

--------------
-- TUTORIAL --
--------------

local function GetRevealModeString(roleColor, revealMode, teamName, teamColor)
    local modeString = "When joining the <span style='color: rgb(" .. teamColor.r .. ", " .. teamColor.g .. ", " .. teamColor.b .. ")'>" .. teamName .. "</span> team, the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. ROLE_STRINGS[ROLE_BEGGAR] .. "</span>'s new role will be revealed to "
    if revealMode == BEGGAR_REVEAL_ALL then
        modeString = modeString .. "everyone"
    elseif revealMode == BEGGAR_REVEAL_TRAITORS then
        local revealColor = ROLE_COLORS[ROLE_TRAITOR]
        modeString = modeString .. "only <span style='color: rgb(" .. revealColor.r .. ", " .. revealColor.g .. ", " .. revealColor.b .. ")'>" .. LANG.GetTranslation("traitors"):lower() .. "</span>"
    elseif revealMode == BEGGAR_REVEAL_INNOCENTS then
        local revealColor = ROLE_COLORS[ROLE_TRAITOR]
        modeString = modeString .. "only <span style='color: rgb(" .. revealColor.r .. ", " .. revealColor.g .. ", " .. revealColor.b .. ")'>" .. LANG.GetTranslation("innocents"):lower() .. "</span>"
    else
        modeString = modeString .. "nobody"
    end
    return modeString .. "."
end

hook.Add("TTTTutorialRoleText", "Beggar_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_BEGGAR then
        local roleColor = GetRoleTeamColor(ROLE_TEAM_JESTER)
        local html = "The " .. ROLE_STRINGS[ROLE_BEGGAR] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>jester</span> role whose goal is to convince another players to give them a shop item."

        html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_BEGGAR] .. " then <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>joins the team</span> of whichever player <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>bought the item</span> they are given.</span>"

        -- Respawn
        if GetGlobalBool("ttt_beggar_respawn", false) then
            html = html .. "<span style='display: block; margin-top: 10px;'>If the " .. ROLE_STRINGS[ROLE_BEGGAR] .. " is killed before they join a team, <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>they will respawn</span>"

            local respawnDelay = GetGlobalInt("ttt_beggar_respawn_delay", 0)
            if respawnDelay > 0 then
                html = html .. " after a " .. respawnDelay .. " second delay"
            end

            html = html .. ".</span>"
        end

        -- Innocent Reveal
        local revealMode = GetGlobalInt("ttt_beggar_reveal_innocent", BEGGAR_REVEAL_TRAITORS)
        local teamName, teamColor = GetRoleTeamInfo(ROLE_TEAM_INNOCENT, true)
        html = html .. "<span style='display: block; margin-top: 10px;'>" .. GetRevealModeString(roleColor, revealMode, teamName, teamColor) .. "</span>"

        -- Traitor Reveal
        revealMode = GetGlobalInt("ttt_beggar_reveal_traitor", BEGGAR_REVEAL_ALL)
        teamName, teamColor = GetRoleTeamInfo(ROLE_TEAM_TRAITOR, true)
        html = html .. "<span style='display: block; margin-top: 10px;'>" .. GetRevealModeString(roleColor, revealMode, teamName, teamColor) .. "</span>"

        return html
    end
end)