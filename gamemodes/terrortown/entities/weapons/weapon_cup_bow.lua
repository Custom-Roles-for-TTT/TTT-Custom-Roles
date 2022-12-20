SWEP.HoldType = "pistol"

if CLIENT then
    SWEP.PrintName = "Cupid's Bow"
    SWEP.Slot = 8

    SWEP.ViewModelFOV = 68
    SWEP.DrawCrosshair = true
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
                local ang = owner:GetAimVector():Angle()
                local pos = owner:EyePos() + ang:Up() * -7 + ang:Forward() * -4

                if not owner:KeyDown(IN_ATTACK2) then
                    pos = pos + ang:Right() * 1.5
                end

                local charge = self:GetNextSecondaryFire()
                charge = math.Clamp(CurTime() - charge, 0, 1)

                local arrow = ents.Create("ttt_cup_arrow")
                arrow:SetOwner(owner)
                arrow:SetPos(pos)
                arrow:SetAngles(ang)
                arrow:Spawn()
                arrow:Activate()
                arrow:SetVelocity(ang:Forward() * 2500 * charge)
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
    local ang = Angle(0, 0, 0)

    local vm_origin = Vector(0, 0, 0)
    local vm_angles = Angle(0, 0, 0)

    SWEP.SwayScale = 0
    SWEP.BobScale = 0

    SWEP.VMOrigin = Vector(0, 0, 0)

    SWEP.BobCycle = 0

    SWEP.BobPos  = Vector(0, 0, 0)
    SWEP.BobPos2 = Vector(0, 0, 0)

    SWEP.AimOrigin = Vector(-6, -3, 1)
    SWEP.AimAngles = Angle(1, 0, -45)

    SWEP.AimMult  = 0
    SWEP.AimMult2 = 0

    SWEP.LastAimState = false

    SWEP.SpeedMult = 0
    SWEP.SideSpeed = 0

    SWEP.LastAngles = Angle(0, 0, 0)
    SWEP.AimFOV = 25

    function SWEP:PreDrawViewModel(vm, wep, ply)
        vm:InvalidateBoneCache()
        vm_angles = vm:GetAngles()

        vm:SetAngles(ang)

        self.AttData  = vm:GetAttachment(1)
        self.VMOrigin = vm:GetPos()

        vm:SetAngles(vm_angles)

        local owner = self:GetOwner()
        local noclip = owner:GetMoveType() == MOVETYPE_NOCLIP
        local onGround = owner:IsOnGround() or noclip

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

        local speed_max = owner:GetWalkSpeed()

        local vel   = owner:GetVelocity()
        local speed = math.min(vel:Length2D() / speed_max, 1.5)

        self.SpeedMult = Lerp(FrameTime() * 10, self.SpeedMult, (noclip or not onGround) and 0 or speed)
        self.BobCycle = self.BobCycle + FrameTime() * self.SpeedMult * 15

        local bob_mult = 1 - self.AimMult2 * 0.6

        local pose    = vm:GetPoseParameter("idle_pose")
        local pose_to = math.Round(self.AimMult2, 3)

        if pose ~= pose_to then
            vm:SetPoseParameter("idle_pose", pose_to)
            vm:InvalidateBoneCache()
        end

        self.BobPos.x = Lerp(FrameTime() * 15, self.BobPos.x, math.sin(self.BobCycle * 0.5) * self.SpeedMult * bob_mult)
        self.BobPos.y = Lerp(FrameTime() * 15, self.BobPos.y, math.cos(self.BobCycle)       * self.SpeedMult * bob_mult)

        self.BobPos2.x = Lerp(FrameTime() * 15, self.BobPos2.x, math.sin(self.BobCycle * 0.5 + 45) * self.SpeedMult * bob_mult)
        self.BobPos2.y = Lerp(FrameTime() * 15, self.BobPos2.y, math.cos(self.BobCycle       + 45) * self.SpeedMult * bob_mult)

        self.LastAngles = LerpAngle(FrameTime() * 15, self.LastAngles, EyeAngles())

        local side_speed = math.Clamp(vel:Dot(EyeAngles():Right()), -speed_max, speed_max) / speed_max
        self.SideSpeed   = Lerp(FrameTime() * 5, self.SideSpeed, noclip and 0 or (side_speed * bob_mult * 4))
    end

    local cam = {
        origin = Vector(0, 0, 0),
        angles = Angle(0, 0, 0)
    }

    function SWEP:GetViewModelPosition(origin, angles)
        local sway_p = math.NormalizeAngle(self.LastAngles.p - EyeAngles().p) * 0.2
        local sway_y = math.NormalizeAngle(self.LastAngles.y - EyeAngles().y) * 0.2

        vm_origin.x = self.BobPos.x * 0.33 + sway_y * 0.1 + self.SideSpeed * 0.33
        vm_origin.y = self.BobPos2.y * 0.2
        vm_origin.z = self.BobPos.y * 0.43 + sway_p * 0.1

        vm_angles.p = -self.BobPos2.y - sway_p
        vm_angles.y = -self.BobPos2.x * 0.25 + sway_y
        vm_angles.r =  self.BobPos2.x * 0.5 + self.SideSpeed

        local Right   = angles:Right()
        local Up      = angles:Up()
        local Forward = angles:Forward()

        angles:RotateAroundAxis(Right,   vm_angles.p)
        angles:RotateAroundAxis(Up,      vm_angles.y)
        angles:RotateAroundAxis(Forward, vm_angles.r)

        origin = origin + (vm_origin.x + cam.origin.x) * Right
        origin = origin + (vm_origin.y + cam.origin.y) * Forward
        origin = origin + (vm_origin.z + cam.origin.z) * Up

        return origin, angles
    end

    function SWEP:CalcView(ply, origin, angles, fov)
        if ply:GetViewEntity() ~= ply then
            return
        end

        local vm = self:GetOwner():GetViewModel()

        if IsValid(vm) then
            vm_origin = vm:GetPos()
            local att = self.AttData

            if att then
                cam.origin.x = att.Pos.x - self.VMOrigin.x
                cam.origin.y = att.Pos.y - self.VMOrigin.y
                cam.origin.z = att.Pos.z - self.VMOrigin.z

                cam.angles.p = math.NormalizeAngle(att.Ang.r)
                cam.angles.y = math.NormalizeAngle(att.Ang.y - 90)
                cam.angles.r = math.NormalizeAngle(att.Ang.p)
            end
        end

        local angles_p = cam.angles.p + self.BobPos.y  * 0.25
        local angles_y = cam.angles.y - self.BobPos.x  * 0.25
        local angles_r = cam.angles.r + self.BobPos2.x * 0.25

        angles:RotateAroundAxis(angles:Right(), angles_p)
        angles:RotateAroundAxis(angles:Up(), angles_y)
        angles:RotateAroundAxis(angles:Forward(), angles_r)

        origin = origin + cam.origin.x * angles:Right()
        origin = origin + cam.origin.y * angles:Forward()
        origin = origin + cam.origin.z * angles:Up()

        return origin, angles, fov
    end

    function SWEP:TranslateFOV(current_fov)
        return current_fov - (self.AimMult2 * self.AimFOV)
    end

    function SWEP:DrawWorldModelTranslucent()
        self:DrawModel()
    end

    function SWEP:AdjustMouseSensitivity()
        local current_fov    = self:GetOwner():GetFOV()
        local translated_fov = self:TranslateFOV(current_fov)

        return translated_fov / current_fov
    end
end