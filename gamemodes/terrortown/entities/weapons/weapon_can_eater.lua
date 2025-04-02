AddCSLuaFile()

if CLIENT then
    SWEP.PrintName          = "Cannibalizer"
    SWEP.Slot               = 8

    SWEP.ViewModelFOV        = 10
end

SWEP.ViewModel              = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel             = "models/weapons/w_crowbar.mdl"

SWEP.Base                   = "weapon_tttbase"
SWEP.Category               = WEAPON_CATEGORY_ROLE

SWEP.Spawnable              = false
SWEP.AutoSpawnable          = false
SWEP.HoldType               = "normal"
SWEP.Kind                   = WEAPON_ROLE

SWEP.DeploySpeed            = 4
SWEP.AllowDrop              = false
SWEP.NoSights               = true
SWEP.LimitedStock           = true
SWEP.AmmoEnt                = nil

SWEP.Primary.Delay          = 0.2
SWEP.Primary.Automatic      = false
SWEP.Primary.Cone           = 0
SWEP.Primary.Ammo           = nil
SWEP.Primary.ClipSize       = -1
SWEP.Primary.ClipMax        = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Sound          = ""

SWEP.InLoadoutFor           = {ROLE_CANNIBAL}
SWEP.InLoadoutForDefault    = {ROLE_CANNIBAL}

SWEP.DeviceCooldownConVar = CreateConVar("ttt_cannibal_eat_cooldown", "10", FCVAR_REPLICATED, "The amount of time (in seconds) between uses of the Cannibal's Cannibalizer", 0, 60)

local eatSounds = {
    "cannibal/eat1.wav",
    "cannibal/eat2.wav",
    "cannibal/eat3.wav"
}

function SWEP:Initialize()
    if CLIENT then
        self:AddHUDHelp("can_eater_help_pri", nil, true)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:SetupDataTables()
    self:NetworkVar("Float", 0, "DeviceCooldownEnd")
    if SERVER then
        self:SetDeviceCooldownEnd(CurTime())
    end
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:Deploy()
    if SERVER and IsValid(self:GetOwner()) then
        self:GetOwner():DrawViewModel(false)
    end

    if CLIENT then
        self.DeployTime = CurTime()
    end

    self:DrawShadow(false)

    return true
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    if CurTime() < self:GetDeviceCooldownEnd() then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    if not owner:IsActiveCannibal() or owner:IsRoleAbilityDisabled() then return end

    local spos = owner:GetShootPos()
    local sdest = spos + (owner:GetAimVector() * 70)
    local kmins = Vector(1,1,1) * -10
    local kmaxs = Vector(1,1,1) * 10

    local tr_main = util.TraceHull({start=spos, endpos=sdest, filter=owner, mask=MASK_SHOT_HULL, mins=kmins, maxs=kmaxs})
    local hitEnt = tr_main.Entity

    if SERVER and IsPlayer(hitEnt) then
        hitEnt:Spectate(OBS_MODE_CHASE)
        hitEnt:SpectateEntity(owner)
        hitEnt:DrawViewModel(false)
        hitEnt:DrawWorldModel(false)

        local sID64 = hitEnt:SteamID64()

        CANNIBAL.playerWeapons[sID64] = {}

        for _, v in pairs(hitEnt:GetWeapons()) do
            local class = WEPS.GetClass(v)
            table.insert(CANNIBAL.playerWeapons[sID64], {
                class = class,
                clip1 = v:Clip1(),
                clip2 = v:Clip2(),
                PAPUpgrade = v.PAPUpgrade
            })
            hitEnt:StripWeapon(class)
        end

        hitEnt:SetFOV(0, 0.2)

        hitEnt:SetProperty("TTTCannibalEaten", owner:SteamID64())
        hitEnt:QueueMessage(MSG_PRINTBOTH, "You have been eaten by " .. owner:Nick() .. "!")

        owner:EmitSound(eatSounds[math.random(1, #eatSounds)], 100)

        local cooldown = self.DeviceCooldownConVar:GetInt()
        if cooldown > 0 then
            self:SetDeviceCooldownEnd(CurTime() + cooldown)
        end
    end
end

function SWEP:DrawWorldModel()
    return false
end

function SWEP:DrawWorldModelTranslucent()
    return false
end

if CLIENT then
    function SWEP:DrawHUD()
        self.BaseClass.DrawHUD(self)

        local cooldown = self.DeviceCooldownConVar:GetInt()
        if cooldown == 0 then return end

        local x = ScrW() / 2.0
        local y = ScrH() / 2.0

        y = y + (y / 3)

        local w = 255

        local cooldownLeft = self:GetDeviceCooldownEnd() - CurTime()
        local progress = 1 - (cooldownLeft / cooldown)
        if cooldownLeft > -3 or self.DeployTime > CurTime() - 3 then
            if progress > 1 then
                CRHUD:PaintProgressBar(x, y, w, Color(0, 255, 0, 155), "READY TO EAT", 1)
            else
                CRHUD:PaintProgressBar(x, y, w, Color(200 + math.sin(CurTime() * 32) * 50, 0, 0, 155), "NOT HUNGRY", progress)
            end
        end
    end
end