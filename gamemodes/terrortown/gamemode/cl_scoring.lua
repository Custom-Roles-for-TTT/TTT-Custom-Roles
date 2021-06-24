-- Game report

include("cl_awards.lua")

local table = table
local string = string
local vgui = vgui
local pairs = pairs
local parentPanel, parentTabs, closeButton, saveButton

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

surface.CreateFont("WinSmall", {
    font = "Trebuchet24",
    size = 32,
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

function CLSCORE:AddEvent(e, offset)
    e["t"] = math.Round(CurTime() + (offset or 0), 2)
    table.insert(customEvents, e)
end

local function GetPlayerFromSteam64(id)
    -- The first bot's ID is 90071996842377216 which translates to "STEAM_0:0:0", an 11-character string
    -- A player's Steam ID cannot be that short, so if it is this must be a bot
    local isBot = string.len(util.SteamIDFrom64(id)) == 11
    -- Bots cannot be retrieved by SteamID on the client so search by name instead
    if isBot then
        for _, p in pairs(player.GetAll()) do
            if p:Nick() == CLSCORE.Players[id] then
                return p
            end
        end
    else
        return player.GetBySteamID64(id)
    end
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

net.Receive("TTT_Hypnotised", function(len)
    local name = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_HYPNOTISED,
        vic = name
    })
end)

net.Receive("TTT_Defibrillated", function(len)
    local name = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_DEFIBRILLATED,
        vic = name
    })
end)

net.Receive("TTT_SwapperSwapped", function(len)
    local victim = net.ReadString()
    local attacker = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_SWAPPER,
        vic = victim,
        att = attacker
    })
end)

net.Receive("TTT_Promotion", function(len)
    local name = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_PROMOTION,
        ply = name
    })
end)

net.Receive("TTT_DrunkSober", function(len)
    local name = net.ReadString()
    local team = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_DRUNKSOBER,
        ply = name,
        team = team
    })
end)

net.Receive("TTT_PhantomHaunt", function(len)
    local victim = net.ReadString()
    local attacker = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_HAUNT,
        vic = victim,
        att = attacker
    })
end)

net.Receive("TTT_Zombified", function(len)
    local name = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_ZOMBIFIED,
        vic = name
    })
end)

net.Receive("TTT_Vampified", function(len)
    local name = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_VAMPIFIED,
        vic = name
    })
end)

net.Receive("TTT_VampirePrimeDeath", function(len)
    local mode = net.ReadUInt(4)
    local name = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_VAMPPRIME_DEATH,
        mode = mode,
        prime = name
    })
end)

net.Receive("TTT_Score_Bodysnatch", function(len)
    local victim = net.ReadString()
    local attacker = net.ReadString()
    local role = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_BODYSNATCH,
        vic = victim,
        att = attacker,
        role = role
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

net.Receive("TTT_ResetScoreboard", function(len)
    spawnedPlayers = {}
    disconnected = {}
    customEvents = {}
end)

net.Receive("TTT_SpawnedPlayers", function(len)
    local name = net.ReadString()
    local role = net.ReadUInt(8)
    table.insert(spawnedPlayers, name)
    CLSCORE:AddEvent({
        id = EVENT_SPAWN,
        ply = name,
        rol = role
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
    local role = net.ReadUInt(8)
    local ply = GetPlayerFromSteam64(s64)
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

local old_man_wins = false
net.Receive("TTT_UpdateOldManWins", function()
    old_man_wins = net.ReadBool()

    -- Log the win event with an offset to force it to the end
    if old_man_wins then
        CLSCORE:AddEvent({
            id = EVENT_FINISH,
            win = WIN_OLDMAN
        }, 1)
    end
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

local wintitle = {
    [WIN_INNOCENT] = { txt = "hilite_win_innocent", c = ROLE_COLORS[ROLE_INNOCENT] },
    [WIN_TRAITOR] = { txt = "hilite_win_traitors", c = ROLE_COLORS[ROLE_TRAITOR] },
    [WIN_JESTER] = { txt = "hilite_win_jester", c = ROLE_COLORS[ROLE_JESTER] },
    [WIN_CLOWN] = { txt = "hilite_win_clown", c = ROLE_COLORS[ROLE_JESTER] },
    [WIN_KILLER] = { txt = "hilite_win_killer", c = ROLE_COLORS[ROLE_KILLER] },
    [WIN_MONSTER] = { txt = "hilite_win_monster", c = ROLE_COLORS[ROLE_ZOMBIE] }
}

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
    local colnames = { "", "col_player", "col_role", "col_kills1", "col_kills2", "col_kills3", "col_kills4" }
    if monsters_exist then
        table.insert(colnames, "col_kills5")
    end
    table.Add(colnames, { "col_points", "col_team", "col_total" })

    for _, name in pairs(colnames) do
        if name == "" then
            -- skull icon column
            local c = dlist:AddColumn("")
            c:SetFixedWidth(18)
        else
            dlist:AddColumn(T(name))
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
            local role_string = ROLE_STRINGS[s.role]

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

            local l
            if monsters_exist then
                l = dlist:AddLine(surv, nicks[id], role_string, s.innos, s.traitors, s.jesters, s.indeps, s.monsters, points_own, points_team, points_total)
            else
                l = dlist:AddLine(surv, nicks[id], role_string, s.innos, s.traitors, s.jesters, s.indeps, points_own, points_team, points_total)
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
    local title = string.upper(award.title)

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

local old_man_won_last_round = false
function CLSCORE:BuildSummaryPanel(dpanel)
    -- Gather player information
    local scores = self.Scores
    local nicks = self.Players

    local scores_by_section = {
        [ROLE_INNOCENT] = {},
        [ROLE_TRAITOR] = {},
        [ROLE_JESTER] = {}
    }

    for id, s in pairs(scores) do
        if id ~= -1 then
            local foundPlayer = false
            for _, v in pairs(spawnedPlayers) do
                if v == nicks[id] then
                    foundPlayer = true
                    break
                end
            end

            if foundPlayer then
                local ply = GetPlayerFromSteam64(id)

                -- Backup in case people disconnect and we cant check their role at the end of the round
                local startingRole = s.role
                local hasDisconnected = false
                local alive = false

                local roleFileName = ROLE_STRINGS_SHORT[startingRole]
                local roleColor = ROLE_COLORS[startingRole]
                local finalRole = startingRole

                local swappedWith = ""
                local jesterKiller = ""
                if IsValid(ply) then
                    alive = ply:Alive()
                    finalRole = ply:GetRole()
                    -- Keep the original role icon for people converted to Zombie and Vampire
                    if finalRole ~= ROLE_ZOMBIE and finalRole ~= ROLE_VAMPIRE then
                        roleFileName = ROLE_STRINGS_SHORT[finalRole]
                    end
                    roleColor = ROLE_COLORS[finalRole]
                    if ply:IsInnocent() then
                        if ply:GetNWBool("WasDrunk", false) then
                            roleFileName = ROLE_STRINGS_SHORT[ROLE_DRUNK]
                        elseif ply:GetNWBool("WasBeggar", false) then
                            roleFileName = ROLE_STRINGS_SHORT[ROLE_BEGGAR]
                        end
                    elseif ply:IsTraitor() then
                        if ply:GetNWBool("WasDrunk", false) then
                            roleFileName = ROLE_STRINGS_SHORT[ROLE_DRUNK]
                        elseif ply:GetNWBool("WasBeggar", false) then
                            roleFileName = ROLE_STRINGS_SHORT[ROLE_BEGGAR]
                        elseif ply:GetNWBool("WasHypnotised", false) then
                            roleFileName = ROLE_STRINGS_SHORT[startingRole]
                        end
                    elseif ply:IsJester() then
                        jesterKiller = ply:GetNWString("JesterKiller", "")
                    elseif ply:IsSwapper() then
                        swappedWith = ply:GetNWString("SwappedWith", "")
                    end
                else
                    hasDisconnected = true
                end

                local playerInfo = {
                    ply = ply,
                    name = nicks[id],
                    roleColor = roleColor,
                    roleFileName = roleFileName,
                    hasDied = not alive,
                    hasDisconnected = hasDisconnected,
                    jesterKiller = jesterKiller,
                    swappedWith = swappedWith
                }

                if INNOCENT_ROLES[startingRole] then
                    table.insert(scores_by_section[ROLE_INNOCENT], playerInfo)
                elseif TRAITOR_ROLES[startingRole] or MONSTER_ROLES[startingRole] then
                    table.insert(scores_by_section[ROLE_TRAITOR], playerInfo)
                else
                    table.insert(scores_by_section[ROLE_JESTER], playerInfo)
                end
            end
        end
    end

    -- Minimum of 10 rows, maximum of whichever team has more players
    local player_rows = math.max(10, math.max(#scores_by_section[ROLE_INNOCENT], #scores_by_section[ROLE_TRAITOR]))

    -- Add 33px for each extra role
    local height_extra = (player_rows - 10) * 33

    -- Build the panel
    local w, h = dpanel:GetSize()
    if height_extra > 0 then
        h = h + height_extra

        -- Make the parent panel and tab container bigger
        local pw, ph = parentPanel:GetSize()
        ph = ph + height_extra
        parentPanel:SetSize(pw, ph)

        local tw, th = parentTabs:GetSize()
        th = th + height_extra
        parentTabs:SetSize(tw, th)

        -- Move the buttons down
        local sx, sy = saveButton:GetPos()
        sy = sy + height_extra
        saveButton:SetPos(sx, sy)

        local cx, cy = closeButton:GetPos()
        cy = cy + height_extra
        closeButton:SetPos(cx, cy)

        -- Make this inner panel bigger
        dpanel:SetSize(w, h)
    end

    local title = wintitle[WIN_INNOCENT]
    for i = #self.Events, 1, -1 do
        local e = self.Events[i]
        if e.id == EVENT_FINISH then
            local wintype = e.win
            if wintype == WIN_TIMELIMIT then wintype = WIN_INNOCENT end
            title = wintitle[wintype]

            -- If this was a monster win, check that both roles are part of the monsters team still
            if wintype == WIN_MONSTER then
                -- If Zombies are not monsters then Vampires win
                if not MONSTER_ROLES[ROLE_ZOMBIE] then
                    title.txt = "hilite_win_vampires"
                    -- Also make sure to override the color because they will be different
                    title.c = ROLE_COLORS[ROLE_VAMPIRE]
                -- And vice versa
                elseif not MONSTER_ROLES[ROLE_VAMPIRE] then
                    title.txt = "hilite_win_zombies"
                -- Otherwise the monsters legit win
                else
                    title.txt = "hilite_win_monster"
                end
            end
            break
        end
    end

    local bg = vgui.Create("ColoredBox", dpanel)
    bg:SetColor(Color(97, 100, 102, 255))
    bg:SetSize(w, h)
    bg:SetPos(0, 0)

    local winlbl = vgui.Create("DLabel", dpanel)
    winlbl:SetFont("WinHuge")
    winlbl:SetText(T(title.txt))
    winlbl:SetTextColor(COLOR_WHITE)
    winlbl:SizeToContents()
    local xwin = (w - winlbl:GetWide())/2
    local ywin = 15
    winlbl:SetPos(xwin, ywin)

    old_man_won_last_round = old_man_wins
    local exwinlbl = vgui.Create("DLabel", dpanel)
    if old_man_won_last_round then
        exwinlbl:SetFont("WinSmall")
        exwinlbl:SetText(T("hilite_win_old_man"))
        exwinlbl:SetTextColor(COLOR_WHITE)
        exwinlbl:SizeToContents()
        local xexwin = (w - exwinlbl:GetWide()) / 2
        local yexwin = 61
        exwinlbl:SetPos(xexwin, yexwin)
    else
        exwinlbl:SetText("")
    end

    bg.PaintOver = function()
        draw.RoundedBox(8, 8, ywin - 5, w - 14, winlbl:GetTall() + 10, title.c)
        if old_man_won_last_round then draw.RoundedBoxEx(8, 8, 65, w - 14, 28, ROLE_COLORS[ROLE_OLDMAN], false, false, true, true) end
        draw.RoundedBox(0, 8, ywin + winlbl:GetTall() + 14, 341, 330 + height_extra, Color(164, 164, 164, 255))
        draw.RoundedBox(0, 357, ywin + winlbl:GetTall() + 14, 341, 330 + height_extra, Color(164, 164, 164, 255))
        local loc = ywin + winlbl:GetTall() + 47
        for _ = 1, player_rows do
            draw.RoundedBox(0, 8, loc, 341, 1, Color(97, 100, 102, 255))
            draw.RoundedBox(0, 357, loc, 341, 1, Color(97, 100, 102, 255))
            loc = loc + 33
        end
        draw.RoundedBox(0, 8, ywin + winlbl:GetTall() + 352 + height_extra, 690, 32, Color(164, 164, 164, 255))
    end

    if old_man_won_last_round then winlbl:SetPos(xwin, ywin - 15) end

    -- Add the players to the panel
    self:BuildPlayerList(scores_by_section[ROLE_INNOCENT], dpanel, 317, 8, 103, 33)
    self:BuildPlayerList(scores_by_section[ROLE_TRAITOR], dpanel, 666, 357, 103, 33)
    self:BuildRoleLabel(scores_by_section[ROLE_JESTER], dpanel, 666, 8, 440 + height_extra)
end

local function GetRoleIconElement(roleFileName, roleColor, dpanel)
    local roleBackground = vgui.Create("DShape", dpanel)
    roleBackground:SetType("Rect")
    roleBackground:SetSize(32, 32)
    roleBackground:SetColor(roleColor)

    local roleIcon = vgui.Create("DImage", roleBackground)
    roleIcon:SetSize(32, 32)
    roleIcon:SetImage("vgui/ttt/score_" .. roleFileName .. ".png")
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
        local roleIcon = GetRoleIconElement(v.roleFileName, v.roleColor, dpanel)
        local nicklbl = GetNickLabelElement(v.name, dpanel)
        FitNicknameLabel(nicklbl, 275, function(nickname)
            return string.sub(nickname, 0, string.len(nickname) - 4) .. "..."
        end)

        self:AddPlayerRow(dpanel, statusX, roleX, initialY + rowY * count, roleIcon, nicklbl, v.hasDisconnected, v.hasDied)
        count = count + 1
    end
end

function CLSCORE:BuildRoleLabel(playerList, dpanel, statusX, roleX, rowY)
    local playerCount = #playerList
    if playerCount == 0 then return end

    local maxWidth = 600
    local names = {}
    local deathCount = 0
    local disconnectCount = 0
    local roleFile = nil
    local roleColor = nil

    for _, v in pairs(playerList) do
        if roleFile == nil then
            roleFile = v.roleFileName
        end
        if roleColor == nil then
            roleColor = v.roleColor
        end
        -- Don't count a disconnect as a death
        if v.hasDisconnected then
            disconnectCount = disconnectCount + 1
        elseif v.hasDied then
            deathCount = deathCount + 1
        end

        local name = v.name
        local label = nil
        local otherName = nil
        if v.jesterKiller ~= "" and v.roleFileName == ROLE_STRINGS_SHORT[ROLE_JESTER] then
            label = "Killed by"
            otherName = v.jesterKiller
        elseif v.swappedWith ~= "" and v.roleFileName == ROLE_STRINGS_SHORT[ROLE_SWAPPER] then
            label = "Killed"
            otherName = v.swappedWith
        end

        if otherName ~= nil then
            name = BuildJesterLabel(name, otherName, label)

            local nickTmp = GetNickLabelElement(name, dpanel)

            -- Then use the Jester/Swapper label and auto-resize until it fits
            FitNicknameLabel(nickTmp, maxWidth, function(_, args)
                local playerArg = args.player
                local otherArg = args.other
                if string.len(playerArg) > string.len(otherArg) then
                    playerArg = string.sub(playerArg, 0, string.len(playerArg) - 4) .. "..."
                else
                    otherArg = string.sub(otherArg, 0, string.len(otherArg) - 4) .. "..."
                end

                return BuildJesterLabel(playerArg, otherArg, label), {player=playerArg, other=otherArg}
            end, {player=v.name, other=otherName})

            -- Save the resized text
            name = nickTmp:GetText()
            -- Remove the temporary label
            nickTmp:Remove()

            -- Insert this one at the beginning so it's readable as a round-over reason
            table.insert(names, 1, name)
        else
            table.insert(names, name)
        end
    end

    if disconnectCount > 0 and deathCount > 0 then
        maxWidth = maxWidth - 30
    end

    local namesList = string.Implode(", ", names)
    local nickLbl = GetNickLabelElement(namesList, dpanel)
    FitNicknameLabel(nickLbl, maxWidth, function(nickname)
        return string.sub(nickname, 0, string.len(nickname) - 4) .. "..."
    end)

    -- Show the normal disconnect icon if we have only 1 player and they disconnected
    local singlePlayerDisconnect = playerCount == 1 and disconnectCount == 1
    -- Show the normal death icon if we have only 1 player and they died
    local singlePlayerDeath = playerCount == 1 and deathCount == 1
    self:AddPlayerRow(dpanel, statusX, roleX, rowY, GetRoleIconElement(roleFile, roleColor, dpanel), nickLbl, singlePlayerDisconnect, singlePlayerDeath)

    -- Add disconnect icon with count if there are disconnects and it wasn't a single player doing it
    if disconnectCount > 0 and playerCount > 1 then
        local disconLbl = vgui.Create("DLabel", dpanel)
        disconLbl:SetFont("IconText")
        disconLbl:SetText(disconnectCount)
        disconLbl:SetTextColor(COLOR_BLACK)
        disconLbl:SizeToContents()
        disconLbl:SetPos(statusX - 10, rowY + 2)

        local disconIcon = vgui.Create("DImage", dpanel)
        disconIcon:SetSize(32, 32)
        disconIcon:SetPos(statusX, rowY)
        disconIcon:SetImage("vgui/ttt/score_disconicon.png")
    end

    -- Add death icon with count if there are deaths and it wasn't a single player doing it
    if deathCount > 0 and playerCount > 1 then
        local offset = 0
        -- If there was also a disconnect, offset the icon more
        if disconnectCount > 0 then
            offset = 40
        end

        local deathLbl = vgui.Create("DLabel", dpanel)
        deathLbl:SetFont("IconText")
        deathLbl:SetText(deathCount)
        deathLbl:SetTextColor(COLOR_BLACK)
        deathLbl:SizeToContents()
        deathLbl:SetPos(statusX - offset - 10, rowY + 2)

        local deathIcon = vgui.Create("DImage", dpanel)
        deathIcon:SetSize(32, 32)
        deathIcon:SetPos(statusX - offset, rowY)
        deathIcon:SetImage("vgui/ttt/score_skullicon.png")
    end
end

function CLSCORE:BuildHilitePanel(dpanel)
    local w, h = dpanel:GetSize()

    local endtime = self.StartTime
    local title = wintitle[WIN_INNOCENT]
    for i=#self.Events, 1, -1 do
        local e = self.Events[i]
        if e.id == EVENT_FINISH then
           endtime = e.t
           -- when win is due to timeout, innocents win
           local wintype = e.win
           if wintype == WIN_TIMELIMIT then wintype = WIN_INNOCENT end
           title = wintitle[wintype]
           break
        end
    end

    local roundtime = endtime - self.StartTime

    local numply = table.Count(self.Players)
    local numtr = 0
    for _, role in ipairs(self.Roles) do
        if TRAITOR_ROLES[role] then
            numtr = numtr + 1
        end
    end

    local bg = vgui.Create("ColoredBox", dpanel)
    bg:SetColor(Color(50, 50, 50, 255))
    bg:SetSize(w,h)
    bg:SetPos(0,0)

    local winlbl = vgui.Create("DLabel", dpanel)
    winlbl:SetFont("WinHuge")
    winlbl:SetText(T(title.txt))
    winlbl:SetTextColor(COLOR_WHITE)
    winlbl:SizeToContents()
    local xwin = (w - winlbl:GetWide())/2
    local ywin = 15
    winlbl:SetPos(xwin, ywin)

    local exwinlbl = vgui.Create("DLabel", dpanel)
    if old_man_won_last_round then
        exwinlbl:SetFont("WinSmall")
        exwinlbl:SetText(T("hilite_win_old_man"))
        exwinlbl:SetTextColor(COLOR_WHITE)
        exwinlbl:SizeToContents()
        local xexwin = (w - exwinlbl:GetWide()) / 2
        local yexwin = 61
        exwinlbl:SetPos(xexwin, yexwin)
    else
        exwinlbl:SetText("")
    end

    bg.PaintOver = function()
        draw.RoundedBox(8, 8, ywin - 5, w - 14, winlbl:GetTall() + 10, title.c)
        if old_man_won_last_round then draw.RoundedBoxEx(8, 8, 65, w - 14, 28, ROLE_COLORS[ROLE_OLDMAN], false, false, true, true) end
    end

    if old_man_won_last_round then winlbl:SetPos(xwin, ywin - 15) end

    local ysubwin = ywin + winlbl:GetTall()
    local partlbl = vgui.Create("DLabel", dpanel)

    local plytxt = PT(numtr == 1 and "hilite_players2" or "hilite_players1",
                      {numplayers = numply, numtraitors = numtr})

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
        local ply = GetPlayerFromSteam64(id)
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

function CLSCORE:ShowPanel()
    parentPanel = vgui.Create("DFrame")
    local w, h = 750, 588
    local margin = 15
    parentPanel:SetSize(w, h)
    parentPanel:Center()
    parentPanel:SetTitle("Round Report")
    parentPanel:SetVisible(true)
    parentPanel:ShowCloseButton(true)
    parentPanel:SetMouseInputEnabled(true)
    parentPanel:SetKeyboardInputEnabled(true)
    parentPanel.OnKeyCodePressed = util.BasicKeyHandler

    function parentPanel:Think()
        self:MoveToFront()
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

    -- Summary tab
    local dtabsummary = vgui.Create("DPanel", parentTabs)
    dtabsummary:SetPaintBackground(false)
    dtabsummary:StretchToParent(padding, padding, padding, padding)
    self:BuildSummaryPanel(dtabsummary)

    parentTabs:AddSheet(T("report_tab_summary"), dtabsummary, "icon16/book_open.png", false, false, T("report_tab_summary_tip"))

    -- Highlight tab
    local dtabhilite = vgui.Create("DPanel", parentTabs)
    dtabhilite:SetPaintBackground(false)
    dtabhilite:StretchToParent(padding, padding, padding, padding)
    self:BuildHilitePanel(dtabhilite)

    parentTabs:AddSheet(T("report_tab_hilite"), dtabhilite, "icon16/star.png", false, false, T("report_tab_hilite_tip"))

    -- Event log tab
    local dtabevents = vgui.Create("DPanel", parentTabs)
    dtabevents:StretchToParent(padding, padding, padding, padding)
    self:BuildEventLogPanel(dtabevents)

    parentTabs:AddSheet(T("report_tab_events"), dtabevents, "icon16/application_view_detail.png", false, false, T("report_tab_events_tip"))

    -- Score tab
    local dtabscores = vgui.Create("DPanel", parentTabs)
    dtabscores:SetPaintBackground(false)
    dtabscores:StretchToParent(padding, padding, padding, padding)
    self:BuildScorePanel(dtabscores)

    parentTabs:AddSheet(T("report_tab_scores"), dtabscores, "icon16/user.png", false, false, T("report_tab_scores_tip"))

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
    local scores, nicks, roles = {}, {}, {}

    local game, selected, spawn = false, false, false
    for i = 1, #events do
        local e = events[i]
        if e.id == EVENT_GAME then
            if e.state == ROUND_ACTIVE then
                starttime = e.t

                if selected and spawn then
                    break
                end

                game = true
            end
        elseif e.id == EVENT_SELECTED then
            roles = e.roles

            if game and spawn then
                break
            end

            selected = true
        elseif e.id == EVENT_SPAWN then
            scores[e.sid64] = ScoreInit()
            nicks[e.sid64] = e.ni

            if game and selected then
                break
            end

            spawn = true
        end
    end

    scores = ScoreEventLog(events, scores, roles)

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

    if events == "" then
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