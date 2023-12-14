AddCSLuaFile()

local hook = hook
local ipairs = ipairs
local net = net
local pairs = pairs
local util = util

local CallHook = hook.Call
local GetAllPlayers = player.GetAll

util.AddNetworkString("TTT_Promotion")

-------------
-- CONVARS --
-------------

local detectives_credits_timer = CreateConVar("ttt_detectives_credits_timer", "0")
CreateConVar("ttt_detectives_search_credits", 0, FCVAR_NONE, "How many credits a detective should get for searching a corpse. Set to 0 to disable.", 0, 10)
CreateConVar("ttt_detectives_search_credits_friendly", 0, FCVAR_NONE, "Whether detectives should get credits for searching friendly corpses", 0, 1)
CreateConVar("ttt_detectives_search_credits_share", 0, FCVAR_NONE, "Whether all detectives should get credits for searching corpses. If disabled, only the searching detective gets credits", 0, 1)

-- Server-side functions shared by detective-like roles (Deputy, Impersonator)

-------------------
-- ROLE FEATURES --
-------------------

function ShouldPromoteDetectiveLike()
    -- Promote immediately
    if GetConVar("ttt_deputy_impersonator_start_promoted"):GetBool() then
        return true
    end

    local alive, dead = 0, 0
    for _, p in ipairs(GetAllPlayers()) do
        if p:IsDetectiveTeam() then
            if not p:IsSpec() and p:Alive() then
                alive = alive + 1
            else
                dead = dead + 1
            end
        end
    end

    -- If they should be promoted when any detective has died, promote them if there is a death
    -- If there isn't a death, fall back to the default logic
    if GetConVar("ttt_deputy_impersonator_promote_any_death"):GetBool() and dead > 0 then
        return true
    end

    -- Otherwise, only promote if there are no living detectives
    return alive == 0
end

local function BeginRoleChecks(ply)
    -- If this is a promotable role and they should be promoted, promote them immediately
    -- The logic which handles a detective dying is in the PlayerDeath hook
    if ply:IsDetectiveLikePromotable() and ShouldPromoteDetectiveLike() then
        ply:HandleDetectiveLikePromotion()
    end
end

local function FindAndPromoteDetectiveLike()
    for _, ply in pairs(GetAllPlayers()) do
        if ply:IsDetectiveLikePromotable() then
            local alive = ply:IsActive()
            if alive then
                ply:QueueMessage(MSG_PRINTBOTH, "You have been promoted to " .. ROLE_STRINGS[ROLE_DETECTIVE] .. "!")
            end

            -- If the player is a member of the traitor team, tell all their team members when they get promoted
            if ply:IsTraitorTeam() then
                for _, v in pairs(GetAllPlayers()) do
                    if v ~= ply and v:IsActiveTraitorTeam() then
                        local message = "The " .. ROLE_STRINGS[ply:GetRole()] .. " has been promoted to " .. ROLE_STRINGS[ROLE_DETECTIVE] .. "!"
                        if not alive then
                            message = message .. " Too bad they're dead..."
                        end
                        v:QueueMessage(MSG_PRINTBOTH, message)
                    end
                end
            end

            ply:HandleDetectiveLikePromotion()
        end
    end
end

ROLE_ON_ROLE_ASSIGNED[ROLE_DEPUTY] = BeginRoleChecks
ROLE_ON_ROLE_ASSIGNED[ROLE_IMPERSONATOR] = BeginRoleChecks

hook.Add("TTTPrepareRound", "DetectiveLike_RoleState_TTTPrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        v:SetNWBool("HasPromotion", false)
    end
end)

hook.Add("PlayerDeath", "DetectiveLike_RoleState_PlayerDeath", function(victim, infl, attacker)
    if victim:IsDetectiveTeam() and GetRoundState() == ROUND_ACTIVE and ShouldPromoteDetectiveLike() then
        FindAndPromoteDetectiveLike()
    end
end)

hook.Add("TTTPlayerRoleChanged", "DetectiveLike_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if DETECTIVE_ROLES[oldRole] and GetRoundState() == ROUND_ACTIVE and ShouldPromoteDetectiveLike() then
        FindAndPromoteDetectiveLike()
    end
end)

------------------
-- AUTO CREDITS --
------------------

hook.Add("TTTBeginRound", "DetectiveLike_TTTBeginRound", function()
    local credit_timer = detectives_credits_timer:GetInt()
    if credit_timer <= 0 then return end

    timer.Create("DetectiveCreditTimer", credit_timer, 0, function()
        for _, v in pairs(GetAllPlayers()) do
            if v:IsActiveDetectiveLike() then
                v:AddCredits(1)
                LANG.Msg(v, "credit_all", { role = ROLE_STRINGS[v:GetRole()], num = 1 })
            end
        end
    end)
end)

hook.Add("TTTEndRound", "DetectiveLike_TTTEndRound", function()
    timer.Remove("DetectiveCreditTimer")
end)

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

    CallHook("TTTDetectiveLikePromoted", nil, self)
end