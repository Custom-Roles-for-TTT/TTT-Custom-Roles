local GetRawTranslation = LANG.GetRawTranslation
local StringLower = string.lower
local TableInsert = table.insert
local TableSort = table.sort
local MathMax = math.max
local MathClamp = math.Clamp
local MathCeil = math.ceil
local MathSin = math.sin

local hotkey = CreateClientConVar("ttt_cheatsheat_hotkey", "h", true, false, "Hotkey for opening the cheat sheet")
local panel

local function ClosePanel()
    panel:Close()
    panel = nil
    hook.Remove("Think", "CheetSheet_Think")
end

hook.Add("PlayerButtonDown", "CheatSheet_PlayerButtonDown", function(ply, button)
    if button ~= input.GetKeyCode(hotkey:GetString()) then return end
    if panel ~= nil then return end

    UpdateRoleColours()

    local function AddRolesFromTeam(tbl, team)
        local roles = {}
        for role = 3, ROLE_MAX do -- Skip over the three default roles as they will be added later to avoid sorting
            if (ROLE_STARTING_TEAM[role] == team or (not ROLE_STARTING_TEAM[role] and player.GetRoleTeam(role, false) == team)) and util.CanRoleSpawn(role) then
                TableInsert(roles, role)
            end
        end
        TableSort(roles, function(a, b) return StringLower(ROLE_STRINGS[a]) < StringLower(ROLE_STRINGS[b]) end)
        for _, role in pairs(roles) do
            TableInsert(tbl, role)
        end
    end

    local detectives = {}
    if ROLE_PACK_ROLES[ROLE_DETECTIVE] or GetConVar("ttt_special_detective_pct"):GetFloat() < 1 or GetConVar("ttt_special_detective_chance"):GetFloat() < 1 then
        TableInsert(detectives, ROLE_DETECTIVE)
    end
    AddRolesFromTeam(detectives, ROLE_TEAM_DETECTIVE)
    local innocents = {}
    if ROLE_PACK_ROLES[ROLE_INNOCENT] or GetConVar("ttt_special_innocent_pct"):GetFloat() < 1 or GetConVar("ttt_special_innocent_chance"):GetFloat() < 1 then
        TableInsert(innocents, ROLE_INNOCENT)
    end
    AddRolesFromTeam(innocents, ROLE_TEAM_INNOCENT)
    local traitors = {}
    if ROLE_PACK_ROLES[ROLE_TRAITOR] or GetConVar("ttt_special_traitor_pct"):GetFloat() < 1 or GetConVar("ttt_special_traitor_chance"):GetFloat() < 1 then
        TableInsert(traitors, ROLE_TRAITOR)
    end
    AddRolesFromTeam(traitors, ROLE_TEAM_TRAITOR)
    local jesters = {}
    AddRolesFromTeam(jesters, ROLE_TEAM_JESTER)
    local independents = {}
    AddRolesFromTeam(independents, ROLE_TEAM_INDEPENDENT)
    local monsters = {}
    AddRolesFromTeam(monsters, ROLE_TEAM_MONSTER)

    local iconSize          = 64
    local titleHeight       = 14
    local descriptionWidth  = 256
    local labelHeight       = 16
    local scrollbarWidth    = 15
    local m                 = 5

    local w, h, detectivesHeight, innocentsHeight, traitorsHeight, jestersHeight, independentsHeight, monstersHeight

    local maxColumns = 3
    local fitsScreen = false
    local needsScrollbar = false
    while not fitsScreen do
        local columns = MathClamp(MathMax(#detectives, #innocents, #traitors, #jesters, #independents, #monsters), 1, maxColumns)
        local detectiveRows     = MathCeil(#detectives / columns)
        local innocentRows      = MathCeil(#innocents / columns)
        local traitorRows       = MathCeil(#traitors / columns)
        local jesterRows        = MathCeil(#jesters / columns)
        local independentRows   = MathCeil(#independents / columns)
        local monsterRows       = MathCeil(#monsters / columns)

        local function IsLabelNeeded(tbl)
            return #tbl == 0 and 0 or 1
        end

        local labels = IsLabelNeeded(detectives) + IsLabelNeeded(innocents) + IsLabelNeeded(traitors)
                + IsLabelNeeded(jesters) + IsLabelNeeded(independents) + IsLabelNeeded(monsters)

        detectivesHeight    = MathMax((iconSize + m) * detectiveRows, 0)
        innocentsHeight     = MathMax((iconSize + m) * innocentRows, 0)
        traitorsHeight      = MathMax((iconSize + m) * traitorRows, 0)
        jestersHeight       = MathMax((iconSize + m) * jesterRows, 0)
        independentsHeight  = MathMax((iconSize + m) * independentRows, 0)
        monstersHeight      = MathMax((iconSize + m) * monsterRows, 0)

        w = (iconSize + descriptionWidth + (m * 3)) * columns
        h = detectivesHeight + innocentsHeight + traitorsHeight + jestersHeight + independentsHeight + monstersHeight + (labelHeight * labels) + m

        if needsScrollbar then -- If we know we need a scrollbar then add it
            w = w + scrollbarWidth
            if w > ScrW() then-- If the scrollbar was enough to push us over the edge we need to go back one more column
                maxColumns = maxColumns - 1
            else -- If everything fits with the scrollbar then exit the loop
                h = ScrH()
                fitsScreen = true
            end
        elseif w > ScrW() then -- If it is too wide then we have gone too far and we will need a scrollbar
            maxColumns = maxColumns - 1
            needsScrollbar = true
        elseif h > ScrH() then -- If it is too tall try adding another column
            maxColumns = maxColumns + 1
        else -- If it fits the screen then exit the loop
            fitsScreen = true
        end
    end

    local dframe = vgui.Create("DFrame")
    dframe:SetSize(w, h)
    dframe:Center()
    dframe:SetVisible(true)
    dframe:SetDeleteOnClose(true)
    dframe:ShowCloseButton(false)

    local dbackground = vgui.Create("DPanel", dframe)
    dbackground:SetSize(w, h)
    dbackground:SetPos(0, 0)
    dbackground:SetBackgroundColor(COLOR_GRAY)

    local dlist = vgui.Create("DScrollPanel", dbackground)
    dlist:SetSize(w, h)
    dlist:SetPos(0, 0)

    local dcanvas = dlist:GetCanvas()

    local function CreateTeamList(label, roleTable, height, yOffset)
        local dlabel = vgui.Create("DLabel", dcanvas)
        dlabel:SetFont("TabLarge")
        dlabel:SetText(label)
        dlabel:SetContentAlignment(7)
        dlabel:SetWidth(w)
        dlabel:SetPos(m + 3, yOffset) -- For some reason the text isn't inline with the icons so we shift it 3px to the right

        local dteam = vgui.Create("DPanel", dcanvas)
        dteam:SetPos(m, yOffset + labelHeight)
        dteam:SetSize(w, height)
        dteam:SetPaintBackground(false)

        local currentColumn = 0
        local currentRow = 0

        for _, role in pairs(roleTable) do
            local icon = vgui.Create("SimpleIcon", dteam)

            local roleStringShort = ROLE_STRINGS_SHORT[role]
            local material = util.GetRoleIconPath(roleStringShort, "icon", "vtf")

            local color = ROLE_COLORS[role]
            local dark_color = ROLE_COLORS_DARK[role]
            if not DEFAULT_ROLES[role] and ROLE_STARTING_TEAM[role] then
                color = GetRoleTeamColor(ROLE_STARTING_TEAM[role])
                dark_color = GetRoleTeamColor(ROLE_STARTING_TEAM[role], "dark")
            end

            icon:SetIconSize(iconSize)
            icon:SetIcon(material)
            icon:SetBackgroundColor(color or Color(0, 0, 0, 0))
            icon:SetTooltip(ROLE_STRINGS[role])
            icon:SetPos(currentColumn * (iconSize + descriptionWidth + (m * 2)), currentRow * (iconSize + m))
            icon.DoClick = function()
                HELPSCRN:OpenRoleTutorial(role)
                ClosePanel()
            end

            if role == ply:GetRole() and ply:IsActive() then
                local r1, g1, b1, _ = color:Unpack()
                local r2, g2, b2, _ = dark_color:Unpack()
                local rd = r2 - r1
                local gd = g2 - g1
                local bd = b2 - b1
                hook.Add("Think", "CheetSheet_Think", function()
                    local fade = (MathSin(RealTime() * 3) + 1) / 2
                    icon:SetBackgroundColor(Color(r1 + (fade * rd), g1 + (fade * gd), b1 + (fade * bd), 255))
                end)
            end

            local title = vgui.Create("DLabel", dteam)
            title:SetFont("TabLarge")
            title:SetPos(iconSize + m + (currentColumn * (iconSize + descriptionWidth + (m * 2))), currentRow * (iconSize + m))
            title:SetSize(descriptionWidth, titleHeight)
            title:SetContentAlignment(7)
            if role == ply:GetRole() and ply:IsActive() then
                title:SetText(ROLE_STRINGS[role] .. " (CURRENT ROLE)")
            else
                title:SetText(ROLE_STRINGS[role])
            end

            local desc = vgui.Create("DLabel", dteam)
            desc:SetPos(iconSize + m + (currentColumn * (iconSize + descriptionWidth + (m * 2))), titleHeight + (currentRow * (iconSize + m)))
            desc:SetSize(descriptionWidth, iconSize - titleHeight)
            desc:SetWrap(true)
            desc:SetContentAlignment(7)

            local roleString = ROLE_STRINGS_RAW[role]
            local newRoleString = hook.Call("TTTCheatSheetRoleStringOverride", nil, ply, roleString)
            if type(newRoleString) == "string" then roleString = newRoleString end

            local text = GetRawTranslation("cheatsheet_desc_" .. roleString)
            if text == nil then
                desc:SetText("Role description not found.")
            else
                desc:SetText(text)
            end

            currentColumn = currentColumn + 1
            if currentColumn == maxColumns then
                currentColumn = 0
                currentRow = currentRow + 1
            end
        end
    end

    local yOffset = m
    if #detectives > 0 then
        CreateTeamList("Detective Roles", detectives, detectivesHeight, yOffset)
        yOffset = yOffset + detectivesHeight + labelHeight
    end
    if #innocents > 0 then
        CreateTeamList("Innocent Roles", innocents, innocentsHeight, yOffset)
        yOffset = yOffset + innocentsHeight + labelHeight
    end
    if #traitors > 0 then
        CreateTeamList("Traitor Roles", traitors, traitorsHeight, yOffset)
        yOffset = yOffset + traitorsHeight + labelHeight
    end
    if #jesters > 0 then
        CreateTeamList("Jester Roles", jesters, jestersHeight, yOffset)
        yOffset = yOffset + jestersHeight + labelHeight
    end
    if #independents > 0 then
        CreateTeamList("Independent Roles", independents, independentsHeight, yOffset)
        yOffset = yOffset + independentsHeight + labelHeight
    end
    if #monsters > 0 then
        CreateTeamList("Monster Roles", monsters, monstersHeight, yOffset)
    end

    dframe:MakePopup()
    dframe:SetKeyboardInputEnabled(false)

    panel = dframe
end)

hook.Add("PlayerButtonUp", "CheatSheet_PlayerButtonUp", function(ply, button)
    if button ~= input.GetKeyCode(hotkey:GetString()) then return end
    if panel == nil then return end

    ClosePanel()
end)