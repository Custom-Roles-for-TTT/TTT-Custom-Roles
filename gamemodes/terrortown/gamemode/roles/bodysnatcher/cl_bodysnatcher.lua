local hook = hook
local net = net
local surface = surface
local string = string

-------------
-- CONVARS --
-------------

local bodysnatcher_respawn = GetConVar("ttt_bodysnatcher_respawn")
local bodysnatcher_respawn_delay = GetConVar("ttt_bodysnatcher_respawn_delay")
local bodysnatcher_respawn_limit = GetConVar("ttt_bodysnatcher_respawn_limit")
local bodysnatcher_reveal_innocent = GetConVar("ttt_bodysnatcher_reveal_innocent")
local bodysnatcher_reveal_traitor = GetConVar("ttt_bodysnatcher_reveal_traitor")
local bodysnatcher_reveal_jester = GetConVar("ttt_bodysnatcher_reveal_jester")
local bodysnatcher_reveal_independent = GetConVar("ttt_bodysnatcher_reveal_independent")
local bodysnatcher_reveal_monster = GetConVar("ttt_bodysnatcher_reveal_monster")
local bodysnatcher_is_independent = GetConVar("ttt_bodysnatcher_is_independent")
local bodysnatcher_destroy_body = GetConVar("ttt_bodysnatcher_destroy_body")
local bodysnatcher_show_role = GetConVar("ttt_bodysnatcher_show_role")
local bodysnatcher_swap_mode = GetConVar("ttt_bodysnatcher_swap_mode")

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

    -- Popups
    LANG.AddToLanguage("english", "info_popup_bodysnatcher_jester", [[You are {role}! {traitors} think you are {ajester} and you
deal no damage. Use your body snatching device on a corpse
to take their role and join the fight!]])
    LANG.AddToLanguage("english", "info_popup_bodysnatcher_indep", [[You are {role}! Use your body snatching device on a corpse
to take their role and join the winning team!]])
end)

hook.Add("TTTRolePopupRoleStringOverride", "Bodysnatcher_TTTRolePopupRoleStringOverride", function(client, roleString)
    if not IsPlayer(client) or not client:IsBodysnatcher() then return end

    if bodysnatcher_is_independent:GetBool() then
        return roleString .. "_indep"
    end
    return roleString .. "_jester"
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
    if not IsPlayer(ply) then return end

    if startingRole == ROLE_BODYSNATCHER then
        return ROLE_STRINGS_SHORT[ROLE_BODYSNATCHER]
    end
end)

---------
-- HUD --
---------

hook.Add("TTTHUDInfoPaint", "Bodysnatcher_TTTHUDInfoPaint", function(client, label_left, label_top, active_labels)
    local hide_role = false
    if ConVarExists("ttt_hide_role") then
        hide_role = GetConVar("ttt_hide_role"):GetBool()
    end

    if hide_role then return end

    if client:GetNWBool("WasBodysnatcher", false) then
        local bodysnatcherMode = BODYSNATCHER_REVEAL_ALL
        if client:IsInnocentTeam() then bodysnatcherMode = bodysnatcher_reveal_innocent:GetInt()
        elseif client:IsTraitorTeam() then bodysnatcherMode = bodysnatcher_reveal_traitor:GetInt()
        elseif client:IsMonsterTeam() then bodysnatcherMode = bodysnatcher_reveal_monster:GetInt()
        elseif client:IsIndependentTeam() then bodysnatcherMode = bodysnatcher_reveal_independent:GetInt()
        elseif client:IsJesterTeam() then bodysnatcherMode = bodysnatcher_reveal_jester:GetInt() end
        if bodysnatcherMode ~= BODYSNATCHER_REVEAL_ALL and bodysnatcherMode ~= BODYSNATCHER_REVEAL_ROLES_THAT_CAN_SEE_JESTER then
            surface.SetFont("TabLarge")
            surface.SetTextColor(255, 255, 255, 230)

            local text
            if bodysnatcherMode == BODYSNATCHER_REVEAL_NONE then
                text = LANG.GetParamTranslation("bodysnatcher_hidden_all_hud", { bodysnatcher = ROLE_STRINGS_EXT[ROLE_BODYSNATCHER] })
            elseif bodysnatcherMode == BODYSNATCHER_REVEAL_TEAM then
                text = LANG.GetParamTranslation("bodysnatcher_hidden_team_hud", { bodysnatcher = ROLE_STRINGS_EXT[ROLE_BODYSNATCHER] })
            end
            local _, h = surface.GetTextSize(text)

            -- Move this up based on how many other labels here are
            label_top = label_top + (20 * #active_labels)

            surface.SetTextPos(label_left, ScrH() - label_top - h)
            surface.DrawText(text)

            -- Track that the label was added so others can position accurately
            table.insert(active_labels, "bodysnatcher")
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
    elseif revealMode == BODYSNATCHER_REVEAL_ROLES_THAT_CAN_SEE_JESTER then
        modeString = modeString .. "any role that can see <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. string.lower(LANG.GetTranslation("jesters")) .. "</span>"
    else
        modeString = modeString .. "nobody"
    end
    return modeString .. "."
end

hook.Add("TTTTutorialRoleText", "Bodysnatcher_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_BODYSNATCHER then
        local roleTeam = player.GetRoleTeam(ROLE_BODYSNATCHER, true)
        local roleTeamName, roleColor = GetRoleTeamInfo(roleTeam)
        local html = "The " .. ROLE_STRINGS[ROLE_BODYSNATCHER] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. roleTeamName .. "</span> team whose goal is to steal the role of a dead player using their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>bodysnatching device</span>."

        html = html .. "<span style='display: block; margin-top: 10px;'>After <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>stealing a corpse's role</span>, they take over the goal of their new role.</span>"

        -- Show role
        html = html .. "<span style='display: block; margin-top: 10px;'>The corpse's role <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>will "
        if not bodysnatcher_show_role:GetBool() then
            html = html .. "not "
        end
        html = html .. "be shown</span> while using the bodysnatching device.</span>"

        -- Destroy body
        if bodysnatcher_destroy_body:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>Once the corpse's role has been snatched, the corpse <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>will be destroyed</span>.</span>"
        -- Swap role
        else
            local swap_mode = bodysnatcher_swap_mode:GetInt()
            if swap_mode > BODYSNATCHER_SWAP_MODE_NOTHING then
                html = html .. "<span style='display: block; margin-top: 10px;'>Once the corpse's role has been snatched, the corpse's owning player <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>will become the new bodysnatcher</span>"
                if swap_mode == BODYSNATCHER_SWAP_MODE_IDENTITY then
                    html = html .. ". They are also respawned and have their name, model, and location swapped with the " .. ROLE_STRINGS[ROLE_BODYSNATCHER] .. "."
                else
                    html = html .. " if they are respawned."
                end
                html = html .. "</span>"
            end
        end

        -- Respawn
        if bodysnatcher_respawn:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>If the " .. ROLE_STRINGS[ROLE_BODYSNATCHER] .. " is killed before they join a team, <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>they will respawn</span>"

            local respawnLimit = bodysnatcher_respawn_limit:GetInt()
            if respawnLimit > 0 then
                html = html .. " up to " .. respawnLimit .. " time(s)"
            end

            local respawnDelay = bodysnatcher_respawn_delay:GetInt()
            if respawnDelay > 0 then
                html = html .. " after a " .. respawnDelay .. " second delay"
            end

            html = html .. ".</span>"
        end

        -- Innocent Reveal
        local revealMode = bodysnatcher_reveal_innocent:GetInt()
        local teamName, teamColor = GetRoleTeamInfo(ROLE_TEAM_INNOCENT, true)
        html = html .. "<span style='display: block; margin-top: 10px;'>" .. GetRevealModeString(roleColor, revealMode, teamName, teamColor) .. "</span>"

        -- Traitor Reveal
        revealMode = bodysnatcher_reveal_traitor:GetInt()
        teamName, teamColor = GetRoleTeamInfo(ROLE_TEAM_TRAITOR, true)
        html = html .. "<span style='display: block; margin-top: 10px;'>" .. GetRevealModeString(roleColor, revealMode, teamName, teamColor) .. "</span>"

        -- Monster Reveal
        revealMode = bodysnatcher_reveal_monster:GetInt()
        teamName, teamColor = GetRoleTeamInfo(ROLE_TEAM_MONSTER, true)
        html = html .. "<span style='display: block; margin-top: 10px;'>" .. GetRevealModeString(roleColor, revealMode, teamName, teamColor) .. "</span>"

        -- Independent Reveal
        revealMode = bodysnatcher_reveal_independent:GetInt()
        teamName, teamColor = GetRoleTeamInfo(ROLE_TEAM_INDEPENDENT, true)
        html = html .. "<span style='display: block; margin-top: 10px;'>" .. GetRevealModeString(roleColor, revealMode, teamName, teamColor) .. "</span>"

        -- Jester Reveal
        revealMode = bodysnatcher_reveal_jester:GetInt()
        teamName, teamColor = GetRoleTeamInfo(ROLE_TEAM_JESTER, true)
        html = html .. "<span style='display: block; margin-top: 10px;'>" .. GetRevealModeString(roleColor, revealMode, teamName, teamColor) .. "</span>"

        return html
    end
end)
