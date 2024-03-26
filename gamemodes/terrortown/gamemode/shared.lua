local file = file
local hook = hook
local ipairs = ipairs
local IsValid = IsValid
local math = math
local net = net
local pairs = pairs
local string = string
local table = table

local FileExists = file.Exists
local FileFind = file.Find
local CallHook = hook.Call
local RunHook = hook.Run
local GetAllPlayers = player.GetAll
local StringUpper = string.upper
local StringLower = string.lower
local StringFind = string.find
local StringFormat = string.format
local StringSplit = string.Split
local StringSub = string.sub

include("player_class/player_ttt.lua")

-- Version string for display and function for version checks
CR_VERSION = "2.1.9"
CR_BETA = true
CR_WORKSHOP_ID = CR_BETA and "2404251054" or "2421039084"

function CRVersion(version)
    local installedVersionRaw = StringSplit(CR_VERSION, ".")
    local installedVersion = {
        major = tonumber(installedVersionRaw[1]),
        minor = tonumber(installedVersionRaw[2]),
        patch = tonumber(installedVersionRaw[3])
    }

    local neededVersionRaw = StringSplit(version, ".")
    local neededVersion = {
        major = tonumber(neededVersionRaw[1]),
        minor = tonumber(neededVersionRaw[2]),
        patch = tonumber(neededVersionRaw[3])
    }

    if installedVersion.major > neededVersion.major then
        return true
    elseif installedVersion.major == neededVersion.major then
        if installedVersion.minor > neededVersion.minor then
            return true
        elseif installedVersion.minor == neededVersion.minor then
            if installedVersion.patch >= neededVersion.patch then
                return true
            end
        end
    end

    return false
end

GM.Name = "Trouble in Terrorist Town"
GM.Author = "Bad King Urgrain"
GM.Website = "ttt.badking.net"
GM.Version = "Custom Roles for TTT v" .. CR_VERSION

GM.Customized = false

local function IsCustomRolesMounted()
    for _, a in ipairs(engine.GetAddons()) do
        if tostring(a.wsid) == CR_WORKSHOP_ID and a.mounted then
            return true
        end
    end
    return false
end

CRDebug = CRDebug or {
    -- Only enable this on beta when we're not mounted from the workshop
    Enabled = CR_BETA and not IsCustomRolesMounted(),
    -- These keys (in "{EventName}_{Identifier}" format) are known to re-register themselves
    IgnoredHookDupes = {
        "InitPostEntity_CreateVoiceVGUI"
    }
}

-- Only run this when we're debugging and only do it once
if CRDebug.Enabled and not CRDebug.HooksChecked then
    CRDebug.HooksChecked = CRDebug.HooksChecked or {}
    local oldHookAdd = hook.Add
    hook.Add = function(eventName, identifier, func)
        local info = debug.getinfo(2, "Sl")
        -- Only run the hook checks for custom roles code
        if StringFind(info.short_src, "custom-roles", 1, true) or StringFind(info.short_src, "customroles", 1, true) then
            local key = eventName .. "_" .. tostring(identifier)
            -- Keep track of which ones we've checked already so we don't spam ourselves on reload
            -- Also ignore the ones that are known to replace themselves... for whatever reason
            if not table.HasValue(CRDebug.IgnoredHookDupes, key) then
                local locationKey = info.short_src .. "_" .. info.currentline
                -- If we have a location key saved but it's different this time then it's a duplicate
                if CRDebug.HooksChecked[key] and CRDebug.HooksChecked[key] ~= locationKey then
                    ErrorNoHaltWithStack("Hook for '" .. eventName .. "' with identifier '" .. identifier .. "' already exists!")
                else
                    CRDebug.HooksChecked[key] = locationKey
                end
            end
        end
        oldHookAdd(eventName, identifier, func)
    end

    local oldHookRemove = hook.Remove
    hook.Remove = function(eventName, identifier)
        local info = debug.getinfo(2, "S")
        -- Only run the hook checks for custom roles code
        if StringFind(info.short_src, "custom-roles", 1, true) or StringFind(info.short_src, "customroles", 1, true) then
            local key = eventName .. "_" .. tostring(identifier)
            CRDebug.HooksChecked[key] = false
        end
        oldHookRemove(eventName, identifier)
    end
end

-- Round status consts
ROUND_WAIT = 1
ROUND_PREP = 2
ROUND_ACTIVE = 3
ROUND_POST = 4

-- Player roles
ROLE_NONE = -1
ROLE_INNOCENT = 0
ROLE_TRAITOR = 1
ROLE_DETECTIVE = 2
ROLE_JESTER = 3
ROLE_SWAPPER = 4
ROLE_GLITCH = 5
ROLE_PHANTOM = 6
ROLE_HYPNOTIST = 7
ROLE_REVENGER = 8
ROLE_DRUNK = 9
ROLE_CLOWN = 10
ROLE_DEPUTY = 11
ROLE_IMPERSONATOR = 12
ROLE_BEGGAR = 13
ROLE_OLDMAN = 14
ROLE_MERCENARY = 15
ROLE_BODYSNATCHER = 16
ROLE_VETERAN = 17
ROLE_ASSASSIN = 18
ROLE_KILLER = 19
ROLE_ZOMBIE = 20
ROLE_VAMPIRE = 21
ROLE_DOCTOR = 22
ROLE_QUACK = 23
ROLE_PARASITE = 24
ROLE_TRICKSTER = 25
ROLE_PARAMEDIC = 26
ROLE_MADSCIENTIST = 27
ROLE_PALADIN = 28
ROLE_TRACKER = 29
ROLE_MEDIUM = 30
ROLE_LOOTGOBLIN = 31
ROLE_TURNCOAT = 32
ROLE_SAPPER = 33
ROLE_INFORMANT = 34
ROLE_MARSHAL = 35
ROLE_INFECTED = 36
ROLE_CUPID = 37
ROLE_SHADOW = 38
ROLE_SPONGE = 39
ROLE_ARSONIST = 40
ROLE_SPY = 41
ROLE_HIVEMIND = 42
ROLE_GUESSER = 43
ROLE_QUARTERMASTER = 44
ROLE_VINDICATOR = 45

ROLE_MAX = 45
ROLE_EXTERNAL_START = ROLE_MAX + 1

local function AddRoleAssociations(list, roles)
    -- Use an associative array so we can do a O(1) lookup by role
    -- See: https://wiki.facepunch.com/gmod/table.HasValue
    for _, r in ipairs(roles) do
        list[r] = true
    end
end

function GetTeamRoles(list, excludes)
    local roles = {}
    for r, v in pairs(list) do
        if v and (not excludes or not excludes[r]) then
            table.insert(roles, r)
        end
    end
    return roles
end

SHOP_ROLES = {}
AddRoleAssociations(SHOP_ROLES, {ROLE_TRAITOR, ROLE_DETECTIVE, ROLE_HYPNOTIST, ROLE_DEPUTY, ROLE_IMPERSONATOR, ROLE_JESTER, ROLE_SWAPPER, ROLE_CLOWN, ROLE_MERCENARY, ROLE_ASSASSIN, ROLE_KILLER, ROLE_ZOMBIE, ROLE_VAMPIRE, ROLE_VETERAN, ROLE_DOCTOR, ROLE_QUACK, ROLE_PARASITE, ROLE_PALADIN, ROLE_TRACKER, ROLE_MEDIUM, ROLE_SAPPER, ROLE_INFORMANT, ROLE_MARSHAL, ROLE_MADSCIENTIST, ROLE_SPY, ROLE_HIVEMIND, ROLE_QUARTERMASTER})

DELAYED_SHOP_ROLES = {}
AddRoleAssociations(DELAYED_SHOP_ROLES, {ROLE_CLOWN, ROLE_VETERAN, ROLE_DEPUTY})

TRAITOR_ROLES = {}
AddRoleAssociations(TRAITOR_ROLES, {ROLE_TRAITOR, ROLE_HYPNOTIST, ROLE_IMPERSONATOR, ROLE_ASSASSIN, ROLE_VAMPIRE, ROLE_QUACK, ROLE_PARASITE, ROLE_INFORMANT, ROLE_SPY})

INNOCENT_ROLES = {}
AddRoleAssociations(INNOCENT_ROLES, {ROLE_INNOCENT, ROLE_DETECTIVE, ROLE_GLITCH, ROLE_PHANTOM, ROLE_REVENGER, ROLE_DEPUTY, ROLE_MERCENARY, ROLE_VETERAN, ROLE_DOCTOR, ROLE_TRICKSTER, ROLE_PARAMEDIC, ROLE_PALADIN, ROLE_TRACKER, ROLE_MEDIUM, ROLE_TURNCOAT, ROLE_SAPPER, ROLE_MARSHAL, ROLE_INFECTED, ROLE_QUARTERMASTER, ROLE_VINDICATOR})

JESTER_ROLES = {}
AddRoleAssociations(JESTER_ROLES, {ROLE_JESTER, ROLE_SWAPPER, ROLE_CLOWN, ROLE_BEGGAR, ROLE_BODYSNATCHER, ROLE_LOOTGOBLIN, ROLE_CUPID, ROLE_SPONGE, ROLE_GUESSER})

INDEPENDENT_ROLES = {}
AddRoleAssociations(INDEPENDENT_ROLES, {ROLE_DRUNK, ROLE_OLDMAN, ROLE_KILLER, ROLE_ZOMBIE, ROLE_MADSCIENTIST, ROLE_SHADOW, ROLE_ARSONIST, ROLE_HIVEMIND})

MONSTER_ROLES = {}
AddRoleAssociations(MONSTER_ROLES, {})

DETECTIVE_ROLES = {}
AddRoleAssociations(DETECTIVE_ROLES, {ROLE_DETECTIVE, ROLE_PALADIN, ROLE_TRACKER, ROLE_MEDIUM, ROLE_SAPPER, ROLE_MARSHAL, ROLE_QUARTERMASTER})

DETECTIVE_LIKE_ROLES = {}
AddRoleAssociations(DETECTIVE_LIKE_ROLES, {ROLE_DEPUTY, ROLE_IMPERSONATOR})

DEFAULT_ROLES = {}
AddRoleAssociations(DEFAULT_ROLES, {ROLE_INNOCENT, ROLE_TRAITOR, ROLE_DETECTIVE})

ROLE_PACK_ROLES = {}

-- Traitors get this ability by default
TRAITOR_BUTTON_ROLES = {}
AddRoleAssociations(TRAITOR_BUTTON_ROLES, {ROLE_TRICKSTER})

-- Shop roles get this ability by default
CAN_LOOT_CREDITS_ROLES = {}
AddRoleAssociations(CAN_LOOT_CREDITS_ROLES, {ROLE_TRICKSTER, ROLE_LOOTGOBLIN, ROLE_HIVEMIND})

-- Role colours
COLOR_INNOCENT = {
    ["default"] = Color(25, 200, 25, 255),
    ["simple"] = Color(25, 200, 25, 255),
    ["protan"] = Color(128, 209, 255, 255),
    ["deutan"] = Color(128, 209, 255, 255),
    ["tritan"] = Color(25, 200, 25, 255)
}

COLOR_SPECIAL_INNOCENT = {
    ["default"] = Color(245, 200, 0, 255),
    ["simple"] = Color(25, 200, 25, 255),
    ["protan"] = Color(128, 209, 255, 255),
    ["deutan"] = Color(128, 209, 255, 255),
    ["tritan"] = Color(25, 200, 25, 255)
}

COLOR_TRAITOR = {
    ["default"] = Color(200, 25, 25, 255),
    ["simple"] = Color(200, 25, 25, 255),
    ["protan"] = Color(200, 25, 25, 255),
    ["deutan"] = Color(200, 25, 25, 255),
    ["tritan"] = Color(200, 25, 25, 255)
}

COLOR_SPECIAL_TRAITOR = {
    ["default"] = Color(245, 106, 0, 255),
    ["simple"] = Color(200, 25, 25, 255),
    ["protan"] = Color(200, 25, 25, 255),
    ["deutan"] = Color(200, 25, 25, 255),
    ["tritan"] = Color(200, 25, 25, 255)
}

COLOR_DETECTIVE = {
    ["default"] = Color(25, 25, 200, 255),
    ["simple"] = Color(25, 25, 200, 255),
    ["protan"] = Color(25, 25, 200, 255),
    ["deutan"] = Color(25, 25, 200, 255),
    ["tritan"] = Color(25, 25, 200, 255),
}

COLOR_SPECIAL_DETECTIVE = {
    ["default"] = Color(40, 180, 200, 255),
    ["simple"] = Color(25, 25, 200, 255),
    ["protan"] = Color(25, 25, 200, 255),
    ["deutan"] = Color(25, 25, 200, 255),
    ["tritan"] = Color(25, 25, 200, 255),
}

COLOR_JESTER = {
    ["default"] = Color(180, 23, 253, 255),
    ["simple"] = Color(180, 23, 253, 255),
    ["protan"] = Color(255, 194, 5, 255),
    ["deutan"] = Color(93, 247, 0, 255),
    ["tritan"] = Color(255, 194, 5, 255)
}

COLOR_INDEPENDENT = {
    ["default"] = Color(112, 50, 0, 255),
    ["simple"] = Color(112, 50, 0, 255),
    ["protan"] = Color(167, 161, 142, 255),
    ["deutan"] = Color(127, 137, 120, 255),
    ["tritan"] = Color(192, 199, 63, 255)
}

COLOR_MONSTER = {
    ["default"] = Color(69, 97, 0, 255),
    ["simple"] = Color(69, 97, 0, 255),
    ["protan"] = Color(69, 97, 0, 255),
    ["deutan"] = Color(69, 97, 0, 255),
    ["tritan"] = Color(69, 97, 0, 255)
}

local function ColorFromCustomConVars(name)
    local rConVar = GetConVar(name .. "_r")
    local gConVar = GetConVar(name .. "_g")
    local bConVar = GetConVar(name .. "_b")
    if rConVar and gConVar and bConVar then
        local r = tonumber(rConVar:GetString())
        local g = tonumber(gConVar:GetString())
        local b = tonumber(bConVar:GetString())
        return Color(r, g, b, 255)
    end
end

local function ModifyColor(color, type)
    local h, s, l = ColorToHSL(color)
    if type == "dark" then
        l = math.max(l - 0.125, 0.125)
    elseif type == "highlight" or "radar" then
        s = 1
    end

    local c = HSLToColor(h, s, l)
    if type == "scoreboard" then
        c = ColorAlpha(c, 30)
    elseif type == "sprite" then
        c = ColorAlpha(c, 130)
    elseif type == "radar" then
        c = ColorAlpha(c, 230)
    -- HSLToColor doesn't apply the Color metatable so call ColorAlpha to ensure this is actually a "Color"
    else
        c = ColorAlpha(c, 255)
    end

    return c
end

local modeCVar = nil
local overrideModeCVar = nil
local function GetColorMode()
    if not modeCVar then
        modeCVar = GetConVar("ttt_color_mode")
    end

    if not overrideModeCVar then
        overrideModeCVar = GetConVar("ttt_color_mode_override")
    end

    local overrideMode = overrideModeCVar and overrideModeCVar:GetString() or "none"
    if overrideMode ~= "none" then
        return overrideMode
    end
    return modeCVar and modeCVar:GetString() or "default"
end

local function FillRoleColors(list, type)
    local mode = GetColorMode()

    for r = ROLE_NONE, ROLE_MAX do
        local c
        if mode == "custom" then
            if r == ROLE_DETECTIVE then c = ColorFromCustomConVars("ttt_custom_det_color") or COLOR_DETECTIVE["default"]
            elseif DETECTIVE_ROLES[r] then c = ColorFromCustomConVars("ttt_custom_spec_det_color") or COLOR_SPECIAL_DETECTIVE["default"]
            elseif r == ROLE_INNOCENT then c = ColorFromCustomConVars("ttt_custom_inn_color") or COLOR_INNOCENT["default"]
            elseif INNOCENT_ROLES[r] then c = ColorFromCustomConVars("ttt_custom_spec_inn_color") or COLOR_SPECIAL_INNOCENT["default"]
            elseif r == ROLE_TRAITOR then c = ColorFromCustomConVars("ttt_custom_tra_color") or COLOR_TRAITOR["default"]
            elseif TRAITOR_ROLES[r] then c = ColorFromCustomConVars("ttt_custom_spec_tra_color") or COLOR_SPECIAL_TRAITOR["default"]
            elseif JESTER_ROLES[r] then c = ColorFromCustomConVars("ttt_custom_jes_color") or COLOR_JESTER["default"]
            elseif INDEPENDENT_ROLES[r] then c = ColorFromCustomConVars("ttt_custom_ind_color") or COLOR_INDEPENDENT["default"]
            elseif MONSTER_ROLES[r] then c = ColorFromCustomConVars("ttt_custom_mon_color") or COLOR_MONSTER["default"]
            else
                -- Don't modify this color because changing the saturation of it makes it red for some reason...
                list[r] = COLOR_DGREY
                continue
            end
        else
            if r == ROLE_DETECTIVE then c = COLOR_DETECTIVE[mode]
            elseif DETECTIVE_ROLES[r] then c = COLOR_SPECIAL_DETECTIVE[mode]
            elseif r == ROLE_INNOCENT then c = COLOR_INNOCENT[mode]
            elseif INNOCENT_ROLES[r] then c = COLOR_SPECIAL_INNOCENT[mode]
            elseif r == ROLE_TRAITOR then c = COLOR_TRAITOR[mode]
            elseif TRAITOR_ROLES[r] then c = COLOR_SPECIAL_TRAITOR[mode]
            elseif JESTER_ROLES[r] then c = COLOR_JESTER[mode]
            elseif INDEPENDENT_ROLES[r] then c = COLOR_INDEPENDENT[mode]
            elseif MONSTER_ROLES[r] then c = COLOR_MONSTER[mode]
            else
                -- Don't modify this color because changing the saturation of it makes it red for some reason...
                list[r] = COLOR_DGREY
                continue
            end
        end

        list[r] = ModifyColor(c or COLOR_WHITE, type)
    end
end

function GetRawRoleTeamName(role_team)
    if role_team == ROLE_TEAM_TRAITOR then
        return "traitor"
    elseif role_team == ROLE_TEAM_MONSTER then
        return "monster"
    elseif role_team == ROLE_TEAM_JESTER then
        return "jester"
    elseif role_team == ROLE_TEAM_INDEPENDENT then
        return "independent"
    end
    return "innocent"
end

if CLIENT then
    function GetRoleTeamColor(role_team, type)
        local mode = GetColorMode()
        local c = nil
        if mode == "custom" then
            if role_team == ROLE_TEAM_DETECTIVE then c = ColorFromCustomConVars("ttt_custom_spec_det_color") or COLOR_SPECIAL_DETECTIVE["default"]
            elseif role_team == ROLE_TEAM_INNOCENT then c = ColorFromCustomConVars("ttt_custom_spec_inn_color") or COLOR_SPECIAL_INNOCENT["default"]
            elseif role_team == ROLE_TEAM_TRAITOR then c = ColorFromCustomConVars("ttt_custom_spec_tra_color") or COLOR_SPECIAL_TRAITOR["default"]
            elseif role_team == ROLE_TEAM_JESTER then c = ColorFromCustomConVars("ttt_custom_jes_color") or COLOR_JESTER["default"]
            elseif role_team == ROLE_TEAM_INDEPENDENT then c = ColorFromCustomConVars("ttt_custom_ind_color") or COLOR_INDEPENDENT["default"]
            elseif role_team == ROLE_TEAM_MONSTER then c = ColorFromCustomConVars("ttt_custom_mon_color") or COLOR_MONSTER["default"]
            end
        else
            if role_team == ROLE_TEAM_DETECTIVE then c = COLOR_SPECIAL_DETECTIVE[mode]
            elseif role_team == ROLE_TEAM_INNOCENT then c = COLOR_SPECIAL_INNOCENT[mode]
            elseif role_team == ROLE_TEAM_TRAITOR then c = COLOR_SPECIAL_TRAITOR[mode]
            elseif role_team == ROLE_TEAM_JESTER then c = COLOR_JESTER[mode]
            elseif role_team == ROLE_TEAM_INDEPENDENT then c = COLOR_INDEPENDENT[mode]
            elseif role_team == ROLE_TEAM_MONSTER then c = COLOR_MONSTER[mode]
            end
        end

        return ModifyColor(c or COLOR_WHITE, type)
    end

    function GetRoleTeamName(role_team)
        return LANG.GetTranslation(GetRawRoleTeamName(role_team))
    end

    function GetRoleTeamInfo(role_team, simple_color)
        local teamName = GetRoleTeamName(role_team)
        local teamColor = GetRoleTeamColor(role_team)
        if simple_color then
            if role_team == ROLE_TEAM_INNOCENT or role_team == ROLE_TEAM_DETECTIVE then
                teamColor = ROLE_COLORS[ROLE_INNOCENT]
            elseif role_team == ROLE_TEAM_TRAITOR then
                teamColor = ROLE_COLORS[ROLE_TRAITOR]
            end
        end
        return teamName, teamColor
    end
else
    GetRoleTeamName = GetRawRoleTeamName
end

function CreateCreditConVar(role)
    -- Add explicit ROLE_INNOCENT exclusion here in case shop-for-all is enabled
    if not DEFAULT_ROLES[role] or role == ROLE_INNOCENT then
        local rolestring = ROLE_STRINGS_RAW[role]
        local credits = "0"
        if ROLE_STARTING_CREDITS[role] then credits = ROLE_STARTING_CREDITS[role]
        elseif TRAITOR_ROLES[role] then credits = "1"
        elseif DETECTIVE_ROLES[role] then credits = "1" end
        CreateConVar("ttt_" .. rolestring .. "_credits_starting", credits, FCVAR_REPLICATED)
    end
end

function CreateShopConVars(role)
    local rolestring = ROLE_STRINGS_RAW[role]
    CreateCreditConVar(role)

    CreateConVar("ttt_" .. rolestring .. "_shop_random_percent", "0", FCVAR_REPLICATED, "The percent chance that a weapon in the shop will not be shown for the " .. rolestring, 0, 100)
    CreateConVar("ttt_" .. rolestring .. "_shop_random_enabled", "0", FCVAR_REPLICATED, "Whether shop randomization should run for the " .. rolestring)

    local hassync = (TRAITOR_ROLES[role] and role ~= ROLE_TRAITOR) or (DETECTIVE_ROLES[role] and role ~= ROLE_DETECTIVE) or ROLE_HAS_SHOP_SYNC[role]
    if hassync then
        CreateConVar("ttt_" .. rolestring .. "_shop_sync", "0", FCVAR_REPLICATED)
    end

    -- Roles don't get both shop sync and shop mode
    if (INDEPENDENT_ROLES[role] or DELAYED_SHOP_ROLES[role] or ROLE_HAS_SHOP_MODE[role]) and not hassync then
        CreateConVar("ttt_" .. rolestring .. "_shop_mode", "0", FCVAR_REPLICATED)
    end

    if DELAYED_SHOP_ROLES[role] then
        CreateConVar("ttt_" .. rolestring .. "_shop_active_only", "1", FCVAR_REPLICATED)
        CreateConVar("ttt_" .. rolestring .. "_shop_delay", "0", FCVAR_REPLICATED)
    end
end

ROLE_COLORS = {}
ROLE_COLORS_DARK = {}
ROLE_COLORS_HIGHLIGHT = {}
ROLE_COLORS_SCOREBOARD = {}
ROLE_COLORS_SPRITE = {}
ROLE_COLORS_RADAR = {}

function UpdateRoleColours()
    ROLE_COLORS = {}
    FillRoleColors(ROLE_COLORS)
    ROLE_COLOURS = ROLE_COLORS

    ROLE_COLORS_DARK = {}
    FillRoleColors(ROLE_COLORS_DARK, "dark")
    ROLE_COLOURS_DARK = ROLE_COLORS_DARK

    ROLE_COLORS_HIGHLIGHT = {}
    FillRoleColors(ROLE_COLORS_HIGHLIGHT, "highlight")
    ROLE_COLOURS_HIGHLIGHT = ROLE_COLORS_HIGHLIGHT

    ROLE_COLORS_SCOREBOARD = {}
    FillRoleColors(ROLE_COLORS_SCOREBOARD, "scoreboard")
    ROLE_COLOURS_SCOREBOARD = ROLE_COLORS_SCOREBOARD

    ROLE_COLORS_SPRITE = {}
    FillRoleColors(ROLE_COLORS_SPRITE, "sprite")
    ROLE_COLOURS_SPRITE = ROLE_COLORS_SPRITE

    ROLE_COLORS_RADAR = {}
    FillRoleColors(ROLE_COLORS_RADAR, "radar")
    ROLE_COLOURS_RADAR = ROLE_COLORS_RADAR
end
UpdateRoleColours()

-- Role strings
ROLE_STRINGS_RAW = {
    [ROLE_INNOCENT] = "innocent",
    [ROLE_TRAITOR] = "traitor",
    [ROLE_DETECTIVE] = "detective",
    [ROLE_JESTER] = "jester",
    [ROLE_SWAPPER] = "swapper",
    [ROLE_GLITCH] = "glitch",
    [ROLE_PHANTOM] = "phantom",
    [ROLE_HYPNOTIST] = "hypnotist",
    [ROLE_REVENGER] = "revenger",
    [ROLE_DRUNK] = "drunk",
    [ROLE_CLOWN] = "clown",
    [ROLE_DEPUTY] = "deputy",
    [ROLE_IMPERSONATOR] = "impersonator",
    [ROLE_BEGGAR] = "beggar",
    [ROLE_OLDMAN] = "oldman",
    [ROLE_MERCENARY] = "mercenary",
    [ROLE_BODYSNATCHER] = "bodysnatcher",
    [ROLE_VETERAN] = "veteran",
    [ROLE_ASSASSIN] = "assassin",
    [ROLE_KILLER] = "killer",
    [ROLE_ZOMBIE] = "zombie",
    [ROLE_VAMPIRE] = "vampire",
    [ROLE_DOCTOR] = "doctor",
    [ROLE_QUACK] = "quack",
    [ROLE_PARASITE] = "parasite",
    [ROLE_TRICKSTER] = "trickster",
    [ROLE_PARAMEDIC] = "paramedic",
    [ROLE_MADSCIENTIST] = "madscientist",
    [ROLE_PALADIN] = "paladin",
    [ROLE_TRACKER] = "tracker",
    [ROLE_MEDIUM] = "medium",
    [ROLE_LOOTGOBLIN] = "lootgoblin",
    [ROLE_TURNCOAT] = "turncoat",
    [ROLE_SAPPER] = "sapper",
    [ROLE_INFORMANT] = "informant",
    [ROLE_MARSHAL] = "marshal",
    [ROLE_INFECTED] = "infected",
    [ROLE_CUPID] = "cupid",
    [ROLE_SHADOW] = "shadow",
    [ROLE_SPONGE] = "sponge",
    [ROLE_ARSONIST] = "arsonist",
    [ROLE_SPY] = "spy",
    [ROLE_HIVEMIND] = "hivemind",
    [ROLE_GUESSER] = "guesser",
    [ROLE_QUARTERMASTER] = "quartermaster",
    [ROLE_VINDICATOR] = "vindicator"
}

ROLE_STRINGS = {
    [ROLE_INNOCENT] = "Innocent",
    [ROLE_TRAITOR] = "Traitor",
    [ROLE_DETECTIVE] = "Detective",
    [ROLE_JESTER] = "Jester",
    [ROLE_SWAPPER] = "Swapper",
    [ROLE_GLITCH] = "Glitch",
    [ROLE_PHANTOM] = "Phantom",
    [ROLE_HYPNOTIST] = "Hypnotist",
    [ROLE_REVENGER] = "Revenger",
    [ROLE_DRUNK] = "Drunk",
    [ROLE_CLOWN] = "Clown",
    [ROLE_DEPUTY] = "Deputy",
    [ROLE_IMPERSONATOR] = "Impersonator",
    [ROLE_BEGGAR] = "Beggar",
    [ROLE_OLDMAN] = "Old Man",
    [ROLE_MERCENARY] = "Mercenary",
    [ROLE_BODYSNATCHER] = "Bodysnatcher",
    [ROLE_VETERAN] = "Veteran",
    [ROLE_ASSASSIN] = "Assassin",
    [ROLE_KILLER] = "Killer",
    [ROLE_ZOMBIE] = "Zombie",
    [ROLE_VAMPIRE] = "Vampire",
    [ROLE_DOCTOR] = "Doctor",
    [ROLE_QUACK] = "Quack",
    [ROLE_PARASITE] = "Parasite",
    [ROLE_TRICKSTER] = "Trickster",
    [ROLE_PARAMEDIC] = "Paramedic",
    [ROLE_MADSCIENTIST] = "Mad Scientist",
    [ROLE_PALADIN] = "Paladin",
    [ROLE_TRACKER] = "Tracker",
    [ROLE_MEDIUM] = "Medium",
    [ROLE_LOOTGOBLIN] = "Loot Goblin",
    [ROLE_TURNCOAT] = "Turncoat",
    [ROLE_SAPPER] = "Sapper",
    [ROLE_INFORMANT] = "Informant",
    [ROLE_MARSHAL] = "Marshal",
    [ROLE_INFECTED] = "Infected",
    [ROLE_CUPID] = "Cupid",
    [ROLE_SHADOW] = "Shadow",
    [ROLE_SPONGE] = "Sponge",
    [ROLE_ARSONIST] = "Arsonist",
    [ROLE_SPY] = "Spy",
    [ROLE_HIVEMIND] = "Hive Mind",
    [ROLE_GUESSER] = "Guesser",
    [ROLE_QUARTERMASTER] = "Quartermaster",
    [ROLE_VINDICATOR] = "Vindicator"
}

ROLE_STRINGS_PLURAL = {
    [ROLE_INNOCENT] = "Innocents",
    [ROLE_TRAITOR] = "Traitors",
    [ROLE_DETECTIVE] = "Detectives",
    [ROLE_JESTER] = "Jesters",
    [ROLE_SWAPPER] = "Swappers",
    [ROLE_GLITCH] = "Glitches",
    [ROLE_PHANTOM] = "Phantoms",
    [ROLE_HYPNOTIST] = "Hypnotists",
    [ROLE_REVENGER] = "Revengers",
    [ROLE_DRUNK] = "Drunks",
    [ROLE_CLOWN] = "Clowns",
    [ROLE_DEPUTY] = "Deputies",
    [ROLE_IMPERSONATOR] = "Impersonators",
    [ROLE_BEGGAR] = "Beggars",
    [ROLE_OLDMAN] = "Old Men",
    [ROLE_MERCENARY] = "Mercenaries",
    [ROLE_BODYSNATCHER] = "Bodysnatchers",
    [ROLE_VETERAN] = "Veterans",
    [ROLE_ASSASSIN] = "Assassins",
    [ROLE_KILLER] = "Killers",
    [ROLE_ZOMBIE] = "Zombies",
    [ROLE_VAMPIRE] = "Vampires",
    [ROLE_DOCTOR] = "Doctors",
    [ROLE_QUACK] = "Quacks",
    [ROLE_PARASITE] = "Parasites",
    [ROLE_TRICKSTER] = "Tricksters",
    [ROLE_PARAMEDIC] = "Paramedics",
    [ROLE_MADSCIENTIST] = "Mad Scientists",
    [ROLE_PALADIN] = "Paladins",
    [ROLE_TRACKER] = "Trackers",
    [ROLE_MEDIUM] = "Mediums",
    [ROLE_LOOTGOBLIN] = "Loot Goblins",
    [ROLE_TURNCOAT] = "Turncoats",
    [ROLE_SAPPER] = "Sappers",
    [ROLE_INFORMANT] = "Informants",
    [ROLE_MARSHAL] = "Marshals",
    [ROLE_INFECTED] = "Infected",
    [ROLE_CUPID] = "Cupids",
    [ROLE_SHADOW] = "Shadows",
    [ROLE_SPONGE] = "Sponges",
    [ROLE_ARSONIST] = "Arsonists",
    [ROLE_SPY] = "Spies",
    [ROLE_HIVEMIND] = "Hive Mind",
    [ROLE_GUESSER] = "Guessers",
    [ROLE_QUARTERMASTER] = "Quartermasters",
    [ROLE_VINDICATOR] = "Vindicators"
}

ROLE_STRINGS_EXT = {
    [ROLE_NONE] = "a hidden role",
    [ROLE_INNOCENT] = "an Innocent",
    [ROLE_TRAITOR] = "a Traitor",
    [ROLE_DETECTIVE] = "a Detective",
    [ROLE_JESTER] = "a Jester",
    [ROLE_SWAPPER] = "a Swapper",
    [ROLE_GLITCH] = "a Glitch",
    [ROLE_PHANTOM] = "a Phantom",
    [ROLE_HYPNOTIST] = "a Hypnotist",
    [ROLE_REVENGER] = "a Revenger",
    [ROLE_DRUNK] = "a Drunk",
    [ROLE_CLOWN] = "a Clown",
    [ROLE_DEPUTY] = "a Deputy",
    [ROLE_IMPERSONATOR] = "an Impersonator",
    [ROLE_BEGGAR] = "a Beggar",
    [ROLE_OLDMAN] = "an Old Man",
    [ROLE_MERCENARY] = "a Mercenary",
    [ROLE_BODYSNATCHER] = "a Bodysnatcher",
    [ROLE_VETERAN] = "a Veteran",
    [ROLE_ASSASSIN] = "an Assassin",
    [ROLE_KILLER] = "a Killer",
    [ROLE_ZOMBIE] = "a Zombie",
    [ROLE_VAMPIRE] = "a Vampire",
    [ROLE_DOCTOR] = "a Doctor",
    [ROLE_QUACK] = "a Quack",
    [ROLE_PARASITE] = "a Parasite",
    [ROLE_TRICKSTER] = "a Trickster",
    [ROLE_PARAMEDIC] = "a Paramedic",
    [ROLE_MADSCIENTIST] = "a Mad Scientist",
    [ROLE_PALADIN] = "a Paladin",
    [ROLE_TRACKER] = "a Tracker",
    [ROLE_MEDIUM] = "a Medium",
    [ROLE_LOOTGOBLIN] = "a Loot Goblin",
    [ROLE_TURNCOAT] = "a Turncoat",
    [ROLE_SAPPER] = "a Sapper",
    [ROLE_INFORMANT] = "an Informant",
    [ROLE_MARSHAL] = "a Marshal",
    [ROLE_INFECTED] = "an Infected",
    [ROLE_CUPID] = "a Cupid",
    [ROLE_SHADOW] = "a Shadow",
    [ROLE_SPONGE] = "a Sponge",
    [ROLE_ARSONIST] = "an Arsonist",
    [ROLE_SPY] = "a Spy",
    [ROLE_HIVEMIND] = "the Hive Mind",
    [ROLE_GUESSER] = "a Guesser",
    [ROLE_QUARTERMASTER] = "a Quartermaster",
    [ROLE_VINDICATOR] = "a Vindicator"
}

ROLE_STRINGS_SHORT = {
    [ROLE_NONE] = "nil",
    [ROLE_INNOCENT] = "inn",
    [ROLE_TRAITOR] = "tra",
    [ROLE_DETECTIVE] = "det",
    [ROLE_JESTER] = "jes",
    [ROLE_SWAPPER] = "swa",
    [ROLE_GLITCH] = "gli",
    [ROLE_PHANTOM] = "pha",
    [ROLE_HYPNOTIST] = "hyp",
    [ROLE_REVENGER] = "rev",
    [ROLE_DRUNK] = "dru",
    [ROLE_CLOWN] = "clo",
    [ROLE_DEPUTY] = "dep",
    [ROLE_IMPERSONATOR] = "imp",
    [ROLE_BEGGAR] = "beg",
    [ROLE_OLDMAN] = "old",
    [ROLE_MERCENARY] = "mer",
    [ROLE_BODYSNATCHER] = "bod",
    [ROLE_VETERAN] = "vet",
    [ROLE_ASSASSIN] = "asn",
    [ROLE_KILLER] = "kil",
    [ROLE_ZOMBIE] = "zom",
    [ROLE_VAMPIRE] = "vam",
    [ROLE_DOCTOR] = "doc",
    [ROLE_QUACK] = "qua",
    [ROLE_PARASITE] = "par",
    [ROLE_TRICKSTER] = "tri",
    [ROLE_PARAMEDIC] = "med",
    [ROLE_MADSCIENTIST] = "mad",
    [ROLE_PALADIN] = "pal",
    [ROLE_TRACKER] = "trk",
    [ROLE_MEDIUM] = "mdm",
    [ROLE_LOOTGOBLIN] = "gob",
    [ROLE_TURNCOAT] = "tur",
    [ROLE_SAPPER] = "sap",
    [ROLE_INFORMANT] = "inf",
    [ROLE_MARSHAL] = "mhl",
    [ROLE_INFECTED] = "ifd",
    [ROLE_CUPID] = "cup",
    [ROLE_SHADOW] = "sha",
    [ROLE_SPONGE] = "spn",
    [ROLE_ARSONIST] = "ars",
    [ROLE_SPY] = "spy",
    [ROLE_HIVEMIND] = "hmd",
    [ROLE_GUESSER] = "gue",
    [ROLE_QUARTERMASTER] = "qmr",
    [ROLE_VINDICATOR] = "vin"
}

function StartsWithVowel(word)
    local firstletter = StringSub(word, 1, 1)
    return firstletter == "a" or
        firstletter == "e" or
        firstletter == "i" or
        firstletter == "o" or
        firstletter == "u"
end

function UpdateRoleStrings()
    for role = 0, ROLE_MAX do
        local name = GetConVar("ttt_" .. ROLE_STRINGS_RAW[role] .. "_name"):GetString()
        if #name > 0 then
            ROLE_STRINGS[role] = name

            local plural = GetConVar("ttt_" .. ROLE_STRINGS_RAW[role] .. "_name_plural"):GetString()
            if #plural == 0 then -- Fallback if no plural is given. Does NOT handle all cases properly
                local lastChar = StringLower(StringSub(name, #name, #name))
                if lastChar == "s" then
                    ROLE_STRINGS_PLURAL[role] = name .. "es"
                elseif lastChar == "y" then
                    ROLE_STRINGS_PLURAL[role] = StringSub(name, 1, #name - 1) .. "ies"
                else
                    ROLE_STRINGS_PLURAL[role] = name .. "s"
                end
            else
                ROLE_STRINGS_PLURAL[role] = plural
            end

            local article = GetConVar("ttt_" .. ROLE_STRINGS_RAW[role] .. "_name_article"):GetString()
            if #article == 0 then -- Fallback if no article is given. Does NOT handle all cases properly
                if StartsWithVowel(name) then
                    ROLE_STRINGS_EXT[role] = "an " .. name
                else
                    ROLE_STRINGS_EXT[role] = "a " .. name
                end
            else
                ROLE_STRINGS_EXT[role] = article .. " " .. name
            end
        end
    end
end
if CLIENT then net.Receive("TTT_UpdateRoleNames", UpdateRoleStrings) end

ROLE_TEAM_INNOCENT = 0
ROLE_TEAM_TRAITOR = 1
ROLE_TEAM_JESTER = 2
ROLE_TEAM_INDEPENDENT = 3
ROLE_TEAM_MONSTER = 4
ROLE_TEAM_DETECTIVE = 5

ROLE_TEAMS_WITH_SHOP = {}
AddRoleAssociations(ROLE_TEAMS_WITH_SHOP, {ROLE_TEAM_TRAITOR, ROLE_TEAM_INDEPENDENT, ROLE_TEAM_MONSTER, ROLE_TEAM_DETECTIVE})

-- Role icon caching
local function CacheRoleIcon(tbl, role_str, typ, ext, cache_key)
    -- Use the role string as the cache key and file name if a specific cache key is not provided
    if not cache_key then
        cache_key = role_str
    end
    local file_path = StringFormat("vgui/ttt/roles/%s/%s_%s.%s", role_str, typ, cache_key, ext)
    if not FileExists(StringFormat("materials/%s", file_path), "GAME") then
        file_path = StringFormat("vgui/ttt/%s_%s.%s", typ, cache_key, ext)
    end
    tbl[cache_key] = Material(file_path)
end

ROLE_TAB_ICON_MATERIALS = {}
local function CacheRoleTabIcon(role_str)
    CacheRoleIcon(ROLE_TAB_ICON_MATERIALS, role_str, "tab", "png")
end

ROLE_SPRITE_ICON_MATERIALS = {}
local function CacheRoleSpriteIcon(role_str)
    CacheRoleIcon(ROLE_SPRITE_ICON_MATERIALS, role_str, "sprite", "vmt")
    CacheRoleIcon(ROLE_SPRITE_ICON_MATERIALS, role_str, "sprite", "vmt", StringFormat("%s_noz", role_str))
end

local function CacheRoleIcons(role_str)
    CacheRoleTabIcon(role_str)
    CacheRoleSpriteIcon(role_str)
end

for _, v in pairs(ROLE_STRINGS_SHORT) do
    CacheRoleIcons(v)
end

ROLE_DATA_EXTERNAL = {}

-- Role strings
ROLE_TRANSLATIONS = {}

-- Role features
ROLE_CONVARS = {}
ROLE_LOADOUT_ITEMS = {}
ROLE_MAX_HEALTH = {}
ROLE_SELECTION_PREDICATE = {}
ROLE_SHOP_ITEMS = {}
ROLE_STARTING_CREDITS = {}
ROLE_STARTING_HEALTH = {}

-- Optional features
ROLE_CAN_SEE_C4 = {}
ROLE_CAN_SEE_JESTERS = {}
ROLE_CAN_SEE_MIA = {}
ROLE_HAS_PASSIVE_WIN = {}
ROLE_HAS_SHOP_MODE = {}
ROLE_HAS_SHOP_SYNC = {}
ROLE_SHOP_SYNC_ROLES = {}
ROLE_SHOULD_NOT_DROWN = {}
ROLE_BLOCK_SPAWN_CONVARS = {}
ROLE_BLOCK_HEALTH_CONVARS = {}
ROLE_BLOCK_SHOP_CONVARS = {}

-- Player functions
ROLE_IS_ACTIVE = {}
ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN = {}
ROLE_IS_TARGETID_OVERRIDDEN = {}
ROLE_IS_TARGET_HIGHLIGHTED = {}
ROLE_MOVE_ROLE_STATE = {}
ROLE_ON_ROLE_ASSIGNED = {}
ROLE_SHOULD_ACT_LIKE_JESTER = {}
ROLE_SHOULD_REVEAL_ROLE_WHEN_ACTIVE = {}
ROLE_SHOULD_SHOW_SPECTATOR_HUD = {}
ROLE_VICTIM_CHANGING_ROLE = {}
ROLETEAM_IS_TARGET_HIGHLIGHTED = {}

ROLE_CONVAR_TYPE_NUM = 0
ROLE_CONVAR_TYPE_BOOL = 1
ROLE_CONVAR_TYPE_TEXT = 2
ROLE_CONVAR_TYPE_DROPDOWN = 3

function RegisterRole(tbl)
    -- Unsigned 8-bit max
    local maximum_role_count = (2^7) - 1
    if ROLE_MAX == maximum_role_count then
        error("Too many roles (more than " .. maximum_role_count .. ") have been defined.")
        return
    end

    if table.HasValue(ROLE_STRINGS_RAW, tbl.nameraw) then
        error("Attempting to define role with a duplicate raw name value: " .. tbl.nameraw)
        return
    end

    if table.HasValue(ROLE_STRINGS_SHORT, tbl.nameshort) then
        error("Attempting to define role with a duplicate short name value: " .. tbl.nameshort)
        return
    end

    local roleID = ROLE_MAX + 1
    _G["ROLE_" .. StringUpper(tbl.nameraw)] = roleID
    ROLE_MAX = roleID

    ROLE_DATA_EXTERNAL[roleID] = tbl

    ROLE_STRINGS_RAW[roleID] = tbl.nameraw
    ROLE_STRINGS[roleID] = tbl.name
    ROLE_STRINGS_PLURAL[roleID] = tbl.nameplural
    ROLE_STRINGS_EXT[roleID] = tbl.nameext
    ROLE_STRINGS_SHORT[roleID] = tbl.nameshort

    CacheRoleIcons(tbl.nameshort)

    if tbl.team == ROLE_TEAM_INNOCENT then
        AddRoleAssociations(INNOCENT_ROLES, {roleID})
    elseif tbl.team == ROLE_TEAM_TRAITOR then
        AddRoleAssociations(TRAITOR_ROLES, {roleID})
    elseif tbl.team == ROLE_TEAM_JESTER then
        AddRoleAssociations(JESTER_ROLES, {roleID})
    elseif tbl.team == ROLE_TEAM_INDEPENDENT then
        AddRoleAssociations(INDEPENDENT_ROLES, {roleID})
    elseif tbl.team == ROLE_TEAM_MONSTER then
        AddRoleAssociations(MONSTER_ROLES, {roleID})
    elseif tbl.team == ROLE_TEAM_DETECTIVE then
        AddRoleAssociations(DETECTIVE_ROLES, {roleID})
        AddRoleAssociations(INNOCENT_ROLES, {roleID})
    end

    -- Allow roles to have translations automatically added for them
    if type(tbl.translations) == "table" then
        ROLE_TRANSLATIONS[roleID] = tbl.translations
    else
        ROLE_TRANSLATIONS[roleID] = {}
    end

    -- Ensure that at least english is present
    if not ROLE_TRANSLATIONS[roleID]["english"] then
        ROLE_TRANSLATIONS[roleID]["english"] = {}
    end

    -- Create the role description translation automatically
    ROLE_TRANSLATIONS[roleID]["english"]["info_popup_" .. tbl.nameraw] = tbl.desc

    if type(tbl.selectionpredicate) == "function" then
        ROLE_SELECTION_PREDICATE[roleID] = tbl.selectionpredicate
    end

    -- Role features
    if type(tbl.startingcredits) == "number" then
        ROLE_STARTING_CREDITS[roleID] = tbl.startingcredits
    end

    if type(tbl.startinghealth) == "number" then
        ROLE_STARTING_HEALTH[roleID] = tbl.startinghealth
    end

    if type(tbl.maxhealth) == "number" then
        ROLE_MAX_HEALTH[roleID] = tbl.maxhealth
    end

    -- Optional Features
    if type(tbl.canlootcredits) == "boolean" then
        CAN_LOOT_CREDITS_ROLES[roleID] = tbl.canlootcredits
    end

    if type(tbl.canseec4) == "boolean" then
        ROLE_CAN_SEE_C4[roleID] = tbl.canseec4
    end

    if type(tbl.canseejesters) == "boolean" then
        ROLE_CAN_SEE_JESTERS[roleID] = tbl.canseejesters
    end

    if type(tbl.canseemia) == "boolean" then
        ROLE_CAN_SEE_MIA[roleID] = tbl.canseemia
    end

    if type(tbl.canusetraitorbuttons) == "boolean" then
        TRAITOR_BUTTON_ROLES[roleID] = tbl.canusetraitorbuttons
    end

    if type(tbl.haspassivewin) == "boolean" then
        ROLE_HAS_PASSIVE_WIN[roleID] = tbl.haspassivewin
    end

    if type(tbl.hasshopmode) == "boolean" then
        ROLE_HAS_SHOP_MODE[roleID] = tbl.hasshopmode
    end

    if type(tbl.hasshopsync) == "boolean" then
        ROLE_HAS_SHOP_SYNC[roleID] = tbl.hasshopsync
    end

    if type(tbl.isdetectivelike) == "boolean" then
        DETECTIVE_LIKE_ROLES[roleID] = tbl.isdetectivelike
    end

    if type(tbl.shopsyncroles) == "table" then
        ROLE_SHOP_SYNC_ROLES[roleID] = tbl.shopsyncroles
    end

    if type(tbl.shoulddelayshop) == "boolean" then
        DELAYED_SHOP_ROLES[roleID] = tbl.shoulddelayshop
    end

    if type(tbl.shouldnotdrown) == "boolean" then
        ROLE_SHOULD_NOT_DROWN[roleID] = tbl.shouldnotdrown
    end

    if type(tbl.blockspawnconvars) == "boolean" then
        ROLE_BLOCK_SPAWN_CONVARS[roleID] = tbl.blockspawnconvars
    end

    if type(tbl.blockhealthconvars) == "boolean" then
        ROLE_BLOCK_HEALTH_CONVARS[roleID] = tbl.blockhealthconvars
    end

    if type(tbl.blockshopconvars) == "boolean" then
        ROLE_BLOCK_SHOP_CONVARS[roleID] = tbl.blockshopconvars
    end

    -- Equipment
    -- Make sure teams that normally have shops are added to the shop list, even if they don't have things in their shop by default
    -- This allows the "sync" and "mode" convars to be created
    if tbl.shop or ROLE_TEAMS_WITH_SHOP[tbl.team] then
        ROLE_SHOP_ITEMS[roleID] = tbl.shop
        AddRoleAssociations(SHOP_ROLES, {roleID})
    end

    if tbl.loadout then
        ROLE_LOADOUT_ITEMS[roleID] = tbl.loadout
    end

    -- plymeta Functions
    if type(tbl.isactive) == "function" then
        ROLE_IS_ACTIVE[roleID] = tbl.isactive
    end

    if type(tbl.isscoreboardinfooverridden) == "function" then
        ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[roleID] = tbl.isscoreboardinfooverridden
    end

    if type(tbl.istargetidoverridden) == "function" then
        ROLE_IS_TARGETID_OVERRIDDEN[roleID] = tbl.istargetidoverridden
    end

    if type(tbl.istargethighlighted) == "function" then
        ROLE_IS_TARGET_HIGHLIGHTED[roleID] = tbl.istargethighlighted
    end

    if type(tbl.moverolestate) == "function" then
        ROLE_MOVE_ROLE_STATE[roleID] = tbl.moverolestate
    end

    if type(tbl.onroleassigned) == "function" then
        ROLE_ON_ROLE_ASSIGNED[roleID] = tbl.onroleassigned
    end

    if type(tbl.shouldactlikejester) == "function" then
        ROLE_SHOULD_ACT_LIKE_JESTER[roleID] = tbl.shouldactlikejester
    end

    if type(tbl.shouldrevealrolewhenactive) == "function" then
        ROLE_SHOULD_REVEAL_ROLE_WHEN_ACTIVE[roleID] = tbl.shouldrevealrolewhenactive
    end

    if type(tbl.shouldshowspectatorhud) == "function" then
        ROLE_SHOULD_SHOW_SPECTATOR_HUD[roleID] = tbl.shouldshowspectatorhud
    end

    if type(tbl.victimchangingrole) == "function" then
        ROLE_VICTIM_CHANGING_ROLE[roleID] = tbl.victimchangingrole
    end

    -- List of objects that describe convars for ULX support, in the following format:
    -- {
    --     cvar = "ttt_test_slider",    -- The name of the convar
    --     decimal = 2,                 -- How many decimal places this number will use
    --     type = ROLE_CONVAR_TYPE_NUM  -- The type of convar (will be used to determine the control, in this case a number slider)
    -- },
    -- {
    --     cvar = "ttt_test_checkbox",  -- The name of the convar
    --     type = ROLE_CONVAR_TYPE_BOOL -- The type of convar (will be used to determine the control, in this case a checkbox)
    -- },
    -- {
    --     cvar = "ttt_test_textbox",   -- The name of the convar
    --     type = ROLE_CONVAR_TYPE_TEXT -- The type of convar (will be used to determine the control, in this case a textbox)
    -- }
    if tbl.convars then
        ROLE_CONVARS[roleID] = tbl.convars
    end

    hook.Call("TTTRoleRegistered", nil, roleID)
end

local function AddRoleFiles(root)
    local rootfiles, dirs = FileFind(root .. "*", "LUA")
    for _, dir in ipairs(dirs) do
        local clientFiles = {}
        local sharedFiles = {}
        local serverFiles = {}
        -- Partition the files by location so we can load shared first
        local files, _ = FileFind(root .. dir .. "/*.lua", "LUA")
        for _, fil in ipairs(files) do
            if StringFind(fil, "cl_") then
                table.insert(clientFiles, fil)
            elseif fil == "shared.lua" or StringFind(fil, "sh_") then
                table.insert(sharedFiles, fil)
            else
                table.insert(serverFiles, fil)
            end
        end

        -- Process all the shared files first
        for _, fil in ipairs(sharedFiles) do
            -- Send shared files to clients
            if SERVER then
                AddCSLuaFile(root .. dir .. "/" .. fil)
            end
            -- Include all shared files
            include(root .. dir .. "/" .. fil)
        end

        if SERVER then
            -- Send client files to clients
            for _, fil in ipairs(clientFiles) do
                AddCSLuaFile(root .. dir .. "/" .. fil)
            end
            -- Include server files
            for _, fil in ipairs(serverFiles) do
                include(root .. dir .. "/" .. fil)
            end
        elseif CLIENT then
            -- Include client files
            for _, fil in ipairs(clientFiles) do
                include(root .. dir .. "/" .. fil)
            end
        end
    end

    -- Include and send client any files using the single file method
    for _, fil in ipairs(rootfiles) do
        if string.GetExtensionFromFilename(fil) == "lua" then
            if SERVER then AddCSLuaFile(root .. fil) end
            include(root .. fil)
        end
    end
end
AddRoleFiles("terrortown/gamemode/roles/") -- Internal roles
AddRoleFiles("customroles/") -- External roles
AddRoleFiles("rolemodifications/") -- Role modifications
hook.Call("TTTRolesLoaded", nil)

local function GetRoleFromStackTrace()
    local role
    local level = 2
    while true do
        local info = debug.getinfo(level, "S")
        if not info then break end

        if info.what ~= "C" then
            -- Get the file path
            local source = info.short_src
            -- Extract the file name from the path and drop the extension
            local role_name = StringLower(string.StripExtension(string.GetFileFromFilename(source)))

            -- Find the role whose raw string matches the file name
            for r, str in pairs(ROLE_STRINGS_RAW) do
                if StringLower(str) == role_name then
                    role = r
                    break
                end
            end

            -- We found a role, no need to continue
            if role then break end
        end

        level = level + 1
    end

    return role
end

-- Game event log defs
EVENT_KILL = 1
EVENT_SPAWN = 2
EVENT_GAME = 3
EVENT_FINISH = 4
EVENT_SELECTED = 5
EVENT_BODYFOUND = 6
EVENT_C4PLANT = 7
EVENT_C4EXPLODE = 8
EVENT_CREDITFOUND = 9
EVENT_C4DISARM = 10
EVENT_HYPNOTISED = 11
EVENT_DEFIBRILLATED = 12
EVENT_DISCONNECTED = 13
EVENT_ROLECHANGE = 14
EVENT_SWAPPER = 15
EVENT_PROMOTION = 16
EVENT_CLOWNACTIVE = 17
EVENT_DRUNKSOBER = 18
EVENT_HAUNT = 19
EVENT_BODYSNATCH = 20
EVENT_LOG = 21
EVENT_ZOMBIFIED = 22
EVENT_VAMPIFIED = 23
EVENT_VAMPPRIME_DEATH = 24
EVENT_BEGGARCONVERTED = 25
EVENT_BEGGARKILLED = 26
EVENT_INFECT = 27
EVENT_BODYSNATCHERKILLED = 28
EVENT_TURNCOATCHANGED = 29
EVENT_DEPUTIZED = 30
EVENT_INFECTEDSUCCUMBED = 31
EVENT_CUPIDPAIRED = 32
EVENT_ARSONISTIGNITED = 33
EVENT_GUESSERCORRECT = 34
EVENT_GUESSERINCORRECT = 35
EVENT_VINDICATORACTIVE = 36
EVENT_VINDICATORSUCCESS = 37
EVENT_VINDICATORFAIL = 38

EVENT_MAX = EVENT_MAX or 38
EVENTS_BY_ROLE = EVENTS_BY_ROLE or {}

if SERVER then
    util.AddNetworkString("TTT_SyncEventIDs")

    function GenerateNewEventID(role)
        if not role or role < ROLE_NONE or role > ROLE_MAX then
            -- Print message telling the server owners that the role dev needs to update
            ErrorNoHaltWithStack("WARNING: Role is missing 'role' parameter when generating unique event ID. Contact developer of role and reference: GenerateNewEventID\n")
            role = GetRoleFromStackTrace()
        end

        EVENT_MAX = EVENT_MAX + 1

        -- Don't assign this event ID to a role we haven't found
        if role and role > ROLE_NONE and role <= ROLE_MAX then
            EVENTS_BY_ROLE[role] = EVENT_MAX
        end

        return EVENT_MAX
    end

    -- Sync the Event IDs to all clients
    hook.Add("TTTPrepareRound", "EventID_TTTPrepareRound", function()
        net.Start("TTT_SyncEventIDs")
        net.WriteTable(EVENTS_BY_ROLE)
        net.WriteUInt(EVENT_MAX, 16)
        net.Broadcast()
    end)
end
if CLIENT then
    net.Receive("TTT_SyncEventIDs", function()
        EVENTS_BY_ROLE = net.ReadTable()
        EVENT_MAX = net.ReadUInt(16)

        CallHook("TTTSyncEventIDs", nil)
    end)
end

WIN_NONE = 1
WIN_TRAITOR = 2
WIN_INNOCENT = 3
WIN_TIMELIMIT = 4
WIN_JESTER = 5
WIN_CLOWN = 6
WIN_OLDMAN = 7
WIN_KILLER = 8
WIN_ZOMBIE = 9
WIN_MONSTER = 10
WIN_VAMPIRE = 11
WIN_LOOTGOBLIN = 12
WIN_CUPID = 13
WIN_SHADOW = 14
WIN_SPONGE = 15
WIN_ARSONIST = 16
WIN_HIVEMIND = 17
WIN_VINDICATOR = 18

WIN_MAX = WIN_MAX or 18
WINS_BY_ROLE = WINS_BY_ROLE or {}

if SERVER then
    util.AddNetworkString("TTT_SyncWinIDs")

    function GenerateNewWinID(role)
        if not role or role < ROLE_NONE or role > ROLE_MAX then
            -- Print message telling the server owners that the role dev needs to update
            ErrorNoHaltWithStack("WARNING: Role is missing 'role' parameter when generating unique win ID. Contact developer of role and reference: GenerateNewWinID\n")
            role = GetRoleFromStackTrace()
        end

        WIN_MAX = WIN_MAX + 1

        -- Don't assign this win ID to a role we haven't found
        if role and role > ROLE_NONE and role <= ROLE_MAX then
            WINS_BY_ROLE[role] = WIN_MAX
        end

        return WIN_MAX
    end

    -- Sync the Event IDs to all clients
    hook.Add("TTTPrepareRound", "WinID_TTTPrepareRound", function()
        net.Start("TTT_SyncWinIDs")
        net.WriteTable(WINS_BY_ROLE)
        net.WriteUInt(WIN_MAX, 16)
        net.Broadcast()
    end)
end
if CLIENT then
    net.Receive("TTT_SyncWinIDs", function()
        WINS_BY_ROLE = net.ReadTable()
        WIN_MAX = net.ReadUInt(16)

        CallHook("TTTSyncWinIDs", nil)
    end)
end

-- Weapon categories, you can only carry one of each
WEAPON_NONE = 0
WEAPON_MELEE = 1
WEAPON_PISTOL = 2
WEAPON_HEAVY = 3
WEAPON_NADE = 4
WEAPON_CARRY = 5
WEAPON_EQUIP1 = 6
WEAPON_EQUIP2 = 7
WEAPON_ROLE = 8

WEAPON_EQUIP = WEAPON_EQUIP1
WEAPON_UNARMED = -1

WEAPON_CATEGORY_ROLE = "CR-RoleWeapon"

-- Kill types discerned by last words
KILL_NORMAL = 0
KILL_SUICIDE = 1
KILL_FALL = 2
KILL_BURN = 3

-- Entity types a crowbar might open
OPEN_NO = 0
OPEN_DOOR = 1
OPEN_ROT = 2
OPEN_BUT = 3
OPEN_NOTOGGLE = 4 --movelinear

-- Mute types
MUTE_NONE = 0
MUTE_TERROR = 1
MUTE_ALL = 2
MUTE_SPEC = 1002

-- Jester notify modes
JESTER_NOTIFY_NONE = 0
JESTER_NOTIFY_DETECTIVE_AND_TRAITOR = 1
JESTER_NOTIFY_TRAITOR = 2
JESTER_NOTIFY_DETECTIVE = 3
JESTER_NOTIFY_EVERYONE = 4

-- Role reveal announcement modes
ANNOUNCE_REVEAL_NONE = 0
ANNOUNCE_REVEAL_ALL = 1
ANNOUNCE_REVEAL_TRAITORS = 2
ANNOUNCE_REVEAL_INNOCENTS = 3

-- Special detective hide modes
SPECIAL_DETECTIVE_HIDE_NONE = 0
SPECIAL_DETECTIVE_HIDE_FOR_ALL = 1
SPECIAL_DETECTIVE_HIDE_FOR_OTHERS = 2

-- Misc. role constants
UNITS_PER_METER = 52.49
UNITS_PER_FIVE_METERS = UNITS_PER_METER * 5

-- Message queue modes
MSG_PRINTBOTH = 1
MSG_PRINTTALK = 3 -- Keep this the same value as HUD_PRINTTALK just in case
MSG_PRINTCENTER = 4 -- Keep this the same value as HUD_PRINTCENTER just in case

-- Corpse stuff
CORPSE_ICON_TYPES = {
    "c4",
    "dmg",
    "dtime",
    "equipment",
    "head",
    "kills",
    "lastid",
    "nick",
    "role",
    "team",
    "stime",
    "wep",
    "words"
}

COLOR_WHITE = Color(255, 255, 255, 255)
COLOR_BLACK = Color(0, 0, 0, 255)
COLOR_GREEN = Color(0, 255, 0, 255)
COLOR_DGREEN = Color(0, 100, 0, 255)
COLOR_RED = Color(255, 0, 0, 255)
COLOR_YELLOW = Color(200, 200, 0, 255)
COLOR_LGRAY = Color(200, 200, 200, 255)
COLOR_LGREY = COLOR_LGRAY
COLOR_GRAY = Color(100, 100, 100, 255)
COLOR_GREY = COLOR_GRAY
COLOR_DGRAY = Color(75, 75, 75, 255)
COLOR_DGREY = COLOR_DGRAY
COLOR_BLUE = Color(0, 0, 255, 255)
COLOR_NAVY = Color(0, 0, 100, 255)
COLOR_PINK = Color(255, 0, 255, 255)
COLOR_ORANGE = Color(250, 100, 0, 255)
COLOR_OLIVE = Color(100, 100, 0, 255)

include("util.lua")
include("lang_shd.lua") -- uses some of util
include("equip_items_shd.lua")

function DetectiveMode() return GetGlobalBool("ttt_detective", false) end
function HasteMode() return GetGlobalBool("ttt_haste", false) end

-- Create teams
TEAM_TERROR = 1
TEAM_SPEC = TEAM_SPECTATOR

function GM:CreateTeams()
    team.SetUp(TEAM_TERROR, "Terrorists", Color(0, 200, 0, 255), false)
    team.SetUp(TEAM_SPEC, "Spectators", Color(200, 200, 0, 255), true)

    -- Not that we use this, but feels good
    team.SetSpawnPoint(TEAM_TERROR, "info_player_deathmatch")
    team.SetSpawnPoint(TEAM_SPEC, "info_player_deathmatch")
end

-- Everyone's model
local ttt_playermodels = {
    Model("models/player/phoenix.mdl"),
    Model("models/player/arctic.mdl"),
    Model("models/player/guerilla.mdl"),
    Model("models/player/leet.mdl")
};

function GetRandomPlayerModel()
    return table.Random(ttt_playermodels)
end

local ttt_playercolors = {
    all = {
        COLOR_WHITE,
        COLOR_BLACK,
        COLOR_GREEN,
        COLOR_DGREEN,
        COLOR_RED,
        COLOR_YELLOW,
        COLOR_LGRAY,
        COLOR_BLUE,
        COLOR_NAVY,
        COLOR_PINK,
        COLOR_OLIVE,
        COLOR_ORANGE
    },

    serious = {
        COLOR_WHITE,
        COLOR_BLACK,
        COLOR_NAVY,
        COLOR_LGRAY,
        COLOR_DGREEN,
        COLOR_OLIVE
    }
};

CreateConVar("ttt_playercolor_mode", "1")
function GM:TTTPlayerColor(model)
    local mode = GetConVar("ttt_playercolor_mode"):GetInt()
    if mode == 1 then
        return table.Random(ttt_playercolors.serious)
    elseif mode == 2 then
        return table.Random(ttt_playercolors.all)
    elseif mode == 3 then
        -- Full randomness
        return Color(math.random(0, 255), math.random(0, 255), math.random(0, 255))
    end
    -- No coloring
    return COLOR_WHITE
end

function GM:PlayerFootstep(ply, pos, foot, sound, volume, rf)
    if not IsValid(ply) or ply:IsSpec() or not ply:Alive() then return true end

    -- Kill footsteps on player and client
    if ply:Crouching() or ply:GetMaxSpeed() < 150 then
        -- do not play anything, just prevent normal sounds from playing
        return true
    end

    if CallHook("TTTBlockPlayerFootstepSound", nil, ply) then
        return true
    end
end

-- Predicted move speed changes
function GM:Move(ply, mv)
    if ply:IsTerror() then
        local basemul = 1
        local slowed = false
        -- Slow down ironsighters
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep.GetIronsights and wep:GetIronsights() then
            basemul = 120 / 220
            slowed = true
        end
        local mul = RunHook("TTTPlayerSpeedModifier", ply, slowed, mv) or 1
        mul = basemul * mul
        mv:SetMaxClientSpeed(mv:GetMaxClientSpeed() * mul)
        mv:SetMaxSpeed(mv:GetMaxSpeed() * mul)
    end
end

function UpdateRoleWeaponState()
    CallHook("TTTUpdateRoleState", nil)

    if SERVER then
        net.Start("TTT_ResetBuyableWeaponsCache")
        net.Broadcast()
    end
end

function UpdateRoleState()
    local disable_looting = GetConVar("ttt_detectives_disable_looting"):GetBool()
    local special_detectives_armor_loadout = GetConVar("ttt_special_detectives_armor_loadout"):GetBool()
    for r, e in pairs(DETECTIVE_ROLES) do
        if e then
            -- Don't overwrite custom roles that have this specifically disabled
            if ROLE_DATA_EXTERNAL[r] and ROLE_DATA_EXTERNAL[r].canlootcredits ~= false then
                CAN_LOOT_CREDITS_ROLES[r] = not disable_looting
            end

            -- If this isn't a regular detective, update the armor equipment loadout status to match the setting
            if not DEFAULT_ROLES[r] then
                for _, i in ipairs(EquipmentItems[r]) do
                    if i.id == EQUIP_ARMOR then
                        i.loadout = special_detectives_armor_loadout
                        break
                    end
                end
            end
        end
    end

    -- Update which weapons are available based on role state
    UpdateRoleWeaponState()

    -- Update role colors to make sure team changes have taken effect
    UpdateRoleColours()

    -- Enable the shop for all roles if configured to do so
    if GetConVar("ttt_shop_for_all"):GetBool() then
        for role = 0, ROLE_MAX do
            if not SHOP_ROLES[role] then
                SHOP_ROLES[role] = true
            end
        end
    end
end

function GetWinningMonsterRole()
    local monsters = GetTeamRoles(MONSTER_ROLES)
    local monster = monsters[1]
    -- If Zombies or Vampires just won on a team by themselves, use their role as the label
    if #monsters == 1 and (monster == ROLE_ZOMBIE or monster == ROLE_VAMPIRE) then
        return monster
    end
    -- Otherwise just use the "Monsters" team name
    return nil
end

function ShouldShowTraitorExtraInfo()
    -- Don't display Parasite and Assassin information if there is a glitch that is distorting the role information
    -- If the glitch mode is "Show as Special Traitor" then we don't want to show this because it reveals which of the traitors is real (because this doesn't show for glitches)
    -- If the glitch mode is "Hide Special Traitor Roles" then we don't want to show anything that reveals what role a traitor really is
    local glitchMode = GetConVar("ttt_glitch_mode"):GetInt()
    local hasGlitch = GetGlobalBool("ttt_glitch_round", false)
    return not hasGlitch or glitchMode == GLITCH_SHOW_AS_TRAITOR
end

if SERVER then
    function SetRoleStartingHealth(ply)
        if not IsValid(ply) or not ply:Alive() or ply:IsSpec() then return end
        local role = ply:GetRole()
        if role <= ROLE_NONE or role > ROLE_MAX then return end

        local health = cvars.Number("ttt_" .. ROLE_STRINGS_RAW[role] .. "_starting_health", 100)
        if health <= 0 then return end
        ply:SetHealth(health)
    end

    function SetRoleMaxHealth(ply)
        if not IsValid(ply) or not ply:Alive() or ply:IsSpec() then return end
        local role = ply:GetRole()
        if role <= ROLE_NONE or role > ROLE_MAX then return end

        local maxhealth = cvars.Number("ttt_" .. ROLE_STRINGS_RAW[role] .. "_max_health", 100)
        if maxhealth <= 0 then return end
        ply:SetMaxHealth(maxhealth)
    end

    function SetRoleHealth(ply)
        SetRoleMaxHealth(ply)
        SetRoleStartingHealth(ply)
    end

    local function ShouldShowJesterNotification(target, mode)
        -- 1 - Only notify Traitors and Detective-likes
        -- 2 - Only notify Traitors
        -- 3 - Only notify Detective-likes
        -- 4 - Notify everyone
        -- Otherwise - Don't notify anyone
        if mode == JESTER_NOTIFY_DETECTIVE_AND_TRAITOR then
            return target:IsDetectiveLike() or target:IsTraitorTeam()
        elseif mode == JESTER_NOTIFY_TRAITOR then
            return target:IsTraitorTeam()
        elseif mode == JESTER_NOTIFY_DETECTIVE then
            return target:IsDetectiveLike()
        elseif mode == JESTER_NOTIFY_EVERYONE then
            return true
        end
        return false
    end

    function JesterTeamKilledNotification(attacker, victim, getkillstring, shouldshow)
        local role = victim:GetRole()
        local cvar_role = ROLE_STRINGS_RAW[role]
        local mode = GetConVar("ttt_" .. cvar_role .. "_notify_mode"):GetInt()
        local play_sound = GetConVar("ttt_" .. cvar_role .. "_notify_sound"):GetBool()
        local show_confetti = GetConVar("ttt_" .. cvar_role .. "_notify_confetti"):GetBool()
        for _, ply in pairs(GetAllPlayers()) do
            if ply == attacker then
                local role_string = ROLE_STRINGS[role]
                ply:QueueMessage(MSG_PRINTCENTER, "You killed the " .. role_string .. "!")
            elseif (shouldshow == nil or shouldshow(ply)) and ShouldShowJesterNotification(ply, mode) then
                ply:QueueMessage(MSG_PRINTCENTER, getkillstring(ply))
            end

            if play_sound or show_confetti then
                net.Start("TTT_JesterDeathCelebration")
                net.WriteEntity(victim)
                net.WriteBool(play_sound)
                net.WriteBool(show_confetti)
                net.Send(ply)
            end
        end
    end
end

if CLIENT then
    net.Receive("TTT_JesterDeathCelebration", function()
        local ent = net.ReadEntity()
        local play_sound = net.ReadBool()
        local show_confetti = net.ReadBool()

        if not IsPlayer(ent) then return end

        local snd = nil
        if play_sound then
            snd = "birthday.wav"
        end

        ent:Celebrate(snd, show_confetti)
    end)
end

-- Weapons and items that come with TTT. Weapons that are not in this list will
-- get a little marker on their icon if they're buyable, showing they are custom
-- and unique to the server.
DefaultEquipment = {
    -- non-buyable
    [ROLE_NONE] = {
        "weapon_ttt_confgrenade",
        "weapon_ttt_m16",
        "weapon_ttt_smokegrenade",
        "weapon_ttt_unarmed",
        "weapon_ttt_wtester",
        "weapon_tttbase",
        "weapon_tttbasegrenade",
        "weapon_zm_carry",
        "weapon_zm_improvised",
        "weapon_zm_mac10",
        "weapon_zm_molotov",
        "weapon_zm_pistol",
        "weapon_zm_revolver",
        "weapon_zm_rifle",
        "weapon_zm_shotgun",
        "weapon_zm_sledge",
        "weapon_ttt_glock"
    }
};

-----------------
-- Old ConVars --
-----------------

--local function OldCVarWarning(oldName, newName)
--    cvars.AddChangeCallback(oldName, function(convar, oldValue, newValue)
--        RunConsoleCommand(newName, newValue)
--        ErrorNoHalt("WARNING: ConVar \'" .. oldName .. "\' deprecated. Use \'" .. newName .. "\' instead!\n")
--    end)
--end
