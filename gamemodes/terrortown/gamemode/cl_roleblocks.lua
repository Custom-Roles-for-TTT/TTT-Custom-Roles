local concommand = concommand
local vgui = vgui
local util = util
local net = net
local pairs = pairs
local table = table
local math = math
local string = string

local GetTranslation = LANG.GetTranslation
local TableInsert = table.insert
local TableRemove = table.remove
local TableRemoveByValue = table.RemoveByValue
local MathCeil = math.ceil
local StringSub = string.sub

local numCols = 4
local numRows = 5
local itemSize = 64
-- margin
local m = 5
-- item list width
local dlistw = ((itemSize + 2) * numCols) - 2 + 15
local dlisth = ((itemSize + 2) * numRows) - 2 + 15
-- right column width
local diw = 270
-- frame size
local w = dlistw + diw + (m * 4)
local h = dlisth + 75 + m + 22

-- 2^16 bytes - 4 (header) - 2 (UInt length) - 1 (Extra optional byte)  - 1 (terminanting byte)
local maxStreamLength = 65528

local function SendStreamToServer(tbl, networkString)
    local jsonTable = util.TableToJSON(tbl)
    if jsonTable == nil then
        ErrorNoHalt("Table encoding failed!\n")
        return
    end

    jsonTable = util.Compress(jsonTable)
    if #jsonTable == 0 then
        ErrorNoHalt("Table compression failed!\n")
        return
    end

    local len = #jsonTable

    if len <= maxStreamLength then
        net.Start(networkString)
        net.WriteUInt(len, 16)
        net.WriteData(jsonTable, len)
        net.SendToServer()
    else
        local curpos = 0

        repeat
            net.Start(networkString .. "_Part")
            net.WriteData(StringSub(jsonTable, curpos + 1, curpos + maxStreamLength + 1), maxStreamLength)
            net.SendToServer()

            curpos = curpos + maxStreamLength + 1
        until (len - curpos <= maxStreamLength)

        net.Start(networkString)
        net.WriteUInt(len, 16)
        net.WriteData(StringSub(jsonTable, curpos + 1, len), len - curpos)
        net.SendToServer()
    end
end

local function ReceiveStreamFromServer(networkString, callback)
    local buff = ""
    net.Receive(networkString .. "_Part", function()
        buff = buff .. net.ReadData(maxStreamLength)
    end)

    net.Receive(networkString, function()
        local byte = net.ReadUInt(8)
        local json = util.Decompress(buff .. net.ReadData(net.ReadUInt(16)))
        buff = ""

        if #json == 0 then
            ErrorNoHalt("Table decompression failed!\n")
            return
        end

        local jsonTable = util.JSONToTable(json)
        if jsonTable == nil then
            ErrorNoHalt("Table decoding failed!\n")
            return
        end

        callback(jsonTable, byte)
    end)
end

local function BuildRoleBlockConfig(dsheet, packName, tab)
    UpdateRoleColours()

    local titleBarHeight = 25
    local groupList = {}

    local droleblocks = vgui.Create("DPanel", dsheet)
    droleblocks:SetPaintBackground(false)
    droleblocks:StretchToParent(m, titleBarHeight, m, m)
    droleblocks.unsavedChanges = false

    local buttonHeight = 22

    local dgrouplist = vgui.Create("DScrollPanel", droleblocks)
    dgrouplist:SetPaintBackground(false)
    dgrouplist:StretchToParent(0, m, 0, buttonHeight + m)

    local function CreateGroup(roleTable)
        local labelHeight = 10
        local iconWidth = 64
        local iconHeight = 84
        local buttonSize = 22

        local dgroup = vgui.Create("DPanel", dgrouplist)
        dgroup:SetPaintBackground(false)
        dgroup:SetSize(dgrouplist:GetSize(), labelHeight + iconHeight + 2 * m)
        dgroup:Dock(TOP)

        local dlabel = vgui.Create("DLabel", dgroup)
        dlabel:SetFont("TabLarge")
        dlabel:SetContentAlignment(7)
        dlabel:SetPos(3, 0) -- For some reason the text isn't inline with the icons so we shift it 3px to the right
        dlabel:SetText("Blocking Group:")
        dlabel:SetWidth(200)

        local dlist = vgui.Create("EquipSelect", dgroup)
        dlist:SetPos(0, labelHeight + m)
        dlist:StretchToParent(0, nil, 0, nil)
        dlist:SetHeight(iconHeight + 2 * m)
        dlist:EnableHorizontal(true)

        local roleList = {}
        TableInsert(groupList, roleList)

        local function CreateRole(rolestr, weight)
            local role = ROLE_NONE
            for r = ROLE_INNOCENT, ROLE_MAX do
                if ROLE_STRINGS_RAW[r] == rolestr then
                    role = r
                    break
                end
            end

            local drole = vgui.Create("DPanel", dlist)
            drole:SetSize(iconWidth, iconHeight)
            drole:SetPaintBackground(false)
            drole.role = role
            drole.weight = 1

            local dicon = vgui.Create("SimpleIcon", drole)

            local roleStringShort = ROLE_STRINGS_SHORT[role]
            local material = util.GetRoleIconPath(roleStringShort, "icon", "vtf")

            dicon:SetIconSize(iconWidth)
            dicon:SetIcon(material)
            dicon:SetBackgroundColor(ROLE_COLORS[role] or Color(0, 0, 0, 0))
            dicon:SetTooltip(ROLE_STRINGS[role])
            dicon.DoClick = function()
                local dmenu = DermaMenu()
                for r, s in SortedPairsByValue(ROLE_STRINGS) do
                    dmenu:AddOption(s, function()
                        roleStringShort = ROLE_STRINGS_SHORT[r]
                        material = util.GetRoleIconPath(roleStringShort, "icon", "vtf")
                        dicon:SetIcon(material)
                        dicon:SetBackgroundColor(ROLE_COLORS[r] or Color(0, 0, 0, 0))
                        dicon:SetTooltip(s)
                        drole.role = r
                        droleblocks.unsavedChanges = true
                    end)
                end
                dmenu:Open()
            end

            local dweight = vgui.Create("DNumberWang", drole)
            dweight:SetWidth(iconWidth)
            dweight:SetPos(0, iconWidth)
            dweight:SetMin(1)
            dweight:SetValue(weight)
            dweight.OnValueChanged = function(_, value)
                drole.weight = value
                droleblocks.unsavedChanges = true
            end

            TableInsert(roleList, drole)

            local iconRows = MathCeil((#roleList + 1) / 8)
            dgroup:SetSize(dgrouplist:GetSize(), labelHeight + iconRows * iconHeight + 2 * m)
            dlist:SetHeight(iconRows * iconHeight + 2 * m)

            dlist:AddPanel(drole)
        end

        for _, role in pairs(roleTable) do
            CreateRole(role.role, role.weight)
        end

        local dbuttons = vgui.Create("DPanel", dlist)
        dbuttons:SetSize(iconWidth, iconHeight)
        dbuttons:SetPaintBackground(false)

        local daddrolebutton = vgui.Create("DButton", dbuttons)
        daddrolebutton:SetSize(buttonSize, buttonSize)
        daddrolebutton:SetPos(0, 0)
        daddrolebutton:SetText("")
        daddrolebutton:SetIcon("icon16/add.png")
        daddrolebutton:SetTooltip(GetTranslation("rolepacks_add_role"))
        daddrolebutton.DoClick = function()
            TableRemove(dlist.Items)
            CreateRole(ROLE_INNOCENT, 1)
            dlist:AddPanel(dbuttons)
            droleblocks.unsavedChanges = true
        end

        local ddeleterolebutton = vgui.Create("DButton", dbuttons)
        ddeleterolebutton:SetSize(buttonSize, buttonSize)
        ddeleterolebutton:SetPos(0, buttonSize + m)
        ddeleterolebutton:SetText("")
        ddeleterolebutton:SetIcon("icon16/delete.png")
        ddeleterolebutton:SetTooltip(GetTranslation("rolepacks_delete_role"))
        ddeleterolebutton.DoClick = function()
            if #dlist.Items == 1 then return end
            TableRemove(dlist.Items)
            local drole = TableRemove(roleList)
            drole:Remove()
            dlist:AddPanel(dbuttons)
            local iconRows = MathCeil((#dlist.Items) / 8)
            dgroup:SetSize(dgrouplist:GetSize(), labelHeight + iconRows * iconHeight + 2 * m)
            dlist:SetHeight(iconRows * iconHeight + 2 * m)
            droleblocks.unsavedChanges = true
        end

        local ddeletegroupbutton = vgui.Create("DButton", dbuttons)
        ddeletegroupbutton:SetSize(buttonSize, buttonSize)
        ddeletegroupbutton:SetPos(0, 2 * (buttonSize + m))
        ddeletegroupbutton:SetText("")
        ddeletegroupbutton:SetIcon("icon16/bin.png")
        ddeletegroupbutton:SetTooltip(GetTranslation("roleblocks_delete_group"))
        ddeletegroupbutton.DoClick = function()
            TableRemoveByValue(groupList, roleList)
            dgroup:Remove()
            droleblocks.unsavedChanges = true
        end

        dlist:AddPanel(dbuttons)

        dgrouplist:AddItem(dgroup)
    end

    local dbuttons = vgui.Create("DPanel", droleblocks)
    dbuttons:Dock(BOTTOM)
    dbuttons:SetHeight(buttonHeight)
    dbuttons:SetPaintBackground(false)

    local panelWidth, _ = droleblocks:GetSize()

    local daddgroupbutton = vgui.Create("DButton", dbuttons)
    daddgroupbutton:SetWidth(panelWidth / 2)
    daddgroupbutton:SetText(GetTranslation("roleblocks_add_group"))
    daddgroupbutton.DoClick = function()
        CreateGroup({})
        droleblocks.unsavedChanges = true
    end

    local dsave = vgui.Create("DButton", dbuttons)
    dsave:SetWidth(panelWidth / 2)
    dsave:SetPos(panelWidth / 2 + m, 0)
    dsave:SetText(GetTranslation("rolepacks_save"))
    dsave.DoClick = function()
        droleblocks.Save()
        droleblocks.unsavedChanges = false
    end

    local function UpdateRoleBlockUI(jsonTable)
        dgrouplist:Clear()
        for _, group in pairs(jsonTable) do
            CreateGroup(group)
        end
    end
    ReceiveStreamFromServer("TTT_ReadRoleBlocks", UpdateRoleBlockUI)

    net.Start("TTT_RequestRoleBlocks")
    net.SendToServer()

    droleblocks.HasUnsavedChanges = function()
        return droleblocks.unsavedChanges
    end

    droleblocks.Save = function()
        if droleblocks.HasUnsavedChanges() then
            local groupTable = {}
            for _, group in pairs(groupList) do
                local roleTable = {}
                for _, role in pairs(group) do
                    TableInsert(roleTable, {role = ROLE_STRINGS_RAW[role.role], weight = role.weight})
                end
                TableInsert(groupTable, roleTable)
            end
            SendStreamToServer(groupTable, "TTT_WriteRoleBlocks")
        end
    end

    return droleblocks
end

local function OpenDialog()
    local dframe = vgui.Create("DFrame")
    dframe:SetSize(w, h)
    dframe:Center()
    dframe:SetTitle(GetTranslation("roleblocks_title"))
    dframe:SetVisible(true)
    dframe:ShowCloseButton(true)
    dframe:SetMouseInputEnabled(true)
    dframe:SetDeleteOnClose(true)

    local droleblocks = BuildRoleBlockConfig(dframe)

    local oldClose = dframe.Close
    dframe.Close = function(self)
        if not droleblocks.HasUnsavedChanges() then
            oldClose(self)
            return
        end

        dframe:SetMouseInputEnabled(false)

        local titleBarHeight = 25
        local buttonWidth = 64
        local popupWidth = 300
        local popupHeight = 60

        local dsavedialog = vgui.Create("DFrame")
        dsavedialog:SetSize(popupWidth, popupHeight)
        dsavedialog:Center()
        dsavedialog:SetTitle("Would you like to save your changes?")
        dsavedialog:SetVisible(true)
        dsavedialog:ShowCloseButton(false)
        dsavedialog:SetMouseInputEnabled(true)
        dsavedialog:SetDeleteOnClose(true)
        dsavedialog.OnClose = function()
            dframe:SetMouseInputEnabled(true)
        end

        local dyes = vgui.Create("DButton", dsavedialog)
        dyes:SetText("Yes")
        dyes:SetPos(popupWidth / 2 - buttonWidth - m, titleBarHeight + m)
        dyes.DoClick = function()
            droleblocks.Save()
            dsavedialog:Close()
            oldClose(self)
        end

        local dno = vgui.Create("DButton", dsavedialog)
        dno:SetText("No")
        dno:SetPos(popupWidth / 2 + m, titleBarHeight + m)
        dno.DoClick = function()
            dsavedialog:Close()
            oldClose(self)
        end

        dsavedialog:MakePopup()
    end

    dframe:MakePopup()
end

concommand.Add("ttt_roleblocks", function(ply, cmd, args)
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ErrorNoHalt("ERROR: You must be an administrator to open the Role Blocks Configuration dialog\n")
        return
    end
    OpenDialog()
end)