AddCSLuaFile()

local hook = hook
local table = table
local weapons = weapons

-- Parasite respawn modes
PARASITE_RESPAWN_HOST = 0
PARASITE_RESPAWN_BODY = 1
PARASITE_RESPAWN_RANDOM = 2

-- Parasite infection suicide respawn modes
PARASITE_SUICIDE_NONE = 0
PARASITE_SUICIDE_RESPAWN_ALL = 1
PARASITE_SUICIDE_RESPAWN_CONSOLE = 2

-- Initialize role features
local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_PARASITE] = {
            EQUIP_ARMOR,
            EQUIP_RADAR,
            EQUIP_DISGUISE
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Parasite_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Parasite_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)

ROLE_SHOULD_SHOW_SPECTATOR_HUD[ROLE_PARASITE] = function(ply)
    if ply:GetNWBool("ParasiteInfecting") then
        return true
    end
end

hook.Add("TTTUpdateRoleState", "Parasite_Team_TTTUpdateRoleState", function()
    local parasite_is_monster = GetGlobalBool("ttt_parasite_is_monster", false)
    MONSTER_ROLES[ROLE_PARASITE] = parasite_is_monster
    TRAITOR_ROLES[ROLE_PARASITE] = not parasite_is_monster
end)

------------------
-- ROLE WEAPONS --
------------------

hook.Add("TTTUpdateRoleState", "Parasite_TTTUpdateRoleState", function()
    local parasite_cure = weapons.GetStored("weapon_par_cure")
    local fake_cure = weapons.GetStored("weapon_qua_fake_cure")
    if GetConVar("ttt_parasite_enabled"):GetBool() then
        parasite_cure.CanBuy = table.Copy(parasite_cure.CanBuyDefault)
        fake_cure.CanBuy = table.Copy(fake_cure.CanBuyDefault)
    else
        table.Empty(parasite_cure.CanBuy)
        table.Empty(fake_cure.CanBuy)
    end
end)

------------------
-- ROLE CONVARS --
------------------

ROLE_CONVARS[ROLE_PARASITE] = {}
table.insert(ROLE_CONVARS[ROLE_PARASITE], {
    cvar = "ttt_parasite_infection_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PARASITE], {
    cvar = "ttt_parasite_infection_warning_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PARASITE], {
    cvar = "ttt_parasite_infection_transfer",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_PARASITE], {
    cvar = "ttt_parasite_infection_transfer_reset",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_PARASITE], {
    cvar = "ttt_parasite_infection_suicide_mode",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PARASITE], {
    cvar = "ttt_parasite_respawn_mode",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PARASITE], {
    cvar = "ttt_parasite_respawn_health",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PARASITE], {
    cvar = "ttt_parasite_announce_infection",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_PARASITE], {
    cvar = "ttt_parasite_cure_mode",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PARASITE], {
    cvar = "ttt_parasite_cure_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_PARASITE], {
    cvar = "ttt_parasite_infection_saves_lover",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_PARASITE], {
    cvar = "ttt_parasite_is_monster",
    type = ROLE_CONVAR_TYPE_BOOL
})