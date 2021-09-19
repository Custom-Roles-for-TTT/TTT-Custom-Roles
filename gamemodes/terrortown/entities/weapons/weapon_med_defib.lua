-- Defib v2 (revision 20170303)

-- This code is copyright (c) 2016-2017 all rights reserved - "Vadim" @ jmwparq@gmail.com
-- (Re)sale of this code and/or products containing part of this code is strictly prohibited
-- Exclusive rights to usage of this product in "Trouble in Terrorist Town" are given to:
-- - The Garry's Mod community

AddCSLuaFile()

SWEP.HoldType = "pistol"
SWEP.LimitedStock = true

if CLIENT then
    SWEP.PrintName = "Defibrillator"
    SWEP.Slot = 8

    SWEP.ViewModelFOV = 78
    SWEP.DrawCrosshair = false
    SWEP.ViewModelFlip = false

    SWEP.EquipMenuData = {
        type = "item_weapon",
        desc = "Revives a dead player."
    }
end

SWEP.Base = "weapon_tttbase"
SWEP.Category = WEAPON_CATEGORY_ROLE

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
SWEP.Secondary.Delay = 1.25

SWEP.InLoadoutFor = {ROLE_PARAMEDIC}
SWEP.InLoadoutForDefault = {ROLE_PARAMEDIC}

SWEP.Charge = 0
SWEP.Timer = -1
SWEP.AllowDrop = false

-- settings
local maxdist = 64
local success = 100
local charge = 8
local mutateok = 0
local mutatemax = 0

local mutate = {
    ["models/props_junk/watermelon01.mdl"] = true,
    ["models/props/cs_italy/orange.mdl"] = true,
    ["models/props/cs_italy/bananna.mdl"] = true,
    ["models/props/cs_italy/bananna_bunch.mdl"] = true
}

local beep = Sound("buttons/button17.wav")
local hum = Sound("items/nvg_on.wav")
local zap = Sound("ambient/energy/zap7.wav")
local revived = Sound("items/smallmedkit1.wav")

SWEP.Kind = WEAPON_ROLE

SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/v_c4.mdl"
SWEP.WorldModel = "models/weapons/w_c4.mdl"

SWEP.AutoSpawnable = false
SWEP.NoSights = true

local DEFIB_IDLE = 0
local DEFIB_BUSY = 1
local DEFIB_ERROR = 2

if CLIENT then
    function SWEP:Initialize()
        self:AddHUDHelp("defibrillator_help_pri", "defibrillator_help_sec", true)
        self:SetHoldType(self.HoldType)
    end
end

function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "State")
    self:NetworkVar("Float", 1, "Begin")
    self:NetworkVar("String", 0, "Message")
end

function SWEP:OnDrop()
    self:Remove()
end

if SERVER then

    util.AddNetworkString("TTT_Paramedic_Revived")

    local offsets = {}

    for i = 0, 360, 15 do
        table.insert(offsets, Vector(math.sin(i), math.cos(i), 0))
    end

    function SWEP:FindRespawnLocation()
        local midsize = Vector(33, 33, 74)
        local tstart = self:GetOwner():GetPos() + Vector(0, 0, midsize.z / 2)

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

            if not tr.Hit then return v - Vector(0, 0, midsize.z / 2) end
        end

        return false
    end

    local function validbody(body)
        return CORPSE.GetPlayerNick(body, false) ~= false
    end

    local function bodyply(body)
        local ply = false

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

    function SWEP:DoRespawnFailure()
        local phys = self.Target:GetPhysicsObjectNum(self.Bone)

        if IsValid(phys) then
            phys:ApplyForceCenter(Vector(0, 0, 4096))
        end

        self:Error("ATTEMPT FAILED TRY AGAIN")
    end

    function SWEP:DoRespawn(body)
        local ply = bodyply(body)
        if not ply or ply:Alive() and not ply:IsSpec() then
            self:DoRespawnFailure()
            return
        end

        local credits = CORPSE.GetCredits(body, 0) or 0

        net.Start("TTT_Paramedic_Revived")
        net.WriteBool(true)
        net.Send(ply)

        -- Un-haunt the player if the target was the Phantom or Parasite
        local owner = self:GetOwner()
        if ply:IsPhantom() and ply:GetNWString("HauntingTarget", nil) == owner:SteamID64() then
            owner:SetNWBool("Haunted", false)
        elseif ply:IsParasite() and ply:GetNWString("InfectingTarget", nil) == owner:SteamID64() then
            owner:SetNWBool("Infected", false)
        end

        ply:SpawnForRound(true)
        ply:SetCredits(credits)
        ply:SetPos(self.Location or body:GetPos())
        ply:SetEyeAngles(Angle(0, body:GetAngles().y, 0))
        if GetConVar("ttt_paramedic_defib_as_innocent"):GetBool() then
            ply:SetRole(ROLE_INNOCENT)
            ply:StripRoleWeapons()
        elseif ply:GetDetectiveLike() then
            if ply:IsInnocentTeam() then
                ply:SetRole(ROLE_INNOCENT)
            elseif ply:IsTraitorTeam() then
                ply:SetRole(ROLE_TRAITOR)
            end
            ply:StripRoleWeapons()
        end
        ply:PrintMessage(HUD_PRINTCENTER, "You have been revived by " .. ROLE_STRINGS_EXT[ROLE_PARAMEDIC] .. "!")
        ply:SetHealth(ply:GetMaxHealth())

        SafeRemoveEntity(body)

        SendFullStateUpdate()

        self:GetOwner():ConCommand("lastinv")
        self:Remove()
        self:Reset()
    end

    function SWEP:Defib()
        sound.Play(zap, self.Target:GetPos(), 75, math.random(95, 105), 1)

        if math.random(0, 100) > success then
            self:DoRespawnFailure()
            return
        end
        if not IsFirstTimePredicted() then return end

        self:DoRespawn(self.Target)
    end

    function SWEP:Begin(body, bone)
        local ply = bodyply(body)

        if not ply then self:Error("INVALID TARGET") return end

        self:SetState(DEFIB_BUSY)
        self:SetBegin(CurTime())
        self:SetMessage("DEFIBRILLATING " .. string.upper(ply:Nick()))

        self:GetOwner():EmitSound(hum, 75, math.random(98, 102), 1)

        self.Target = body
        self.Bone = bone
    end

    function SWEP:Think()
        if self:GetState() == DEFIB_BUSY then
            if self:GetBegin() + charge <= CurTime() then
                self:Defib()
            elseif not self:GetOwner():KeyDown(IN_ATTACK) or self:GetOwner():GetEyeTrace(MASK_SHOT_HULL).Entity ~= self.Target then
                self:Error("DEFIBRILLATION ABORTED")
            end
        end
    end

    function SWEP:PrimaryAttack()
        if self:GetState() ~= DEFIB_IDLE then return end

        local tr = self:GetOwner():GetEyeTrace(MASK_SHOT_HULL)

        if tr.HitPos:Distance(self:GetOwner():GetPos()) > maxdist then return end
        if GetRoundState() ~= ROUND_ACTIVE then return end

        local ent = tr.Entity
        if IsValid(ent) then
            if ent:GetClass() == "prop_physics" and mutate[ent:GetModel()] and mutateok > 0 then
                self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
                ent:EmitSound(zap, 75, math.random(98, 102))
                ent:SetModelScale(math.min(mutatemax, ent:GetModelScale() + 0.25), 1)
            elseif ent:GetClass() == "prop_ragdoll" and validbody(ent) then
                self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
                self.Location = self:FindRespawnLocation()

                if self.Location then
                    self:Begin(ent, tr.PhysicsBone)
                else
                    self:Error("INSUFFICIENT ROOM")
                    return
                end
            elseif ent:IsPlayer() and ent:IsActive() and ent:IsJesterTeam() and not ent:IsFrozen() then
                self:SetNextPrimaryFire(CurTime() + 0.1)
                ent:EmitSound(zap, 100, math.random(98, 102))
                ent:Freeze(true)
                ent:ScreenFade(SCREENFADE.IN, Color(255, 255, 255, 255), 1, 10)
                timer.Simple(10, function()
                    if IsValid(ent) then
                        ent:Freeze(false)
                    end
                end)
            end
        end
    end
end

if CLIENT then
    net.Receive("TTT_Paramedic_Revived", function(len, ply)
        if ply or len <= 0 then return end
        surface.PlaySound(revived)
    end)

    function SWEP:DrawHUD()
        local state = self:GetState()
        self.BaseClass.DrawHUD(self)

        if state == DEFIB_IDLE then return end

        local x = ScrW() / 2.0
        local y = ScrH() / 2.0

        y = y + (y / 3)

        local w, h = 255, 20

        if state == DEFIB_BUSY then
            local time = self:GetBegin() + charge
            if time < 0 then return end

            local cc = math.min(1, 1 - ((time - CurTime()) / charge))

            surface.SetDrawColor(0, 255, 0, 155)

            surface.DrawOutlinedRect(x - w / 2, y - h, w, h)

            surface.DrawRect(x - w / 2, y - h, w * cc, h)

            surface.SetFont("TabLarge")
            surface.SetTextColor(255, 255, 255, 180)
            surface.SetTextPos((x - w / 2) + 3, y - h - 15)
            surface.DrawText(self:GetMessage())
        elseif state == DEFIB_ERROR then
            surface.SetDrawColor(200 + math.sin(CurTime() * 32) * 50, 0, 0, 155)

            surface.DrawOutlinedRect(x - w / 2, y - h, w, h)

            surface.DrawRect(x - w / 2, y - h, w, h)

            surface.SetFont("TabLarge")
            surface.SetTextColor(255, 255, 255, 180)
            surface.SetTextPos((x - w / 2) + 3, y - h - 15)
            surface.DrawText(self:GetMessage())
        end
    end

    function SWEP:PrimaryAttack() return false end
end

function SWEP:DryFire() return false end