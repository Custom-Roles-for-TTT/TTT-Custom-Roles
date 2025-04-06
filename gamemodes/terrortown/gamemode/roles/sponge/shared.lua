AddCSLuaFile()

local table = table

SPONGE_ALL_PLAYERS = 0
SPONGE_ATTACKER_AND_VICTIM = 1

-------------------
-- ROLE FEATURES --
-------------------

ROLE_STARTING_HEALTH[ROLE_SPONGE] = 150
ROLE_MAX_HEALTH[ROLE_SPONGE] = 150

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_sponge_aura_radius", "6", FCVAR_REPLICATED, "The radius of the sponge's aura in meters", 1, 30)
CreateConVar("ttt_sponge_aura_shrink", "1", FCVAR_REPLICATED)
CreateConVar("ttt_sponge_aura_mode", "0", FCVAR_REPLICATED, "The way in which the Sponge's aura redirects damage. 0 - Redirects unless all living players are inside, 1 - Redirects unless attacker and victim are both inside", 0, 1)

if not ROLE_CONVARS[ROLE_SPONGE] then
    ROLE_CONVARS[ROLE_SPONGE] = {}
end
table.insert(ROLE_CONVARS[ROLE_SPONGE], {
    cvar = "ttt_sponge_aura_radius",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SPONGE], {
    cvar = "ttt_sponge_notify_mode",
    type = ROLE_CONVAR_TYPE_DROPDOWN,
    choices = {"None", "Detective and Traitor", "Traitor", "Detective", "Everyone"},
    isNumeric = true
})
table.insert(ROLE_CONVARS[ROLE_SPONGE], {
    cvar = "ttt_sponge_notify_killer",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SPONGE], {
    cvar = "ttt_sponge_notify_sound",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SPONGE], {
    cvar = "ttt_sponge_notify_confetti",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SPONGE], {
    cvar = "ttt_sponge_device_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SPONGE], {
    cvar = "ttt_sponge_aura_shrink",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SPONGE], {
    cvar = "ttt_sponge_aura_mode",
    type = ROLE_CONVAR_TYPE_DROPDOWN,
    choices = {"All players", "Attacker and victim"},
    isNumeric = true
})
table.insert(ROLE_CONVARS[ROLE_SPONGE], {
    cvar = "ttt_sponge_aura_float_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

for _, r in ipairs(GetTeamRoles(JESTER_ROLES)) do
    if r == ROLE_SPONGE then continue end

    local rolestring = ROLE_STRINGS_RAW[r]
    local convarname = "ttt_sponge_device_for_" .. rolestring
    CreateConVar(convarname, "0", FCVAR_REPLICATED, "Whether the " .. rolestring .. " should get the spongifier", 0, 1)

    table.insert(ROLE_CONVARS[ROLE_SPONGE], {
        cvar = convarname,
        type = ROLE_CONVAR_TYPE_BOOL
    })

    convarname = "ttt_sponge_device_for_" .. rolestring .. "_heal"
    CreateConVar(convarname, "0", FCVAR_REPLICATED, "Whether the " .. rolestring .. " should be healed when they use the spongifier", 0, 1)

    table.insert(ROLE_CONVARS[ROLE_SPONGE], {
        cvar = convarname,
        type = ROLE_CONVAR_TYPE_BOOL
    })
end

-----------------
-- ROLE WEAPON --
-----------------

hook.Add("TTTUpdateRoleState", "Sponge_Shared_TTTUpdateRoleState", function()
    local spongifier = weapons.GetStored("weapon_spn_spongifier")

    table.Empty(spongifier.InLoadoutFor)

    for _, r in ipairs(GetTeamRoles(JESTER_ROLES)) do
        if r == ROLE_SPONGE then continue end

        if cvars.Bool("ttt_sponge_device_for_" .. ROLE_STRINGS_RAW[r], false) then
            table.insert(spongifier.InLoadoutFor, r)
        end
    end
end)