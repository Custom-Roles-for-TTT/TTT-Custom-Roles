AddCSLuaFile()

local net = net
local surface = surface
local string = string
local util = util

if CLIENT then
    SWEP.PrintName = "Bodysnatching Device"
    SWEP.Slot = 8

    SWEP.EquipMenuData = {
        type = "item_weapon",
        desc = "Changes your role to that of a corpses."
    }
end

SWEP.Base = "weapon_cr_defibbase"
SWEP.Category = WEAPON_CATEGORY_ROLE
SWEP.InLoadoutFor = {ROLE_BODYSNATCHER}
SWEP.Kind = WEAPON_ROLE

SWEP.FindRespawnLocation = false

if SERVER then
    SWEP.DeviceTimeConVar = CreateConVar("ttt_bodysnatcher_device_time", "5", FCVAR_NONE, "The amount of time (in seconds) the bodysnatcher's device takes to use", 0, 60)
end

if SERVER then
    util.AddNetworkString("TTT_Bodysnatched")
    util.AddNetworkString("TTT_ScoreBodysnatch")

    function SWEP:OnSuccess(ply, body)
        local owner = self:GetOwner()
        hook.Call("TTTPlayerRoleChangedByItem", nil, owner, owner, self)

        net.Start("TTT_Bodysnatched")
        net.Send(ply)

        local role = body.was_role or ply:GetRole()
        net.Start("TTT_ScoreBodysnatch")
        net.WriteString(ply:Nick())
        net.WriteString(owner:Nick())
        net.WriteString(ROLE_STRINGS_EXT[role])
        net.WriteString(owner:SteamID64())
        net.Broadcast()

        owner:SetRole(role)
        ply:MoveRoleState(owner, true)
        owner:SelectWeapon("weapon_zm_carry")
        owner:SetNWBool("WasBodysnatcher", true)

        if GetConVar("ttt_bodysnatcher_destroy_body"):GetBool() then
            SafeRemoveEntity(body)
        end
        SetRoleMaxHealth(owner)

        SendFullStateUpdate()
    end

    function SWEP:GetProgressMessage(ply, body, bone)
        local message = "BODYSNATCHING " .. string.upper(ply:Nick())
        if GetConVar("ttt_bodysnatcher_show_role"):GetBool() then
            local role = body.was_role or ply:GetRole()
            message = message .. " [" .. string.upper(ROLE_STRINGS_RAW[role]) .. "]"
        end
        return message
    end

    function SWEP:GetAbortMessage()
        return "BODYSNATCH ABORTED"
    end
end

if CLIENT then
    local revived = Sound("items/smallmedkit1.wav")
    net.Receive("TTT_Bodysnatched", function()
        surface.PlaySound(revived)
    end)
end