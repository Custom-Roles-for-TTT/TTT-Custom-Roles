AddCSLuaFile()

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_hivemind_vision_enable", "1", FCVAR_REPLICATED)
CreateConVar("ttt_hivemind_friendly_fire", "0", FCVAR_REPLICATED)
local hivemind_is_monster = CreateConVar("ttt_hivemind_is_monster", "0", FCVAR_REPLICATED)

ROLE_CONVARS[ROLE_HIVEMIND] = {}
table.insert(ROLE_CONVARS[ROLE_HIVEMIND], {
    cvar = "ttt_hivemind_vision_enable",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_HIVEMIND], {
    cvar = "ttt_hivemind_friendly_fire",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_HIVEMIND], {
    cvar = "ttt_hivemind_is_monster",
    type = ROLE_CONVAR_TYPE_BOOL
})

-------------------
-- ROLE FEATURES --
-------------------

hook.Add("TTTUpdateRoleState", "HiveMind_Team_TTTUpdateRoleState", function()
    local is_monster = hivemind_is_monster:GetBool()
    MONSTER_ROLES[ROLE_HIVEMIND] = is_monster
    INDEPENDENT_ROLES[ROLE_HIVEMIND] = not is_monster
end)