AddCSLuaFile()
local hook = hook
local table = table
local weapons = weapons

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_SPY] = {"weapon_spy_flaregun", "weapon_ttt_sipistol", "weapon_ttt_knife", EQUIP_ARMOR, EQUIP_RADAR, EQUIP_DISGUISE}
    end
end

InitializeEquipment()

hook.Add("Initialize", "Spy_Shared_Initialize", function()
    InitializeEquipment()
end)

hook.Add("TTTPrepareRound", "Spy_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)

-------------
-- CONVARS --
-------------
CreateConVar("ttt_spy_steal_model", "1", {FCVAR_REPLICATED})

CreateConVar("ttt_spy_steal_model_hands", "1", {FCVAR_REPLICATED})

CreateConVar("ttt_spy_steal_model_alert", "1", {FCVAR_REPLICATED})

CreateConVar("ttt_spy_steal_name", "1", {FCVAR_REPLICATED})

local spy_flare_gun_loadout = CreateConVar("ttt_spy_flare_gun_loadout", "1", {FCVAR_REPLICATED})

local spy_flare_gun_shop = CreateConVar("ttt_spy_flare_gun_shop", "0", {FCVAR_REPLICATED})

local spy_flare_gun_shop_rebuyable = CreateConVar("ttt_spy_flare_gun_shop_rebuyable", "0", {FCVAR_REPLICATED})

-----------------
-- ROLE WEAPON --
-----------------
hook.Add("TTTUpdateRoleState", "Spy_TTTUpdateRoleState", function()
    local spy_flare_gun = weapons.GetStored("weapon_spy_flaregun")

    if spy_flare_gun_loadout:GetBool() then
        spy_flare_gun.InLoadoutFor = table.Copy(spy_flare_gun.InLoadoutForDefault)
    else
        table.Empty(spy_flare_gun.InLoadoutFor)
    end

    if spy_flare_gun_shop:GetBool() then
        spy_flare_gun.CanBuy = {ROLE_SPY}

        spy_flare_gun.LimitedStock = not spy_flare_gun_shop_rebuyable:GetBool()
    else
        spy_flare_gun.CanBuy = nil
        spy_flare_gun.LimitedStock = true
    end
end)

------------------
-- ROLE CONVARS --
------------------
ROLE_CONVARS[ROLE_SPY] = {}

table.insert(ROLE_CONVARS[ROLE_SPY], {
    cvar = "ttt_spy_steal_model",
    type = ROLE_CONVAR_TYPE_BOOL
})

table.insert(ROLE_CONVARS[ROLE_SPY], {
    cvar = "ttt_spy_steal_model_hands",
    type = ROLE_CONVAR_TYPE_BOOL
})

table.insert(ROLE_CONVARS[ROLE_SPY], {
    cvar = "ttt_spy_steal_model_alert",
    type = ROLE_CONVAR_TYPE_BOOL
})

table.insert(ROLE_CONVARS[ROLE_SPY], {
    cvar = "ttt_spy_steal_name",
    type = ROLE_CONVAR_TYPE_BOOL
})

table.insert(ROLE_CONVARS[ROLE_SPY], {
    cvar = "ttt_spy_flare_gun_loadout",
    type = ROLE_CONVAR_TYPE_BOOL
})

table.insert(ROLE_CONVARS[ROLE_SPY], {
    cvar = "ttt_spy_flare_gun_shop",
    type = ROLE_CONVAR_TYPE_BOOL
})

table.insert(ROLE_CONVARS[ROLE_SPY], {
    cvar = "ttt_spy_flare_gun_shop_rebuyable",
    type = ROLE_CONVAR_TYPE_BOOL
})