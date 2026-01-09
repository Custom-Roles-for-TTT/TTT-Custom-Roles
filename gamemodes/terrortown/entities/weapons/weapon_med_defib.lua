AddCSLuaFile()

local hook = hook
local net = net
local surface = surface
local util = util

if CLIENT then
    SWEP.PrintName = "Defibrillator"
    SWEP.Slot = 8

    SWEP.EquipMenuData = {
        type = "item_weapon",
        desc = "Revives a dead player."
    }

    SWEP.Icon = "vgui/ttt/icon_meddefib"
end

SWEP.Base = "weapon_cr_defibbase"
SWEP.Category = WEAPON_CATEGORY_ROLE
SWEP.InLoadoutFor = {ROLE_PARAMEDIC}
SWEP.InLoadoutForDefault = {ROLE_PARAMEDIC}
SWEP.Kind = WEAPON_ROLE

SWEP.BlockShopRandomization = true

if SERVER then
    SWEP.DeviceTimeConVar = CreateConVar("ttt_paramedic_defib_time", "8", FCVAR_NONE, "The amount of time (in seconds) the paramedic's defib takes to use", 0, 60)
end

if CLIENT then
    function SWEP:Initialize()
        self:AddHUDHelp("defibrillator_help_pri", "defibrillator_help_sec", true)
        return self.BaseClass.Initialize(self)
    end
end

if SERVER then
    util.AddNetworkString("TTT_Paramedic_Revived")

    function SWEP:OnSuccess(ply, body)
        local credits = CORPSE.GetCredits(body, 0) or 0

        net.Start("TTT_Paramedic_Revived")
        net.WriteBool(true)
        net.Send(ply)

        local owner = self:GetOwner()
        hook.Call("TTTPlayerRoleChangedByItem", nil, owner, ply, self)

        ply:SpawnForRound(true)
        ply:SetCredits(credits)
        ply:SetPos(self.Location or body:GetPos())
        ply:SetEyeAngles(Angle(0, body:GetAngles().y, 0))
        ply:SetNWBool("WasRevivedByParamedic", true)

        -- Only change the player's role if we're not reviving them as-is
        if not GetConVar("ttt_paramedic_defib_as_is"):GetBool() then
            if GetConVar("ttt_paramedic_defib_as_innocent"):GetBool() then
                ply:SetRole(ROLE_INNOCENT)
                ply:StripRoleWeapons()
            elseif ply:GetDetectiveLike() then
                -- Convert detective roles to promoted deputy
                -- This leaves everyone else as their existing role
                if GetConVar("ttt_paramedic_defib_detectives_as_deputy"):GetBool() then
                    if ply:IsDetectiveTeam() then
                        ply:SetRole(ROLE_DEPUTY)
                        ply:StripRoleWeapons()
                        ply:HandleDetectiveLikePromotion()
                    end
                -- Otherwise demote detective-like roles to their base role
                else
                    if ply:IsJesterTeam() then
                        ply:SetRole(ROLE_JESTER)
                    elseif ply:IsTraitorTeam() then
                        ply:SetRole(ROLE_TRAITOR)
                    else
                        ply:SetRole(ROLE_INNOCENT)
                    end
                    ply:StripRoleWeapons()
                end
            end
        end

        ply:QueueMessage(MSG_PRINTCENTER, "You have been revived by " .. ROLE_STRINGS_EXT[ROLE_PARAMEDIC] .. "!")
        if GetConVar("ttt_paramedic_revive_muted"):GetBool() then
            ply:PrintMessage(HUD_PRINTTALK, "You have not yet regained your ability to speak")
        end
        SetRoleHealth(ply)

        SafeRemoveEntity(body)

        SendFullStateUpdate()
    end

    function SWEP:GetProgressMessage(ply, body, bone)
        return "DEFIBRILLATING " .. utf8.upper(ply:Nick())
    end

    function SWEP:GetAbortMessage()
        return "DEFIBRILLATION ABORTED"
    end
end

if CLIENT then
    local revived = Sound("items/smallmedkit1.wav")
    net.Receive("TTT_Paramedic_Revived", function()
        surface.PlaySound(revived)
    end)
end