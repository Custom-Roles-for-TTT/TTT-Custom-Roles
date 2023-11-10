AddCSLuaFile()

local hook = hook
local player = player
local table = table

local AddHook = hook.Add
local GetAllPlayers = player.GetAll
local TableInsert = table.insert

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_hivemind_vision_enabled", "1", FCVAR_REPLICATED)
CreateConVar("ttt_hivemind_friendly_fire", "0", FCVAR_REPLICATED)
local hivemind_is_monster = CreateConVar("ttt_hivemind_is_monster", "0", FCVAR_REPLICATED)
CreateConVar("ttt_hivemind_join_heal_pct", 0.25, FCVAR_REPLICATED, "The percentage a new member's maximum health that the hive mind should be healed (e.g. 0.25 = 25% of their health healed)", 0, 1)
CreateConVar("ttt_hivemind_regen_timer", 0, FCVAR_REPLICATED, "The amount of time (in seconds) between each health regeneration", 0, 180)
CreateConVar("ttt_hivemind_regen_per_member_amt", 1, FCVAR_REPLICATED, "The amount of health per-member of the hive mind that they should regenerate over time", 1, 20)
CreateConVar("ttt_hivemind_regen_max_pct", 0.5, FCVAR_REPLICATED, "The percentage of the hive mind's maximum health to heal them up to (e.g. 0.5 = 50% of their max health)", 0.1, 1)

ROLE_CONVARS[ROLE_HIVEMIND] = {}
TableInsert(ROLE_CONVARS[ROLE_HIVEMIND], {
    cvar = "ttt_hivemind_vision_enabled",
    type = ROLE_CONVAR_TYPE_BOOL
})
TableInsert(ROLE_CONVARS[ROLE_HIVEMIND], {
    cvar = "ttt_hivemind_friendly_fire",
    type = ROLE_CONVAR_TYPE_BOOL
})
TableInsert(ROLE_CONVARS[ROLE_HIVEMIND], {
    cvar = "ttt_hivemind_is_monster",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_HIVEMIND], {
    cvar = "ttt_hivemind_join_heal_pct",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_HIVEMIND], {
    cvar = "ttt_hivemind_regen_per_member_amt",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_HIVEMIND], {
    cvar = "ttt_hivemind_regen_timer",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_HIVEMIND], {
    cvar = "ttt_hivemind_regen_max_pct",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})

-------------------
-- ROLE FEATURES --
-------------------

ROLE_VICTIM_CHANGING_ROLE[ROLE_HIVEMIND] = function(ply, victim)
    return not victim:IsHiveMind()
end

AddHook("TTTUpdateRoleState", "HiveMind_Team_TTTUpdateRoleState", function()
    local is_monster = hivemind_is_monster:GetBool()
    MONSTER_ROLES[ROLE_HIVEMIND] = is_monster
    INDEPENDENT_ROLES[ROLE_HIVEMIND] = not is_monster
end)

ROLE_SHOP_SYNC_ROLES[ROLE_HIVEMIND] = {}

AddHook("TTTPlayerRoleChanged", "HiveMind_ShopSync_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if GetRoundState() ~= ROUND_ACTIVE then return end
    if oldRole == ROLE_HIVEMIND or newRole ~= ROLE_HIVEMIND then return end
    -- Don't bother checking if the player is alive since this happens right after
    -- they die and by the time this hook is called on the client they haven't been respawned yet

    -- Add any new (valid) role to the list of shop sync roles
    if oldRole ~= ROLE_NONE and not table.HasValue(ROLE_SHOP_SYNC_ROLES[ROLE_HIVEMIND], oldRole) then
        TableInsert(ROLE_SHOP_SYNC_ROLES[ROLE_HIVEMIND], oldRole)

        if SERVER and WEPS.DoesRoleHaveWeapon(oldRole) then
            -- Bust the weapons cache for all players so the weapons show in the shop and they can buy them
            for _, p in ipairs(GetAllPlayers()) do
                if not p:IsHiveMind() then continue end
                -- Bust the shop cache
                p:ConCommand("ttt_reset_weapons_cache")

                -- Let the existing players know there might be new weapons
                if ply ~= p then
                    timer.Simple(0.25, function()
                        -- Sanity check
                        if not IsPlayer(p) or not p:IsActiveHiveMind() then return end
                        p:QueueMessage(MSG_PRINTCENTER, "New weapons from the assimilated player are now available in your shop")
                    end)
                end
            end
        end
    end
end)

AddHook("TTTPrepareRound", "HiveMind_ShopSync_PrepareRound", function()
    table.Empty(ROLE_SHOP_SYNC_ROLES[ROLE_HIVEMIND])
end)