AddCSLuaFile()

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