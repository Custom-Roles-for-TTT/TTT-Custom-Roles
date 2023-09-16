AddCSLuaFile()

local math = math
local net = net
local string = string
local util = util

SWEP.HoldType               = "slam"

if CLIENT then
    SWEP.PrintName          = "Deputy Badge"
    SWEP.Slot               = 8

    SWEP.ViewModelFOV       = 60
    SWEP.DrawCrosshair      = false
    SWEP.ViewModelFlip      = false
end

SWEP.ViewModel              = "models/weapons/v_slam.mdl"
SWEP.WorldModel             = "models/weapons/w_slam.mdl"
SWEP.Weight                 = 2

SWEP.Base                   = "weapon_cr_defibbase"
SWEP.Category               = WEAPON_CATEGORY_ROLE
SWEP.InLoadoutFor           = {ROLE_MARSHAL}
SWEP.InLoadoutForDefault    = {ROLE_MARSHAL}
SWEP.Kind                   = WEAPON_ROLE

SWEP.DeploySpeed            = 4

SWEP.DeadTarget             = false

-- Settings
SWEP.MaxDistance            = 96

if SERVER then
    SWEP.DeviceTimeConVar = CreateConVar("ttt_marshal_badge_time", "8", FCVAR_NONE, "The amount of time (in seconds) the marshal's badge takes to use", 0, 60)
end

function SWEP:Initialize()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
    if CLIENT then
        self:AddHUDHelp("marshalbadge_help_pri", "marshalbadge_help_sec", true)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:Deploy()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
    return true
end

if SERVER then
    util.AddNetworkString("TTT_Deputized")

    function SWEP:OnSuccess(ply, body)
        local role = ROLE_DEPUTY
        if ply:IsTraitorTeam() then
            role = ROLE_IMPERSONATOR
        end

        local marshal_monster_deputy_chance = GetConVar("ttt_marshal_monster_deputy_chance"):GetFloat()
        if ply:IsMonsterTeam() and marshal_monster_deputy_chance <= math.random() then
            role = ROLE_IMPERSONATOR
        end

        local marshal_jester_deputy_chance = GetConVar("ttt_marshal_jester_deputy_chance"):GetFloat()
        if ply:IsJesterTeam() and marshal_jester_deputy_chance <= math.random() then
            role = ROLE_IMPERSONATOR
        end

        local marshal_independent_deputy_chance = GetConVar("ttt_marshal_independent_deputy_chance"):GetFloat()
        if ply:IsIndependentTeam() and marshal_independent_deputy_chance <= math.random() then
            role = ROLE_IMPERSONATOR
        end

        ply:SetRole(role)
        SendFullStateUpdate()

        -- Update the player's health
        SetRoleMaxHealth(ply)
        if ply:Health() > ply:GetMaxHealth() then
            ply:SetHealth(ply:GetMaxHealth())
        end

        ply:StripRoleWeapons()
        if not ply:HasWeapon("weapon_ttt_unarmed") then
            ply:Give("weapon_ttt_unarmed")
        end
        if not ply:HasWeapon("weapon_zm_carry") then
            ply:Give("weapon_zm_carry")
        end
        if not ply:HasWeapon("weapon_zm_improvised") then
            ply:Give("weapon_zm_improvised")
        end

        local owner = self:GetOwner()
        hook.Call("TTTPlayerRoleChangedByItem", nil, owner, ply, self)

        -- Broadcast the event
        net.Start("TTT_Deputized")
        net.WriteString(owner:Nick())
        net.WriteString(ply:Nick())
        net.WriteString(ply:SteamID64())
        net.Broadcast()
    end

    function SWEP:ValidateTarget(ply, body, bone)
        local marshal_monster_deputy_chance = GetConVar("ttt_marshal_monster_deputy_chance"):GetFloat()
        if ply:IsMonsterTeam() and marshal_monster_deputy_chance < 0 then
            return false, "INVALID TARGET"
        end

        local marshal_jester_deputy_chance = GetConVar("ttt_marshal_jester_deputy_chance"):GetFloat()
        if ply:IsJesterTeam() and marshal_jester_deputy_chance < 0 then
            return false, "INVALID TARGET"
        end

        local marshal_independent_deputy_chance = GetConVar("ttt_marshal_independent_deputy_chance"):GetFloat()
        if ply:IsIndependentTeam() and marshal_independent_deputy_chance < 0 then
            return false, "INVALID TARGET"
        end

        return true, ""
    end

    function SWEP:GetProgressMessage(ply, body, bone)
        ply:QueueMessage(MSG_PRINTCENTER, "The " .. ROLE_STRINGS[ROLE_MARSHAL] .. " is promoting you.")
        return "DEPUTIZING " .. string.upper(ply:Nick())
    end

    function SWEP:GetAbortMessage()
        return "DEPUTIZING ABORTED"
    end
end