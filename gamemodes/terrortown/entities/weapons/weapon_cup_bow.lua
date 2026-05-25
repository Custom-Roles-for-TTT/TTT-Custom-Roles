SWEP.HoldType = "pistol"

if CLIENT then
    SWEP.PrintName = "Cupid's Bow"
    SWEP.Slot = 8

    SWEP.ViewModelFOV = 68
    SWEP.DrawCrosshair = false
    SWEP.ViewModelFlip = false
end

SWEP.Base = "weapon_tttbase"
SWEP.Category = WEAPON_CATEGORY_ROLE

SWEP.Primary.Recoil = 0
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Delay = 0
SWEP.Primary.Ammo = "none"

SWEP.Secondary.Recoil = 0
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Delay = 0
SWEP.Secondary.Ammo = "none"

SWEP.InLoadoutFor = {ROLE_CUPID}

SWEP.AllowDrop = false

SWEP.Kind = WEAPON_ROLE

SWEP.UseHands = true
SWEP.ViewModel = Model("models/weapons/v_huntingbow.mdl")
SWEP.WorldModel = Model("models/weapons/w_huntingbow.mdl")

SWEP.AutoSpawnable = false

SWEP.STATE_NOCKED = 0
SWEP.STATE_PULLED = 1
SWEP.STATE_RELEASE = 2

SWEP.ActivitySound = {
    [ACT_VM_PULLBACK] = "Weapon_CupidsBow.Pull",
    [ACT_VM_PRIMARYATTACK] = "Weapon_CupidsBow.Single",
    [ACT_VM_LOWERED_TO_IDLE] = "Weapon_CupidsBow.Nock",
    [ACT_VM_RELEASE] = "Weapon_CupidsBow.Pull"
}

SWEP.ActivityLength = {
    [ACT_VM_PULLBACK] = 0.2,
    [ACT_VM_PRIMARYATTACK] = 0.25,
    [ACT_VM_LOWERED_TO_IDLE] = 1,
    [ACT_VM_RELEASE] = 0.5
}

SWEP.HoldTypeTranslate = {
    [SWEP.STATE_NOCKED] = "pistol",
    [SWEP.STATE_PULLED] = "pistol",
    [SWEP.STATE_RELEASE] = "grenade"
}

sound.Add({
    channel = CHAN_AUTO,
    volume = 0.4,
    level = 60,
    name = "Weapon_CupidsBow.Nock",
    sound = { "cupid/nock_1.wav", "cupid/nock_2.wav", "cupid/nock_3.wav" }
})

sound.Add({
    channel = CHAN_AUTO,
    volume = 0.3,
    level = 60,
    name = "Weapon_CupidsBow.Pull",
    sound = { "cupid/pull_1.wav", "cupid/pull_2.wav", "cupid/pull_3.wav" }
})

sound.Add({
    channel = CHAN_AUTO,
    volume = 1,
    level = 60,
    name = "Weapon_CupidsBow.Single",
    sound = { "cupid/shoot_1.wav", "cupid/shoot_2.wav", "cupid/shoot_3.wav" }
})

sound.Add({
    channel = CHAN_AUTO,
    volume = 1,
    level = 60,
    name = "Weapon_CupidsBow.ZoomIn",
    sound = "cupid/zoomin.wav"
})

sound.Add({
    channel = CHAN_AUTO,
    volume = 1,
    level = 60,
    name = "Weapon_CupidsBow.ZoomOut",
    sound = "cupid/zoomout.wav"
})

if SERVER then
    CreateConVar("ttt_cupid_arrow_speed_mult", "1", FCVAR_NONE, "The speed multiplier for the cupid's arrow (Only applies when ttt_cupid_arrow_hitscan is disabled)", 0.1, 1.5)
    CreateConVar("ttt_cupid_arrow_hitscan", "0", FCVAR_NONE, "Whether the cupid's arrow should be an instant hit instead of a projectile", 0, 1)
end

function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "WepState")
end

function SWEP:RunActivity(act)
    self:SendWeaponAnim(act)

    local snd = self.ActivitySound[act]
    if snd and ((game.SinglePlayer() and SERVER) or (CLIENT and IsFirstTimePredicted())) then
        self:EmitSound(snd)
    end

    local t = self.ActivityLength[act]
    if t then
        self:SetNextPrimaryFire(CurTime() + t)
    end
end

function SWEP:PrimaryAttack()
    return
end

function SWEP:SecondaryAttack()
    return
end

function SWEP:Think()
    local holdType = self.HoldTypeTranslate[self.dt.WepState]
    if holdType ~= self:GetHoldType() then
        self:SetHoldType(holdType)
    end

    if self:GetNextPrimaryFire() >= CurTime() then
        return
    end

    local owner = self:GetOwner()
    if self.dt.WepState == self.STATE_PULLED then
        if owner:KeyDown(IN_RELOAD) then
            self.dt.WepState = self.STATE_NOCKED
            self:RunActivity(ACT_VM_RELEASE)
        elseif not owner:KeyDown(IN_ATTACK) then
            self.dt.WepState = self.STATE_RELEASE
            self:RunActivity(ACT_VM_PRIMARYATTACK)

            if SERVER then
                local aimVec = owner:GetAimVector()
                local ang = aimVec:Angle()
                local pos = owner:EyePos() + ang:Up() * -7 + ang:Forward() * -4

                if not owner:KeyDown(IN_ATTACK2) then
                    pos = pos + ang:Right() * 1.5
                end

                local mult = 1
                if GetConVar("ttt_cupid_arrow_hitscan"):GetBool() then
                    local trace = util.TraceLine({ start = pos, endpos = pos + (aimVec * 4096), filter={self, owner} })
                    if not trace.Hit then return end

                    -- Start a little bit back from where it hit so it can fly and trigger the impact correctly
                    pos = trace.HitPos - (aimVec * 4)
                else
                    local charge = self:GetNextSecondaryFire()
                    charge = math.Clamp(CurTime() - charge, 0, 1)

                    mult = GetConVar("ttt_cupid_arrow_speed_mult"):GetFloat() * charge
                end

                local arrow = ents.Create("ttt_cup_arrow")
                arrow:SetOwner(owner)
                arrow:SetPos(pos)
                arrow:SetAngles(ang)
                arrow:Spawn()
                arrow:Activate()
                arrow:SetVelocity(ang:Forward() * 2500 * mult)
                arrow.Weapon = self
            end
        end
    elseif self.dt.WepState == self.STATE_RELEASE then
        self.dt.WepState = self.STATE_NOCKED
        self:RunActivity(ACT_VM_LOWERED_TO_IDLE)
    elseif self.dt.WepState == self.STATE_NOCKED then
        if owner:KeyDown(IN_ATTACK) and not owner:KeyDown(IN_RELOAD) then
            self.dt.WepState = self.STATE_PULLED

            self:RunActivity(ACT_VM_PULLBACK)
            self:SetNextSecondaryFire(CurTime())
        end
    end
end

function SWEP:Holster(wep)
    return true
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:Deploy()
    if CLIENT then
        self.AimMult = 0
        self.AimMult2 = 0
    end

    self.dt.WepState = self.STATE_NOCKED
    self.nextWeapon = nil

    self:RunActivity(ACT_VM_LOWERED_TO_IDLE)
    return true
end

if CLIENT then
    SWEP.AimMult  = 0
    SWEP.AimMult2 = 0
    SWEP.AimFOV = 25
    SWEP.LastAimState = false

    function SWEP:PreDrawViewModel(vm, wep, ply)
        vm:InvalidateBoneCache()

        local owner = self:GetOwner()
        local state = self.dt.WepState
        if (state == self.STATE_PULLED or state == self.STATE_RELEASE) and owner:KeyDown(IN_ATTACK2) then
            self.AimMult  = math.Approach(self.AimMult, 1, FrameTime() * 8)
            self.AimMult2 = Lerp(FrameTime() * 15, self.AimMult2, self.AimMult)

            if not self.LastAimState then
                self:EmitSound("Weapon_CupidsBow.ZoomIn")
                self.LastAimState = true
            end
        else
            self.AimMult  = math.Approach(self.AimMult, 0, FrameTime() * 8)
            self.AimMult2 = Lerp(FrameTime() * 15, self.AimMult2, self.AimMult)

            if self.LastAimState then
                self:EmitSound("Weapon_CupidsBow.ZoomOut")
                self.LastAimState = false
            end
        end

        local pose    = vm:GetPoseParameter("idle_pose")
        local pose_to = math.Round(self.AimMult2, 3)

        if pose ~= pose_to then
            vm:SetPoseParameter("idle_pose", pose_to)
            vm:InvalidateBoneCache()
        end
    end

    function SWEP:TranslateFOV(current_fov)
        return current_fov - (self.AimMult2 * self.AimFOV)
    end

    function SWEP:DrawWorldModelTranslucent(flags)
        self:DrawModel(flags)
    end

    function SWEP:AdjustMouseSensitivity()
        local current_fov    = self:GetOwner():GetFOV()
        local translated_fov = self:TranslateFOV(current_fov)

        return translated_fov / current_fov
    end
end