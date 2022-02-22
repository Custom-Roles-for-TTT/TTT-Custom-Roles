AddCSLuaFile()

local hook = hook
local table = table

-- Initialize role features

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

------------------
-- ROLE CONVARS --
------------------

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