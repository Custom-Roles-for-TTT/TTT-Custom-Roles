AddCSLuaFile()

local hook = hook
local table = table

-- Initialize role features
local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_ASSASSIN] = {
            EQUIP_ARMOR,
            EQUIP_RADAR,
            EQUIP_DISGUISE
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Assassin_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Assassin_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_assassin_show_target_icon", "0", FCVAR_REPLICATED)
CreateConVar("ttt_assassin_target_vision_enabled", "0", FCVAR_REPLICATED)
CreateConVar("ttt_assassin_next_target_delay", "5", FCVAR_REPLICATED, "The delay (in seconds) before an assassin is assigned their next target", 0, 30)
CreateConVar("ttt_assassin_allow_independents_kill", "0", FCVAR_REPLICATED, "Whether independents can be killed without failing the contract", 0, 1)
CreateConVar("ttt_assassin_allow_jesters_kill", "0", FCVAR_REPLICATED, "Whether jesters can be killed without failing the contract", 0, 1)
CreateConVar("ttt_assassin_allow_monsters_kill", "0", FCVAR_REPLICATED, "Whether monsters can be killed without failing the contract", 0, 1)
CreateConVar("ttt_assassin_target_damage_bonus", "1", FCVAR_REPLICATED, "Damage bonus that the assassin has against their target (e.g. 0.5 = 50% extra damage)", 0, 1)
CreateConVar("ttt_assassin_target_bonus_bought", "1", FCVAR_REPLICATED)
CreateConVar("ttt_assassin_wrong_damage_penalty", "0.5", FCVAR_REPLICATED, "Damage penalty that the assassin has when attacking someone who is not their target (e.g. 0.5 = 50% less damage)", 0, 1)
CreateConVar("ttt_assassin_failed_damage_penalty", "0.5", FCVAR_REPLICATED, "Damage penalty that the assassin has after they have failed their contract by killing the wrong person (e.g. 0.5 = 50% less damage)", 0, 1)

ROLE_CONVARS[ROLE_ASSASSIN] = {}
table.insert(ROLE_CONVARS[ROLE_ASSASSIN], {
    cvar = "ttt_assassin_show_target_icon",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ASSASSIN], {
    cvar = "ttt_assassin_target_vision_enabled",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ASSASSIN], {
    cvar = "ttt_assassin_next_target_delay",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_ASSASSIN], {
    cvar = "ttt_assassin_target_damage_bonus",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_ASSASSIN], {
    cvar = "ttt_assassin_target_bonus_bought",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ASSASSIN], {
    cvar = "ttt_assassin_wrong_damage_penalty",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_ASSASSIN], {
    cvar = "ttt_assassin_failed_damage_penalty",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_ASSASSIN], {
    cvar = "ttt_assassin_damage_penalty_complete",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ASSASSIN], {
    cvar = "ttt_assassin_shop_roles_last",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ASSASSIN], {
    cvar = "ttt_assassin_allow_independents_kill",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ASSASSIN], {
    cvar = "ttt_assassin_allow_jesters_kill",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ASSASSIN], {
    cvar = "ttt_assassin_allow_monsters_kill",
    type = ROLE_CONVAR_TYPE_BOOL
})
for r = 0, ROLE_MAX do
    -- Explicitly add vindicator here since they turn into an independent, but start as an innocent
    if INDEPENDENT_ROLES[r] or JESTER_ROLES[r] or MONSTER_ROLES[r] or r == ROLE_VINDICATOR then
        local rolestring = ROLE_STRINGS_RAW[r]
        table.insert(ROLE_CONVARS[ROLE_ASSASSIN], {
            cvar = "ttt_assassin_allow_" .. rolestring .. "_kill",
            type = ROLE_CONVAR_TYPE_BOOL
        })
    end
end