AddCSLuaFile()

local ents = ents
local hook = hook
local IsValid = IsValid
local math = math
local net = net
local player = player
local timer = timer
local util = util

local CreateEntity = ents.Create

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

SWEP.TargetEntity = nil

local STATE_ERROR = -1
local STATE_NONE = 0
local STATE_EAT = 1

local beep = Sound("npc/fast_zombie/fz_alert_close1.wav")
local sound_single = Sound("Weapon_Crowbar.Single")

local zombie_leap_enabled = CreateConVar("ttt_zombie_leap_enabled", "1", FCVAR_REPLICATED)
local zombie_spit_enabled = CreateConVar("ttt_zombie_spit_enabled", "1", FCVAR_REPLICATED)
local zombie_prime_attack_damage = CreateConVar("ttt_zombie_prime_attack_damage", "65", FCVAR_REPLICATED, "The amount of a damage a prime zombie (e.g. player who spawned as a zombie originally) does with their claws. Server or round must be restarted for changes to take effect", 1, 100)
local zombie_thrall_attack_damage = CreateConVar("ttt_zombie_thrall_attack_damage", "45", FCVAR_REPLICATED, "The amount of a damage a zombie thrall (e.g. non-prime zombie) does with their claws. Server or round must be restarted for changes to take effect", 1, 100)
local zombie_prime_attack_delay = CreateConVar("ttt_zombie_prime_attack_delay", "0.7", FCVAR_REPLICATED, "The amount of time between claw attacks for a prime zombie (e.g. player who spawned as a zombie originally). Server or round must be restarted for changes to take effect", 0.1, 3)
local zombie_thrall_attack_delay = CreateConVar("ttt_zombie_thrall_attack_delay", "1.4", FCVAR_REPLICATED, "The amount of time between claw attacks for a zombie thrall (e.g. non-prime zombie). Server or round must be restarted for changes to take effect", 0.1, 3)
local zombie_eat_enabled = CreateConVar("ttt_zombie_eat_enabled", "0", FCVAR_REPLICATED, "Whether zombies have the ability to eat a player's corpse", 0, 1)
local zombie_eat_drop_bones = CreateConVar("ttt_zombie_eat_drop_bones", "1", FCVAR_REPLICATED, "Whether zombies should drop bones when eating a player's corpse", 0, 1)

if SERVER then
    CreateConVar("ttt_zombie_eat_timer", "5", FCVAR_NONE, "The amount of time it takes to consume a player's corpse", 0, 30)
    CreateConVar("ttt_zombie_eat_heal", "50", FCVAR_NONE, "The amount of health a zombie will heal by when they consume a player's corpse", 0, 100)
    CreateConVar("ttt_zombie_eat_overheal", "25", FCVAR_NONE, "The amount over the zombie's normal maximum health (e.g. 100 + this ConVar) that the zombie can heal to by consuming a player's corpse", 0, 100)
end

function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "State")
    self:NetworkVar("Int", 1, "EatTime")
    self:NetworkVar("Float", 0, "StartTime")
    self:NetworkVar("String", 0, "Message")
    if SERVER then
        self:SetEatTime(GetConVar("ttt_zombie_eat_timer"):GetInt())
        self:Reset()
    end
end

function SWEP:Initialize()
    if CLIENT then
        local secondary = nil
        if zombie_leap_enabled:GetBool() then
            secondary = "zom_claws_help_sec"
            if not zombie_spit_enabled:GetBool() then
                secondary = secondary .. "_nospit"
            end
        elseif zombie_spit_enabled:GetBool() then
            secondary = "zom_claws_help_sec_noleap"
        end
        self:AddHUDHelp("zom_claws_help_pri", secondary, true)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:SetWeaponHoldType(t)
    self.BaseClass.SetWeaponHoldType(self, t)

    -- Sanity check, this should have been set up by the BaseClass.SetWeaponHoldType call above
    if not self.ActivityTranslate then
        self.ActivityTranslate = {}
    end

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

local function GetPlayerFromBody(body)
    local ply

    if body.sid64 then
        ply = player.GetBySteamID64(body.sid64)
    elseif body.sid == "BOT" then
        ply = player.GetByUniqueID(body.uqid)
    else
        ply = player.GetBySteamID(body.sid)
    end

    if not IsValid(ply) then return false end

    return ply
end

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

                if SERVER and zombie_eat_enabled:GetBool() and hitEnt:GetClass() == "prop_ragdoll" then
                    local ply = GetPlayerFromBody(hitEnt)
                    if IsValid(ply) and not ply:Alive() then
                        self:Eat(hitEnt)
                    end
                end
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
    if not zombie_leap_enabled:GetBool() then return end

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
            net.WritePlayer(owner)
        net.Broadcast()
    end
end

function SWEP:Think()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    if SERVER and self:GetState() >= STATE_EAT then
        local tr = self:GetTraceEntity()
        if not owner:KeyDown(IN_ATTACK) or tr.Entity ~= self.TargetEntity then
            self:Error("EATING ABORTED")
            return
        end

        -- We've finished eating
        if CurTime() >= self:GetStartTime() + self:GetEatTime() then
            self:DropBones()
            self:DoHeal()
            SafeRemoveEntity(self.TargetEntity)

            -- Not actually an error, but it resets the things we want
            self:FireError()
        end
    end

    if self.ActivityTranslate[ACT_MP_JUMP] == nil then return end

    if owner.m_bJumping then return end

    -- When the player hits the ground or lands in water, reset the animation back to normal
    if owner:IsOnGround() or owner:WaterLevel() > 0 then
        self.ActivityTranslate[ACT_MP_JUMP] = nil

        -- Sync clearing the override to the other players as well
        if SERVER then
            net.Start("TTT_ZombieLeapEnd")
                net.WritePlayer(owner)
            net.Broadcast()
        end
    end
end

--[[
Spit Attack
]]

function SWEP:Reload()
    if not zombie_spit_enabled:GetBool() then return end
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

--[[
Eat
]]

function SWEP:Eat(entity)
    self:GetOwner():EmitSound("weapons/ttt/zombieeat.wav")
    self:SetState(STATE_EAT)
    self:SetStartTime(CurTime())
    self:SetMessage("EATING BODY")

    self.TargetEntity = entity

    self:SetNextPrimaryFire(CurTime() + self:GetEatTime())
end

function SWEP:DoHeal()
    local overheal = GetConVar("ttt_zombie_eat_overheal"):GetInt()
    local heal = GetConVar("ttt_zombie_eat_heal"):GetInt()
    local owner = self:GetOwner()
    local health = math.min(owner:Health() + heal, owner:GetMaxHealth() + overheal)
    hook.Call("TTTZombieBodyEaten", nil, owner, self.TargetEntity, health - owner:Health())
    owner:SetHealth(health)
end

function SWEP:DropBones()
    if not zombie_eat_drop_bones:GetBool() then return end

    local pos = self.TargetEntity:GetPos()
    local fingerprints = { self:GetOwner() }

    local skull = CreateEntity("prop_physics")
    if not IsValid(skull) then return end
    skull:SetModel("models/Gibs/HGIBS.mdl")
    skull:SetPos(pos)
    skull:Spawn()
    skull:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    skull.fingerprints = fingerprints

    local ribs = CreateEntity("prop_physics")
    if not IsValid(ribs) then return end
    ribs:SetModel("models/Gibs/HGIBS_rib.mdl")
    ribs:SetPos(pos + Vector(0, 0, 15))
    ribs:Spawn()
    ribs:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    ribs.fingerprints = fingerprints

    local spine = CreateEntity("prop_physics")
    if not IsValid(ribs) then return end
    spine:SetModel("models/Gibs/HGIBS_spine.mdl")
    spine:SetPos(pos + Vector(0, 0, 30))
    spine:Spawn()
    spine:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    spine.fingerprints = fingerprints

    local scapula = CreateEntity("prop_physics")
    if not IsValid(scapula) then return end
    scapula:SetModel("models/Gibs/HGIBS_scapula.mdl")
    scapula:SetPos(pos + Vector(0, 0, 45))
    scapula:Spawn()
    scapula:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    scapula.fingerprints = fingerprints
end

--[[
Misc.
]]

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
    if CLIENT and IsValid(weap) then
        local owner = weap:GetOwner()
        if not IsPlayer(owner) then return end

        local vm = owner:GetViewModel()
        if not IsValid(vm) or vm:GetColor() == COLOR_WHITE then return end

        vm:SetColor(COLOR_WHITE)
    end
    return true
end

if CLIENT then
    function SWEP:DrawHUD()
        self.BaseClass.DrawHUD(self)

        local progress
        local color
        if self:GetState() == STATE_ERROR then
            progress = 1
            color = Color(200 + math.sin(CurTime() * 32) * 50, 0, 0, 155)
        elseif self:GetState() >= STATE_EAT then
            progress = math.TimeFraction(self:GetStartTime(), self:GetStartTime() + self:GetEatTime(), CurTime())
            color = Color(0, 255, 0, 155)
        else
            return
        end

        if progress < 0 then return end

        progress = math.Clamp(progress, 0, 1)

        local x = ScrW() / 2.0
        local y = ScrH() / 2.0
        y = y + (y / 3)
        CRHUD:PaintProgressBar(x, y, 255, color, self:GetMessage(), progress)
    end
else
    function SWEP:Reset()
        self:SetState(STATE_NONE)
        self:SetStartTime(-1)
        self:SetMessage('')
        self:SetNextPrimaryFire(CurTime() + 0.1)
    end

    function SWEP:Error(msg)
        self:SetState(STATE_ERROR)
        self:SetStartTime(CurTime())
        self:SetMessage(msg)

        self:GetOwner():EmitSound(beep, 60, 50, 1)

        timer.Simple(0.75, function()
            if IsValid(self) then self:Reset() end
        end)
    end

    function SWEP:GetTraceEntity()
        local spos = self:GetOwner():GetShootPos()
        local sdest = spos + (self:GetOwner():GetAimVector() * 70)
        local kmins = Vector(1,1,1) * -10
        local kmaxs = Vector(1,1,1) * 10

        return util.TraceHull({start=spos, endpos=sdest, filter=self:GetOwner(), mask=MASK_SHOT_HULL, mins=kmins, maxs=kmaxs})
    end

    function SWEP:FireError()
        self:SetState(STATE_NONE)
        self:SetNextPrimaryFire(CurTime() + 0.1)
    end
end

if CLIENT then
    net.Receive("TTT_ZombieLeapStart", function()
        local ply = net.ReadPlayer()
        if not IsPlayer(ply) then return end

        hook.Run("DoAnimationEvent", ply, PLAYERANIMEVENT_JUMP)

        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and WEPS.GetClass(wep) == "weapon_zom_claws" and wep.ActivityTranslate then
            wep.ActivityTranslate[ACT_MP_JUMP] = ACT_ZOMBIE_LEAPING
        end
    end)

    net.Receive("TTT_ZombieLeapEnd", function()
        local ply = net.ReadPlayer()
        if not IsPlayer(ply) then return end

        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and WEPS.GetClass(wep) == "weapon_zom_claws" and wep.ActivityTranslate then
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