AddCSLuaFile()

local table = table

local TableInsert = table.insert

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_quartermaster_limited_loot", "0", FCVAR_REPLICATED)

ROLE_CONVARS[ROLE_QUARTERMASTER] = {}
TableInsert(ROLE_CONVARS[ROLE_QUARTERMASTER], {
    cvar = "ttt_quartermaster_limited_loot",
    type = ROLE_CONVAR_TYPE_BOOL
})

-------------------
-- ROLE FEATURES --
-------------------

ROLE_SHOP_SYNC_ROLES[ROLE_QUARTERMASTER] = {ROLE_TRAITOR}
ROLE_STARTING_CREDITS[ROLE_QUARTERMASTER] = 3