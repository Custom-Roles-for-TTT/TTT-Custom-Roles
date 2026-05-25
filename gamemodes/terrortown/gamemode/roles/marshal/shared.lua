AddCSLuaFile()

local hook = hook
local player = player

local PlayerIterator = player.Iterator

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_marshal_monster_deputy_chance", "0.5", FCVAR_REPLICATED, "The chance that a monster will become a deputy. -1 to disable", -1, 1)
CreateConVar("ttt_marshal_jester_deputy_chance", "0.5", FCVAR_REPLICATED, "The chance that a jester will become a deputy. -1 to disable", -1, 1)
CreateConVar("ttt_marshal_independent_deputy_chance", "0.5", FCVAR_REPLICATED, "The chance that an independent will become a deputy. -1 to disable", -1, 1)
CreateConVar("ttt_marshal_announce_deputy", "1", FCVAR_REPLICATED, "Whether a player being deputized will be announced to everyone", 0, 1)
local marshal_prevent_deputy = CreateConVar("ttt_marshal_prevent_deputy", "1", FCVAR_REPLICATED, "Whether to only spawn the marshal when there isn't already a deputy or impersonator in the round", 0, 1)
CreateConVar("ttt_marshal_badge_loadout", "1", FCVAR_REPLICATED)
CreateConVar("ttt_marshal_badge_shop", "0", FCVAR_REPLICATED)
CreateConVar("ttt_marshal_badge_shop_rebuyable", "0", FCVAR_REPLICATED)

ROLE_CONVARS[ROLE_MARSHAL] = {}
table.insert(ROLE_CONVARS[ROLE_MARSHAL], {
    cvar = "ttt_marshal_monster_deputy_chance",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_MARSHAL], {
    cvar = "ttt_marshal_jester_deputy_chance",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_MARSHAL], {
    cvar = "ttt_marshal_independent_deputy_chance",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_MARSHAL], {
    cvar = "ttt_marshal_announce_deputy",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_MARSHAL], {
    cvar = "ttt_marshal_prevent_deputy",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_MARSHAL], {
    cvar = "ttt_marshal_badge_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_MARSHAL], {
    cvar = "ttt_marshal_badge_loadout",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_MARSHAL], {
    cvar = "ttt_marshal_badge_shop",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_MARSHAL], {
    cvar = "ttt_marshal_badge_shop_rebuyable",
    type = ROLE_CONVAR_TYPE_BOOL
})

-----------------
-- ROLE WEAPON --
-----------------

hook.Add("TTTUpdateRoleState", "Marshal_TTTUpdateRoleState", function()
    local marshal_badge = weapons.GetStored("weapon_mhl_badge")
    if GetConVar("ttt_marshal_badge_loadout"):GetBool() then
        marshal_badge.InLoadoutFor = table.Copy(marshal_badge.InLoadoutForDefault)
    else
        table.Empty(marshal_badge.InLoadoutFor)
    end
    if GetConVar("ttt_marshal_badge_shop"):GetBool() then
        marshal_badge.CanBuy = {ROLE_MARSHAL}
        marshal_badge.LimitedStock = not GetConVar("ttt_marshal_badge_shop_rebuyable"):GetBool()
    else
        marshal_badge.CanBuy = nil
        marshal_badge.LimitedStock = true
    end
end)

-------------------
-- ROLE FEATURES --
-------------------

ROLE_SELECTION_PREDICATE[ROLE_MARSHAL] = function()
    if not marshal_prevent_deputy:GetBool() then return true end

    -- Don't allow the marshal to spawn if there's already a deputy or impersonator
    for _, p in PlayerIterator() do
        if p:IsDeputy() or p:IsImpersonator() then
            return false
        end
    end
    return true
end

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_MARSHAL] = {
            EQUIP_ARMOR,
            EQUIP_RADAR
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Marshal_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Marshal_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)