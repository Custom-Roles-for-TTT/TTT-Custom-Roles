local concommand = concommand
local vgui = vgui
local util = util
local net = net
local timer = timer
local pairs = pairs
local table = table
local math = math
local string = string

local GetTranslation = LANG.GetTranslation
local SafeTranslate = LANG.TryTranslation
local TableInsert = table.insert
local TableRemove = table.remove
local TableSort = table.sort
local TableRemoveByValue = table.RemoveByValue
local MathCeil = math.ceil
local StringSub = string.sub
local StringLower = string.lower
local StringFind = string.find

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
            return
        end

        local jsonTable = util.JSONToTable(json)
        if jsonTable == nil then
            ErrorNoHalt("Table decoding failed!\n")
            return
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

local function ItemIsWeapon(item) return not tonumber(item.id) end

local function DoesValueMatch(item, data, value)
    if not item[data] then return false end

    local itemdata = item[data]
    if isfunction(itemdata) then
        itemdata = itemdata()
    end
    return itemdata and StringFind(StringLower(SafeTranslate(itemdata)), StringLower(value), 1, true)
end

local function IsNameValid(name, dpack)
    if string.find(name, '[\\/:%*%?"<>|]') then
        LocalPlayer():PrintMessage(HUD_PRINTTALK, 'Name cannot contain the following characters: \\/:*?"<>|')
        return false
    elseif #name > 30 then
        LocalPlayer():PrintMessage(HUD_PRINTTALK, 'Name cannot be longer than 30 characters')
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

local function BuildRoleConfig(dsheet, packName, tab)
    UpdateRoleColours()

    local slotList = {}

    local droles = vgui.Create("DPanel", dsheet)
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
    dslotlist:StretchToParent(0, 20, 16, 62)

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

            local roleStringShort = ROLE_STRINGS_SHORT[role]
            local material = util.GetRoleIconPath(roleStringShort, "icon", "vtf")

            dicon:SetIconSize(64)
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

    if tab then
        tab:SetPanel(droles)
        local properySheetPadding = tab:GetPropertySheet():GetPadding()
        droles:SetPos(properySheetPadding, 20 + properySheetPadding)
    else
        local tabTable = dsheet:AddSheet(GetTranslation("rolepacks_role_tabtitle"), droles, "icon16/user.png", false, false, GetTranslation("rolepacks_role_tabtitle_tooltip"))
        tab = tabTable.Tab
    end

    return droles, tab
end

local function BuildWeaponConfig(dsheet, packName, tab)
    local dweapons = vgui.Create("DPanel", dsheet)
    dweapons:SetPaintBackground(false)
    dweapons:StretchToParent(0, 0, 0, 0)

    local role = ROLE_NONE
    local save_role = ROLE_NONE

    local dsearchheight = 25
    local dsearchpadding = 5
    local dsearch = vgui.Create("DTextEntry", dweapons)
    dsearch:SetPos(0, 0)
    dsearch:SetSize(dlistw, dsearchheight)
    dsearch:SetPlaceholderText("Search...")
    dsearch:SetUpdateOnType(true)

    local dinfow = diw - m
    local dsearchrole = vgui.Create("DComboBox", dweapons)
    dsearchrole:CopyPos(dsearch)
    dsearchrole:MoveRightOf(dsearch)
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
    dlist:EnableVerticalScrollbar(true)
    dlist:EnableHorizontal(true)

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

    local function FillEquipmentList(itemlist)
        dlist:Clear()

        -- temp table for sorting
        local paneltable = {}
        for i = 0, 9 do
            paneltable[i] = {}
        end

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
                        ic.slot = math.Clamp(ic.slot, 1, #paneltable)
                    end

                    slot:SetIconProperties(COLOR_WHITE,
                            "DefaultBold",
                            { opacity = 220, offset = 1 },
                            { 9, 8 })

                    ic:AddLayer(slot)
                    ic:EnableMousePassthrough(slot)
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
            local externalLoadout = ROLE_LOADOUT_ITEMS[role] and table.HasValue(ROLE_LOADOUT_ITEMS[role], item.name)
            if not ItemIsWeapon(item) and (item.loadout or externalLoadout) then
                ic:Remove()
            else
                TableInsert(paneltable[ic.slot or 1], ic)
            end
        end

        local AddNameSortedItems = function(panels)
            if GetConVar("ttt_sort_alphabetically"):GetBool() then
                TableSort(panels, function(a, b) return StringLower(a.item.name) < StringLower(b.item.name) end)
            end
            for _, panel in pairs(panels) do
                dlist:AddPanel(panel)
            end
        end

        -- Add equipment items separately
        AddNameSortedItems(paneltable[0])

        if GetConVar("ttt_sort_by_slot_first"):GetBool() then
            for i = 1, 9 do
                AddNameSortedItems(paneltable[i])
            end
        else
            -- Gather all the panels into one list
            local panels = {}
            for i = 1, 9 do
                for _, p in pairs(paneltable[i]) do
                    TableInsert(panels, p)
                end
            end

            AddNameSortedItems(panels)
        end

        -- select first
        dlist:SelectPanel(dlist:GetItems()[1])
    end
    dsearch.OnValueChange = function(box, value)
        if role <= ROLE_NONE then return end

        local roleitems = GetEquipmentForRole(role, false, true, true, true)
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
    dsaverole:SetSize(bw, dsearchheight)
    dsaverole:AddChoice(GetTranslation("roleweapons_select_saverole"), ROLE_NONE, true)
    dsaverole:SetTooltip(GetTranslation("roleweapons_select_saverole_tooltip"))
    for r = ROLE_INNOCENT, ROLE_MAX do
        dsaverole:AddChoice(ROLE_STRINGS[r], r)
    end

    local dconfirm = vgui.Create("DButton", dweapons)
    dconfirm:SetPos(w - 30 - bw, dih + dsearchheight + 3)
    dconfirm:SetSize(bw, bh)
    dconfirm:SetDisabled(true)
    dconfirm:SetText(GetTranslation("roleweapons_confirm"))

    local dcancel = vgui.Create("DButton", dweapons)
    dcancel:SetPos(w - 30 - bw, dih + dsearchheight + bh + 6)
    dcancel:SetSize(bw, bh)
    dcancel:SetDisabled(false)
    dcancel:SetText(GetTranslation("close"))
    dcancel.DoClick = function() dframe:Close() end

    local dradiopadding = 3

    local dradionone = vgui.Create("DCheckBoxLabel", dweapons)
    dradionone:SetPos(dlistw + m, dih + dsearchheight + dradiopadding)
    dradionone:SetText(GetTranslation("roleweapons_option_none"))
    dradionone:SetTooltip(GetTranslation("roleweapons_option_none_tooltip"))
    dradionone:SizeToContents()
    dradionone:SetValue(true)
    dradionone:SetTextColor(COLOR_WHITE)
    dradionone:SetDisabled(true)

    local dradiol, dradiot = dradionone:GetPos()
    local _, dradioh = dradionone:GetSize()

    local dradioinclude = vgui.Create("DCheckBoxLabel", dweapons)
    dradioinclude:SetPos(dradiol, dradiot + dradioh + dradiopadding)
    dradioinclude:SetText(GetTranslation("roleweapons_option_include"))
    dradioinclude:SetTooltip(GetTranslation("roleweapons_option_include_tooltip"))
    dradioinclude:SizeToContents()
    dradioinclude:SetTextColor(COLOR_WHITE)
    dradioinclude:SetDisabled(true)

    local dradioexclude = vgui.Create("DCheckBoxLabel", dweapons)
    dradioexclude:SetPos(dradiol, dradiot + (dradioh * 2) + (dradiopadding * 2))
    dradioexclude:SetText(GetTranslation("roleweapons_option_exclude"))
    dradioexclude:SetTooltip(GetTranslation("roleweapons_option_exclude_tooltip"))
    dradioexclude:SizeToContents()
    dradioexclude:SetTextColor(COLOR_WHITE)
    dradioexclude:SetDisabled(true)

    local dradionorandom = vgui.Create("DCheckBoxLabel", dweapons)
    dradionorandom:SetPos(w - 30 - bw, dih + (dradiopadding * 2))
    dradionorandom:SetText(GetTranslation("roleweapons_option_norandom"))
    dradionorandom:SetTooltip(GetTranslation("roleweapons_option_norandom_tooltip"))
    dradionorandom:SizeToContents()
    dradionorandom:SetTextColor(COLOR_WHITE)
    dradionorandom:SetDisabled(true)

    local function UpdateButtonState()
        local valid = role > ROLE_NONE and save_role > ROLE_NONE
        if valid and not dradionone:GetChecked() and not dradioinclude:GetChecked() and not dradioexclude:GetChecked() and not dradionorandom:GetChecked() then
            valid = false
        end

        dconfirm:SetDisabled(not valid)
        dradionone:SetDisabled(not valid)
        dradioinclude:SetDisabled(not valid)
        dradioexclude:SetDisabled(not valid)
        dradionorandom:SetDisabled(not valid)
    end

    local function UpdateRadioButtonState(item)
        -- Update checkbox state based on tables
        if ItemIsWeapon(item) then
            local weap_class = StringLower(item.id)
            if WEPS.BuyableWeapons[save_role] and table.HasValue(WEPS.BuyableWeapons[save_role], weap_class) then
                dradioinclude:SetValue(true)
            elseif WEPS.ExcludeWeapons[save_role] and table.HasValue(WEPS.ExcludeWeapons[save_role], weap_class) then
                dradioexclude:SetValue(true)
            else
                dradionone:SetValue(true)
            end

            dradionorandom:SetValue(WEPS.BypassRandomWeapons[save_role] and table.HasValue(WEPS.BypassRandomWeapons[save_role], weap_class))
        else
            local name = StringLower(item.name)
            if WEPS.BuyableWeapons[save_role] and table.HasValue(WEPS.BuyableWeapons[save_role], name) then
                dradioinclude:SetValue(true)
            elseif WEPS.ExcludeWeapons[save_role] and table.HasValue(WEPS.ExcludeWeapons[save_role], name) then
                dradioexclude:SetValue(true)
            else
                dradionone:SetValue(true)
            end

            dradionorandom:SetValue(WEPS.BypassRandomWeapons[save_role] and table.HasValue(WEPS.BypassRandomWeapons[save_role], name))
        end
    end

    dradionone.OnChange = function(pnl, val)
        if val then
            dradioinclude:SetValue(false)
            dradioexclude:SetValue(false)
            UpdateButtonState()
        else
            dconfirm:SetDisabled(true)
        end
    end
    dradioinclude.OnChange = function(pnl, val)
        if val then
            dradionone:SetValue(false)
            dradioexclude:SetValue(false)
            UpdateButtonState()
        else
            dconfirm:SetDisabled(true)
        end
    end
    dradioexclude.OnChange = function(pnl, val)
        if val then
            dradionone:SetValue(false)
            dradioinclude:SetValue(false)
            -- You can't have "no random" a weapon that is excluded
            dradionorandom:SetValue(false)
            UpdateButtonState()
        else
            dconfirm:SetDisabled(true)
        end
    end
    dradionorandom.OnChange = function(pnl, val)
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
            UpdateRadioButtonState(new.item)
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

    dsearchrole.OnSelect = function(pnl, index, label, data)
        role = data
        if role <= ROLE_NONE then
            dlist:Clear()
            dlist.OnActivePanelChanged(dlist, nil, false)
        else
            local searchText = dsearch:GetValue()
            if #searchText then
                dsearch.OnValueChange(dsearch, searchText)
            else
                FillEquipmentList(GetEquipmentForRole(role, false, true, true, true))
            end
        end
    end

    dsaverole.OnSelect = function(pnl, index, label, data)
        save_role = data
        UpdateButtonState()

        local new = dlist.SelectedPanel
        if not new or not new.item then return end
        UpdateRadioButtonState(new.item)
    end

    dconfirm.DoClick = function()
        local pnl = dlist.SelectedPanel
        if not pnl or not pnl.item then return end
        local choice = pnl.item

        -- Gather selected information
        local includeSelected = dradioinclude:GetChecked()
        local excludeSelected = dradioexclude:GetChecked()
        local noRandomSelected = dradionorandom:GetChecked()

        local id
        if ItemIsWeapon(choice) then
            id = choice.id
        else
            id = choice.name
        end

        -- Send message to server to update tables and files
        net.Start("TTT_ConfigureRolePackWeapons")
        net.WriteString(id)
        net.WriteInt(save_role, 8)
        net.WriteBool(includeSelected)
        net.WriteBool(excludeSelected)
        net.WriteBool(noRandomSelected)
        net.SendToServer()

        -- Update the list if we just updated the role we're already looking at
        if role == save_role then
            LocalPlayer():ConCommand("ttt_reset_weapons_cache")
            timer.Simple(0.25, function()
                dsearch.OnValueChange(dsearch, dsearch:GetText())
            end)
        end
    end

    if role > ROLE_NONE then
        FillEquipmentList(GetEquipmentForRole(role, false, true, true, true))
    end

    if not packName or packName == "" then
        dsearch:SetDisabled(true)
        dsearchrole:SetDisabled(true)
        dsaverole:SetDisabled(true)
        dconfirm:SetDisabled(true)
        dcancel:SetDisabled(true)
    end

    if tab then
        tab:SetPanel(dweapons)
        local properySheetPadding = tab:GetPropertySheet():GetPadding()
        dweapons:SetPos(properySheetPadding, 20 + properySheetPadding)
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

    local dtextentry = vgui.Create("DTextEntry", dconvars)
    dtextentry:SetMultiline(true)
    local _, texth = dconvars:GetSize()
    dtextentry:Dock(FILL)
    dtextentry:SetHeight(texth - 36)

    local dconfirm = vgui.Create("DButton", dconvars)
    dconfirm:SetText("Confirm")
    dconfirm:Dock(BOTTOM)
    dconfirm:DockMargin(0, 4, 0, 0)


    if not packName or packName == "" then
        dtextentry:SetDisabled(true)
        dconfirm:SetDisabled(true)
    end

    if tab then
        tab:SetPanel(dconvars)
        local properySheetPadding = tab:GetPropertySheet():GetPadding()
        dconvars:SetPos(properySheetPadding, 20 + properySheetPadding)
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
    
    local droles, drolestab = BuildRoleConfig(dsheet, "")

    local dweapons, dweaponstab = BuildWeaponConfig(dsheet, "")

    local dconvars, dconvarstab = BuildConVarConfig(dsheet, "")

    local dpack = vgui.Create("DComboBox", dframe)
    dpack:SetPos(m, m + 25)
    dpack:StretchToParent(m, nil, 5 * m + 88, nil)
    dpack.OnSelect = function(_, _, name)
        droles:Remove()
        dweapons:Remove()
        dconvars:Remove()
        droles = BuildRoleConfig(dsheet, name, drolestab)
        dweapons = BuildWeaponConfig(dsheet, name, dweaponstab)
        dconvars = BuildConVarConfig(dsheet, name, dconvarstab)
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
            dweapons:Remove()
            dconvars:Remove()
            dconfirmdialog:Close()
            droles = BuildRoleConfig(dsheet, "", drolestab)
            dweapons = BuildWeaponConfig(dsheet, "", dweaponstab)
            dconvars = BuildConVarConfig(dsheet, "", dconvarstab)
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
            dweapons:Remove()
            dconvars:Remove()
            dnewdialog:Close()
            droles = BuildRoleConfig(dsheet, pack, drolestab)
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

    local count = net.ReadUInt(8)
    if count <= 0 then return end
    for _ = 1, count do
        local role = net.ReadUInt(8)
        ROLE_PACK_ROLES[role] = true
    end
end)