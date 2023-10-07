AddCSLuaFile()

local IsValid = IsValid
local math = math
local util = util

if SERVER then
    util.AddNetworkString("TTT_ZombieLeapStart")
    util.AddNetworkString("TTT_ZombieLeapEnd")
end

if CLIENT then
    SWEP.PrintName = "Claws"
    SWEP.EquipMenuData = {
        type = "Weapon",
        desc = "Left click to attack. Right click to leap. Press reload to spit."
    };

    SWEP.Slot = 8 -- add 1 to get the slot number key
    SWEP.ViewModelFOV = 54
    SWEP.ViewModelFlip = false
end

SWEP.InLoadoutFor = { ROLE_ZOMBIE }

SWEP.Base = "weapon_tttbase"
SWEP.Category = WEAPON_CATEGORY_ROLE

SWEP.HoldType = "fist"

SWEP.ViewModel = Model("models/weapons/c_arms.mdl")
SWEP.WorldModel = ""

SWEP.HitDistance = 250

SWEP.Primary.Damage = 65
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 0.7

SWEP.Secondary.ClipSize = 5
SWEP.Secondary.DefaultClip = 5
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Delay = 2

SWEP.Tertiary = {}
SWEP.Tertiary.Damage = 25
SWEP.Tertiary.NumShots = 1
SWEP.Tertiary.Recoil = 5
SWEP.Tertiary.Cone = 0.02
SWEP.Tertiary.Delay = 3

SWEP.Kind = WEAPON_ROLE

SWEP.UseHands = true
SWEP.AllowDrop = false
SWEP.IsSilent = false

SWEP.NextReload = CurTime()

-- Pull out faster than standard guns
SWEP.DeploySpeed = 2
local sound_single = Sound("Weapon_Crowbar.Single")

local zombie_leap_enable = CreateConVar("ttt_zombie_leap_enable", "1", FCVAR_REPLICATED)
local zombie_spit_enable = CreateConVar("ttt_zombie_spit_enable", "1", FCVAR_REPLICATED)
local zombie_prime_attack_damage = CreateConVar("ttt_zombie_prime_attack_damage", "65", FCVAR_REPLICATED, "The amount of a damage a prime zombie (e.g. player who spawned as a zombie originally) does with their claws. Server or round must be restarted for changes to take effect", 1, 100)
local zombie_thrall_attack_damage = CreateConVar("ttt_zombie_thrall_attack_damage", "45", FCVAR_REPLICATED, "The amount of a damage a zombie thrall (e.g. non-prime zombie) does with their claws. Server or round must be restarted for changes to take effect", 1, 100)
local zombie_prime_attack_delay = CreateConVar("ttt_zombie_prime_attack_delay", "0.7", FCVAR_REPLICATED, "The amount of time between claw attacks for a prime zombie (e.g. player who spawned as a zombie originally). Server or round must be restarted for changes to take effect", 0.1, 3)
local zombie_thrall_attack_delay = CreateConVar("ttt_zombie_thrall_attack_delay", "1.4", FCVAR_REPLICATED, "The amount of time between claw attacks for a zombie thrall (e.g. non-prime zombie). Server or round must be restarted for changes to take effect", 0.1, 3)

function SWEP:Initialize()
    if CLIENT then
        self:AddHUDHelp("zom_claws_help_pri", "zom_claws_help_sec", true)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:SetWeaponHoldType(t)
    self.BaseClass.SetWeaponHoldType(self, t)

    self.ActivityTranslate[ACT_MP_STAND_IDLE]                  = ACT_HL2MP_IDLE_ZOMBIE
    self.ActivityTranslate[ACT_MP_WALK]                        = ACT_HL2MP_WALK_ZOMBIE_01
    self.ActivityTranslate[ACT_MP_RUN]                         = ACT_HL2MP_RUN_ZOMBIE
    self.ActivityTranslate[ACT_MP_CROUCH_IDLE]                 = ACT_HL2MP_IDLE_CROUCH_ZOMBIE
    self.ActivityTranslate[ACT_MP_CROUCHWALK]                  = ACT_HL2MP_WALK_CROUCH_ZOMBIE_01
    self.ActivityTranslate[ACT_MP_ATTACK_STAND_PRIMARYFIRE]    = ACT_GMOD_GESTURE_RANGE_ZOMBIE
    self.ActivityTranslate[ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]   = ACT_GMOD_GESTURE_RANGE_ZOMBIE
    self.ActivityTranslate[ACT_RANGE_ATTACK1]                  = ACT_GMOD_GESTURE_RANGE_ZOMBIE
end

function SWEP:PlayAnimation(sequence, anim)
    local owner = self:GetOwner()
    local vm = owner:GetViewModel()
    vm:SendViewModelMatchingSequence(vm:LookupSequence(anim))
    owner:SetAnimation(sequence)
end

--[[
Claw Attack
]]

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    if owner.LagCompensation then -- for some reason not always true
        owner:LagCompensation(true)
    end

    local anim = math.random() < 0.5 and "fists_right" or "fists_left"
    self:PlayAnimation(PLAYER_ATTACK1, anim)
    owner:ViewPunch(Angle( 4, 4, 0 ))

    local spos = owner:GetShootPos()
    local sdest = spos + (owner:GetAimVector() * 70)
    local kmins = Vector(1,1,1) * -10
    local kmaxs = Vector(1,1,1) * 10

    local tr_main = util.TraceHull({start=spos, endpos=sdest, filter=owner, mask=MASK_SHOT_HULL, mins=kmins, maxs=kmaxs})
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
                owner:LagCompensation(false)
                owner:FireBullets({ Num = 1, Src = spos, Dir = owner:GetAimVector(), Spread = vector_origin, Tracer = 0, Force = 1, Damage = 0 })
            else
                util.Effect("Impact", edata)
            end
        end
    else
        self:SendWeaponAnim(ACT_VM_MISSCENTER)
    end

    if not CLIENT and IsPlayer(hitEnt) and not hitEnt:IsZombieAlly() and not hitEnt:ShouldActLikeJester() then
        local dmg = DamageInfo()
        dmg:SetDamage(self.Primary.Damage)
        dmg:SetAttacker(owner)
        dmg:SetInflictor(self)
        dmg:SetDamageForce(owner:GetAimVector() * 5)
        dmg:SetDamagePosition(owner:GetPos())
        dmg:SetDamageType(DMG_SLASH)

        hitEnt:DispatchTraceAttack(dmg, spos + (owner:GetAimVector() * 3), sdest)
    end

    if owner.LagCompensation then
        owner:LagCompensation(false)
    end
end

--[[
Jump Attack
]]

function SWEP:SecondaryAttack()
    if not zombie_leap_enable:GetBool() then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    if not self:CanSecondaryAttack() or not owner:IsOnGround() then return end

    self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)

    if SERVER then
        local jumpsounds = { "npc/fast_zombie/leap1.wav", "npc/zombie/zo_attack2.wav", "npc/fast_zombie/fz_alert_close1.wav", "npc/zombie/zombie_alert1.wav" }
        owner:SetVelocity(owner:GetForward() * 200 + Vector(0,0,400))
        owner:EmitSound(jumpsounds[math.random(#jumpsounds)], 100, 100)
    end

    -- Make this use the leap animation
    self.ActivityTranslate[ACT_MP_JUMP] = ACT_ZOMBIE_LEAPING

    -- Make it look like the player is jumping
    hook.Run("DoAnimationEvent", owner, PLAYERANIMEVENT_JUMP)

    -- Sync this jump override to the other players so they can see it too
    if SERVER then
        net.Start("TTT_ZombieLeapStart")
        net.WriteEntity(owner)
        net.Broadcast()
    end
end

function SWEP:Think()
    if self.ActivityTranslate[ACT_MP_JUMP] == nil then return end

    local owner = self:GetOwner()
    if not IsValid(owner) or owner.m_bJumping then return end

    -- When the player hits the ground or lands in water, reset the animation back to normal
    if owner:IsOnGround() or owner:WaterLevel() > 0 then
        self.ActivityTranslate[ACT_MP_JUMP] = nil

        -- Sync clearing the override to the other players as well
        if SERVER then
            net.Start("TTT_ZombieLeapEnd")
            net.WriteEntity(owner)
            net.Broadcast()
        end
    end
end

--[[
Spit Attack
]]

function SWEP:Reload()
    if not zombie_spit_enable:GetBool() then return end
    if self.NextReload > CurTime() then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    self.NextReload = CurTime() + self.Tertiary.Delay
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    if SERVER then
        self:CSShootBullet(self.Tertiary.Damage, self.Tertiary.Recoil, self.Tertiary.NumShots, self.Tertiary.Cone)
        owner:EmitSound("npc/fast_zombie/wake1.wav", 100, 100)
    end
    self:SendWeaponAnim(ACT_VM_MISSCENTER)

    -- If you play a fake sequence the fists hide in a quicker and cleaner way than when using "fists_holster"
    self:PlayAnimation(PLAYER_ATTACK1, "ThisIsAFakeSequence")
    -- After a short delay, bring the fists back out
    timer.Simple(0.25, function()
        if not IsValid(self) then return end
        if not IsValid(owner) then return end

        local vm = owner:GetViewModel()
        vm:SendViewModelMatchingSequence(vm:LookupSequence("fists_draw"))
    end)
end

function SWEP:CSShootBullet(dmg, recoil, numbul, cone)
    numbul = numbul or 1
    cone = cone or 0.01

    local owner = self:GetOwner()
    local bullet = {}
    bullet.Attacker      = owner
    bullet.Num           = numbul
    bullet.Src           = owner:GetShootPos()    -- Source
    bullet.Dir           = owner:GetAimVector()   -- Dir of bullet
    bullet.Spread        = Vector(cone, 0, 0)     -- Aim Cone
    bullet.Tracer        = 1
    bullet.TracerName    = "acidtracer"
    bullet.Force         = 55
    bullet.Damage        = dmg
    bullet.Callback      = function(attacker, tr, dmginfo)
        dmginfo:SetInflictor(self)
    end

    owner:FireBullets(bullet)

    if owner:IsNPC() then return end

    -- Custom Recoil, sometimes up and sometimes down
    local recoilDirection = 1
    if math.random(2) == 1 then
        recoilDirection = -1
    end

    owner:ViewPunch(Angle(recoilDirection * recoil, 0, 0))
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:Deploy()
    if self:GetOwner():IsZombiePrime() then
        self.Primary.Damage = zombie_prime_attack_damage:GetInt()
        self.Primary.Delay = zombie_prime_attack_delay:GetFloat()
    else
        self.Primary.Damage = zombie_thrall_attack_damage:GetInt()
        self.Primary.Delay = zombie_thrall_attack_delay:GetFloat()
    end

    local vm = self:GetOwner():GetViewModel()
    vm:SendViewModelMatchingSequence(vm:LookupSequence("fists_draw"))
end

function SWEP:Holster(weap)
    if CLIENT then
        local owner = weap:GetOwner()
        if not IsPlayer(owner) then return end

        local vm = owner:GetViewModel()
        if not IsValid(vm) or vm:GetColor() == COLOR_WHITE then return end

        vm:SetColor(COLOR_WHITE)
    end
    return true
end

if CLIENT then
    net.Receive("TTT_ZombieLeapStart", function()
        local ply = net.ReadEntity()
        if not IsPlayer(ply) then return end

        hook.Run("DoAnimationEvent", ply, PLAYERANIMEVENT_JUMP)

        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and WEPS.GetClass(wep) == "weapon_zom_claws" then
            wep.ActivityTranslate[ACT_MP_JUMP] = ACT_ZOMBIE_LEAPING
        end
    end)

    net.Receive("TTT_ZombieLeapEnd", function()
        local ply = net.ReadEntity()
        if not IsPlayer(ply) then return end

        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and WEPS.GetClass(wep) == "weapon_zom_claws" then
            wep.ActivityTranslate[ACT_MP_JUMP] = nil
        end
    end)

    local zombie_color = Color(70, 100, 25, 255)

    -- Set the viewmodel color to the zombie color so it matches what other players see
    function SWEP:PreDrawViewModel(vm, wep, ply)
        if vm:GetColor() ~= zombie_color then
            vm:SetColor(zombie_color)
        end
    end
end