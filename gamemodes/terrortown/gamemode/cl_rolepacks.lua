local concommand = concommand
local vgui = vgui
local table = table
local math = math

local GetTranslation = LANG.GetTranslation
local TableInsert = table.insert
local TableRemove = table.remove
local MathCeil = math.ceil

local rolePackConfig = {}

local function BuildRoleConfig(dsheet)
    UpdateRoleColours()

    local droles = vgui.Create("DPanel", dsheet)
    droles:SetPaintBackground(false)
    droles:StretchToParent(0, 0, 0, 0)

    local dslotlist = vgui.Create("DScrollPanel", droles)
    dslotlist:SetPaintBackground(false)
    dslotlist:StretchToParent(0, 0, 16, 64)

    local function CreateSlot(label, roleTable)
        local iconHeight = 88

        local dslot = vgui.Create("DPanel", dslotlist)
        dslot:SetPaintBackground(false)
        dslot:SetSize(dslotlist:GetSize(), 16 + iconHeight)
        dslot:Dock(TOP)

        local dlabel = vgui.Create("DLabel", dslot)
        dlabel:SetFont("TabLarge")
        dlabel:SetText(label)
        dlabel:SetContentAlignment(7)
        dlabel:SetPos(3, 0) -- For some reason the text isn't inline with the icons so we shift it 3px to the right

        local dlist = vgui.Create("EquipSelect", dslot)
        dlist:SetPos(0, 14)
        dlist:StretchToParent(0, nil, 0, nil)
        dlist:SetHeight(iconHeight)
        dlist:EnableHorizontal(true)

        local roleList = {}

        local function CreateRole(role)
            local drole = vgui.Create("DPanel", dlist)
            drole:SetSize(64, 84)
            dslot:SetPaintBackground(false)

            local dicon = vgui.Create("SimpleIcon", drole)

            local roleStringShort = ROLE_STRINGS_SHORT[role]
            local material = "vgui/ttt/icon_" .. roleStringShort
            if file.Exists("materials/vgui/ttt/roles/" .. roleStringShort .. "/icon_" .. roleStringShort .. ".vtf", "GAME") then
                material = "vgui/ttt/roles/" .. roleStringShort .. "/icon_" .. roleStringShort
            end

            dicon:SetIconSize(64)
            dicon:SetIcon(material)
            dicon:SetBackgroundColor(ROLE_COLORS[role] or Color(0, 0, 0, 0))
            dicon:SetTooltip(ROLE_STRINGS[role])
            dicon.DoClick = function()
                local dmenu = DermaMenu()
                for r, s in SortedPairsByValue(ROLE_STRINGS) do
                    dmenu:AddOption(s, function()
                        roleStringShort = ROLE_STRINGS_SHORT[r]
                        material = "vgui/ttt/icon_" .. roleStringShort
                        if file.Exists("materials/vgui/ttt/roles/" .. roleStringShort .. "/icon_" .. roleStringShort .. ".vtf", "GAME") then
                            material = "vgui/ttt/roles/" .. roleStringShort .. "/icon_" .. roleStringShort
                        end
                        dicon:SetIcon(material)
                        dicon:SetBackgroundColor(ROLE_COLORS[r] or Color(0, 0, 0, 0))
                        dicon:SetTooltip(s)
                    end)
                end
                dmenu:Open()
            end

            local dweight = vgui.Create("DNumberWang", drole)
            dweight:SetWidth(64)
            dweight:SetPos(0, 64)
            dweight:SetMin(1)
            dweight:SetValue(1)

            TableInsert(roleList, drole)

            local iconRows = MathCeil((#roleList + 1) / 8)
            dslot:SetSize(dslotlist:GetSize(), 16 + iconRows * iconHeight)
            dlist:SetHeight(iconRows * iconHeight)

            dlist:AddPanel(drole)
        end

        for _, role in pairs(roleTable) do
            CreateRole(role)
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
            CreateRole(ROLE_INNOCENT)
            dlist:AddPanel(dbuttons)
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
        end

        local ddeleteslotbutton = vgui.Create("DButton", dbuttons)
        ddeleteslotbutton:SetSize(22, 22)
        ddeleteslotbutton:SetPos(0, 48)
        ddeleteslotbutton:SetText("")
        ddeleteslotbutton:SetIcon("icon16/bin.png")
        ddeleteslotbutton:SetTooltip(GetTranslation("rolepacks_delete_slot"))
        ddeleteslotbutton.DoClick = function()
            dslot:Remove()
        end

        dlist:AddPanel(dbuttons)

        dslotlist:AddItem(dslot)
    end

    local daddslotbutton = vgui.Create("DButton", droles)
    daddslotbutton:SetText("Add Slot")
    daddslotbutton:Dock(BOTTOM)
    daddslotbutton.DoClick = function()
        CreateSlot("Role Slot:", {})
    end

    return droles
end

local function BuildWeaponConfig(dsheet)
    local dweapons = vgui.Create("DScrollPanel", dsheet)
    dweapons:SetPaintBackground(false)
    dweapons:StretchToParent(0, 0, 0, 0)

    return dweapons
end

local function BuildConVarConfig(dsheet)
    local dconvars = vgui.Create("DScrollPanel", dsheet)
    dconvars:SetPaintBackground(false)
    dconvars:StretchToParent(0, 0, 0, 0)

    return dconvars
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
    local h = dlisth + 75 + m + 22

    local dframe = vgui.Create("DFrame")
    dframe:SetSize(w, h)
    dframe:Center()
    dframe:SetTitle(GetTranslation("rolepacks_title"))
    dframe:SetVisible(true)
    dframe:ShowCloseButton(true)
    dframe:SetMouseInputEnabled(true)
    dframe:SetDeleteOnClose(true)

    local dpack = vgui.Create("DComboBox", dframe)
    dpack:SetPos(m, m + 25)
    dpack:StretchToParent(m, nil, 4 * m + 66, nil)
    -- TODO: Populate dropdown with available role packs

    local ddeletebutton = vgui.Create("DButton", dframe)
    ddeletebutton:SetSize(22, 22)
    ddeletebutton:SetPos(w - m - 22, m + 25)
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
            -- TODO: Delete role pack JSON and clear currently open panel
            dconfirmdialog:Close()
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
    drenamebutton:SetPos(w - 2 * m - 44, m + 25)
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
            local newpack = drenameentry:GetValue()
            if not newpack or newpack == "" then return end
            -- TODO: Check that new name is valid
            TableRemove(dpack.Choices, index)
            local newindex = dpack:AddChoice(newpack)
            dpack:ChooseOption(newpack, newindex)
            -- TODO: Update role pack JSON and currently open panel
            drenamedialog:Close()
        end

        drenamedialog:MakePopup()
    end

    local dnewbutton = vgui.Create("DButton", dframe)
    dnewbutton:SetSize(22, 22)
    dnewbutton:SetPos(w - 3 * m - 66, m + 25)
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
            local pack = dnewentry:GetValue()
            if not pack or pack == "" then return end
            -- TODO: Check that new name is valid
            local index = dpack:AddChoice(pack)
            dpack:ChooseOption(pack, index)
            -- TODO: Create role pack JSON and clear currently open panel
            dnewdialog:Close()
        end

        dnewdialog:MakePopup()
    end

    local dsheet = vgui.Create("DPropertySheet", dframe)
    dsheet:SetPos(0, 0)
    dsheet:StretchToParent(m, 2 * m + 47, m, m)

    local droleweapons = BuildRoleConfig(dsheet)
    dsheet:AddSheet(GetTranslation("rolepacks_role_tabtitle"), droleweapons, "icon16/user.png", false, false, GetTranslation("rolepacks_role_tabtitle_tooltip"))

    local droleweapons = BuildWeaponConfig(dsheet)
    dsheet:AddSheet(GetTranslation("rolepacks_weapon_tabtitle"), droleweapons, "icon16/bomb.png", false, false, GetTranslation("rolepacks_weapon_tabtitle_tooltip"))

    local droleweapons = BuildConVarConfig(dsheet)
    dsheet:AddSheet(GetTranslation("rolepacks_convar_tabtitle"), droleweapons, "icon16/application_xp_terminal.png", false, false, GetTranslation("rolepacks_convar_tabtitle_tooltip"))

    dframe:MakePopup()
end

concommand.Add("ttt_rolepacks", function(ply, cmd, args)
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ErrorNoHalt("ERROR: You must be an administrator to open the Role Packs Configuration dialog\n")
        return
    end
    OpenDialog()
end)