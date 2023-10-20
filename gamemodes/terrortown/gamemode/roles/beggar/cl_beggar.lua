local hook = hook
local net = net
local surface = surface
local string = string

local StringUpper = string.upper

local client = nil

-------------
-- CONVARS --
-------------

local beggar_is_independent = GetConVar("ttt_beggar_is_independent")
local beggar_respawn = GetConVar("ttt_beggar_respawn")
local beggar_respawn_limit = GetConVar("ttt_beggar_respawn_limit")
local beggar_respawn_delay = GetConVar("ttt_beggar_respawn_delay")
local beggar_respawn_change_role = GetConVar("ttt_beggar_respawn_change_role")
local beggar_reveal_traitor = GetConVar("ttt_beggar_reveal_traitor")
local beggar_reveal_innocent = GetConVar("ttt_beggar_reveal_innocent")
local beggar_scan = GetConVar("ttt_beggar_scan")
local beggar_scan_time = GetConVar("ttt_beggar_scan_time")

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

    if beggar_is_independent:GetBool() then
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
    local scanMode = beggar_scan:GetInt()
    if scanMode == BEGGAR_SCAN_MODE_DISABLED then return end

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

    if ply:ShouldRevealRoleWhenActive() and ply:IsRoleActive() then return end

    local state = ply:GetNWInt("TTTBeggarScanStage", BEGGAR_UNSCANNED)
    if state ~= BEGGAR_SCANNED_TEAM then return end

    -- This should already be covered by the scan stage check, but just in case
    local scanMode = beggar_scan:GetInt()
    if scanMode == BEGGAR_SCAN_MODE_DISABLED then return end

    if scanMode == BEGGAR_SCAN_MODE_TRAITORS then
        if ply:IsTraitorTeam() then
            return ROLE_NONE, noz, ROLE_TRAITOR
        end
    elseif ply:IsShopRole() then
        return ROLE_NONE, noz, ROLE_NONE
    end
end)

hook.Add("TTTTargetIDPlayerRing", "Beggar_TTTTargetIDPlayerRing", function(ent, cli, ringVisible)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not cli:IsBeggar() then return end
    if not IsPlayer(ent) then return end

    if ent:ShouldRevealRoleWhenActive() and ent:IsRoleActive() then return end

    local state = ent:GetNWInt("TTTBeggarScanStage", BEGGAR_UNSCANNED)
    if state ~= BEGGAR_SCANNED_TEAM then return end

    -- This should already be covered by the scan stage check, but just in case
    local scanMode = beggar_scan:GetInt()
    if scanMode == BEGGAR_SCAN_MODE_DISABLED then return end

    if scanMode == BEGGAR_SCAN_MODE_TRAITORS then
        if ent:IsTraitorTeam() then
            return true, ROLE_COLORS_RADAR[ROLE_TRAITOR]
        end
    elseif ent:IsShopRole() then
        return true, ROLE_COLORS_RADAR[ROLE_NONE]
    end
end)

hook.Add("TTTTargetIDPlayerText", "Beggar_TTTTargetIDPlayerText", function(ent, cli, text, col, secondaryText)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not cli:IsBeggar() then return end
    if not IsPlayer(ent) then return end

    if ent:ShouldRevealRoleWhenActive() and ent:IsRoleActive() then return end

    local state = ent:GetNWInt("TTTBeggarScanStage", BEGGAR_UNSCANNED)
    if state <= BEGGAR_UNSCANNED then return end

    -- This should already be covered by the scan stage check, but just in case
    local scanMode = beggar_scan:GetInt()
    if scanMode == BEGGAR_SCAN_MODE_DISABLED then return end

    local PT = LANG.GetParamTranslation
    if scanMode == BEGGAR_SCAN_MODE_TRAITORS then
        local labelName = "target_not_role"
        local newCol = ROLE_COLORS_RADAR[ROLE_INNOCENT]
        if state == BEGGAR_SCANNED_TEAM and ent:IsTraitorTeam() then
            labelName = "target_unknown_team"
            newCol = ROLE_COLORS_RADAR[ROLE_TRAITOR]
        end
        return PT(labelName, { targettype = StringUpper(ROLE_STRINGS[ROLE_TRAITOR]) }), newCol, false
    else
        local T = LANG.GetTranslation
        local labelName = "target_not_role"
        local newCol = ROLE_COLORS_RADAR[ROLE_NONE]
        if state == BEGGAR_SCANNED_TEAM and ent:IsShopRole() then
            labelName = "target_unknown_team"
        end
        return PT(labelName, { targettype = StringUpper(T("shoprole")) }), newCol, false
    end
end)

ROLE_IS_TARGETID_OVERRIDDEN[ROLE_BEGGAR] = function(ply, target, showJester)
    if not IsPlayer(target) then return end

    if target:ShouldRevealRoleWhenActive() and target:IsRoleActive() then return end

    local state = target:GetNWInt("TTTBeggarScanStage", BEGGAR_UNSCANNED)
    if state <= BEGGAR_UNSCANNED then return end

    -- Info is only overridden for players viewed by the beggar
    if not ply:IsBeggar() then return end

    -- This should already be covered by the scan stage check, but just in case
    local scanMode = beggar_scan:GetInt()
    if scanMode == BEGGAR_SCAN_MODE_DISABLED then return end

    -- Icon and ring are shown for the target group, text is shown for everyone
    local infoShown = false
    if scanMode == BEGGAR_SCAN_MODE_TRAITORS then
        if target:IsTraitorTeam() then
            infoShown = true
        end
    elseif target:IsShopRole() then
        infoShown = true
    end

    ------ icon,      ring,      text
    return infoShown, infoShown, true
end

----------------
-- SCOREBOARD --
----------------

hook.Add("TTTScoreboardPlayerRole", "Beggar_TTTScoreboardPlayerRole", function(ply, cli, c, roleStr)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not cli:IsBeggar() then return end
    if not IsPlayer(ply) then return end

    if ply:ShouldRevealRoleWhenActive() and ply:IsRoleActive() then return end

    local state = ply:GetNWInt("TTTBeggarScanStage", BEGGAR_UNSCANNED)
    if state ~= BEGGAR_SCANNED_TEAM then return end

    -- This should already be covered by the scan stage check, but just in case
    local scanMode = beggar_scan:GetInt()
    if scanMode == BEGGAR_SCAN_MODE_DISABLED then return end

    if scanMode == BEGGAR_SCAN_MODE_TRAITORS then
        if ply:IsTraitorTeam() then
            return ROLE_COLORS_SCOREBOARD[ROLE_TRAITOR], "nil"
        end
    elseif ply:IsShopRole() then
        return ROLE_COLORS_SCOREBOARD[ROLE_NONE], "nil"
    end
end)

ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_BEGGAR] = function(ply, target)
    if not ply:IsBeggar() then return end
    if not IsPlayer(target) then return end

    if target:ShouldRevealRoleWhenActive() and target:IsRoleActive() then return end

    local state = target:GetNWInt("TTTBeggarScanStage", BEGGAR_UNSCANNED)
    if state ~= BEGGAR_SCANNED_TEAM then return end

    -- This should already be covered by the scan stage check, but just in case
    local scanMode = beggar_scan:GetInt()
    if scanMode == BEGGAR_SCAN_MODE_DISABLED then return end

    -- Info is only overridden for targetted players viewed by the beggar
    local infoShown = false
    if scanMode == BEGGAR_SCAN_MODE_TRAITORS then
        if target:IsTraitorTeam() then
            infoShown = true
        end
    elseif target:IsShopRole() then
        infoShown = true
    end

    ------ name,  role
    return false, infoShown
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
        local beggarMode = BEGGAR_REVEAL_ALL
        if cli:IsInnocent() then beggarMode = beggar_reveal_innocent:GetInt()
        elseif cli:IsTraitor() then beggarMode = beggar_reveal_traitor:GetInt() end
        if beggarMode ~= BEGGAR_REVEAL_ALL and beggarMode ~= BEGGAR_REVEAL_ROLES_THAT_CAN_SEE_JESTER then
            surface.SetFont("TabLarge")
            surface.SetTextColor(255, 255, 255, 230)

            local text
            if beggarMode == BEGGAR_REVEAL_NONE then
                text = LANG.GetParamTranslation("beggar_hidden_all_hud", { beggar = ROLE_STRINGS_EXT[ROLE_BEGGAR] })
            elseif beggarMode == BEGGAR_REVEAL_TRAITORS then
                text = LANG.GetParamTranslation("beggar_hidden_innocent_hud", { beggar = ROLE_STRINGS_EXT[ROLE_BEGGAR], innocents = ROLE_STRINGS_PLURAL[ROLE_INNOCENT] })
            elseif beggarMode == BEGGAR_REVEAL_INNOCENTS then
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

    local scanMode = beggar_scan:GetInt()
    if scanMode == BEGGAR_SCAN_MODE_DISABLED then return end

    if beggar_show_scan_radius:GetBool() then
        surface.DrawCircle(ScrW() / 2, ScrH() / 2, math.Round(ScrW() / 6), 0, 255, 0, 155)
    end

    local state = client:GetNWInt("TTTBeggarScannerState", BEGGAR_SCANNER_IDLE)
    if state == BEGGAR_SCANNER_IDLE then
        return
    end

    local scan = beggar_scan_time:GetInt()
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
    if revealMode == BEGGAR_REVEAL_ALL then
        modeString = modeString .. "everyone"
    elseif revealMode == BEGGAR_REVEAL_TRAITORS then
        local revealColor = ROLE_COLORS[ROLE_TRAITOR]
        modeString = modeString .. "only <span style='color: rgb(" .. revealColor.r .. ", " .. revealColor.g .. ", " .. revealColor.b .. ")'>" .. string.lower(LANG.GetTranslation("traitors")) .. "</span>"
    elseif revealMode == BEGGAR_REVEAL_INNOCENTS then
        local revealColor = ROLE_COLORS[ROLE_TRAITOR]
        modeString = modeString .. "only <span style='color: rgb(" .. revealColor.r .. ", " .. revealColor.g .. ", " .. revealColor.b .. ")'>" .. string.lower(LANG.GetTranslation("innocents")) .. "</span>"
    elseif revealMode == BEGGAR_REVEAL_ROLES_THAT_CAN_SEE_JESTER then
       modeString = modeString .. "any role that can see <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. string.lower(LANG.GetTranslation("jesters")) .. "</span>"
    else
        modeString = modeString .. "nobody"
    end
    return modeString .. "."
end

hook.Add("TTTTutorialRoleText", "Beggar_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_BEGGAR then
        local roleTeam = player.GetRoleTeam(ROLE_BEGGAR, true)
        local roleTeamName, roleColor = GetRoleTeamInfo(roleTeam)
        local html = "The " .. ROLE_STRINGS[ROLE_BEGGAR] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. roleTeamName .. "</span> team whose goal is to convince another players to give them a shop item."

        html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_BEGGAR] .. " then <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>joins the team</span> of whichever player <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>bought the item</span> they are given.</span>"

        -- Respawn
        if beggar_respawn:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>If the " .. ROLE_STRINGS[ROLE_BEGGAR] .. " is killed before they join a team, <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>they will respawn</span>"

            local respawnLimit = beggar_respawn_limit:GetInt()
            if respawnLimit > 0 then
                html = html .. " up to " .. respawnLimit .. " time(s)"
            end

            local respawnDelay = beggar_respawn_delay:GetInt()
            if respawnDelay > 0 then
                html = html .. " after a " .. respawnDelay .. " second delay"
            end

            html = html .. ".</span>"

            if beggar_respawn_change_role:GetBool() then
                html = html .. "<span style='display: block; margin-top: 10px;'>When respawning, the " .. ROLE_STRINGS[ROLE_BEGGAR] .. " will switch to the opposite team of their killer.</span>"
            end
        end

        -- Innocent Reveal
        local revealMode = beggar_reveal_innocent:GetInt()
        local teamName, teamColor = GetRoleTeamInfo(ROLE_TEAM_INNOCENT, true)
        html = html .. "<span style='display: block; margin-top: 10px;'>" .. GetRevealModeString(roleColor, revealMode, teamName, teamColor) .. "</span>"

        -- Traitor Reveal
        revealMode = beggar_reveal_traitor:GetInt()
        teamName, teamColor = GetRoleTeamInfo(ROLE_TEAM_TRAITOR, true)
        html = html .. "<span style='display: block; margin-top: 10px;'>" .. GetRevealModeString(roleColor, revealMode, teamName, teamColor) .. "</span>"

        -- Traitor scanning
        local scanMode = beggar_scan:GetInt()
        if scanMode > BEGGAR_SCAN_MODE_DISABLED then
            local mode_string
            if scanMode == BEGGAR_SCAN_MODE_TRAITORS then
                mode_string = "members of the " .. LANG.GetTranslation("traitor") ..  " team"
            else
                mode_string = "out if they have a shop"
            end
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_BEGGAR] .. " also has the ability to scan players to find " .. mode_string .. ".</span>"
        end

        return html
    end
end)
