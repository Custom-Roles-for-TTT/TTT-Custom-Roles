local concommand = concommand
local vgui = vgui
local util = util
local net = net
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
    if string.find(name, "[\\/:%*%?\"<>|]") then
        LocalPlayer():PrintMessage(HUD_PRINTTALK, "Name cannot contain the following characters: \\/:*?\"<>|")
        return false
    elseif #name > 30 then
        LocalPlayer():PrintMessage(HUD_PRINTTALK, "Name cannot be longer than 30 characters")
        return false
    else
        for _, v in pairs(dpack.Choices) do
            if name == v then
                LocalPlayer():PrintMessage(HUD_PRINTTALK, "Name cannot be a duplicate of another role pack")
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
    droles.unsavedChanges = false

    local configHeight = 16
    local buttonHeight = 22

    local dconfig = vgui.Create("DPanel", droles)
    dconfig:SetPaintBackground(false)
    dconfig:StretchToParent(0, 0, 0, nil)
    dconfig:SetHeight(configHeight)

    local dallowduplicates = vgui.Create("DCheckBoxLabel", dconfig)
    dallowduplicates:SetText("Allow Duplicate Roles")
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
            label:SetText("Slot " .. index .. ":")
        end
    end

    local function CreateSlot(roleTable)
        local labelHeight = 10
        local iconWidth = 64
        local iconHeight = 84
        local buttonSize = 22

        local dslot = vgui.Create("DPanel", dslotlist)
        dslot:SetPaintBackground(false)
        dslot:SetSize(dslotlist:GetSize(), labelHeight + iconHeight + 2 * m)
        dslot:Dock(TOP)

        local dlabel = vgui.Create("DLabel", dslot)
        dlabel:SetFont("TabLarge")
        dlabel:SetContentAlignment(7)
        dlabel:SetPos(3, 0) -- For some reason the text isn't inline with the icons so we shift it 3px to the right
        TableInsert(slotLabels, dlabel)

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
            dslot:SetSize(dslotlist:GetSize(), labelHeight + iconRows * iconHeight + 2 * m)
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
            droles.unsavedChanges = true
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
            dslot:SetSize(dslotlist:GetSize(), labelHeight + iconRows * iconHeight + 2 * m)
            dlist:SetHeight(iconRows * iconHeight + 2 * m)
            droles.unsavedChanges = true
        end

        local ddeleteslotbutton = vgui.Create("DButton", dbuttons)
        ddeleteslotbutton:SetSize(buttonSize, buttonSize)
        ddeleteslotbutton:SetPos(0, 2 * (buttonSize + m))
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

        dlist:AddPanel(dbuttons)

        dslotlist:AddItem(dslot)
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
        dslotlist:Clear()
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
        daddslotbutton:SetDisabled(true)
        dallowduplicates:SetDisabled(true)
    else
        ReadRolePackRoleTable(packName)
    end

    droles.Save = function()
        if droles.unsavedChanges then
            local slotTable = {name = packName, config = {allowduplicates = dallowduplicates:GetChecked()}, slots = {}}
            for _, slot in pairs(slotList) do
                local roleTable = {}
                for _, role in pairs(slot) do
                    TableInsert(roleTable, {role = ROLE_STRINGS_RAW[role.role], weight = role.weight})
                end
                TableInsert(slotTable.slots, roleTable)
            end
            SendStreamToServer(slotTable, "TTT_WriteRolePackRoles")
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

local function BuildWeaponConfig(dsheet, packName, tab)
    local dweapons = vgui.Create("DPanel", dsheet)
    dweapons:SetPaintBackground(false)
    dweapons:StretchToParent(0, 0, 0, 0)
    dweapons.unsavedChanges = false

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

    local weaponChanges = {name = "", weapons = {}}

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
    dradionorandom:SetPos(w - 30 - bw, dih + dsearchheight + dradiopadding)
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

        dradionone:SetDisabled(not valid)
        dradioinclude:SetDisabled(not valid)
        dradioexclude:SetDisabled(not valid)
        dradionorandom:SetDisabled(not valid)
    end

    local function UpdateRadioButtonState(item)
        -- Update checkbox state based on tables
        if ItemIsWeapon(item) then
            local weap_class = StringLower(item.id)
            if weaponChanges.weapons[save_role] and table.HasValue(weaponChanges.weapons[save_role].Buyables, weap_class) then
                dradioinclude:SetValue(true)
            elseif weaponChanges.weapons[save_role] and table.HasValue(weaponChanges.weapons[save_role].Excludes, weap_class) then
                dradioexclude:SetValue(true)
            else
                dradionone:SetValue(true)
            end

            dradionorandom:SetValue(weaponChanges.weapons[save_role] and table.HasValue(weaponChanges.weapons[save_role].NoRandoms, weap_class))
        else
            local name = StringLower(item.name)
            if weaponChanges.weapons[save_role] and table.HasValue(weaponChanges.weapons[save_role].Buyables, name) then
                dradioinclude:SetValue(true)
            elseif weaponChanges.weapons[save_role] and table.HasValue(weaponChanges.weapons[save_role].Excludes, name) then
                dradioexclude:SetValue(true)
            else
                dradionone:SetValue(true)
            end

            dradionorandom:SetValue(weaponChanges.weapons[save_role] and table.HasValue(weaponChanges.weapons[save_role].NoRandoms, name))
        end
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
            weaponChanges.weapons[save_role] = {Buyables = {}, Excludes = {}, NoRandoms = {}}
        end

        if dradioinclude:GetChecked() then
            TableInsert(weaponChanges.weapons[save_role].Buyables, id)
        else
            TableRemoveByValue(weaponChanges.weapons[save_role].Buyables, id)
        end

        if dradioexclude:GetChecked() then
            TableInsert(weaponChanges.weapons[save_role].Excludes, id)
        else
            TableRemoveByValue(weaponChanges.weapons[save_role].Excludes, id)
        end

        if dradionorandom:GetChecked() then
            TableInsert(weaponChanges.weapons[save_role].NoRandoms, id)
        else
            TableRemoveByValue(weaponChanges.weapons[save_role].NoRandoms, id)
        end

        dweapons.unsavedChanges = true
    end

    dradionone.OnChange = function(pnl, val)
        if val then
            dradioinclude:SetValue(false)
            dradioexclude:SetValue(false)
            UpdateButtonState()
            CacheWeaponChange()
        end
    end
    dradioinclude.OnChange = function(pnl, val)
        if val then
            dradionone:SetValue(false)
            dradioexclude:SetValue(false)
            UpdateButtonState()
            CacheWeaponChange()
        end
    end
    dradioexclude.OnChange = function(pnl, val)
        if val then
            dradionone:SetValue(false)
            dradioinclude:SetValue(false)
            -- You can't have "no random" a weapon that is excluded
            dradionorandom:SetValue(false)
            UpdateButtonState()
            CacheWeaponChange()
        end
    end
    dradionorandom.OnChange = function(pnl, val)
        if val then
            UpdateButtonState()
            CacheWeaponChange()
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
                FillEquipmentList(GetEquipmentForRole(role, false, true, true, true, weaponChanges.weapons[role] or false))
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

    if role > ROLE_NONE then
        FillEquipmentList(GetEquipmentForRole(role, false, true, true, true, weaponChanges.weapons[role] or false))
    end

    local function ReadRolePackWeaponTables(name)
        for r = ROLE_INNOCENT, ROLE_MAX do
            net.Start("TTT_RequestRolePackWeapons")
            net.WriteString(name)
            net.WriteUInt(r, 8)
            net.SendToServer()
        end
    end

    local function UpdateRolePackWeaponUI(jsonTable, roleByte)
        weaponChanges.weapons[roleByte] = jsonTable
        if roleByte == role then
            LocalPlayer():ConCommand("ttt_reset_weapons_cache")
            timer.Simple(0.25, function()
                dsearch.OnValueChange(dsearch, dsearch:GetText())
            end)
        end
    end
    ReceiveStreamFromServer("TTT_ReadRolePackWeapons", UpdateRolePackWeaponUI)

    if not packName or #packName == 0 then
        dsearch:SetDisabled(true)
        dsearchrole:SetDisabled(true)
        dsaverole:SetDisabled(true)
    else
        weaponChanges.name = packName
        ReadRolePackWeaponTables(packName)
    end

    dweapons.Save = function()
        if dweapons.unsavedChanges then
            SendStreamToServer(weaponChanges, "TTT_WriteRolePackWeapons")
            if role == save_role then
                LocalPlayer():ConCommand("ttt_reset_weapons_cache")
                timer.Simple(0.25, function()
                    dsearch.OnValueChange(dsearch, dsearch:GetText())
                end)
            end
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
        dtextentry:SetDisabled(true)
    else
        ReadRolePackConvarTable(packName)
    end

    dconvars.Save = function()
        if dconvars.unsavedChanges then
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

    local dweapons, dweaponstab = BuildWeaponConfig(dsheet, "")

    local dconvars, dconvarstab = BuildConVarConfig(dsheet, "")

    local dpack = vgui.Create("DComboBox", dframe)
    dpack:SetPos(m, titleBarHeight + m)
    dpack:StretchToParent(m, nil, m + 6 * (m + iconButtonSize), nil)
    dpack.OnSelect = function(_, _, name)
        droles:Remove()
        dweapons:Remove()
        dconvars:Remove()
        droles = BuildRoleConfig(dsheet, name, drolestab)
        dweapons = BuildWeaponConfig(dsheet, name, dweaponstab)
        dconvars = BuildConVarConfig(dsheet, name, dconvarstab)
    end

    local function Save()
        droles.Save()
        dweapons.Save()
        dconvars.Save()
        droles.unsavedChanges = false
        dweapons.unsavedChanges = false
        dconvars.unsavedChanges = false
        net.Start("TTT_SaveRolePack")
        local pack, _ = dpack:GetSelected()
        net.WriteString(pack)
        net.SendToServer()
    end

    local oldChooseOption = dpack.ChooseOption
    dpack.ChooseOption = function(self, value, index)
        local pack, _ = dpack:GetSelected()
        if pack == value then return end
        if not pack or #pack == 0 or (not droles.unsavedChanges and not dweapons.unsavedChanges and not dconvars.unsavedChanges) then
            oldChooseOption(self, value, index)
            return
        end

        dframe:SetMouseInputEnabled(false)

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
            Save()
            dsavedialog:Close()
            oldChooseOption(self, value, index)
        end

        local dno = vgui.Create("DButton", dsavedialog)
        dno:SetText("No")
        dno:SetPos(popupWidth / 2 + m, titleBarHeight + m)
        dno.DoClick = function()
            droles.unsavedChanges = false
            dweapons.unsavedChanges = false
            dconvars.unsavedChanges = false
            dsavedialog:Close()
            oldChooseOption(self, value, index)
        end

        dsavedialog:MakePopup()
    end

    local oldClose = dframe.Close
    dframe.Close = function(self)
        local pack, _ = dpack:GetSelected()
        if not pack or #pack == 0 or (not droles.unsavedChanges and not dweapons.unsavedChanges and not dconvars.unsavedChanges) then
            oldClose(self)
            return
        end

        dframe:SetMouseInputEnabled(false)

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
            Save()
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

    local dsavebutton = vgui.Create("DButton", dframe)
    dsavebutton:SetSize(iconButtonSize, iconButtonSize)
    dsavebutton:SetPos(w - 3 * (m + iconButtonSize), titleBarHeight + m)
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
    ddeletebutton:SetPos(w - 4 * (m + iconButtonSize), titleBarHeight + m)
    ddeletebutton:SetText("")
    ddeletebutton:SetIcon("icon16/delete.png")
    ddeletebutton:SetTooltip(GetTranslation("rolepacks_delete"))
    ddeletebutton.DoClick = function()
        local pack, index = dpack:GetSelected()
        if not pack or #pack == 0 then return end

        dframe:SetMouseInputEnabled(false)

        local dconfirmdialog = vgui.Create("DFrame")
        dconfirmdialog:SetSize(popupWidth, popupHeight)
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
        dyes:SetPos(popupWidth / 2 - buttonWidth - m, titleBarHeight + m)
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
        dno:SetPos(popupWidth / 2 + m, titleBarHeight + m)
        dno.DoClick = function()
            dconfirmdialog:Close()
        end

        dconfirmdialog:MakePopup()
    end

    local drenamebutton = vgui.Create("DButton", dframe)
    drenamebutton:SetSize(iconButtonSize, iconButtonSize)
    drenamebutton:SetPos(w - 5 * (m + iconButtonSize), titleBarHeight + m)
    drenamebutton:SetText("")
    drenamebutton:SetIcon("icon16/page_edit.png")
    drenamebutton:SetTooltip(GetTranslation("rolepacks_rename"))
    drenamebutton.DoClick = function()
        local pack, index = dpack:GetSelected()
        if not pack or #pack == 0 then return end

        dframe:SetMouseInputEnabled(false)

        local drenamedialog = vgui.Create("DFrame")
        drenamedialog:SetSize(popupWidth, popupHeight)
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
        drenameentry:SetPos(m, titleBarHeight + m)
        drenameentry:SetWidth(popupWidth - 3 * m - buttonWidth)
        drenameentry:SetText(pack)

        local drename = vgui.Create("DButton", drenamedialog)
        drename:SetText("Rename")
        drename:SetPos(popupWidth - m - buttonWidth, titleBarHeight + m)
        drename.DoClick = function()
            local newpack = StringLower(drenameentry:GetValue())
            if not newpack or #newpack == 0 then return end
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
    dnewbutton:SetSize(iconButtonSize, iconButtonSize)
    dnewbutton:SetPos(w - 6 * (m + iconButtonSize), titleBarHeight + m)
    dnewbutton:SetText("")
    dnewbutton:SetIcon("icon16/add.png")
    dnewbutton:SetTooltip(GetTranslation("rolepacks_add"))
    dnewbutton.DoClick = function()
        dframe:SetMouseInputEnabled(false)

        local dnewdialog = vgui.Create("DFrame")
        dnewdialog:SetSize(popupWidth, popupHeight)
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
        dnewentry:SetPos(m, titleBarHeight + m)
        dnewentry:SetWidth(popupWidth - 3 * m - buttonWidth)

        local dconfirm = vgui.Create("DButton", dnewdialog)
        dconfirm:SetText("Confirm")
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