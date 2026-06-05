AddCSLuaFile()

local hook = hook

local AddHook = hook.Add
local RemoveHook = hook.Remove

-------------
-- CONVARS --
-------------

CreateConVar("ttt_deputy_without_detective", "0")
CreateConVar("ttt_deputy_activation_credits", "0", FCVAR_NONE, "The number of credits to give the deputy when they are activated", 0, 10)

local deputy_damage_penalty = GetConVar("ttt_deputy_damage_penalty")

------------
-- DAMAGE --
------------

local function Deputy_ScalePlayerDamage(ply, hitgroup, dmginfo)
    -- Only apply damage scaling after the round starts
    if GetRoundState() < ROUND_ACTIVE then return end

    local att = dmginfo:GetAttacker()
    -- Deputies deal less damage before they are promoted
    if not IsPlayer(att) or not att:IsDeputy() or att:IsRoleActive() then return end

    local penalty = deputy_damage_penalty:GetFloat()
    dmginfo:ScaleDamage(1 - penalty)
end

------------------
-- REGISTRATION --
------------------

ROLE_REGISTER_HOOKS[ROLE_DEPUTY] = function()
    AddHook("ScalePlayerDamage", "Deputy_ScalePlayerDamage", Deputy_ScalePlayerDamage)
end

ROLE_UNREGISTER_HOOKS[ROLE_DEPUTY] = function()
    RemoveHook("ScalePlayerDamage", "Deputy_ScalePlayerDamage")
end