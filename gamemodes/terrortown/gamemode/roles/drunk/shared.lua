AddCSLuaFile()

local hook = hook
local table = table

------------------
-- ROLE CONVARS --
------------------

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