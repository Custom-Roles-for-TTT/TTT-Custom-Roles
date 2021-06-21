SWEP.HoldType  = "melee"

if CLIENT then
    SWEP.PrintName = "kil_crowbar_name"
    SWEP.Slot = 0

    SWEP.DrawCrosshair = false
    SWEP.ViewModelFlip = false
    SWEP.ViewModelFOV = 54

    SWEP.EquipMenuData = {type = "item_weapon", desc = "kil_crowbar_desc"};

    SWEP.Icon = "vgui/ttt/icon_cbar"
end

SWEP.Base = "weapon_tttbase"
SWEP.HeadshotMultiplier = 10

SWEP.UseHands                = true
SWEP.ViewModel               = "models/weapons/c_crowbar.mdl"
SWEP.WorldModel              = "models/weapons/w_crowbar.mdl"

SWEP.Primary.Damage          = 20
SWEP.Primary.ClipSize        = -1
SWEP.Primary.DefaultClip     = -1
SWEP.Primary.Automatic       = true
SWEP.Primary.Delay           = 0.5
SWEP.Primary.Ammo            = "none"

SWEP.Secondary.ClipSize      = -1
SWEP.Secondary.DefaultClip   = -1
SWEP.Secondary.Automatic     = true
SWEP.Secondary.Ammo          = "none"
SWEP.Secondary.Delay         = 1

SWEP.IsGrenade = false

SWEP.Kind                   = WEAPON_MELEE
SWEP.WeaponID               = AMMO_CROWBAR

SWEP.NoSights                = true
SWEP.IsSilent                = true

SWEP.Weight                  = 5
SWEP.AutoSpawnable           = false

SWEP.AllowDelete             = true
SWEP.AllowDrop = true

local sound_single = Sound("Weapon_Crowbar.Single")

function SWEP:Initialize()
    self:SetWeaponHoldType(self.HoldType)
    self.CanFire = true
    self:SetDeploySpeed(self.DeploySpeed)
    self.was_thrown = false
    if CLIENT then
        self.ModelEntity = ClientsideModel(self.WorldModel)
        self.ModelEntity:SetNoDraw(true)
    end
end

function SWEP:PrimaryAttack()
    self.Weapon:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    if not IsValid(self:GetOwner()) then return end

    if self:GetOwner().LagCompensation then -- for some reason not always true
        self:GetOwner():LagCompensation(true)
    end

    local spos = self:GetOwner():GetShootPos()
    local sdest = spos + (self:GetOwner():GetAimVector() * 70)

    local tr_main = util.TraceLine({
        start = spos,
        endpos = sdest,
        filter = self:GetOwner(),
        mask = MASK_SHOT_HULL
    })
    local hitEnt = tr_main.Entity

    self.Weapon:EmitSound(sound_single)

    if IsValid(hitEnt) or tr_main.HitWorld then
        self.Weapon:SendWeaponAnim(ACT_VM_HITCENTER)

        if not (CLIENT and (not IsFirstTimePredicted())) then
            local edata = EffectData()
            edata:SetStart(spos)
            edata:SetOrigin(tr_main.HitPos)
            edata:SetNormal(tr_main.Normal)
            edata:SetSurfaceProp(tr_main.SurfaceProps)
            edata:SetHitBox(tr_main.HitBox)
            edata:SetEntity(hitEnt)

            if hitEnt:IsPlayer() or hitEnt:GetClass() == "prop_ragdoll" then
                util.Effect("BloodImpact", edata)
                -- do a bullet just to make blood decals work sanely
                -- need to disable lagcomp because firebullets does its own
                self:GetOwner():LagCompensation(false)
                self:GetOwner():FireBullets({Num=1, Src=spos, Dir=self:GetOwner():GetAimVector(), Spread=Vector(0,0,0), Tracer=0, Force=1, Damage=0})
            else
                util.Effect("Impact", edata)
            end
        end
    else
        self.Weapon:SendWeaponAnim(ACT_VM_MISSCENTER)
    end

    if SERVER then
        self:GetOwner():SetAnimation(PLAYER_ATTACK1)

        if hitEnt and hitEnt:IsValid() then
            local dmg = DamageInfo()
            dmg:SetDamage(self.Primary.Damage)
            dmg:SetAttacker(self:GetOwner())
            dmg:SetInflictor(self.Weapon)
            dmg:SetDamageForce(self:GetOwner():GetAimVector() * 1500)
            dmg:SetDamagePosition(self:GetOwner():GetPos())
            dmg:SetDamageType(DMG_CLUB)

            hitEnt:DispatchTraceAttack(dmg, spos + (self:GetOwner():GetAimVector() * 3), sdest)
        end
    end

    if self:GetOwner().LagCompensation then
        self:GetOwner():LagCompensation(false)
    end
end

function SWEP:Throw()
    if not SERVER then return end

    self:ShootEffects()
    self.BaseClass.ShootEffects(self)

    self.Weapon:SendWeaponAnim(ACT_VM_THROW)
    self.CanFire = false

    local ent = ents.Create("ttt_kil_crowbar")

    ent:SetOwner(self:GetOwner())
    ent:SetPos(self.Owner:EyePos() + (self.Owner:GetAimVector() * 16))
    ent:SetAngles(self.Owner:EyeAngles())
    ent:Spawn()

    local phys = ent:GetPhysicsObject()

    phys:ApplyForceCenter(self.Owner:GetAimVector():GetNormalized() * 1300)

    self:Remove()
end

function SWEP:SecondaryAttack()
    if (self.CanFire) then
        self:Throw()
    end
end
