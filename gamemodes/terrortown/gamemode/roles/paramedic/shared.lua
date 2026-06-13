AddCSLuaFile()

local hook = hook
local table = table
local weapons = weapons

local AddHook = hook.Add

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_PARAMEDIC] = {
            "weapon_med_defib"
        }
    end
end
InitializeEquipment()

AddHook("Initialize", "Paramedic_Shared_Initialize", InitializeEquipment)
AddHook("TTTPrepareRound", "Paramedic_Shared_TTTPrepareRound", InitializeEquipment)

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_paramedic_defib_as_innocent", "0", FCVAR_REPLICATED, "Whether the paramedic's defib brings back everyone as a vanilla innocent role", 0, 1)
CreateConVar("ttt_paramedic_defib_as_is", "0", FCVAR_REPLICATED, "Whether the paramedic's defib brings back everyone as their previous role", 0, 1)
CreateConVar("ttt_paramedic_defib_detectives_as_deputy", "0", FCVAR_REPLICATED, "Whether the paramedic's defib brings back detective roles as a promoted deputy", 0, 1)
local paramedic_device_loadout = CreateConVar("ttt_paramedic_device_loadout", "1", FCVAR_REPLICATED, "Whether the paramedic's defib should be given to them when they spawn", 0, 1)
local paramedic_device_shop = CreateConVar("ttt_paramedic_device_shop", "0", FCVAR_REPLICATED, "Whether the paramedic's defib should be purchasable in the shop", 0, 1)
local paramedic_device_shop_rebuyable = CreateConVar("ttt_paramedic_device_shop_rebuyable", "0", FCVAR_REPLICATED, "Whether the paramedic's defib should be purchaseable multiple times", 0, 1)

ROLE_CONVARS[ROLE_PARAMEDIC] = {
    {
        cvar = "ttt_paramedic_defib_as_innocent",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_paramedic_defib_as_is",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_paramedic_defib_detectives_as_deputy",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_paramedic_device_loadout",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_paramedic_device_shop",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_paramedic_device_shop_rebuyable",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_paramedic_defib_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    }
}

------------------
-- ROLE WEAPONS --
------------------

AddHook("TTTUpdateRoleState", "Paramedic_TTTUpdateRoleState", function()
    local paramedic_defib = weapons.GetStored("weapon_med_defib")
    if paramedic_device_loadout:GetBool() then
        paramedic_defib.InLoadoutFor = table.Copy(paramedic_defib.InLoadoutForDefault)
    else
        table.Empty(paramedic_defib.InLoadoutFor)
    end
    if paramedic_device_shop:GetBool() then
        paramedic_defib.CanBuy = {ROLE_PARAMEDIC}
        paramedic_defib.LimitedStock = not paramedic_device_shop_rebuyable:GetBool()
    else
        paramedic_defib.CanBuy = nil
        paramedic_defib.LimitedStock = true
    end
end)