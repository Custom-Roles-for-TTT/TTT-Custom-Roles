AddCSLuaFile()

local hook = hook

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_MEDIUM] = {
            EQUIP_ARMOR,
            EQUIP_RADAR
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Medium_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Medium_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)

------------------
-- ROLE CONVARS --
------------------

ROLE_CONVARS[ROLE_MEDIUM] = {}
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_spirit_color",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_spirit_vision",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_MEDIUM], {
    cvar = "ttt_medium_dead_notify",
    type = ROLE_CONVAR_TYPE_BOOL
})