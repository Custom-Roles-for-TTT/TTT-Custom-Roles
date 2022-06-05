AddCSLuaFile()

-- Initialize role features
local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_SAPPER] = {
            EQUIP_ARMOR,
            EQUIP_RADAR
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Sapper_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Sapper_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)

hook.Add("TTTUpdateRoleState", "Sapper_TTTUpdateRoleState", function()
    ROLE_CAN_SEE_C4[ROLE_SAPPER] = GetGlobalBool("ttt_sapper_can_see_c4", false)
end)

------------------
-- ROLE CONVARS --
------------------

ROLE_CONVARS[ROLE_SAPPER] = {}
table.insert(ROLE_CONVARS[ROLE_SAPPER], {
    cvar = "ttt_sapper_aura_radius",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_SAPPER], {
    cvar = "ttt_sapper_protect_self",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SAPPER], {
    cvar = "ttt_sapper_fire_immune",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SAPPER], {
    cvar = "ttt_sapper_can_see_c4",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_SAPPER], {
    cvar = "ttt_sapper_c4_guaranteed_defuse",
    type = ROLE_CONVAR_TYPE_BOOL
})