AddCSLuaFile()

local hook = hook
local player = player
local table = table

local GetAllPlayers = player.GetAll

-- Initialize role features

ROLE_SELECTION_PREDICATE[ROLE_DEPUTY] = function()
    -- Don't allow the deputy to spawn if there's already a marshal
    for _, p in ipairs(GetAllPlayers()) do
        if p:IsMarshal() then
            return false
        end
    end
    return true
end

-- HandleDetectiveLikePromotion and ROLE_MOVE_ROLE_STATE are defined in detectivelike/shared.lua
-- ROLE_ON_ROLE_ASSIGNED is defined in detectivelike/detectivelike.lua

ROLE_IS_ACTIVE[ROLE_DEPUTY] = function(ply)
    return ply:GetNWBool("HasPromotion", false)
end

local function InitializeEquipment()
    if EquipmentItems then
        if not EquipmentItems[ROLE_DEPUTY] then
            EquipmentItems[ROLE_DEPUTY] = {}
        end

        local mat_dir = "vgui/ttt/"
        -- If we haven't already registered these items, add them to the list
        if not table.HasItemWithPropertyValue(EquipmentItems[ROLE_DEPUTY], "id", EQUIP_ARMOR) then
            table.insert(EquipmentItems[ROLE_DEPUTY], {
                id = EQUIP_ARMOR,
                type = "item_passive",
                material = mat_dir .. "icon_armor",
                name = "item_armor",
                desc = "item_armor_desc"
            })
        end

        if not table.HasItemWithPropertyValue(EquipmentItems[ROLE_DEPUTY], "id", EQUIP_RADAR) then
            table.insert(EquipmentItems[ROLE_DEPUTY], {
                id = EQUIP_RADAR,
                type = "item_active",
                material = mat_dir .. "icon_radar",
                name = "item_radar",
                desc = "item_radar_desc"
            })
        end
    end

    if DefaultEquipment then
        DefaultEquipment[ROLE_DEPUTY] = {
            EQUIP_ARMOR,
            EQUIP_RADAR
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Deputy_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Deputy_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)

hook.Add("TTTRoleSpawnsArtificially", "Deputy_TTTRoleSpawnsArtificially", function(role)
    if role == ROLE_DEPUTY and GetConVar("ttt_marshal_enabled"):GetBool() then
        return true
    end
end)

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_deputy_use_detective_icon", "1", FCVAR_REPLICATED)
CreateConVar("ttt_deputy_damage_penalty", "0", FCVAR_REPLICATED, "Damage penalty that the deputy has before being promoted (e.g. 0.5 = 50% less damage)", 0, 1)

ROLE_CONVARS[ROLE_DEPUTY] = {}
table.insert(ROLE_CONVARS[ROLE_DEPUTY], {
    cvar = "ttt_deputy_damage_penalty",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_DEPUTY], {
    cvar = "ttt_deputy_use_detective_icon",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_DEPUTY], {
    cvar = "ttt_deputy_without_detective",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_DEPUTY], {
    cvar = "ttt_deputy_activation_credits",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})