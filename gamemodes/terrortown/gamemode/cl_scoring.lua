-- Game report

include("cl_awards.lua")

local chat = chat
local concommand = concommand
local draw = draw
local file = file
local hook = hook
local input = input
local ipairs = ipairs
local math = math
local net = net
local pairs = pairs
local player = player
local surface = surface
local string = string
local table = table
local timer = timer
local util = util
local vgui = vgui
local parentPanel, parentTabs, closeButton, saveButton

local StringUpper = string.upper

CLSCORE = {}
CLSCORE.Events = {}
CLSCORE.Scores = {}
CLSCORE.Roles = {}
CLSCORE.Players = {}
CLSCORE.StartTime = 0
CLSCORE.Panel = nil

CLSCORE.EventDisplay = {}

include("scoring_shd.lua")

local skull_icon = Material("HUD/killicons/default")

surface.CreateFont("WinHuge", {
    font = "Trebuchet24",
    size = 72,
    weight = 1000,
    shadow = true,
    extended = true
})

surface.CreateFont("WinLarge", {
    font = "Trebuchet24",
    size = 48,
    weight = 1000,
    shadow = true,
    extended = true
})

surface.CreateFont("WinMedium", {
    font = "Trebuchet24",
    size = 40,
    weight = 1000,
    shadow = true,
    extended = true
})

surface.CreateFont("WinSmall", {
    font = "Trebuchet24",
    size = 32,
    weight = 1000,
    shadow = true,
    extended = true
})

surface.CreateFont("WinTiny", {
    font = "Trebuchet24",
    size = 24,
    weight = 1000,
    shadow = true,
    extended = true
})

surface.CreateFont("ScoreNicks", {
    font = "Trebuchet24",
    size = 32,
    weight = 100
})

surface.CreateFont("IconText", {
    font = "Trebuchet24",
    size = 24,
    weight = 100
})

-- so much text here I'm using shorter names than usual
local T = LANG.GetTranslation
local PT = LANG.GetParamTranslation
local spawnedPlayers = {}
local disconnected = {}
local customEvents = {}
local secondary_win_roles = {}

function CLSCORE:ResetScoreboard()
    spawnedPlayers = {}
    disconnected = {}
    customEvents = {}
    secondary_win_roles = {}
end

function CLSCORE:AddEvent(e, offset)
    e["t"] = math.Round(CurTime() + (offset or 0), 2)
    table.insert(customEvents, e)
end

function CLSCORE:PlayerSpawned(ply)
    local name = ply:Nick()
    local role = ply:GetRole()
    table.insert(spawnedPlayers, name)
    CLSCORE:AddEvent({
        id = EVENT_SPAWN,
        ply = name,
        rol = role
    })
end

local function FitNicknameLabel(nicklbl, maxwidth, getstring, args)
    local nickw, _ = nicklbl:GetSize()
    while nickw > maxwidth do
        local nickname = nicklbl:GetText()
        nickname, args = getstring(nickname, args)
        nicklbl:SetText(nickname)
        nicklbl:SizeToContents()
        nickw, _ = nicklbl:GetSize()
    end
end

net.Receive("TTT_Defibrillated", function(len)
    local name = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_DEFIBRILLATED,
        vic = name
    })
end)

net.Receive("TTT_PlayerDisconnected", function(len)
    local name = net.ReadString()
    table.insert(disconnected, name)
    CLSCORE:AddEvent({
        id = EVENT_DISCONNECTED,
        vic = name
    })
end)

net.Receive("TTT_LogInfo", function(len)
    CLSCORE:AddEvent({
        id = EVENT_LOG,
        txt = net.ReadString()
    })
end)

net.Receive("TTT_RoleChanged", function(len)
    local s64 = net.ReadString()
    local role = net.ReadInt(8)
    local ply = player.GetBySteamID64(s64)
    local name = "UNKNOWN"
    if IsValid(ply) then
        name = ply:Nick()
    end

    CLSCORE:AddEvent({
        id = EVENT_ROLECHANGE,
        ply = name,
        rol = role
    })
end)

function CLSCORE:GetDisplay(key, event)
    local displayfns = self.EventDisplay[event.id]
    if not displayfns then return end
    local keyfn = displayfns[key]
    if not keyfn then return end

    return keyfn(event)
end

function CLSCORE:TextForEvent(e)
    return self:GetDisplay("text", e)
end

function CLSCORE:IconForEvent(e)
    return self:GetDisplay("icon", e)
end

function CLSCORE:TimeForEvent(e)
    local t = e.t - self.StartTime
    if t >= 0 then
        return util.SimpleTime(t, "%02i:%02i")
    else
        return "     "
    end
end

-- Tell CLSCORE how to display an event. See cl_scoring_events for examples.
-- Pass an empty table to keep an event from showing up.
function CLSCORE.DeclareEventDisplay(event_id, event_fns)
    -- basic input vetting, can't check returned value types because the
    -- functions may be impure
    if not tonumber(event_id) then
        error("Event ??? display: invalid event id", 2)
    end
    if not istable(event_fns) then
        error(string.format("Event %d display: no display functions found.", event_id), 2)
    end
    if not event_fns.text then
        error(string.format("Event %d display: no text display function found.", event_id), 2)
    end
    if not event_fns.icon then
        error(string.format("Event %d display: no icon and tooltip display function found.", event_id), 2)
    end

    CLSCORE.EventDisplay[event_id] = event_fns
end

function CLSCORE:FillDList(dlst)
    local allEvents = self.Events
    table.Merge(allEvents, customEvents)
    table.SortByMember(allEvents, "t", true)

    for _, e in pairs(allEvents) do
        local etxt = self:TextForEvent(e)
        local eicon, ttip = self:IconForEvent(e)
        local etime = self:TimeForEvent(e)

        if etxt then
            if eicon then
                local mat = eicon
                eicon = vgui.Create("DImage")
                eicon:SetMaterial(mat)
                eicon:SetTooltip(ttip)
                eicon:SetKeepAspect(true)
                eicon:SizeToContents()
            end

            dlst:AddLine(etime, eicon, "  " .. etxt)
        end
    end
end

local function ValidAward(a)
    return a and a.nick and a.text and a.title and a.priority
end

local function GetWinTitle(wintype)
    local wintitles = {
        [WIN_INNOCENT] = { txt = "hilite_win_role_plural", params = { role = StringUpper(ROLE_STRINGS_PLURAL[ROLE_INNOCENT]) }, c = ROLE_COLORS[ROLE_INNOCENT] },
        [WIN_TRAITOR] = { txt = "hilite_win_role_plural", params = { role = StringUpper(ROLE_STRINGS_PLURAL[ROLE_TRAITOR]) }, c = ROLE_COLORS[ROLE_TRAITOR] },
        [WIN_MONSTER] = { txt = "hilite_win_role_plural", params = { role = StringUpper(T("monsters")) }, c = GetRoleTeamColor(ROLE_TEAM_MONSTER) }
    }
    if GetConVar("ttt_roundtime_win_draw"):GetBool() then
        wintitles[WIN_TIMELIMIT] = { txt = "hilite_win_draw", c = ROLE_COLORS[ROLE_NONE] }
    else
        -- If it's not a draw, the innocents win
        wintitles[WIN_TIMELIMIT] = wintitles[WIN_INNOCENT]
    end
    local title = wintitles[wintype]
    local new_title = hook.Call("TTTScoringWinTitle", nil, wintype, wintitles, title)
    if new_title then title = new_title end

    local secondary_wins = {}
    hook.Call("TTTScoringSecondaryWins", nil, wintype, secondary_wins)
    secondary_win_roles = secondary_wins

    -- If this was a monster win, check that both roles are part of the monsters team still
    if wintype == WIN_MONSTER then
        local monster_role = GetWinningMonsterRole()
        -- If a single support role (zombies or vampires) won as the "monsters team", use their role as the label
        if monster_role then
            title.params = { role = StringUpper(ROLE_STRINGS_PLURAL[monster_role]) }
        -- Otherwise use the monsters label
        else
            title.params = { role = StringUpper(T("monsters")) }
        end
    end

    -- Let other addons override this after the roles have set their own win screens
    return hook.Call("TTTScoringWinTitleOverride", nil, wintype, wintitles, title) or title
end

local function GetFontForWinTitle(wintxt, width)
    -- Scale the title down if it's too wide
    local winfont_options = {"WinHuge", "WinLarge", "WinMedium", "WinSmall", "WinTiny"}
    local winfont = "WinHuge"
    for _, font in ipairs(winfont_options) do
        -- If we got to this loop iteration we want to use this font
        winfont = font

        surface.SetFont(font)
        local textWidth, _ = surface.GetTextSize(wintxt)
        if textWidth < width then
            break
        end
    end

    -- Reset the font now that we're done messing with it
    surface.SetFont("Default")

    return winfont
end

function CLSCORE:BuildEventLogPanel(dpanel)
    local margin = 10

    local w, h = dpanel:GetSize()

    local dlist = vgui.Create("DListView", dpanel)
    dlist:SetPos(0, 0)
    dlist:SetSize(w, h - margin * 2)
    dlist:SetSortable(true)
    dlist:SetMultiSelect(false)

    local timecol = dlist:AddColumn(T("col_time"))
    local iconcol = dlist:AddColumn("")
    local eventcol = dlist:AddColumn(T("col_event"))

    iconcol:SetFixedWidth(18)
    timecol:SetFixedWidth(40)

    -- If sortable is off, no background is drawn for the headers which looks
    -- terrible. So enable it, but disable the actual use of sorting.
    iconcol.Header:SetDisabled(true)
    timecol.Header:SetDisabled(true)
    eventcol.Header:SetDisabled(true)

    self:FillDList(dlist)

    dlist:SetDataHeight(18)
end

function CLSCORE:BuildScorePanel(dpanel)
    local w, h = dpanel:GetSize()

    local dlist = vgui.Create("DListView", dpanel)
    dlist:SetPos(0, 0)
    dlist:SetSize(w, h)
    dlist:SetSortable(true)
    dlist:SetMultiSelect(false)

    local monsters_exist = false
    for _, exist in pairs(MONSTER_ROLES) do
        if exist then
            monsters_exist = true
            break
        end
    end
    local colnames = { { "", 18 }, "col_player", "col_role", { "col_kills1", 52 }, { "col_kills2", 60 }, "col_kills3", "col_kills4" }
    if monsters_exist then
        table.insert(colnames, { "col_kills5", 52 })
    end
    table.Add(colnames, { { "col_totalkills", 52 }, { "col_points", 40 }, "col_team", "col_total" })

    for _, name in pairs(colnames) do
        local width = nil
        -- If this column has a width defined, extract that out
        if type(name) == "table" then
            width = name[2]
            name = name[1]
        end
        local col
        if #name == 0 then
            -- skull icon column
            col = dlist:AddColumn("")
        else
            local colname = PT(name, {
                traitor = ROLE_STRINGS[ROLE_TRAITOR],
                jester = ROLE_STRINGS[ROLE_JESTER]
            })
            col = dlist:AddColumn(colname)
        end

        if width ~= nil then
            col:SetFixedWidth(width)
        end
    end

    -- the type of win condition triggered is relevant for team bonus
    local wintype = WIN_NONE
    for i = #self.Events, 1, -1 do
        local e = self.Events[i]
        if e.id == EVENT_FINISH then
            wintype = e.win
            break
        end
    end

    local scores = self.Scores
    local nicks = self.Players
    local bonus = ScoreTeamBonus(scores, wintype)

    for id, s in pairs(scores) do
        if id ~= -1 then
            local was_traitor = TRAITOR_ROLES[s.role]
            local was_innocent = INNOCENT_ROLES[s.role]
            local was_jester = JESTER_ROLES[s.role]
            local was_indep = INDEPENDENT_ROLES[s.role]
            local was_monster = MONSTER_ROLES[s.role]
            local role_string = ROLE_STRINGS_RAW[s.role]

            local surv = ""
            if s.deaths > 0 then
                surv = vgui.Create("ColoredBox", dlist)
                surv:SetColor(Color(150, 50, 50))
                surv:SetBorder(false)
                surv:SetSize(18, 18)

                local skull = vgui.Create("DImage", surv)
                skull:SetMaterial(skull_icon)
                skull:SetTooltip("Dead")
                skull:SetKeepAspect(true)
                skull:SetSize(18, 18)
            end

            local points_own = KillsToPoints(s, was_traitor, was_innocent)
            local points_team = bonus.innos
            if was_traitor then
                points_team = bonus.traitors
            elseif was_jester then
                points_team = bonus.jesters
            elseif was_indep then
                points_team = bonus.indeps
            elseif was_monster then
                points_team = bonus.monsters
            end
            local points_total = points_own + points_team

            local total_kills = s.innos + s.traitors + s.jesters + s.indeps
            local l
            if monsters_exist then
                l = dlist:AddLine(surv, nicks[id], role_string, s.innos, s.traitors, s.jesters, s.indeps, s.monsters, total_kills + s.monsters, points_own, points_team, points_total)
            else
                l = dlist:AddLine(surv, nicks[id], role_string, s.innos, s.traitors, s.jesters, s.indeps, total_kills, points_own, points_team, points_total)
            end

            -- center align
            for _, col in pairs(l.Columns) do
                col:SetContentAlignment(5)
            end

            -- when sorting on the column showing survival, we would get an error
            -- because images can't be sorted, so instead hack in a dummy value
            local surv_col = l.Columns[1]
            if surv_col then
                surv_col.Value = type(surv_col.Value) == "Panel" and "1" or "0"
            end
        end
    end

    dlist:SortByColumn(6)
end

function CLSCORE:AddAward(y, pw, award, dpanel)
    local nick = award.nick
    local text = award.text
    local title = StringUpper(award.title)

    local titlelbl = vgui.Create("DLabel", dpanel)
    titlelbl:SetText(title)
    titlelbl:SetFont("TabLarge")
    titlelbl:SizeToContents()
    local tiw, tih = titlelbl:GetSize()

    local nicklbl = vgui.Create("DLabel", dpanel)
    nicklbl:SetText(nick)
    nicklbl:SetFont("DermaDefaultBold")
    nicklbl:SizeToContents()
    local nw, nh = nicklbl:GetSize()

    local txtlbl = vgui.Create("DLabel", dpanel)
    txtlbl:SetText(text)
    txtlbl:SetFont("DermaDefault")
    txtlbl:SizeToContents()
    local tw, _ = txtlbl:GetSize()

    titlelbl:SetPos((pw - tiw) / 2, y)
    y = y + tih + 2

    local fw = nw + tw + 5
    local fx = ((pw - fw) / 2)
    nicklbl:SetPos(fx, y)
    txtlbl:SetPos(fx + nw + 5, y)

    y = y + nh

    return y
end

function CLSCORE:BuildSummaryPanel(dpanel)
    local default_title = GetWinTitle(WIN_INNOCENT)
    local title
    for i = #self.Events, 1, -1 do
        local e = self.Events[i]
        if e.id == EVENT_FINISH then
            title = GetWinTitle(e.win)
            break
        end
    end

    -- Sanity check for late joiners since this info isn't synced to them
    if not title then
        title = default_title
    end

    -- Gather player information
    local scores = self.Scores
    local nicks = self.Players

    local scores_by_section = {
        [ROLE_TEAM_INNOCENT] = {},
        [ROLE_TEAM_TRAITOR] = {},
        [ROLE_TEAM_JESTER] = {}
    }

    for id, s in pairs(scores) do
        if id ~= -1 and s.role and s.role > ROLE_NONE and s.role <= ROLE_MAX then
            local foundPlayer = false
            for _, v in pairs(spawnedPlayers) do
                if v == nicks[id] then
                    foundPlayer = true
                    break
                end
            end

            if foundPlayer then
                local ply = player.GetBySteamID64(id)

                -- Backup in case people disconnect and we cant check their role at the end of the round
                local startingRole = s.role
                local hasDisconnected = false
                local alive = false

                local name = nicks[id]
                local roleFileName = ROLE_STRINGS_SHORT[startingRole]
                local roleColor = ROLE_COLORS[startingRole]
                local finalRole = startingRole

                if IsValid(ply) then
                    alive = ply:Alive() and not ply:IsSpec()
                    finalRole = ply:GetRole()
                    -- Sanity check to make sure only valid roles are used for icons and stuff
                    if not finalRole or finalRole <= ROLE_NONE or finalRole > ROLE_MAX then
                        finalRole = startingRole
                    end

                    -- Update the icon to use the final role, in case it changed
                    roleFileName = ROLE_STRINGS_SHORT[finalRole]
                    roleColor = ROLE_COLORS[finalRole]
                else
                    hasDisconnected = true
                end

                -- Group players in the summary by the team each player ended in
                local groupingRole = finalRole

                -- Allow developers to override role icon, grouping, and color
                local roleFile, groupRole, iconColor, newName, otherName, label = hook.Call("TTTScoringSummaryRender", nil, ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
                if roleFile then roleFileName = roleFile end
                if groupRole then groupingRole = groupRole end
                if iconColor then roleColor = iconColor end
                if newName then name = newName end

                local playerInfo = {
                    ply = ply,
                    name = name,
                    otherName = otherName,
                    label = label,
                    roleColor = roleColor,
                    roleFileName = roleFileName,
                    hasDied = not alive,
                    hasDisconnected = hasDisconnected,
                    startingRole = startingRole,
                    finalRole = finalRole
                }

                if INNOCENT_ROLES[groupingRole] then
                    table.insert(scores_by_section[ROLE_TEAM_INNOCENT], playerInfo)
                elseif TRAITOR_ROLES[groupingRole] or MONSTER_ROLES[groupingRole] then
                    table.insert(scores_by_section[ROLE_TEAM_TRAITOR], playerInfo)
                else
                    table.insert(scores_by_section[ROLE_TEAM_JESTER], playerInfo)
                end
            end
        end
    end

    -- Add 33px for each extra jester/independent
    local jester_rows = math.max(1, #scores_by_section[ROLE_TEAM_JESTER])
    local height_extra_jester = (jester_rows - 1) * 33

    -- Minimum of 10 rows minus any extra jesters, maximum of whichever team has more players
    local player_rows = math.max(1, 10 - (jester_rows - 1), math.max(#scores_by_section[ROLE_TEAM_INNOCENT], #scores_by_section[ROLE_TEAM_TRAITOR]))

    -- Add padding for each extra role
    local padding = 33
    local height_extra = (player_rows - 1) * padding

    local height_extra_secondaries = 0
    if #secondary_win_roles > 1 then
        height_extra_secondaries = (#secondary_win_roles - 1) * 28
    end

    local height_extra_total = height_extra + height_extra_jester + height_extra_secondaries

    -- Build the panel
    local w, h = dpanel:GetSize()
    -- The DScrollPanel has a gap at the bottom for some reason so just close the height to get rid of it
    h = h - 22
    -- Remove 9 rows of padding here so that the window is the correct size if the summary tab isn't enabled
    local extra_row_padding = 9 * padding
    h = h - extra_row_padding
    if height_extra_total > 0 then
        local screen_height = ScrH()

        -- Decrease the max height by 20 to give a gap at the top and bottom matching the left HUD for aesthetics
        local max_height = screen_height - 20

        -- Make the parent panel and tab container bigger
        local pw, ph = parentPanel:GetSize()
        local height_extra_total_parent = height_extra_total - extra_row_padding
        local width_extra_total_parent = 0
        -- If the height of the panel would be larger than the available space,
        -- shrink the parent panel to force the inner panel to scroll
        -- Then add width to the parent panel so the scrollbar doesn't overlap the inner panel
        if (ph + height_extra_total_parent) > max_height then
            height_extra_total_parent = (max_height - ph)
            width_extra_total_parent = 18
        end
        ph = ph + height_extra_total_parent
        pw = pw + width_extra_total_parent
        parentPanel:SetSize(pw, ph)
        parentPanel:Center()

        local tw, th = parentTabs:GetSize()
        th = th + height_extra_total_parent
        tw = tw + width_extra_total_parent
        parentTabs:SetSize(tw, th)

        -- Move the buttons down
        local sx, sy = saveButton:GetPos()
        sy = sy + height_extra_total_parent
        saveButton:SetPos(sx, sy)

        local cx, cy = closeButton:GetPos()
        cy = cy + height_extra_total_parent
        closeButton:SetPos(cx, cy)

        -- Make this inner panel bigger
        h = h + height_extra_total
        dpanel:SetSize(w, h)
    end

    local bg = vgui.Create("ColoredBox", dpanel)
    bg:SetColor(Color(97, 100, 102, 255))
    bg:SetSize(w, h)
    bg:SetPos(0, 0)

    local winlbl = vgui.Create("DLabel", dpanel)
    local wintxt = PT(title.txt, title.params or {})
    winlbl:SetFont(GetFontForWinTitle(wintxt, w - 20))
    winlbl:SetText(wintxt)
    winlbl:SetTextColor(COLOR_WHITE)
    winlbl:SizeToContents()

    -- Set a fixed height to make sure the different font sizes don't break the layout
    local lblw, _ = winlbl:GetSize()
    winlbl:SetSize(lblw, 73)

    local xwin = (w - winlbl:GetWide())/2
    local ywin = 15
    winlbl:SetPos(xwin, ywin)

    for i, r in ipairs(secondary_win_roles) do
        local role_string
        if type(r) == "table" then
            role_string = r.txt
        else
            role_string = PT("hilite_win_role_singular_additional", { role = StringUpper(ROLE_STRINGS[r]) })
        end
        local exwinlbl = vgui.Create("DLabel", dpanel)
        exwinlbl:SetFont("WinSmall")
        exwinlbl:SetText(role_string)
        exwinlbl:SetTextColor(COLOR_WHITE)
        exwinlbl:SizeToContents()
        local xexwin = (w - exwinlbl:GetWide()) / 2
        local yexwin = 61 + (28 * (i - 1))
        exwinlbl:SetPos(xexwin, yexwin)
    end

    bg.PaintOver = function()
        draw.RoundedBox(8, 8, ywin - 5, w - 14, winlbl:GetTall() + 10, title.c)
        for i, r in ipairs(secondary_win_roles) do
            local role_color
            if type(r) == "table" then
                role_color = r.col
            else
                role_color = ROLE_COLORS[r]
            end
            local round_bottom = i == #secondary_win_roles
            local height = 28
            draw.RoundedBoxEx(8, 8, 65 + (height * (i - 1)), w - 14, height, role_color, false, false, round_bottom, round_bottom)
        end
        draw.RoundedBox(0, 8, ywin + winlbl:GetTall() + 15 + height_extra_secondaries, 341, 32 + height_extra, Color(164, 164, 164, 255))
        draw.RoundedBox(0, 357, ywin + winlbl:GetTall() + 15 + height_extra_secondaries, 341, 32 + height_extra, Color(164, 164, 164, 255))
        draw.RoundedBox(0, 8, ywin + winlbl:GetTall() + 55 + height_extra + height_extra_secondaries, 690, 32 + height_extra_jester, Color(164, 164, 164, 255))
        local loc = ywin + winlbl:GetTall() + 47 + height_extra_secondaries
        for _ = 1, player_rows do
            draw.RoundedBox(0, 8, loc, 341, 1, Color(97, 100, 102, 255))
            draw.RoundedBox(0, 357, loc, 341, 1, Color(97, 100, 102, 255))
            loc = loc + 33
        end
        loc = ywin + winlbl:GetTall() + 87 + height_extra + height_extra_secondaries
        for _ = 1, jester_rows do
            draw.RoundedBox(0, 8, loc, 690, 1, Color(97, 100, 102, 255))
            loc = loc + 33
        end
    end

    if #secondary_win_roles > 0 then winlbl:SetPos(xwin, ywin - 15) end

    -- Add the players to the panel
    self:BuildPlayerList(scores_by_section[ROLE_TEAM_INNOCENT], dpanel, 317, 8, 103 + height_extra_secondaries, 33)
    self:BuildPlayerList(scores_by_section[ROLE_TEAM_TRAITOR], dpanel, 666, 357, 103 + height_extra_secondaries, 33)
    self:BuildPlayerList(scores_by_section[ROLE_TEAM_JESTER], dpanel, 666, 8, 143 + height_extra + height_extra_secondaries, 33)
end

local function GetRoleIconElement(roleFileName, roleColor, startingRole, finalRole, dpanel)
    local roleBackground = vgui.Create("DPanel", dpanel)
    roleBackground:SetSize(32, 32)
    roleBackground:SetBackgroundColor(roleColor)

    local startingString = ROLE_STRINGS[startingRole]
    local endingString = ROLE_STRINGS[finalRole]
    local tooltip = startingString
    if startingString ~= endingString then
        tooltip = PT("summary_role_changed", { starting = startingString, ending = endingString })
    end
    roleBackground:SetTooltip(tooltip)

    local roleIcon = vgui.Create("DImage", roleBackground)
    roleIcon:SetSize(32, 32)
    roleIcon:SetImage(util.GetRoleIconPath(roleFileName, "score", "png"))
    return roleBackground
end

local function GetNickLabelElement(name, dpanel)
    local nicklbl = vgui.Create("DLabel", dpanel)
    nicklbl:SetFont("ScoreNicks")
    nicklbl:SetText(name)
    nicklbl:SetTextColor(COLOR_WHITE)
    nicklbl:SizeToContents()
    return nicklbl
end

local function BuildJesterLabel(playerName, otherName, label)
    return playerName .. " (" .. label .. " " .. otherName .. ")"
end

function CLSCORE:AddPlayerRow(dpanel, statusX, roleX, y, roleIcon, nicklbl, hasDisconnected, hasDied)
    roleIcon:SetPos(roleX, y)
    nicklbl:SetPos(roleX + 38, y - 2)
    if hasDisconnected then
        local disconIcon = vgui.Create("DImage", dpanel)
        disconIcon:SetSize(32, 32)
        disconIcon:SetPos(statusX, y)
        disconIcon:SetImage("vgui/ttt/score_disconicon.png")
    elseif hasDied then
        local skullIcon = vgui.Create("DImage", dpanel)
        skullIcon:SetSize(32, 32)
        skullIcon:SetPos(statusX, y)
        skullIcon:SetImage("vgui/ttt/score_skullicon.png")
    end
end

function CLSCORE:BuildPlayerList(playerList, dpanel, statusX, roleX, initialY, rowY)
    local count = 0
    for _, v in pairs(playerList) do
        local roleIcon = GetRoleIconElement(v.roleFileName, v.roleColor, v.startingRole, v.finalRole, dpanel)

        local name = v.name
        local label = v.label
        local otherName = v.otherName
        local nicklbl
        if otherName ~= nil then
            nicklbl = GetNickLabelElement(BuildJesterLabel(name, otherName, label), dpanel)
        else
            nicklbl = GetNickLabelElement(v.name, dpanel)
        end
        FitNicknameLabel(nicklbl, statusX - roleX - 34, function(nickname)
            return utf8.sub(nickname, 0, -5) .. "..."
        end)

        self:AddPlayerRow(dpanel, statusX, roleX, initialY + rowY * count, roleIcon, nicklbl, v.hasDisconnected, v.hasDied)
        count = count + 1
    end
end

function CLSCORE:BuildHilitePanel(dpanel)
    local w, h = dpanel:GetSize()

    local endtime = self.StartTime
    local default_title = GetWinTitle(WIN_INNOCENT)
    local title
    for i=#self.Events, 1, -1 do
        local e = self.Events[i]
        if e.id == EVENT_FINISH then
           endtime = e.t
           title = GetWinTitle(e.win)
           break
        end
    end

    -- Sanity check for late joiners since this info isn't synced to them
    if not title then
        title = default_title
    end

    local roundtime = endtime - self.StartTime
    local numply = table.Count(self.Players)
    local numtr = 0
    for _, role in pairs(self.Roles) do
        if TRAITOR_ROLES[role] then
            numtr = numtr + 1
        end
    end

    local bg = vgui.Create("ColoredBox", dpanel)
    bg:SetColor(Color(50, 50, 50, 255))
    bg:SetSize(w, h)
    bg:SetPos(0, 0)

    local winlbl = vgui.Create("DLabel", dpanel)
    local wintxt = PT(title.txt, title.params or {})
    winlbl:SetFont(GetFontForWinTitle(wintxt, w - 20))
    winlbl:SetText(wintxt)
    winlbl:SetTextColor(COLOR_WHITE)
    winlbl:SizeToContents()

    -- Set a fixed height to make sure the different font sizes don't break the layout
    local lblw, _ = winlbl:GetSize()
    winlbl:SetSize(lblw, 73)

    local xwin = (w - winlbl:GetWide())/2
    local ywin = 15
    winlbl:SetPos(xwin, ywin)

    for i, r in ipairs(secondary_win_roles) do
        local role_string
        if type(r) == "table" then
            role_string = r.txt
        else
            role_string = PT("hilite_win_role_singular_additional", { role = StringUpper(ROLE_STRINGS[r]) })
        end
        local exwinlbl = vgui.Create("DLabel", dpanel)
        exwinlbl:SetFont("WinSmall")
        exwinlbl:SetText(role_string)
        exwinlbl:SetTextColor(COLOR_WHITE)
        exwinlbl:SizeToContents()
        local xexwin = (w - exwinlbl:GetWide()) / 2
        local yexwin = 61 + (28 * (i - 1))
        exwinlbl:SetPos(xexwin, yexwin)
    end

    bg.PaintOver = function()
        draw.RoundedBox(8, 8, ywin - 5, w - 14, winlbl:GetTall() + 10, title.c)
        for i, r in ipairs(secondary_win_roles) do
            local role_color
            if type(r) == "table" then
                role_color = r.col
            else
                role_color = ROLE_COLORS[r]
            end
            local round_bottom = i == #secondary_win_roles
            local height = 28
            draw.RoundedBoxEx(8, 8, 65 + (height * (i - 1)), w - 14, height, role_color, false, false, round_bottom, round_bottom)
        end
    end

    if #secondary_win_roles > 0 then winlbl:SetPos(xwin, ywin - 15) end

    local ysubwin = ywin + winlbl:GetTall()
    -- Add extra space if we have more than one secondary win
    if #secondary_win_roles > 1 then
        ysubwin = ysubwin + (#secondary_win_roles - 1) * 28
    end
    local partlbl = vgui.Create("DLabel", dpanel)

    local plytxt = PT(numtr == 1 and "hilite_players2" or "hilite_players1",
                    {
                        numplayers = numply,
                        numtraitors = numtr,
                        traitor = ROLE_STRINGS[ROLE_TRAITOR],
                        traitors = ROLE_STRINGS_PLURAL[ROLE_TRAITOR]
                    })

    partlbl:SetText(plytxt)
    partlbl:SizeToContents()
    partlbl:SetPos(xwin, ysubwin + 8)

    local timelbl = vgui.Create("DLabel", dpanel)
    timelbl:SetText(PT("hilite_duration", {time= util.SimpleTime(roundtime, "%02i:%02i")}))
    timelbl:SizeToContents()
    timelbl:SetPos(xwin + winlbl:GetWide() - timelbl:GetWide(), ysubwin + 8)

    -- Awards
    local wa = math.Round(w * 0.9)
    local ha = h - ysubwin - 40
    local xa = (w - wa) / 2
    local ya = h - ha

    local awardp = vgui.Create("DPanel", dpanel)
    awardp:SetSize(wa, ha)
    awardp:SetPos(xa, ya)
    awardp:SetPaintBackground(false)

    -- Before we pick awards, seed the rng in a way that is the same on all
    -- clients. We can do this using the round start time. To make it a bit more
    -- random, involve the round's duration too.
    math.randomseed(self.StartTime + endtime)

    -- Get the player's name and current role and pass that into the awards
    local playerInfo = {}
    for id, nick in pairs(self.Players) do
        local role = self.Roles[GetRoleId(id)]
        local ply = player.GetBySteamID64(id)
        -- If the player disconnected, use their starting role
        if IsValid(ply) then
            role = ply:GetRole()
        end
        playerInfo[id] = {
            nick = nick,
            role = role
        }
    end

    -- Attempt to generate every award, then sort the succeeded ones based on
    -- priority/interestingness
    local award_choices = {}
    for _, afn in pairs(AWARDS) do
        local a = afn(self.Events, self.Scores, playerInfo)
        if ValidAward(a) then
            table.insert(award_choices, a)
        end
    end

    local max_awards = 5

    -- sort descending by priority
    table.SortByMember(award_choices, "priority")

    -- put the N most interesting awards in the menu
    for i=1,max_awards do
        local a = award_choices[i]
        if a then
            self:AddAward((i - 1) * 42, wa, a, awardp)
        end
    end
end

local tabs = {
    ["summary"] = function(panel, padding)
        local dtabsummary = vgui.Create("DScrollPanel", parentTabs)
        dtabsummary:SetPaintBackground(false)
        dtabsummary:StretchToParent(padding, padding, padding, padding)
        panel:BuildSummaryPanel(dtabsummary)

        parentTabs:AddSheet(T("report_tab_summary"), dtabsummary, "icon16/book_open.png", false, false, T("report_tab_summary_tip"))
    end,
    ["hilite"] = function(panel, padding)
        local dtabhilite = vgui.Create("DPanel", parentTabs)
        dtabhilite:SetPaintBackground(false)
        dtabhilite:StretchToParent(padding, padding, padding, padding)
        panel:BuildHilitePanel(dtabhilite)

        parentTabs:AddSheet(T("report_tab_hilite"), dtabhilite, "icon16/star.png", false, false, T("report_tab_hilite_tip"))
    end,
    ["events"] = function(panel, padding)
        local dtabevents = vgui.Create("DPanel", parentTabs)
        dtabevents:StretchToParent(padding, padding, padding, padding)
        panel:BuildEventLogPanel(dtabevents)

        parentTabs:AddSheet(T("report_tab_events"), dtabevents, "icon16/application_view_detail.png", false, false, T("report_tab_events_tip"))
    end,
    ["scores"] = function(panel, padding)
        local dtabscores = vgui.Create("DPanel", parentTabs)
        dtabscores:SetPaintBackground(false)
        dtabscores:StretchToParent(padding, padding, padding, padding)
        panel:BuildScorePanel(dtabscores)

        parentTabs:AddSheet(T("report_tab_scores"), dtabscores, "icon16/user.png", false, false, T("report_tab_scores_tip"))
    end
}

function CLSCORE:ShowPanel()
    parentPanel = vgui.Create("DFrame")
    local w, h = 750, 588
    local margin = 15
    parentPanel:SetSize(w, h)
    parentPanel:Center()
    parentPanel:SetTitle("Round Report - " .. GAMEMODE.Version .. " - " .. StringUpper(game.GetMap()))
    parentPanel:SetVisible(true)
    parentPanel:ShowCloseButton(true)
    parentPanel:SetMouseInputEnabled(true)
    parentPanel:SetKeyboardInputEnabled(true)
    parentPanel.OnKeyCodePressed = util.BasicKeyHandler

    parentPanel.Think = function()
        parentPanel:MoveToFront()
    end

    -- keep it around so we can reopen easily
    parentPanel:SetDeleteOnClose(false)
    self.Panel = parentPanel

    closeButton = vgui.Create("DButton", parentPanel)
    local bw, bh = 100, 25
    closeButton:SetSize(bw, bh)
    closeButton:SetPos(w - bw - margin, h - bh - margin/2)
    closeButton:SetText(T("close"))
    closeButton.DoClick = function() parentPanel:Close() end

    saveButton = vgui.Create("DButton", parentPanel)
    saveButton:SetSize(bw, bh)
    saveButton:SetPos(margin, h - bh - margin/2)
    saveButton:SetText(T("report_save"))
    saveButton:SetTooltip(T("report_save_tip"))
    saveButton:SetConsoleCommand("ttt_save_events")

    parentTabs = vgui.Create("DPropertySheet", parentPanel)
    parentTabs:SetPos(margin, margin + 15)
    parentTabs:SetSize(w - margin*2, h - margin*3 - bh)
    local padding = parentTabs:GetPadding()

    local summary_tabs = GetConVar("ttt_round_summary_tabs"):GetString()
    local tab_order = string.Explode(",", summary_tabs, false)

    -- If the convar is empty, use the default list
    if #summary_tabs == 0 then
        tab_order = table.GetKeys(tabs)
    end

    -- Add all the tabs in order
    for _, tab in ipairs(tab_order) do
        if tabs[tab] then
            tabs[tab](self, padding)
        end
    end

    parentPanel:MakePopup()

    -- makepopup grabs keyboard, whereas we only need mouse
    parentPanel:SetKeyboardInputEnabled(false)
end

function CLSCORE:ClearPanel()

    if IsValid(self.Panel) then
        -- move the mouse off any tooltips and then remove the panel next tick

        -- we need this hack as opposed to just calling Remove because gmod does
        -- not offer a means of killing the tooltip, and doesn't clean it up
        -- properly on Remove
        input.SetCursorPos(ScrW() / 2, ScrH() / 2)
        local pnl = self.Panel
        timer.Simple(0, function() if IsValid(pnl) then pnl:Remove() end end)
    end
end

function CLSCORE:SaveLog()
    if self.Events and #self.Events <= 0 then
        chat.AddText(COLOR_WHITE, T("report_save_error"))
        return
    end

    local logdir = "ttt/logs"
    if not file.IsDir(logdir, "DATA") then
        file.CreateDir(logdir)
    end

    local logname = logdir .. "/ttt_events_" .. os.time() .. ".txt"
    local log = "Trouble in Terrorist Town - Round Events Log\n" .. string.rep("-", 50) .. "\n"

    log = log .. string.format("%s | %-25s | %s\n", " TIME", "TYPE", "WHAT HAPPENED") .. string.rep("-", 50) .. "\n"

    for _, e in pairs(self.Events) do
        local etxt = self:TextForEvent(e)
        local etime = self:TimeForEvent(e)
        local _, etype = self:IconForEvent(e)
        if etxt then
            log = log .. string.format("%s | %-25s | %s\n", etime, etype, etxt)
        end
    end

    file.Write(logname, log)

    chat.AddText(COLOR_WHITE, T("report_save_result"), COLOR_GREEN, " /garrysmod/data/" .. logname)
end

function CLSCORE:Reset()
    self.Events = {}
    self.Roles = {}
    self.Scores = {}
    self.Players = {}
    self.RoundStarted = 0

    self:ClearPanel()
end

function CLSCORE:Init(events)
    -- Get start time, traitors, detectives, scores, and nicks
    local starttime = 0
    local scores, nicks, roles, bonus = {}, {}, {}, {}
    for i = 1, #events do
        local e = events[i]
        if e.id == EVENT_GAME and e.state == ROUND_ACTIVE then
            starttime = e.t
        elseif e.id == EVENT_SELECTED then
            roles = e.roles
        elseif e.id == EVENT_SPAWN then
            scores[e.sid64] = ScoreInit()
            nicks[e.sid64] = e.ni
        end
    end

    for i = 1, #customEvents do
        local e = customEvents[i]
        -- Allow any event to provide bonus points
        if e.sid64 and e.bonus then
            local sid = e.sid64
            bonus[sid] = (bonus[sid] or 0) + e.bonus
        end
    end

    scores = ScoreEventLog(events, scores, roles, bonus)

    self.Players = nicks
    self.Scores = scores
    self.Roles = roles
    self.StartTime = starttime
    self.Events = events
end

function CLSCORE:ReportEvents(events)
    self:Reset()

    self:Init(events)
    self:ShowPanel()
end

function CLSCORE:Toggle()
    if IsValid(self.Panel) then
        self.Panel:ToggleVisible()
    end
end

hook.Add("OnPauseMenuShow", "Scoring_OnPauseMenuShow", function()
    -- If we needed to hide the score screen, don't open the pause menu too
    if IsValid(CLSCORE.Panel) and CLSCORE.Panel:IsVisible() then
        CLSCORE.Panel:ToggleVisible()
        return false
    end
end)

local function SortEvents(a, b)
    return a.t < b.t
end

local buff = ""
net.Receive("TTT_ReportStream_Part", function()
    buff = buff .. net.ReadData(CLSCORE.MaxStreamLength)
end)

net.Receive("TTT_ReportStream", function()
    local events = util.Decompress(buff .. net.ReadData(net.ReadUInt(16)))
    buff = ""

    if #events == 0 then
        ErrorNoHalt("Round report decompression failed!\n")
    end

    events = util.JSONToTable(events)
    if events == nil then
        ErrorNoHalt("Round report decoding failed!\n")
    end

    table.sort(events, SortEvents)
    CLSCORE:ReportEvents(events)
end)

concommand.Add("ttt_save_events", function()
    CLSCORE:SaveLog()
end)