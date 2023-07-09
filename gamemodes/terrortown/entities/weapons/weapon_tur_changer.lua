if CLIENT then
    SWEP.PrintName          = "tur_changer"
    SWEP.Slot               = 7

    SWEP.ViewModelFOV       = 60
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
SWEP.InLoadoutFor           = {ROLE_TURNCOAT}

SWEP.Primary.Delay          = 0.25
SWEP.Primary.Automatic      = false
SWEP.Primary.Cone           = 0
SWEP.Primary.Ammo           = nil
SWEP.Primary.Sound          = ""

function SWEP:Initialize()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)

    if CLIENT then
        self:AddHUDHelp("tur_changer_help_pri", "tur_changer_help_sec", true)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:Equip()
end

function SWEP:Deploy()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
    return true
end

function SWEP:PrimaryAttack()
    if self:GetNextPrimaryFire() > CurTime() then return end
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DETONATE)

    if SERVER then
        local owner = self:GetOwner()
        if IsPlayer(owner) then
            owner:ChangeTurncoatTeam()
            self:Remove()
        end
    end
end

function SWEP:SecondaryAttack()
end

function SWEP:OnDrop()
    self:Remove()
end