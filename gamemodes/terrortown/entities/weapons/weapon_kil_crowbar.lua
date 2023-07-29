local ents = ents
local IsValid = IsValid
local util = util

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
SWEP.Category = WEAPON_CATEGORY_ROLE

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

local killer_crowbar_damage = CreateConVar("ttt_killer_crowbar_damage", "20", FCVAR_REPLICATED, "How much damage the crowbar should do when the killer bashes another player with it. Server or round must be restarted for changes to take effect", 1, 100)
if SERVER then
    CreateConVar("ttt_killer_crowbar_thrown_damage", "50", FCVAR_NONE, "How much damage the crowbar should do when the killer throws it at another player. Server or round must be restarted for changes to take effect", 1, 100)
end

function SWEP:Initialize()
    self.CanFire = true
    self.was_thrown = false

    if CLIENT then
        self.ModelEntity = ClientsideModel(self.WorldModel)
        self.ModelEntity:SetNoDraw(true)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:Deploy()
    self.Primary.Damage = killer_crowbar_damage:GetInt()
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    if owner.LagCompensation then -- for some reason not always true
        owner:LagCompensation(true)
    end

    local spos = owner:GetShootPos()
    local sdest = spos + (owner:GetAimVector() * 70)

    local tr_main = util.TraceLine({
        start = spos,
        endpos = sdest,
        filter = owner,
        mask = MASK_SHOT_HULL
    })
    local hitEnt = tr_main.Entity

    self:EmitSound(sound_single)

    if IsValid(hitEnt) or tr_main.HitWorld then
        self:SendWeaponAnim(ACT_VM_HITCENTER)

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
                owner:LagCompensation(false)
                owner:FireBullets({Num=1, Src=spos, Dir=owner:GetAimVector(), Spread=Vector(0,0,0), Tracer=0, Force=1, Damage=0})
            else
                util.Effect("Impact", edata)
            end
        end
    else
        self:SendWeaponAnim(ACT_VM_MISSCENTER)
    end

    if SERVER then
        owner:SetAnimation(PLAYER_ATTACK1)

        if IsValid(hitEnt) then
            local dmg = DamageInfo()
            dmg:SetDamage(self.Primary.Damage)
            dmg:SetAttacker(owner)
            dmg:SetInflictor(self)
            dmg:SetDamageForce(owner:GetAimVector() * 1500)
            dmg:SetDamagePosition(owner:GetPos())
            dmg:SetDamageType(DMG_CLUB)

            hitEnt:DispatchTraceAttack(dmg, spos + (owner:GetAimVector() * 3), sdest)
        end
    end

    if owner.LagCompensation then
        owner:LagCompensation(false)
    end
end

function SWEP:Throw()
    if not SERVER then return end

    self:ShootEffects()
    self.BaseClass.ShootEffects(self)

    self:SendWeaponAnim(ACT_VM_THROW)
    self.CanFire = false

    local ent = ents.Create("ttt_kil_crowbar")
    ent:SetDamage(GetConVar("ttt_killer_crowbar_thrown_damage"):GetInt())

    local owner = self:GetOwner()
    ent:SetOwner(owner)
    ent:SetPos(owner:EyePos() + (owner:GetAimVector() * 16))
    ent:SetAngles(owner:EyeAngles())
    ent:Spawn()

    local phys = ent:GetPhysicsObject()
    phys:ApplyForceCenter(owner:GetAimVector():GetNormalized() * 1300)

    self:Remove()
end

function SWEP:SecondaryAttack()
    if self.CanFire then
        self:Throw()
    end
end
