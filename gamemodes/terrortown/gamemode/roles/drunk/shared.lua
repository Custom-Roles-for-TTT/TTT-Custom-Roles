AddCSLuaFile()

local hook = hook
local player = player
local table = table

local GetAllPlayers = player.GetAll

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_drunk_become_clown", "0", FCVAR_REPLICATED)
local drunk_any_role = CreateConVar("ttt_drunk_any_role", "0", FCVAR_REPLICATED)
local drunk_any_role_include_disabled = CreateConVar("ttt_drunk_any_role_include_disabled", "0", FCVAR_REPLICATED)

ROLE_CONVARS[ROLE_DRUNK] = {}
table.insert(ROLE_CONVARS[ROLE_DRUNK], {
    cvar = "ttt_drunk_sober_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_DRUNK], {
    cvar = "ttt_drunk_notify_mode",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_DRUNK], {
    cvar = "ttt_drunk_innocent_chance",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_DRUNK], {
    cvar = "ttt_drunk_traitor_chance",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_DRUNK], {
    cvar = "ttt_drunk_become_clown",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_DRUNK], {
    cvar = "ttt_drunk_any_role",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_DRUNK], {
    cvar = "ttt_drunk_join_losing_team",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_DRUNK], {
    cvar = "ttt_drunk_can_see_jesters",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_DRUNK], {
    cvar = "ttt_drunk_update_scoreboard",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_DRUNK], {
    cvar = "ttt_drunk_any_role_include_disabled",
    type = ROLE_CONVAR_TYPE_BOOL
})

for r = 0, ROLE_MAX do
    if r ~= ROLE_DRUNK and r ~= ROLE_GLITCH then
        local rolestring = ROLE_STRINGS_RAW[r]
        table.insert(ROLE_CONVARS[ROLE_DRUNK], {
            cvar = "ttt_drunk_can_be_" .. rolestring,
            type = ROLE_CONVAR_TYPE_BOOL
        })
    end
end

-- Add any external roles that are loaded in
-- Above, ROLE_MAX would have only included default roles
hook.Add("TTTRoleRegistered", "Drunk_TTTRoleRegistered", function(roleID)
    local rolestring = ROLE_STRINGS_RAW[roleID]
    table.insert(ROLE_CONVARS[ROLE_DRUNK], {
        cvar = "ttt_drunk_can_be_" .. rolestring,
        type = ROLE_CONVAR_TYPE_BOOL
    })
end)

-------------------
-- ROLE FEATURES --
-------------------

-- Mark any role as spawning artificially if the drunk can be any role (including disabled), the role isn't enabled, and a player exists with the role
hook.Add("TTTRoleSpawnsArtificially", "Drunk_TTTRoleSpawnsArtificially", function(role)
    if not drunk_any_role:GetBool() or not drunk_any_role_include_disabled:GetBool() then return end

    local rolestring = ROLE_STRINGS_RAW[role]
    if DEFAULT_ROLES[role] or GetConVar("ttt_" .. rolestring .. "_enabled"):GetBool() then return end

    for _, v in ipairs(GetAllPlayers()) do
        if v:IsRole(role) then
            return true
        end
    end
end)