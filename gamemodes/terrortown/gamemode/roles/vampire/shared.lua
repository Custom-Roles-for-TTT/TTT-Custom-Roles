AddCSLuaFile()

local hook = hook
local IsValid = IsValid
local table = table

-- Vampire prime death modes
VAMPIRE_DEATH_NONE = 0
VAMPIRE_DEATH_KILL_CONVERTED = 1
VAMPIRE_DEATH_REVERT_CONVERTED = 2

-- Vampire thrall friendly fire modes
VAMPIRE_THRALL_FF_MODE_NONE = 0
VAMPIRE_THRALL_FF_MODE_REFLECT = 1
VAMPIRE_THRALL_FF_MODE_IMMUNE = 2

local function InitializeEquipment()
    if EquipmentItems then
        local mat_dir = "vgui/ttt/"
        EquipmentItems[ROLE_VAMPIRE] = {
            -- body armor
            { id = EQUIP_ARMOR,
              type = "item_passive",
              material = mat_dir .. "icon_armor",
              name = "item_armor",
              desc = "item_armor_desc"
            }
        }
    end

    if DefaultEquipment then
        DefaultEquipment[ROLE_VAMPIRE] = {
            EQUIP_ARMOR,
            EQUIP_RADAR,
            EQUIP_DISGUISE
        }
    end
end
InitializeEquipment()

-- Initialize role features
hook.Add("Initialize", "Vampire_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Vampire_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)

hook.Add("TTTUpdateRoleState", "Vampire_TTTUpdateRoleState", function()
    local vampires_are_monsters = GetGlobalBool("ttt_vampires_are_monsters", false)
    -- Vampires cannot be both Monsters and Independents so don't make them Independents if they are already Monsters
    local vampires_are_independent = not vampires_are_monsters and GetGlobalBool("ttt_vampires_are_independent", false)
    MONSTER_ROLES[ROLE_VAMPIRE] = vampires_are_monsters
    TRAITOR_ROLES[ROLE_VAMPIRE] = not vampires_are_monsters and not vampires_are_independent
    INDEPENDENT_ROLES[ROLE_VAMPIRE] = vampires_are_independent

    -- Override whether the Vampire can loot credits
    CAN_LOOT_CREDITS_ROLES[ROLE_VAMPIRE] = GetGlobalBool("ttt_vampire_loot_credits", true)
end)

--------------------
-- PLAYER METHODS --
--------------------

local plymeta = FindMetaTable("Player")

function plymeta:GetVampirePrime() return self:GetVampire() and self:GetNWBool("vampire_prime", false) end
function plymeta:GetVampirePreviousRole() return self:GetNWInt("vampire_previous_role", ROLE_NONE) end
function plymeta:GetVampireAlly()
    local role = self:GetRole()
    if MONSTER_ROLES[ROLE_VAMPIRE] then
        return MONSTER_ROLES[role]
    elseif TRAITOR_ROLES[ROLE_VAMPIRE] then
        return TRAITOR_ROLES[role]
    end
    return INDEPENDENT_ROLES[role]
end

plymeta.IsVampirePrime = plymeta.GetVampirePrime
plymeta.IsVampireAlly = plymeta.GetVampireAlly

-----------------
-- SPEED BONUS --
-----------------

-- Vampire moves 3x faster temporarily while fading
hook.Add("TTTSpeedMultiplier", "Vampire_TTTSpeedMultiplier", function(ply, mults)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and WEPS.GetClass(wep) == "weapon_vam_fangs" and wep:Clip1() < 15 then
        table.insert(mults, 3)
    end
end)

------------------
-- ROLE CONVARS --
------------------

ROLE_CONVARS[ROLE_VAMPIRE] = {}
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampires_are_monsters",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampires_are_independent",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_convert_enable",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_drain_enable",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_drain_first",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_drain_credits",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_kill_credits",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_loot_credits",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_fang_timer",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_fang_dead_timer",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_fang_heal",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_fang_overheal",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_fang_overheal_living",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_fang_unfreeze_delay",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_damage_reduction",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_prime_only_convert",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_prime_death_mode",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_prime_friendly_fire",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_show_target_icon",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_vision_enable",
    type = ROLE_CONVAR_TYPE_BOOL
})
