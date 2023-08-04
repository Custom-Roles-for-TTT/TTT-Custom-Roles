AddCSLuaFile()

local hook = hook

-------------
-- CONVARS --
-------------

local impersonator_damage_penalty = GetConVar("ttt_impersonator_damage_penalty")

CreateConVar("ttt_impersonator_without_detective", "0")
CreateConVar("ttt_impersonator_activation_credits", "0", FCVAR_NONE, "The number of credits to give the impersonator when they are activated", 0, 10)
CreateConVar("ttt_impersonator_detective_chance", "0", FCVAR_NONE, "The chance that a detective will spawn as a promoted impersonator instead (e.g. 0.5 = 50% chance)", 0, 1)

------------
-- DAMAGE --
------------

hook.Add("ScalePlayerDamage", "Impersonator_ScalePlayerDamage", function(ply, hitgroup, dmginfo)
    -- Only apply damage scaling after the round starts
    if GetRoundState() < ROUND_ACTIVE then return end

    local att = dmginfo:GetAttacker()
    -- Impersonators deal less damage before they are promoted
    if not IsPlayer(att) or not att:IsImpersonator() or att:IsRoleActive() then return end

    local penalty = impersonator_damage_penalty:GetFloat()
    dmginfo:ScaleDamage(1 - penalty)
end)