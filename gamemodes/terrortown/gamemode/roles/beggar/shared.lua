AddCSLuaFile()

local table = table

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

    -- Use what role they changed to to determine which setting to use and whether they should be revealed
    local beggarMode = nil
    local sameTeam = false
    local otherTeam = false
    if tgt:IsTraitor() then
        beggarMode = GetGlobalInt("ttt_beggar_reveal_traitor", BEGGAR_REVEAL_ALL)
        sameTeam = self:IsTraitorTeam() and beggarMode == BEGGAR_REVEAL_TRAITORS
        otherTeam = self:IsInnocentTeam() and beggarMode == BEGGAR_REVEAL_INNOCENTS
    elseif tgt:IsInnocent() then
        beggarMode = GetGlobalInt("ttt_beggar_reveal_innocent", BEGGAR_REVEAL_TRAITORS)
        sameTeam = self:IsInnocentTeam() and beggarMode == BEGGAR_REVEAL_INNOCENTS
        otherTeam = self:IsTraitorTeam() and beggarMode == BEGGAR_REVEAL_TRAITORS
    end

    -- Check the setting value and whether the client's team matches the reveal mode
    return beggarMode == BEGGAR_REVEAL_ALL or sameTeam or otherTeam
end

------------------
-- ROLE CONVARS --
------------------

ROLE_CONVARS[ROLE_BEGGAR] = {}
table.insert(ROLE_CONVARS[ROLE_BEGGAR], {
    cvar = "ttt_beggar_notify_mode",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_BEGGAR], {
    cvar = "ttt_beggar_notify_sound",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_BEGGAR], {
    cvar = "ttt_beggar_notify_confetti",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_BEGGAR], {
    cvar = "ttt_beggar_reveal_traitor",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_BEGGAR], {
    cvar = "ttt_beggar_reveal_innocent",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_BEGGAR], {
    cvar = "ttt_beggar_respawn",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_BEGGAR], {
    cvar = "ttt_beggar_respawn_limit",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_BEGGAR], {
    cvar = "ttt_beggar_respawn_delay",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})