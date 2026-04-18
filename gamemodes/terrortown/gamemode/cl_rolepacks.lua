local concommand = concommand
local cvars = cvars
local hook = hook
local ipairs = ipairs
local math = math
local net = net
local pairs = pairs
local string = string
local table = table
local util = util
local vgui = vgui

local AddHook = hook.Add
local GetParamTranslation = LANG.GetParamTranslation
local GetTranslation = LANG.GetTranslation
local MathCeil = math.ceil
local MathClamp = math.Clamp
local MathFloor = math.floor
local SafeTranslate = LANG.TryTranslation
local StringFind = string.find
local StringLower = string.lower
local StringSub = string.sub
local TableCopy = table.Copy
local TableHasValue = table.HasValue
local TableInsert = table.insert
local TableRemove = table.remove
local TableRemoveByValue = table.RemoveByValue
local TableSort = table.sort

local equipment_sorting = GetConVar("ttt_equipment_sorting")
local equipment_ascending = GetConVar("ttt_equipment_ascending")

local numCols = 4
local numRows = 5
local itemSize = 64
-- margin
local m = 5
local buttonMargin = 1
-- item list width
local dlistw = ((itemSize + 2) * numCols) - 2 + 15
local dlisth = ((itemSize + 2) * numRows) - 2 + 15
-- right column width
local diw = 270
-- frame size
local w = dlistw + diw + (m * 4)
local h = dlisth + 75 + m + 22

-- 2^16 bytes - 4 (header) - 2 (UInt length) - 1 (Extra optional byte) - 1 (terminating byte)
local maxStreamLength = 65528

local packDetails = {}

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

local function ItemIsWeapon(item) return not tonumber(item.id) end

local sort_funcs = {
   default = {
      name = "equip_sort_default",
      func = function(a, b)
                local aItem, bItem = not ItemIsWeapon(a), not ItemIsWeapon(b)

                if aItem or bItem then
                   -- sort items by id
                   if aItem and bItem then
                      return a.id < b.id
                   end

                   -- keep items above weapons
                   return aItem
                end

                return StringLower(SafeTranslate(a.name)) < StringLower(SafeTranslate(b.name))
             end
   },
   name = {
      name = "equip_spec_name",
      func = function(a, b)
                return StringLower(SafeTranslate(a.name)) < StringLower(SafeTranslate(b.name))
             end
   },
   slot = {
      name = "equip_sort_slot",
      func = function(a, b)
                local aSlot = a.slot or 0
                local bSlot = b.slot or 0

                -- sort items by id
                if aSlot == 0 and bSlot == 0 then
                   return a.id < b.id
                end

                if aSlot == bSlot then
                   return StringLower(SafeTranslate(a.name)) < StringLower(SafeTranslate(b.name))
                end

                return aSlot < bSlot
             end
   }
}

local function SortEquipmentPanels(pnls)
   local sort = equipment_sorting:GetString() or "default"
   local sort_func = sort_funcs[sort].func

   local ascending = equipment_ascending:GetBool()

   TableSort(pnls, function(a, b)
      local aItem, bItem = a.item, b.item
      local ret = sort_func(aItem, bItem)

      -- if table.sort is comparing an item to itself, don't mess with the result otherwise weird stuff happens
      if not ascending and aItem.id ~= bItem.id then
         ret = not ret
      end

      return ret
   end)
end

local ListPanel = nil
local function AddSortedPanels(panels)
    SortEquipmentPanels(panels)
    for _, panel in pairs(panels) do
        ListPanel:AddPanel(panel)
    end
end

local function ReSortEquipment()
    if not IsValid(ListPanel) then return end

    -- temp table for sorting
    local paneltable = {}
    for _, ic in ipairs(ListPanel:GetItems()) do
        TableInsert(paneltable, ic)
    end

    ListPanel:Clear()
    AddSortedPanels(paneltable)
    ListPanel:InvalidateLayout()
end
AddHook("TTTLanguageChanged", "TTT_RolePacks_ReSortEquipment", ReSortEquipment)
cvars.AddChangeCallback("ttt_equipment_sorting", ReSortEquipment, "rolepacks")
cvars.AddChangeCallback("ttt_equipment_ascending", ReSortEquipment, "rolepacks")

local function DoesValueMatch(item, data, value)
    if not item[data] then return false end

    local itemdata = item[data]
    if isfunction(itemdata) then
        itemdata = itemdata()
    end
    return itemdata and StringFind(StringLower(SafeTranslate(itemdata)), StringLower(value), 1, true)
end

local function IsNameUsed(name, dpack)
    for _, v in pairs(dpack.Choices) do
        if name == v then
            return true
        end
    end
    return false
end

local function IsNameValid(name, dpack, overwrite)
    if string.find(name, "[\\/:%*%?\"<>|]") then
        LocalPlayer():PrintMessage(HUD_PRINTTALK, "Name cannot contain the following characters: \\/:*?\"<>|")
        return false
    elseif #name > 30 then
        LocalPlayer():PrintMessage(HUD_PRINTTALK, "Name cannot be longer than 30 characters")
        return false
    elseif not overwrite and IsNameUsed(name, dpack) then
        LocalPlayer():PrintMessage(HUD_PRINTTALK, "Name cannot be a duplicate of another role pack")
        return false
    end
    return true
end

local function BuildRoleConfig(dsheet, packName, tab)
    UpdateRoleColours()

    local slotList = {}

    local droles = vgui.Create("DPanel", dsheet)
    droles:SetPaintBackground(false)
    droles:StretchToParent(0, 0, 0, 0)
    droles.unsavedChanges = false

    local configHeight = 16
    local buttonHeight = 22

    local dconfig = vgui.Create("DPanel", droles)
    dconfig:SetPaintBackground(false)
    dconfig:StretchToParent(0, 0, 0, nil)
    dconfig:SetHeight(configHeight)

    local dallowduplicates = vgui.Create("DCheckBoxLabel", dconfig)
    dallowduplicates:SetText(GetTranslation("rolepacks_allow_duplicate"))
    dallowduplicates:Dock(LEFT)
    dallowduplicates.OnChange = function()
        droles.unsavedChanges = true
    end

    local dslotlist = vgui.Create("DScrollPanel", droles)
    dslotlist:SetPaintBackground(false)
    dslotlist:StretchToParent(0, configHeight + m, 16, buttonHeight + m + 36)  -- For some reason filling the scroll panel to the size of its parent makes it too big, thus the magic numbers

    local slotLabels = {}
    local function UpdateSlotLabels()
        for index, label in ipairs(slotLabels) do
            label:SetText(GetParamTranslation("rolepacks_slot_title", { num = index }))
        end
    end

    local listwidth, listheight = dslotlist:GetSize()
    local dlayout = vgui.Create("DListLayout", dslotlist)
    dlayout:SetPaintBackground(false)
    dlayout:SetSize(listwidth, listheight)
    dlayout:MakeDroppable("cr4ttt_rolepacks_packslots")
    dlayout.OnModified = function()
        slotLabels = {}
        for _, dslot in ipairs(dlayout:GetChildren()) do
            TableInsert(slotLabels, dslot.label)
        end
        UpdateSlotLabels()
    end

    local function CreateSlot(roleTable)
        local labelHeight = 10
        local iconWidth = 64
        local iconHeight = 84
        local buttonSize = 20

        local dslot = vgui.Create("DPanel", dlayout)
        dslot:SetPaintBackground(false)
        dslot:SetSize(dlayout:GetSize(), labelHeight + iconHeight + 2 * m)
        dslot:Dock(TOP)

        local dlabel = vgui.Create("DLabel", dslot)
        dlabel:SetFont("TabLarge")
        dlabel:SetContentAlignment(7)
        dlabel:SetPos(3, 0) -- For some reason the text isn't inline with the icons so we shift it 3px to the right
        TableInsert(slotLabels, dlabel)
        dslot.label = dlabel

        local dlist = vgui.Create("EquipSelect", dslot)
        dlist:SetPos(0, labelHeight + m)
        dlist:StretchToParent(0, nil, 0, nil)
        dlist:SetHeight(iconHeight + 2 * m)
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
            drole:SetSize(iconWidth, iconHeight)
            drole:SetPaintBackground(false)
            drole.role = role
            drole.weight = weight
            drole.rolestr = rolestr

            local dicon = vgui.Create("SimpleIcon", drole)

            local roleStringShort = ROLE_STRINGS_SHORT[role]
            local material = util.GetRoleIconPath(roleStringShort, "icon", "vtf")

            dicon:SetIconSize(iconWidth)
            dicon:SetIcon(material)
            dicon:SetBackgroundColor(ROLE_COLORS[role] or Color(0, 0, 0, 0))
            if role ~= ROLE_NONE then
                dicon:SetTooltip(ROLE_STRINGS[role])
            -- Show the string that was loaded from JSON if it doesn't exist on the server anymore
            elseif rolestr ~= nil then
                dicon:SetTooltip(GetParamTranslation("rolepacks_unknown_role", { role = rolestr }))
            end
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
                        drole.rolestr = ROLE_STRINGS_RAW[r]
                        droles.unsavedChanges = true
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
                droles.unsavedChanges = true
            end

            TableInsert(roleList, drole)

            local iconRows = MathCeil((#roleList + 1) / 8)
            dslot:SetSize(dlayout:GetSize(), labelHeight + iconRows * iconHeight + 2 * m)
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
            CreateRole(nil, 1)
            dlist:AddPanel(dbuttons)
            droles.unsavedChanges = true
        end

        local ddeleterolebutton = vgui.Create("DButton", dbuttons)
        ddeleterolebutton:SetSize(buttonSize, buttonSize)
        ddeleterolebutton:SetPos(0, buttonSize + buttonMargin)
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
            dslot:SetSize(dlayout:GetSize(), labelHeight + iconRows * iconHeight + 2 * m)
            dlist:SetHeight(iconRows * iconHeight + 2 * m)
            droles.unsavedChanges = true
        end

        local ddeleteslotbutton = vgui.Create("DButton", dbuttons)
        ddeleteslotbutton:SetSize(buttonSize, buttonSize)
        ddeleteslotbutton:SetPos(0, 2 * (buttonSize + buttonMargin))
        ddeleteslotbutton:SetText("")
        ddeleteslotbutton:SetIcon("icon16/bin.png")
        ddeleteslotbutton:SetTooltip(GetTranslation("rolepacks_delete_slot"))
        ddeleteslotbutton.DoClick = function()
            TableRemoveByValue(slotList, roleList)
            TableRemoveByValue(slotLabels, dlabel)
            UpdateSlotLabels()
            dslot:Remove()
            droles.unsavedChanges = true
        end

        local ddupeslotbutton = vgui.Create("DButton", dbuttons)
        ddupeslotbutton:SetSize(buttonSize, buttonSize)
        ddupeslotbutton:SetPos(0, 3 * (buttonSize + buttonMargin))
        ddupeslotbutton:SetText("")
        ddupeslotbutton:SetIcon("icon16/page_copy.png")
        ddupeslotbutton:SetTooltip(GetTranslation("rolepacks_duplicate_slot"))
        ddupeslotbutton.DoClick = function()
            local slotRoles = {}
            for _, d in ipairs(roleList) do
                TableInsert(slotRoles, {
                    role = d.rolestr,
                    weight = d.weight
                })
            end
            CreateSlot(slotRoles)
            UpdateSlotLabels()
            droles.unsavedChanges = true
        end

        dlist:AddPanel(dbuttons)

        dlayout:Add(dslot)
    end

    local daddslotbutton = vgui.Create("DButton", droles)
    daddslotbutton:SetText(GetTranslation("rolepacks_add_slot"))
    daddslotbutton:Dock(BOTTOM)
    daddslotbutton.DoClick = function()
        CreateSlot({})
        UpdateSlotLabels()
        droles.unsavedChanges = true
    end

    local function ReadRolePackRoleTable(name)
        net.Start("TTT_RequestRolePackRoles")
            net.WriteString(name)
        net.SendToServer()
    end

    local function UpdateRolePackRoleUI(jsonTable)
        dlayout:Clear()
        if jsonTable.config then
            dallowduplicates:SetChecked(jsonTable.config.allowduplicates)

            for _, slot in pairs(jsonTable.slots) do
                CreateSlot(slot)
            end
        end
        UpdateSlotLabels()
    end
    ReceiveStreamFromServer("TTT_ReadRolePackRoles", UpdateRolePackRoleUI)

    if not packName or #packName == 0 then
        daddslotbutton:SetEnabled(false)
        dallowduplicates:SetEnabled(false)
    else
        ReadRolePackRoleTable(packName)
    end

    droles.HasUnsavedChanges = function()
        return droles.unsavedChanges
    end

    droles.Save = function(name)
        if droles.HasUnsavedChanges() then
            packName = name or packName
            local slotTable = {name = packName, details = packDetails[packName], config = {allowduplicates = dallowduplicates:GetChecked()}, slots = {}}
            for _, slot in pairs(slotList) do
                local roleTable = {}
                for _, role in pairs(slot) do
                    TableInsert(roleTable, {role = ROLE_STRINGS_RAW[role.role], weight = role.weight})
                end
                TableInsert(slotTable.slots, roleTable)
            end
            SendStreamToServer(slotTable, "TTT_WriteRolePackRoles")
            droles.unsavedChanges = false
        end
    end

    if tab then
        tab:SetPanel(droles)
        local properySheetPadding = tab:GetPropertySheet():GetPadding()
        droles:SetPos(properySheetPadding, 20 + properySheetPadding) -- From PANEL:AddSheet
    else
        local tabTable = dsheet:AddSheet(GetTranslation("rolepacks_role_tabtitle"), droles, "icon16/user.png", false, false, GetTranslation("rolepacks_role_tabtitle_tooltip"))
        tab = tabTable.Tab
    end

    return droles, tab
end

local function BuildRoleBlockConfig(dsheet, packName, tab)
    UpdateRoleColours()

    local groupList = {}

    local droleblocks = vgui.Create("DPanel", dsheet)
    droleblocks:SetPaintBackground(false)
    droleblocks:StretchToParent(0, 0, 0, 0)
    droleblocks.unsavedChanges = false

    local configHeight = 16
    local buttonHeight = 22

    local dconfig = vgui.Create("DPanel", droleblocks)
    dconfig:SetPaintBackground(false)
    dconfig:StretchToParent(0, 0, 0, nil)
    dconfig:SetHeight(configHeight)

    local dusedefault = vgui.Create("DCheckBoxLabel", dconfig)
    dusedefault:SetText(GetTranslation("roleblocks_use_default"))
    dusedefault:Dock(LEFT)
    dusedefault.OnChange = function()
        droleblocks.unsavedChanges = true
    end

    local dgrouplist = vgui.Create("DScrollPanel", droleblocks)
    dgrouplist:SetPaintBackground(false)
    dgrouplist:StretchToParent(0, configHeight + m, 16, buttonHeight + m + 36)  -- For some reason filling the scroll panel to the size of its parent makes it too big, thus the magic numbers

    local listwidth, listheight = dgrouplist:GetSize()
    local dlayout = vgui.Create("DListLayout", dgrouplist)
    dlayout:SetPaintBackground(false)
    dlayout:SetSize(listwidth, listheight)
    dlayout:MakeDroppable("cr4ttt_rolepacks_blockgroups")

    local function CreateGroup(roleTable)
        local labelHeight = 10
        local iconWidth = 64
        local iconHeight = 84
        local buttonSize = 20

        local dgroup = vgui.Create("DPanel", dlayout)
        dgroup:SetPaintBackground(false)
        dgroup:SetSize(dlayout:GetSize(), labelHeight + iconHeight + 2 * m)
        dgroup:Dock(TOP)

        local dlabel = vgui.Create("DLabel", dgroup)
        dlabel:SetFont("TabLarge")
        dlabel:SetContentAlignment(7)
        dlabel:SetPos(3, 0) -- For some reason the text isn't inline with the icons so we shift it 3px to the right
        dlabel:SetText(GetTranslation("roleblocks_group_title"))
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
            drole.rolestr = rolestr
            drole.weight = 1

            local dicon = vgui.Create("SimpleIcon", drole)

            local roleStringShort = ROLE_STRINGS_SHORT[role]
            local material = util.GetRoleIconPath(roleStringShort, "icon", "vtf")

            dicon:SetIconSize(iconWidth)
            dicon:SetIcon(material)
            dicon:SetBackgroundColor(ROLE_COLORS[role] or Color(0, 0, 0, 0))
            if role ~= ROLE_NONE then
                dicon:SetTooltip(ROLE_STRINGS[role])
            -- Show the string that was loaded from JSON if it doesn't exist on the server anymore
            elseif rolestr ~= nil then
                dicon:SetTooltip(GetParamTranslation("roleblocks_unknown_role", { role = rolestr }))
            end
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
                        drole.rolestr = ROLE_STRINGS_RAW[r]
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
            dgroup:SetSize(dlayout:GetSize(), labelHeight + iconRows * iconHeight + 2 * m)
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
            CreateRole(nil, 1)
            dlist:AddPanel(dbuttons)
            droleblocks.unsavedChanges = true
        end

        local ddeleterolebutton = vgui.Create("DButton", dbuttons)
        ddeleterolebutton:SetSize(buttonSize, buttonSize)
        ddeleterolebutton:SetPos(0, buttonSize + buttonMargin)
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
            dgroup:SetSize(dlayout:GetSize(), labelHeight + iconRows * iconHeight + 2 * m)
            dlist:SetHeight(iconRows * iconHeight + 2 * m)
            droleblocks.unsavedChanges = true
        end

        local ddeletegroupbutton = vgui.Create("DButton", dbuttons)
        ddeletegroupbutton:SetSize(buttonSize, buttonSize)
        ddeletegroupbutton:SetPos(0, 2 * (buttonSize + buttonMargin))
        ddeletegroupbutton:SetText("")
        ddeletegroupbutton:SetIcon("icon16/bin.png")
        ddeletegroupbutton:SetTooltip(GetTranslation("roleblocks_delete_group"))
        ddeletegroupbutton.DoClick = function()
            TableRemoveByValue(groupList, roleList)
            dgroup:Remove()
            droleblocks.unsavedChanges = true
        end

        local ddupegroupbutton = vgui.Create("DButton", dbuttons)
        ddupegroupbutton:SetSize(buttonSize, buttonSize)
        ddupegroupbutton:SetPos(0, 3 * (buttonSize + buttonMargin))
        ddupegroupbutton:SetText("")
        ddupegroupbutton:SetIcon("icon16/page_copy.png")
        ddupegroupbutton:SetTooltip(GetTranslation("roleblocks_duplicate_group"))
        ddupegroupbutton.DoClick = function()
            local groupRoles = {}
            for _, d in ipairs(roleList) do
                TableInsert(groupRoles, {
                    role = d.rolestr,
                    weight = d.weight
                })
            end
            CreateGroup(groupRoles)
            droleblocks.unsavedChanges = true
        end

        dlist:AddPanel(dbuttons)

        dlayout:Add(dgroup)
    end

    local daddgroupbutton = vgui.Create("DButton", droleblocks)
    daddgroupbutton:SetText(GetTranslation("roleblocks_add_group"))
    daddgroupbutton:Dock(BOTTOM)
    daddgroupbutton.DoClick = function()
        CreateGroup({})
        droleblocks.unsavedChanges = true
    end

    local function ReadRolePackRoleBlockTable(name)
        net.Start("TTT_RequestRolePackRoleBlocks")
            net.WriteString(name)
        net.SendToServer()
    end

    local function UpdateRolePackRoleBlockUI(jsonTable)
        dlayout:Clear()
        if jsonTable.config then
            dusedefault:SetChecked(jsonTable.config.usedefault)

            for _, group in pairs(jsonTable.groups) do
                CreateGroup(group)
            end
        end
    end
    ReceiveStreamFromServer("TTT_ReadRolePackRoleBlocks", UpdateRolePackRoleBlockUI)

    if not packName or #packName == 0 then
        daddgroupbutton:SetEnabled(false)
        dusedefault:SetEnabled(false)
    else
        ReadRolePackRoleBlockTable(packName)
    end

    droleblocks.HasUnsavedChanges = function()
        return droleblocks.unsavedChanges
    end

    droleblocks.Save = function(name)
        if droleblocks.HasUnsavedChanges() then
            packName = name or packName
            local groupTable = { name = packName, config = { usedefault = dusedefault:GetChecked()}, groups = {}}
            for _, group in pairs(groupList) do
                local roleTable = {}
                for _, role in pairs(group) do
                    TableInsert(roleTable, {role = ROLE_STRINGS_RAW[role.role], weight = role.weight})
                end
                TableInsert(groupTable.groups, roleTable)
            end
            SendStreamToServer(groupTable, "TTT_WriteRolePackRoleBlocks")
            droleblocks.unsavedChanges = false
        end
    end

    if tab then
        tab:SetPanel(droleblocks)
        local properySheetPadding = tab:GetPropertySheet():GetPadding()
        droleblocks:SetPos(properySheetPadding, 20 + properySheetPadding) -- From PANEL:AddSheet
    else
        local tabTable = dsheet:AddSheet(GetTranslation("rolepacks_roleblock_tabtitle"), droleblocks, "icon16/stop.png", false, false, GetTranslation("rolepacks_roleblock_tabtitle_tooltip"))
        tab = tabTable.Tab
    end

    return droleblocks, tab
end

local function BuildWeaponConfig(dsheet, packName, tab)
    local dweapons = vgui.Create("DPanel", dsheet)
    dweapons:SetPaintBackground(false)
    dweapons:StretchToParent(0, 0, 0, 0)
    dweapons.unsavedChanges = false

    local role = ROLE_NONE
    local save_role = ROLE_NONE

    local dsearchheight = 25
    local dsearchpadding = 5
    local dsortdirsize = 16
    local sw = MathFloor((dlistw - dsearchpadding) / 2)

    local dsearch = vgui.Create("DTextEntry", dweapons)
    dsearch:SetPos(0, 0)
    dsearch:SetSize(sw, dsearchheight)
    dsearch:SetPlaceholderText("Search...")
    dsearch:SetUpdateOnType(true)

    local dsort = vgui.Create("DPanel", dweapons)
    dsort:SetPos(sw + dsearchpadding, 0)
    dsort:SetSize(sw, dsearchheight)
    dsort:SetPaintBackground(false)

    local dsortlbl = vgui.Create("DLabel", dsort)
    dsortlbl:SetFont("DermaDefaultBold")
    dsortlbl:SetText(GetTranslation("sb_sortby"))
    dsortlbl:SizeToContentsX()
    dsortlbl:SetTall(dsearchheight)
    dsortlbl:SetColor(COLOR_WHITE)

    local dsorttype = vgui.Create("DComboBox", dsort)
    dsorttype:MoveRightOf(dsortlbl, m)
    dsorttype:SetSize(dsort:GetWide() - dsortlbl:GetWide() - m - dsortdirsize, dsearchheight)

    for key, data in pairs(sort_funcs) do
        dsorttype:AddChoice(GetTranslation(data.name), key, StringLower(equipment_sorting:GetString()) == key)
    end

    dsorttype.OnSelect = function(s, idx, val, data) equipment_sorting:SetString(data) end

    local dsortasc = vgui.Create("DButton", dsort)
    dsortasc:SetSize(dsortdirsize, dsortdirsize)
    dsortasc:MoveRightOf(dsorttype)
    dsortasc:SetY(dsearchpadding)
    dsortasc:SetText("")
    dsortasc:SetTooltip(GetTranslation("equip_sort_direction_tip"))

    dsortasc.Paint = function(s, pw, ph)
        local name = equipment_ascending:GetBool() and "ButtonUp" or "ButtonDown"
        derma.SkinHook("Paint", name, s, dsortdirsize, dsortdirsize)
    end

    dsortasc.DoClick = function(s) equipment_ascending:SetBool(not equipment_ascending:GetBool()) end

    local dinfow = diw - m
    local dsearchrole = vgui.Create("DComboBox", dweapons)
    dsearchrole:CopyPos(dsort)
    dsearchrole:MoveRightOf(dsort)
    local dsrw, dsrh = dsearchrole:GetPos()
    dsearchrole:SetPos(dsrw + dsearchpadding, dsrh)
    dsearchrole:SetSize(dinfow - dsearchpadding * 2, dsearchheight)
    dsearchrole:AddChoice(GetTranslation("roleweapons_select_searchrole"), ROLE_NONE, true)
    dsearchrole:SetTooltip(GetTranslation("roleweapons_select_searchrole_tooltip"))
    for r = ROLE_INNOCENT, ROLE_MAX do
        dsearchrole:AddChoice(ROLE_STRINGS[r], r)
    end

    --- Construct icon listing
    --- icon size = 64 x 64
    local dlist = vgui.Create("EquipSelect", dweapons)
    dlist:SetPos(0, dsearchheight + dsearchpadding)
    dlist:SetSize(dlistw, dlisth - dsearchheight - dsearchpadding)
    dlist:EnableVerticalScrollbar()
    dlist:EnableHorizontal(true)

    ListPanel = dlist

    local bw, bh = 126, 25

    -- Whole right column
    local dih = h - bh - m * 20 - 30 - m - 22
    local dinfobg = vgui.Create("DPanel", dweapons)
    dinfobg:SetPaintBackground(false)
    dinfobg:SetSize(dinfow, dih)
    dinfobg:SetPos(dlistw + m, dsearchheight + dsearchpadding)

    -- item info pane
    local dinfo = vgui.Create("ColoredBox", dinfobg)
    dinfo:SetColor(Color(90, 90, 95))
    dinfo:SetPos(0, 0)
    dinfo:StretchToParent(0, 0, m * 2, 40)

    local dfields = {}
    for _, k in pairs({ "name", "type", "desc" }) do
        dfields[k] = vgui.Create("DLabel", dinfo)
        dfields[k]:SetTooltip(GetTranslation("equip_spec_" .. k))
        dfields[k]:SetPos(m * 3, m * 2)
        dfields[k]:SetWidth(diw - m * 6)
        dfields[k]:SetText("")
    end

    dfields.name:SetFont("TabLarge")

    dfields.type:SetFont("DermaDefault")
    dfields.type:MoveBelow(dfields.name)

    dfields.desc:SetFont("DermaDefaultBold")
    dfields.desc:SetContentAlignment(7)
    dfields.desc:MoveBelow(dfields.type, 1)

    local weaponChanges = {name = "", weapons = {}}
    local oldWeaponChanges = TableCopy(weaponChanges)

    local function FillEquipmentList(itemlist)
        dlist:Clear()

        -- temp table for sorting
        local paneltable = {}

        for k, item in pairs(itemlist) do
            local ic = nil

            -- Create icon panel
            if item.material then
                ic = vgui.Create("LayeredIcon", dlist)

                if item.custom then
                    -- Custom marker icon
                    local marker = vgui.Create("DImage")
                    marker:SetImage("vgui/ttt/custom_marker")
                    marker.PerformLayout = function(s)
                        s:AlignBottom(2)
                        s:AlignRight(2)
                        s:SetSize(16, 16)
                    end
                    marker:SetTooltip(GetTranslation("equip_custom"))

                    ic:AddLayer(marker)

                    ic:EnableMousePassthrough(marker)
                end

                -- Slot marker icon
                ic.slot = 0
                local table_index
                if ItemIsWeapon(item) then
                    local slot = vgui.Create("SimpleIconLabelled")
                    slot:SetIcon("vgui/ttt/slot_cap")
                    slot:SetIconColor(ROLE_COLORS[role] or COLOR_GREY)
                    slot:SetIconSize(16)

                    slot:SetIconText(item.slot)
                    ic.slot = item.slot

                    -- Credit to @Angela and @Technofrood on the Lonely Yogs Discord for the fix!
                    -- Clamp the item slot within the correct limits
                    if ic.slot ~= nil then
                        ic.slot = MathClamp(ic.slot, 1, 9)
                    end

                    slot:SetIconProperties(COLOR_WHITE,
                            "DefaultBold",
                            { opacity = 220, offset = 1 },
                            { 9, 8 })

                    ic:AddLayer(slot)
                    ic:EnableMousePassthrough(slot)

                    table_index = item.id
                else
                    table_index = item.name
                end

                local state_icon = nil
                local tooltip = nil
                if weaponChanges.weapons[save_role] then
                    if weaponChanges.weapons[save_role].Buyables and table.HasValue(weaponChanges.weapons[save_role].Buyables, table_index) then
                        state_icon = "cart_add.png"
                        tooltip = "roleweapons_buyable_tooltip"
                    elseif weaponChanges.weapons[save_role].Excludes and table.HasValue(weaponChanges.weapons[save_role].Excludes, table_index) then
                        state_icon = "cart_delete.png"
                        tooltip = "roleweapons_exclude_tooltip"
                    end
                end

                if state_icon ~= nil then
                    local state = vgui.Create("DImage")
                    state:SetImage("icon16/" .. state_icon)
                    state.PerformLayout = function(s)
                        s:AlignBottom(3)
                        s:AlignLeft(3)
                        s:SetSize(16, 16)
                    end
                    state:SetTooltip(GetTranslation(tooltip))

                    ic:AddLayer(state)
                    ic:EnableMousePassthrough(state)
                end

                if weaponChanges.weapons[save_role] and weaponChanges.weapons[save_role].NoRandoms and table.HasValue(weaponChanges.weapons[save_role].NoRandoms, table_index) then
                    local norandom = vgui.Create("DImage")
                    norandom:SetImage("icon16/cart_put.png")
                    norandom.PerformLayout = function(s)
                        s:AlignTop(3)
                        s:AlignRight(3)
                        s:SetSize(16, 16)
                    end
                    norandom:SetTooltip(GetTranslation("roleweapons_norandom_tooltip"))

                    ic:AddLayer(norandom)
                    ic:EnableMousePassthrough(norandom)
                end

                if weaponChanges.weapons[save_role] and weaponChanges.weapons[save_role].Loadouts and table.HasValue(weaponChanges.weapons[save_role].Loadouts, table_index) then
                    local loadout = vgui.Create("DImage")
                    loadout:SetImage("icon16/cart_go.png")
                    loadout.PerformLayout = function(s)
                        s:AlignBottom(3)
                        s:CenterHorizontal()
                        s:SetSize(16, 16)
                    end
                    loadout:SetTooltip(GetTranslation("roleweapons_loadout_tooltip"))

                    ic:AddLayer(loadout)
                    ic:EnableMousePassthrough(loadout)
                end

                ic:SetIconSize(itemSize)
                ic:SetIcon(item.material)
            elseif item.model then
                ic = vgui.Create("SpawnIcon", dlist)
                ic:SetModel(item.model)
            else
                ErrorNoHalt("Equipment item does not have model or material specified: " .. tostring(item) .. "\n")
            end

            ic.item = item

            local tip = SafeTranslate(item.name) .. " (" .. SafeTranslate(item.type) .. ")"
            ic:SetTooltip(tip)

            -- Don't show equipment items that you already own that are listed as "loadout" because you were given it for free
            local externalLoadout = ROLE_LOADOUT_ITEMS[role] and TableHasValue(ROLE_LOADOUT_ITEMS[role], item.name)
            if not ItemIsWeapon(item) and (item.loadout or externalLoadout) then
                ic:Remove()
            else
                TableInsert(paneltable, ic)
            end
        end

        AddSortedPanels(paneltable)

        -- select first
        dlist:SelectPanel(dlist:GetItems()[1])
    end
    dsearch.OnValueChange = function(box, value)
        if role <= ROLE_NONE then return end

        local roleitems = GetEquipmentForRole(role, false, true, true, true, weaponChanges.weapons[role] or false)
        local filtered = {}
        for _, v in pairs(roleitems) do
            if v and (DoesValueMatch(v, "name", value) or DoesValueMatch(v, "desc", value)) then
                table.insert(filtered, v)
            end
        end
        FillEquipmentList(filtered)
    end

    local dsaverole = vgui.Create("DComboBox", dweapons)
    dsaverole:SetPos(dlistw + m, dih)
    dsaverole:SetSize(dinfow - dsearchpadding * 2, dsearchheight)
    dsaverole:AddChoice(GetTranslation("roleweapons_select_saverole"), ROLE_NONE, true)
    dsaverole:SetTooltip(GetTranslation("roleweapons_select_saverole_tooltip"))
    for r = ROLE_INNOCENT, ROLE_MAX do
        dsaverole:AddChoice(ROLE_STRINGS[r], r)
    end

    local dradiopadding = 3

    local dradionone = vgui.Create("DCheckBoxLabel", dweapons)
    dradionone:SetPos(dlistw + m, dih + dsearchheight + dradiopadding)
    dradionone:SetText(GetTranslation("rolepacks_use_default"))
    dradionone:SetTooltip(GetTranslation("roleweapons_option_none_tooltip"))
    dradionone:SizeToContents()
    dradionone:SetValue(true)
    dradionone:SetTextColor(COLOR_WHITE)
    dradionone:SetEnabled(false)

    local dradiol, dradiot = dradionone:GetPos()
    local _, dradioh = dradionone:GetSize()

    local dradioinclude = vgui.Create("DCheckBoxLabel", dweapons)
    dradioinclude:SetPos(dradiol, dradiot + dradioh + dradiopadding)
    dradioinclude:SetText(GetTranslation("roleweapons_option_include"))
    dradioinclude:SetTooltip(GetTranslation("roleweapons_option_include_tooltip"))
    dradioinclude:SizeToContents()
    dradioinclude:SetTextColor(COLOR_WHITE)
    dradioinclude:SetEnabled(false)

    local dradioexclude = vgui.Create("DCheckBoxLabel", dweapons)
    dradioexclude:SetPos(dradiol, dradiot + (dradioh * 2) + (dradiopadding * 2))
    dradioexclude:SetText(GetTranslation("roleweapons_option_exclude"))
    dradioexclude:SetTooltip(GetTranslation("roleweapons_option_exclude_tooltip"))
    dradioexclude:SizeToContents()
    dradioexclude:SetTextColor(COLOR_WHITE)
    dradioexclude:SetEnabled(false)

    local dradionorandom = vgui.Create("DCheckBoxLabel", dweapons)
    dradionorandom:SetPos(w - 30 - bw, dih + dsearchheight + dradiopadding)
    dradionorandom:SetText(GetTranslation("roleweapons_option_norandom"))
    dradionorandom:SetTooltip(GetTranslation("roleweapons_option_norandom_tooltip"))
    dradionorandom:SizeToContents()
    dradionorandom:SetTextColor(COLOR_WHITE)
    dradionorandom:SetEnabled(false)

    local dradioloadout = vgui.Create("DCheckBoxLabel", dweapons)
    dradioloadout:SetPos(w - 30 - bw, dih + dsearchheight + dradioh + (dradiopadding * 2))
    dradioloadout:SetText(GetTranslation("roleweapons_option_loadout"))
    dradioloadout:SetTooltip(GetTranslation("roleweapons_option_loadout_tooltip"))
    dradioloadout:SizeToContents()
    dradioloadout:SetTextColor(COLOR_WHITE)
    dradioloadout:SetEnabled(false)

    local function UpdateButtonState()
        local valid = role > ROLE_NONE and save_role > ROLE_NONE
        if valid and not dradionone:GetChecked() and not dradioinclude:GetChecked() and not dradioexclude:GetChecked() and not dradionorandom:GetChecked() and not dradioloadout:GetChecked() then
            valid = false
        end

        dradionone:SetEnabled(valid)
        dradioinclude:SetEnabled(valid)
        dradioexclude:SetEnabled(valid)
        dradionorandom:SetEnabled(valid)
        dradioloadout:SetEnabled(valid)
    end

    local function UpdateRadioButtonState(item)
        -- Update checkbox state based on tables
        local id
        if ItemIsWeapon(item) then
            id = item.id
        else
            id = item.name
        end

        if weaponChanges.weapons[save_role] and TableHasValue(weaponChanges.weapons[save_role].Buyables, id) then
            dradioinclude:SetValue(true)
        elseif weaponChanges.weapons[save_role] and TableHasValue(weaponChanges.weapons[save_role].Excludes, id) then
            dradioexclude:SetValue(true)
        else
            dradionone:SetValue(true)
        end

        dradionorandom:SetValue(weaponChanges.weapons[save_role] and TableHasValue(weaponChanges.weapons[save_role].NoRandoms, id))
        dradioloadout:SetValue(weaponChanges.weapons[save_role] and TableHasValue(weaponChanges.weapons[save_role].Loadouts, id))
    end

    local function CacheWeaponChange()
        if save_role < 0 or save_role > ROLE_MAX then return end
        local pnl = dlist.SelectedPanel
        if not pnl or not pnl.item then return end
        local choice = pnl.item

        local id
        if ItemIsWeapon(choice) then
            id = choice.id
        else
            id = choice.name
        end

        if not weaponChanges.weapons[save_role] then
            weaponChanges.weapons[save_role] = {Buyables = {}, Excludes = {}, NoRandoms = {}, Loadouts = {}}
        end

        if dradioinclude:GetChecked() then
            if not TableHasValue(weaponChanges.weapons[save_role].Buyables, id) then
                TableInsert(weaponChanges.weapons[save_role].Buyables, id)
            end
        else
            TableRemoveByValue(weaponChanges.weapons[save_role].Buyables, id)
        end

        if dradioexclude:GetChecked() then
            if not TableHasValue(weaponChanges.weapons[save_role].Excludes, id) then
                TableInsert(weaponChanges.weapons[save_role].Excludes, id)
            end
        else
            TableRemoveByValue(weaponChanges.weapons[save_role].Excludes, id)
        end

        if dradionorandom:GetChecked() then
            if not TableHasValue(weaponChanges.weapons[save_role].NoRandoms, id) then
                TableInsert(weaponChanges.weapons[save_role].NoRandoms, id)
            end
        else
            TableRemoveByValue(weaponChanges.weapons[save_role].NoRandoms, id)
        end

        if dradioloadout:GetChecked() then
            if not TableHasValue(weaponChanges.weapons[save_role].Loadouts, id) then
                TableInsert(weaponChanges.weapons[save_role].Loadouts, id)
            end
        else
            TableRemoveByValue(weaponChanges.weapons[save_role].Loadouts, id)
        end
    end

    dradionone.OnChange = function(pnl, val)
        if val then
            dradioinclude:SetValue(false)
            dradioexclude:SetValue(false)
            UpdateButtonState()
        end
    end
    dradioinclude.OnChange = function(pnl, val)
        if val then
            dradionone:SetValue(false)
            dradioexclude:SetValue(false)
            UpdateButtonState()
        end
    end
    dradioexclude.OnChange = function(pnl, val)
        if val then
            dradionone:SetValue(false)
            dradioinclude:SetValue(false)
            -- You can't have "no random" a weapon that is excluded
            dradionorandom:SetValue(false)
            UpdateButtonState()
        end
    end
    dradionorandom.OnChange = function(pnl, val)
        if val then
            UpdateButtonState()
        end
    end
    dradioloadout.OnChange = function(pnl, val)
        if val then
            UpdateButtonState()
        end
    end

    -- couple panelselect with info
    dlist.OnActivePanelChanged = function(pnl, _, new)
        local valid = new and new.item
        if valid then
            for k, v in pairs(new.item) do
                if dfields[k] then
                    local value = v
                    if type(v) == "function" then
                        value = v()
                    end
                    dfields[k]:SetText(SafeTranslate(value))
                    dfields[k]:SetAutoStretchVertical(true)
                    dfields[k]:SetWrap(true)
                end
            end

            -- Trying to force everything to update to
            -- the right size is a giant pain, so just
            -- force a good size.
            dfields.desc:SetTall(70)
            timer.Simple(0, function() UpdateRadioButtonState(new.item) end) -- Thanks to The Stig for this trick. 0 second timer forces this to happen after everything else
        else
            for _, v in pairs(dfields) do
                if v then
                    v:SetText("---")
                    v:SetAutoStretchVertical(true)
                    v:SetWrap(true)
                end
            end
        end

        UpdateButtonState()
    end

    local function RefreshEquipmentList()
        if role <= ROLE_NONE then
            dlist:Clear()
            dlist.OnActivePanelChanged(dlist, nil, false)
        else
            local searchText = dsearch:GetValue()
            if #searchText then
                dsearch.OnValueChange(dsearch, searchText)
            else
                FillEquipmentList(GetEquipmentForRole(role, false, true, true, true, weaponChanges.weapons[role] or false))
            end
        end
    end

    dsearchrole.OnSelect = function(pnl, index, label, data)
        role = data
        RefreshEquipmentList()
    end

    dsaverole.OnSelect = function(pnl, index, label, data)
        save_role = data
        UpdateButtonState()
        RefreshEquipmentList()

        local new = dlist.SelectedPanel
        if not new or not new.item then return end
        UpdateRadioButtonState(new.item)
    end

    if role > ROLE_NONE then
        FillEquipmentList(GetEquipmentForRole(role, false, true, true, true, weaponChanges.weapons[role] or false))
    end

    local function ReadRolePackWeaponTables(name)
        local roleBits = util.RoleBits()
        for r = ROLE_INNOCENT, ROLE_MAX do
            net.Start("TTT_RequestRolePackWeapons")
                net.WriteString(name)
                net.WriteUInt(r, roleBits)
            net.SendToServer()
        end
    end

    local function UpdateRolePackWeaponUI(jsonTable, roleByte)
        weaponChanges.weapons[roleByte] = jsonTable
        -- This was added after the other three, so make sure it exists on load
        if not weaponChanges.weapons[roleByte].Loadouts then
            weaponChanges.weapons[roleByte].Loadouts = {}
        end
        oldWeaponChanges = TableCopy(weaponChanges)
        if roleByte == role then
            LocalPlayer():ConCommand("ttt_reset_weapons_cache")
            timer.Simple(0.25, function()
                dsearch.OnValueChange(dsearch, dsearch:GetText())
            end)
        end
    end
    ReceiveStreamFromServer("TTT_ReadRolePackWeapons", UpdateRolePackWeaponUI)

    if not packName or #packName == 0 then
        dsearch:SetEnabled(false)
        dsearchrole:SetEnabled(false)
        dsaverole:SetEnabled(false)
    else
        weaponChanges.name = packName
        ReadRolePackWeaponTables(packName)
    end

    local function WeaponTablesMatch(tbl1, tbl2)
        -- If both tables are missing, they essentially match
        if not tbl1 and not tbl2 then return true end
        -- If only one is missing then they don't match
        if not tbl1 or not tbl2 then return false end
        if #tbl1 ~= #tbl2 then return false end

        local t1 = TableCopy(tbl1)
        local t2 = TableCopy(tbl2)
        TableSort(t1)
        TableSort(t2)

        for k, v1 in pairs(t1) do
            local v2 = t2[k]
            if v1 ~= v2 then return false end
        end

        return true
    end

    dweapons.HasUnsavedChanges = function()
        if dweapons.unsavedChanges then
            return true
        end

        for r = 0, ROLE_MAX do
            if weaponChanges.weapons[r] then
                if not oldWeaponChanges.weapons[r] then return true end
                if not WeaponTablesMatch(weaponChanges.weapons[r].Buyables, oldWeaponChanges.weapons[r].Buyables) then return true end
                if not WeaponTablesMatch(weaponChanges.weapons[r].Excludes, oldWeaponChanges.weapons[r].Excludes) then return true end
                if not WeaponTablesMatch(weaponChanges.weapons[r].NoRandoms, oldWeaponChanges.weapons[r].NoRandoms) then return true end
                if not WeaponTablesMatch(weaponChanges.weapons[r].Loadouts, oldWeaponChanges.weapons[r].Loadouts) then return true end
            end
        end
        return false
    end

    dweapons.Save = function(name)
        CacheWeaponChange()
        if dweapons.HasUnsavedChanges() then
            packName = name or packName
            weaponChanges.name = packName
            SendStreamToServer(weaponChanges, "TTT_WriteRolePackWeapons")
            if role == save_role then
                LocalPlayer():ConCommand("ttt_reset_weapons_cache")
                timer.Simple(0.25, function()
                    if not IsValid(dsearch) then return end
                    dsearch.OnValueChange(dsearch, dsearch:GetText())
                end)
            end
            oldWeaponChanges = TableCopy(weaponChanges)
        end
    end

    if tab then
        tab:SetPanel(dweapons)
        local properySheetPadding = tab:GetPropertySheet():GetPadding()
        dweapons:SetPos(properySheetPadding, 20 + properySheetPadding) -- From PANEL:AddSheet
    else
        local tabTable = dsheet:AddSheet(GetTranslation("rolepacks_weapon_tabtitle"), dweapons, "icon16/bomb.png", false, false, GetTranslation("rolepacks_weapon_tabtitle_tooltip"))
        tab = tabTable.Tab
    end

    return dweapons, tab
end

local function BuildConVarConfig(dsheet, packName, tab)
    local dconvars = vgui.Create("DScrollPanel", dsheet)
    dconvars:SetPaintBackground(false)
    dconvars:StretchToParent(0, 0, 0, 0)
    dconvars.unsavedChanges = false

    local dtextentry = vgui.Create("DTextEntry", dconvars)
    dtextentry:SetMultiline(true)
    local _, texth = dconvars:GetSize()
    dtextentry:Dock(FILL)
    dtextentry:SetHeight(texth - 36) -- For some reason filling the text entry to the size of its parent makes it too big, thus the magic number
    dtextentry:SetPlaceholderText("One ConVar per line")
    dtextentry.OnTextChanged = function()
        dconvars.unsavedChanges = true
    end

    local function ReadRolePackConvarTable(name)
        net.Start("TTT_RequestRolePackConvars")
            net.WriteString(name)
        net.SendToServer()
    end

    local function UpdateRolePackConvarUI(jsonTable)
        local text = ""
        if jsonTable.convars then
            for _, line in pairs(jsonTable.convars) do
                if #text > 0 then
                    text = text .. '\n'
                end
                if line.cvar then
                    if line.invalid then
                        text = text .. "#INVALID# "
                    end
                    text = text .. line.cvar
                    if line.value then
                        text = text .. " \"" .. line.value .. "\""
                    end
                elseif line.comment then
                    text = text .. line.comment
                end
            end
        end
        dtextentry:SetValue(text)
    end
    ReceiveStreamFromServer("TTT_ReadRolePackConvars", UpdateRolePackConvarUI)

    if not packName or #packName == 0 then
        dtextentry:SetEnabled(false)
    else
        ReadRolePackConvarTable(packName)
    end

    dconvars.HasUnsavedChanges = function()
        return dconvars.unsavedChanges
    end

    dconvars.Save = function(name)
        if dconvars.HasUnsavedChanges() then
            packName = name or packName
            local text = dtextentry:GetValue()
            local lines = string.Split(text, '\n')
            if #lines <= 0 then return end
            local convarTable = {name = packName, convars = {}}
            for _, line in ipairs(lines) do
                if #line == 0 then
                    TableInsert(convarTable.convars, {cvar = false, newline = true})
                else
                    line = string.gsub(line, "#INVALID# ", "")
                    line = string.TrimLeft(line)
                    if string.sub(line, 1, 2) == "//" then
                        TableInsert(convarTable.convars, {cvar = false, comment = line})
                    else
                        local spacePos = string.find(line, ' ')
                        if spacePos then
                            local cvar = string.sub(line, 1, spacePos - 1)
                            local value = string.sub(line, spacePos + 1)
                            value = string.gsub(value, '"', '')
                            value = string.Trim(value)
                            TableInsert(convarTable.convars, {cvar = cvar, value = value, invalid = false})
                        else
                            TableInsert(convarTable.convars, {cvar = line, value = false, invalid = true})
                        end
                    end
                end
            end
            SendStreamToServer(convarTable, "TTT_WriteRolePackConvars")
            dconvars.unsavedChanges = false
        end
    end

    if tab then
        tab:SetPanel(dconvars)
        local properySheetPadding = tab:GetPropertySheet():GetPadding()
        dconvars:SetPos(properySheetPadding, 20 + properySheetPadding) -- From PANEL:AddSheet
    else
        local tabTable = dsheet:AddSheet(GetTranslation("rolepacks_convar_tabtitle"), dconvars, "icon16/application_xp_terminal.png", false, false, GetTranslation("rolepacks_convar_tabtitle_tooltip"))
        tab = tabTable.Tab
    end

    return dconvars, tab
end

local function OpenDialog()
    local dframe = vgui.Create("DFrame")
    dframe:SetSize(w, h)
    dframe:Center()
    dframe:SetTitle(GetTranslation("rolepacks_title"))
    dframe:SetVisible(true)
    dframe:ShowCloseButton(true)
    dframe:SetMouseInputEnabled(true)
    dframe:SetDeleteOnClose(true)

    local dsheet = vgui.Create("DPropertySheet", dframe)
    dsheet:SetPos(0, 0)
    dsheet:StretchToParent(m, 2 * m + 47, m, m)

    local titleBarHeight = 25
    local iconButtonSize = 22
    local buttonWidth = 64
    local popupWidth = 300
    local popupHeight = 60

    local droles, drolestab = BuildRoleConfig(dsheet, "")
    local droleblocks, droleblockstab = BuildRoleBlockConfig(dsheet, "")
    local dweapons, dweaponstab = BuildWeaponConfig(dsheet, "")
    local dconvars, dconvarstab = BuildConVarConfig(dsheet, "")

    local dpack = vgui.Create("DComboBox", dframe)
    dpack:SetPos(m, titleBarHeight + m)
    dpack:StretchToParent(m, nil, m + 9 * (m + iconButtonSize), nil)
    dpack.OnSelect = function(_, _, name)
        droles:Remove()
        droleblocks:Remove()
        dweapons:Remove()
        dconvars:Remove()
        droles = BuildRoleConfig(dsheet, name, drolestab)
        droleblocks = BuildRoleBlockConfig(dsheet, name, droleblockstab)
        dweapons = BuildWeaponConfig(dsheet, name, dweaponstab)
        dconvars = BuildConVarConfig(dsheet, name, dconvarstab)
    end

    local function Save(name)
        if not name then
            local pack, _ = dpack:GetSelected()
            name = pack
        end

        droles.Save(name)
        droleblocks.Save(name)
        dweapons.Save(name)
        dconvars.Save(name)

        net.Start("TTT_SavedRolePack")
            net.WriteString(name)
        net.SendToServer()
    end

    local oldChooseOption = dpack.ChooseOption
    dpack.ChooseOption = function(self, value, index)
        local pack, _ = dpack:GetSelected()
        if pack == value then return end
        if not pack or #pack == 0 or (not droles.HasUnsavedChanges() and not droleblocks.HasUnsavedChanges() and not dweapons.HasUnsavedChanges() and not dconvars.HasUnsavedChanges()) then
            oldChooseOption(self, value, index)
            return
        end

        dframe:SetMouseInputEnabled(false)

        local dsavedialog = vgui.Create("DFrame")
        dsavedialog:SetSize(popupWidth, popupHeight)
        dsavedialog:Center()
        dsavedialog:SetTitle(GetTranslation("rolepacks_save_title"))
        dsavedialog:SetVisible(true)
        dsavedialog:ShowCloseButton(false)
        dsavedialog:SetMouseInputEnabled(true)
        dsavedialog:SetDeleteOnClose(true)
        dsavedialog.OnClose = function()
            dframe:SetMouseInputEnabled(true)
        end

        local dyes = vgui.Create("DButton", dsavedialog)
        dyes:SetText(GetTranslation("dialog_yes"))
        dyes:SetPos(popupWidth / 2 - buttonWidth - m, titleBarHeight + m)
        dyes.DoClick = function()
            Save()
            dsavedialog:Close()
            oldChooseOption(self, value, index)
        end

        local dno = vgui.Create("DButton", dsavedialog)
        dno:SetText(GetTranslation("dialog_no"))
        dno:SetPos(popupWidth / 2 + m, titleBarHeight + m)
        dno.DoClick = function()
            dsavedialog:Close()
            oldChooseOption(self, value, index)
        end

        dsavedialog:MakePopup()
    end

    local oldClose = dframe.Close
    dframe.Close = function(self)
        local pack, _ = dpack:GetSelected()
        if not pack or #pack == 0 or (not droles.HasUnsavedChanges() and not droleblocks.HasUnsavedChanges() and not dweapons.HasUnsavedChanges() and not dconvars.HasUnsavedChanges()) then
            oldClose(self)
            return
        end

        dframe:SetMouseInputEnabled(false)

        local dsavedialog = vgui.Create("DFrame")
        dsavedialog:SetSize(popupWidth, popupHeight)
        dsavedialog:Center()
        dsavedialog:SetTitle(GetTranslation("rolepacks_save_title"))
        dsavedialog:SetVisible(true)
        dsavedialog:ShowCloseButton(false)
        dsavedialog:SetMouseInputEnabled(true)
        dsavedialog:SetDeleteOnClose(true)
        dsavedialog.OnClose = function()
            dframe:SetMouseInputEnabled(true)
        end

        local dyes = vgui.Create("DButton", dsavedialog)
        dyes:SetText(GetTranslation("dialog_yes"))
        dyes:SetPos(popupWidth / 2 - buttonWidth - m, titleBarHeight + m)
        dyes.DoClick = function()
            Save()
            dsavedialog:Close()
            oldClose(self)
        end

        local dno = vgui.Create("DButton", dsavedialog)
        dno:SetText(GetTranslation("dialog_no"))
        dno:SetPos(popupWidth / 2 + m, titleBarHeight + m)
        dno.DoClick = function()
            dsavedialog:Close()
            oldClose(self)
        end

        dsavedialog:MakePopup()
    end

    net.Start("TTT_RequestRolePackList")
    net.SendToServer()

    net.Receive("TTT_SendRolePackList", function()
        local currentPack = GetConVar("ttt_role_pack"):GetString()
        local length = net.ReadUInt(8)
        for _ = 1, length do
            local packName = net.ReadString()
            packDetails[packName] = net.ReadTable(false)

            local index = dpack:AddChoice(packName)
            if packName == currentPack then
                dpack:ChooseOption(packName, index)
            end
        end
    end)

    local dclearbutton = vgui.Create("DButton", dframe)
    dclearbutton:SetSize(iconButtonSize, iconButtonSize)
    dclearbutton:SetPos(w - (m + iconButtonSize), titleBarHeight + m)
    dclearbutton:SetText("")
    dclearbutton:SetIcon("icon16/server_delete.png")
    dclearbutton:SetTooltip(GetTranslation("rolepacks_clear"))
    dclearbutton.DoClick = function()
        net.Start("TTT_ClearRolePack")
        net.SendToServer()
        LocalPlayer():PrintMessage(HUD_PRINTTALK, "Disabling active role packs...")
    end

    local dapplybutton = vgui.Create("DButton", dframe)
    dapplybutton:SetSize(iconButtonSize, iconButtonSize)
    dapplybutton:SetPos(w - 2 * (m + iconButtonSize), titleBarHeight + m)
    dapplybutton:SetText("")
    dapplybutton:SetIcon("icon16/server_go.png")
    dapplybutton:SetTooltip(GetTranslation("rolepacks_apply"))
    dapplybutton.DoClick = function()
        local pack, _ = dpack:GetSelected()
        if not pack or #pack == 0 then return end
        net.Start("TTT_ApplyRolePack")
            net.WriteString(pack)
        net.SendToServer()
        LocalPlayer():PrintMessage(HUD_PRINTTALK, "Enabling " .. pack .. " role pack...")
    end

    local dtestbutton = vgui.Create("DButton", dframe)
    dtestbutton:SetSize(iconButtonSize, iconButtonSize)
    dtestbutton:SetPos(w - 3 * (m + iconButtonSize), titleBarHeight + m)
    dtestbutton:SetText("")
    dtestbutton:SetIcon("icon16/user_go.png")
    dtestbutton:SetTooltip(GetTranslation("rolepacks_test"))
    dtestbutton.DoClick = function()
        local pack, _ = dpack:GetSelected()
        if not pack or #pack == 0 then return end
        net.Start("TTT_TestRolePack")
            net.WriteString(pack)
        net.SendToServer()
        LocalPlayer():PrintMessage(HUD_PRINTTALK, "Enabling and testing " .. pack .. " role pack...")
    end

    local dsaveasbutton = vgui.Create("DButton", dframe)
    dsaveasbutton:SetSize(iconButtonSize, iconButtonSize)
    dsaveasbutton:SetPos(w - 4 * (m + iconButtonSize), titleBarHeight + m)
    dsaveasbutton:SetText("")
    dsaveasbutton:SetIcon("icon16/page_copy.png")
    dsaveasbutton:SetTooltip(GetTranslation("rolepacks_saveas"))
    dsaveasbutton.DoClick = function()
        local pack, _ = dpack:GetSelected()
        if not pack or #pack == 0 then return end

        dframe:SetMouseInputEnabled(false)

        local dsaveasdialog = vgui.Create("DFrame")
        dsaveasdialog:SetSize(popupWidth, popupHeight)
        dsaveasdialog:Center()
        dsaveasdialog:SetTitle(GetParamTranslation("rolepacks_saveas_title", { name = pack }))
        dsaveasdialog:SetVisible(true)
        dsaveasdialog:ShowCloseButton(true)
        dsaveasdialog:SetMouseInputEnabled(true)
        dsaveasdialog:SetDeleteOnClose(true)
        dsaveasdialog.OnClose = function()
            dframe:SetMouseInputEnabled(true)
        end

        local dsaveasentry = vgui.Create("DTextEntry", dsaveasdialog)
        dsaveasentry:SetPos(m, titleBarHeight + m)
        dsaveasentry:SetWidth(popupWidth - 3 * m - buttonWidth)

        local dsaveas = vgui.Create("DButton", dsaveasdialog)
        dsaveas:SetText(GetTranslation("rolepacks_saveas"))
        dsaveas:SetPos(popupWidth - m - buttonWidth, titleBarHeight + m)
        dsaveas.DoClick = function()
            local newpack = StringLower(dsaveasentry:GetValue())
            if not newpack or #newpack == 0 then return end

            local function SaveAs()
                net.Start("TTT_CreateRolePack")
                    net.WriteString(newpack)
                net.SendToServer()

                -- Cheese the save logic and use a name override to duplicate all tabs
                droles.unsavedChanges = true
                droleblocks.unsavedChanges = true
                dweapons.unsavedChanges = true
                dconvars.unsavedChanges = true
                packDetails[newpack] = packDetails[pack]
                Save(newpack)
                droles.unsavedChanges = false
                droleblocks.unsavedChanges = false
                dweapons.unsavedChanges = false
                dconvars.unsavedChanges = false

                local index = dpack:AddChoice(newpack)
                dpack:ChooseOption(newpack, index)

                dsaveasdialog:Close()
            end

            if IsNameUsed(newpack, dpack) then
                dsaveasdialog:SetMouseInputEnabled(false)

                local dconfirmdialog = vgui.Create("DFrame")
                dconfirmdialog:SetSize(popupWidth, popupHeight)
                dconfirmdialog:Center()
                dconfirmdialog:SetTitle(GetParamTranslation("rolepacks_saveas_override_title", { name = newpack }))
                dconfirmdialog:SetVisible(true)
                dconfirmdialog:ShowCloseButton(false)
                dconfirmdialog:SetMouseInputEnabled(true)
                dconfirmdialog:SetDeleteOnClose(true)
                dconfirmdialog.OnClose = function()
                    dsaveasdialog:SetMouseInputEnabled(true)
                end

                local dyes = vgui.Create("DButton", dconfirmdialog)
                dyes:SetText(GetTranslation("dialog_yes"))
                dyes:SetPos(popupWidth / 2 - buttonWidth - m, titleBarHeight + m)
                dyes.DoClick = function()
                    SaveAs()
                    dconfirmdialog:Close()
                end

                local dno = vgui.Create("DButton", dconfirmdialog)
                dno:SetText(GetTranslation("dialog_no"))
                dno:SetPos(popupWidth / 2 + m, titleBarHeight + m)
                dno.DoClick = function()
                    dconfirmdialog:Close()
                end

                dconfirmdialog:MakePopup()
                return
            end

            if not IsNameValid(newpack, dpack, true) then return end

            SaveAs()
        end

        dsaveasdialog:MakePopup()
    end

    local dsavebutton = vgui.Create("DButton", dframe)
    dsavebutton:SetSize(iconButtonSize, iconButtonSize)
    dsavebutton:SetPos(w - 5 * (m + iconButtonSize), titleBarHeight + m)
    dsavebutton:SetText("")
    dsavebutton:SetIcon("icon16/disk.png")
    dsavebutton:SetTooltip(GetTranslation("rolepacks_save"))
    dsavebutton.DoClick = function()
        local pack, _ = dpack:GetSelected()
        if not pack or #pack == 0 then return end
        Save()
    end

    local ddeletebutton = vgui.Create("DButton", dframe)
    ddeletebutton:SetSize(iconButtonSize, iconButtonSize)
    ddeletebutton:SetPos(w - 6 * (m + iconButtonSize), titleBarHeight + m)
    ddeletebutton:SetText("")
    ddeletebutton:SetIcon("icon16/delete.png")
    ddeletebutton:SetTooltip(GetTranslation("rolepacks_delete"))
    ddeletebutton.DoClick = function()
        local pack, _ = dpack:GetSelected()
        if not pack or #pack == 0 then return end

        dframe:SetMouseInputEnabled(false)

        local dconfirmdialog = vgui.Create("DFrame")
        dconfirmdialog:SetSize(popupWidth, popupHeight)
        dconfirmdialog:Center()
        dconfirmdialog:SetTitle(GetParamTranslation("rolepacks_delete_title", { name = pack }))
        dconfirmdialog:SetVisible(true)
        dconfirmdialog:ShowCloseButton(false)
        dconfirmdialog:SetMouseInputEnabled(true)
        dconfirmdialog:SetDeleteOnClose(true)
        dconfirmdialog.OnClose = function()
            dframe:SetMouseInputEnabled(true)
        end

        local dyes = vgui.Create("DButton", dconfirmdialog)
        dyes:SetText(GetTranslation("dialog_yes"))
        dyes:SetPos(popupWidth / 2 - buttonWidth - m, titleBarHeight + m)
        dyes.DoClick = function()
            dpack:Clear()
            net.Start("TTT_DeleteRolePack")
                net.WriteString(pack)
            net.SendToServer()
            droles:Remove()
            droleblocks:Remove()
            dweapons:Remove()
            dconvars:Remove()
            dconfirmdialog:Close()
            droles = BuildRoleConfig(dsheet, "", drolestab)
            droleblocks = BuildRoleConfig(dsheet, "", droleblockstab)
            dweapons = BuildWeaponConfig(dsheet, "", dweaponstab)
            dconvars = BuildConVarConfig(dsheet, "", dconvarstab)
        end

        local dno = vgui.Create("DButton", dconfirmdialog)
        dno:SetText(GetTranslation("dialog_no"))
        dno:SetPos(popupWidth / 2 + m, titleBarHeight + m)
        dno.DoClick = function()
            dconfirmdialog:Close()
        end

        dconfirmdialog:MakePopup()
    end

    local ddetailsbutton = vgui.Create("DButton", dframe)
    ddetailsbutton:SetSize(iconButtonSize, iconButtonSize)
    ddetailsbutton:SetPos(w - 7 * (m + iconButtonSize), titleBarHeight + m)
    ddetailsbutton:SetText("")
    ddetailsbutton:SetIcon("icon16/database_edit.png")
    ddetailsbutton:SetTooltip(GetTranslation("rolepacks_details"))
    ddetailsbutton.DoClick = function()
        local pack, _ = dpack:GetSelected()
        if not pack or #pack == 0 then return end

        -- Make sure the table exists before we try to use it
        if not packDetails[pack] then
            packDetails[pack] = {}
        end

        dframe:SetMouseInputEnabled(false)

        local lineHeight = 20
        local ddetailsdialog = vgui.Create("DFrame")
        ddetailsdialog:SetSize(popupWidth, titleBarHeight + (lineHeight * 5) + (m * 5) + (m * 2))
        ddetailsdialog:Center()
        ddetailsdialog:SetTitle(GetParamTranslation("rolepacks_details_title", { name = pack }))
        ddetailsdialog:SetVisible(true)
        ddetailsdialog:ShowCloseButton(true)
        ddetailsdialog:SetMouseInputEnabled(true)
        ddetailsdialog:SetDeleteOnClose(true)
        ddetailsdialog.OnClose = function()
            dframe:SetMouseInputEnabled(true)
        end

        local ddisplaynamelabel = vgui.Create("DLabel", ddetailsdialog)
        ddisplaynamelabel:SetFont("TabLarge")
        ddisplaynamelabel:SetContentAlignment(7)
        ddisplaynamelabel:SetPos(m + 2, titleBarHeight + m)
        ddisplaynamelabel:SetWidth(popupWidth - (m * 2))
        ddisplaynamelabel:SetText(GetTranslation("rolepacks_displayname"))

        local ddisplaynameentry = vgui.Create("DTextEntry", ddetailsdialog)
        ddisplaynameentry:SetPos(m, titleBarHeight + m + lineHeight)
        ddisplaynameentry:SetWidth(popupWidth - (m * 2))
        ddisplaynameentry:SetText(packDetails[pack].displayName or "")

        local ddescriptionlabel = vgui.Create("DLabel", ddetailsdialog)
        ddescriptionlabel:SetFont("TabLarge")
        ddescriptionlabel:SetContentAlignment(7)
        ddescriptionlabel:SetPos(m + 2, titleBarHeight + (m * 3) + (lineHeight * 2))
        ddescriptionlabel:SetWidth(popupWidth - (m * 2))
        ddescriptionlabel:SetText(GetTranslation("rolepacks_description"))

        local ddescriptionentry = vgui.Create("DTextEntry", ddetailsdialog)
        ddescriptionentry:SetPos(m, titleBarHeight + (m * 3) + (lineHeight * 3))
        ddescriptionentry:SetWidth(popupWidth - (m * 2))
        ddescriptionentry:SetText(packDetails[pack].description or "")

        local dconfirm = vgui.Create("DButton", ddetailsdialog)
        dconfirm:SetText(GetTranslation("rolepacks_confirm"))
        dconfirm:SetPos(m, titleBarHeight + (m * 5) + (lineHeight * 4))
        dconfirm.DoClick = function()
            packDetails[pack].displayName = ddisplaynameentry:GetValue()
            packDetails[pack].description = ddescriptionentry:GetValue()
            droles.unsavedChanges = true
            ddetailsdialog:Close()
        end

        ddetailsdialog:MakePopup()
    end

    local drenamebutton = vgui.Create("DButton", dframe)
    drenamebutton:SetSize(iconButtonSize, iconButtonSize)
    drenamebutton:SetPos(w - 8 * (m + iconButtonSize), titleBarHeight + m)
    drenamebutton:SetText("")
    drenamebutton:SetIcon("icon16/page_edit.png")
    drenamebutton:SetTooltip(GetTranslation("rolepacks_rename"))
    drenamebutton.DoClick = function()
        local pack, _ = dpack:GetSelected()
        if not pack or #pack == 0 then return end

        dframe:SetMouseInputEnabled(false)

        local drenamedialog = vgui.Create("DFrame")
        drenamedialog:SetSize(popupWidth, popupHeight)
        drenamedialog:Center()
        drenamedialog:SetTitle(GetParamTranslation("rolepacks_rename_title", { name = pack }))
        drenamedialog:SetVisible(true)
        drenamedialog:ShowCloseButton(true)
        drenamedialog:SetMouseInputEnabled(true)
        drenamedialog:SetDeleteOnClose(true)
        drenamedialog.OnClose = function()
            dframe:SetMouseInputEnabled(true)
        end

        local drenameentry = vgui.Create("DTextEntry", drenamedialog)
        drenameentry:SetPos(m, titleBarHeight + m)
        drenameentry:SetWidth(popupWidth - 3 * m - buttonWidth)
        drenameentry:SetText(pack)

        local drename = vgui.Create("DButton", drenamedialog)
        drename:SetText(GetTranslation("rolepacks_rename"))
        drename:SetPos(popupWidth - m - buttonWidth, titleBarHeight + m)
        drename.DoClick = function()
            local newpack = StringLower(drenameentry:GetValue())
            if not newpack or #newpack == 0 then return end
            if not IsNameValid(newpack, dpack) then return end
            dpack:Clear()
            net.Start("TTT_RenameRolePack")
                net.WriteString(pack)
                net.WriteString(newpack)
            net.SendToServer()
            droles:Remove()
            droleblocks:Remove()
            dweapons:Remove()
            dconvars:Remove()
            drenamedialog:Close()
            droles = BuildRoleConfig(dsheet, "", drolestab)
            droleblocks = BuildRoleConfig(dsheet, "", droleblockstab)
            dweapons = BuildWeaponConfig(dsheet, "", dweaponstab)
            dconvars = BuildConVarConfig(dsheet, "", dconvarstab)
        end

        drenamedialog:MakePopup()
    end

    local dnewbutton = vgui.Create("DButton", dframe)
    dnewbutton:SetSize(iconButtonSize, iconButtonSize)
    dnewbutton:SetPos(w - 9 * (m + iconButtonSize), titleBarHeight + m)
    dnewbutton:SetText("")
    dnewbutton:SetIcon("icon16/add.png")
    dnewbutton:SetTooltip(GetTranslation("rolepacks_add"))
    dnewbutton.DoClick = function()
        dframe:SetMouseInputEnabled(false)

        local dnewdialog = vgui.Create("DFrame")
        dnewdialog:SetSize(popupWidth, popupHeight)
        dnewdialog:Center()
        dnewdialog:SetTitle(GetTranslation("rolepacks_add_title"))
        dnewdialog:SetVisible(true)
        dnewdialog:ShowCloseButton(true)
        dnewdialog:SetMouseInputEnabled(true)
        dnewdialog:SetDeleteOnClose(true)
        dnewdialog.OnClose = function()
            dframe:SetMouseInputEnabled(true)
        end

        local dnewentry = vgui.Create("DTextEntry", dnewdialog)
        dnewentry:SetPos(m, titleBarHeight + m)
        dnewentry:SetWidth(popupWidth - 3 * m - buttonWidth)

        local dconfirm = vgui.Create("DButton", dnewdialog)
        dconfirm:SetText(GetTranslation("rolepacks_confirm"))
        dconfirm:SetPos(popupWidth - m - buttonWidth, titleBarHeight + m)
        dconfirm.DoClick = function()
            local pack = StringLower(dnewentry:GetValue())
            if not pack or #pack == 0 then return end
            if not IsNameValid(pack, dpack) then return end
            local index = dpack:AddChoice(pack)
            dpack:ChooseOption(pack, index)
            net.Start("TTT_CreateRolePack")
                net.WriteString(pack)
            net.SendToServer()
            droles:Remove()
            droleblocks:Remove()
            dweapons:Remove()
            dconvars:Remove()
            dnewdialog:Close()
            droles = BuildRoleConfig(dsheet, pack, drolestab)
            droleblocks = BuildRoleConfig(dsheet, pack, droleblockstab)
            dweapons = BuildWeaponConfig(dsheet, pack, dweaponstab)
            dconvars = BuildConVarConfig(dsheet, pack, dconvarstab)
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
    ROLE_PACK_DETAILS = {}

    local count = net.ReadUInt(8)
    if count <= 0 then return end

    local roleBits = util.RoleBits()
    for _ = 1, count do
        local role = net.ReadUInt(roleBits)
        ROLE_PACK_ROLES[role] = true
    end
    ROLE_PACK_DETAILS = net.ReadTable(false)
end)
