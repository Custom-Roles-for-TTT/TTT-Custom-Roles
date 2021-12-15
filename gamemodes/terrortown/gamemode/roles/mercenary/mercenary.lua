AddCSLuaFile()

local hook = hook

-------------
-- CONVARS --
-------------

-- Create this here since it wouldn't normally get created and has a different default value anyway
local mercenary_shop_mode = CreateConVar("ttt_mercenary_shop_mode", "2")

hook.Add("TTTSyncGlobals", "Mercenary_TTTSyncGlobals", function()
    SetGlobalInt("ttt_mercenary_shop_mode", mercenary_shop_mode:GetInt())
end)