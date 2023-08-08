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

CreateConVar("ttt_hivemind_vision_enable", "1", FCVAR_REPLICATED)
CreateConVar("ttt_hivemind_friendly_fire", "0", FCVAR_REPLICATED)
local hivemind_is_monster = CreateConVar("ttt_hivemind_is_monster", "0", FCVAR_REPLICATED)

ROLE_CONVARS[ROLE_HIVEMIND] = {}
TableInsert(ROLE_CONVARS[ROLE_HIVEMIND], {
    cvar = "ttt_hivemind_vision_enable",
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

-------------------
-- ROLE FEATURES --
-------------------

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

        -- Bust the weapons cache for all players so the weapons show in the shop and they can buy them
        for _, p in ipairs(GetAllPlayers()) do
            if not p:IsHiveMind() then continue end
            -- Bust the shop cache
            p:ConCommand("ttt_reset_weapons_cache")
        end
    end
end)

AddHook("TTTPrepareRound", "HiveMind_ShopSync_PrepareRound", function()
    table.Empty(ROLE_SHOP_SYNC_ROLES[ROLE_HIVEMIND])
end)