AddCSLuaFile()

local hook = hook

-------------
-- CONVARS --
-------------

local deputy_damage_penalty = GetConVar("ttt_deputy_damage_penalty")

CreateConVar("ttt_deputy_without_detective", "0")
CreateConVar("ttt_deputy_activation_credits", "0", FCVAR_NONE, "The number of credits to give the deputy when they are activated", 0, 10)

------------
-- DAMAGE --
------------

hook.Add("ScalePlayerDamage", "Deputy_ScalePlayerDamage", function(ply, hitgroup, dmginfo)
    -- Only apply damage scaling after the round starts
    if GetRoundState() < ROUND_ACTIVE then return end

    local att = dmginfo:GetAttacker()
    -- Deputies deal less damage before they are promoted
    if not IsPlayer(att) or not att:IsDeputy() or att:IsRoleActive() then return end

    local penalty = deputy_damage_penalty:GetFloat()
    dmginfo:ScaleDamage(1 - penalty)
end)