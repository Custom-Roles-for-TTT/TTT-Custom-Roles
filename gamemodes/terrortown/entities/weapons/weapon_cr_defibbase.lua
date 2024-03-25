-- Defib v2 (revision 20170303)

-- This code is copyright (c) 2016-2017 all rights reserved - "Vadim" @ jmwparq@gmail.com
-- (Re)sale of this code and/or products containing part of this code is strictly prohibited
-- Exclusive rights to usage of this product in "Trouble in Terrorist Town" are given to:
-- - The Garry's Mod community

AddCSLuaFile()

local IsValid = IsValid
local math = math
local player = player
local string = string
local timer = timer

SWEP.HoldType = "pistol"
SWEP.LimitedStock = true

if CLIENT then
    SWEP.ViewModelFOV = 54
    SWEP.DrawCrosshair = false
    SWEP.ViewModelFlip = false
end

SWEP.Base = "weapon_tttbase"

SWEP.Primary.Recoil = 0
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Delay = 1
SWEP.Primary.Ammo = "none"

SWEP.Secondary.Recoil = 0
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Delay = 1

local beep = Sound("buttons/button17.wav")
local hum = Sound("items/nvg_on.wav")
local zap = Sound("ambient/energy/zap7.wav")

SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/cstrike/c_c4.mdl"
SWEP.WorldModel = "models/weapons/w_c4.mdl"

SWEP.Spawnable = false
SWEP.AutoSpawnable = false
SWEP.NoSights = true
SWEP.AllowDrop = false
SWEP.AmmoEnt = nil

SWEP.Target = nil
SWEP.Bone = nil
SWEP.Location = nil

-- Settings
SWEP.MaxDistance = 64
SWEP.SuccessChance = 100

-- ConVar object used to control how long the device takes to use
SWEP.DeviceTimeConVar = nil
-- Whether the device should be removed after it is used once
SWEP.SingleUse = true
-- Whether the device should find a location (saved in self.Location) to use as the respawn. Also automatically fails if no valid respawn location can be found
SWEP.FindRespawnLocation = true
-- Whether the target of this device should be a dead player. If `false` then it will target living players instead
SWEP.DeadTarget = true
-- Whether this device has a secondary attack
SWEP.HasSecondary = false

local DEFIB_IDLE = 0
local DEFIB_BUSY = 1
local DEFIB_ERROR = 2

function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "State")
    self:NetworkVar("Int", 1, "ChargeTime")
    self:NetworkVar("Float", 0, "Begin")
    self:NetworkVar("String", 0, "Message")

    if SERVER and self.DeviceTimeConVar then
        self:SetChargeTime(self.DeviceTimeConVar:GetInt())
    end
end

function SWEP:OnDrop()
    if not self.AllowDrop then
        self:Remove()
    end
end

function SWEP:OnRemove()
    if CLIENT and IsValid(self:GetOwner()) and self:GetOwner() == LocalPlayer() and self:GetOwner():Alive() then
        RunConsoleCommand("lastinv")
    end
end

if SERVER then
    local function IsBodyValid(body)
        return CORPSE.GetPlayerNick(body, false) ~= false
    end

    local function GetPlayerFromBody(body)
        local ply

        if body.sid64 then
            ply = player.GetBySteamID64(body.sid64)
        elseif body.sid == "BOT" then
            ply = player.GetByUniqueID(body.uqid)
        elseif body.sid then
            ply = player.GetBySteamID(body.sid)
        end

        if not IsValid(ply) then return false end

        return ply
    end

    function SWEP:GetPlayerAndBodyFromTarget(target)
        if self.DeadTarget then
            if IsPlayer(target) then
                local body = target.server_ragdoll or target:GetRagdollEntity()
                return target, body
            end
            return GetPlayerFromBody(target), target
        end
        return target, nil
    end

    function SWEP:Reset()
        self:SetState(DEFIB_IDLE)
        self:SetBegin(-1)
        self:SetMessage('')
        self.Target = nil
    end

    function SWEP:Error(msg)
        self:SetState(DEFIB_ERROR)
        self:SetBegin(CurTime())
        self:SetMessage(msg)

        self:GetOwner():EmitSound(beep, 60, 50, 1)
        self.Target = nil

        timer.Simple(3 * 0.75, function()
            if IsValid(self) then self:Reset() end
        end)
    end

    function SWEP:DoFailure()
        local phys = self.Target:GetPhysicsObjectNum(self.Bone)

        if IsValid(phys) then
            phys:ApplyForceCenter(Vector(0, 0, 4096))
        end

        self:Error("ATTEMPT FAILED TRY AGAIN")
    end

    function SWEP:DoSuccess(target)
        local ply, body = self:GetPlayerAndBodyFromTarget(target)
        if not IsPlayer(ply) or (self.DeadTarget and ply:IsActive()) then
            self:DoFailure()
            return
        end

        self:OnSuccess(ply, body)
        if self.SingleUse then
            self:Remove()
        end
        self:Reset()
    end

    function SWEP:OnSuccess(ply, body)
        -- Override in derived weapons
    end

    function SWEP:Defib()
        sound.Play(zap, self.Target:GetPos(), 75, math.random(95, 105), 1)

        if math.random(0, 100) > self.SuccessChance then
            self:DoFailure()
            return
        end
        if not IsFirstTimePredicted() then return end

        self:DoSuccess(self.Target)
    end

    function SWEP:OnDefibStart(ply, body, bone)
        -- Override in derived weapons
    end

    function SWEP:ValidateTarget(ply, body, bone)
        -- Override in derived weapons
        return true, ""
    end

    function SWEP:GetProgressMessage(ply, body, bone)
        -- Override in derived weapons
        return "WORKING ON " .. string.upper(ply:Nick())
    end

    function SWEP:Begin(target, bone)
        local ply, body = self:GetPlayerAndBodyFromTarget(target)
        self:OnDefibStart(ply, body, bone)

        if not ply then
            self:Error("INVALID TARGET")
            return
        end

        local isValidTarget, invalidMessage = self:ValidateTarget(ply, body, bone)
        if not isValidTarget then
            self:Error(invalidMessage)
            return
        end

        self:SetState(DEFIB_BUSY)
        self:SetBegin(CurTime())
        self:SetMessage(self:GetProgressMessage(ply, body, bone))
        self:GetOwner():EmitSound(hum, 75, math.random(98, 102), 1)

        self.Target = body or ply
        self.Bone = bone
    end

    function SWEP:GetAbortMessage()
        -- Override in derived weapons
        return "WORK ABORTED"
    end

    function SWEP:IsCurrentTargetValid()
        local owner = self:GetOwner()
        return owner:KeyDown(IN_ATTACK) and owner:GetEyeTrace(MASK_SHOT_HULL).Entity == self.Target
    end

    function SWEP:Think()
        if self:GetState() == DEFIB_BUSY then
            if self:GetBegin() + self:GetChargeTime() <= CurTime() then
                self:Defib()
            elseif not self:IsCurrentTargetValid() then
                self:Error(self:GetAbortMessage())
            end
        end
    end

    function SWEP:GetTarget(primary)
        local owner = self:GetOwner()
        local tr = owner:GetEyeTrace(MASK_SHOT_HULL)
        local pos = owner:GetPos()

        if tr.HitPos:Distance(pos) > self.MaxDistance then return end

        return tr.Entity, tr.PhysicsBone
    end

    function SWEP:IsTargetValid(target, bone, primary)
        if self.DeadTarget then
            return IsValid(target) and target:GetClass() == "prop_ragdoll" and IsBodyValid(target)
        end
        return IsPlayer(target)
    end

    function SWEP:SharedAttack(primary)
        if self:GetState() ~= DEFIB_IDLE then return end
        if GetRoundState() ~= ROUND_ACTIVE then return end

        local target, bone = self:GetTarget(primary)
        if self:IsTargetValid(target, bone, primary) then
            if primary then
                self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
            else
                self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
            end
            local isRespawn = self.FindRespawnLocation and self.DeadTarget
            if isRespawn then
                local pos = self:GetOwner():GetPos()
                self.Location = FindRespawnLocation(pos) or pos
            end

            if not isRespawn or self.Location then
                self:Begin(target, bone)
            else
                self:Error("INSUFFICIENT ROOM")
                return
            end
        end
    end

    function SWEP:PrimaryAttack()
        self:SharedAttack(true)
    end

    function SWEP:SecondaryAttack()
        if not self.HasSecondary then
            return
        end
        self:SharedAttack(false)
    end

    function SWEP:Holster()
        self:Reset()
        return true
    end
end

if CLIENT then
    function SWEP:DrawHUD()
        local baseClass = self.BaseClass
        while baseClass.ClassName ~= "weapon_tttbase" do
            baseClass = baseClass.BaseClass
        end
        baseClass.DrawHUD(self)

        local state = self:GetState()
        if state == DEFIB_IDLE then return end

        local charge = self:GetChargeTime()
        local time = self:GetBegin() + charge

        local x = ScrW() / 2.0
        local y = ScrH() / 2.0

        y = y + (y / 3)

        local w = 255

        if state == DEFIB_BUSY then
            if time < 0 then return end
            local progress = math.min(1, 1 - ((time - CurTime()) / charge))
            CRHUD:PaintProgressBar(x, y, w, Color(0, 255, 0, 155), self:GetMessage(), progress)
        elseif state == DEFIB_ERROR then
            CRHUD:PaintProgressBar(x, y, w, Color(200 + math.sin(CurTime() * 32) * 50, 0, 0, 155), self:GetMessage(), 1)
        end
    end

    function SWEP:PrimaryAttack() return false end
end

function SWEP:DryFire() return false end