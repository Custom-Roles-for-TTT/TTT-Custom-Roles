-- Vampire prime death modes
VAMPIRE_DEATH_NONE = 0
VAMPIRE_DEATH_KILL_CONVERED = 1
VAMPIRE_DEATH_REVERT_CONVERTED = 2

-- Initialize role features
hook.Add("Initialize", "Vampire_Shared_Initialize", function()
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

    DefaultEquipment[ROLE_VAMPIRE] = {
        EQUIP_ARMOR,
        EQUIP_RADAR,
        EQUIP_DISGUISE
    }
end)

hook.Add("TTTUpdateRoleState", "Vampire_Team_TTTUpdateRoleState", function()
    local vampires_are_monsters = GetGlobalBool("ttt_vampires_are_monsters", false)
    -- Vampires cannot be both Monsters and Independents so don't make them Independents if they are already Monsters
    local vampires_are_independent = not vampires_are_monsters and GetGlobalBool("ttt_vampires_are_independent", false)
    MONSTER_ROLES[ROLE_VAMPIRE] = vampires_are_monsters
    TRAITOR_ROLES[ROLE_VAMPIRE] = not vampires_are_monsters and not vampires_are_independent
    INDEPENDENT_ROLES[ROLE_VAMPIRE] = vampires_are_independent
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