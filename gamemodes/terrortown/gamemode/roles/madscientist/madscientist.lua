AddCSLuaFile()

local hook = hook

-------------
-- CONVARS --
-------------

local madscientist_respawn_enable = CreateConVar("ttt_madscientist_respawn_enable", "0")

hook.Add("TTTSyncGlobals", "MadScientist_TTTSyncGlobals", function()
    SetGlobalBool("ttt_madscientist_respawn_enable", madscientist_respawn_enable:GetBool())
end)

-------------------
-- ROLE FEATURES --
-------------------

hook.Add("PlayerDeath", "MadScientist_PlayerDeath", function(victim, infl, attacker)
    if GetRoundState() ~= ROUND_ACTIVE then return end
    if not victim:IsMadScientist() then return end
    if not madscientist_respawn_enable:GetBool() then return end

    -- Respawn the mad scientist as a zombie if they are killed
    victim:RespawnAsZombie()
end)