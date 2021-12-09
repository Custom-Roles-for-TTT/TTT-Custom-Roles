local ipairs = ipairs
local pairs = pairs
local string = string
local table = table

-- This table is used by the client to show items in the equipment menu, and by
-- the server to check if a certain role is allowed to buy a certain item.


-- If you have custom items you want to add, consider using a separate lua
-- script that uses table.insert to add an entry to this table. This method
-- means you won't have to add your code back in after every TTT update. Just
-- make sure the script is also run on the client.
--
-- For example:
--   table.insert(EquipmentItems[ROLE_DETECTIVE], { id = EQUIP_ARMOR, ... })
--
-- Note that for existing items you can just do:
--   table.insert(EquipmentItems[ROLE_DETECTIVE], GetEquipmentItem(ROLE_TRAITOR, EQUIP_ARMOR))


-- Special equipment bitflags. Every unique piece of equipment needs its own
-- id. 
--
-- Use the GenerateNewEquipmentID function (see below) to get a unique ID for
-- your equipment. This is guaranteed not to clash with other addons (as long
-- as they use the same safe method).
--
-- Details you shouldn't need:
-- The number should increase by a factor of two for every item (ie. ids
-- should be powers of two).
EQUIP_NONE = 0
EQUIP_ARMOR = 1
EQUIP_RADAR = 2
EQUIP_DISGUISE = 4
EQUIP_SPEED = 8
EQUIP_REGEN = 16

EQUIP_MAX = 16

-- Icon doesn't have to be in this dir, but all default ones are in here
local mat_dir = "vgui/ttt/"


-- Stick to around 35 characters per description line, and add a "\n" where you
-- want a new line to start.

EquipmentItems = {}

local defaultDetectiveItems = {
    -- body armor
    { id = EQUIP_ARMOR,
      loadout = true, -- default equipment for detectives
      type = "item_passive",
      material = mat_dir .. "icon_armor",
      name = "item_armor",
      desc = "item_armor_desc"
    },

    -- radar
    { id = EQUIP_RADAR,
      type = "item_active",
      material = mat_dir .. "icon_radar",
      name = "item_radar",
      desc = "item_radar_desc"
    }
}
local defaultTraitorItems = {
    -- body armor
    { id = EQUIP_ARMOR,
      type = "item_passive",
      material = mat_dir .. "icon_armor",
      name = "item_armor",
      desc = "item_armor_desc"
    },

    -- radar
    { id = EQUIP_RADAR,
      type = "item_active",
      material = mat_dir .. "icon_radar",
      name = "item_radar",
      desc = "item_radar_desc"
    },

    -- disguiser
    { id = EQUIP_DISGUISE,
      type = "item_active",
      material = mat_dir .. "icon_disguise",
      name = "item_disg",
      desc = "item_disg_desc"
    }
}

-- Populate any role that doesn't already have an equipment list set
local function PrepareRoleEquipment()
    for r = 0, ROLE_MAX do
        if not EquipmentItems[r] then
            if DETECTIVE_ROLES[r] then
                EquipmentItems[r] = table.Copy(defaultDetectiveItems)
            elseif TRAITOR_ROLES[r] then
                EquipmentItems[r] = table.Copy(defaultTraitorItems)
            else
                EquipmentItems[r] = {}
            end
        end
    end
end
PrepareRoleEquipment()

-- Search if an item is in the equipment table of a given role, and return it if
-- it exists, else return nil.
function GetEquipmentItem(role, id)
    local tbl = EquipmentItems[role]
    if not tbl then return end

    for _, v in pairs(tbl) do
        if v and v.id == id then
            return v
        end
    end
end

EquipmentCache = nil
local function PopulateEquipmentCache()
    if EquipmentCache ~= nil then return end

    EquipmentCache = {}
    for _, role_tbl in pairs(EquipmentItems) do
        for _, equip in pairs(role_tbl) do
            if not EquipmentCache[equip.id] then
                EquipmentCache[equip.id] = equip
            end
        end
    end
end

function GetEquipmentItemById(id)
    PopulateEquipmentCache()

    return EquipmentCache[id]
end

function GetEquipmentItemByName(name)
    PopulateEquipmentCache()

    for _, equip in pairs(EquipmentCache) do
        if string.lower(equip.name) == string.lower(name) then
            return equip
        end
    end

    return nil
end

-- Utility function to register a new Equipment ID
function GenerateNewEquipmentID()
    EQUIP_MAX = EQUIP_MAX * 2
    return EQUIP_MAX
end

local function LoadMonsterRoleEquipment(role, radar)
    if not table.HasValue(DefaultEquipment[role], EQUIP_RADAR) then
        table.insert(DefaultEquipment[role], EQUIP_RADAR)
    end

    if GetEquipmentItem(role, EQUIP_RADAR) == nil then
        table.insert(EquipmentItems[role], radar)
    end
end

local function RemoveMonsterRoleEquipment(role)
    for i, v in ipairs(DefaultEquipment[role]) do
        if v == EQUIP_RADAR then
            table.remove(DefaultEquipment[role], i)
        end
    end

    for i, v in ipairs(EquipmentItems[role]) do
        if v.id == EQUIP_RADAR then
            table.remove(EquipmentItems[role], i)
        end
    end
end

function LoadMonsterEquipment(zombies_are_traitors, vampires_are_traitors)
    local radar = GetEquipmentItem(ROLE_TRAITOR, EQUIP_RADAR)

    -- Allow Monsters to buy Radar if they are members of the Traitor team
    if zombies_are_traitors then
        LoadMonsterRoleEquipment(ROLE_ZOMBIE, radar)
    else
        RemoveMonsterRoleEquipment(ROLE_ZOMBIE)
    end

    if vampires_are_traitors then
        LoadMonsterRoleEquipment(ROLE_VAMPIRE, radar)
    else
        RemoveMonsterRoleEquipment(ROLE_VAMPIRE)
    end
end