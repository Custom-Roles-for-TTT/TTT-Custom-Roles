AddCSLuaFile()

local table = table

-------------------
-- ROLE FEATURES --
-------------------

ROLE_STARTING_HEALTH[ROLE_SPONGE] = 150
ROLE_MAX_HEALTH[ROLE_SPONGE] = 150

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_sponge_aura_radius", "5", FCVAR_REPLICATED, "The radius of the sponge's aura in meters", 1, 30)

ROLE_CONVARS[ROLE_SPONGE] = {}
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

for _, r in ipairs(GetTeamRoles(JESTER_ROLES, {ROLE_SPONGE})) do
    local rolestring = ROLE_STRINGS_RAW[r]
    local convarname = "ttt_sponge_device_for_" .. rolestring
    CreateConVar(convarname, "0", FCVAR_REPLICATED, "Whether the " .. rolestring .. " should get the spongifier", 0, 1)

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

    for _, r in ipairs(GetTeamRoles(JESTER_ROLES, {ROLE_SPONGE})) do
        if cvars.Bool("ttt_sponge_device_for_" .. ROLE_STRINGS_RAW[r], false) then
            table.insert(spongifier.InLoadoutFor, r)
        end
    end
end)