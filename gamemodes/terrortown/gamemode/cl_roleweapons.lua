include("shared.lua")

local concommand = concommand
local math = math
local net = net
local pairs = pairs
local table = table
local timer = timer
local vgui = vgui

local GetTranslation = LANG.GetTranslation
local SafeTranslate = LANG.TryTranslation
local StringFind = string.find
local StringLower = string.lower

local function ItemIsWeapon(item) return not tonumber(item.id) end

local function DoesValueMatch(item, data, value)
    if not item[data] then return false end

    local itemdata = item[data]
    if isfunction(itemdata) then
        itemdata = itemdata()
    end
    return itemdata and StringFind(StringLower(SafeTranslate(itemdata)), StringLower(value), 1, true)
end

local function OpenDialog(client)
    if not client:IsAdmin() and not client:IsSuperAdmin() then
        ErrorNoHalt("ERROR: You must be an administrator to open the Role Weapons Configuration dialog\n")
        return
    end

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
    local h = dlisth + 75

    local dframe = vgui.Create("DFrame")
    dframe:SetSize(w, h)
    dframe:Center()
    dframe:SetTitle(GetTranslation("roleweapons_title"))
    dframe:SetVisible(true)
    dframe:ShowCloseButton(true)
    dframe:SetMouseInputEnabled(true)
    dframe:SetDeleteOnClose(true)

    local dsheet = vgui.Create("DPropertySheet", dframe)

    -- Add a callback when switching tabs
    local oldfunc = dsheet.SetActiveTab
    dsheet.SetActiveTab = function(self, new)
        if self.m_pActiveTab ~= new and self.OnTabChanged then
            self:OnTabChanged(self.m_pActiveTab, new)
        end
        oldfunc(self, new)
    end

    dsheet:SetPos(0, 0)
    dsheet:StretchToParent(m, m + 25, m, m)

    local role = ROLE_NONE
    local save_role = ROLE_NONE
    local padding = dsheet:GetPadding()

    local dequip = vgui.Create("DPanel", dsheet)
    dequip:SetPaintBackground(false)
    dequip:StretchToParent(padding, padding, padding, padding)

    local dsearchheight = 25
    local dsearchpadding = 5
    local dsearch = vgui.Create("DTextEntry", dequip)
    dsearch:SetPos(0, 0)
    dsearch:SetSize(dlistw, dsearchheight)
    dsearch:SetPlaceholderText("Search...")
    dsearch:SetUpdateOnType(true)
    dsearch.OnGetFocus = function() dframe:SetKeyboardInputEnabled(true) end
    dsearch.OnLoseFocus = function() dframe:SetKeyboardInputEnabled(false) end

    local dinfow = diw - m
    local dsearchrole = vgui.Create("DComboBox", dequip)
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
    local dlist = vgui.Create("EquipSelect", dequip)
    dlist:SetPos(0, dsearchheight + dsearchpadding)
    dlist:SetSize(dlistw, dlisth - dsearchheight - dsearchpadding)
    dlist:EnableVerticalScrollbar(true)
    dlist:EnableHorizontal(true)

    local bw, bh = 126, 25

    -- Whole right column
    local dih = h - bh - m * 20 - 30
    local dinfobg = vgui.Create("DPanel", dequip)
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
        for i = 1, 9 do
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
                ic.slot = 1
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
                paneltable[ic.slot or 1][k] = ic
            end
        end

        for i = 1, 9 do
            for _, panel in pairs(paneltable[i]) do
                dlist:AddPanel(panel)
            end
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

    local dsaverole = vgui.Create("DComboBox", dequip)
    dsaverole:SetPos(dlistw + m, dih)
    dsaverole:SetSize(bw, dsearchheight)
    dsaverole:AddChoice(GetTranslation("roleweapons_select_saverole"), ROLE_NONE, true)
    dsaverole:SetTooltip(GetTranslation("roleweapons_select_saverole_tooltip"))
    for r = ROLE_INNOCENT, ROLE_MAX do
        dsaverole:AddChoice(ROLE_STRINGS[r], r)
    end

    local dconfirm = vgui.Create("DButton", dequip)
    dconfirm:SetPos(w - 30 - bw, dih + dsearchheight + 3)
    dconfirm:SetSize(bw, bh)
    dconfirm:SetDisabled(true)
    dconfirm:SetText(GetTranslation("roleweapons_confirm"))

    local dcancel = vgui.Create("DButton", dequip)
    dcancel:SetPos(w - 30 - bw, dih + dsearchheight + bh + 6)
    dcancel:SetSize(bw, bh)
    dcancel:SetDisabled(false)
    dcancel:SetText(GetTranslation("close"))
    dcancel.DoClick = function() dframe:Close() end

    local dradiopadding = 3

    local dradionone = vgui.Create("DCheckBoxLabel", dequip)
    dradionone:SetPos(dlistw + m, dih + dsearchheight + dradiopadding)
    dradionone:SetText(GetTranslation("roleweapons_option_none"))
    dradionone:SetTooltip(GetTranslation("roleweapons_option_none_tooltip"))
    dradionone:SizeToContents()
    dradionone:SetValue(true)
    dradionone:SetTextColor(COLOR_WHITE)
    dradionone:SetDisabled(true)

    local dradiol, dradiot = dradionone:GetPos()
    local _, dradioh = dradionone:GetSize()

    local dradioinclude = vgui.Create("DCheckBoxLabel", dequip)
    dradioinclude:SetPos(dradiol, dradiot + dradioh + dradiopadding)
    dradioinclude:SetText(GetTranslation("roleweapons_option_include"))
    dradioinclude:SetTooltip(GetTranslation("roleweapons_option_include_tooltip"))
    dradioinclude:SizeToContents()
    dradioinclude:SetTextColor(COLOR_WHITE)
    dradioinclude:SetDisabled(true)

    local dradioexclude = vgui.Create("DCheckBoxLabel", dequip)
    dradioexclude:SetPos(dradiol, dradiot + (dradioh * 2) + (dradiopadding * 2))
    dradioexclude:SetText(GetTranslation("roleweapons_option_exclude"))
    dradioexclude:SetTooltip(GetTranslation("roleweapons_option_exclude_tooltip"))
    dradioexclude:SizeToContents()
    dradioexclude:SetTextColor(COLOR_WHITE)
    dradioexclude:SetDisabled(true)

    local dradionorandom = vgui.Create("DCheckBoxLabel", dequip)
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
            local weap_class = item.id
            if WEPS.BuyableWeapons[save_role] and table.HasValue(WEPS.BuyableWeapons[save_role], weap_class) then
                dradioinclude:SetValue(true)
            elseif WEPS.ExcludeWeapons[save_role] and table.HasValue(WEPS.ExcludeWeapons[save_role], weap_class) then
                dradioexclude:SetValue(true)
            else
                dradionone:SetValue(true)
            end

            dradionorandom:SetValue(WEPS.BypassRandomWeapons[save_role] and table.HasValue(WEPS.BypassRandomWeapons[save_role], weap_class))
        else
            local name = item.name
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
        net.Start("TTT_ConfigureRoleWeapons")
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

    dsheet:AddSheet(GetTranslation("roleweapons_tabtitle"), dequip, "icon16/bomb.png", false, false, GetTranslation("roleweapons_tabtitle_tooltip"))

    dframe:MakePopup()
    dframe:SetKeyboardInputEnabled(false)
end
concommand.Add("ttt_roleweapons", OpenDialog)