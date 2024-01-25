local concommand = concommand
local vgui = vgui
local table = table

local GetTranslation = LANG.GetTranslation
local TableRemove = table.remove

local function BuildRoleConfig(dsheet)
    local padding = dsheet:GetPadding()

    local droles = vgui.Create("DPanel", dsheet)
    droles:SetPaintBackground(false)
    droles:StretchToParent(padding, padding, padding, padding)

    return droles
end

local function BuildWeaponConfig(dsheet)
    local padding = dsheet:GetPadding()

    local dweapons = vgui.Create("DPanel", dsheet)
    dweapons:SetPaintBackground(false)
    dweapons:StretchToParent(padding, padding, padding, padding)

    return dweapons
end

local function BuildConVarConfig(dsheet)
    local padding = dsheet:GetPadding()

    local dconvars = vgui.Create("DPanel", dsheet)
    dconvars:SetPaintBackground(false)
    dconvars:StretchToParent(padding, padding, padding, padding)

    return dconvars
end

local function OpenDialog()
    local w = 600
    local h = 1000
    local m = 5

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