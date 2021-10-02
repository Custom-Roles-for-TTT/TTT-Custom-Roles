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
    local zombies_are_monsters = GetGlobalBool("ttt_zombies_are_monsters", false)
    -- Zombies cannot be both Monsters and Traitors so don't make them Traitors if they are already Monsters
    local zombies_are_traitors = not zombies_are_monsters and GetGlobalBool("ttt_zombies_are_traitors", false)
    MONSTER_ROLES[ROLE_ZOMBIE] = zombies_are_monsters
    TRAITOR_ROLES[ROLE_ZOMBIE] = zombies_are_traitors
    INDEPENDENT_ROLES[ROLE_ZOMBIE] = not zombies_are_monsters and not zombies_are_traitors
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
    return INDEPENDENT_ROLES[role]
end

plymeta.IsZombiePrime = plymeta.GetZombiePrime
plymeta.IsZombieAlly = plymeta.GetZombieAlly

-----------------
-- SPEED BONUS --
-----------------

-- Zombies move faster when they have their claws out and if they have the speed perk
hook.Add("TTTSpeedMultiplier", "Zombie_TTTSpeedMultiplier", function(ply, mults)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and WEPS.GetClass(wep) == "weapon_zom_claws" then
        local speed_bonus = 1
        if ply:IsZombiePrime() then
            speed_bonus = speed_bonus + GetGlobalFloat("ttt_zombie_prime_speed_bonus", 0.35)
        else
            speed_bonus = speed_bonus + GetGlobalFloat("ttt_zombie_thrall_speed_bonus", 0.15)
        end

        if ply:HasEquipmentItem(EQUIP_SPEED) then
            speed_bonus = speed_bonus + 0.15
        end

        table.insert(mults, speed_bonus)
    end
end)