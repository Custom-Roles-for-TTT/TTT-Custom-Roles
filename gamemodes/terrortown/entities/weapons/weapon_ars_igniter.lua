AddCSLuaFile()

local ipairs = ipairs
local player = player

local GetAllPlayers = player.GetAll

if CLIENT then
    SWEP.PrintName          = "Igniter"
    SWEP.Slot               = 8

    SWEP.ViewModelFOV       = 60
    SWEP.DrawCrosshair      = false
    SWEP.ViewModelFlip      = false
else
    util.AddNetworkString("TTT_ArsonistIgnited")
end

SWEP.ViewModel              = "models/weapons/v_slam.mdl"
SWEP.WorldModel             = "models/weapons/w_slam.mdl"
SWEP.Weight                 = 2

SWEP.Base                   = "weapon_tttbase"
SWEP.Category               = WEAPON_CATEGORY_ROLE

SWEP.Spawnable              = false
SWEP.AutoSpawnable          = false
SWEP.HoldType               = "slam"
SWEP.Kind                   = WEAPON_ROLE

SWEP.DeploySpeed            = 4
SWEP.AllowDrop              = false
SWEP.NoSights               = true
SWEP.UseHands               = true
SWEP.LimitedStock           = true
SWEP.AmmoEnt                = nil

SWEP.Primary.Delay          = 1
SWEP.Primary.Automatic      = false
SWEP.Primary.Cone           = 0
SWEP.Primary.Ammo           = nil
SWEP.Primary.ClipSize       = -1
SWEP.Primary.ClipMax        = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Sound          = ""

SWEP.Secondary.Delay        = 1.25
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Cone         = 0
SWEP.Secondary.Ammo         = nil
SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.ClipMax      = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Sound        = ""

SWEP.InLoadoutFor           = {ROLE_ARSONIST}
SWEP.InLoadoutForDefault    = {ROLE_ARSONIST}

function SWEP:Initialize()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
    if CLIENT then
        self:AddHUDHelp("arsonistigniter_help_pri", "arsonistigniter_help_sec", true)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:Deploy()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
    return true
end

function SWEP:PrimaryAttack()
    if self:GetNextPrimaryFire() > CurTime() then return end
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    if GetRoundState() ~= ROUND_ACTIVE then return end

    local owner = self:GetOwner()
    if not IsPlayer(owner) then return end

    -- Don't ignite if all players aren't doused
    if not owner:GetNWBool("TTTArsonistDouseComplete", false) then
        if SERVER then
            local message = "Not all players have been doused yet"
            owner:PrintMessage(HUD_PRINTCENTER, message)
            owner:PrintMessage(HUD_PRINTTALK, message)
        end
        return
    end

    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DETONATE)

    if CLIENT then return end

    for _, p in ipairs(GetAllPlayers()) do
        if p == owner then continue end
        if not p:Alive() or p:IsSpec() then continue end

        -- Arbitrarily high number so they burn to death
        p:Ignite(1000)

        local message = "You've been ignited by the " .. ROLE_STRINGS[ROLE_ARSONIST]
        p:PrintMessage(HUD_PRINTCENTER, message)
        p:PrintMessage(HUD_PRINTTALK, message)
    end

    -- Log the event
    net.Start("TTT_ArsonistIgnited")
    net.Broadcast()

    self:Remove()
end

function SWEP:DryFire() return false end