AddCSLuaFile()

local hook = hook
local table = table

-- Initialize role features
ROLE_SHOULD_DELAY_ANNOUNCEMENTS[ROLE_ASSASSIN] = true

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

ROLE_CONVARS[ROLE_ASSASSIN] = {}
table.insert(ROLE_CONVARS[ROLE_ASSASSIN], {
    cvar = "ttt_assassin_show_target_icon",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ASSASSIN], {
    cvar = "ttt_assassin_target_vision_enable",
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
    cvar = "ttt_assassin_shop_roles_last",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ASSASSIN], {
    cvar = "ttt_assassin_allow_lootgoblin_kill",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ASSASSIN], {
    cvar = "ttt_assassin_allow_zombie_kill",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ASSASSIN], {
    cvar = "ttt_assassin_allow_vampire_kill",
    type = ROLE_CONVAR_TYPE_BOOL
})