AddCSLuaFile()

local hook = hook
local IsValid = IsValid
local pairs = pairs

local GetAllPlayers = player.GetAll

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
    for _, v in pairs(GetAllPlayers()) do
        v:SetNWBool("WasHypnotised", false)
    end
end)