local hook = hook
local net = net
local surface = surface
local string = string

local StringUpper = string.upper

local client = nil

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Beggar_Translations_Initialize", function()
    -- ConVars
    LANG.AddToLanguage("english", "beggar_config_show_radius", "Show tracking radius circle")

    -- Events
    LANG.AddToLanguage("english", "ev_beggar_converted", "The {beggar} ({victim}) was converted to {team} by {attacker}")
    LANG.AddToLanguage("english", "ev_beggar_killed", "The {beggar} ({victim}) was killed by {attacker} but respawned")
    LANG.AddToLanguage("english", "ev_beggar_killed_delay", "The {beggar} ({victim}) was killed by {attacker} but will respawn in {delay} seconds")

    -- HUD
    LANG.AddToLanguage("english", "beggar_hidden_all_hud", "You still appear as {beggar} to others")
    LANG.AddToLanguage("english", "beggar_hidden_innocent_hud", "You still appear as {beggar} to {innocents}")
    LANG.AddToLanguage("english", "beggar_hidden_traitor_hud", "You still appear as {beggar} to {traitors}")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_beggar_jester", [[You are {role}! {traitors} think you are {ajester} and you
deal no damage. However, if you can convince someone to give
you a shop item you will join their team.]])
    LANG.AddToLanguage("english", "info_popup_beggar_indep", [[You are {role}! If you can convince someone to give
you a shop item you will join their team.]])
end)

hook.Add("TTTRolePopupRoleStringOverride", "Beggar_TTTRolePopupRoleStringOverride", function(cli, roleString)
    if not IsPlayer(cli) or not cli:IsBeggar() then return end

    if GetGlobalBool("ttt_beggars_are_independent", false) then
        return roleString .. "_indep"
    end
    return roleString .. "_jester"
end)

-------------
-- CONVARS --
-------------

local beggar_show_scan_radius = CreateClientConVar("ttt_beggar_show_scan_radius", "0", true, false, "Whether the scan radius circle should show", 0, 1)

hook.Add("TTTSettingsRolesTabSections", "Beggar_TTTSettingsRolesTabSections", function(role, parentForm)
    if role ~= ROLE_BEGGAR then return end
    if not GetGlobalBool("ttt_beggar_traitor_scan", false) then return true end

    parentForm:CheckBox(LANG.GetTranslation("beggar_config_show_radius"), "ttt_beggar_show_scan_radius")
    return true
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

-- Show that this person was a beggar via the icon
hook.Add("TTTScoringSummaryRender", "Beggar_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
    if not IsPlayer(ply) then return end

    if (ply:IsInnocent() or ply:IsTraitor()) and ply:GetNWBool("WasBeggar", false) then
        return ROLE_STRINGS_SHORT[ROLE_BEGGAR], groupingRole, roleColor, name
    end
end)

---------------
-- TARGET ID --
---------------

hook.Add("TTTTargetIDPlayerRoleIcon", "Beggar_TTTTargetIDPlayerRoleIcon", function(ply, cli, role, noz, colorRole, hideBeggar, showJester, hideBodysnatcher)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not cli:IsBeggar() then return end

    local state = ply:GetNWInt("TTTBeggarScanStage", BEGGAR_UNSCANNED)
    if state == BEGGAR_SCANNED_TEAM and ply:IsTraitorTeam() then
        return ROLE_NONE, noz, ROLE_TRAITOR
    end
end)

hook.Add("TTTTargetIDPlayerRing", "Beggar_TTTTargetIDPlayerRing", function(ent, cli, ringVisible)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not cli:IsBeggar() then return end
    if not IsPlayer(ent) then return end

    local state = ent:GetNWInt("TTTBeggarScanStage", BEGGAR_UNSCANNED)
    if state == BEGGAR_SCANNED_TEAM and ent:IsTraitorTeam() then
        return true, ROLE_COLORS_RADAR[ROLE_TRAITOR]
    end
end)

hook.Add("TTTTargetIDPlayerText", "Beggar_TTTTargetIDPlayerText", function(ent, cli, text, col, secondaryText)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not cli:IsBeggar() then return end
    if not IsPlayer(ent) then return end

    local state = ent:GetNWInt("TTTBeggarScanStage", BEGGAR_UNSCANNED)
    if state > BEGGAR_UNSCANNED then
        local PT = LANG.GetParamTranslation
        local labelName = "target_not_role"
        local newCol = ROLE_COLORS_RADAR[ROLE_INNOCENT]
        if state == BEGGAR_SCANNED_TEAM and ent:IsTraitorTeam() then
            labelName = "target_unknown_team"
            newCol = ROLE_COLORS_RADAR[ROLE_TRAITOR]
        end
        return PT(labelName, { targettype = StringUpper(ROLE_STRINGS[ROLE_TRAITOR]) }), newCol, false
    end
end)

ROLE_IS_TARGETID_OVERRIDDEN[ROLE_BEGGAR] = function(ply, target, showJester)
    if not IsPlayer(target) then return end

    local state = target:GetNWInt("TTTBeggarScanStage", BEGGAR_UNSCANNED)
    if state <= BEGGAR_UNSCANNED then return end

    -- Info is only overridden for players viewed by the beggar
    if not ply:IsBeggar() then return end

    -- Icon and ring are shown for traitors, text is shown for everyone
    local targetIsTraitor = target:IsTraitorTeam()
    ------ icon,            ring,            text
    return targetIsTraitor, targetIsTraitor, true
end

----------------
-- SCOREBOARD --
----------------

hook.Add("TTTScoreboardPlayerRole", "Beggar_TTTScoreboardPlayerRole", function(ply, cli, c, roleStr)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not cli:IsBeggar() then return end
    if not IsPlayer(ply) then return end

    local state = ply:GetNWInt("TTTBeggarScanStage", BEGGAR_UNSCANNED)
    if state == BEGGAR_SCANNED_TEAM and ply:IsTraitorTeam()then
        return ROLE_COLORS_SCOREBOARD[ROLE_TRAITOR], "nil"
    end
end)

ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_BEGGAR] = function(ply, target)
    if not IsPlayer(target) then return end

    local state = target:GetNWInt("TTTBeggarScanStage", BEGGAR_UNSCANNED)
    if state ~= BEGGAR_SCANNED_TEAM then return end

    -- Info is only overridden for traitors viewed by the beggar
    if not ply:IsBeggar() or not target:IsTraitorTeam() then return end

    ------ name,  role
    return false, true
end

--------------
-- HUD INFO --
--------------

hook.Add("TTTHUDInfoPaint", "Beggar_TTTHUDInfoPaint", function(cli, label_left, label_top, active_labels)
    local hide_role = false
    if ConVarExists("ttt_hide_role") then
        hide_role = GetConVar("ttt_hide_role"):GetBool()
    end

    if hide_role then return end

    if (cli:IsInnocent() or cli:IsTraitor()) and cli:GetNWBool("WasBeggar", false) then
        local beggarMode = ANNOUNCE_REVEAL_ALL
        if cli:IsInnocent() then beggarMode = GetGlobalInt("ttt_beggar_reveal_innocent", ANNOUNCE_REVEAL_TRAITORS)
        elseif cli:IsTraitor() then beggarMode = GetGlobalInt("ttt_beggar_reveal_traitor", ANNOUNCE_REVEAL_ALL) end
        if beggarMode ~= ANNOUNCE_REVEAL_ALL then
            surface.SetFont("TabLarge")
            surface.SetTextColor(255, 255, 255, 230)

            local text
            if beggarMode == ANNOUNCE_REVEAL_NONE then
                text = LANG.GetParamTranslation("beggar_hidden_all_hud", { beggar = ROLE_STRINGS_EXT[ROLE_BEGGAR] })
            elseif beggarMode == ANNOUNCE_REVEAL_TRAITORS then
                text = LANG.GetParamTranslation("beggar_hidden_innocent_hud", { beggar = ROLE_STRINGS_EXT[ROLE_BEGGAR], innocents = ROLE_STRINGS_PLURAL[ROLE_INNOCENT] })
            elseif beggarMode == ANNOUNCE_REVEAL_INNOCENTS then
                text = LANG.GetParamTranslation("beggar_hidden_traitor_hud", { beggar = ROLE_STRINGS_EXT[ROLE_BEGGAR], traitors = ROLE_STRINGS_PLURAL[ROLE_TRAITOR] })
            end
            local _, h = surface.GetTextSize(text)

            -- Move this up based on how many other labels here are
            label_top = label_top + (20 * #active_labels)

            surface.SetTextPos(label_left, ScrH() - label_top - h)
            surface.DrawText(text)

            -- Track that the label was added so others can position accurately
            table.insert(active_labels, "beggar")
        end
    end
end)

-----------------
-- SCANNER HUD --
-----------------

hook.Add("HUDPaint", "Beggar_HUDPaint", function()
    if not client then
        client = LocalPlayer()
    end

    if not IsValid(client) or client:IsSpec() or GetRoundState() ~= ROUND_ACTIVE then return end
    if not client:IsBeggar() then return end

    if beggar_show_scan_radius:GetBool() then
        surface.DrawCircle(ScrW() / 2, ScrH() / 2, math.Round(ScrW() / 6), 0, 255, 0, 155)
    end

    local state = client:GetNWInt("TTTBeggarScannerState", BEGGAR_SCANNER_IDLE)
    if state == BEGGAR_SCANNER_IDLE then
        return
    end

    local scan = GetGlobalInt("ttt_beggar_traitor_scan_time", 15)
    local time = client:GetNWFloat("TTTBeggarScannerStartTime", -1) + scan

    local x = ScrW() / 2.0
    local y = ScrH() / 2.0

    y = y + (y / 3)

    local w = 300

    if state == BEGGAR_SCANNER_LOCKED or state == BEGGAR_SCANNER_SEARCHING then
        if time < 0 then return end

        local color = Color(255, 255, 0, 155)
        if state == BEGGAR_SCANNER_LOCKED then
            color = Color(0, 255, 0, 155)
        end

        local progress = math.min(1, 1 - ((time - CurTime()) / scan))

        CRHUD:PaintProgressBar(x, y, w, color, client:GetNWString("TTTBeggarScannerMessage", ""), progress)
    elseif state == BEGGAR_SCANNER_LOST then
        local color = Color(200 + math.sin(CurTime() * 32) * 50, 0, 0, 155)
        CRHUD:PaintProgressBar(x, y, w, color, client:GetNWString("TTTBeggarScannerMessage", ""), 1)
    end
end)

--------------
-- TUTORIAL --
--------------

local function GetRevealModeString(roleColor, revealMode, teamName, teamColor)
    local modeString = "When joining the <span style='color: rgb(" .. teamColor.r .. ", " .. teamColor.g .. ", " .. teamColor.b .. ")'>" .. string.lower(teamName) .. "</span> team, the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. ROLE_STRINGS[ROLE_BEGGAR] .. "</span>'s new role will be revealed to "
    if revealMode == ANNOUNCE_REVEAL_ALL then
        modeString = modeString .. "everyone"
    elseif revealMode == ANNOUNCE_REVEAL_TRAITORS then
        local revealColor = ROLE_COLORS[ROLE_TRAITOR]
        modeString = modeString .. "only <span style='color: rgb(" .. revealColor.r .. ", " .. revealColor.g .. ", " .. revealColor.b .. ")'>" .. string.lower(LANG.GetTranslation("traitors")) .. "</span>"
    elseif revealMode == ANNOUNCE_REVEAL_INNOCENTS then
        local revealColor = ROLE_COLORS[ROLE_TRAITOR]
        modeString = modeString .. "only <span style='color: rgb(" .. revealColor.r .. ", " .. revealColor.g .. ", " .. revealColor.b .. ")'>" .. string.lower(LANG.GetTranslation("innocents")) .. "</span>"
    else
        modeString = modeString .. "nobody"
    end
    return modeString .. "."
end

hook.Add("TTTTutorialRoleText", "Beggar_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_BEGGAR then
        local roleTeam = player.GetRoleTeam(ROLE_BEGGAR, true)
        local roleTeamName, roleColor = GetRoleTeamInfo(roleTeam)
        local html = "The " .. ROLE_STRINGS[ROLE_BEGGAR] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. roleTeamName .. "</span> role whose goal is to convince another players to give them a shop item."

        html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_BEGGAR] .. " then <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>joins the team</span> of whichever player <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>bought the item</span> they are given.</span>"

        -- Respawn
        if GetGlobalBool("ttt_beggar_respawn", false) then
            html = html .. "<span style='display: block; margin-top: 10px;'>If the " .. ROLE_STRINGS[ROLE_BEGGAR] .. " is killed before they join a team, <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>they will respawn</span>"

            local respawnLimit = GetGlobalInt("ttt_beggar_respawn_limit", 0)
            if respawnLimit > 0 then
                html = html .. " up to " .. respawnLimit .. " time(s)"
            end

            local respawnDelay = GetGlobalInt("ttt_beggar_respawn_delay", 0)
            if respawnDelay > 0 then
                html = html .. " after a " .. respawnDelay .. " second delay"
            end

            html = html .. ".</span>"

            if GetGlobalBool("ttt_beggar_respawn_change_role", false) then
                html = html .. "<span style='display: block; margin-top: 10px;'>When respawning, the " .. ROLE_STRINGS[ROLE_BEGGAR] .. " will switch to the opposite team of their killer.</span>"
            end
        end

        -- Innocent Reveal
        local revealMode = GetGlobalInt("ttt_beggar_reveal_innocent", ANNOUNCE_REVEAL_TRAITORS)
        local teamName, teamColor = GetRoleTeamInfo(ROLE_TEAM_INNOCENT, true)
        html = html .. "<span style='display: block; margin-top: 10px;'>" .. GetRevealModeString(roleColor, revealMode, teamName, teamColor) .. "</span>"

        -- Traitor Reveal
        revealMode = GetGlobalInt("ttt_beggar_reveal_traitor", ANNOUNCE_REVEAL_ALL)
        teamName, teamColor = GetRoleTeamInfo(ROLE_TEAM_TRAITOR, true)
        html = html .. "<span style='display: block; margin-top: 10px;'>" .. GetRevealModeString(roleColor, revealMode, teamName, teamColor) .. "</span>"

        -- Traitor scanning
        if GetGlobalBool("ttt_beggar_traitor_scan", false) then
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_BEGGAR] .. " also has the ability to scan players to find members of the " .. LANG.GetTranslation("traitor") ..  " team.</span>"
        end

        return html
    end
end)
