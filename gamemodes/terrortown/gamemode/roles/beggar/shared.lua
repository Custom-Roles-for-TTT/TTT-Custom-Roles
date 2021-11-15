AddCSLuaFile()

-- Beggar reveal modes
BEGGAR_REVEAL_NONE = 0
BEGGAR_REVEAL_ALL = 1
BEGGAR_REVEAL_TRAITORS = 2
BEGGAR_REVEAL_INNOCENTS = 3

--------------------
-- PLAYER METHODS --
--------------------

local plymeta = FindMetaTable("Player")

function plymeta:ShouldRevealBeggar(tgt)
    -- If we weren't given a target, use ourselves
    if not tgt then tgt = self end

    -- Determine whether which setting we should check based on what role they changed to
    local beggarMode = nil
    local sameTeam = false
    if tgt:IsTraitor() then
        beggarMode = GetGlobalInt("ttt_beggar_reveal_traitor", BEGGAR_REVEAL_ALL)
        sameTeam = self:IsTraitorTeam() and beggarMode == BEGGAR_REVEAL_TRAITORS
    elseif tgt:IsInnocent() then
        beggarMode = GetGlobalInt("ttt_beggar_reveal_innocent", BEGGAR_REVEAL_TRAITORS)
        sameTeam = self:IsInnocentTeam() and beggarMode == BEGGAR_REVEAL_INNOCENTS
    end

    -- Check the setting value and the player's team to see we if should reveal this beggar
    return beggarMode == BEGGAR_REVEAL_ALL or sameTeam
end