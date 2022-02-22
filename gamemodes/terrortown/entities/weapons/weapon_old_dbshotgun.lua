if SERVER then AddCSLuaFile() end

local IsValid = IsValid
local math = math

SWEP.HoldType = "shotgun"

if CLIENT then
    SWEP.PrintName = "Double Barrel"
    SWEP.Slot = 2
end

SWEP.Base = "weapon_tttbase"
SWEP.Category = WEAPON_CATEGORY_ROLE

SWEP.Kind = WEAPON_HEAVY

SWEP.Primary.Ammo = "none"
SWEP.Primary.Damage = 10
SWEP.Primary.Cone = 0.13
SWEP.Primary.Delay = 0.5
SWEP.Primary.ClipSize = 2
SWEP.Primary.ClipMax = 2
SWEP.Primary.DefaultClip = 2
SWEP.Primary.Automatic = true
SWEP.Primary.NumShots = 12
SWEP.Primary.Sound = "weapons/ttt/dbsingle.wav"
SWEP.Primary.Recoil = 15

SWEP.Secondary.Sound = "weapons/ttt/dbblast.wav"
SWEP.Secondary.Recoil = 40

SWEP.AllowDrop = false

SWEP.UseHands = false
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 70
SWEP.ViewModel = "models/weapons/v_doublebarrl.mdl"
SWEP.WorldModel = "models/weapons/w_double_barrel_shotgun.mdl"

SWEP.IronSightsPos = Vector(0, 0, 0)
SWEP.IronSightsAng = Vector(0, 0, 0)

if SERVER then
    CreateConVar("ttt_oldman_adrenaline_shotgun_damage", "10", FCVAR_NONE, "How much damage the double barrel shotgun should do", 0, 100)
end

function SWEP:Initialize()
    self:SetWeaponHoldType(self.HoldType)

    if SERVER then
        SetGlobalInt("ttt_oldman_adrenaline_shotgun_damage", GetConVar("ttt_oldman_adrenaline_shotgun_damage"):GetInt())
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:Deploy()
    self.Primary.Damage = GetGlobalInt("ttt_oldman_adrenaline_shotgun_damage", 10)
end

function SWEP:OnDrop()
   self:Remove()
end

function SWEP:CanPrimaryAttack()
    if self:Clip1() <= 0 then
        self:EmitSound("Weapon_Shotgun.Empty")
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        return false
    end
    return true
end

function SWEP:GetHeadshotMultiplier(victim, dmginfo)
    local att = dmginfo:GetAttacker()
    if not IsValid(att) then return 2 end

    local dist = victim:GetPos():Distance(att:GetPos())
    local d = math.max(0, dist - 140)

    -- decay from 3 to 1 as distance increases
    return 1 + math.max(0, 2 - 0.002 * (d ^ 1.25))
end

function SWEP:SecondaryAttack(worldsnd)
    self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    if self:Clip1() == 2 then
        if not worldsnd then
            self:EmitSound(self.Secondary.Sound, self.Primary.SoundLevel)
        elseif SERVER then
            sound.Play(self.Secondary.Sound, self:GetPos(), self.Primary.SoundLevel)
        end

        self:ShootBullet(self.Primary.Damage, self.Secondary.Recoil, self.Primary.NumShots * 2, self:GetPrimaryCone())
        self:TakePrimaryAmmo(2)

        local owner = self:GetOwner()
        if not IsValid(owner) or owner:IsNPC() or (not owner.ViewPunch) then return end
        owner:ViewPunch(Angle(math.Rand(-0.2, -0.1) * self.Secondary.Recoil, math.Rand(-0.1, 0.1) * self.Secondary.Recoil, 0))
    elseif self:Clip1() == 1 then
        if not worldsnd then
            self:EmitSound(self.Primary.Sound, self.Primary.SoundLevel)
        elseif SERVER then
            sound.Play(self.Primary.Sound, self:GetPos(), self.Primary.SoundLevel)
        end

        self:ShootBullet(self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self:GetPrimaryCone())
        self:TakePrimaryAmmo(1)

        local owner = self:GetOwner()
        if not IsValid(owner) or owner:IsNPC() or (not owner.ViewPunch) then return end
        owner:ViewPunch(Angle(math.Rand(-0.2, -0.1) * self.Primary.Recoil, math.Rand(-0.1, 0.1) * self.Primary.Recoil, 0))
    end
end