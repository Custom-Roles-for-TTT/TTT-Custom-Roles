AddCSLuaFile()

local table = table

-- Initialize role features
BEGGAR_UNSCANNED = 0
BEGGAR_SCANNED_HIDDEN = 1
BEGGAR_SCANNED_TEAM = 2

BEGGAR_SCANNER_IDLE = 0
BEGGAR_SCANNER_LOCKED = 1
BEGGAR_SCANNER_SEARCHING = 2
BEGGAR_SCANNER_LOST = 3

BEGGAR_SCAN_MODE_DISABLED = 0
BEGGAR_SCAN_MODE_TRAITORS = 1
BEGGAR_SCAN_MODE_SHOPS = 2

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
        beggarMode = GetConVar("ttt_beggar_reveal_traitor"):GetInt()
    elseif tgt:IsInnocent() then
        beggarMode = GetConVar("ttt_beggar_reveal_innocent"):GetInt()
    end

    -- Then determine whether this player should show for the client's team
    local traitorTeam = self:IsTraitorTeam() and beggarMode == ANNOUNCE_REVEAL_TRAITORS
    local innocentTeam = self:IsInnocentTeam() and beggarMode == ANNOUNCE_REVEAL_INNOCENTS

    -- Check the setting value and whether the client's team matches the reveal mode
    return beggarMode == ANNOUNCE_REVEAL_ALL or traitorTeam or innocentTeam
end

------------------
-- ROLE CONVARS --
------------------

local beggar_is_independent = CreateConVar("ttt_beggar_is_independent", "0", FCVAR_REPLICATED, "Whether beggars should be treated as members of the independent team", 0, 1)
CreateConVar("ttt_beggar_respawn", "0", FCVAR_REPLICATED, "Whether the beggar respawns when they are killed before joining another team", 0, 1)
CreateConVar("ttt_beggar_respawn_limit", "0", FCVAR_REPLICATED, "The maximum number of times the beggar can respawn (if \"ttt_beggar_respawn\" is enabled). Set to 0 to allow infinite", 0, 30)
CreateConVar("ttt_beggar_respawn_delay", "3", FCVAR_REPLICATED, "The delay to use when respawning the beggar (if \"ttt_beggar_respawn\" is enabled)", 0, 60)
CreateConVar("ttt_beggar_respawn_change_role", "0", FCVAR_REPLICATED, "Whether to change the role of the respawning the beggar (if \"ttt_beggar_respawn\" is enabled)", 0, 1)
CreateConVar("ttt_beggar_reveal_traitor", "1", FCVAR_REPLICATED, "Who the beggar is revealed to when they join the traitor team", 0, 3)
CreateConVar("ttt_beggar_reveal_innocent", "2", FCVAR_REPLICATED, "Who the beggar is revealed to when they join the innocent team", 0, 3)
CreateConVar("ttt_beggar_scan", "0", FCVAR_REPLICATED, "Whether the beggar can scan players to see if they are traitors. 0 - Disabled. 1 - Can only scan traitors. 2 - Can scan any role that has a shop.", 0, 2)
CreateConVar("ttt_beggar_scan_time", "15", FCVAR_REPLICATED, "The amount of time (in seconds) the beggar's scanner takes to use", 0, 60)

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
    cvar = "ttt_beggar_is_independent",
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
table.insert(ROLE_CONVARS[ROLE_BEGGAR], {
    cvar = "ttt_beggar_respawn_change_role",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_BEGGAR], {
    cvar = "ttt_beggar_scan",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_BEGGAR], {
    cvar = "ttt_beggar_scan_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_BEGGAR], {
    cvar = "ttt_beggar_scan_float_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_BEGGAR], {
    cvar = "ttt_beggar_scan_cooldown",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_BEGGAR], {
    cvar = "ttt_beggar_scan_distance",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

-------------------
-- ROLE FEATURES --
-------------------

hook.Add("TTTUpdateRoleState", "Beggar_TTTUpdateRoleState", function()
    local is_independent = beggar_is_independent:GetBool()
    INDEPENDENT_ROLES[ROLE_BEGGAR] = is_independent
    JESTER_ROLES[ROLE_BEGGAR] = not is_independent
end)