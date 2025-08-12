------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Taskmaster_Translations_Initialize", function()
    -- ConVars
    LANG.AddToLanguage("english", "taskmaster_config_x_pos", "Task list X (horizontal) position")
    LANG.AddToLanguage("english", "taskmaster_config_y_pos", "Task list Y (vertical) position")

    -- Reroll Menu
    LANG.AddToLanguage("english", "equip_tooltip_taskmaster_reroll", "Task Reroll control")

    LANG.AddToLanguage("english", "taskmaster_reroll_name", "Task Reroll")

    -- Bonus credit popup
    LANG.AddToLanguage("english", "taskmaster_credit_bonus", "{role}, you have been awarded {num} credit(s) for completing a task.")

    -- Win conditions
    LANG.AddToLanguage("english", "win_taskmaster", "The {role} finished off their list!")
    LANG.AddToLanguage("english", "ev_win_taskmaster", "The methodical {role} has won the round!")

    -- HUD
    LANG.AddToLanguage("english", "taskmaster_hud", "You will lose in: {time}")
end)

-------------
-- CONVARS --
-------------

local taskmaster_wins_with_others = GetConVar("ttt_taskmaster_wins_with_others")

local xOffset = CreateClientConVar("ttt_taskmaster_list_x_pos", "10", true, false, "The X (horizontal) position of the Taskmaster's task list HUD", 0, ScrW())
local yOffset = CreateClientConVar("ttt_taskmaster_list_y_pos", "10", true, false, "The Y (vertical) position of the Taskmaster's task list HUD", 0, ScrH())

hook.Add("TTTSettingsRolesTabSections", "Taskmaster_TTTSettingsRolesTabSections", function(role, parentForm)
    if role ~= ROLE_TASKMASTER then return end

    parentForm:NumSlider(LANG.GetTranslation("taskmaster_config_x_pos"), "ttt_taskmaster_list_x_pos", 0, ScrW(), 0)
    parentForm:NumSlider(LANG.GetTranslation("taskmaster_config_y_pos"), "ttt_taskmaster_list_y_pos", 0, ScrH(), 0)
    return true
end)


----------------
-- WIN CHECKS --
----------------

hook.Add("TTTScoringWinTitle", "Taskmaster_TTTScoringWinTitle", function(wintype, wintitles, title, secondary_win_role)
    if wintype == WIN_TASKMASTER then
        return { txt = "hilite_win_role_singular", params = { role = string.upper(ROLE_STRINGS[ROLE_TASKMASTER]) }, c = ROLE_COLORS[ROLE_TASKMASTER] }
    end
end)

hook.Add("TTTScoringSecondaryWins", "Taskmaster_TTTScoringSecondaryWins", function(wintype, secondary_wins)
    if wintype == WIN_TASKMASTER then return end

    if not taskmaster_wins_with_others:GetBool() then return end

    for _, ply in player.Iterator() do
        if not ply:IsTaskmaster() then continue end
        if ply.taskmasterShouldWin then
            table.insert(secondary_wins, ROLE_TASKMASTER)
            break
        end
    end
end)

------------
-- EVENTS --
------------

hook.Add("TTTEventFinishText", "Taskmaster_TTTEventFinishText", function(e)
    if e.win == WIN_TASKMASTER then
        return LANG.GetParamTranslation("ev_win_taskmaster", { role = string.lower(ROLE_STRINGS[ROLE_TASKMASTER]) })
    end
end)

hook.Add("TTTEventFinishIconText", "Taskmaster_TTTEventFinishIconText", function(e, win_string, role_string)
    if e.win == WIN_TASKMASTER then
        return win_string, ROLE_STRINGS[ROLE_TASKMASTER]
    end
end)

---------
-- HUD --
---------

local client

local margin = 10
local checkboxSize = 21
local maxHeight, maxWidth = 0, 0

local function DrawTask(task, height, isShadow)
    local xPos = xOffset:GetInt()

    local offset = 0
    surface.SetDrawColor(255, 255, 255)
    surface.SetTextColor(255, 255, 255)

    if isShadow then
        offset = 2
        surface.SetDrawColor(0, 0, 0)
        surface.SetTextColor(0, 0, 0)
    end

    local name = task.Name(client)
    local desc = task.Description(client)
    local progress
    if task.Progress then
        progress = task.Progress(client)
        desc = desc .. " " .. progress
    end
    local completed = table.HasValue(client.taskmasterCompletedTasks, task.id)

    -- The checkboxes don't naturally align with the text, thus the '+2's everywhere to make it line up
    surface.DrawRect(xPos + margin + 2 + offset, height + 2 + offset, 2, checkboxSize)
    surface.DrawRect(xPos + margin + 2 + offset, height + 2 + offset, checkboxSize, 2)
    surface.DrawRect(xPos + margin + 2 + offset, height + checkboxSize + offset, checkboxSize, 2)
    surface.DrawRect(xPos + margin + checkboxSize + offset, height + 2 + offset, 2, checkboxSize)

    surface.SetFont("TraitorStateSmall")
    surface.SetTextPos(xPos + (margin * 2) + checkboxSize + offset, height + offset)
    surface.DrawText(name)

    local nameWidth, nameHeight = surface.GetTextSize(name)
    if completed then
        -- Shifting the strikethrough lines down one pixel makes it look much nicer with lowercase letters
        surface.DrawRect(xPos + (margin * 2) + checkboxSize + offset, height + (nameHeight / 2) + 1 + offset, nameWidth, 2)
        if not isShadow then
            -- Drawing the checkmark shadows over the checkbox helps it to stand out
            surface.SetDrawColor(0, 0, 0)
            draw.NoTexture()
            surface.DrawPoly({
                {x = xPos + margin + 5, y = height + 13},
                {x = xPos + margin + 9, y = height + 10},
                {x = xPos + margin + 14, y = height + 15},
                {x = xPos + margin + 14, y = height + 21}
            })
            surface.DrawPoly({
                {x = xPos + margin + 14, y = height + 21},
                {x = xPos + margin + 14, y = height + 15},
                {x = xPos + margin + 26, y = height + 3},
                {x = xPos + margin + 29, y = height + 6}
            })
            surface.SetDrawColor(0, 192, 0)
            surface.DrawPoly({
                {x = xPos + margin + 4, y = height + 11},
                {x = xPos + margin + 8, y = height + 8},
                {x = xPos + margin + 13, y = height + 13},
                {x = xPos + margin + 13, y = height + 19}
            })
            surface.DrawPoly({
                {x = xPos + margin + 13, y = height + 19},
                {x = xPos + margin + 13, y = height + 13},
                {x = xPos + margin + 25, y = height + 1},
                {x = xPos + margin + 28, y = height + 4}
            })
            surface.SetDrawColor(255, 255, 255)
        end
    end

    if (margin * 3) + checkboxSize + nameWidth > maxWidth then maxWidth = (margin * 3) + checkboxSize + nameWidth end

    height = height + nameHeight + (margin / 2)

    surface.SetFont("UseHint")
    surface.SetTextPos(xPos + (margin * 2) + offset, height + offset)
    surface.DrawText(desc)

    local descWidth, descHeight = surface.GetTextSize(desc)
    if completed then
        -- Shifting the strikethrough lines down one pixel makes it look much nicer with lowercase letters
        surface.DrawRect(xPos + (margin * 2) + offset, height + (descHeight / 2) + 1 + offset, descWidth, 1)
    end

    if (margin * 3) + descWidth > maxWidth then maxWidth = (margin * 3) + descWidth end

    height = height + descHeight + margin
    return height
end

hook.Add("HUDPaintBackground", "Taskmaster_HUDPaintBackground", function()
    if GetRoundState() ~= ROUND_ACTIVE then return end
    if maxHeight == 0 or maxWidth == 0 then return end

    if not client then
        client = LocalPlayer()
    end
    if not client:IsActiveTaskmaster() then return end

    -- Add 2 to the maxWidth here to account for the text shadows
    draw.RoundedBox(8, xOffset:GetInt(), yOffset:GetInt(), maxWidth + 2, maxHeight, Color(0, 0, 10, 200))
    maxWidth, maxHeight = 0, 0
end)

hook.Add("HUDPaint", "Taskmaster_HUDPaint", function()
    if GetRoundState() ~= ROUND_ACTIVE then return end

    if not client then
        client = LocalPlayer()
    end
    if not client:IsActiveTaskmaster() then return end

    local height = yOffset:GetInt() + margin

    for _, id in ipairs(client.taskmasterKillTasks) do
        DrawTask(TASKMASTER.killTasks[id], height, true)
        height = DrawTask(TASKMASTER.killTasks[id], height)
    end

    for _, id in ipairs(client.taskmasterMiscTasks) do
        DrawTask(TASKMASTER.miscTasks[id], height, true)
        height = DrawTask(TASKMASTER.miscTasks[id], height)
    end

    maxHeight = height - yOffset:GetInt()
end)

hook.Add("TTTHUDInfoPaint", "Taskmaster_TTTHUDInfoPaint", function(client, label_left, label_top, active_labels)
    if client:IsActiveTaskmaster() then
        local blockEnd = GetGlobalFloat("taskmaster_block_end", 0)
        if blockEnd > 0 then
            surface.SetFont("TabLarge")
            surface.SetTextColor(255, 255, 255, 230)

            local remaining = math.max(0, blockEnd - CurTime())
            local text = LANG.GetParamTranslation("taskmaster_hud", { time = util.SimpleTime(remaining, "%02i:%02i") })
            local _, h = surface.GetTextSize(text)

            -- Move this up based on how many other labels here are
            label_top = label_top + (20 * #active_labels)

            surface.SetTextPos(label_left, ScrH() - label_top - h)
            surface.DrawText(text)

            -- Track that the label was added so others can position accurately
            table.insert(active_labels, "taskmaster")
        end
    end
end)

----------------------
-- TASK REROLL MENU --
----------------------

local dtasks = {}
local dtasksHeight = 0

local scrollBarWidth = 15
local creditsIconSize = 32

local CreateTaskList

local function CreateTaskReroll(task, dscrollpanel)
    if table.HasValue(client.taskmasterCompletedTasks, task.id) then return false end

    local name = task.Name(client)
    local desc = task.Description(client)

    local width, _ = dscrollpanel:GetSize()

    local dpanel = vgui.Create("DPanel", dscrollpanel)
    dpanel:SetPaintBackground(false)
    dpanel:SetWidth(width)
    dpanel:SetPos(0, dtasksHeight)

    local buttonWidth, buttonHeight = 80, 45

    local dname = vgui.Create("DLabel", dpanel)
    dname:SetFont("TraitorStateSmall")
    dname:SetText(name)
    dname:SetPos(margin, margin)
    dname:SetWidth(width - (margin * 2) - buttonWidth - scrollBarWidth)

    local _, nameHeight = dname:GetSize()

    local ddesc = vgui.Create("DLabel", dpanel)
    ddesc:SetFont("UseHint")
    ddesc:SetText(desc)
    ddesc:SetPos(margin, (margin * 1.5) + nameHeight)
    ddesc:SetWidth(width - (margin * 2) - buttonWidth - scrollBarWidth)
    ddesc:SetWrap(true)
    ddesc:SetAutoStretchVertical(true)

    local _, descHeight = ddesc:GetSize()
    local height = (margin * 2.5) + nameHeight + descHeight

    dpanel:SetHeight(height)

    local dreroll = vgui.Create("DButton", dpanel)
    dreroll:SetSize(buttonWidth, buttonHeight)
    dreroll:SetPos(width - margin - buttonWidth, (height - buttonHeight) / 2)
    dreroll:SetText("    Reroll\n (1 credit)")

    dreroll.DoClick = function()
        if client:GetCredits() == 0 then return end

        net.Start("TTT_TaskmasterRerollTask")
        net.WriteString(task.id)
        net.SendToServer()
    end

    dreroll.Think = function()
        dreroll:SetDisabled(client:GetCredits() == 0)
    end

    dpanel.rerollButton = dreroll

    dtasksHeight = dtasksHeight + height

    local dline = vgui.Create("DPanel", dscrollpanel)
    dline:SetSize(width, 1)
    dline:SetPos(0, dtasksHeight)

    dtasksHeight = dtasksHeight + 1

    return dpanel, dline
end

function CreateTaskList(dscrollpanel)
    if not dscrollpanel:IsValid() then return end

    for _, dtask in ipairs(dtasks) do
        dtask:Remove()
    end
    dtasks = {}
    dtasksHeight = 0

    for _, id in ipairs(client.taskmasterKillTasks) do
        local dtask, dline = CreateTaskReroll(TASKMASTER.killTasks[id], dscrollpanel)
        if dtask then
            table.insert(dtasks, dtask)
            table.insert(dtasks, dline)
        end
    end

    for _, id in ipairs(client.taskmasterMiscTasks) do
        local dtask, dline = CreateTaskReroll(TASKMASTER.miscTasks[id], dscrollpanel)
        if dtask then
            table.insert(dtasks, dtask)
            table.insert(dtasks, dline)
        end
    end

    if #dtasks > 0 then
        dtasks[#dtasks]:Remove()

        local spacerWidth, _ = dscrollpanel:GetSize()
        local spacerHeight = (margin * 2) + creditsIconSize

        local dspacer = vgui.Create("DPanel", dscrollpanel)
        dspacer:SetPaintBackground(false)
        dspacer:SetSize(spacerWidth, spacerHeight)
        dspacer:SetPos(0, dtasksHeight)

        dtasksHeight = dtasksHeight + spacerHeight
    end

    if dtasksHeight > dscrollpanel:GetTall() then
        for _, dtask in ipairs(dtasks) do
            if dtask.rerollButton then
                local xPos, yPos = dtask.rerollButton:GetPos()
                dtask.rerollButton:SetPos(xPos - scrollBarWidth, yPos)
            end
        end
    end
end

hook.Add("TTTEquipmentTabs", "Taskmaster_TTTEquipmentTabs", function(dsheet, dframe)
    if not client then
        client = LocalPlayer()
    end

    if client:IsActiveTaskmaster() then
        local padding = dsheet:GetPadding()
        local tabHeight = 20

        local dpanel = vgui.Create("DPanel", dsheet)
        dpanel:SetBackgroundColor(Color(90, 90, 95))
        dpanel:StretchToParent(padding, padding + tabHeight, padding, padding)

        local _, panelHeight = dpanel:GetSize()

        local dscrollpanel = vgui.Create("DScrollPanel", dpanel)
        dscrollpanel:SetPaintBackground(false)
        dscrollpanel:StretchToParent(0, 0, 0, 0)

        local dcredits = vgui.Create("Panel", dsheet)
        dcredits.Paint = function(panel, w, h)
            draw.RoundedBoxEx(8, 0, 0, w, h, Color(151, 155, 159), false, true, false, false)
        end

        local dcreditsicon = vgui.Create("DImage", dcredits)
        dcreditsicon:SetSize(creditsIconSize, creditsIconSize)
        dcreditsicon:SetImage("vgui/ttt/equip/coin.png")

        local dcreditsamount = vgui.Create("DLabel", dcredits)
        dcreditsamount:SetFont("DermaLarge")

        dcreditsamount.Think = function()
            local credits = client:GetCredits()
            local noCreditsColor = Color(220, 60, 60, 255)

            dcreditsamount:SetText(" " .. credits)
            dcreditsamount:SetColor(credits == 0 and noCreditsColor or COLOR_WHITE)
            dcreditsamount:SizeToContents()

            dcreditsicon:SetImageColor(credits == 0 and noCreditsColor or COLOR_WHITE)

            local creditsAmountWidth, _ = dcreditsamount:GetSize()

            local creditsWidth = padding + margin + creditsAmountWidth + creditsIconSize
            local creditsHeight = padding + margin + creditsIconSize
            dcredits:SetSize(creditsWidth, creditsHeight)
            dcredits:SetPos(padding, panelHeight - creditsHeight + padding + tabHeight)

            dcreditsamount:SetPos(padding + creditsIconSize, margin)
            dcreditsicon:SetPos(padding, margin)

            dcredits:MoveToFront()
            dcreditsamount:MoveToFront()
            dcreditsicon:MoveToFront()
        end

        CreateTaskList(dscrollpanel)

        net.Receive("TTT_TaskmasterUpdateTaskList", function(len, ply)
            CreateTaskList(dscrollpanel)
        end)

        dsheet:AddSheet(LANG.GetTranslation("taskmaster_reroll_name"), dscrollpanel, "icon16/table_edit.png", false, false, LANG.GetTranslation("equip_tooltip_taskmaster_reroll"))
        return true
    end
end)