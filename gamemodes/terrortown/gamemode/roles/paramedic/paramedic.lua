AddCSLuaFile()

-------------
-- CONVARS --
-------------

local ttt_paramedic_defib_as_innocent = CreateConVar("ttt_paramedic_defib_as_innocent", "0")
local ttt_paramedic_device_loadout = CreateConVar("ttt_paramedic_device_loadout", "1")
local ttt_paramedic_device_shop = CreateConVar("ttt_paramedic_device_shop", "0")

hook.Add("TTTSyncGlobals", "Paramedic_TTTSyncGlobals", function()
    SetGlobalBool("ttt_paramedic_defib_as_innocent", ttt_paramedic_defib_as_innocent:GetBool())
    SetGlobalBool("ttt_paramedic_device_loadout", ttt_paramedic_device_loadout:GetBool())
    SetGlobalBool("ttt_paramedic_device_shop", ttt_paramedic_device_shop:GetBool())
end)