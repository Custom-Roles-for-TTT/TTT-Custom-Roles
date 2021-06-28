AddCSLuaFile()

if CLIENT then
    SWEP.PrintName = "Parasite Cure"
    SWEP.Slot = 6

    SWEP.DrawCrosshair = false
    SWEP.ViewModelFOV = 54

    SWEP.EquipMenuData = {
            type =  "Weapon",
            desc =  [[Use on a player to cure them of parasites.

Using this on a player who is not infected will kill them!]]
        };

    SWEP.Icon = "vgui/ttt/icon_cure"
end

SWEP.Base = "weapon_tttbase"

SWEP.ViewModel = "models/weapons/c_medkit.mdl"
SWEP.WorldModel = "models/weapons/w_medkit.mdl"

SWEP.Primary.ClipSize        = -1
SWEP.Primary.DefaultClip     = -1
SWEP.Primary.Automatic       = true
SWEP.Primary.Delay           = 1
SWEP.Primary.Ammo            = "none"

SWEP.Secondary.ClipSize       = -1
SWEP.Secondary.DefaultClip    = -1
SWEP.Secondary.Automatic      = true
SWEP.Secondary.Ammo           = "none"
SWEP.Secondary.Delay          = 2

SWEP.Kind = WEAPON_EQUIP
SWEP.CanBuy = { ROLE_DETECTIVE }
SWEP.NoSights = true

local CureSound = Sound("items/smallmedkit1.wav")

function SWEP:Initialize()
    self:SetWeaponHoldType("slam")
end

function SWEP:PrimaryAttack()

    if not SERVER then return end

    local tr = util.TraceLine({
        start = self.Owner:GetShootPos(),
        endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 64,
        filter = self.Owner
    })

    local ent = tr.Entity

    if IsValid(ent) and ent:IsPlayer() then
        ent:EmitSound(CureSound)

        if ent:GetNWBool("Infected", false) then
            for _, v in pairs(player.GetAll()) do
                if v:GetNWString(InfectingTarget, "") == ent:SteamID64() then
                    ent:SetNWBool("Infected", false)
                    v:SetNWBool("Infecting", false)
                    v:SetNWString("InfectingTarget", nil)
                    v:SetNWInt("InfectionProgress", 0)
                    timer.Remove(v:Nick() .. "InfectionProgress")
                    timer.Remove(v:Nick() .. "InfectingSpectate")
                    v:PrintMessage(HUD_PRINTCENTER, "Your host has been cured.")
                end
            end
        else
            ent:Kill()
        end

        self:Remove()
    else
        self:SetNextPrimaryFire(CurTime() + 1)
    end
end
