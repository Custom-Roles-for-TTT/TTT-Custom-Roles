AddCSLuaFile()

local IsValid = IsValid

DEFINE_BASECLASS "weapon_tttbase"

SWEP.HoldType               = "normal"

if CLIENT then
   SWEP.PrintName           = "Scanner"
   SWEP.Slot                = 8

   SWEP.ViewModelFOV        = 10
   SWEP.ViewModelFlip       = false
   SWEP.DrawCrosshair       = false
end

SWEP.Base                   = "weapon_tttbase"
SWEP.Category               = WEAPON_CATEGORY_ROLE

SWEP.ViewModel                = "models/weapons/v_binoculars.mdl"
SWEP.WorldModel                = "models/weapons/w_binoculars.mdl"

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
SWEP.InLoadoutForDefault    = {ROLE_INFORMANT}

SWEP.AllowDrop              = false

SWEP.ViewModelOffset        = Vector(4, 100, -1)

function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
end

function SWEP:Holster()
    if SERVER and IsValid(self:GetOwner()) then
        local owner = self:GetOwner()
        owner:SetNWInt("TTTInformantScannerState", INFORMANT_SCANNER_IDLE)
        owner:SetNWString("TTTInformantScannerTarget", "")
        owner:SetNWString("TTTInformantScannerMessage", "")
        owner:SetNWFloat("TTTInformantScannerStartTime", -1)
        owner:SetNWFloat("TTTInformantScannerTargetLostTime", -1)
        owner:SetNWFloat("TTTInformantScannerCooldown", -1)
    end
    return true
end

function SWEP:Deploy()
    if SERVER and IsValid(self:GetOwner()) then
        self:GetOwner():DrawViewModel(false)
    end

    self:DrawShadow(false)

    return true
end

if CLIENT then
    function SWEP:Initialize()
        self:AddHUDHelp("infscanner_help_pri", "infscanner_help_sec", true)

        return self.BaseClass.Initialize(self)
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

