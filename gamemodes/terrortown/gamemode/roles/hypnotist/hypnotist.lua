AddCSLuaFile()

-------------
-- CONVARS --
-------------

local hypnotist_device_loadout = CreateConVar("ttt_hypnotist_device_loadout", "1")
local hypnotist_device_shop = CreateConVar("ttt_hypnotist_device_shop", "0")
local hypnotist_device_shop_rebuyable = CreateConVar("ttt_hypnotist_device_shop_rebuyable", "0")

hook.Add("TTTSyncGlobals", "Hypnotist_TTTSyncGlobals", function()
    SetGlobalBool("ttt_hypnotist_device_loadout", hypnotist_device_loadout:GetBool())
    SetGlobalBool("ttt_hypnotist_device_shop", hypnotist_device_shop:GetBool())
    SetGlobalBool("ttt_hypnotist_device_shop_rebuyable", hypnotist_device_shop_rebuyable:GetBool())
end)

------------------
-- ROLE WEAPONS --
------------------

-- Only allow the hypnotist to pick up hypnotist-specific weapons
hook.Add("PlayerCanPickupWeapon", "Hypnotist_Weapons_PlayerCanPickupWeapon", function(ply, wep)
    if not IsValid(wep) or not IsValid(ply) then return end
    if ply:IsSpec() then return false end

    if wep:GetClass() == "weapon_hyp_brainwash" then
        return ply:IsHypnotist()
    end
end)

----------------
-- ROLE STATE --
----------------

hook.Add("TTTPrepareRound", "Hypnotist_PrepareRound", function()
    for _, v in pairs(player.GetAll()) do
        v:SetNWBool("WasHypnotised", false)
    end
end)