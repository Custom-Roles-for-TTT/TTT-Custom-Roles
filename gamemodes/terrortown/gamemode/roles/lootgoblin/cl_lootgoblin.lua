---------------
-- TARGET ID --
---------------

-- Reveal the loot goblin to all players once activated
hook.Add("TTTTargetIDPlayerRoleIcon", "LootGoblin_TTTTargetIDPlayerRoleIcon", function(ply, client, role, noz, colorRole, hideBeggar, showJester, hideBodysnatcher)
    if ply:IsActiveLootGoblin() and ply:GetNWBool("LootGoblinActive", false) then
        return ROLE_LOOTGOBLIN, false
    end
end)

hook.Add("TTTTargetIDPlayerRing", "LootGoblin_TTTTargetIDPlayerRing", function(ent, client, ringVisible)
    if IsPlayer(ent) and ent:IsActiveLootGoblin() and ent:GetNWBool("LootGoblinActive", false) then
        return true, ROLE_COLORS_RADAR[ROLE_LOOTGOBLIN]
    end
end)

hook.Add("TTTTargetIDPlayerText", "LootGoblin_TTTTargetIDPlayerText", function(ent, client, text, clr, secondaryText)
    if IsPlayer(ent) and ent:IsActiveLootGoblin() and ent:GetNWBool("LootGoblinActive", false) then
        return string.upper(ROLE_STRINGS[ROLE_LOOTGOBLIN]), ROLE_COLORS_RADAR[ROLE_LOOTGOBLIN]
    end
end)

----------------
-- SCOREBOARD --
----------------

hook.Add("TTTScoreboardPlayerRole", "LootGoblin_TTTScoreboardPlayerRole", function(ply, client, color, roleFileName)
    if ply:IsActiveLootGoblin() and ply:GetNWBool("LootGoblinActive", false) then
        return ROLE_COLORS_SCOREBOARD[ROLE_LOOTGOBLIN], ROLE_STRINGS_SHORT[ROLE_LOOTGOBLIN]
    end
end)