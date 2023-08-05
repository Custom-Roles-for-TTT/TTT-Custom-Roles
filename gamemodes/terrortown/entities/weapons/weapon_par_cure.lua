AddCSLuaFile()

local IsValid = IsValid
local pairs = pairs
local player = player
local string = string
local timer = timer
local util = util

SWEP.HoldType               = "slam"

if CLIENT then
    local GetPTranslation = LANG.GetParamTranslation
    SWEP.PrintName = "Parasite Cure"
    SWEP.Slot = 6

    SWEP.DrawCrosshair = false
    SWEP.ViewModelFOV = 54

    SWEP.EquipMenuData = {
        type =  "item_weapon",
        desc = function()
            return GetPTranslation("cure_desc", {
                parasites = string.lower(ROLE_STRINGS_PLURAL[ROLE_PARASITE])
            })
        end
    };

    SWEP.Icon = "vgui/ttt/icon_cure"
end

SWEP.ViewModel              = "models/weapons/c_medkit.mdl"
SWEP.WorldModel             = "models/weapons/w_medkit.mdl"

SWEP.Base                   = "weapon_cr_defibbase"
SWEP.Category               = WEAPON_CATEGORY_ROLE
SWEP.Kind                   = WEAPON_EQUIP
SWEP.CanBuy                 = { ROLE_DOCTOR, ROLE_QUACK }
for role = 0, ROLE_MAX do
    if DETECTIVE_ROLES[role] then
        table.insert(SWEP.CanBuy, role)
        if not istable(DefaultEquipment[role]) then
            DefaultEquipment[role] = {}
        end
        if not table.HasValue(DefaultEquipment[role], "weapon_par_cure") then
            table.insert(DefaultEquipment[role], "weapon_par_cure")
        end
    end
end
SWEP.CanBuyDefault          = table.Copy(SWEP.CanBuy)
SWEP.AllowDrop              = true

SWEP.BlockShopRandomization = true

SWEP.DeadTarget             = false
SWEP.HasSecondary           = true

PARASITE_CURE_KILL_NONE = 0
PARASITE_CURE_KILL_OWNER = 1
PARASITE_CURE_KILL_TARGET = 2

local cured = Sound("items/smallmedkit1.wav")

if SERVER then
    SWEP.DeviceTimeConVar = CreateConVar("ttt_parasite_cure_time", "3", FCVAR_NONE, "The amount of time (in seconds) the parasite cure takes to use", 0, 30)
end

if CLIENT then
    function SWEP:Initialize()
        self:AddHUDHelp("cure_help_pri", "cure_help_sec", true)
        return self.BaseClass.Initialize(self)
    end
end

local parasite_cure_mode = CreateConVar("ttt_parasite_cure_mode", "2", FCVAR_REPLICATED, "How to handle using a parasite cure on someone who is not infected. 0 - Kill nobody (But use up the cure), 1 - Kill the person who uses the cure, 2 - Kill the person the cure is used on", 0, 2)

if SERVER then
    function SWEP:OnSuccess(ply, body)
        ply:EmitSound(cured)

        if ply:GetNWBool("ParasiteInfected", false) then
            for _, v in pairs(player.GetAll()) do
                if v:GetNWString("ParasiteInfectingTarget", "") == ply:SteamID64() then
                    ply:SetNWBool("ParasiteInfected", false)
                    v:SetNWBool("ParasiteInfecting", false)
                    v:SetNWString("ParasiteInfectingTarget", nil)
                    v:SetNWInt("ParasiteInfectionProgress", 0)
                    timer.Remove(v:Nick() .. "ParasiteInfectionProgress")
                    timer.Remove(v:Nick() .. "ParasiteInfectingSpectate")
                    v:QueueMessage(MSG_PRINTCENTER, "Your host has been cured.")

                    if GetConVar("ttt_parasite_infection_saves_lover"):GetBool() then
                        local loverSID = v:GetNWString("TTTCupidLover", "")
                        if loverSID ~= "" then
                            local lover = player.GetBySteamID64(loverSID)
                            lover:PrintMessage(HUD_PRINTTALK, "Your lover's host was cured!")
                        end
                    end
                end
            end
        else
            local owner = self:GetOwner()
            local cure_mode = parasite_cure_mode:GetInt()
            if cure_mode == PARASITE_CURE_KILL_OWNER and IsValid(owner) then
                owner:Kill()
            elseif cure_mode == PARASITE_CURE_KILL_TARGET then
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
            newowner:PrintMessage(HUD_PRINTTALK, ROLE_STRINGS[ROLE_TRAITOR] .. ", the parasite cure you are holding is real.")
        end
    end
end