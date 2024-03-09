-- Put this script in the "garrysmod/lua/autorun" directory of your GMod install.

if engine.ActiveGamemode() ~= "terrortown" then return end

AddCSLuaFile()

if not CLIENT then return end

local hook = hook
local table = table

local AddHook = hook.Add
local TableHasValue = table.HasValue

print("[EQUIPFIX] Loading...")

local function ApplyFixes()
    print("[EQUIPFIX] Applying fixes...")

    -- Zombie Perk Bottles by Hagen (https://steamcommunity.com/sharedfiles/filedetails/?id=842302491)
    AddHook("TTTBodySearchEquipment", "DoubleTapCorpseIcon", function(search, eq)
        search.eq_doubletap = TableHasValue(eq, EQUIP_DOUBLETAP)
    end)

    AddHook("TTTBodySearchEquipment", "JuggernogCorpseIcon", function(search, eq)
        search.eq_juggernog = TableHasValue(eq, EQUIP_JUGGERNOG)
    end)

    AddHook("TTTBodySearchEquipment", "PHDCorpseIcon", function(search, eq)
        search.eq_phd = TableHasValue(eq, EQUIP_PHD)
    end)

    AddHook("TTTBodySearchEquipment", "SpeedColaCorpseIcon", function(search, eq)
        search.eq_speedcola = TableHasValue(eq, EQUIP_SPEEDCOLA)
    end)

    AddHook("TTTBodySearchEquipment", "StaminupCorpseIcon", function(search, eq)
        search.eq_staminup = TableHasValue(eq, EQUIP_STAMINUP)
    end)

    -- Blue Bull by Hagen (https://steamcommunity.com/sharedfiles/filedetails/?id=653258161)
    AddHook("TTTBodySearchEquipment", "BlueBullCorpseIcon", function(search, eq)
        search.eq_bluebull = TableHasValue(eq, EQUIP_BLUE_BULL)
    end)

    -- The Little Helper by Hagen (https://steamcommunity.com/sharedfiles/filedetails/?id=676695745)
    AddHook("TTTBodySearchEquipment", "TLHCorpseIcon", function(search, eq)
        search.eq_tlh = TableHasValue(eq, EQUIP_TLH)
    end)

    -- A Second Chance by Hagen (https://steamcommunity.com/sharedfiles/filedetails/?id=672173225)
    AddHook("TTTBodySearchEquipment", "ASCCorpseIcon", function(search, eq)
        search.eq_asc = TableHasValue(eq, EQUIP_ASC)
    end)
end

AddHook("TTTPrepareRound", "EquipFixHooks_Prepare", ApplyFixes)
AddHook("Initialize", "EquipFixHooks_Initialize", ApplyFixes)