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

hook.Add("TTTTutorialRoleText", "Beggar_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_BEGGAR then
        local roleColor = GetRoleTeamColor(ROLE_TEAM_JESTER)
        return "The " .. ROLE_STRINGS[ROLE_BEGGAR] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>jester</span> role whose goal is to ."
    end
end)