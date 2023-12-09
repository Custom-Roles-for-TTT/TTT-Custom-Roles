AddCSLuaFile()

-- Role features shared by detective-like roles (Deputy, Impersonator)
local function MoveRoleState(ply, target, keep_on_source)
    if ply:IsRoleActive() then
        if not keep_on_source then ply:SetNWBool("HasPromotion", false) end
        target:HandleDetectiveLikePromotion()
    end
end

ROLE_MOVE_ROLE_STATE[ROLE_DEPUTY] = MoveRoleState
ROLE_MOVE_ROLE_STATE[ROLE_IMPERSONATOR] = MoveRoleState

-------------
-- CONVARS --
-------------

local detectives_glow_enabled = CreateConVar("ttt_detectives_glow_enabled", "0", FCVAR_REPLICATED)

--------------------
-- PLAYER METHODS --
--------------------

local plymeta = FindMetaTable("Player")

function plymeta:GetDetectiveLike() return self:IsDetectiveTeam() or (DETECTIVE_LIKE_ROLES[self:GetRole()] and self:IsRoleActive()) end
function plymeta:GetDetectiveLikePromotable() return DETECTIVE_LIKE_ROLES[self:GetRole()] and not self:IsRoleActive() end
function plymeta:IsActiveDetectiveLike() return self:IsActive() and self:IsDetectiveLike() end

plymeta.IsDetectiveLike = plymeta.GetDetectiveLike
plymeta.IsDetectiveLikePromotable = plymeta.GetDetectiveLikePromotable

ROLETEAM_IS_TARGET_HIGHLIGHTED[ROLE_TEAM_DETECTIVE] = function(ply, tgt)
    if tgt:IsActiveDetectiveLike() then return detectives_glow_enabled:GetBool() end
    return false
end