AddCSLuaFile()

SWEP.HoldType              = "revolver"
SWEP.ReloadHoldType        = "pistol"

if CLIENT then
   SWEP.PrintName          = "Plague Dart Gun"
   SWEP.Slot               = 8

   SWEP.ViewModelFlip      = false
   SWEP.ViewModelFOV       = 54
end

SWEP.Base                  = "weapon_tttbase"
SWEP.Category              = WEAPON_CATEGORY_ROLE

SWEP.Primary.Recoil        = 1.35
SWEP.Primary.Damage        = 0
SWEP.Primary.Delay         = 0.38
SWEP.Primary.Cone          = 0.02
SWEP.Primary.ClipSize      = 1
SWEP.Primary.Automatic     = true
SWEP.Primary.DefaultClip   = 1
SWEP.Primary.ClipMax       = 1
SWEP.Primary.Ammo          = "none"

SWEP.Kind                  = WEAPON_ROLE
SWEP.InLoadoutFor          = {ROLE_PLAGUEMASTER}

SWEP.AllowDrop             = false
SWEP.IsSilent              = true

SWEP.UseHands              = true
SWEP.ViewModel             = "models/weapons/cstrike/c_pist_usp.mdl"
SWEP.WorldModel            = "models/weapons/w_pist_usp_silencer.mdl"

SWEP.IronSightsPos         = Vector(-5.91, -4, 2.84)
SWEP.IronSightsAng         = Vector(-0.5, 0, 0)

SWEP.PrimaryAnim           = ACT_VM_PRIMARYATTACK_SILENCED
SWEP.ReloadAnim            = ACT_VM_RELOAD_SILENCED

function SWEP:Deploy()
   self:SendWeaponAnim(ACT_VM_DRAW_SILENCED)
   return self.BaseClass.Deploy(self)
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    if not self:CanPrimaryAttack() then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local cone = self.Primary.Cone
    local bullet      = {}
    bullet.Attacker   = owner
    bullet.Inflictor  = self
    bullet.Num        = 1
    bullet.Src        = owner:GetShootPos()
    bullet.Dir        = owner:GetAimVector()
    bullet.Spread     = Vector(cone, cone, 0)
    bullet.Force      = 2
    bullet.Damage     = self.Primary.Damage
    bullet.Callback   = function(attacker, tr, dmginfo)
        if not SERVER then return end
        if not IsValid(owner) then return end
        if not tr.Hit or not tr.HitNonWorld then return end
        if not IsPlayer(tr.Entity) then return end
        if owner:IsRoleAbilityDisabled() then return end

        local victim = tr.Entity
        -- If the target already has the plague, don't try to give it to them again
        if victim.TTTPlaguemasterStartTime then
            owner:QueueMessage(MSG_PRINTBOTH, victim:Nick() .. " already has the plague, find someone new!")
        else
            net.Start("TTT_PlaguemasterPlagued")
                net.WriteString(victim:Nick())
                net.WriteString(owner:Nick())
            net.Broadcast()
            victim:SetProperty("TTTPlaguemasterStartTime", CurTime())
            victim.TTTPlaguemasterOriginalSource = owner:SteamID64()
            self:Remove()
        end

        -- Disable effects so the victim doesn't know they got shot by something
        return { effects = false, damage = false }
    end

    owner:FireBullets(bullet)

    if owner:IsNPC() or (not owner.ViewPunch) then return end
    owner:ViewPunch(Angle(util.SharedRandom(self:GetClass(), -0.2, -0.1, 0) * self.Primary.Recoil, util.SharedRandom(self:GetClass(), -0.1, 0.1, 1) * self.Primary.Recoil, 0))
end

function SWEP:OnDrop()
    self:Remove()
end