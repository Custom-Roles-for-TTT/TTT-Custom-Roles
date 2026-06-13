AddCSLuaFile()

-------------
-- CONVARS --
-------------

local madscientist_respawn_enabled = GetConVar("ttt_madscientist_respawn_enabled")

-------------------
-- ROLE FEATURES --
-------------------

local function MadScientist_PlayerDeath(victim, infl, attacker)
    if GetRoundState() ~= ROUND_ACTIVE then return end
    if not victim:IsMadScientist() then return end
    if not madscientist_respawn_enabled:GetBool() then return end

    -- Respawn the mad scientist as a zombie if they are killed
    victim:RespawnAsZombie()
end

------------------
-- REGISTRATION --
------------------

ROLE_REGISTERED_HOOKS[ROLE_MADSCIENTIST] = {
    ["PlayerDeath"] = MadScientist_PlayerDeath
}