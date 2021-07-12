-- Defib v2 (revision 20170303)

-- This code is copyright (c) 2016-2017 all rights reserved - "Vadim" @ jmwparq@gmail.com
-- (Re)sale of this code and/or products containing part of this code is strictly prohibited
-- Exclusive rights to usage of this product in "Trouble in Terrorist Town" are given to:
-- - The Garry's Mod community

AddCSLuaFile()

SWEP.HoldType = "pistol"
SWEP.LimitedStock = true

if CLIENT then
    SWEP.PrintName = "Bodysnatching Device"
    SWEP.Slot = 8

    SWEP.ViewModelFOV = 78
    SWEP.DrawCrosshair = false
    SWEP.ViewModelFlip = false

    SWEP.EquipMenuData = {
        type = "item_weapon",
        desc = "Changes your role to that of a corpses."
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

SWEP.InLoadoutFor = {ROLE_BODYSNATCHER}

SWEP.Charge = 0
SWEP.Timer = -1
SWEP.AllowDrop = false

-- settings
local maxdist = 64
local success = 100
local charge = 5

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
    util.AddNetworkString("TTT_Bodysnatched")
    util.AddNetworkString("TTT_ScoreBodysnatch")

    local offsets = {}

    for i = 0, 360, 15 do
        table.insert(offsets, Vector(math.sin(i), math.cos(i), 0))
    end

    local function validbody(body)
        return (CORPSE.GetPlayerNick(body, false) ~= false)
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

    function SWEP:DoBodysnatch(body)
        local ply = bodyply(body)

        net.Start("TTT_Bodysnatched")
        net.WriteBool(true)
        net.Send(ply)

        net.Start("TTT_ScoreBodysnatch")
        net.WriteString(ply:Nick())
        net.WriteString(self:GetOwner():Nick())
        net.WriteString(ROLE_STRINGS_EXT[ply:GetRole()])
        net.Broadcast()

        local role = ply:GetRole()
        self:GetOwner():SetRole(role)

        if GetConVar("ttt_bodysnatcher_destroy_body"):GetBool() then
            body:Remove()
        end

        SendFullStateUpdate()

        self:Remove()
    end

    function SWEP:Defib()
        sound.Play(zap, self.Target:GetPos(), 75, math.random(95, 105), 1)

        if math.random(0, 100) > success then
            local phys = self.Target:GetPhysicsObjectNum(self.Bone)

            if IsValid(phys) then
                phys:ApplyForceCenter(Vector(0, 0, 4096))
            end

            self:Error("ATTEMPT FAILED TRY AGAIN")
            return
        end
        if not IsFirstTimePredicted() then return end

        self:DoBodysnatch(self.Target)
        self:Reset()
    end

    function SWEP:Begin(body, bone)
        local ply = bodyply(body)

        if not ply then
            self:Error("INVALID TARGET")
            return
        end

        self:SetState(DEFIB_BUSY)
        self:SetBegin(CurTime())
        if GetConVar("ttt_bodysnatcher_show_role"):GetBool() then
            self:SetMessage("BODYSNATCHING " .. string.upper(ply:Nick()) .. " [" .. string.upper(ROLE_STRINGS[ply:GetRole()]) .. "]")
        else
            self:SetMessage("BODYSNATCHING " .. string.upper(ply:Nick()))
        end

        self:GetOwner():EmitSound(hum, 75, math.random(98, 102), 1)

        self.Target = body
        self.Bone = bone
    end

    function SWEP:Think()
        if self:GetState() == DEFIB_BUSY then
            if self:GetBegin() + charge <= CurTime() then
                self:Defib()
            elseif not self:GetOwner():KeyDown(IN_ATTACK) or self:GetOwner():GetEyeTrace(MASK_SHOT_HULL).Entity ~= self.Target then
                self:Error("BODYSNATCH ABORTED")
            end
        end
    end

    function SWEP:PrimaryAttack()
        if self:GetState() ~= DEFIB_IDLE then return end

        local tr = self:GetOwner():GetEyeTrace(MASK_SHOT_HULL)

        if tr.HitPos:Distance(self:GetOwner():GetPos()) > maxdist then return end
        if GetRoundState() ~= ROUND_ACTIVE then return end

        local ent = tr.Entity

        if ent and IsValid(ent) then
            if ent:GetClass() == "prop_ragdoll" and validbody(ent) then
                self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
                self:Begin(ent, tr.PhysicsBone)
            end
        end
    end
end

if CLIENT then
    net.Receive("TTT_Bodysnatched", function(len, ply)
        if ply or len <= 0 then return end
        surface.PlaySound(revived)
    end)

    function SWEP:DrawHUD()
        local state = self:GetState()
        self.BaseClass.DrawHUD(self)

        if state == DEFIB_IDLE then return end

        local timer = self:GetBegin() + charge

        local x = ScrW() / 2.0
        local y = ScrH() / 2.0

        y = y + (y / 3)

        local w, h = 255, 20

        if state == DEFIB_BUSY then
            if timer < 0 then return end

            local cc = math.min(1, 1 - ((timer - CurTime()) / charge))

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