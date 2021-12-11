AddCSLuaFile()

local ents = ents
local IsValid = IsValid
local math = math
local surface = surface
local timer = timer

SWEP.HoldType = "slam"

if CLIENT then
    local GetPTranslation = LANG.GetParamTranslation
    local GetTranslation = LANG.GetTranslation
    SWEP.PrintName = "stationb_name"
    SWEP.Slot = 6
    SWEP.ViewModelFOV = 54
    SWEP.DrawCrosshair = false

    SWEP.EquipMenuData = {
        type = "item_weapon",
        desc = function()
            return GetPTranslation("stationb_desc", {
                healthstation = GetTranslation("hstation_name"),
                bombstation = GetTranslation("bstation_name")
            })
        end
    };

    SWEP.Icon = "vgui/ttt/icon_stationbomb"
end

SWEP.Base = "weapon_tttbase"
SWEP.Category = WEAPON_CATEGORY_ROLE

SWEP.UseHands = true
SWEP.ViewModel = Model("models/weapons/cstrike/c_c4.mdl")
SWEP.WorldModel = Model("models/weapons/w_c4.mdl")

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 1.0

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Delay = 1.0

local beep = Sound("buttons/button17.wav")
local hum = Sound("items/nvg_on.wav")
local zap = Sound("weapons/c4_initiate.mp3")

-- This is special equipment
SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = { ROLE_QUACK }
SWEP.LimitedStock = true
SWEP.WeaponID = AMMO_STATIONBOMB

SWEP.AllowDrop = false
SWEP.NoSights = true

-- settings
local maxdist = 64

local DEFIB_IDLE = 0
local DEFIB_BUSY = 1
local DEFIB_ERROR = 2

if SERVER then
    CreateConVar("ttt_quack_station_bomb_time", "4")
end

if CLIENT then
    function SWEP:Initialize()
        self:AddHUDHelp("stationb_help", nil, true)
        return self.BaseClass.Initialize(self)
    end
end

function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "State")
    self:NetworkVar("Int", 1, "ChargeTime")
    self:NetworkVar("Float", 0, "Begin")
    self:NetworkVar("String", 0, "Message")

    if SERVER then
        self:SetChargeTime(GetConVar("ttt_quack_station_bomb_time"):GetInt())
    end
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:OnRemove()
    if CLIENT and IsValid(self:GetOwner()) and self:GetOwner() == LocalPlayer() and self:GetOwner():Alive() then
        RunConsoleCommand("lastinv")
    end
end

if SERVER then
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

    function SWEP:Bomb()
        sound.Play(zap, self.Target:GetPos(), 75, math.random(95, 105), 1)

        if not IsFirstTimePredicted() then return end

        if not IsValid(self.Target) then
            self:Error("ATTEMPT FAILED TRY AGAIN")
            return
        end

        local bomb = ents.Create("ttt_bomb_station")
        if IsValid(bomb) then
            local owner = self:GetOwner()
            local pos = self.Target:GetPos()
            local ang = self.Target:GetAngles()

            SafeRemoveEntity(self.Target)

            bomb:SetPos(pos)
            bomb:SetAngles(ang)
            bomb:Spawn()

            bomb:SetPlacer(owner)
            bomb:PhysWake()

            self:Remove()
        else
            self:Error("ATTEMPT FAILED TRY AGAIN")
            return
        end

        self:Reset()
    end

    function SWEP:Begin(ent)
        if not IsValid(ent) then
            self:Error("INVALID TARGET")
            return
        end

        self:SetState(DEFIB_BUSY)
        self:SetBegin(CurTime())
        self:SetMessage("PLANTING BOMB")

        self:GetOwner():EmitSound(hum, 75, math.random(98, 102), 1)

        self.Target = ent
    end

    function SWEP:Think()
        if self:GetState() == DEFIB_BUSY then
            if self:GetBegin() + self:GetChargeTime() <= CurTime() then
                self:Bomb()
            elseif not self:GetOwner():KeyDown(IN_ATTACK) or self:GetOwner():GetEyeTrace(MASK_SHOT_HULL).Entity ~= self.Target then
                self:Error("PLANTING ABORTED")
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
            if ent:GetClass() == "ttt_health_station" then
                self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
                self:Begin(ent)
            end
        end
    end
end

if CLIENT then
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