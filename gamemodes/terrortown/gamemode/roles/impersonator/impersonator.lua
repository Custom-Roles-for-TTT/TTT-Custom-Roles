AddCSLuaFile()

local hook = hook
local IsPlayer = IsPlayer

-------------
-- CONVARS --
-------------

local impersonator_damage_penalty = CreateConVar("ttt_impersonator_damage_penalty", "0")
local impersonator_use_detective_icon = CreateConVar("ttt_impersonator_use_detective_icon", "1")
CreateConVar("ttt_impersonator_without_detective", "0")
CreateConVar("ttt_impersonator_activation_credits", "0")
CreateConVar("ttt_impersonator_detective_chance", "0")

hook.Add("TTTSyncGlobals", "Impersonator_TTTSyncGlobals", function()
    SetGlobalBool("ttt_impersonator_use_detective_icon", impersonator_use_detective_icon:GetBool())
end)

------------
-- DAMAGE --
------------

hook.Add("ScalePlayerDamage", "Impersonator_ScalePlayerDamage", function(ply, hitgroup, dmginfo)
    local att = dmginfo:GetAttacker()
    -- Only apply damage scaling after the round starts
    if IsPlayer(att) and GetRoundState() >= ROUND_ACTIVE then
        -- Impersonators deal less damage before they are promoted
        if att:IsImpersonator() and not att:IsRoleActive() then
            local penalty = impersonator_damage_penalty:GetFloat()
            dmginfo:ScaleDamage(1 - penalty)
        end
    end
end)