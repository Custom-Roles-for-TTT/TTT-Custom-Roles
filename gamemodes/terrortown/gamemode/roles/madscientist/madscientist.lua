AddCSLuaFile()

local player = player

local PlayerIterator = player.Iterator

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

----------------
-- WIN CHECKS --
----------------

local function MadScientist_TTTCheckForWin()
    -- Only run the win check if the mad scientist win by themselves (or with the Zombies)
    if not INDEPENDENT_ROLES[ROLE_MADSCIENTIST] then return end

    local zombie_alive = false
    local other_alive = false
    for _, v in PlayerIterator() do
        if v:IsActive() then
            if v:IsZombie() or v:IsMadScientist() then
                zombie_alive = true
            elseif not v:ShouldActLikeJester() and not ROLE_HAS_PASSIVE_WIN[v:GetRole()] then
                other_alive = true
            end
        end
    end

    if zombie_alive and not other_alive then
        return WIN_ZOMBIE
    elseif zombie_alive then
        return WIN_NONE
    end
end

------------------
-- REGISTRATION --
------------------

ROLE_REGISTERED_HOOKS[ROLE_MADSCIENTIST] = {
    ["TTTCheckForWin"] = MadScientist_TTTCheckForWin,
    ["PlayerDeath"] = MadScientist_PlayerDeath
}