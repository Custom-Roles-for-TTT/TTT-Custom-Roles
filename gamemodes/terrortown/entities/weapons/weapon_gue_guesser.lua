AddCSLuaFile()

local file = file
local vgui = vgui
local net = net
local util = util

local GetTranslation = LANG.GetTranslation
local StringLower = string.lower
local StringFind = string.find
local TableInsert = table.insert
local TableSort = table.sort
local TableHasValue = table.HasValue
local MathMax = math.max
local MathClamp = math.Clamp
local MathCeil = math.ceil

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

SWEP.Primary.Delay          = 0.2
SWEP.Primary.Automatic      = false
SWEP.Primary.Cone           = 0
SWEP.Primary.Ammo           = nil
SWEP.Primary.ClipSize       = -1
SWEP.Primary.ClipMax        = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Sound          = ""

SWEP.Secondary.Delay        = 0.2
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Cone         = 0
SWEP.Secondary.Ammo         = nil
SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.ClipMax      = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Sound        = ""

SWEP.InLoadoutFor           = {ROLE_GUESSER}
SWEP.InLoadoutForDefault    = {ROLE_GUESSER}

local guesser_can_guess_detectives = CreateConVar("ttt_guesser_can_guess_detectives", "0", FCVAR_REPLICATED, "Whether the guesser is allowed to guess detectives", 0, 1)
local guesser_unguessable_roles = CreateConVar("ttt_guesser_unguessable_roles", "lootgoblin,zombie", FCVAR_REPLICATED, "Names of roles that cannot be guessed by the guesser, separated with commas. Do not include spaces or capital letters.")
local guesser_minimum_radius = CreateConVar("ttt_guesser_minimum_radius", "5", FCVAR_REPLICATED, "The minimum radius of the guesser's device in meters. Set to 0 to disable", 1, 30)

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
    if SERVER and IsValid(self:GetOwner()) then
        self:GetOwner():DrawViewModel(false)
    end

    self:DrawShadow(false)
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
    return true
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    if SERVER then
        local owner = self:GetOwner()
        local role = owner:GetNWInt("TTTGuesserSelection", ROLE_NONE)
        if role == ROLE_NONE then
            owner:QueueMessage(MSG_PRINTCENTER, "Select a role first!", 1)
            return
        end

        local trace = util.GetPlayerTrace(self.Owner)
        local tr = util.TraceLine(trace)
        if tr.Entity.IsPlayer() then
            local ply = tr.Entity
            local radius = guesser_minimum_radius:GetFloat() * UNITS_PER_METER
            if ply:GetPos():Distance(owner:GetPos()) <= radius or radius == 0 then
                if ply:GetNWBool("TTTGuesserWasGuesser", false) then
                    owner:QueueMessage(MSG_PRINTCENTER, "That player was previously ".. ROLE_STRINGS_EXT[ROLE_GUESSER] .. " and so cannot be guessed!")
                    return
                end
                if ply:IsRole(role) then
                    owner:QueueMessage(MSG_PRINTBOTH, "You guessed correctly and have become " .. ROLE_STRINGS_EXT[role] .. "!")
                    owner:SetNWBool("TTTGuesserWasGuesser", true)
                    hook.Call("TTTPlayerRoleChangedByItem", nil, owner, owner, self)
                    ply:Give("weapon_gue_guesser")
                    ply:SetNWString("TTTGuesserGuessedBy", owner:Nick())
                    ply:QueueMessage(MSG_PRINTBOTH, "Your role was guessed by " .. ROLE_STRINGS_EXT[ROLE_GUESSER] .. " and you have taken their place!")
                    hook.Call("TTTPlayerRoleChangedByItem", nil, owner, ply, self)
                    owner:SetRole(role)
                    ply:SetRole(ROLE_GUESSER)
                    SendFullStateUpdate()
                    net.Start("TTT_GuesserGuessed")
                    net.WriteBool(true)
                    net.WriteString(ply:Nick())
                    net.WriteString(owner:Nick())
                    net.Broadcast()
                    self:Remove()

                else
                    owner:QueueMessage(MSG_PRINTBOTH, "You guessed incorrectly and have died!")
                    net.Start("TTT_GuesserGuessed")
                    net.WriteBool(false)
                    net.WriteString(ply:Nick())
                    net.WriteString(owner:Nick())
                    net.Broadcast()
                    owner:Kill()
                end
            end
        end
    end
end

function SWEP:SecondaryAttack()
    if not IsFirstTimePredicted() then return end
    self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
    if CLIENT then
        local function AddRolesFromTeam(table, team, exclude)
            local bannedRoles = {}
            local bannedRolesString = guesser_unguessable_roles:GetString()
            if #bannedRolesString > 0 then
                bannedRoles = string.Explode(",", bannedRolesString)
            end
            local roles = {}
            for role, v in pairs(team) do
                if not v or role == ROLE_GUESSER or DEFAULT_ROLES[role] or (exclude and exclude[role])
                    or TableHasValue(bannedRoles, ROLE_STRINGS_RAW[role]) then continue end
                if util.CanRoleSpawn(role) then
                    TableInsert(roles, role)
                end
            end
            TableSort(roles, function(a, b) return StringLower(ROLE_STRINGS[a]) < StringLower(ROLE_STRINGS[b]) end)
            for _, role in pairs(roles) do
                TableInsert(table, role)
            end
        end

        local detectives = {}
        if guesser_can_guess_detectives:GetBool() then
            TableInsert(detectives, ROLE_DETECTIVE)
            AddRolesFromTeam(detectives, DETECTIVE_ROLES)
        end
        local innocents = {}
        TableInsert(innocents, ROLE_INNOCENT)
        AddRolesFromTeam(innocents, INNOCENT_ROLES, DETECTIVE_ROLES)
        local traitors = {}
        TableInsert(traitors, ROLE_TRAITOR)
        AddRolesFromTeam(traitors, TRAITOR_ROLES)
        local jesters = {}
        AddRolesFromTeam(jesters, JESTER_ROLES)
        local independents = {}
        AddRolesFromTeam(independents, INDEPENDENT_ROLES)
        local monsters = {}
        AddRolesFromTeam(monsters, MONSTER_ROLES)

        local largestTeam       = MathMax(#detectives, #innocents, #traitors, #jesters, #independents, #monsters)
        local columns           = MathClamp(largestTeam, 4, 8)
        local detectiveRows     = MathCeil(#detectives / columns)
        local innocentRows      = MathCeil(#innocents / columns)
        local traitorRows       = MathCeil(#traitors / columns)
        local jesterRows        = MathCeil(#jesters / columns)
        local independentRows   = MathCeil(#independents / columns)
        local monsterRows       = MathCeil(#monsters / columns)

        local function isHeadingNeeded(table)
            return #table == 0 and 0 or 1
        end

        local labels = isHeadingNeeded(detectives) + isHeadingNeeded(innocents) + isHeadingNeeded(traitors)
                        + isHeadingNeeded(jesters) + isHeadingNeeded(independents) + isHeadingNeeded(monsters)

        local itemSize      = 64
        local headingHeight = 22
        local searchHeight  = 25
        local labelHeight   = 16
        local m             = 5

        -- list sizes
        local listWidth             = (itemSize + 2) * columns
        local detectivesHeight      = MathMax(((itemSize + 2) * detectiveRows + 2), 0)
        local innocentsHeight       = MathMax(((itemSize + 2) * innocentRows + 2), 0)
        local traitorsHeight        = MathMax(((itemSize + 2) * traitorRows + 2), 0)
        local jestersHeight         = MathMax(((itemSize + 2) * jesterRows + 2), 0)
        local independentsHeight    = MathMax(((itemSize + 2) * independentRows + 2), 0)
        local monstersHeight        = MathMax(((itemSize + 2) * monsterRows + 2), 0)

        -- I worked this out from looking at screenshots and measuring how the bottom margin changes based on the number of labels. I don't know why this is needed or where these numbers come from!
        local bottomMarginOffset = (2 * labels) - 7

        -- frame size
        local w = listWidth + (m * 2) + 2 -- For some reason the icons aren't centred horizontally so add 2px
        local h = detectivesHeight + innocentsHeight + traitorsHeight + jestersHeight + independentsHeight + monstersHeight
                + (labelHeight * labels) + (m * 2) + headingHeight + searchHeight + bottomMarginOffset

        local dframe = vgui.Create("DFrame")
        dframe:SetSize(w, h)
        dframe:Center()
        dframe:SetTitle(GetTranslation("guessingdevice_title"))
        dframe:SetVisible(true)
        dframe:ShowCloseButton(true)
        dframe:SetMouseInputEnabled(true)
        dframe:SetDeleteOnClose(true)

        local dsearch = vgui.Create("DTextEntry", dframe)
        dsearch:SetPos(m + 2, m + headingHeight + 2) -- For some reason this is 2px higher than it should be so shift it down, also undo the extra width added above
        dsearch:SetSize(listWidth - 2, searchHeight)
        dsearch:SetPlaceholderText("Search...")
        dsearch:SetUpdateOnType(true)
        dsearch.OnGetFocus = function() dframe:SetKeyboardInputEnabled(true) end
        dsearch.OnLoseFocus = function() dframe:SetKeyboardInputEnabled(false) end

        local panelList = {}

        local function createTeamList(label, roleTable, height, yOffset)
            local dlabel = vgui.Create("DLabel", dframe)
            dlabel:SetFont("TabLarge")
            dlabel:SetText(label)
            dlabel:SetContentAlignment(7)
            dlabel:SetWidth(listWidth)
            dlabel:SetPos(m + 3, yOffset) -- For some reason the text isn't inline with the icons so we shift it 3px to the right

            local dlist = vgui.Create("EquipSelect", dframe)
            dlist:SetPos(m, yOffset + labelHeight)
            dlist:SetSize(listWidth, height)
            dlist:EnableHorizontal(true)

            for _, role in pairs(roleTable) do
                local ic = vgui.Create("SimpleIcon", dlist)

                local roleStringShort = ROLE_STRINGS_SHORT[role]
                local material = "vgui/ttt/icon_" .. roleStringShort
                if file.Exists("materials/vgui/ttt/roles/" .. roleStringShort .. "/icon_" .. roleStringShort .. ".vtf", "GAME") then
                    material = "vgui/ttt/roles/" .. roleStringShort .. "/icon_" .. roleStringShort
                end

                ic:SetIconSize(itemSize)
                ic:SetIcon(material)
                ic:SetBackgroundColor(ROLE_COLORS[role] or Color(0, 0, 0, 0))
                ic:SetTooltip(ROLE_STRINGS[role])
                ic.role = role
                ic.enabled = true

                TableInsert(panelList, ic)

                dlist:AddPanel(ic)
            end

            dlist.OnActivePanelChanged = function(_, _, new)
                if new.enabled then
                    net.Start("TTT_GuesserSelectRole")
                    net.WriteInt(new.role, 8)
                    net.SendToServer()
                    dframe:Close()
                end
            end
        end

        local yOffset = m * 2 + headingHeight + searchHeight
        if #detectives > 0 then
            createTeamList("Detective Roles", detectives, detectivesHeight, yOffset)
            yOffset = yOffset + detectivesHeight + labelHeight
        end
        if #innocents > 0 then
            createTeamList("Innocent Roles", innocents, innocentsHeight, yOffset)
            yOffset = yOffset + innocentsHeight + labelHeight
        end
        if #traitors > 0 then
            createTeamList("Traitor Roles", traitors, traitorsHeight, yOffset)
            yOffset = yOffset + traitorsHeight + labelHeight
        end
        if #jesters > 0 then
            createTeamList("Jester Roles", jesters, jestersHeight, yOffset)
            yOffset = yOffset + jestersHeight + labelHeight
        end
        if #independents > 0 then
            createTeamList("Independent Roles", independents, independentsHeight, yOffset)
            yOffset = yOffset + independentsHeight + labelHeight
        end
        if #monsters > 0 then
            createTeamList("Monster Roles", monsters, monstersHeight, yOffset)
        end

        dsearch.OnValueChange = function(_, value)
            local query = StringLower(value:gsub("[%p%c%s]", ""))
            for _, panel in pairs(panelList) do
                if StringFind(ROLE_STRINGS_RAW[panel.role], query, 1, true) or value == "" then
                    panel:SetIconColor(COLOR_WHITE)
                    panel:SetBackgroundColor(ROLE_COLORS[panel.role])
                    panel.enabled = true
                else
                    panel:SetIconColor(COLOR_LGRAY)
                    panel:SetBackgroundColor(ROLE_COLORS_DARK[panel.role])
                    panel.enabled = false
                end
            end
        end

        dframe:MakePopup()
        dframe:SetKeyboardInputEnabled(false)
    end
end