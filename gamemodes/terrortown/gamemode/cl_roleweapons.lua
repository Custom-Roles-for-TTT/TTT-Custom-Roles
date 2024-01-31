include("shared.lua")

local concommand = concommand
local math = math
local net = net
local pairs = pairs
local string = string
local table = table
local timer = timer
local vgui = vgui

local GetTranslation = LANG.GetTranslation
local SafeTranslate = LANG.TryTranslation
local StringFind = string.find
local StringLower = string.lower
local TableInsert = table.insert
local TableSort = table.sort

local function ShowList()
    print("[ROLEWEAPONS] Sending configuration list command... Please check server console for results")

    net.Start("TTT_RoleWeaponsList")
    net.SendToServer()
end

local function Clean()
    print("[ROLEWEAPONS] Sending invalid configuration clean command... Please check server console for results")

    net.Start("TTT_RoleWeaponsClean")
    net.SendToServer()
end

local function Reload()
    print("[ROLEWEAPONS] Sending configuration reload command... Please check server console for results")

    net.Start("TTT_RoleWeaponsReload")
    net.SendToServer()
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

local function BuildRoleWeapons(dsheet, dframe, itemSize, m, dlistw, dlisth, diw, w, h)
    local role = ROLE_NONE
    local save_role = ROLE_NONE
    local padding = dsheet:GetPadding()

    local droleweapons = vgui.Create("DPanel", dsheet)
    droleweapons:SetPaintBackground(false)
    droleweapons:StretchToParent(padding, padding, padding, padding)

    local dsearchheight = 25
    local dsearchpadding = 5
    local dsearch = vgui.Create("DTextEntry", droleweapons)
    dsearch:SetPos(0, 0)
    dsearch:SetSize(dlistw, dsearchheight)
    dsearch:SetPlaceholderText("Search...")
    dsearch:SetUpdateOnType(true)
    dsearch.OnGetFocus = function() dframe:SetKeyboardInputEnabled(true) end
    dsearch.OnLoseFocus = function() dframe:SetKeyboardInputEnabled(false) end

    local dinfow = diw - m
    local dsearchrole = vgui.Create("DComboBox", droleweapons)
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
    local dlist = vgui.Create("EquipSelect", droleweapons)
    dlist:SetPos(0, dsearchheight + dsearchpadding)
    dlist:SetSize(dlistw, dlisth - dsearchheight - dsearchpadding)
    dlist:EnableVerticalScrollbar(true)
    dlist:EnableHorizontal(true)

    local bw, bh = 126, 25

    -- Whole right column
    local dih = h - bh - m * 20 - 30
    local dinfobg = vgui.Create("DPanel", droleweapons)
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

    local dsaverole = vgui.Create("DComboBox", droleweapons)
    dsaverole:SetPos(dlistw + m, dih)
    dsaverole:SetSize(bw, dsearchheight)
    dsaverole:AddChoice(GetTranslation("roleweapons_select_saverole"), ROLE_NONE, true)
    dsaverole:SetTooltip(GetTranslation("roleweapons_select_saverole_tooltip"))
    for r = ROLE_INNOCENT, ROLE_MAX do
        dsaverole:AddChoice(ROLE_STRINGS[r], r)
    end

    local dconfirm = vgui.Create("DButton", droleweapons)
    dconfirm:SetPos(w - 30 - bw, dih + dsearchheight + 3)
    dconfirm:SetSize(bw, bh)
    dconfirm:SetDisabled(true)
    dconfirm:SetText(GetTranslation("roleweapons_confirm"))

    local dcancel = vgui.Create("DButton", droleweapons)
    dcancel:SetPos(w - 30 - bw, dih + dsearchheight + bh + 6)
    dcancel:SetSize(bw, bh)
    dcancel:SetDisabled(false)
    dcancel:SetText(GetTranslation("close"))
    dcancel.DoClick = function() dframe:Close() end

    local dradiopadding = 3

    local dradionone = vgui.Create("DCheckBoxLabel", droleweapons)
    dradionone:SetPos(dlistw + m, dih + dsearchheight + dradiopadding)
    dradionone:SetText(GetTranslation("roleweapons_option_none"))
    dradionone:SetTooltip(GetTranslation("roleweapons_option_none_tooltip"))
    dradionone:SizeToContents()
    dradionone:SetValue(true)
    dradionone:SetTextColor(COLOR_WHITE)
    dradionone:SetDisabled(true)

    local dradiol, dradiot = dradionone:GetPos()
    local _, dradioh = dradionone:GetSize()

    local dradioinclude = vgui.Create("DCheckBoxLabel", droleweapons)
    dradioinclude:SetPos(dradiol, dradiot + dradioh + dradiopadding)
    dradioinclude:SetText(GetTranslation("roleweapons_option_include"))
    dradioinclude:SetTooltip(GetTranslation("roleweapons_option_include_tooltip"))
    dradioinclude:SizeToContents()
    dradioinclude:SetTextColor(COLOR_WHITE)
    dradioinclude:SetDisabled(true)

    local dradioexclude = vgui.Create("DCheckBoxLabel", droleweapons)
    dradioexclude:SetPos(dradiol, dradiot + (dradioh * 2) + (dradiopadding * 2))
    dradioexclude:SetText(GetTranslation("roleweapons_option_exclude"))
    dradioexclude:SetTooltip(GetTranslation("roleweapons_option_exclude_tooltip"))
    dradioexclude:SizeToContents()
    dradioexclude:SetTextColor(COLOR_WHITE)
    dradioexclude:SetDisabled(true)

    local dradionorandom = vgui.Create("DCheckBoxLabel", droleweapons)
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
    return droleweapons
end

local function BuildCommands(dsheet, dframe, m, w, h)
    local padding = dsheet:GetPadding()
    local gap = 20
    local bw, bh = 126, 25

    local dcommands = vgui.Create("DPanel", dsheet)
    dcommands:SetPaintBackground(false)
    dcommands:StretchToParent(padding, padding, padding, padding)

    local currenth = m
    local dlistlabel = vgui.Create("DLabel", dcommands)
    dlistlabel:SetPos(0, currenth)
    dlistlabel:SetText(GetTranslation("roleweapons_command_print_desc"))
    dlistlabel:SetTextColor(COLOR_DGREY)
    dlistlabel:SizeToContents()

    local _, parth = dlistlabel:GetSize()
    currenth = currenth + parth + m

    local dlist = vgui.Create("DButton", dcommands)
    dlist:SetPos(0, currenth)
    dlist:SetSize(w - m * 2, bh)
    dlist:SetDisabled(false)
    dlist:SetText(GetTranslation("roleweapons_command_print"))
    dlist.DoClick = function() ShowList() end

    _, parth = dlist:GetSize()
    currenth = currenth + parth + m + gap

    local dcleanlabel = vgui.Create("DLabel", dcommands)
    dcleanlabel:SetPos(0, currenth)
    dcleanlabel:SetText(GetTranslation("roleweapons_command_clean_desc"))
    dcleanlabel:SetTextColor(COLOR_DGREY)
    dcleanlabel:SizeToContents()

    _, parth = dcleanlabel:GetSize()
    currenth = currenth + parth + m

    local dclean = vgui.Create("DButton", dcommands)
    dclean:SetPos(0, currenth)
    dclean:SetSize(w - m * 2, bh)
    dclean:SetDisabled(false)
    dclean:SetText(GetTranslation("roleweapons_command_clean"))
    dclean.DoClick = function() Clean() end

    _, parth = dclean:GetSize()
    currenth = currenth + parth + m + gap

    local dreloadlabel = vgui.Create("DLabel", dcommands)
    dreloadlabel:SetPos(0, currenth)
    dreloadlabel:SetText(GetTranslation("roleweapons_command_reload_desc"))
    dreloadlabel:SetTextColor(COLOR_DGREY)
    dreloadlabel:SizeToContents()

    _, parth = dreloadlabel:GetSize()
    currenth = currenth + parth + m

    local dreload = vgui.Create("DButton", dcommands)
    dreload:SetPos(0, currenth)
    dreload:SetSize(w - m * 2, bh)
    dreload:SetDisabled(false)
    dreload:SetText(GetTranslation("roleweapons_command_reload"))
    dreload.DoClick = function() Reload() end

    local dcancel = vgui.Create("DButton", dcommands)
    dcancel:SetPos(w - bw - 30, h - bh - 74)
    dcancel:SetSize(bw, bh)
    dcancel:SetDisabled(false)
    dcancel:SetText(GetTranslation("close"))
    dcancel.DoClick = function() dframe:Close() end

    return dcommands
end

local function OpenDialog()
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

    local droleweapons = BuildRoleWeapons(dsheet, dframe, itemSize, m, dlistw, dlisth, diw, w, h)
    dsheet:AddSheet(GetTranslation("roleweapons_tabtitle"), droleweapons, "icon16/bomb.png", false, false, GetTranslation("roleweapons_tabtitle_tooltip"))

    local dcommands = BuildCommands(dsheet, dframe, m, w, h)
    dsheet:AddSheet(GetTranslation("roleweapons_commandtitle"), dcommands, "icon16/application_xp_terminal.png", false, false, GetTranslation("roleweapons_commandtitle_tooltip"))

    dframe:MakePopup()
    dframe:SetKeyboardInputEnabled(false)
end

local function PrintHelp()
    print("ttt_roleweapons [OPTION]")
    print("If no options provided, default of 'open' will be used")
    print("\tclean\t-\tRemoves any invalid configurations. WARNING: This CANNOT be undone!")
    print("\thelp\t-\tPrints this message")
    print("\topen\t-\tOpen the configuration dialog [CLIENT ONLY]")
    print("\tshow\t")
    print("\tlist\t-\tPrints the current configuration in the server console, highlighting anything invalid")
    print("\tprint\t")
    print("\treload\t-\tReloads the configurations from the server's filesystem")
end

concommand.Add("ttt_roleweapons", function(ply, cmd, args)
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ErrorNoHalt("ERROR: You must be an administrator to open the Role Weapons Configuration dialog\n")
        return
    end

    local method = #args > 0 and args[1] or "open"
    if method == "open" or method == "show" then
        OpenDialog()
    elseif method == "print" or method == "list" then
        ShowList()
    elseif method == "clean" then
        Clean()
    elseif method == "reload" then
        Reload()
    elseif method == "help" then
        PrintHelp()
    else
        ErrorNoHalt("ERROR: Unknown command '" .. method .. "'\n")
    end
end)