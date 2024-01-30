AddCSLuaFile()

local hook = hook
local player = player
local table = table

local GetAllPlayers = player.GetAll

-- Initialize role features

ROLE_SELECTION_PREDICATE[ROLE_IMPERSONATOR] = function()
    -- Don't allow the impersonator to spawn if there's already a marshal
    for _, p in ipairs(GetAllPlayers()) do
        if p:IsMarshal() then
            return false
        end
    end
    return true
end

-- HandleDetectiveLikePromotion and ROLE_MOVE_ROLE_STATE are defined in detectivelike/shared.lua
-- ROLE_ON_ROLE_ASSIGNED is defined in detectivelike/detectivelike.lua

ROLE_IS_ACTIVE[ROLE_IMPERSONATOR] = function(ply)
    return ply:GetNWBool("HasPromotion", false)
end

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_IMPERSONATOR] = {
            EQUIP_ARMOR,
            EQUIP_RADAR,
            EQUIP_DISGUISE
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Impersonator_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Impersonator_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)

hook.Add("TTTRoleSpawnsArtificially", "Impersonator_TTTRoleSpawnsArtificially", function(role)
    if role == ROLE_IMPERSONATOR and util.CanRoleSpawn(ROLE_MARSHAL) then
        return true
    end
end)

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_impersonator_use_detective_icon", "1", FCVAR_REPLICATED)
CreateConVar("ttt_impersonator_damage_penalty", "0", FCVAR_REPLICATED, "Damage penalty that the impersonator has before being promoted (e.g. 0.5 = 50% less damage)", 0, 1)

ROLE_CONVARS[ROLE_IMPERSONATOR] = {}
table.insert(ROLE_CONVARS[ROLE_IMPERSONATOR], {
    cvar = "ttt_impersonator_damage_penalty",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE_CONVARS[ROLE_IMPERSONATOR], {
    cvar = "ttt_impersonator_use_detective_icon",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_IMPERSONATOR], {
    cvar = "ttt_impersonator_without_detective",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_IMPERSONATOR], {
    cvar = "ttt_impersonator_activation_credits",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_IMPERSONATOR], {
    cvar = "ttt_impersonator_detective_chance",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})