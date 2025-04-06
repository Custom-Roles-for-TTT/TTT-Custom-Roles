AddCSLuaFile()

local table = table

-- Initialize role features
ROLE_SHOULD_SHOW_SPECTATOR_HUD[ROLE_PHANTOM] = function(ply)
    if ply:GetNWBool("PhantomPossessing") then
        return true
    end
end

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_phantom_killer_smoke", "0", FCVAR_REPLICATED)
CreateConVar("ttt_phantom_killer_haunt", "1", FCVAR_REPLICATED)
CreateConVar("ttt_phantom_killer_haunt_power_max", "100", FCVAR_REPLICATED, "The maximum amount of power a phantom can have when haunting their killer", 1, 200)
CreateConVar("ttt_phantom_killer_haunt_move_cost", "25", FCVAR_REPLICATED, "The amount of power to spend when a phantom is moving their killer via a haunting. Set to 0 to disable", 0, 100)
CreateConVar("ttt_phantom_killer_haunt_attack_cost", "100", FCVAR_REPLICATED, "The amount of power to spend when a phantom is making their killer attack via a haunting. Set to 0 to disable", 0, 100)
CreateConVar("ttt_phantom_killer_haunt_jump_cost", "50", FCVAR_REPLICATED, "The amount of power to spend when a phantom is making their killer jump via a haunting. Set to 0 to disable", 0, 100)
CreateConVar("ttt_phantom_killer_haunt_drop_cost", "75", FCVAR_REPLICATED, "The amount of power to spend when a phantom is making their killer drop their weapon via a haunting. Set to 0 to disable", 0, 100)
CreateConVar("ttt_phantom_weaker_each_respawn", "0", FCVAR_REPLICATED)
CreateConVar("ttt_phantom_announce_death", "0", FCVAR_REPLICATED)
CreateConVar("ttt_phantom_killer_footstep_time", "0", FCVAR_REPLICATED, "The amount of time a phantom's killer's footsteps should show before fading. Set to 0 to disable", 1, 60)
CreateConVar("ttt_phantom_respawn", "1", FCVAR_REPLICATED, "Whether the phantom should respawn when their killer is killed", 0, 1)

ROLE_CONVARS[ROLE_PHANTOM] = {}
table.insert(ROLE_CONVARS[ROLE_PHANTOM], {
    cvar = "ttt_phantom_respawn",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_PHANTOM], {
    cvar = "ttt_phantom_respawn_health",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PHANTOM], {
    cvar = "ttt_phantom_respawn_limit",
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
table.insert(ROLE_CONVARS[ROLE_PHANTOM], {
    cvar = "ttt_phantom_haunt_saves_lover",
    type = ROLE_CONVAR_TYPE_BOOL
})