AddCSLuaFile()

-- Role features shared by detective-like roles (Deputy, Impersonator)
local function MoveRoleState(ply)
    if ply:IsRoleActive() then
        if not keep_on_source then ply:SetNWBool("HasPromotion", false) end
        target:HandleDetectiveLikePromotion()
    end
end

ROLE_MOVE_ROLE_STATE[ROLE_DEPUTY] = MoveRoleState
ROLE_MOVE_ROLE_STATE[ROLE_IMPERSONATOR] = MoveRoleState

--------------------
-- PLAYER METHODS --
--------------------

local plymeta = FindMetaTable("Player")

function plymeta:HandleDetectiveLikePromotion()
    self:SetNWBool("HasPromotion", true)

    if self:IsDeputy() then
        local credits = GetConVar("ttt_deputy_activation_credits"):GetInt()
        if credits > 0 then
            self:AddCredits(credits)
        end

        -- Give the deputy their shop items if purchase was delayed
        if self.bought and GetConVar("ttt_deputy_shop_delay"):GetBool() then
            self:GiveDelayedShopItems()
        end
    end

    net.Start("TTT_Promotion")
    net.WriteString(self:Nick())
    net.Broadcast()

    -- The player has been promoted so we need to update their shop
    net.Start("TTT_ResetBuyableWeaponsCache")
    net.Send(self)
end

function plymeta:GetDetectiveLike() return self:IsDetectiveTeam() or ((self:GetDeputy() or self:GetImpersonator()) and self:IsRoleActive()) end
function plymeta:GetDetectiveLikePromotable() return (self:IsDeputy() or self:IsImpersonator()) and not self:IsRoleActive() end
function plymeta:IsActiveDetectiveLike() return self:IsActive() and self:IsDetectiveLike() end

plymeta.IsDetectiveLike = plymeta.GetDetectiveLike
plymeta.IsDetectiveLikePromotable = plymeta.GetDetectiveLikePromotable