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
    SWEP.PrintName = "Brain Washing Device"
    SWEP.Slot = 8

    SWEP.EquipMenuData = {
        type = "item_weapon",
        desc = "Revives an innocent as a traitor."
    }

    SWEP.Icon = "vgui/ttt/icon_brainwash"
end

SWEP.Base = "weapon_cr_defibbase"
SWEP.Category = WEAPON_CATEGORY_ROLE
SWEP.InLoadoutFor = {ROLE_HYPNOTIST}
SWEP.InLoadoutForDefault = {ROLE_HYPNOTIST}
SWEP.Kind = WEAPON_ROLE

SWEP.BlockShopRandomization = true

if SERVER then
    SWEP.DeviceTimeConVar = CreateConVar("ttt_hypnotist_device_time", "8", FCVAR_NONE, "The amount of time (in seconds) the hypnotist's device takes to use", 0, 60)
end

if CLIENT then
    function SWEP:Initialize()
        self:AddHUDHelp("brainwash_help_pri", "brainwash_help_sec", true)
        return self.BaseClass.Initialize(self)
    end
end

if SERVER then
    local convert_detectives = CreateConVar("ttt_hypnotist_convert_detectives", "0")

    util.AddNetworkString("TTT_Hypnotised_Hide")
    util.AddNetworkString("TTT_Hypnotised_Revived")
    util.AddNetworkString("TTT_Hypnotised")

    function SWEP:ShouldConvertToImpersonator(ply)
        if not convert_detectives:GetBool() then
            return false
        end
        if ply:IsDetectiveTeam() then
            return true
        end
        if ply:IsDeputy() then
            return GetConVar("ttt_deputy_use_detective_icon"):GetBool()
        end
        return false
    end

    function SWEP:OnSuccess(ply, body)
        local credits = CORPSE.GetCredits(body, 0) or 0

        if ply:IsTraitor() and CORPSE.GetFound(body, false) == true then
            local plys = {}

            for _, v in pairs(player.GetAll()) do
                if not v:IsTraitor() then
                    table.insert(plys, v)
                end
            end

            net.Start("TTT_Hypnotised_Hide")
            net.WriteEntity(ply)
            net.WriteBool(true)
            net.Send(plys)
        end

        net.Start("TTT_Hypnotised_Revived")
        net.Send(ply)

        local owner = self:GetOwner()
        hook.Call("TTTPlayerRoleChangedByItem", nil, owner, ply, self)

        net.Start("TTT_Hypnotised")
        net.WriteString(ply:Nick())
        net.WriteString(owner:SteamID64())
        net.Broadcast()

        ply:SpawnForRound(true)
        ply:SetCredits(credits)
        ply:SetPos(self.Location or body:GetPos())
        ply:SetEyeAngles(Angle(0, body:GetAngles().y, 0))
        ply:SetNWBool("WasHypnotised", true)
        -- If detectives and deputies that look like detectives should be converted
        if self:ShouldConvertToImpersonator(ply) then
            -- Keep track of whether they should be promoted
            local promote = (ply:IsDetectiveTeam() or ShouldPromoteDetectiveLike())

            -- Convert them to an impersonator and promote them if appropriate
            ply:SetRole(ROLE_IMPERSONATOR)
            if promote then
                ply:HandleDetectiveLikePromotion()
            end
        else
            ply:SetRole(ROLE_TRAITOR)
        end
        ply:StripRoleWeapons()
        ply:PrintMessage(HUD_PRINTCENTER, "You have been brainwashed and are now a traitor.")
        SetRoleHealth(ply)

        SafeRemoveEntity(body)

        SendFullStateUpdate()
    end

    function SWEP:ValidateTarget(ply, body, bone)
        if ply:IsTraitorTeam() then
            return false, "SUBJECT IS ALREADY A TRAITOR"
        end
        return true, ""
    end

    function SWEP:GetProgressMessage(ply, body, bone)
        return "BRAINWASHING " .. string.upper(ply:Nick())
    end

    function SWEP:GetAbortMessage()
        return "BRAINWASHING ABORTED"
    end
end

if CLIENT then
    net.Receive("TTT_Hypnotised_Hide", function()
        local hply = net.ReadEntity()
        hply.HypnotisedHide = net.ReadBool()
    end)

    local revived = Sound("items/smallmedkit1.wav")
    net.Receive("TTT_Hypnotised_Revived", function()
        surface.PlaySound(revived)
    end)

    hook.Add("TTTEndRound", "RemoveHypnotisedHide", function()
        for _, v in pairs(player.GetAll()) do v.HypnotisedHide = nil end
    end)

    local oldScoreGroup = oldScoreGroup or ScoreGroup
    function ScoreGroup(ply)
        if ply.HypnotisedHide then return GROUP_FOUND end
        return oldScoreGroup(ply)
    end
end