AddCSLuaFile()

local hook = hook
local table = table
local weapons = weapons

SPY_STEAL_MODE_DISABLE = 0
SPY_STEAL_MODE_KILL = 1
SPY_STEAL_MODE_SEARCH = 2

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_SPY] = {
            "weapon_spy_flaregun",
            "weapon_ttt_sipistol",
            "weapon_ttt_knife",
            EQUIP_ARMOR,
            EQUIP_RADAR,
            EQUIP_DISGUISE
        }
    end
end

InitializeEquipment()

hook.Add("Initialize", "Spy_Shared_Initialize", function()
    InitializeEquipment()

    -- Modifying the knife and silenced pistol so they also show up in the Spy's shop
    -- (If the knife or silenced pistol ever get modified in the future, this should be moved to the weapon SWEP file)
    local roleWeapons = {"weapon_ttt_sipistol", "weapon_ttt_knife"}

    for _, class in ipairs(roleWeapons) do
        local modifiedCanBuy = weapons.Get(class).CanBuy or {}
        table.insert(modifiedCanBuy, ROLE_SPY)
        weapons.GetStored(class).CanBuy = modifiedCanBuy
    end
end)

hook.Add("TTTPrepareRound", "Spy_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_spy_steal_mode", "1", FCVAR_REPLICATED, "When a spy should steal their victim's identity. 0 - Never. 1 - When they kill a player. 2 - When they inspect a body", 0, 2)
CreateConVar("ttt_spy_steal_model", "1", FCVAR_REPLICATED, "Whether the spy should change to the victim's playermodel", 0, 1)
local spy_steal_name = CreateConVar("ttt_spy_steal_name", "1", FCVAR_REPLICATED, "Whether the spy should change to the victim's name (When other players look at the spy and see their info under the crosshair)", 0, 1)
local spy_flare_gun_loadout = CreateConVar("ttt_spy_flare_gun_loadout", "1", FCVAR_REPLICATED, "Whether the spy should have a flare gun given to them when they spawn. Server must be restarted for changes to take effect", 0, 1)
local spy_flare_gun_shop = CreateConVar("ttt_spy_flare_gun_shop", "0", FCVAR_REPLICATED, "Whether the spy should have a flare gun be purchasable in the shop. Server must be restarted for changes to take effect", 0, 1)
local spy_flare_gun_shop_rebuyable = CreateConVar("ttt_spy_flare_gun_shop_rebuyable", "0", FCVAR_REPLICATED, "Whether the spy should be able to purchase the flare gun multiple times (requires \"ttt_spy_flare_gun_shop\" to be enabled). Server must be restarted for changes to take effect", 0, 1)

ROLE_CONVARS[ROLE_SPY] = {}
table.insert(ROLE_CONVARS[ROLE_SPY], {
    cvar = "ttt_spy_steal_mode",
    type = ROLE_CONVAR_TYPE_DROPDOWN,
    choices = {"Disable", "On Kill", "On Body Search"},
    isNumeric = true
})
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
    cvar = "ttt_spy_steal_from_respawning",
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

-----------------
-- ROLE WEAPON --
-----------------

hook.Add("TTTUpdateRoleState", "Spy_Shared_TTTUpdateRoleState", function()
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

----------------
-- ROLE STATE --
----------------

-- Override the player's name in radio messages too
hook.Add("TTTRadioPlayerName", "Spy_TTTRadioPlayerName", function(sender, target)
    if not IsPlayer(sender) or not IsPlayer(target) then return end

    if not spy_steal_name:GetBool() then return end
    if not target:IsActiveSpy() then return end

    local disguiseName = target:GetNWString("TTTSpyDisguiseName", "")
    if not disguiseName or #disguiseName == 0 then return end

    return disguiseName
end)