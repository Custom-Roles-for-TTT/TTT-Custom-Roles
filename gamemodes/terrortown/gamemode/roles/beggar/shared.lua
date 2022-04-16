AddCSLuaFile()

local table = table

-- Beggar reveal modes
BEGGAR_REVEAL_NONE = 0
BEGGAR_REVEAL_ALL = 1
BEGGAR_REVEAL_TRAITORS = 2
BEGGAR_REVEAL_INNOCENTS = 3

-- Update their team
hook.Add("TTTUpdateRoleState", "Beggar_TTTUpdateRoleState", function()
    local beggars_are_independent = GetGlobalBool("ttt_beggars_are_independent", false)
    INDEPENDENT_ROLES[ROLE_BEGGAR] = beggars_are_independent
    JESTER_ROLES[ROLE_BEGGAR] = not beggars_are_independent
end)

--------------------
-- PLAYER METHODS --
--------------------

local plymeta = FindMetaTable("Player")

function plymeta:ShouldRevealBeggar(tgt)
    -- If we weren't given a target, use ourselves
    if not tgt then tgt = self end

    -- Use what role they changed to to determine which setting to use
    local beggarMode = nil
    if tgt:IsTraitor() then
        beggarMode = GetGlobalInt("ttt_beggar_reveal_traitor", BEGGAR_REVEAL_ALL)
    elseif tgt:IsInnocent() then
        beggarMode = GetGlobalInt("ttt_beggar_reveal_innocent", BEGGAR_REVEAL_TRAITORS)
    end

    -- Then determine whether this player should show for the client's team
    local traitorTeam = self:IsTraitorTeam() and beggarMode == BEGGAR_REVEAL_TRAITORS
    local innocentTeam = self:IsInnocentTeam() and beggarMode == BEGGAR_REVEAL_INNOCENTS

    -- Check the setting value and whether the client's team matches the reveal mode
    return beggarMode == BEGGAR_REVEAL_ALL or traitorTeam or innocentTeam
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
    cvar = "ttt_beggars_are_independent",
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