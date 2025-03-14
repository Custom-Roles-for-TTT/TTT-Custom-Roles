AddCSLuaFile()

local hook = hook
local table = table

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

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_paladin_aura_radius", "6", FCVAR_REPLICATED, "The radius of the paladin's aura in meters", 1, 30)
CreateConVar("ttt_paladin_protect_self", "0", FCVAR_REPLICATED)
CreateConVar("ttt_paladin_heal_self", "1", FCVAR_REPLICATED)
CreateConVar("ttt_paladin_damage_reduction", "0.3", FCVAR_REPLICATED, "The fraction an attacker's damage will be reduced by when they are shooting a player inside the paladin's aura", 0, 1)

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