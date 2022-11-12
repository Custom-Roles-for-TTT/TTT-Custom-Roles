AddCSLuaFile()

local hook = hook
local player = player

local GetAllPlayers = player.GetAll

-- Initialize role features

ROLE_SELECTION_PREDICATE[ROLE_MARSHAL] = function()
    -- Don't allow the marshal to spawn if there's already a deputy or impersonator
    for _, p in ipairs(GetAllPlayers()) do
        if p:IsDeputy() or p:IsImpersonator() then
            return false
        end
    end
    return true
end

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_MARSHAL] = {
            EQUIP_ARMOR,
            EQUIP_RADAR
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Marshal_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Marshal_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)

------------------
-- ROLE CONVARS --
------------------

ROLE_CONVARS[ROLE_MARSHAL] = {}
table.insert(ROLE_CONVARS[ROLE_MARSHAL], {
    cvar = "ttt_marshal_monster_deputy_chance",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_MARSHAL], {
    cvar = "ttt_marshal_jester_deputy_chance",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_MARSHAL], {
    cvar = "ttt_marshal_independent_deputy_chance",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_MARSHAL], {
    cvar = "ttt_marshal_announce_deputy",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_MARSHAL], {
    cvar = "ttt_marshal_badge_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})