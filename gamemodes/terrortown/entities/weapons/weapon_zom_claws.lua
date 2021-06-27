AddCSLuaFile()

if CLIENT then
    SWEP.PrintName = "Claws"
    SWEP.EquipMenuData = {
        type = "Weapon",
        desc = "Left click to attack. Right click to leap. Press reload to spit."
    };

    SWEP.Slot = 8 -- add 1 to get the slot number key
    SWEP.ViewModelFOV = 54
    SWEP.ViewModelFlip = false
else
    util.AddNetworkString("TTT_Zombified")
end

SWEP.InLoadoutFor = { ROLE_ZOMBIE }

SWEP.Base = "weapon_tttbase"

SWEP.HoldType = "fist"

SWEP.ViewModel = Model("models/weapons/c_arms_cstrike.mdl")
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
SWEP.Tertiary.NumShots = SWEP.Primary.NumShots
SWEP.Tertiary.Recoil = 5
SWEP.Tertiary.Cone = 0.02

SWEP.Kind = WEAPON_ROLE

SWEP.AllowDrop = false
SWEP.IsSilent = false

SWEP.NextReload = CurTime()

-- Pull out faster than standard guns
SWEP.DeploySpeed = 2
local sound_single = Sound("Weapon_Crowbar.Single")

local zombie_leap = CreateConVar("ttt_zombie_leap_enable", "1")
local zombie_spit = CreateConVar("ttt_zombie_spit_enable", "1")

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)

    if CLIENT then
        self:AddHUDHelp("Left click to attack", "Right click to leap. Press reload to spit", false)
    end
end

--[[
Claw Attack
]]

function SWEP:PlayPunchAnimation()
    local anim = "fists_right"
    local vm = self.Owner:GetViewModel()
    vm:SendViewModelMatchingSequence(vm:LookupSequence(anim))
    self:GetOwner():ViewPunch(Angle( 4, 4, 0 ))
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)
end

function SWEP:PrimaryAttack()
    self.Weapon:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    if not IsValid(self:GetOwner()) then return end

    self:PlayPunchAnimation()

    if self:GetOwner().LagCompensation then -- for some reason not always true
        self:GetOwner():LagCompensation(true)
    end

    local spos = self:GetOwner():GetShootPos()
    local sdest = spos + (self:GetOwner():GetAimVector() * 70)
    local kmins = Vector(1,1,1) * -10
    local kmaxs = Vector(1,1,1) * 10

    local tr_main = util.TraceHull({start=spos, endpos=sdest, filter=self:GetOwner(), mask=MASK_SHOT_HULL, mins=kmins, maxs=kmaxs})
    local hitEnt = tr_main.Entity

    self.Weapon:EmitSound(sound_single)

    if IsValid(hitEnt) or tr_main.HitWorld then
        self:PlayPunchAnimation()
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
                self:GetOwner():LagCompensation(false)
                self:GetOwner():FireBullets({ Num = 1, Src = spos, Dir = self:GetOwner():GetAimVector(), Spread = Vector(0, 0, 0), Tracer = 0, Force = 1, Damage = 0 })
            else
                util.Effect("Impact", edata)
            end
        end
    else
        self.Weapon:SendWeaponAnim(ACT_VM_MISSCENTER)
    end

    if not CLIENT then
        self:GetOwner():SetAnimation(PLAYER_ATTACK1)

        if hitEnt and hitEnt:IsValid() then
            if hitEnt:IsPlayer() and not hitEnt:IsZombieAlly() and (not hitEnt:IsJesterTeam() or hitEnt:GetNWBool("KillerClownActive", false)) then
                if hitEnt:Health() <= self.Primary.Damage then
                    self:GetOwner():AddCredits(1)
                    LANG.Msg(self:GetOwner(), "credit_zom", { num = 1 })
                    hitEnt:PrintMessage(HUD_PRINTCENTER, "You will respawn as a zombie in 3 seconds.")
                    hitEnt:SetNWBool("IsZombifying", true)

                    net.Start("TTT_Zombified")
                    net.WriteString(hitEnt:Nick())
                    net.Broadcast()

                    timer.Simple(3, function()
                        -- Don't respawn the player if they were already zombified by something else
                        if hitEnt:GetRole() ~= ROLE_ZOMBIE then
                            local body = hitEnt.server_ragdoll or hitEnt:GetRagdollEntity()
                            hitEnt:SpawnForRound(true)
                            hitEnt:SetRole(ROLE_ZOMBIE)
                            hitEnt:SetZombiePrime(false)
                            hitEnt:SetMaxHealth(100)
                            hitEnt:SetHealth(100)
                            hitEnt:StripAll()
                            hitEnt:Give("weapon_zom_claws")
                            if IsValid(body) then
                                hitEnt:SetPos(FindRespawnLocation(body:GetPos()) or body:GetPos())
                                hitEnt:SetEyeAngles(Angle(0, body:GetAngles().y, 0))
                                body:Remove()
                            end
                        end
                        hitEnt:SetNWBool("IsZombifying", false)
                        SendFullStateUpdate()
                    end)
                end

                local dmg = DamageInfo()
                dmg:SetDamage(self.Primary.Damage)
                dmg:SetAttacker(self:GetOwner())
                dmg:SetInflictor(self.Weapon or self)
                dmg:SetDamageForce(self:GetOwner():GetAimVector() * 5)
                dmg:SetDamagePosition(self:GetOwner():GetPos())
                dmg:SetDamageType(DMG_SLASH)

                hitEnt:DispatchTraceAttack(dmg, spos + (self:GetOwner():GetAimVector() * 3), sdest)
            end
        end
    end

    if self:GetOwner().LagCompensation then
        self:GetOwner():LagCompensation(false)
    end
end

--[[
Jump Attack
]]

function SWEP:SecondaryAttack()
    if SERVER then
        if not zombie_leap:GetBool() then return end
        if (not self:CanSecondaryAttack()) or self.Owner:IsOnGround() == false then return end

        local jumpsounds = { "npc/fast_zombie/leap1.wav", "npc/zombie/zo_attack2.wav", "npc/fast_zombie/fz_alert_close1.wav", "npc/zombie/zombie_alert1.wav" }
        self.SecondaryDelay = CurTime()+10
        self.Owner:SetVelocity(self.Owner:GetForward() * 200 + Vector(0,0,400))
        self.Owner:EmitSound(jumpsounds[math.random(#jumpsounds)], 100, 100)
        self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
    end
end

--[[
Spit Attack
]]

function SWEP:Reload()
    if not zombie_spit:GetBool() then return end
    if self.NextReload > CurTime() then return end
    self.NextReload = CurTime() + 3
    self.Weapon:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    self:CSShootBullet(self.Tertiary.Damage, self.Tertiary.Recoil, self.Tertiary.NumShots, self.Tertiary.Cone)
end

function SWEP:CSShootBullet(dmg, recoil, numbul, cone)
    numbul = numbul or 1
    cone = cone or 0.01

    local bullet = {}
    bullet.Attacker      = self.Owner
    bullet.Num           = 1
    bullet.Src           = self.Owner:GetShootPos()            -- Source
    bullet.Dir           = self.Owner:GetAimVector()            -- Dir of bullet
    bullet.Spread        = Vector(cone, 0, 0)                    -- Aim Cone
    bullet.Tracer        = 1
    bullet.TracerName    = "acidtracer"
    bullet.Force         = 55
    bullet.Damage        = dmg

    self.Owner:FireBullets(bullet)
    self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)     -- View model animation
    self.Owner:MuzzleFlash()                            -- Crappy muzzle light
    self.Owner:SetAnimation(PLAYER_ATTACK1)                -- 3rd Person Animation

    if (self.Owner:IsNPC()) then return end

    -- Custom Recoil, sometimes up and sometimes down
    local recoilDirection = 1
    if math.random(2) == 1 then
        recoilDirection = -1
    end

    self.Owner:ViewPunch(Angle(recoilDirection * recoil, 0, 0))
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:Deploy()
    local vm = self.Owner:GetViewModel()
    vm:SendViewModelMatchingSequence(vm:LookupSequence("fists_draw"))
end

function SWEP:Holster(weapon)
    return true
end

local offsets = {}

for i = 0, 360, 15 do
    table.insert(offsets, Vector(math.sin(i), math.cos(i), 0))
end

function FindRespawnLocation(pos)
    local midsize = Vector(33, 33, 74)
    local tstart = pos + Vector(0, 0, midsize.z / 2)

    for i = 1, #offsets do
        local o = offsets[i]
        local v = tstart + o * midsize * 1.5

        local t = {
            start = v,
            endpos = v,
            mins = midsize / -2,
            maxs = midsize / 2
        }

        local tr = util.TraceHull(t)

        if not tr.Hit then return (v - Vector(0, 0, midsize.z / 2)) end
    end

    return false
end
