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
SWEP.ViewModel = "models/weapons/v_old_doublebarrel.mdl"
SWEP.WorldModel = "models/weapons/w_old_doublebarrel.mdl"

SWEP.IronSightsPos = vector_origin
SWEP.IronSightsAng = vector_origin

local oldman_adrenaline_shotgun_damage = CreateConVar("ttt_oldman_adrenaline_shotgun_damage", "10", FCVAR_REPLICATED, "How much damage the double barrel shotgun should do", 0, 100)

function SWEP:Initialize()
    self:SetWeaponHoldType(self.HoldType)
    return self.BaseClass.Initialize(self)
end

function SWEP:Deploy()
    self.Primary.Damage = oldman_adrenaline_shotgun_damage:GetInt()
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

    local bullets = self:Clip1()
    if bullets == 0 then
        self:CanPrimaryAttack()
        return
    end

    local bulletSound
    local bulletRecoil
    if bullets == 1 then
        bulletSound = self.Primary.Sound
        bulletRecoil = self.Primary.Recoil
    else
        bulletSound = self.Secondary.Sound
        bulletRecoil = self.Secondary.Recoil
    end

    if not worldsnd then
        self:EmitSound(bulletSound, self.Primary.SoundLevel)
    elseif SERVER then
        sound.Play(bulletSound, self:GetPos(), self.Primary.SoundLevel)
    end

    self:ShootBullet(self.Primary.Damage, bulletRecoil, self.Primary.NumShots * bullets, self:GetPrimaryCone())
    self:TakePrimaryAmmo(bullets)

    local owner = self:GetOwner()
    if not IsValid(owner) or owner:IsNPC() or not owner.ViewPunch then return end
    owner:ViewPunch(Angle(math.Rand(-0.2, -0.1) * bulletRecoil, math.Rand(-0.1, 0.1) * bulletRecoil, 0))
end