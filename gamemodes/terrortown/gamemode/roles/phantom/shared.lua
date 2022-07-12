AddCSLuaFile()

local table = table

-- Initialize role features
ROLE_SHOULD_SHOW_SPECTATOR_HUD[ROLE_PHANTOM] = function(ply)
    if ply:GetNWBool("Haunting") then
        return true
    end
end

------------------
-- ROLE CONVARS --
------------------

ROLE_CONVARS[ROLE_PHANTOM] = {}
table.insert(ROLE_CONVARS[ROLE_PHANTOM], {
    cvar = "ttt_phantom_respawn_health",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PHANTOM], {
    cvar = "ttt_phantom_weaker_each_respawn",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_PHANTOM], {
    cvar = "ttt_phantom_announce_death",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_PHANTOM], {
    cvar = "ttt_phantom_killer_smoke",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_PHANTOM], {
    cvar = "ttt_phantom_killer_footstep_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PHANTOM], {
    cvar = "ttt_phantom_killer_haunt",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_PHANTOM], {
    cvar = "ttt_phantom_killer_haunt_power_max",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PHANTOM], {
    cvar = "ttt_phantom_killer_haunt_power_rate",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PHANTOM], {
    cvar = "ttt_phantom_killer_haunt_power_starting",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PHANTOM], {
    cvar = "ttt_phantom_killer_haunt_move_cost",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PHANTOM], {
    cvar = "ttt_phantom_killer_haunt_jump_cost",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PHANTOM], {
    cvar = "ttt_phantom_killer_haunt_drop_cost",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PHANTOM], {
    cvar = "ttt_phantom_killer_haunt_attack_cost",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PHANTOM], {
    cvar = "ttt_phantom_killer_haunt_without_body",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_PHANTOM], {
    cvar = "ttt_phantom_cure_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})