AddCSLuaFile()

local IsValid = IsValid
local math = math
local pairs = pairs
local player = player
local surface = surface
local string = string

local GetAllPlayers = player.GetAll

DEFINE_BASECLASS "weapon_tttbase"

SWEP.HoldType               = "normal"

if SERVER then
    resource.AddFile("models/weapons/v_binoculars.mdl")
    resource.AddFile("models/weapons/w_binoculars.mdl")
    resource.AddFile("materials/models/weapons/v_binoculars/binocular2.vmt")
end

if CLIENT then
   SWEP.PrintName           = "Scanner"
   SWEP.Slot                = 8

   SWEP.ViewModelFOV        = 10
   SWEP.ViewModelFlip       = false
   SWEP.DrawCrosshair       = false
end

SWEP.Base                   = "weapon_tttbase"
SWEP.Category               = WEAPON_CATEGORY_ROLE

SWEP.ViewModel		        = "models/weapons/v_binoculars.mdl"
SWEP.WorldModel		        = "models/weapons/w_binoculars.mdl"

SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = false
SWEP.Primary.Ammo           = "none"
SWEP.Primary.Delay          = 0

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = true
SWEP.Secondary.Ammo         = "none"
SWEP.Secondary.Delay        = 0

SWEP.Kind                   = WEAPON_ROLE

SWEP.InLoadoutFor           = {ROLE_INFORMANT}

SWEP.AllowDrop              = false

SWEP.ViewModelOffset        = Vector(4, 100, -1)

local SCANNER_IDLE = 0
local SCANNER_LOCKED = 1
local SCANNER_SEARCHING = 2
local SCANNER_LOST = 3

if SERVER then
    CreateConVar("ttt_informant_scanner_time", "8", FCVAR_NONE, "The amount of time (in seconds) the informant's scanner takes to use", 0, 60)
    CreateConVar("ttt_informant_scanner_float_time", "1", FCVAR_NONE, "The amount of time (in seconds) it takes for the informant's scanner to lose it's target without line of sight", 0, 60)
    CreateConVar("ttt_informant_scanner_cooldown", "3", FCVAR_NONE, "The amount of time (in seconds) the informant's tracker goes on cooldown for after losing it's target", 0, 60)
end

function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "State")
    self:NetworkVar("Int", 1, "ScanTime")
    self:NetworkVar("String", 0, "Target")
    self:NetworkVar("String", 1, "Message")
    self:NetworkVar("Float", 0, "ScanStart")
    self:NetworkVar("Float", 1, "TargetLost")
    self:NetworkVar("Float", 2, "Cooldown")

    if SERVER then
        self:SetScanTime(GetConVar("ttt_informant_scanner_time"):GetInt())
    end
end

function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
end

function SWEP:Holster()
    self:SetState(SCANNER_IDLE)
    self:SetTarget("")
    self:SetMessage("")
    self:SetScanStart(-1)
    self:SetTargetLost(-1)
    self:SetCooldown(-1)
    return true
end

function SWEP:Deploy()
    if SERVER and IsValid(self:GetOwner()) then
        self:GetOwner():DrawViewModel(false)
    end

    self:DrawShadow(false)

    return true
end

if SERVER then
    function SWEP:IsTargetingPlayer()
        local tr = self:GetOwner():GetEyeTrace(MASK_SHOT)
        local ent = tr.Entity

        return (IsPlayer(ent) and ent:IsActive()) and ent or false
    end

    function SWEP:TargetLost()
        self:SetState(SCANNER_LOST)
        self:SetTarget("")
        self:SetScanStart(-1)
        self:SetCooldown(CurTime())
        self:SetMessage("TARGET LOST")
    end

    function SWEP:Announce(message)
        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        owner:PrintMessage(HUD_PRINTTALK, "You have " .. message)
        if not GetGlobalBool("ttt_informant_share_scans", true) then return end

        for _, p in pairs(GetAllPlayers()) do
            if p:IsActiveTraitorTeam() and p ~= owner then
                p:PrintMessage(HUD_PRINTTALK, "The informant has " .. message)
            end
        end
    end

    function SWEP:InRange(target)
        if not self:GetOwner():IsLineOfSightClear(target) then return false end

        local ownerPos = self:GetOwner():GetPos()
        local targetPos = target:GetPos()
        if ownerPos:Distance(targetPos) > 2500 then return false end

        local dir = targetPos - ownerPos
        dir:Normalize()
        local eye = self:GetOwner():EyeAngles():Forward()
        if math.acos(dir:Dot(eye)) > 0.35 then return false end

        return true
    end

    function SWEP:ScanAllowed(target)
        if not IsPlayer(target) then return false end
        if not target:IsActive() then return false end
        if not self:InRange(target) then return false end
        if target:IsJesterTeam() and not GetConVar("ttt_informant_can_scan_jesters"):GetBool() then return false end
        if (target:IsGlitch() or target:IsTraitorTeam()) then
            if not GetConVar("ttt_informant_can_scan_glitches"):GetBool() then return false end
            if target:IsGlitch() then return true end
            local glitchMode = GetConVar("ttt_glitch_mode"):GetInt()
            if GetGlobalBool("ttt_glitch_round", false) and ((glitchMode == GLITCH_SHOW_AS_TRAITOR and target:IsTraitor()) or glitchMode >= GLITCH_SHOW_AS_SPECIAL_TRAITOR) then
                return true
            else
                return false
            end
        end
        return true
    end

    function SWEP:Scan(target)
        if target:IsActive() then
            local stage = target:GetNWInt("TTTInformantScanStage", INFORMANT_UNSCANNED)
            if CurTime() - self:GetScanStart() >= GetConVar("ttt_informant_scanner_time"):GetInt() then
                stage = stage + 1
                if stage == INFORMANT_SCANNED_TEAM then
                    local message = "discovered that " .. target:Nick() .. " is "
                    if target:IsInnocentTeam() then
                        message = message .. "an innocent role."
                    elseif target:IsIndependentTeam() then
                        message = message .. "an independent role."
                    elseif target:IsMonsterTeam() then
                        message = message .. "a monster role."
                    end

                    self:Announce(message)
                    self:SetScanStart(CurTime())
                elseif stage == INFORMANT_SCANNED_ROLE then
                    self:Announce("discovered that " .. target:Nick() .. " is " .. ROLE_STRINGS_EXT[target:GetRole()] .. ".")
                    self:SetScanStart(CurTime())
                elseif stage == INFORMANT_SCANNED_TRACKED then
                    self:Announce("tracked the movements of " .. target:Nick() .. " (" .. ROLE_STRINGS[target:GetRole()] .. ").")
                    self:SetState(SCANNER_IDLE)
                    self:SetTarget("")
                    self:SetScanStart(-1)
                    self:SetMessage("")
                end
                target:SetNWInt("TTTInformantScanStage", stage)
            end
        else
            self:TargetLost()
        end
    end

    function SWEP:Think()
        local state = self:GetState()
        if state == SCANNER_IDLE then
            local target = self:IsTargetingPlayer()
            if target then
                if target:GetNWInt("TTTInformantScanStage", INFORMANT_UNSCANNED) < INFORMANT_SCANNED_TRACKED and self:ScanAllowed(target) then
                    self:SetState(SCANNER_LOCKED)
                    self:SetTarget(target:SteamID64())
                    self:SetScanStart(CurTime())
                    self:SetMessage("SCANNING " .. string.upper(target:Nick()))
                end
            end
        elseif state == SCANNER_LOCKED then
            local target = player.GetBySteamID64(self:GetTarget())
            if target:IsActive() then
                if not self:InRange(target) then
                    self:SetState(SCANNER_SEARCHING)
                    self:SetTargetLost(CurTime())
                    self:SetMessage("SCANNING " .. string.upper(target:Nick()) .. " (LOSING TARGET)")
                end
                self:Scan(target)
            else
                self:TargetLost()
            end
        elseif state == SCANNER_SEARCHING then
            local target = player.GetBySteamID64(self:GetTarget())
            if target:IsActive() then
                if (CurTime() - self:GetTargetLost()) >= GetConVar("ttt_informant_scanner_float_time"):GetInt() then
                    self:TargetLost()
                else
                    if self:InRange(target) then
                        self:SetState(SCANNER_LOCKED)
                        self:SetTargetLost(-1)
                        self:SetMessage("SCANNING " .. string.upper(target:Nick()))
                    end
                    self:Scan(target)
                end
            else
                self:TargetLost()
            end
        elseif state == SCANNER_LOST then
            if (CurTime() - self:GetCooldown()) >= GetConVar("ttt_informant_scanner_cooldown"):GetInt() then
                self:SetState(SCANNER_IDLE)
                self:SetCooldown(-1)
                self:SetMessage("")
            end
        end
    end
end

if CLIENT then
    function SWEP:Initialize()
        self:AddHUDHelp("infscanner_help_pri", "infscanner_help_sec", true)

        return self.BaseClass.Initialize(self)
    end

    function SWEP:DrawStructure(x, y, w, h, m, color)
        local r, g, b, a = color:Unpack()
        surface.SetDrawColor(r, g, b, a)
        surface.DrawCircle(x, ScrH() / 2, math.Round(ScrW() / 6), r, g, b, a)

        surface.DrawOutlinedRect(x - m - (3 * w) / 2, y - h, w, h)
        surface.DrawOutlinedRect(x - w / 2, y - h, w, h)
        surface.DrawOutlinedRect(x + m + w / 2, y - h, w, h)

        surface.SetFont("TabLarge")
        surface.SetTextColor(255, 255, 255, 180)
        surface.SetTextPos((x - m - (3 * w) / 2) + 3, y - h - 15)
        surface.DrawText(self:GetMessage())

        local T = LANG.GetTranslation
        surface.SetTextPos((x - m - (3 * w) / 2) +  (w / 3), y - h + 3)
        surface.DrawText(T("infscanner_team"))

        surface.SetTextPos((x - m - (3 * w) / 2) + w + (w / 2) - 3, y - h + 3)
        surface.DrawText(T("infscanner_role"))

        surface.SetTextPos((x - m - (3 * w) / 2) + (2 * w) + (w / 2), y - h + 3)
        surface.DrawText(T("infscanner_track"))
    end

    function SWEP:DrawHUD()
        local state = self:GetState()
        self.BaseClass.DrawHUD(self)

        if state == SCANNER_IDLE then
            surface.DrawCircle(ScrW() / 2, ScrH() / 2, math.Round(ScrW() / 6), 0, 255, 0, 155)
            return
        end

        local scan = self:GetScanTime()
        local time = self:GetScanStart() + scan

        local x = ScrW() / 2.0
        local y = ScrH() / 2.0

        y = y + (y / 3)

        local w, h = 100, 20
        local m = 10

        if state == SCANNER_LOCKED or state == SCANNER_SEARCHING then
            if time < 0 then return end

            local color = Color(255, 255, 0, 155)
            if state == SCANNER_LOCKED then
                color = Color(0, 255, 0, 155)
            end

            self:DrawStructure(x, y, w, h, m, color)

            local target = player.GetBySteamID64(self:GetTarget())
            local targetState = target:GetNWInt("TTTInformantScanStage", INFORMANT_UNSCANNED)

            local cc = math.min(1, 1 - ((time - CurTime()) / scan))
            if targetState == INFORMANT_UNSCANNED then
                surface.DrawRect(x - m - (3 * w) / 2, y - h, w * cc, h)
            elseif targetState == INFORMANT_SCANNED_TEAM then
                surface.DrawRect(x - m - (3 * w) / 2, y - h, w, h)
                surface.DrawRect(x - w / 2, y - h, w * cc, h)
            elseif targetState == INFORMANT_SCANNED_ROLE then
                surface.DrawRect(x - m - (3 * w) / 2, y - h, w, h)
                surface.DrawRect(x - w / 2, y - h, w, h)
                surface.DrawRect(x + m + w / 2, y - h, w * cc, h)
            end
        elseif state == SCANNER_LOST then
            local color = Color(200 + math.sin(CurTime() * 32) * 50, 0, 0, 155)
            self:DrawStructure(x, y, w, h, m, color)

            surface.DrawRect(x - m - (3 * w) / 2, y - h, w, h)
            surface.DrawRect(x - w / 2, y - h, w, h)
            surface.DrawRect(x + m + w / 2, y - h, w, h)
        end
    end

    function SWEP:DrawWorldModel()
    end

    function SWEP:GetViewModelPosition(pos, ang)
        local right = ang:Right()
        local up = ang:Up()
        local forward = ang:Forward()
        local offset = self.ViewModelOffset

        pos = pos + offset.x * right
        pos = pos + offset.y * forward
        pos = pos + offset.z * up

        return pos, ang
    end
end

