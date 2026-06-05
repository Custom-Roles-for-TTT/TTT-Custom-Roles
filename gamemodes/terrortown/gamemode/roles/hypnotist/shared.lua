AddCSLuaFile()

local hook = hook
local table = table
local weapons = weapons

local AddHook = hook.Add

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_HYPNOTIST] = {
            "weapon_hyp_brainwash",
            EQUIP_ARMOR,
            EQUIP_RADAR,
            EQUIP_DISGUISE
        }
    end
end
InitializeEquipment()

AddHook("Initialize", "Hypnotist_Shared_Initialize", InitializeEquipment)
AddHook("TTTPrepareRound", "Hypnotist_Shared_TTTPrepareRound", InitializeEquipment)

-----------------
-- ROLE WEAPON --
-----------------

AddHook("TTTUpdateRoleState", "Hypnotist_TTTUpdateRoleState", function()
    local hypnotist_defib = weapons.GetStored("weapon_hyp_brainwash")
    if GetConVar("ttt_hypnotist_device_loadout"):GetBool() then
        hypnotist_defib.InLoadoutFor = table.Copy(hypnotist_defib.InLoadoutForDefault)
    else
        table.Empty(hypnotist_defib.InLoadoutFor)
    end
    if GetConVar("ttt_hypnotist_device_shop"):GetBool() then
        hypnotist_defib.CanBuy = {ROLE_HYPNOTIST}
        hypnotist_defib.LimitedStock = not GetConVar("ttt_hypnotist_device_shop_rebuyable"):GetBool()
    else
        hypnotist_defib.CanBuy = nil
        hypnotist_defib.LimitedStock = true
    end
end)

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_hypnotist_device_loadout", "1", FCVAR_REPLICATED)
CreateConVar("ttt_hypnotist_device_shop", "0", FCVAR_REPLICATED)
CreateConVar("ttt_hypnotist_device_shop_rebuyable", "0", FCVAR_REPLICATED)

ROLE_CONVARS[ROLE_HYPNOTIST] = {
    {
        cvar = "ttt_hypnotist_device_loadout",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_hypnotist_device_shop",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_hypnotist_device_shop_rebuyable",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_hypnotist_convert_detectives",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_hypnotist_device_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_hypnotist_brainwash_muted",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_hypnotist_brainwash_credits",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    }
}