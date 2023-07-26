AddCSLuaFile()

local hook = hook
local table = table
local weapons = weapons

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_TRAITOR] = {
            "weapon_ttt_c4",
            "weapon_ttt_flaregun",
            "weapon_ttt_knife",
            "weapon_ttt_phammer",
            "weapon_ttt_push",
            "weapon_ttt_radio",
            "weapon_ttt_sipistol",
            "weapon_ttt_teleport",
            "weapon_ttt_decoy",
            "weapon_pha_exorcism",
            EQUIP_ARMOR,
            EQUIP_RADAR,
            EQUIP_DISGUISE
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Traitor_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Traitor_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)

------------------
-- ROLE CONVARS --
------------------

local traitor_phantom_cure = CreateConVar("ttt_traitor_phantom_cure", "0", FCVAR_REPLICATED)

ROLE_CONVARS[ROLE_TRAITOR] = {}
table.insert(ROLE_CONVARS[ROLE_TRAITOR], {
    cvar = "ttt_traitor_phantom_cure",
    type = ROLE_CONVAR_TYPE_BOOL
})

------------------
-- ROLE WEAPONS --
------------------

hook.Add("TTTUpdateRoleState", "Traitor_TTTUpdateRoleState", function()
    local phantom_device = weapons.GetStored("weapon_pha_exorcism")
    if traitor_phantom_cure:GetBool() then
        if not table.HasValue(phantom_device.CanBuy, ROLE_TRAITOR) then
            table.insert(phantom_device.CanBuy, ROLE_TRAITOR)
        end
    elseif table.HasValue(phantom_device.CanBuy, ROLE_TRAITOR) then
        table.RemoveByValue(phantom_device.CanBuy, ROLE_TRAITOR)
    end
end)

--------------------
-- PLAYER METHODS --
--------------------

ROLETEAM_IS_TARGET_HIGHLIGHTED[ROLE_TEAM_TRAITOR] = function(ply, tgt)
    local traitor_vision = GetConVar("ttt_traitors_vision_enable"):GetBool()
    if ply:IsActiveTraitorTeam() and tgt:IsActiveTraitorTeam() then return traitor_vision end
    if ply:IsActiveTraitorTeam() and tgt:IsActiveJesterTeam() then return traitor_vision and GetConVar("ttt_jesters_visible_to_traitors"):GetBool() end
    return false
end