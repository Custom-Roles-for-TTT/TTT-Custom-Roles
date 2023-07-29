AddCSLuaFile()

local hook = hook

-------------
-- CONVARS --
-------------

local deputy_damage_penalty = CreateConVar("ttt_deputy_damage_penalty", "0", FCVAR_NONE, "Damage penalty that the deputy has before being promoted (e.g. 0.5 = 50% less damage)", 0, 1)
CreateConVar("ttt_deputy_without_detective", "0")
CreateConVar("ttt_deputy_activation_credits", "0", FCVAR_NONE, "The number of credits to give the deputy when they are activated", 0, 10)

------------
-- DAMAGE --
------------

hook.Add("ScalePlayerDamage", "Deputy_ScalePlayerDamage", function(ply, hitgroup, dmginfo)
    local att = dmginfo:GetAttacker()
    -- Only apply damage scaling after the round starts
    if IsPlayer(att) and GetRoundState() >= ROUND_ACTIVE then
        -- Deputies deal less damage before they are promoted
        if att:IsDeputy() and not att:IsRoleActive() then
            local penalty = deputy_damage_penalty:GetFloat()
            dmginfo:ScaleDamage(1 - penalty)
        end
    end
end)