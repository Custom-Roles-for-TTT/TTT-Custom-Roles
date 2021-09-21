AddCSLuaFile()

if CLIENT then
    SWEP.PrintName = "Parasite Cure"
    SWEP.Slot = 6

    SWEP.DrawCrosshair = false
    SWEP.ViewModelFOV = 54

    SWEP.EquipMenuData = {
            type =  "Weapon",
            desc =  [[Use on a player to cure them of parasites.

Using this on a player who is not infected will kill them!]]
        };

    SWEP.Icon = "vgui/ttt/icon_cure"
end

SWEP.Base = "weapon_tttbase"

SWEP.ViewModel = "models/weapons/c_medkit.mdl"
SWEP.WorldModel = "models/weapons/w_medkit.mdl"

SWEP.Primary.ClipSize        = -1
SWEP.Primary.DefaultClip     = -1
SWEP.Primary.Automatic       = true
SWEP.Primary.Delay           = 1
SWEP.Primary.Ammo            = "none"

SWEP.Secondary.ClipSize       = -1
SWEP.Secondary.DefaultClip    = -1
SWEP.Secondary.Automatic      = true
SWEP.Secondary.Ammo           = "none"
SWEP.Secondary.Delay          = 2

SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = { ROLE_DETECTIVE, ROLE_DOCTOR, ROLE_QUACK }
SWEP.CanBuyDefault = { ROLE_DETECTIVE, ROLE_DOCTOR, ROLE_QUACK  }
SWEP.NoSights = true
SWEP.HoldType = "slam"

SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.BlockShopRandomization = true

PARASITE_CURE_KILL_NONE = 0
PARASITE_CURE_KILL_OWNER = 1
PARASITE_CURE_KILL_TARGET = 2

local DEFIB_IDLE = 0
local DEFIB_BUSY = 1
local DEFIB_ERROR = 2

local CureMode = CreateConVar("ttt_parasite_cure_mode", "2")

local charge = 3

local beep = Sound("buttons/button17.wav")
local hum = Sound("items/nvg_on.wav")
local cured = Sound("items/smallmedkit1.wav")

if CLIENT then
    function SWEP:Initialize()
        self:AddHUDHelp("cure_help_pri", "cure_help_sec", true)
        self:SetHoldType(self.HoldType)
        return self.BaseClass.Initialize(self)
    end
end

function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "State")
    self:NetworkVar("Float", 1, "Begin")
    self:NetworkVar("String", 0, "Message")
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

    function SWEP:DoCure(ply)
        local owner = self:GetOwner()
        if IsPlayer(ply) then
            ply:EmitSound(cured)

            if ply:GetNWBool("Infected", false) then
                for _, v in pairs(player.GetAll()) do
                    if v:GetNWString("InfectingTarget", "") == ply:SteamID64() then
                        ply:SetNWBool("Infected", false)
                        v:SetNWBool("Infecting", false)
                        v:SetNWString("InfectingTarget", nil)
                        v:SetNWInt("InfectionProgress", 0)
                        timer.Remove(v:Nick() .. "InfectionProgress")
                        timer.Remove(v:Nick() .. "InfectingSpectate")
                        v:PrintMessage(HUD_PRINTCENTER, "Your host has been cured.")
                    end
                end
            else
                local cureMode = CureMode:GetInt()
                if cureMode == PARASITE_CURE_KILL_OWNER and IsValid(owner) then
                    owner:Kill()
                elseif cureMode == PARASITE_CURE_KILL_TARGET then
                    ply:Kill()
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
            self:SetMessage("CURING YOURSELF")
        else
            self:SetMessage("CURING " .. string.upper(ply:Nick()))
        end

        self:GetOwner():EmitSound(hum, 75, math.random(98, 102), 1)

        self.Target = ply
    end

    function SWEP:Think()
        if self:GetState() == DEFIB_BUSY then
            local owner = self:GetOwner()
            if self:GetBegin() + charge <= CurTime() then
                self:DoCure(self.Target)
                self:Reset()
            elseif owner == self.Target then
                if not owner:KeyDown(IN_ATTACK2) then
                    self:Error("CURE ABORTED")
                end
            elseif not owner:KeyDown(IN_ATTACK) or owner:GetEyeTrace(MASK_SHOT_HULL).Entity ~= self.Target then
                self:Error("CURE ABORTED")
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

    function SWEP:Equip(newowner)
        if newowner:IsTraitorTeam() then
            newowner:PrintMessage(HUD_PRINTTALK, "The parasite cure you are holding is real.")
        end
    end
end

if CLIENT then
    function SWEP:DrawHUD()
        local state = self:GetState()
        self.BaseClass.DrawHUD(self)

        if state == DEFIB_IDLE then return end

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