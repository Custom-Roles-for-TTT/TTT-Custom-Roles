AddCSLuaFile()

local ents = ents
local IsValid = IsValid

if CLIENT then
    local GetPTranslation = LANG.GetParamTranslation
    local GetTranslation = LANG.GetTranslation
    SWEP.PrintName = "stationb_name"
    SWEP.Slot = 6

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

SWEP.Base = "weapon_cr_defibbase"
SWEP.Category = WEAPON_CATEGORY_ROLE
SWEP.CanBuy = { ROLE_QUACK }
-- This is special equipment
SWEP.Kind = WEAPON_EQUIP2
SWEP.WeaponID = AMMO_STATIONBOMB

SWEP.BlockShopRandomization = true

local hum = Sound("items/nvg_on.wav")

local DEFIB_BUSY = 1

if SERVER then
    SWEP.DeviceTimeConVar = CreateConVar("ttt_quack_station_bomb_time", "4", FCVAR_NONE, "The amount of time (in seconds) the station bomb takes to plant", 0, 30)
end

if CLIENT then
    function SWEP:Initialize()
        self:AddHUDHelp("stationb_help", nil, true)
        return self.BaseClass.Initialize(self)
    end
end

if SERVER then
    function SWEP:OnSuccess(target)
        local bomb = ents.Create("ttt_bomb_station")
        if not IsValid(bomb) then
            self:Error("ATTEMPT FAILED TRY AGAIN")
            return false
        end

        local owner = self:GetOwner()
        local pos = target:GetPos()
        local ang = target:GetAngles()

        SafeRemoveEntity(target)

        bomb:SetPos(pos)
        bomb:SetAngles(ang)
        bomb:Spawn()

        bomb:SetPlacer(owner)
        bomb:PhysWake()
    end

    function SWEP:GetProgressMessage()
        return "PLANTING BOMB"
    end

    function SWEP:GetAbortMessage()
        return "PLANTING ABORTED"
    end

    -- Override these so we can bypass the checks that assume the target is a player
    function SWEP:DoSuccess(target)
        if not IsValid(target) then
            self:DoFailure()
            return
        end

        if self:OnSuccess(target) ~= false then
            if self.SingleUse then
                self:Remove()
            end
        end
        self:Reset()
    end

    function SWEP:Begin(target)
        if not target then
            self:Error("INVALID TARGET")
            return
        end

        self:SetState(DEFIB_BUSY)
        self:SetBegin(CurTime())
        self:SetMessage(self:GetProgressMessage())
        self:GetOwner():EmitSound(hum, 75, math.random(98, 102), 1)

        self.Target = target
    end

    -- Override this so we can check for the health station we want as a target
    function SWEP:IsTargetValid(target, bone, primary)
        return IsValid(target) and target:GetClass() == "ttt_health_station"
    end
end