AddCSLuaFile()

------------------
-- ROLE CONVARS --
------------------

local sapper_is_innocent = CreateConVar("ttt_sapper_is_innocent", "0", FCVAR_REPLICATED, "Whether the sapper should be treated as a special innocent", 0, 1)
CreateConVar("ttt_sapper_aura_radius", "6", FCVAR_REPLICATED, "The radius of the sapper's aura in meters", 1, 30)
CreateConVar("ttt_sapper_protect_self", "1", FCVAR_REPLICATED)
CreateConVar("ttt_sapper_fire_immune", "0", FCVAR_REPLICATED)
local sapper_can_see_c4 = CreateConVar("ttt_sapper_can_see_c4", "0", FCVAR_REPLICATED)
CreateConVar("ttt_sapper_c4_guaranteed_defuse", "0", FCVAR_REPLICATED)

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
table.insert(ROLE_CONVARS[ROLE_SAPPER], {
    cvar = "ttt_sapper_is_innocent",
    type = ROLE_CONVAR_TYPE_BOOL
})

-------------------
-- ROLE FEATURES --
-------------------

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
    ROLE_CAN_SEE_C4[ROLE_SAPPER] = sapper_can_see_c4:GetBool()

    local is_innocent = sapper_is_innocent:GetBool()
    DETECTIVE_ROLES[ROLE_SAPPER] = not is_innocent
end)