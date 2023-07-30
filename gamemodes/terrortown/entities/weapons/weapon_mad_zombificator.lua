AddCSLuaFile()

local hook = hook
local net = net
local pairs = pairs
local player = player
local surface = surface
local string = string
local table = table
local util = util

if CLIENT then
    SWEP.PrintName = "Zombification Device"
    SWEP.Slot = 8

    SWEP.EquipMenuData = {
        type = "item_weapon",
        desc = "Turns dead players into zombies."
    }
end

SWEP.Base = "weapon_cr_defibbase"
SWEP.Category = WEAPON_CATEGORY_ROLE
SWEP.InLoadoutFor = {ROLE_MADSCIENTIST}
SWEP.Kind = WEAPON_ROLE

SWEP.SingleUse = false

if SERVER then
    SWEP.DeviceTimeConVar = CreateConVar("ttt_madscientist_device_time", "4", FCVAR_NONE, "The amount of time (in seconds) the mad scientist's device takes to use", 0, 60)
end

if CLIENT then
    function SWEP:Initialize()
        self:AddHUDHelp("zombificator_help_pri", "zombificator_help_sec", true)
        return self.BaseClass.Initialize(self)
    end
end

if SERVER then
    util.AddNetworkString("TTT_Zombificator_Hide")
    util.AddNetworkString("TTT_Zombificator_Revived")

    function SWEP:OnSuccess(ply, body)
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
        net.Send(ply)

        local owner = self:GetOwner()
        hook.Call("TTTPlayerRoleChangedByItem", nil, owner, ply, self)

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
    end

    function SWEP:OnDefibStart(ply, body, bone)
        hook.Call("TTTMadScientistZombifyBegin", nil, self:GetOwner(), ply)
    end

    function SWEP:ValidateTarget(ply, body, bone)
        if ply:IsZombie() then
            return false, "SUBJECT IS ALREADY A ZOMBIE"
        end
        return true, ""
    end

    function SWEP:GetProgressMessage(ply, body, bone)
        return "ZOMBIFYING " .. string.upper(ply:Nick())
    end

    function SWEP:GetAbortMessage()
        return "ZOMBIFYING ABORTED"
    end
end

if CLIENT then
    net.Receive("TTT_Zombificator_Hide", function()
        local hply = net.ReadEntity()
        hply.MadZomHide = net.ReadBool()
    end)

    local revived = Sound("items/smallmedkit1.wav")
    net.Receive("TTT_Zombificator_Revived", function()
        surface.PlaySound(revived)
    end)

    hook.Add("TTTEndRound", "RemoveZombificatorHide", function()
        for _, v in pairs(player.GetAll()) do v.MadZomHide = nil end
    end)

    local oldScoreGroup = oldScoreGroup or ScoreGroup
    function ScoreGroup(ply)
        if ply.MadZomHide then return GROUP_FOUND end
        return oldScoreGroup(ply)
    end
end