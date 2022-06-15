AddCSLuaFile()

local hook = hook

-------------
-- CONVARS --
-------------

local madscientist_respawn_enable = CreateConVar("ttt_madscientist_respawn_enable", "0")
local madscientist_is_monster = CreateConVar("ttt_madscientist_is_monster", "0")

hook.Add("TTTSyncGlobals", "MadScientist_TTTSyncGlobals", function()
    SetGlobalBool("ttt_madscientist_respawn_enable", madscientist_respawn_enable:GetBool())
    SetGlobalBool("ttt_madscientist_is_monster", madscientist_is_monster:GetBool())
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