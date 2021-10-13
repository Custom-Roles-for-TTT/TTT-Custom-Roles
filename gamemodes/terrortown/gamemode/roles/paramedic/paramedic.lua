AddCSLuaFile()

-------------
-- CONVARS --
-------------

CreateConVar("ttt_paramedic_defib_as_innocent", "0")
CreateConVar("ttt_paramedic_device_loadout", "1")
CreateConVar("ttt_paramedic_device_shop", "0")

hook.Add("TTTSyncGlobals", "Paramedic_TTTSyncGlobals", function()
    SetGlobalBool("ttt_paramedic_defib_as_innocent", GetConVar("ttt_paramedic_defib_as_innocent"):GetBool())
    SetGlobalBool("ttt_paramedic_device_loadout", GetConVar("ttt_paramedic_device_loadout"):GetBool())
    SetGlobalBool("ttt_paramedic_device_shop", GetConVar("ttt_paramedic_device_shop"):GetBool())
end)