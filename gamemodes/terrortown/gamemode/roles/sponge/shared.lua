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
local sponge_device_for_jester = CreateConVar("ttt_sponge_device_for_jester", "0", FCVAR_REPLICATED, "Whether the jester should get the spongifier", 0 ,1)
local sponge_device_for_swapper = CreateConVar("ttt_sponge_device_for_swapper", "0", FCVAR_REPLICATED, "Whether the swapper should get the spongifier", 0 ,1)

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
table.insert(ROLE_CONVARS[ROLE_SPONGE], {
    cvar = "ttt_sponge_device_for_jester",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SPONGE], {
    cvar = "ttt_sponge_device_for_swapper",
    type = ROLE_CONVAR_TYPE_BOOL
})

-----------------
-- ROLE WEAPON --
-----------------

hook.Add("TTTUpdateRoleState", "Sponge_Shared_TTTUpdateRoleState", function()
    local spongifier = weapons.GetStored("weapon_spn_spongifier")

    table.Empty(spongifier.InLoadoutFor)

    if sponge_device_for_jester:GetBool() then
        table.insert(spongifier.InLoadoutFor, ROLE_JESTER)
    end
    if sponge_device_for_swapper:GetBool() then
        table.insert(spongifier.InLoadoutFor, ROLE_SWAPPER)
    end
end)