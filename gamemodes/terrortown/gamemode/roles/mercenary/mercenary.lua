AddCSLuaFile()

-------------
-- CONVARS --
-------------

-- Create this here since it wouldn't normally get created and has a different default value anyway
CreateConVar("ttt_mercenary_shop_mode", "2")

hook.Add("TTTSyncGlobals", "Mercenary_TTTSyncGlobals", function()
    SetGlobalInt("ttt_mercenary_shop_mode", GetConVar("ttt_mercenary_shop_mode"):GetInt())
end)