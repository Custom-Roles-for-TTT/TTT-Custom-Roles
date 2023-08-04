AddCSLuaFile()

local hook = hook
local table = table

-- Bodysnatcher reveal modes
BODYSNATCHER_REVEAL_NONE = 0
BODYSNATCHER_REVEAL_ALL = 1
BODYSNATCHER_REVEAL_TEAM = 2

--------------------
-- PLAYER METHODS --
--------------------

local plymeta = FindMetaTable("Player")

function plymeta:ShouldRevealBodysnatcher(tgt)
    -- If we weren't given a target, use ourselves
    if not tgt then tgt = self end

    -- Determine whether which setting we should check based on what role they changed to
    local roleTeam = player.GetRoleTeam(tgt:GetRole(), true)
    local convarTeam = GetRawRoleTeamName(roleTeam)
    local bodysnatcherMode = cvars.Number("ttt_bodysnatcher_reveal_" .. convarTeam, BODYSNATCHER_REVEAL_ALL)

    -- Check the setting value and whether the player and the target are the same team
    return bodysnatcherMode == BODYSNATCHER_REVEAL_ALL or (self:IsSameTeam(tgt) and bodysnatcherMode == BODYSNATCHER_REVEAL_TEAM)
end

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_bodysnatcher_respawn", "0", FCVAR_REPLICATED, "Whether the bodysnatcher respawns when they are killed before joining another team", 0, 1)
CreateConVar("ttt_bodysnatcher_respawn_delay", "3", FCVAR_REPLICATED, "The delay to use when respawning the bodysnatcher (if \"ttt_bodysnatcher_respawn\" is enabled)", 0, 60)
CreateConVar("ttt_bodysnatcher_respawn_limit", "0", FCVAR_REPLICATED, "The maximum number of times the bodysnatcher can respawn (if \"ttt_bodysnatcher_respawn\" is enabled). Set to 0 to allow infinite respawns", 0, 30)
CreateConVar("ttt_bodysnatcher_reveal_innocent", "1", FCVAR_REPLICATED, "Who the bodysnatcher is revealed to when they join the innocent team", 0, 2)
CreateConVar("ttt_bodysnatcher_reveal_traitor", "1", FCVAR_REPLICATED, "Who the bodysnatcher is revealed to when they join the traitor team", 0, 2)
CreateConVar("ttt_bodysnatcher_reveal_jester", "1", FCVAR_REPLICATED, "Who the bodysnatcher is revealed to when they join the jester team", 0, 2)
CreateConVar("ttt_bodysnatcher_reveal_independent", "1", FCVAR_REPLICATED, "Who the bodysnatcher is revealed to when they join the independent team", 0, 2)
CreateConVar("ttt_bodysnatcher_reveal_monster", "1", FCVAR_REPLICATED, "Who the bodysnatcher is revealed to when they join the monster team", 0, 2)
CreateConVar("ttt_bodysnatcher_destroy_body", "0", FCVAR_REPLICATED, "Whether the bodysnatching device destroys the body it is used on or not", 0, 1)
CreateConVar("ttt_bodysnatcher_show_role", "1", FCVAR_REPLICATED, "Whether the bodysnatching device shows the role of the corpse it is used on or not", 0, 1)
local bodysnatcher_is_independent = CreateConVar("ttt_bodysnatcher_is_independent", "0", FCVAR_REPLICATED, "Whether bodysnatchers should be treated as members of the independent team", 0, 1)

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
    cvar = "ttt_bodysnatcher_is_independent",
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
    cvar = "ttt_bodysnatcher_reveal_jester",
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

-------------------
-- ROLE FEATURES --
-------------------

hook.Add("TTTUpdateRoleState", "Bodysnatcher_Team_TTTUpdateRoleState", function()
    local is_independent = bodysnatcher_is_independent:GetBool()
    INDEPENDENT_ROLES[ROLE_BODYSNATCHER] = is_independent
    JESTER_ROLES[ROLE_BODYSNATCHER] = not is_independent
end)