-- Defib v2 (revision 20170303)

-- This code is copyright (c) 2016-2017 all rights reserved - "Vadim" @ jmwparq@gmail.com
-- (Re)sale of this code and/or products containing part of this code is strictly prohibited
-- Exclusive rights to usage of this product in "Trouble in Terrorist Town" are given to:
-- - The Garry's Mod community

AddCSLuaFile()

local hook = hook
local IsValid = IsValid
local math = math
local net = net
local pairs = pairs
local player = player
local surface = surface
local string = string
local table = table
local timer = timer
local util = util

SWEP.HoldType = "pistol"
SWEP.LimitedStock = true

if CLIENT then
    SWEP.PrintName = "Zombification Device"
    SWEP.Slot = 8

    SWEP.ViewModelFOV = 78
    SWEP.DrawCrosshair = false
    SWEP.ViewModelFlip = false

    SWEP.EquipMenuData = {
        type = "item_weapon",
        desc = "Turns dead players into zombies."
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

SWEP.InLoadoutFor = {ROLE_MADSCIENTIST}

SWEP.AllowDrop = false

-- settings
local maxdist = 64
local success = 100
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
local oldScoreGroup = nil

if SERVER then
    CreateConVar("ttt_madscientist_device_time", "4")
end

if CLIENT then
    function SWEP:Initialize()
        self:AddHUDHelp("zombificator_help_pri", "zombificator_help_sec", true)
        return self.BaseClass.Initialize(self)
    end
end

function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "State")
    self:NetworkVar("Int", 1, "ChargeTime")
    self:NetworkVar("Float", 0, "Begin")
    self:NetworkVar("String", 0, "Message")

    if SERVER then
        self:SetChargeTime(GetConVar("ttt_madscientist_device_time"):GetInt())
    end
end

function SWEP:OnDrop()
    self:Remove()
end

if SERVER then
    util.AddNetworkString("TTT_Zombificator_Hide")
    util.AddNetworkString("TTT_Zombificator_Revived")

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
        if ply:IsTraitor() and CORPSE.GetFound(body, false) == true then
            local plys = {}

            for _, v in pairs(player.GetAll()) do
                if not v:IsTraitor() then
                    table.insert(plys, v)
                end
            end

            net.Start("TTT_Zombificator_Hide")
            net.WriteEntity(ply)
            net.WriteBool(true)
            net.Send(plys)
        end

        net.Start("TTT_Zombificator_Revived")
        net.WriteBool(true)
        net.Send(ply)

        local owner = self:GetOwner()
        hook.Call("TTTPlayerDefibRoleChange", nil, owner, ply)

        net.Start("TTT_Zombified")
        net.WriteString(ply:Nick())
        net.Broadcast()

        ply:SpawnForRound(true)
        ply:SetCredits(credits)
        ply:SetPos(self.Location or body:GetPos())
        ply:SetEyeAngles(Angle(0, body:GetAngles().y, 0))
        ply:SetRole(ROLE_ZOMBIE)
        ply:StripRoleWeapons()
        ply:PrintMessage(HUD_PRINTCENTER, "You have been turned into a zombie.")
        SetRoleHealth(ply)

        SafeRemoveEntity(body)

        SendFullStateUpdate()
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

        if not ply then
            self:Error("INVALID TARGET")
            return
        end

        if ply:IsZombie() then
            self:Error("SUBJECT IS ALREADY A ZOMBIE")
            return
        end

        self:SetState(DEFIB_BUSY)
        self:SetBegin(CurTime())
        self:SetMessage("ZOMBIFYING " .. string.upper(ply:Nick()))

        self:GetOwner():EmitSound(hum, 75, math.random(98, 102), 1)

        self.Target = body
        self.Bone = bone
    end

    function SWEP:Think()
        if self:GetState() == DEFIB_BUSY then
            if self:GetBegin() + self:GetChargeTime() <= CurTime() then
                self:Defib()
            elseif not self:GetOwner():KeyDown(IN_ATTACK) or self:GetOwner():GetEyeTrace(MASK_SHOT_HULL).Entity ~= self.Target then
                self:Error("ZOMBIFYING ABORTED")
            end
        end
    end

    function SWEP:PrimaryAttack()
        if self:GetState() ~= DEFIB_IDLE then return end

        local owner = self:GetOwner()
        local tr = owner:GetEyeTrace(MASK_SHOT_HULL)
        local pos = owner:GetPos()

        if tr.HitPos:Distance(pos) > maxdist then return end
        if GetRoundState() ~= ROUND_ACTIVE then return end

        local ent = tr.Entity
        if IsValid(ent) then
            if ent:GetClass() == "prop_physics" and mutate[ent:GetModel()] and mutateok > 0 then
                self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
                ent:EmitSound(zap, 75, math.random(98, 102))
                ent:SetModelScale(math.min(mutatemax, ent:GetModelScale() + 0.25), 1)
            elseif ent:GetClass() == "prop_ragdoll" and validbody(ent) then
                self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
                self.Location = FindRespawnLocation(pos) or pos

                if self.Location then
                    self:Begin(ent, tr.PhysicsBone)
                else
                    self:Error("INSUFFICIENT ROOM")
                    return
                end
            end
        end
    end
end

if CLIENT then
    net.Receive("TTT_Zombificator_Hide", function(len, ply)
        if ply or len <= 0 then return end

        local hply = net.ReadEntity()
        hply.MadZomHide = net.ReadBool()
    end)

    net.Receive("TTT_Zombificator_Revived", function(len, ply)
        if ply or len <= 0 then return end
        surface.PlaySound(revived)
    end)

    hook.Remove("TTTEndRound", "RemoveZombificatorHide")
    hook.Add("TTTEndRound", "RemoveZombificatorHide", function()
        for _, v in pairs(player.GetAll()) do v.MadZomHide = nil end
    end)

    oldScoreGroup = oldScoreGroup or ScoreGroup

    function ScoreGroup(ply)
        if ply.MadZomHide then return GROUP_FOUND end
        return oldScoreGroup(ply)
    end

    function SWEP:DrawHUD()
        local state = self:GetState()
        self.BaseClass.DrawHUD(self)

        if state == DEFIB_IDLE then return end

        local charge = self:GetChargeTime()
        local time = self:GetBegin() + charge

        local x = ScrW() / 2.0
        local y = ScrH() / 2.0

        y = y + (y / 3)

        local w, h = 255, 20

        if state == DEFIB_BUSY then
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