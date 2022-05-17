AddCSLuaFile()

local hook = hook
local IsValid = IsValid
local pairs = pairs

local GetAllPlayers = player.GetAll

-------------
-- CONVARS --
-------------

local informant_share_scans = CreateConVar("ttt_informant_share_scans", "1")
local informant_can_scan_jesters = CreateConVar("ttt_informant_can_scan_jesters", "1")
local informant_can_scan_glitches = CreateConVar("ttt_informant_can_scan_glitches", "0")

hook.Add("TTTSyncGlobals", "Hypnotist_TTTSyncGlobals", function()
    SetGlobalBool("ttt_informant_share_scans", informant_share_scans:GetBool())
    SetGlobalBool("ttt_informant_can_scan_jesters", informant_can_scan_jesters:GetBool())
    SetGlobalBool("ttt_informant_can_scan_glitches", informant_can_scan_glitches:GetBool())
end)

------------------
-- ROLE WEAPONS --
------------------

-- Only allow the hypnotist to pick up hypnotist-specific weapons
hook.Add("PlayerCanPickupWeapon", "Informant_Weapons_PlayerCanPickupWeapon", function(ply, wep)
    if not IsValid(wep) or not IsValid(ply) then return end
    if ply:IsSpec() then return false end

    if wep:GetClass() == "weapon_inf_scanner" then
        return ply:IsInformant()
    end
end)

----------------
-- ROLE STATE --
----------------

hook.Add("TTTPrepareRound", "Informant_PrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        v:SetNWInt("TTTInformantScanStage", INFORMANT_UNSCANNED)
    end
end)