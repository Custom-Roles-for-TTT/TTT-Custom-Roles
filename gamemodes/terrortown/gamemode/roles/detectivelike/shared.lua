AddCSLuaFile()

local net = net

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

local detectives_glow_enable = CreateConVar("ttt_detectives_glow_enable", "0", FCVAR_REPLICATED)

--------------------
-- PLAYER METHODS --
--------------------

local plymeta = FindMetaTable("Player")

function plymeta:HandleDetectiveLikePromotion()
    self:SetNWBool("HasPromotion", true)

    local role = self:GetRole()
    local rolestring = ROLE_STRINGS_RAW[role]
    local convar = "ttt_" .. rolestring .. "_activation_credits"
    if ConVarExists(convar) then
        local credits = GetConVar(convar):GetInt()
        if credits > 0 then
            self:AddCredits(credits)
        end
    end

    -- Give the player their shop items if purchase was delayed
    if DELAYED_SHOP_ROLES[role] and self.bought and cvars.Bool("ttt_" .. rolestring .. "_shop_delay", false) then
        self:GiveDelayedShopItems()
    end

    net.Start("TTT_Promotion")
    net.WriteString(self:Nick())
    net.Broadcast()

    -- The player has been promoted so we need to update their shop
    net.Start("TTT_ResetBuyableWeaponsCache")
    net.Send(self)
end

function plymeta:GetDetectiveLike() return self:IsDetectiveTeam() or ((self:IsDeputy() or self:IsImpersonator()) and self:IsRoleActive()) end
function plymeta:GetDetectiveLikePromotable() return (self:IsDeputy() or self:IsImpersonator()) and not self:IsRoleActive() end
function plymeta:IsActiveDetectiveLike() return self:IsActive() and self:IsDetectiveLike() end

plymeta.IsDetectiveLike = plymeta.GetDetectiveLike
plymeta.IsDetectiveLikePromotable = plymeta.GetDetectiveLikePromotable

ROLETEAM_IS_TARGET_HIGHLIGHTED[ROLE_TEAM_DETECTIVE] = function(ply, tgt)
    if tgt:IsActiveDetectiveLike() then return detectives_glow_enable:GetBool() end
    return false
end