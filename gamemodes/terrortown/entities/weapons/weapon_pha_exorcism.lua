AddCSLuaFile()

local pairs = pairs
local player = player
local string = string
local timer = timer
local util = util

SWEP.HoldType               = "slam"

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

SWEP.ViewModel              = "models/weapons/c_toolgun.mdl"
SWEP.WorldModel             = "models/weapons/w_toolgun.mdl"

SWEP.Base                   = "weapon_cr_defibbase"
SWEP.Category               = WEAPON_CATEGORY_ROLE
SWEP.Kind                   = WEAPON_EQUIP
SWEP.CanBuy                 = { }
SWEP.AllowDrop              = true

SWEP.BlockShopRandomization = true

SWEP.DeadTarget             = false
SWEP.HasSecondary           = true

local cured = Sound("items/smallmedkit1.wav")

if SERVER then
    SWEP.DeviceTimeConVar = CreateConVar("ttt_phantom_cure_time", "3", FCVAR_NONE, "The amount of time (in seconds) the phantom exorcism device takes to use. See \"ttt_traitor_phantom_cure\" and \"ttt_quack_phantom_cure\" to enable the device itself", 0, 60)
end

if CLIENT then
    function SWEP:Initialize()
        self:AddHUDHelp("exor_help_pri", "exor_help_sec", true)
        return self.BaseClass.Initialize(self)
    end
end

if SERVER then
    function SWEP:OnSuccess(ply, body)
        ply:EmitSound(cured)

        if ply:GetNWBool("PhantomHaunted", false) then
            for _, v in pairs(player.GetAll()) do
                if v:GetNWString("PhantomHauntingTarget", "") == ply:SteamID64() then
                    ply:SetNWBool("PhantomHaunted", false)
                    v:SetNWBool("PhantomHaunting", false)
                    v:SetNWString("PhantomHauntingTarget", "")
                    v:SetNWBool("PhantomPossessing", false)
                    v:SetNWInt("PhantomPossessingPower", 0)
                    timer.Remove(v:Nick() .. "PhantomPossessingPower")
                    timer.Remove(v:Nick() .. "PhantomPossessingSpectate")
                    v:QueueMessage(MSG_PRINTCENTER, "Your spirit has been cleansed from your target.")

                    if GetConVar("ttt_phantom_haunt_saves_lover"):GetBool() then
                        local loverSID = v:GetNWString("TTTCupidLover", "")
                        if #loverSID > 0 then
                            local lover = player.GetBySteamID64(loverSID)
                            lover:PrintMessage(HUD_PRINTTALK, "Your lover was exorcised from their host!")
                        end
                    end
                end
            end
        end
    end

    function SWEP:GetProgressMessage(ply, body, bone)
        if ply == self:GetOwner() then
            return "CLEANSING YOURSELF"
        end
        return "CLEANSING " .. string.upper(ply:Nick())
    end

    function SWEP:GetAbortMessage()
        return "CLEANSE ABORTED"
    end

    function SWEP:IsCurrentTargetValid()
        local owner = self:GetOwner()
        if owner == self.Target then
            return owner:KeyDown(IN_ATTACK2)
        end
        return owner:KeyDown(IN_ATTACK) and owner:GetEyeTrace(MASK_SHOT_HULL).Entity == self.Target
    end

    function SWEP:GetTarget(primary)
        local owner = self:GetOwner()
        if primary then
            local tr = util.TraceLine({
                start = owner:GetShootPos(),
                endpos = owner:GetShootPos() + owner:GetAimVector() * 64,
                filter = owner
            })

            return tr.Entity, tr.PhysicsBone
        end
        return owner, nil
    end
end