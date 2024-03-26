AddCSLuaFile()

SWEP.HoldType              = "pistol"

if CLIENT then
   SWEP.PrintName          = "flare_name"
   SWEP.Slot               = 8

   SWEP.ViewModelFOV       = 54
   SWEP.ViewModelFlip      = false

   SWEP.EquipMenuData = {
      type = "item_weapon",
      desc = "flare_desc"
   };

   SWEP.Icon               = "vgui/ttt/icon_flare"
end

SWEP.Base                  = "weapon_tttbase"
SWEP.Category              = WEAPON_CATEGORY_ROLE

-- if I run out of ammo types, this weapon is one I could move to a custom ammo
-- handling strategy, because you never need to pick up ammo for it
SWEP.Primary.Ammo          = "AR2AltFire"
SWEP.Primary.Recoil        = 4
SWEP.Primary.Damage        = 7
SWEP.Primary.Delay         = 1.0
SWEP.Primary.Cone          = 0.01
SWEP.Primary.ClipSize      = 4
SWEP.Primary.Automatic     = false
SWEP.Primary.DefaultClip   = 4
SWEP.Primary.ClipMax       = 4
SWEP.Primary.Sound         = Sound("Weapon_USP.SilencedShot")

SWEP.InLoadoutFor          = {ROLE_SPY}
SWEP.InLoadoutForDefault   = {ROLE_SPY}

SWEP.Kind                  = WEAPON_ROLE
SWEP.CanBuy                = {} -- only traitors can buy
SWEP.LimitedStock          = true -- only buyable once
SWEP.AllowDrop             = false
SWEP.WeaponID              = AMMO_FLARE

SWEP.Tracer                = "AR2Tracer"

SWEP.UseHands              = true
SWEP.ViewModel             = Model("models/weapons/c_357.mdl")
SWEP.WorldModel            = Model("models/weapons/w_357.mdl")

function SWEP:ShootFlare()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local cone = self.Primary.Cone
    local bullet      = {}
    bullet.Num        = 1
    bullet.Src        = owner:GetShootPos()
    bullet.Dir        = owner:GetAimVector()
    bullet.Spread     = Vector(cone, cone, 0)
    bullet.Tracer     = 1
    bullet.Force      = 2
    bullet.Damage     = self.Primary.Damage
    bullet.TracerName = self.Tracer
    bullet.Callback   = IgniteTarget

    owner:FireBullets(bullet)
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    if not self:CanPrimaryAttack() then return end

    self:EmitSound(self.Primary.Sound)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

    self:ShootFlare()
    self:TakePrimaryAmmo(1)

    local owner = self:GetOwner()
    if IsValid(owner) then
        owner:SetAnimation(PLAYER_ATTACK1)
        owner:ViewPunch(Angle(math.Rand(-0.2,-0.1) * self.Primary.Recoil, math.Rand(-0.1,0.1) * self.Primary.Recoil, 0))
    end

    if ((game.SinglePlayer() and SERVER) or CLIENT) then
        self:SetNWFloat("LastShootTime", CurTime())
    end

    if SERVER and self:Clip1() <= 0 then
        if IsPlayer(owner) then
            owner:ConCommand("lastinv")
        end

        self:Remove()
    end
end

function SWEP:SecondaryAttack()
end

function SWEP:OnDrop()
    self:Remove()
end