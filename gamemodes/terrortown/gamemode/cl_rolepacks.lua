local concommand = concommand
local vgui = vgui
local util = util
local net = net
local table = table
local math = math
local string = string

local GetTranslation = LANG.GetTranslation
local TableInsert = table.insert
local TableRemove = table.remove
local TableRemoveByValue = table.RemoveByValue
local MathCeil = math.ceil
local StringSub = string.sub
local StringLower = string.lower

-- 2^16 bytes - 4 (header) - 2 (UInt length) - 1 (terminanting byte)
local maxStreamLength = 65529

local function SendStreamToServer(tbl, networkString)
    local jsonTable = util.TableToJSON(tbl)
    if jsonTable == nil then
        ErrorNoHalt("Table encoding failed!\n")
        return
    end

    jsonTable = util.Compress(jsonTable)
    if jsonTable == "" then
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
        local json = util.Decompress(buff .. net.ReadData(net.ReadUInt(16)))
        buff = ""

        if json == "" then
            ErrorNoHalt("Table decompression failed!\n")
        end

        local jsonTable = util.JSONToTable(json)
        if jsonTable == nil then
            ErrorNoHalt("Table decoding failed!\n")
        end

        callback(jsonTable)
    end)
end

local function WriteRolePackTable(slots, name, config)
    local slotTable = {name = name, config = config, slots = {}}
    for _, slot in pairs(slots) do
        local roleTable = {}
        for _, role in pairs(slot) do
            TableInsert(roleTable, {role = ROLE_STRINGS_RAW[role.role], weight = role.weight})
        end
        TableInsert(slotTable.slots, roleTable)
    end
    SendStreamToServer(slotTable, "TTT_WriteRolePackTable")
end

local function BuildRoleConfig(dframe, packName)
    UpdateRoleColours()

    local slotList = {}

    local droles = vgui.Create("DPanel", dframe)
    droles:SetPaintBackground(false)
    droles:StretchToParent(0, 0, 0, 0)

    local dconfig = vgui.Create("DPanel", droles)
    dconfig:SetPaintBackground(false)
    dconfig:StretchToParent(0, 0, 0, nil)
    dconfig:SetHeight(16)

    local dallowduplicates = vgui.Create("DCheckBoxLabel", dconfig)
    dallowduplicates:SetText("Allow Duplicate Roles")
    dallowduplicates:Dock(LEFT)
    dallowduplicates:DockMargin(0, 0, 12, 0)
    dallowduplicates.OnChange = function()
        WriteRolePackTable(slotList, packName, {allowduplicates = dallowduplicates:GetChecked()})
    end

    local dslotlist = vgui.Create("DScrollPanel", droles)
    dslotlist:SetPaintBackground(false)
    dslotlist:StretchToParent(0, 20, 13, 88)

    local function CreateSlot(roleTable)
        local iconHeight = 88

        local dslot = vgui.Create("DPanel", dslotlist)
        dslot:SetPaintBackground(false)
        dslot:SetSize(dslotlist:GetSize(), 16 + iconHeight)
        dslot:Dock(TOP)

        local dlabel = vgui.Create("DLabel", dslot)
        dlabel:SetFont("TabLarge")
        dlabel:SetText("Role Slot:")
        dlabel:SetContentAlignment(7)
        dlabel:SetPos(3, 0) -- For some reason the text isn't inline with the icons so we shift it 3px to the right

        local dlist = vgui.Create("EquipSelect", dslot)
        dlist:SetPos(0, 14)
        dlist:StretchToParent(0, nil, 0, nil)
        dlist:SetHeight(iconHeight)
        dlist:EnableHorizontal(true)

        local roleList = {}
        TableInsert(slotList, roleList)

        local function CreateRole(rolestr, weight)
            local role = ROLE_NONE
            for r = ROLE_INNOCENT, ROLE_MAX do
                if ROLE_STRINGS_RAW[r] == rolestr then
                    role = r
                    break
                end
            end

            local drole = vgui.Create("DPanel", dlist)
            drole:SetSize(64, 84)
            drole:SetPaintBackground(false)
            drole.role = role
            drole.weight = 1

            local dicon = vgui.Create("SimpleIcon", drole)
            local material = ROLE_ICON_ICON_MATERIALS[ROLE_STRINGS_SHORT[role]]

            dicon:SetIconSize(64)
            dicon:SetIcon(material)
            dicon:SetBackgroundColor(ROLE_COLORS[role] or Color(0, 0, 0, 0))
            dicon:SetTooltip(ROLE_STRINGS[role])
            dicon.DoClick = function()
                local dmenu = DermaMenu()
                for r, s in SortedPairsByValue(ROLE_STRINGS) do
                    dmenu:AddOption(s, function()
                        material = ROLE_ICON_ICON_MATERIALS[ROLE_STRINGS_SHORT[r]]
                        dicon:SetIcon(material)
                        dicon:SetBackgroundColor(ROLE_COLORS[r] or Color(0, 0, 0, 0))
                        dicon:SetTooltip(s)
                        drole.role = r
                        WriteRolePackTable(slotList, packName, {allowduplicates = dallowduplicates:GetChecked()})
                    end)
                end
                dmenu:Open()
            end

            local dweight = vgui.Create("DNumberWang", drole)
            dweight:SetWidth(64)
            dweight:SetPos(0, 64)
            dweight:SetMin(1)
            dweight:SetValue(weight)
            dweight.OnValueChanged = function(_, value)
                drole.weight = value
                WriteRolePackTable(slotList, packName, {allowduplicates = dallowduplicates:GetChecked()})
            end

            TableInsert(roleList, drole)

            local iconRows = MathCeil((#roleList + 1) / 8)
            dslot:SetSize(dslotlist:GetSize(), 16 + iconRows * iconHeight)
            dlist:SetHeight(iconRows * iconHeight)

            dlist:AddPanel(drole)
        end

        for _, role in pairs(roleTable) do
            CreateRole(role.role, role.weight)
        end

        local dbuttons = vgui.Create("DPanel", dlist)
        dbuttons:SetSize(64, 84)
        dbuttons:SetPaintBackground(false)

        local daddrolebutton = vgui.Create("DButton", dbuttons)
        daddrolebutton:SetSize(22, 22)
        daddrolebutton:SetPos(0, 0)
        daddrolebutton:SetText("")
        daddrolebutton:SetIcon("icon16/add.png")
        daddrolebutton:SetTooltip(GetTranslation("rolepacks_add_role"))
        daddrolebutton.DoClick = function()
            TableRemove(dlist.Items)
            CreateRole(ROLE_INNOCENT, 1)
            dlist:AddPanel(dbuttons)
            WriteRolePackTable(slotList, packName, {allowduplicates = dallowduplicates:GetChecked()})
        end

        local ddeleterolebutton = vgui.Create("DButton", dbuttons)
        ddeleterolebutton:SetSize(22, 22)
        ddeleterolebutton:SetPos(0, 24)
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
            dslot:SetSize(dslotlist:GetSize(), 16 + iconRows * iconHeight)
            dlist:SetHeight(iconRows * iconHeight)
            WriteRolePackTable(slotList, packName, {allowduplicates = dallowduplicates:GetChecked()})
        end

        local ddeleteslotbutton = vgui.Create("DButton", dbuttons)
        ddeleteslotbutton:SetSize(22, 22)
        ddeleteslotbutton:SetPos(0, 48)
        ddeleteslotbutton:SetText("")
        ddeleteslotbutton:SetIcon("icon16/bin.png")
        ddeleteslotbutton:SetTooltip(GetTranslation("rolepacks_delete_slot"))
        ddeleteslotbutton.DoClick = function()
            TableRemoveByValue(slotList, roleList)
            dslot:Remove()
            WriteRolePackTable(slotList, packName, {allowduplicates = dallowduplicates:GetChecked()})
        end

        dlist:AddPanel(dbuttons)

        dslotlist:AddItem(dslot)
    end

    local function ReadRolePackTable(name)
        net.Start("TTT_RequestRolePackTable")
        net.WriteString(name)
        net.SendToServer()
    end

    local function UpdateRolePackUI(jsonTable)
        dslotlist:Clear()
        dallowduplicates:SetChecked(jsonTable.config.allowduplicates)
        for _, slot in pairs(jsonTable.slots) do
            CreateSlot(slot)
        end
    end
    ReceiveStreamFromServer("TTT_ReadRolePackTable", UpdateRolePackUI)

    local daddslotbutton = vgui.Create("DButton", droles)
    daddslotbutton:SetText(GetTranslation("rolepacks_add_slot"))
    daddslotbutton:Dock(BOTTOM)
    daddslotbutton.DoClick = function()
        CreateSlot({})
        WriteRolePackTable(slotList, packName, {allowduplicates = dallowduplicates:GetChecked()})
    end

    if not packName or packName == "" then
        daddslotbutton:SetDisabled(true)
        dallowduplicates:SetDisabled(true)
    else
        ReadRolePackTable(packName)
    end

    return droles
end

local function IsNameValid(name, dpack)
    if string.find(name, '[\\/:%*%?"<>|]') then
        LocalPlayer():PrintMessage(HUD_PRINTTALK, 'Name cannot contain the following characters: \\/:*?"<>|')
        return false
    elseif #name > 20 then
        LocalPlayer():PrintMessage(HUD_PRINTTALK, 'Name cannot be longer than 20 characters')
        return false
    else
        for _, v in pairs(dpack.Choices) do
            if name == v then
                LocalPlayer():PrintMessage(HUD_PRINTTALK, 'Name cannot be a duplicate of another role pack')
                return false
            end
        end
    end
    return true
end

local function OpenDialog()
    local numCols = 8
    local numRows = 5
    local itemSize = 64
    -- margin
    local m = 5
    -- item list width
    local dlistw = ((itemSize + 2) * numCols) - 2 + 15
    local dlisth = ((itemSize + 2) * numRows) - 2 + 15
    -- frame size
    local w = dlistw + (m * 4)
    local h = dlisth + 75 + m + 22

    local dframe = vgui.Create("DFrame")
    dframe:SetSize(w, h)
    dframe:Center()
    dframe:SetTitle(GetTranslation("rolepacks_title"))
    dframe:SetVisible(true)
    dframe:ShowCloseButton(true)
    dframe:SetMouseInputEnabled(true)
    dframe:SetDeleteOnClose(true)

    local droles = BuildRoleConfig(dframe, "")
    droles:SetPos(0, 0)
    droles:StretchToParent(m, 2 * m + 47, m, m)

    local dpack = vgui.Create("DComboBox", dframe)
    dpack:SetPos(m, m + 25)
    dpack:StretchToParent(m, nil, 5 * m + 88, nil)
    dpack.OnSelect = function(_, _, name)
        droles:Remove()
        droles = BuildRoleConfig(dframe, name)
        droles:SetPos(0, 0)
        droles:StretchToParent(m, 2 * m + 47, m, m)
    end

    net.Start("TTT_RequestRolePackList")
    net.SendToServer()

    net.Receive("TTT_SendRolePackList", function()
        local currentPack = GetConVar("ttt_role_pack"):GetString()
        local length = net.ReadUInt(8)
        for _ = 1, length do
            local packName = net.ReadString()
            local index = dpack:AddChoice(packName)
            if packName == currentPack then
                dpack:ChooseOption(packName, index)
            end
        end
    end)

    local dapplybutton = vgui.Create("DButton", dframe)
    dapplybutton:SetSize(22, 22)
    dapplybutton:SetPos(w - (m + 22), m + 25)
    dapplybutton:SetText("")
    dapplybutton:SetIcon("icon16/server_go.png")
    dapplybutton:SetTooltip(GetTranslation("rolepacks_apply"))
    dapplybutton.DoClick = function()
        local pack, _ = dpack:GetSelected()
        if not pack or pack == "" then return end
        net.Start("TTT_ApplyRolePack")
        net.WriteString(pack)
        net.SendToServer()
    end

    local ddeletebutton = vgui.Create("DButton", dframe)
    ddeletebutton:SetSize(22, 22)
    ddeletebutton:SetPos(w - 2 * (m + 22), m + 25)
    ddeletebutton:SetText("")
    ddeletebutton:SetIcon("icon16/delete.png")
    ddeletebutton:SetTooltip(GetTranslation("rolepacks_delete"))
    ddeletebutton.DoClick = function()
        local pack, index = dpack:GetSelected()
        if not pack or pack == "" then return end

        dframe:SetMouseInputEnabled(false)

        local dconfirmdialog = vgui.Create("DFrame")
        dconfirmdialog:SetSize(300, 60)
        dconfirmdialog:Center()
        dconfirmdialog:SetTitle("Are you sure you want to delete " .. pack .. "?")
        dconfirmdialog:SetVisible(true)
        dconfirmdialog:ShowCloseButton(false)
        dconfirmdialog:SetMouseInputEnabled(true)
        dconfirmdialog:SetDeleteOnClose(true)
        dconfirmdialog.OnClose = function()
            dframe:SetMouseInputEnabled(true)
        end

        local dyes = vgui.Create("DButton", dconfirmdialog)
        dyes:SetText("Yes")
        dyes:SetPos(150 - 64 - m, 25 + m)
        dyes.DoClick = function()
            TableRemove(dpack.Choices, index)
            dpack:SetText("")
            dpack.selected = nil
            net.Start("TTT_DeleteRolePack")
            net.WriteString(pack)
            net.SendToServer()
            droles:Remove()
            dconfirmdialog:Close()
            droles = BuildRoleConfig(dframe, "")
            droles:SetPos(0, 0)
            droles:StretchToParent(m, 2 * m + 47, m, m)
        end

        local dno = vgui.Create("DButton", dconfirmdialog)
        dno:SetText("No")
        dno:SetPos(150 + m, 25 + m)
        dno.DoClick = function()
            dconfirmdialog:Close()
        end

        dconfirmdialog:MakePopup()
    end

    local drenamebutton = vgui.Create("DButton", dframe)
    drenamebutton:SetSize(22, 22)
    drenamebutton:SetPos(w - 3 * (m + 22), m + 25)
    drenamebutton:SetText("")
    drenamebutton:SetIcon("icon16/page_edit.png")
    drenamebutton:SetTooltip(GetTranslation("rolepacks_rename"))
    drenamebutton.DoClick = function()
        local pack, index = dpack:GetSelected()
        if not pack or pack == "" then return end

        dframe:SetMouseInputEnabled(false)

        local drenamedialog = vgui.Create("DFrame")
        drenamedialog:SetSize(300, 60)
        drenamedialog:Center()
        drenamedialog:SetTitle("Renaming " .. pack)
        drenamedialog:SetVisible(true)
        drenamedialog:ShowCloseButton(true)
        drenamedialog:SetMouseInputEnabled(true)
        drenamedialog:SetDeleteOnClose(true)
        drenamedialog.OnClose = function()
            dframe:SetMouseInputEnabled(true)
        end

        local drenameentry = vgui.Create("DTextEntry", drenamedialog)
        drenameentry:SetPos(m, 25 + m)
        drenameentry:SetWidth(300 - 3 * m - 64)
        drenameentry:SetText(pack)

        local drename = vgui.Create("DButton", drenamedialog)
        drename:SetText("Rename")
        drename:SetPos(300 - m - 64, 25 + m)
        drename.DoClick = function()
            local newpack = StringLower(drenameentry:GetValue())
            if not newpack or newpack == "" then return end
            if not IsNameValid(newpack, dpack) then return end
            TableRemove(dpack.Choices, index)
            local newindex = dpack:AddChoice(newpack)
            dpack:SetText(newpack)
            dpack.selected = newindex
            net.Start("TTT_RenameRolePack")
            net.WriteString(pack)
            net.WriteString(newpack)
            net.SendToServer()
            drenamedialog:Close()
        end

        drenamedialog:MakePopup()
    end

    local dnewbutton = vgui.Create("DButton", dframe)
    dnewbutton:SetSize(22, 22)
    dnewbutton:SetPos(w - 4 * (m + 22), m + 25)
    dnewbutton:SetText("")
    dnewbutton:SetIcon("icon16/add.png")
    dnewbutton:SetTooltip(GetTranslation("rolepacks_add"))
    dnewbutton.DoClick = function()
        dframe:SetMouseInputEnabled(false)

        local dnewdialog = vgui.Create("DFrame")
        dnewdialog:SetSize(300, 60)
        dnewdialog:Center()
        dnewdialog:SetTitle("Create new role pack")
        dnewdialog:SetVisible(true)
        dnewdialog:ShowCloseButton(true)
        dnewdialog:SetMouseInputEnabled(true)
        dnewdialog:SetDeleteOnClose(true)
        dnewdialog.OnClose = function()
            dframe:SetMouseInputEnabled(true)
        end

        local dnewentry = vgui.Create("DTextEntry", dnewdialog)
        dnewentry:SetPos(m, 25 + m)
        dnewentry:SetWidth(300 - 3 * m - 64)

        local dconfirm = vgui.Create("DButton", dnewdialog)
        dconfirm:SetText("Confirm")
        dconfirm:SetPos(300 - m - 64, 25 + m)
        dconfirm.DoClick = function()
            local pack = StringLower(dnewentry:GetValue())
            if not pack or pack == "" then return end
            if not IsNameValid(pack, dpack) then return end
            local index = dpack:AddChoice(pack)
            dpack:ChooseOption(pack, index)
            net.Start("TTT_CreateRolePack")
            net.WriteString(pack)
            net.SendToServer()
            droles:Remove()
            dnewdialog:Close()
            droles = BuildRoleConfig(dframe, pack)
            droles:SetPos(0, 0)
            droles:StretchToParent(m, 2 * m + 47, m, m)
        end

        dnewdialog:MakePopup()
    end

    dframe:MakePopup()
end

concommand.Add("ttt_rolepacks", function(ply, cmd, args)
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ErrorNoHalt("ERROR: You must be an administrator to open the Role Packs Configuration dialog\n")
        return
    end
    OpenDialog()
end)

net.Receive("TTT_SendRolePackRoleList", function()
    ROLE_PACK_ROLES = {}
    
    local count = net.ReadUInt(8)
    if count <= 0 then return end
    for _ = 1, count do
        local role = net.ReadUInt(8)
        ROLE_PACK_ROLES[role] = true
    end
end)