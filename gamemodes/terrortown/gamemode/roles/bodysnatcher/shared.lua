AddCSLuaFile()

local hook = hook
local table = table

-- Bodysnatcher reveal modes
BODYSNATCHER_REVEAL_NONE = 0
BODYSNATCHER_REVEAL_ALL = 1
BODYSNATCHER_REVEAL_TEAM = 2

-- Update their team
hook.Add("TTTUpdateRoleState", "Bodysnatcher_TTTUpdateRoleState", function()
    local bodysnatchers_are_independent = GetGlobalBool("ttt_bodysnatchers_are_independent", false)
    INDEPENDENT_ROLES[ROLE_BODYSNATCHER] = bodysnatchers_are_independent
    JESTER_ROLES[ROLE_BODYSNATCHER] = not bodysnatchers_are_independent
end)

--------------------
-- PLAYER METHODS --
--------------------

local plymeta = FindMetaTable("Player")

function plymeta:ShouldRevealBodysnatcher(tgt)
    -- If we weren't given a target, use ourselves
    if not tgt then tgt = self end

    -- Determine whether which setting we should check based on what role they changed to
    local bodysnatcherMode = nil
    if tgt:IsTraitorTeam() then
        bodysnatcherMode = GetGlobalInt("ttt_bodysnatcher_reveal_traitor", BODYSNATCHER_REVEAL_ALL)
    elseif tgt:IsInnocentTeam() then
        bodysnatcherMode = GetGlobalInt("ttt_bodysnatcher_reveal_innocent", BODYSNATCHER_REVEAL_ALL)
    elseif tgt:IsMonsterTeam() then
        bodysnatcherMode = GetGlobalInt("ttt_bodysnatcher_reveal_monster", BODYSNATCHER_REVEAL_ALL)
    elseif tgt:IsIndependentTeam() then
        bodysnatcherMode = GetGlobalInt("ttt_bodysnatcher_reveal_independent", BODYSNATCHER_REVEAL_ALL)
    end

    -- Check the setting value and whether the player and the target are the same team
    return bodysnatcherMode == BODYSNATCHER_REVEAL_ALL or (self:IsSameTeam(tgt) and bodysnatcherMode == BODYSNATCHER_REVEAL_TEAM)
end

------------------
-- ROLE CONVARS --
------------------

ROLE_CONVARS[ROLE_BODYSNATCHER] = {}
table.insert(ROLE_CONVARS[ROLE_BODYSNATCHER], {
    cvar = "ttt_bodysnatcher_notify_mode",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_BODYSNATCHER], {
    cvar = "ttt_bodysnatcher_notify_sound",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_BODYSNATCHER], {
    cvar = "ttt_bodysnatcher_notify_confetti",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_BODYSNATCHER], {
    cvar = "ttt_bodysnatcher_destroy_body",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_BODYSNATCHER], {
    cvar = "ttt_bodysnatcher_show_role",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_BODYSNATCHER], {
    cvar = "ttt_bodysnatchers_are_independent",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_BODYSNATCHER], {
    cvar = "ttt_bodysnatcher_reveal_traitor",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_BODYSNATCHER], {
    cvar = "ttt_bodysnatcher_reveal_innocent",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_BODYSNATCHER], {
    cvar = "ttt_bodysnatcher_reveal_monster",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_BODYSNATCHER], {
    cvar = "ttt_bodysnatcher_reveal_independent",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_BODYSNATCHER], {
    cvar = "ttt_bodysnatcher_respawn",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_BODYSNATCHER], {
    cvar = "ttt_bodysnatcher_respawn_limit",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_BODYSNATCHER], {
    cvar = "ttt_bodysnatcher_respawn_delay",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_BODYSNATCHER], {
    cvar = "ttt_bodysnatcher_device_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})