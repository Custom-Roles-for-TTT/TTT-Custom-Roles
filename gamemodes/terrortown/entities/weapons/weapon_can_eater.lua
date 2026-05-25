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
SWEP.GainsHealthConVar = CreateConVar("ttt_cannibal_gains_health", "0", FCVAR_REPLICATED, "Whether the Cannibal gains their victim's health when eating them", 0, 1)
SWEP.GainedHealthPercentageConVar = CreateConVar("ttt_cannibal_gained_health_percentage", "15", FCVAR_REPLICATED, "What percentage of their victim's health the Cannibal gains (set to 0 to always gain a flat 100HP)", 0, 500)
SWEP.DigestionConVar = CreateConVar("ttt_cannibal_digestion", "0", FCVAR_REPLICATED, "Whether the Cannibal digests and permanently kills their victims over time", 0, 1)
SWEP.DigestionTimeConVar = CreateConVar("ttt_cannibal_digestion_time", "30", FCVAR_REPLICATED, "How long in seconds a victim takes to be digested when eaten (set to 0 for immediate digestion)", 0, 300)

if SERVER then
    SWEP.DigestionPoopConVar = CreateConVar("ttt_cannibal_digestion_poop", "1", FCVAR_NONE, "Whether the Cannibal drops poop when a victim is digested", 0, 1)
    SWEP.DigestionPoopSoundConVar = CreateConVar("ttt_cannibal_digestion_poop_sound", "1", FCVAR_NONE, "Whether the Cannibal causes a sound when poop is dropped from a digested victim.", 0, 1)
end

local eatSounds = {
    "cannibal/eat1.wav",
    "cannibal/eat2.wav",
    "cannibal/eat3.wav"
}

local poopSounds = {
    "cannibal/poop1.wav",
    "cannibal/poop2.wav",
    "cannibal/poop3.wav",
    "cannibal/poop4.wav",
    "cannibal/poop5.wav",
    "cannibal/poop6.wav"
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

function SWEP:OnRemove()
    if SERVER then
        for sid64, _ in pairs(CANNIBAL.playerWeapons) do
            timer.Remove("TTTCannibalDigestion_" .. sid64)
        end
    end
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
        if IsValid(hitEnt.hat) then
            hitEnt.hat:SetNoDraw(true)
        end

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

        -- Cannibal health gain
        if self.GainsHealthConVar:GetBool() then
            local gained_health_percentage = self.GainedHealthPercentageConVar:GetInt()
            local victimHealth = hitEnt:Health()
            local cannibalHealth = owner:Health()

            local gainedHealth
            if gained_health_percentage == 0 then
                gainedHealth = 100
            else
                gainedHealth = math.floor((gained_health_percentage / 100) * victimHealth)
            end

            if gainedHealth > 0 then
                owner:SetHealth(cannibalHealth + gainedHealth)
            end
        end

        -- Victim digestion
        if self.DigestionConVar:GetBool() then
            local digestion_time = self.DigestionTimeConVar:GetInt()
            -- Ensure there's a short delay to allow time for the vars to be set first
            if digestion_time == 0 then
                digestion_time = 0.1
            end

            timer.Create("TTTCannibalDigestion_" .. sID64, digestion_time, 1, function()
                if not IsPlayer(hitEnt) then return end
                if not IsPlayer(owner) then return end

                -- Only digest if they are still in THIS cannibal's tummy
                if hitEnt.TTTCannibalEaten ~= owner:SteamID64() then return end

                hitEnt:Kill()
                hitEnt:ClearProperty("TTTCannibalEaten")

                hitEnt:SetParent(nil)
                hitEnt:SpectateEntity(nil)

                hitEnt:QueueMessage(MSG_PRINTBOTH, "You have been fully digested!")
                owner:QueueMessage(MSG_PRINTBOTH, "You have fully digested " .. hitEnt:Nick() .. "!")

                -- Spawn poop at cannibal's position
                if self.DigestionPoopConVar:GetBool() then
                    local poop = ents.Create("prop_physics")
                    if IsValid(poop) then
                        local fingerprints = { owner }
                        poop:SetModel("models/poo/poo.mdl")

                        local forward = owner:GetForward()
                        local dropPos = owner:GetPos() + forward * -30 + Vector(0, 0, 10)
                        poop:SetPos(dropPos)

                        poop:SetAngles(Angle(0, math.random(0, 360), 0))
                        poop:Spawn()
                        poop:Activate()
                        poop:SetCollisionGroup(COLLISION_GROUP_WEAPON)
                        poop.fingerprints = fingerprints

                        if self.DigestionPoopSoundConVar:GetBool()then
                            owner:EmitSound(poopSounds[math.random(#poopSounds)], 100)
                        end
                    end
                end
            end)
        end
    end
end

function SWEP:DrawWorldModel(flags)
    return false
end

function SWEP:DrawWorldModelTranslucent(flags)
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
        if cooldownLeft > -3 or (self.DeployTime and self.DeployTime > CurTime() - 3) then
            if progress > 1 then
                CRHUD:PaintProgressBar(x, y, w, Color(0, 255, 0, 155), "READY TO EAT", 1)
            else
                CRHUD:PaintProgressBar(x, y, w, Color(200 + math.sin(CurTime() * 32) * 50, 0, 0, 155), "NOT HUNGRY", progress)
            end
        end
    end
end
