AddCSLuaFile()

-------------
-- CONVARS --
-------------

local paramedic_defib_as_innocent = CreateConVar("ttt_paramedic_defib_as_innocent", "0")
local paramedic_device_loadout = CreateConVar("ttt_paramedic_device_loadout", "1")
local paramedic_device_shop = CreateConVar("ttt_paramedic_device_shop", "0")
local paramedic_device_shop_rebuyable = CreateConVar("ttt_paramedic_device_shop_rebuyable", "0")

hook.Add("TTTSyncGlobals", "Paramedic_TTTSyncGlobals", function()
    SetGlobalBool("ttt_paramedic_defib_as_innocent", paramedic_defib_as_innocent:GetBool())
    SetGlobalBool("ttt_paramedic_device_loadout", paramedic_device_loadout:GetBool())
    SetGlobalBool("ttt_paramedic_device_shop", paramedic_device_shop:GetBool())
    SetGlobalBool("ttt_paramedic_device_shop_rebuyable", paramedic_device_shop_rebuyable:GetBool())
end)