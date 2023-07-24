AddCSLuaFile()

if CLIENT then
   SWEP.Slot = 8
end

SWEP.Base = "weapon_ttt_flaregun"
SWEP.Category = WEAPON_CATEGORY_ROLE
SWEP.Kind = WEAPON_ROLE
SWEP.CanBuy = {}

SWEP.InLoadoutFor = {ROLE_SPY}

SWEP.InLoadoutForDefault = {ROLE_SPY}

SWEP.AllowDrop = false
SWEP.LimitedStock = true