AddCSLuaFile()

SWEP.HoldType = "normal"

if CLIENT then
    local GetPTranslation = LANG.GetParamTranslation
    SWEP.PrintName = "bstation_name"
    SWEP.Slot = 6
    SWEP.ViewModelFOV = 10

    SWEP.EquipMenuData = {
        type = "item_weapon",
        desc = function()
            return GetPTranslation("bstation_desc", {
                traitor = ROLE_STRINGS[ROLE_TRAITOR],
                traitors = ROLE_STRINGS_PLURAL[ROLE_TRAITOR]
            })
        end
    };
end

SWEP.Base = "weapon_tttbase"
SWEP.Category = WEAPON_CATEGORY_ROLE

SWEP.ViewModel = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel = "models/props/cs_office/microwave.mdl"

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

SWEP.InLoadoutFor = {ROLE_QUACK}

-- This is special equipment
SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = nil
SWEP.LimitedStock = true
SWEP.WeaponID = AMMO_HEALTHSTATION

SWEP.AllowDrop = false
SWEP.NoSights = true

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:PrimaryAttack()
    self.Weapon:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:BombDrop()
end
function SWEP:SecondaryAttack()
    self.Weapon:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
    self:BombDrop()
end

local throwsound = Sound("Weapon_SLAM.SatchelThrow")

-- ye olde droppe code
function SWEP:BombDrop()
    if SERVER then
        local ply = self:GetOwner()
        if not IsValid(ply) then return end

        if self.Planted then return end

        local vsrc = ply:GetShootPos()
        local vang = ply:GetAimVector()
        local vvel = ply:GetVelocity()

        local vthrow = vvel + vang * 200

        local bomb = ents.Create("ttt_bomb_station")
        if IsValid(bomb) then
            bomb:SetPos(vsrc + vang * 10)
            bomb:Spawn()

            bomb:SetPlacer(ply)

            bomb:PhysWake()
            local phys = bomb:GetPhysicsObject()
            if IsValid(phys) then
                phys:SetVelocity(vthrow)
            end
            self:Remove()

            self.Planted = true
        end
    end

    self:EmitSound(throwsound)
end

function SWEP:Reload()
    return false
end

function SWEP:OnRemove()
    if CLIENT and IsValid(self:GetOwner()) and self:GetOwner() == LocalPlayer() and self:GetOwner():Alive() then
        RunConsoleCommand("lastinv")
    end
end

if CLIENT then
    function SWEP:Initialize()
        self:AddHUDHelp("bstation_help", nil, true)

        return self.BaseClass.Initialize(self)
    end
end

function SWEP:Deploy()
    if SERVER and IsValid(self:GetOwner()) then
        self:GetOwner():DrawViewModel(false)
    end
    return true
end

function SWEP:DrawWorldModel()
end

function SWEP:DrawWorldModelTranslucent()
end
