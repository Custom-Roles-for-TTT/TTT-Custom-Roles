AddCSLuaFile()

local file = file
local vgui = vgui

local GetTranslation = LANG.GetTranslation
local StringLower = string.lower
local TableInsert = table.insert
local TableHasValue = table.HasValue
local TableSort = table.sort

if CLIENT then
    SWEP.PrintName          = "Role Guesser"
    SWEP.Slot               = 8

    SWEP.ViewModelFOV       = 60
    SWEP.DrawCrosshair      = false
    SWEP.ViewModelFlip      = false
end

SWEP.ViewModel              = "models/weapons/v_slam.mdl"
SWEP.WorldModel             = "models/weapons/w_slam.mdl"
SWEP.Weight                 = 2

SWEP.Base                   = "weapon_tttbase"
SWEP.Category               = WEAPON_CATEGORY_ROLE

SWEP.Spawnable              = false
SWEP.AutoSpawnable          = false
SWEP.HoldType               = "slam"
SWEP.Kind                   = WEAPON_ROLE

SWEP.DeploySpeed            = 4
SWEP.AllowDrop              = false
SWEP.NoSights               = true
SWEP.UseHands               = true
SWEP.LimitedStock           = true
SWEP.AmmoEnt                = nil

SWEP.Primary.Delay          = 1
SWEP.Primary.Automatic      = false
SWEP.Primary.Cone           = 0
SWEP.Primary.Ammo           = nil
SWEP.Primary.ClipSize       = -1
SWEP.Primary.ClipMax        = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Sound          = ""

SWEP.Secondary.Delay        = 1.25
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Cone         = 0
SWEP.Secondary.Ammo         = nil
SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.ClipMax      = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Sound        = ""

SWEP.InLoadoutFor           = {ROLE_GUESSER}
SWEP.InLoadoutForDefault    = {ROLE_GUESSER}

function SWEP:Initialize()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
    if CLIENT then
        self:AddHUDHelp("guessingdevice_help_pri", "guessingdevice_help_sec", true)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:Deploy()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
    return true
end

function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
    if CLIENT then
        local numCols = 6
        local numRows = 5
        local itemSize = 64
        -- margin
        local m = 5
        -- item list width
        local dlistw = ((itemSize + 2) * numCols) - 2 + 15
        local dlisth = ((itemSize + 2) * numRows) - 2 + 15

        -- frame size
        local w = dlistw + (m * 2)
        local h = dlisth + (m * 2) + 52

        local dframe = vgui.Create("DFrame")
        dframe:SetSize(w, h)
        dframe:Center()
        dframe:SetTitle(GetTranslation("guessingdevice_title"))
        dframe:SetVisible(true)
        dframe:ShowCloseButton(true)
        dframe:SetMouseInputEnabled(true)
        dframe:SetDeleteOnClose(true)

        local dpanel = vgui.Create("DPanel", dframe)
        dpanel:SetPaintBackground(false)
        dpanel:StretchToParent(m, m + 22, m, m + 30)

        local dcancel = vgui.Create("DButton", dframe)
        dcancel:SetPos(w - 102 - m, h - 27 - m)
        dcancel:SetSize(100, 25)
        dcancel:SetText(GetTranslation("close"))
        dcancel.DoClick = function() dframe:Close() end

        local dlabel = vgui.Create("DLabel", dframe)
        dlabel:SetFont("GuesserSelection")
        dlabel:SetText("Currently selected: ")
        dlabel:SetWidth(w - 100 - (2 * m))
        dlabel:SetTextColor(Color(255, 255, 255, 255))
        dlabel:SetPos(m + 1, h - 25 - m)

        surface.SetFont("GuesserSelection")
        local labelWidth = surface.GetTextSize("Currently selected: ")

        local drolelabel = vgui.Create("DLabel", dframe)
        drolelabel:SetFont("GuesserSelection")
        drolelabel:SetText(ROLE_STRINGS[ROLE_INNOCENT])
        drolelabel:SetWidth(w - 100 - (2 * m) - labelWidth)
        drolelabel:SetTextColor(ROLE_COLORS[ROLE_INNOCENT])
        drolelabel:SetPos(m + 1 + labelWidth, h - 25 - m)

        local dlistbg = vgui.Create("DPanel", dframe)
        dlistbg:SetBackgroundColor(Color(156, 159, 163))
        dlistbg:SetPos(2, 24)
        dlistbg:SetSize(dlistw + 6, dlisth)

        local dlist = vgui.Create("EquipSelect", dlistbg)
        dlist:SetPos(0, 0)
        dlist:SetSize(dlistw, dlisth)
        dlist:EnableVerticalScrollbar(true)
        dlist:EnableHorizontal(true)

        -- sort roles
        local roletable = {}

        local function AddRolesFromTeam(team, exclude)
            local roles = {}
            for role, v in pairs(team) do
                if not v or role == ROLE_GUESSER or DEFAULT_ROLES[role] or (exclude and exclude[role]) then continue end
                if GetConVar("ttt_" .. ROLE_STRINGS_RAW[role] .. "_enabled"):GetBool() then -- TODO: Add hook/table to show roles that can be spawned by another role
                    TableInsert(roles, role)
                end
            end
            TableSort(roles, function(a, b) return StringLower(ROLE_STRINGS[a]) < StringLower(ROLE_STRINGS[b]) end)
            for _, role in pairs(roles) do
                TableInsert(roletable, role)
            end
        end

        TableInsert(roletable, ROLE_DETECTIVE) -- TODO: Add convar to disable guessing of detectives (or maybe just tie to ttt_detectives_hide_special_mode?)
        AddRolesFromTeam(DETECTIVE_ROLES)
        TableInsert(roletable, ROLE_INNOCENT)
        AddRolesFromTeam(INNOCENT_ROLES, DETECTIVE_ROLES)
        TableInsert(roletable, ROLE_TRAITOR)
        AddRolesFromTeam(TRAITOR_ROLES)
        AddRolesFromTeam(JESTER_ROLES)
        AddRolesFromTeam(INDEPENDENT_ROLES)
        AddRolesFromTeam(MONSTER_ROLES)

        local selection = nil

        for _, role in pairs(roletable) do
            local ic = vgui.Create("SimpleIcon", dlist)

            local roleStringShord = ROLE_STRINGS_SHORT[role]
            local material = "vgui/ttt/icon_" .. roleStringShord
            if file.Exists("materials/vgui/ttt/roles/" .. roleStringShord .. "/icon_" .. roleStringShord .. ".vtf", "GAME") then
                material = "vgui/ttt/roles/" .. roleStringShord .. "/icon_" .. roleStringShord
            end

            ic:SetIconSize(itemSize)
            ic:SetIcon(material)
            ic:SetBackgroundColor(ROLE_COLORS[role] or Color(0, 0, 0, 0))
            ic:SetTooltip(ROLE_STRINGS[role])
            ic.role = role

            if role == LocalPlayer():GetNWInt("TTTGuesserSelection", ROLE_INNOCENT) then
                selection = ic
            end

            dlist:AddPanel(ic)
        end

        dlist:SelectPanel(selection)
        drolelabel:SetText(ROLE_STRINGS[selection.role])
        drolelabel:SetTextColor(ROLE_COLORS[selection.role])

        dlist.OnActivePanelChanged = function(self, _, new)
            -- TODO: Add network message to sync selected role to NWInt TTTGuesserSelection
            drolelabel:SetText(ROLE_STRINGS[new.role])
            drolelabel:SetTextColor(ROLE_COLORS[new.role])
        end

        dframe:MakePopup()
        dframe:SetKeyboardInputEnabled(false)
    end
end

if CLIENT then
    surface.CreateFont( "GuesserSelection", {
        font		= "Roboto",
        size		= 24,
        weight		= 500,
        extended	= true
    })
end