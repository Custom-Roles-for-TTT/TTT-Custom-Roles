AddCSLuaFile()

-------------
-- CONVARS --
-------------

CreateConVar("ttt_hypnotist_device_loadout", "1")
CreateConVar("ttt_hypnotist_device_shop", "0")

hook.Add("TTTSyncGlobals", "Hypnotist_TTTSyncGlobals", function()
    SetGlobalBool("ttt_hypnotist_device_loadout", GetConVar("ttt_hypnotist_device_loadout"):GetBool())
    SetGlobalBool("ttt_hypnotist_device_shop", GetConVar("ttt_hypnotist_device_shop"):GetBool())
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