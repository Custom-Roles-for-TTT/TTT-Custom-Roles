AddCSLuaFile()

local IsValid = IsValid
local math = math
local pairs = pairs
local player = player
local string = string
local timer = timer
local util = util

if CLIENT then
    local GetPTranslation = LANG.GetParamTranslation
    SWEP.PrintName = "Exorcism Device"
    SWEP.Slot = 6

    SWEP.DrawCrosshair = false
    SWEP.ViewModelFOV = 54

    SWEP.EquipMenuData = {
        type = "item_weapon",
        desc = function()
            return GetPTranslation("exor_desc", {
                phantom = string.lower(ROLE_STRINGS[ROLE_PHANTOM])
            })
        end
    };

    SWEP.Icon = "vgui/ttt/icon_exor"
end

SWEP.Base = "weapon_tttbase"

SWEP.ViewModel = "models/weapons/c_toolgun.mdl"
SWEP.WorldModel = "models/weapons/w_toolgun.mdl"

SWEP.Primary.ClipSize        = -1
SWEP.Primary.DefaultClip     = -1
SWEP.Primary.Automatic       = true
SWEP.Primary.Delay           = 1
SWEP.Primary.Ammo            = "none"

SWEP.Secondary.ClipSize      = -1
SWEP.Secondary.DefaultClip   = -1
SWEP.Secondary.Automatic     = true
SWEP.Secondary.Ammo          = "none"
SWEP.Secondary.Delay         = 2

SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = { }
SWEP.NoSights = true
SWEP.HoldType = "slam"

SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.BlockShopRandomization = true

local DEFIB_IDLE = 0
local DEFIB_BUSY = 1
local DEFIB_ERROR = 2

local beep = Sound("buttons/button17.wav")
local hum = Sound("items/nvg_on.wav")
local cured = Sound("items/smallmedkit1.wav")

if SERVER then
    CreateConVar("ttt_phantom_cure_time", "3", FCVAR_NONE, "The amount of time (in seconds) the phantom exorcism device takes to use. See \"ttt_traitor_phantom_cure\" and \"ttt_quack_phantom_cure\" to enable the device itself", 0, 60)
end

if CLIENT then
    function SWEP:Initialize()
        self:AddHUDHelp("exor_help_pri", "exor_help_sec", true)
        return self.BaseClass.Initialize(self)
    end
end

function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "State")
    self:NetworkVar("Int", 1, "ChargeTime")
    self:NetworkVar("Float", 0, "Begin")
    self:NetworkVar("String", 0, "Message")

    if SERVER then
        self:SetChargeTime(GetConVar("ttt_phantom_cure_time"):GetInt())
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

    function SWEP:DoCleanse(ply)
        local owner = self:GetOwner()
        if IsPlayer(ply) and ply:Alive() and not ply:IsSpec() then
            ply:EmitSound(cured)

            if ply:GetNWBool("Haunted", false) then
                for _, v in pairs(player.GetAll()) do
                    if v:GetNWString("HauntingTarget", "") == ply:EnhancedSteamID64() then
                        ply:SetNWBool("Haunted", false)
                        v:SetNWBool("Haunting", false)
                        v:SetNWString("HauntingTarget", nil)
                        v:SetNWInt("HauntingPower", 0)
                        timer.Remove(v:Nick() .. "HauntingPower")
                        timer.Remove(v:Nick() .. "HauntingSpectate")
                        v:PrintMessage(HUD_PRINTCENTER, "Your spirit has been cleansed from your target.")
                    end
                end
            end

            self:Remove()
        else
            if ply == owner then
                self:SetNextSecondaryFire(CurTime() + 1)
            else
                self:SetNextPrimaryFire(CurTime() + 1)
            end
        end
    end

    function SWEP:Begin(ply)
        if not IsPlayer(ply) then
            self:Error("INVALID TARGET")
            return
        end

        self:SetState(DEFIB_BUSY)
        self:SetBegin(CurTime())
        if ply == self:GetOwner() then
            self:SetMessage("CLEANSING YOURSELF")
        else
            self:SetMessage("CLEANSING " .. string.upper(ply:Nick()))
        end

        self:GetOwner():EmitSound(hum, 75, math.random(98, 102), 1)

        self.Target = ply
    end

    function SWEP:Think()
        if self:GetState() == DEFIB_BUSY then
            local owner = self:GetOwner()
            if self:GetBegin() + self:GetChargeTime() <= CurTime() then
                self:DoCleanse(self.Target)
                self:Reset()
            elseif owner == self.Target then
                if not owner:KeyDown(IN_ATTACK2) then
                    self:Error("CLEANSE ABORTED")
                end
            elseif not owner:KeyDown(IN_ATTACK) or owner:GetEyeTrace(MASK_SHOT_HULL).Entity ~= self.Target then
                self:Error("CLEANSE ABORTED")
            end
        end
    end

    function SWEP:PrimaryAttack()
        if self:GetState() ~= DEFIB_IDLE then return end
        if GetRoundState() ~= ROUND_ACTIVE then return end

        local owner = self:GetOwner()
        local tr = util.TraceLine({
            start = owner:GetShootPos(),
            endpos = owner:GetShootPos() + owner:GetAimVector() * 64,
            filter = owner
        })

        local ent = tr.Entity
        if IsPlayer(ent) then
            self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
            self:Begin(ent)
        end
    end

    function SWEP:SecondaryAttack()
        if self:GetState() ~= DEFIB_IDLE then return end
        if GetRoundState() ~= ROUND_ACTIVE then return end

        local owner = self:GetOwner()
        if IsPlayer(owner) then
            self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
            self:Begin(owner)
        end
    end

    function SWEP:Holster()
        self:Reset()
        return true
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

        local w = 255

        if state == DEFIB_BUSY then
            if time < 0 then return end
            local progress = math.min(1, 1 - ((time - CurTime()) / charge))
            CRHUD:PaintProgressBar(x, y, w, Color(0, 255, 0, 155), self:GetMessage(), progress)
        elseif state == DEFIB_ERROR then
            CRHUD:PaintProgressBar(x, y, w, Color(200 + math.sin(CurTime() * 32) * 50, 0, 0, 155), self:GetMessage(), progress)
        end
    end

    function SWEP:PrimaryAttack() return false end
end

function SWEP:DryFire() return false end