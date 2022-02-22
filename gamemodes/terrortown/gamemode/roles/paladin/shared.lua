AddCSLuaFile()

local hook = hook

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_PALADIN] = {
            EQUIP_ARMOR,
            EQUIP_RADAR
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Paladin_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Paladin_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)

-- ROLE CONVARS --
------------------

ROLE_CONVARS[ROLE_PALADIN] = {}
table.insert(ROLE_CONVARS[ROLE_PALADIN], {
    cvar = "ttt_paladin_aura_radius",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PALADIN], {
    cvar = "ttt_paladin_damage_reduction",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_PALADIN], {
    cvar = "ttt_paladin_heal_rate",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PALADIN], {
    cvar = "ttt_paladin_protect_self",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_PALADIN], {
    cvar = "ttt_paladin_heal_self",
    type = ROLE_CONVAR_TYPE_BOOL
})