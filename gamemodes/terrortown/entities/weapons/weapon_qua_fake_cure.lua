AddCSLuaFile()

local IsValid = IsValid
local pairs = pairs
local player = player
local string = string
local util = util

SWEP.HoldType               = "slam"

if CLIENT then
    local GetPTranslation = LANG.GetParamTranslation
    SWEP.PrintName = "Parasite Cure"
    SWEP.ShopName = "Fake Parasite Cure"
    SWEP.Slot = 6

    SWEP.DrawCrosshair = false
    SWEP.ViewModelFOV = 54

    SWEP.EquipMenuData = {
        type =  "item_weapon",
        desc = function()
            return GetPTranslation("fake_cure_desc", {
                parasite = string.lower(ROLE_STRINGS[ROLE_PARASITE])
            })
        end
    };

    SWEP.Icon = "vgui/ttt/icon_fakecure"
end

SWEP.ViewModel              = "models/weapons/c_medkit.mdl"
SWEP.WorldModel             = "models/weapons/w_medkit.mdl"

SWEP.Base                   = "weapon_cr_defibbase"
SWEP.Category               = WEAPON_CATEGORY_ROLE
SWEP.Kind                   = WEAPON_EQUIP
SWEP.CanBuy                 = { ROLE_QUACK }
SWEP.CanBuyDefault          = { ROLE_QUACK }
SWEP.AllowDrop              = true

SWEP.BlockShopRandomization = true

SWEP.DeadTarget             = false
SWEP.HasSecondary           = true

QUACK_FAKE_CURE_KILL_NONE = 0
QUACK_FAKE_CURE_KILL_OWNER = 1
QUACK_FAKE_CURE_KILL_TARGET = 2

local cured = Sound("items/smallmedkit1.wav")

if SERVER then
    SWEP.DeviceTimeConVar = CreateConVar("ttt_quack_fake_cure_time", "-1", FCVAR_NONE, "The amount of time (in seconds) the fake parasite cure takes to use. If set to -1, the ttt_parasite_cure_time value will be used instead", -1, 30)
end

if CLIENT then
    function SWEP:Initialize()
        self:AddHUDHelp("cure_help_pri", "cure_help_sec", true)
        return self.BaseClass.Initialize(self)
    end
end

function SWEP:SetupDataTables()
    self.BaseClass.SetupDataTables(self)

    if SERVER then
        -- Use the same setting as for the real parasite cure if the override isn't explicitly set
        if self.DeviceTimeConVar:GetInt() < 0 then
            self:SetChargeTime(GetConVar("ttt_parasite_cure_time"):GetInt())
        end
    end
end

local quack_fake_cure_mode = CreateConVar("ttt_quack_fake_cure_mode", "0", FCVAR_REPLICATED, "How to handle using a fake parasite cure on someone who is not infected. 0 - Kill nobody (But use up the cure), 1 - Kill the person who uses the cure, 2 - Kill the person the cure is used on", 0, 2)

if SERVER then
    function SWEP:OnSuccess(ply, body)
        ply:EmitSound(cured)

        if ply:GetNWBool("ParasiteInfected", false) then
            for _, v in pairs(player.GetAll()) do
                if v:GetNWString("ParasiteInfectingTarget", "") == ply:SteamID64() then
                    v:QueueMessage(MSG_PRINTCENTER, "A fake cure has been used on your host.")
                end
            end
        else
            local owner = self:GetOwner()
            local cure_mode = quack_fake_cure_mode:GetInt()
            if cure_mode == QUACK_FAKE_CURE_KILL_OWNER and IsValid(owner) then
                owner:Kill()
            elseif cure_mode == QUACK_FAKE_CURE_KILL_TARGET then
                ply:Kill()
            end
        end
    end

    function SWEP:GetProgressMessage(ply, body, bone)
        if ply == self:GetOwner() then
            return "CURING YOURSELF"
        end
        return "CURING " .. string.upper(ply:Nick())
    end

    function SWEP:GetAbortMessage()
        return "CURE ABORTED"
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

    function SWEP:Equip(newowner)
        if newowner:IsTraitorTeam() then
            newowner:PrintMessage(HUD_PRINTTALK, ROLE_STRINGS[ROLE_TRAITOR] .. ", the parasite cure you are holding is a fake.")
        end
    end
end