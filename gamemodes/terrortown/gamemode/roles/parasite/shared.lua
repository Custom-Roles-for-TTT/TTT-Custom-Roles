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

hook.Add("Initialize", "Parasite__Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Parasite__Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)

ROLE_SHOULD_SHOW_SPECTATOR_HUD[ROLE_PARASITE] = function(ply)
    if ply:GetNWBool("Infecting") then
        return true
    end
end

------------------
-- ROLE WEAPONS --
------------------

hook.Add("TTTUpdateRoleState", "Parasite__TTTUpdateRoleState", function()
    local parasite_cure = weapons.GetStored("weapon_par_cure")
    local fake_cure = weapons.GetStored("weapon_qua_fake_cure")
    if GetGlobalBool("ttt_parasite_enabled", false) then
        parasite_cure.CanBuy = table.Copy(parasite_cure.CanBuyDefault)
        fake_cure.CanBuy = table.Copy(fake_cure.CanBuyDefault)
    else
        table.Empty(parasite_cure.CanBuy)
        table.Empty(fake_cure.CanBuy)
    end
end)