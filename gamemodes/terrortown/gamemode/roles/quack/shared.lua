AddCSLuaFile()

local hook = hook
local table = table
local weapons = weapons

local AddHook = hook.Add
local CallHook = hook.Call
local TableInsert = table.insert

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_QUACK] = {
            "weapon_ttt_health_station",
            "weapon_doc_cure",
            "weapon_pha_exorcism",
            "weapon_qua_bomb_station",
            "weapon_qua_station_bomb",
            "weapon_qua_fake_cure",
            EQUIP_ARMOR,
            EQUIP_RADAR,
            EQUIP_DISGUISE
        }
    end
end
InitializeEquipment()

AddHook("Initialize", "Quack_Shared_Initialize", InitializeEquipment)
AddHook("TTTPrepareRound", "Quack_Shared_TTTPrepareRound", InitializeEquipment)

------------------
-- ROLE CONVARS --
------------------

local quack_phantom_cure = CreateConVar("ttt_quack_phantom_cure", "0", FCVAR_REPLICATED)
local quack_station_bomb = CreateConVar("ttt_quack_station_bomb", "0", FCVAR_REPLICATED)
local quack_fake_cure_rebuyable = CreateConVar("ttt_quack_fake_cure_rebuyable", "0", FCVAR_REPLICATED, "Whether the fake cure can be bought multiple times", 0, 1)

ROLE_CONVARS[ROLE_QUACK] = {
    {
        cvar = "ttt_quack_fake_cure_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"Kill nobody", "Kill owner", "Kill target"},
        isNumeric = true
    },
    {
        cvar = "ttt_quack_fake_cure_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_quack_fake_cure_rebuyable",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_quack_phantom_cure",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_quack_station_bomb",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_quack_station_bomb_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    }
}

------------------
-- ROLE WEAPONS --
------------------

AddHook("TTTUpdateRoleState", "Quack_TTTUpdateRoleState", function()
    local phantom_device = weapons.GetStored("weapon_pha_exorcism")
    if quack_phantom_cure:GetBool() then
        if not table.HasValue(phantom_device.CanBuy, ROLE_QUACK) then
            TableInsert(phantom_device.CanBuy, ROLE_QUACK)
        end
    elseif table.HasValue(phantom_device.CanBuy, ROLE_QUACK) then
        table.RemoveByValue(phantom_device.CanBuy, ROLE_QUACK)
    end

    local station_bomb = weapons.GetStored("weapon_qua_station_bomb")
    if quack_station_bomb:GetBool() then
        if not table.HasValue(station_bomb.CanBuy, ROLE_QUACK) then
            TableInsert(station_bomb.CanBuy, ROLE_QUACK)
        end
    elseif table.HasValue(station_bomb.CanBuy, ROLE_QUACK) then
        table.RemoveByValue(station_bomb.CanBuy, ROLE_QUACK)
    end

    local fake_cure = weapons.GetStored("weapon_qua_fake_cure")
    if CallHook("TTTCanCureableRoleSpawn") then
        fake_cure.CanBuy = table.Copy(fake_cure.CanBuyDefault)
    else
        table.Empty(fake_cure.CanBuy)
    end

    fake_cure.LimitedStock = not quack_fake_cure_rebuyable:GetBool()
end)