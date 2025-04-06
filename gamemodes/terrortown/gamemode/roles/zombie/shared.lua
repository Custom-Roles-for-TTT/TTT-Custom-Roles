AddCSLuaFile()

local hook = hook
local IsValid = IsValid
local table = table

-- Zombie friendly fire modes
ZOMBIE_FF_MODE_NONE = 0
ZOMBIE_FF_MODE_REFLECT = 1
ZOMBIE_FF_MODE_IMMUNE = 2

-- Initialize role features
ROLE_CAN_SEE_JESTERS[ROLE_ZOMBIE] = true
ROLE_CAN_SEE_MIA[ROLE_ZOMBIE] = true
ROLE_HAS_SHOP_SYNC[ROLE_ZOMBIE] = true

ROLE_VICTIM_CHANGING_ROLE[ROLE_ZOMBIE] = function(ply, victim)
    return victim:IsZombifying()
end

hook.Add("TTTIsPlayerRespawning", "Zombie_TTTIsPlayerRespawning", function(ply)
    if not IsPlayer(ply) then return end
    if ply:Alive() then return end

    if ply:IsZombifying() then
        return true
    end
end)

hook.Add("TTTRoleSpawnsArtificially", "Zombie_TTTRoleSpawnsArtificially", function(role)
    if role == ROLE_ZOMBIE then
        local madScientistEnabled = util.CanRoleSpawn(ROLE_MADSCIENTIST) and
            ((INDEPENDENT_ROLES[ROLE_ZOMBIE] and INDEPENDENT_ROLES[ROLE_MADSCIENTIST])
            or (MONSTER_ROLES[ROLE_ZOMBIE] and MONSTER_ROLES[ROLE_MADSCIENTIST]))
        if util.CanRoleSpawn(ROLE_INFECTED) or madScientistEnabled then
            return true
        end
    end
end)

--------------------
-- PLAYER METHODS --
--------------------

local plymeta = FindMetaTable("Player")

function plymeta:GetZombiePrime() return self:GetZombie() and self:GetNWBool("zombie_prime", false) end
function plymeta:GetZombieAlly()
    local role = self:GetRole()
    if MONSTER_ROLES[ROLE_ZOMBIE] then
        return MONSTER_ROLES[role]
    elseif TRAITOR_ROLES[ROLE_ZOMBIE] then
        return TRAITOR_ROLES[role]
    end
    return role == ROLE_ZOMBIE or role == ROLE_MADSCIENTIST
end

plymeta.IsZombiePrime = plymeta.GetZombiePrime
plymeta.IsZombieAlly = plymeta.GetZombieAlly

function plymeta:IsZombifying() return self:GetNWBool("IsZombifying", false) or self:GetNWBool("InfectedIsZombifying", false) end

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_zombie_show_target_icon", "0", FCVAR_REPLICATED)
CreateConVar("ttt_zombie_vision_enabled", "0", FCVAR_REPLICATED)
local zombie_is_monster = CreateConVar("ttt_zombie_is_monster", "0", FCVAR_REPLICATED)
local zombie_is_traitor = CreateConVar("ttt_zombie_is_traitor", "0", FCVAR_REPLICATED)
local zombie_prime_speed_bonus = CreateConVar("ttt_zombie_prime_speed_bonus", "0.35", FCVAR_REPLICATED, "The amount of bonus speed a prime zombie (e.g. player who spawned as a zombie originally) should get when using their claws. Server or round must be restarted for changes to take effect", 0, 1)
local zombie_thrall_speed_bonus = CreateConVar("ttt_zombie_thrall_speed_bonus", "0.15", FCVAR_REPLICATED, "The amount of bonus speed a zombie thrall (e.g. non-prime zombie) should get when using their claws. Server or round must be restarted for changes to take effect", 0, 1)
CreateConVar("ttt_zombie_damage_penalty", "0.5", FCVAR_REPLICATED, "The fraction a zombie's damage will be scaled by when they are attacking without using their claws. For example, setting this to 0.25 will let the zombie deal 75% of normal gun damage, and 0.66 will let the zombie deal 33% of normal damage", 0, 1)
CreateConVar("ttt_zombie_damage_reduction", "0", FCVAR_REPLICATED, "The fraction an attacker's bullet damage will be reduced by when they are shooting a zombie", 0, 1)
CreateConVar("ttt_zombie_spit_convert", "0", FCVAR_REPLICATED)

ROLE_CONVARS[ROLE_ZOMBIE] = {}
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_round_chance",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_is_monster",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_is_traitor",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_show_target_icon",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_damage_penalty",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_damage_reduction",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_prime_only_weapons",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_prime_speed_bonus",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_thrall_speed_bonus",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_vision_enabled",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_leap_enabled",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_spit_enabled",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_prime_convert_chance",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_thrall_convert_chance",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_respawn_health",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_prime_attack_damage",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_thrall_attack_damage",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_prime_attack_delay",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_thrall_attack_delay",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_friendly_fire",
    type = ROLE_CONVAR_TYPE_DROPDOWN,
    choices = {"Do nothing", "Reflect", "Block"},
    isNumeric = true
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_respawn_block_win",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_can_see_jesters",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_update_scoreboard",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_spit_convert",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_eat_enabled",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_eat_drop_bones",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_eat_timer",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_eat_heal",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_ZOMBIE], {
    cvar = "ttt_zombie_eat_overheal",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
-------------------
-- ROLE FEATURES --
-------------------

ROLE_SHOULD_NOT_DROWN[ROLE_ZOMBIE] = true

local function InitializeEquipment()
    if EquipmentItems then
        local mat_dir = "vgui/ttt/"
        EquipmentItems[ROLE_ZOMBIE] = {
            -- body armor
            { id = EQUIP_ARMOR,
              type = "item_passive",
              material = mat_dir .. "icon_armor",
              name = "item_armor",
              desc = "item_armor_desc"
            },

            -- zombie speed
            { id = EQUIP_SPEED,
              type = "item_passive",
              material = mat_dir .. "icon_speed",
              name = "item_speed",
              desc = "item_speed_desc"
            },

            -- passive regen
            { id = EQUIP_REGEN,
              type = "item_passive",
              material = mat_dir .. "icon_regen",
              name = "item_regen",
              desc = "item_regen_desc"
            }
        }
    end

    if DefaultEquipment then
        DefaultEquipment[ROLE_ZOMBIE] = {
            EQUIP_ARMOR,
            EQUIP_RADAR,
            EQUIP_DISGUISE,
            EQUIP_SPEED,
            EQUIP_REGEN
        }
    end
end
InitializeEquipment()

-- Initialize role features
hook.Add("Initialize", "Zombie_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Zombie_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)

hook.Add("TTTUpdateRoleState", "Zombie_Team_TTTUpdateRoleState", function()
    local is_monster = zombie_is_monster:GetBool()
    -- Zombies cannot be both Monsters and Traitors so don't make them Traitors if they are already Monsters
    local is_traitor = not is_monster and zombie_is_traitor:GetBool()
    MONSTER_ROLES[ROLE_ZOMBIE] = is_monster
    TRAITOR_ROLES[ROLE_ZOMBIE] = is_traitor
    INDEPENDENT_ROLES[ROLE_ZOMBIE] = not is_monster and not is_traitor
end)

-----------------
-- SPEED BONUS --
-----------------

-- Zombies move faster when they have their claws out and if they have the speed perk
hook.Add("TTTSpeedMultiplier", "Zombie_TTTSpeedMultiplier", function(ply, mults)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and WEPS.GetClass(wep) == "weapon_zom_claws" then
        local speed_bonus = 1
        if ply:IsZombiePrime() then
            speed_bonus = speed_bonus + zombie_prime_speed_bonus:GetFloat()
        else
            speed_bonus = speed_bonus + zombie_thrall_speed_bonus:GetFloat()
        end

        if ply:HasEquipmentItem(EQUIP_SPEED) then
            speed_bonus = speed_bonus + 0.15
        end

        table.insert(mults, speed_bonus)
    end
end)