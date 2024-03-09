if engine.ActiveGamemode() ~= "terrortown" then return end

AddCSLuaFile()

if not CLIENT then return end

print("[PERKFIX] Loading...")

local function ApplyFixes()
    print("[PERKFIX] Applying fixes...")

    hook.Add("TTTBodySearchEquipment", "DoubleTapCorpseIcon", function(search, eq)
        search.eq_doubletap = table.HasValue(eq, EQUIP_DOUBLETAP)
    end)

    hook.Add("TTTBodySearchEquipment", "JuggernogCorpseIcon", function(search, eq)
        search.eq_juggernog = table.HasValue(eq, EQUIP_JUGGERNOG)
    end)

    hook.Add("TTTBodySearchEquipment", "PHDCorpseIcon", function(search, eq)
        search.eq_phd = table.HasValue(eq, EQUIP_PHD)
    end)

    hook.Add("TTTBodySearchEquipment", "SpeedColaCorpseIcon", function(search, eq)
        search.eq_speedcola = table.HasValue(eq, EQUIP_SPEEDCOLA)
    end)

    hook.Add("TTTBodySearchEquipment", "StaminupCorpseIcon", function(search, eq)
        search.eq_staminup = table.HasValue(eq, EQUIP_STAMINUP)
    end)

    hook.Add("TTTBodySearchEquipment", "BlueBullCorpseIcon", function(search, eq)
        search.eq_bluebull = table.HasValue(eq, EQUIP_BLUE_BULL)
    end )
end

hook.Add("TTTPrepareRound", "PerkFixHooks_Prepare", ApplyFixes)
hook.Add("Initialize", "PerkFixHooks_Initialize", ApplyFixes)