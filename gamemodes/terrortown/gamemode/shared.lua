-- Version string for display and function for version checks
CR_VERSION = "1.0.8"

function CRVersion(version)
    local installedVersionRaw = string.Split(CR_VERSION, ".")
    local installedVersion = {
        major = tonumber(installedVersionRaw[1]),
        minor = tonumber(installedVersionRaw[2]),
        patch = tonumber(installedVersionRaw[3])
    }

    local neededVersionRaw = string.Split(version, ".")
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
GM.Version = "Custom Roles for TTT - " .. CR_VERSION

GM.Customized = false

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

ROLE_MAX = 25

local function AddRoleAssociations(list, roles)
    -- Use an associative array so we can do a O(1) lookup by role
    -- See: https://wiki.facepunch.com/gmod/table.HasValue
    for _, r in ipairs(roles) do
        list[r] = true
    end
end

function GetTeamRoles(list)
    local roles = {}
    for r, v in pairs(list) do
        if v then
            table.insert(roles, r)
        end
    end
    return roles
end

SHOP_ROLES = {}
AddRoleAssociations(SHOP_ROLES, {ROLE_TRAITOR, ROLE_DETECTIVE, ROLE_HYPNOTIST, ROLE_DEPUTY, ROLE_IMPERSONATOR, ROLE_JESTER, ROLE_SWAPPER, ROLE_CLOWN, ROLE_MERCENARY, ROLE_ASSASSIN, ROLE_KILLER, ROLE_ZOMBIE, ROLE_VAMPIRE, ROLE_QUACK, ROLE_PARASITE})

TRAITOR_ROLES = {}
AddRoleAssociations(TRAITOR_ROLES, {ROLE_TRAITOR, ROLE_HYPNOTIST, ROLE_IMPERSONATOR, ROLE_ASSASSIN, ROLE_VAMPIRE, ROLE_QUACK, ROLE_PARASITE})

INNOCENT_ROLES = {}
AddRoleAssociations(INNOCENT_ROLES, {ROLE_INNOCENT, ROLE_DETECTIVE, ROLE_GLITCH, ROLE_PHANTOM, ROLE_REVENGER, ROLE_DEPUTY, ROLE_MERCENARY, ROLE_VETERAN, ROLE_DOCTOR, ROLE_TRICKSTER})

JESTER_ROLES = {}
AddRoleAssociations(JESTER_ROLES, {ROLE_JESTER, ROLE_SWAPPER, ROLE_CLOWN, ROLE_BEGGAR, ROLE_BODYSNATCHER})

INDEPENDENT_ROLES = {}
AddRoleAssociations(INDEPENDENT_ROLES, {ROLE_DRUNK, ROLE_OLDMAN, ROLE_KILLER, ROLE_ZOMBIE})

MONSTER_ROLES = {}
AddRoleAssociations(MONSTER_ROLES, {})

DEFAULT_ROLES = {}
AddRoleAssociations(DEFAULT_ROLES, {ROLE_INNOCENT, ROLE_TRAITOR, ROLE_DETECTIVE})

-- Traitors get this ability by default
TRAITOR_BUTTON_ROLES = {}
AddRoleAssociations(TRAITOR_BUTTON_ROLES, {ROLE_TRICKSTER})

-- Shop roles get this ability by default
CAN_LOOT_CREDITS_ROLES = {}
AddRoleAssociations(CAN_LOOT_CREDITS_ROLES, {ROLE_TRICKSTER})

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
    else
        return false
    end
end

local function FillRoleColors(list, type)
    local c = nil
    local mode = "default"
    if CLIENT then
        local modeCVar = GetConVar("ttt_color_mode")
        if modeCVar then mode = modeCVar:GetString() end
    end

    for r = -1, ROLE_MAX do
        if mode == "custom" then
            if r == ROLE_INNOCENT then
                local cVarCol = ColorFromCustomConVars("ttt_custom_inn_color")
                if cVarCol then c = cVarCol
                else c = COLOR_INNOCENT["default"] end
            elseif r == ROLE_DETECTIVE then
                local cVarCol = ColorFromCustomConVars("ttt_custom_det_color")
                if cVarCol then c = cVarCol
                else c = COLOR_DETECTIVE["default"] end
            elseif INNOCENT_ROLES[r] then
                local cVarCol = ColorFromCustomConVars("ttt_custom_spec_inn_color")
                if cVarCol then c = cVarCol
                else c = COLOR_SPECIAL_INNOCENT["default"] end
            elseif r == ROLE_TRAITOR then
                local cVarCol = ColorFromCustomConVars("ttt_custom_tra_color")
                if cVarCol then c = cVarCol
                else c = COLOR_TRAITOR["default"] end
            elseif TRAITOR_ROLES[r] then
                local cVarCol = ColorFromCustomConVars("ttt_custom_spec_tra_color")
                if cVarCol then c = cVarCol
                else c = COLOR_SPECIAL_TRAITOR["default"] end
            elseif JESTER_ROLES[r] then
                local cVarCol = ColorFromCustomConVars("ttt_custom_jes_color")
                if cVarCol then c = cVarCol
                else c = COLOR_JESTER["default"] end
            elseif INDEPENDENT_ROLES[r] then
                local cVarCol = ColorFromCustomConVars("ttt_custom_ind_color")
                if cVarCol then c = cVarCol
                else c = COLOR_INDEPENDENT["default"] end
            elseif MONSTER_ROLES[r] then
                local cVarCol = ColorFromCustomConVars("ttt_custom_mon_color")
                if cVarCol then c = cVarCol
                else c = COLOR_MONSTER["default"] end
            else c = COLOR_WHITE end
        else
            if r == ROLE_INNOCENT then c = COLOR_INNOCENT[mode]
            elseif r == ROLE_DETECTIVE then c = COLOR_DETECTIVE[mode]
            elseif INNOCENT_ROLES[r] then c = COLOR_SPECIAL_INNOCENT[mode]
            elseif r == ROLE_TRAITOR then c = COLOR_TRAITOR[mode]
            elseif TRAITOR_ROLES[r] then c = COLOR_SPECIAL_TRAITOR[mode]
            elseif JESTER_ROLES[r] then c = COLOR_JESTER[mode]
            elseif INDEPENDENT_ROLES[r] then c = COLOR_INDEPENDENT[mode]
            elseif MONSTER_ROLES[r] then c = COLOR_MONSTER[mode]
            else c = COLOR_WHITE end
        end


        local h, s, l = ColorToHSL(c)
        if type == "dark" then
            l = math.max(l - 0.125, 0.125)
        elseif type == "highlight" or "radar" then
            s = 1
        end
        c = HSLToColor(h, s, l)

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

        list[r] = c
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
    [ROLE_TRICKSTER] = "trickster"
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
    [ROLE_REVENGER] = "Tevenger",
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
    [ROLE_TRICKSTER] = "Trickster"
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
    [ROLE_REVENGER] = "Tevengers",
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
    [ROLE_TRICKSTER] = "Tricksters"
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
    [ROLE_TRICKSTER] = "a Trickster"
}

ROLE_STRINGS_SHORT = {
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
    [ROLE_TRICKSTER] = "tri"
}

function UpdateRoleStrings()
    for role = 0, ROLE_MAX do
        local name = GetGlobalString("ttt_" .. ROLE_STRINGS_RAW[role] .. "_name", "")
        if name ~= "" then
            ROLE_STRINGS[role] = name

            local plural = GetGlobalString("ttt_" .. ROLE_STRINGS_RAW[role] .. "_name_plural", "")
            if plural == "" then -- Fallback if no plural is given. Does NOT handle all cases properly
                local lastChar = string.sub(name, name:len(), name:len()):lower()
                if lastChar == "s" then
                    ROLE_STRINGS_PLURAL[role] = name .. "es"
                elseif lastChar == "y" then
                    ROLE_STRINGS_PLURAL[role] = string.sub(name, 1, name:len() - 1) .. "ies"
                else
                    ROLE_STRINGS_PLURAL[role] = name .. "s"
                end
            else
                ROLE_STRINGS_PLURAL[role] = plural
            end

            local article = GetGlobalString("ttt_" .. ROLE_STRINGS_RAW[role] .. "_name_article", "")
            if article == "" then -- Fallback if no article is given. Does NOT handle all cases properly
                local firstChar = string.sub(name, 1, 1):lower()
                if firstChar == "a" or firstChar == "e" or firstChar == "i" or firstChar == "o" or firstChar == "u" then
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
JESTER_NOTIFY_DETECTIVE_AND_TRAITOR = 1
JESTER_NOTIFY_TRAITOR = 2
JESTER_NOTIFY_DETECTIVE = 3
JESTER_NOTIFY_EVERYONE = 4

-- Vampire prime death modes
VAMPIRE_DEATH_NONE = 0
VAMPIRE_DEATH_KILL_CONVERED = 1
VAMPIRE_DEATH_REVERT_CONVERTED = 2

-- Doctor Modes
DOCTOR_MODE_STATION = 0
DOCTOR_MODE_EMT = 1

-- Parasite respawn modes
PARASITE_RESPAWN_HOST = 0
PARASITE_RESPAWN_BODY = 1
PARASITE_RESPAWN_RANDOM = 2

-- Swapper weapon modes
SWAPPER_WEAPON_NONE = 0
SWAPPER_WEAPON_ROLE = 1
SWAPPER_WEAPON_ALL = 2

COLOR_WHITE = Color(255, 255, 255, 255)
COLOR_BLACK = Color(0, 0, 0, 255)
COLOR_GREEN = Color(0, 255, 0, 255)
COLOR_DGREEN = Color(0, 100, 0, 255)
COLOR_RED = Color(255, 0, 0, 255)
COLOR_YELLOW = Color(200, 200, 0, 255)
COLOR_LGRAY = Color(200, 200, 200, 255)
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

    if SERVER then
        -- This player killed a Phantom. Tell everyone where their foot steps should go
        local phantom_killer_footstep_time = GetConVar("ttt_phantom_killer_footstep_time"):GetInt()
        if phantom_killer_footstep_time > 0 and ply:GetNWBool("Haunted", false) and ply:WaterLevel() == 0 then
            net.Start("TTT_PlayerFootstep")
            net.WriteEntity(ply)
            net.WriteVector(pos)
            net.WriteAngle(ply:GetAimVector():Angle())
            net.WriteBit(foot)
            net.WriteTable(Color(138, 4, 4))
            net.WriteUInt(phantom_killer_footstep_time, 8)
            net.Broadcast()
        end
    end

    -- Kill footsteps on player and client
    if ply:Crouching() or ply:GetMaxSpeed() < 150 then
        -- do not play anything, just prevent normal sounds from playing
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
        local mul = hook.Call("TTTPlayerSpeedModifier", GAMEMODE, ply, slowed, mv) or 1
        mul = basemul * mul
        mv:SetMaxClientSpeed(mv:GetMaxClientSpeed() * mul)
        mv:SetMaxSpeed(mv:GetMaxSpeed() * mul)
    end
end

function GetSprintMultiplier(ply, sprinting)
    local mult = 1
    if IsValid(ply) then
        local mults = {}
        hook.Run("TTTSpeedMultiplier", ply, mults)
        for _, m in pairs(mults) do
            mult = mult * m
        end

        if sprinting and ply.mult then
            mult = mult * ply.mult
        end

        local wep = ply:GetActiveWeapon()
        if wep and IsValid(wep) then
            local weaponClass = wep:GetClass()
            if weaponClass == "genji_melee" then
                return 1.4 * mult
            elseif weaponClass == "weapon_ttt_homebat" then
                return 1.25 * mult
            elseif weaponClass == "weapon_vam_fangs" and wep:Clip1() < 15 then
                return 3 * mult
            elseif weaponClass == "weapon_zom_claws" then
                local speed_bonus = 1
                if ply:IsZombiePrime() then
                    speed_bonus = speed_bonus + GetGlobalFloat("ttt_zombie_prime_speed_bonus", 0.35)
                else
                    speed_bonus = speed_bonus + GetGlobalFloat("ttt_zombie_thrall_speed_bonus", 0.15)
                end

                if ply:HasEquipmentItem(EQUIP_SPEED) then
                    speed_bonus = speed_bonus + 0.15
                end
                return speed_bonus * mult
            end
        end
    end

    return mult
end

function UpdateRoleWeaponState()
    -- If the parasite is not enabled, don't let anyone buy the cure
    local parasite_cure = weapons.GetStored("weapon_par_cure")
    if not GetGlobalBool("ttt_parasite_enabled", false) then
        table.Empty(parasite_cure.CanBuy)
    else
        parasite_cure.CanBuy = table.Copy(parasite_cure.CanBuyDefault)
    end

    if SERVER then
        net.Start("TTT_ResetBuyableWeaponsCache")
        net.Broadcast()
    end
end

function UpdateRoleState()
    local zombies_are_monsters = GetGlobalBool("ttt_zombies_are_monsters", false)
    -- Zombies cannot be both Monsters and Traitors so don't make them Traitors if they are already Monsters
    local zombies_are_traitors = not zombies_are_monsters and GetGlobalBool("ttt_zombies_are_traitors", false)
    MONSTER_ROLES[ROLE_ZOMBIE] = zombies_are_monsters
    TRAITOR_ROLES[ROLE_ZOMBIE] = zombies_are_traitors
    INDEPENDENT_ROLES[ROLE_ZOMBIE] = not zombies_are_monsters and not zombies_are_traitors

    local vampires_are_monsters = GetGlobalBool("ttt_vampires_are_monsters", false)
    MONSTER_ROLES[ROLE_VAMPIRE] = vampires_are_monsters
    TRAITOR_ROLES[ROLE_VAMPIRE] = not vampires_are_monsters

    -- Update role colors to make sure team changes have taken effect
    UpdateRoleColours()

    UpdateRoleWeaponState()
end

if SERVER then
    -- Centralize this so it can be handled on round start and on player death
    function AssignAssassinTarget(ply, start, delay)
        -- Don't let dead players, spectators, non-assassins, or failed assassins get another target
        -- And don't assign targets if the round isn't currently running
        if not IsValid(ply) or GetRoundState() > ROUND_ACTIVE or
            not ply:IsAssassin() or ply:GetNWBool("AssassinFailed", false)
        then
            return
        end

        -- Reset the target to empty in case there are no valid targets
        ply:SetNWString("AssassinTarget", "")

        local enemies = {}
        local shops = {}
        local detectives = {}
        local independents = {}
        for _, p in pairs(player.GetAll()) do
            if p:Alive() and not p:IsSpec() then
                if p:IsDetective() then
                    table.insert(detectives, p:Nick())
                -- Exclude Glitch from this list so they don't get discovered immediately
                elseif (p:IsInnocentTeam() or p:IsMonsterTeam()) and not p:IsGlitch() then
                    -- Don't add the former beggar to the list of enemies unless the "reveal" setting is enabled
                    if GetConVar("ttt_beggar_reveal_change"):GetBool() or not p:GetNWBool("WasBeggar", false) then
                        -- Put shop roles into a list if they should be targeted last
                        if GetConVar("ttt_assassin_shop_roles_last"):GetBool() and p:IsShopRole() then
                            table.insert(shops, p:Nick())
                        else
                            table.insert(enemies, p:Nick())
                        end
                    end
                -- Exclude the Old Man because they just want to survive
                elseif p:IsIndependentTeam() and not p:IsOldMan() then
                    table.insert(independents, p:Nick())
                end
            end
        end

        local target = nil
        if #enemies > 0 then
            target = enemies[math.random(#enemies)]
        elseif #shops > 0 then
            target = shops[math.random(#shops)]
        elseif #detectives > 0 then
            target = detectives[math.random(#detectives)]
        elseif #independents > 0 then
            target = independents[math.random(#independents)]
        end

        local targetMessage = ""
        if target ~= nil then
            ply:SetNWString("AssassinTarget", target)

            local targets = #enemies + #shops + #detectives + #independents
            local targetCount
            if targets > 1 then
                targetCount = start and "first" or "next"
            elseif targets == 1 then
                targetCount = "final"
            end
            targetMessage = "Your " .. targetCount .. " target is " .. target .. "."
        else
            targetMessage = "No further targets available."
        end

        if ply:Alive() and not ply:IsSpec() then
            if not delay and not start then targetMessage = "Target eliminated. " .. targetMessage end
            ply:PrintMessage(HUD_PRINTCENTER, targetMessage)
            ply:PrintMessage(HUD_PRINTTALK, targetMessage)
        end
    end

    function SetRoleHealth(ply)
        if not IsValid(ply) or not ply:Alive() or ply:IsSpec() then return end
        local role = ply:GetRole()
        if role <= ROLE_NONE or role > ROLE_MAX then return end

        local maxhealth = GetConVar("ttt_" .. ROLE_STRINGS_RAW[role] .. "_max_health"):GetInt()
        ply:SetMaxHealth(maxhealth)
        local health = GetConVar("ttt_" .. ROLE_STRINGS_RAW[role] .. "_starting_health"):GetInt()
        ply:SetHealth(health)
    end
end

-- Weapons and items that come with TTT. Weapons that are not in this list will
-- get a little marker on their icon if they're buyable, showing they are custom
-- and unique to the server.
DefaultEquipment = {
    -- traitor-buyable by default
    [ROLE_TRAITOR] = {
        "weapon_ttt_c4",
        "weapon_ttt_flaregun",
        "weapon_ttt_knife",
        "weapon_ttt_phammer",
        "weapon_ttt_push",
        "weapon_ttt_radio",
        "weapon_ttt_sipistol",
        "weapon_ttt_teleport",
        "weapon_ttt_decoy",
        EQUIP_ARMOR,
        EQUIP_RADAR,
        EQUIP_DISGUISE
    },

    -- detective-buyable by default
    [ROLE_DETECTIVE] = {
        "weapon_ttt_binoculars",
        "weapon_ttt_defuser",
        "weapon_ttt_health_station",
        "weapon_ttt_stungun",
        "weapon_ttt_cse",
        "weapon_ttt_teleport",
        EQUIP_ARMOR,
        EQUIP_RADAR
    },

    [ROLE_MERCENARY] = {
        "weapon_ttt_health_station",
        "weapon_ttt_teleport",
        "weapon_ttt_confgrenade",
        "weapon_ttt_m16",
        "weapon_ttt_smokegrenade",
        "weapon_zm_mac10",
        "weapon_zm_molotov",
        "weapon_zm_pistol",
        "weapon_zm_revolver",
        "weapon_zm_rifle",
        "weapon_zm_shotgun",
        "weapon_zm_sledge",
        "weapon_ttt_glock",
        EQUIP_ARMOR,
        EQUIP_RADAR
    },

    [ROLE_HYPNOTIST] = {
        EQUIP_ARMOR,
        EQUIP_RADAR,
        EQUIP_DISGUISE
    },

    [ROLE_IMPERSONATOR] = {
        EQUIP_ARMOR,
        EQUIP_RADAR,
        EQUIP_DISGUISE
    },

    [ROLE_ASSASSIN] = {
        EQUIP_ARMOR,
        EQUIP_RADAR,
        EQUIP_DISGUISE
    },

    [ROLE_KILLER] = {
        "weapon_ttt_health_station",
        "weapon_ttt_teleport",
        "weapon_ttt_confgrenade",
        "weapon_ttt_m16",
        "weapon_ttt_smokegrenade",
        "weapon_zm_mac10",
        "weapon_zm_molotov",
        "weapon_zm_pistol",
        "weapon_zm_revolver",
        "weapon_zm_rifle",
        "weapon_zm_shotgun",
        "weapon_zm_sledge",
        "weapon_ttt_glock",
        EQUIP_ARMOR,
        EQUIP_RADAR,
        EQUIP_DISGUISE
    },

    [ROLE_ZOMBIE] = {
        EQUIP_ARMOR,
        EQUIP_RADAR,
        EQUIP_DISGUISE,
        EQUIP_SPEED,
        EQUIP_REGEN
    },

    [ROLE_VAMPIRE] = {
        EQUIP_ARMOR,
        EQUIP_RADAR,
        EQUIP_DISGUISE
    },

    [ROLE_QUACK] = {
        EQUIP_ARMOR,
        EQUIP_RADAR,
        EQUIP_DISGUISE
    },

    [ROLE_PARASITE] = {
        EQUIP_ARMOR,
        EQUIP_RADAR,
        EQUIP_DISGUISE
    },

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
