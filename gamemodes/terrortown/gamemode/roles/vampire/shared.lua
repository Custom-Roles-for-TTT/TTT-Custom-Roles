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

-- Initialize role features
ROLE_CAN_SEE_JESTERS[ROLE_VAMPIRE] = true
ROLE_CAN_SEE_MIA[ROLE_VAMPIRE] = true

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

local vampire_is_monster = CreateConVar("ttt_vampire_is_monster", "0", FCVAR_REPLICATED)
local vampire_is_independent = CreateConVar("ttt_vampire_is_independent", "0", FCVAR_REPLICATED)
local vampire_loot_credits = CreateConVar("ttt_vampire_loot_credits", "1", FCVAR_REPLICATED)
CreateConVar("ttt_vampire_show_target_icon", "0", FCVAR_REPLICATED)
CreateConVar("ttt_vampire_vision_enabled", "0", FCVAR_REPLICATED)
CreateConVar("ttt_vampire_prime_death_mode", "0", FCVAR_REPLICATED, "What to do when the prime vampire(s) (e.g. players who spawn as vampires originally) are killed. 0 - Do nothing. 1 - Kill all vampire thralls (non-prime vampires). 2 - Revert all vampire thralls (non-prime vampires) to their original role", 0, 2)
CreateConVar("ttt_vampire_damage_reduction", "0", FCVAR_REPLICATED, "The fraction an attacker's bullet damage will be reduced by when they are shooting a vampire", 0, 1)
CreateConVar("ttt_vampire_can_see_jesters", "1", FCVAR_REPLICATED)
CreateConVar("ttt_vampire_update_scoreboard", "1", FCVAR_REPLICATED)

ROLE_CONVARS[ROLE_VAMPIRE] = {}
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_is_monster",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_is_independent",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_convert_enabled",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_drain_enabled",
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
    cvar = "ttt_vampire_drain_mute_target",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_drop_bones",
    type = ROLE_CONVAR_TYPE_BOOL
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
    type = ROLE_CONVAR_TYPE_DROPDOWN,
    choices = {"Do nothing", "Kill all thralls", "Revert role of all thralls"},
    isNumeric = true
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_prime_friendly_fire",
    type = ROLE_CONVAR_TYPE_DROPDOWN,
    choices = {"Do nothing", "Reflect", "Block"},
    isNumeric = true
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_show_target_icon",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_vision_enabled",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_can_see_jesters",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_update_scoreboard",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_credits_award_pct",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_credits_award_size",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_VAMPIRE], {
    cvar = "ttt_vampire_credits_award_repeat",
    type = ROLE_CONVAR_TYPE_BOOL
})

-------------------
-- ROLE FEATURES --
-------------------

local function InitializeEquipment()
    if EquipmentItems then
        if not EquipmentItems[ROLE_VAMPIRE] then
            EquipmentItems[ROLE_VAMPIRE] = {}
        end

        -- If we haven't already registered this item, add it to the list
        if not table.HasItemWithPropertyValue(EquipmentItems[ROLE_VAMPIRE], "id", EQUIP_ARMOR) then
            local mat_dir = "vgui/ttt/"
            table.insert(EquipmentItems[ROLE_VAMPIRE], {
                id = EQUIP_ARMOR,
                type = "item_passive",
                material = mat_dir .. "icon_armor",
                name = "item_armor",
                desc = "item_armor_desc"
            })
        end
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
    local is_monster = vampire_is_monster:GetBool()
    -- Vampires cannot be both Monsters and Independents so don't make them Independents if they are already Monsters
    local is_independent = not is_monster and vampire_is_independent:GetBool()
    MONSTER_ROLES[ROLE_VAMPIRE] = is_monster
    TRAITOR_ROLES[ROLE_VAMPIRE] = not is_monster and not is_independent
    INDEPENDENT_ROLES[ROLE_VAMPIRE] = is_independent

    -- Override whether the Vampire can loot credits
    CAN_LOOT_CREDITS_ROLES[ROLE_VAMPIRE] = vampire_loot_credits:GetBool()
end)