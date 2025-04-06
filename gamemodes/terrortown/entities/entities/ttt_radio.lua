---- Radio equipment playing distraction sounds

AddCSLuaFile()

local concommand = concommand
local IsValid = IsValid
local math = math
local table = table
local sound = sound
local timer = timer
local util = util

local MathRand = math.Rand
local MathRandom = math.random
local SoundPlay = sound.Play
local TableAdd = table.Add
local TableHasValue = table.HasValue
local TableInsert = table.insert
local TableRandom = table.Random
local TableRemove = table.remove
local TimerSimple = timer.Simple
local UtilEffect = util.Effect

if CLIENT then
   -- this entity can be DNA-sampled so we need some display info
   ENT.Icon = "vgui/ttt/icon_radio"
   ENT.PrintName = "radio_name"
end

ENT.Type = "anim"
ENT.Model = Model("models/props/cs_office/radio.mdl")

ENT.CanUseKey = true
ENT.CanHavePrints = false
ENT.SoundLimit = 5
ENT.SoundDelay = 0.5

function ENT:Initialize()
    self:SetModel(self.Model)

    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_NONE)
    if SERVER then
        self:SetMaxHealth(40)
    end
    self:SetHealth(40)

    if SERVER then
        self:SetUseType(SIMPLE_USE)
    end

    -- Register with owner
    if CLIENT then
        if LocalPlayer() == self:GetOwner() then
            LocalPlayer().radio = self
        end
    end

    self.SoundQueue = {}
    self.Playing = false
    self.fingerprints = {}
end

function ENT:UseOverride(activator)
    local owner = self:GetOwner()
    if IsPlayer(activator) and IsPlayer(owner) and activator:IsActive() and activator:IsSameTeam(owner) then
        local prints = self.fingerprints or {}
        self:Remove()

        local wep = activator:Give("weapon_ttt_radio")
        if IsValid(wep) then
            wep.fingerprints = wep.fingerprints or {}
            TableAdd(wep.fingerprints, prints)
        end
    end
end

local zapsound = Sound("npc/assassin/ball_zap1.wav")
function ENT:OnTakeDamage(dmginfo)
    self:TakePhysicsDamage(dmginfo)

    self:SetHealth(self:Health() - dmginfo:GetDamage())
    if self:Health() < 0 then
        self:Remove()

        local effect = EffectData()
        effect:SetOrigin(self:GetPos())
        UtilEffect("cball_explode", effect)
        SoundPlay(zapsound, self:GetPos())

        if IsValid(self:GetOwner()) then
            LANG.Msg(self:GetOwner(), "radio_broken")
        end
    end
end

function ENT:OnRemove()
    if CLIENT then
        if LocalPlayer() == self:GetOwner() then
            LocalPlayer().radio = nil
        end
    end
end

function ENT:AddSound(snd)
    if #self.SoundQueue < self.SoundLimit then
        TableInsert(self.SoundQueue, snd)
    end
end

local simplesounds = {
    scream = {
        Sound("vo/npc/male01/pain07.wav"),
        Sound("vo/npc/male01/pain08.wav"),
        Sound("vo/npc/male01/pain09.wav"),
        Sound("vo/npc/male01/no02.wav")
    },
    explosion = {
        Sound("BaseExplosionEffect.Sound")
    }
};

local serialsounds = {
    footsteps = {
        sound = {
            {Sound("player/footsteps/concrete1.wav"), Sound("player/footsteps/concrete2.wav")},
            {Sound("player/footsteps/concrete3.wav"), Sound("player/footsteps/concrete4.wav")}
        },
        times = {8, 16},
        delay = 0.35,
        ampl = 80
    },

    burning = {
        sound = {
            Sound("General.BurningObject"),
            Sound("General.StopBurning")
        },
        times = {2, 2},
        delay = 4,
    },


    beeps = {
        sound = { Sound("weapons/c4/c4_beep1.wav") },
        delay = 0.75,
        times = {8, 12},
        ampl = 70
    }
};

local gunsounds = {
    shotgun = {
        sound = Sound( "Weapon_XM1014.Single" ),
        delay = 0.8,
        times = {1, 3},
        burst = false
    },

    pistol = {
        sound = Sound( "Weapon_FiveSeven.Single" ),
        delay = 0.4,
        times = {2, 4},
        burst = false
    },

    mac10 = {
        sound = Sound( "Weapon_mac10.Single" ),
        delay = 0.065,
        times = {5, 10},
        burst = true
    },

    deagle = {
        sound = Sound( "Weapon_Deagle.Single" ),
        delay = 0.6,
        times = {1, 3},
        burst = false
    },

    m16 = {
        sound = Sound( "Weapon_M4A1.Single" ),
        delay = 0.2,
        times = {1, 5},
        burst = true
    },

    rifle = {
        sound = Sound( "weapons/scout/scout_fire-1.wav" ),
        delay = 1.5,
        times = {1, 1},
        burst = false,
        ampl = 80
    },

    huge = {
        sound = Sound( "Weapon_m249.Single" ),
        delay = 0.055,
        times = {6, 12},
        burst = true
    }
};

function ENT:PlayDelayedSound(snd, ampl, last)
    -- maybe we can get destroyed while a timer is still up
    if IsValid(self) then
        if istable(snd) then
            snd = TableRandom(snd)
        end

        if self.BroadcastSound then
            self:BroadcastSound(snd, ampl)
        else
            SoundPlay(snd, self:GetPos(), ampl)
        end
        self.Playing = not last
    end
end

function ENT:PlaySound(snd)
    local pos = self:GetPos()
    local this = self
    if simplesounds[snd] then
        if self.BroadcastSound then
            self:BroadcastSound(TableRandom(simplesounds[snd]))
        else
            SoundPlay(TableRandom(simplesounds[snd]), pos)
        end
    elseif gunsounds[snd] then
        local gunsound = gunsounds[snd]
        local times = MathRandom(gunsound.times[1], gunsound.times[2])
        local t = 0
        for i=1, times do
            TimerSimple(t,
                        function()
                            if IsValid(this) then
                                this:PlayDelayedSound(gunsound.sound, gunsound.ampl or 90, i == times)
                            end
                        end)

            if gunsound.burst then
                t = t + gunsound.delay
            else
                t = t + MathRand(gunsound.delay, gunsound.delay * 2)
            end
        end
    elseif serialsounds[snd] then
        local serialsound = serialsounds[snd]
        local num = #serialsound.sound
        local times = MathRandom(serialsound.times[1], serialsound.times[2])
        local t = 0
        local idx = 1
        for i=1, times do
            local chosen = serialsound.sound[idx]
            TimerSimple(t,
                        function()
                            if IsValid(this) then
                                this:PlayDelayedSound(chosen, serialsound.ampl or 75, i == times)
                            end
                        end)

            t = t + serialsound.delay
            idx = idx + 1
            if idx > num then idx = 1 end
        end
    end
end

local nextplay = 0
function ENT:Think()
    if CurTime() > nextplay and #self.SoundQueue > 0 then
        if not self.Playing then
            local snd = TableRemove(self.SoundQueue, 1)
            self:PlaySound(snd)
        end

        -- always do this, makes timing work out a little better
        nextplay = CurTime() + self.SoundDelay
    end
end

if SERVER then
    local soundtypes = {
        "scream", "shotgun", "explosion",
        "pistol", "mac10", "deagle",
        "m16", "rifle", "huge",
        "burning", "beeps", "footsteps"
    };

    local function RadioCmd(ply, cmd, args)
        if not IsValid(ply) then return end
        if #args ~= 2 then return end

        local eidx = tonumber(args[1])
        local snd = tostring(args[2])
        if not eidx or not snd then return end

        local radio = Entity(eidx)
        if not IsValid(radio) then return end
        if radio:GetOwner() ~= ply then return end
        if radio:GetClass() ~= "ttt_radio" then return end

        if not TableHasValue(soundtypes, snd) then
            print("Received radio sound not in table from", ply)
            return
        end

        radio:AddSound(snd)
    end
    concommand.Add("ttt_radio_play", RadioCmd)
end