AddCSLuaFile()

local table = table

------------------
-- ROLE CONVARS --
------------------

local clown_hide_when_active = CreateConVar("ttt_clown_hide_when_active", "0", FCVAR_REPLICATED)
CreateConVar("ttt_clown_use_traps_when_active", "0", FCVAR_REPLICATED)
CreateConVar("ttt_clown_show_target_icon", "0", FCVAR_REPLICATED)
CreateConVar("ttt_clown_heal_on_activate", "0", FCVAR_REPLICATED)
CreateConVar("ttt_clown_heal_bonus", "0", FCVAR_REPLICATED, "The amount of bonus health to give the clown if they are healed when they are activated", 0, 100)
CreateConVar("ttt_clown_damage_bonus", "0", FCVAR_REPLICATED, "Damage bonus that the clown has after being activated (e.g. 0.5 = 50% more damage)", 0, 1)
CreateConVar("ttt_clown_can_see_jesters", 0, FCVAR_REPLICATED)
CreateConVar("ttt_clown_update_scoreboard", 0, FCVAR_REPLICATED)

ROLE_CONVARS[ROLE_CLOWN] = {}
table.insert(ROLE_CONVARS[ROLE_CLOWN], {
    cvar = "ttt_clown_damage_bonus",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_CLOWN], {
    cvar = "ttt_clown_activation_credits",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_CLOWN], {
    cvar = "ttt_clown_hide_when_active",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_CLOWN], {
    cvar = "ttt_clown_use_traps_when_active",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_CLOWN], {
    cvar = "ttt_clown_show_target_icon",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_CLOWN], {
    cvar = "ttt_clown_heal_on_activate",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_CLOWN], {
    cvar = "ttt_clown_heal_bonus",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_CLOWN], {
    cvar = "ttt_clown_can_see_jesters",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_CLOWN], {
    cvar = "ttt_clown_update_scoreboard",
    type = ROLE_CONVAR_TYPE_BOOL
})

-------------------
-- ROLE FEATURES --
-------------------

ROLE_IS_ACTIVE[ROLE_CLOWN] = function(ply)
    return ply:IsIndependentTeam()
end

function SetClownTeam(independent)
    INDEPENDENT_ROLES[ROLE_CLOWN] = independent
    JESTER_ROLES[ROLE_CLOWN] = not independent

    UpdateRoleColours()

    if SERVER then
        net.Start("TTT_ClownTeamChange")
        net.WriteBool(independent)
        net.Broadcast()
    end
end

if CLIENT then
    net.Receive("TTT_ClownTeamChange", function()
        local independent = net.ReadBool()
        SetClownTeam(independent)
    end)
end

ROLE_SHOULD_REVEAL_ROLE_WHEN_ACTIVE[ROLE_CLOWN] = function()
    return not clown_hide_when_active:GetBool()
end