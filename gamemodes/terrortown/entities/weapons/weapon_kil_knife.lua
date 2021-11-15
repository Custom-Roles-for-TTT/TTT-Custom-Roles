AddCSLuaFile()

SWEP.HoldType = "knife"

if CLIENT then
    SWEP.PrintName = "knife_name"
    SWEP.Slot = 6

    SWEP.ViewModelFlip = false
    SWEP.ViewModelFOV = 54
    SWEP.DrawCrosshair = false

    SWEP.EquipMenuData = {type = "item_weapon", desc = "kil_knife_desc"};

    SWEP.Icon = "vgui/ttt/icon_knife"
    SWEP.IconLetter = "j"
end

SWEP.Base                   = "weapon_tttbase"
SWEP.Category               = WEAPON_CATEGORY_ROLE

SWEP.UseHands               = true
SWEP.ViewModel              = "models/weapons/cstrike/c_knife_t.mdl"
SWEP.WorldModel             = "models/weapons/w_knife_t.mdl"

SWEP.Primary.Damage         = 65
SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = true
SWEP.Primary.Delay          = 0.8
SWEP.Primary.Ammo           = "none"

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo         = "none"
SWEP.Secondary.Delay        = 12

SWEP.Kind                    = WEAPON_NONE
SWEP.WeaponID                = AMMO_CROWBAR

SWEP.IsSilent               = true

SWEP.AllowDelete             = true -- never removed for weapon reduction
SWEP.AllowDrop = false

-- Pull out faster than standard guns
SWEP.DeploySpeed = 2

if SERVER then
    local killer_knife_damage = CreateConVar("ttt_killer_knife_damage", "65")
    local killer_knife_delay = CreateConVar("ttt_killer_knife_delay", "0.8")

    function SWEP:Initialize()
        SetGlobalInt("ttt_killer_knife_damage", killer_knife_damage:GetInt())
        SetGlobalFloat("ttt_killer_knife_delay", killer_knife_delay:GetFloat())
        return self.BaseClass.Initialize(self)
    end
end

function SWEP:Deploy()
    self.Primary.Damage = GetGlobalInt("ttt_killer_knife_damage", 65)
    self.Primary.Delay = GetGlobalFloat("ttt_killer_knife_delay", 0.8)
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    owner:LagCompensation(true)

    local spos = owner:GetShootPos()
    local sdest = spos + (owner:GetAimVector() * 70)

    local kmins = Vector(1, 1, 1) * -10
    local kmaxs = Vector(1, 1, 1) * 10

    local tr = util.TraceHull({start=spos, endpos=sdest, filter=owner, mask=MASK_SHOT_HULL, mins=kmins, maxs=kmaxs})

    -- Hull might hit environment stuff that line does not hit
    if not IsValid(tr.Entity) then
        tr = util.TraceLine({start=spos, endpos=sdest, filter=owner, mask=MASK_SHOT_HULL})
    end

    local hitEnt = tr.Entity

    -- effects
    if IsValid(hitEnt) then
        self:SendWeaponAnim(ACT_VM_HITCENTER)

        local edata = EffectData()
        edata:SetStart(spos)
        edata:SetOrigin(tr.HitPos)
        edata:SetNormal(tr.Normal)
        edata:SetEntity(hitEnt)

        if hitEnt:IsPlayer() or hitEnt:GetClass() == "prop_ragdoll" then
            owner:SetAnimation(PLAYER_ATTACK1)
            self:SendWeaponAnim(ACT_VM_MISSCENTER)
            util.Effect("BloodImpact", edata)
        end
    else
        self:SendWeaponAnim(ACT_VM_MISSCENTER)
    end

    if SERVER then owner:SetAnimation(PLAYER_ATTACK1) end

    if SERVER and tr.Hit and tr.HitNonWorld and IsPlayer(hitEnt) then
        -- knife damage is never karma'd, so don't need to take that into
        -- account we do want to avoid rounding error strangeness caused by
        -- other damage scaling, causing a death when we don't expect one, so
        -- when the target's health is close to kill-point we just kill
        if hitEnt:Health() < (self.Primary.Damage + 10) then
            self:StabKill(tr, spos, sdest)
        else
            local dmg = DamageInfo()
            dmg:SetDamage(self.Primary.Damage)
            dmg:SetAttacker(owner)
            dmg:SetInflictor(self)
            dmg:SetDamageForce(owner:GetAimVector() * 5)
            dmg:SetDamagePosition(owner:GetPos())
            dmg:SetDamageType(DMG_SLASH)

            hitEnt:DispatchTraceAttack(dmg, spos + (owner:GetAimVector() * 3), sdest)
        end
    end

    owner:LagCompensation(false)
end

function SWEP:StabKill(tr, spos, sdest)
    local target = tr.Entity

    local owner = self:GetOwner()
    local dmg = DamageInfo()
    dmg:SetDamage(2000)
    dmg:SetAttacker(owner)
    dmg:SetInflictor(self)
    dmg:SetDamageForce(owner:GetAimVector())
    dmg:SetDamagePosition(owner:GetPos())
    dmg:SetDamageType(DMG_SLASH)
    target:TakeDamageInfo(dmg)
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
    if not IsFirstTimePredicted() then return end
    self:SetNextPrimaryFire(CurTime() + 1)

    if CLIENT then return end

    local owner = self:GetOwner()
    local nade = ents.Create("tot_smokenade")
    nade.HmcdSpawned = self.HmcdSpawned
    nade:SetPos(owner:GetShootPos() + owner:GetAimVector() * 20)
    nade:Spawn()
    nade:Activate()
    nade:GetPhysicsObject():SetVelocity(owner:GetVelocity() + owner:GetAimVector() * 300)
    sound.Play("snd_jack_hmcd_match.wav", self:GetPos(), 65, math.random(90, 110))
    sound.Play("weapons/slam/throw.wav", self:GetPos(), 65, math.random(90, 110))
end

function SWEP:OnDrop()
    self:Remove()
end

if CLIENT then
    local T = LANG.GetTranslation
    function SWEP:DrawHUD()
       local tr = self:GetOwner():GetEyeTrace(MASK_SHOT)

       if tr.HitNonWorld and IsPlayer(tr.Entity)
          and tr.Entity:Health() < (self.Primary.Damage + 10) then

          local x = ScrW() / 2.0
          local y = ScrH() / 2.0

          surface.SetDrawColor(255, 0, 0, 255)

          local outer = 20
          local inner = 10
          surface.DrawLine(x - outer, y - outer, x - inner, y - inner)
          surface.DrawLine(x + outer, y + outer, x + inner, y + inner)

          surface.DrawLine(x - outer, y + outer, x - inner, y + inner)
          surface.DrawLine(x + outer, y - outer, x + inner, y - inner)

          draw.SimpleText(T("knife_instant"), "TabLarge", x, y - 30, COLOR_RED, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
       end

       return self.BaseClass.DrawHUD(self)
    end
 end