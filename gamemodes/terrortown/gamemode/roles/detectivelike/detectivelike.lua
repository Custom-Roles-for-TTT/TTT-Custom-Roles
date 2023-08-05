AddCSLuaFile()

local hook = hook
local ipairs = ipairs
local pairs = pairs
local util = util

local GetAllPlayers = player.GetAll

util.AddNetworkString("TTT_Promotion")

-------------
-- CONVARS --
-------------

local detectives_credits_timer = CreateConVar("ttt_detectives_credits_timer", "0")

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
            local alive = ply:Alive() and not ply:IsSpec()
            if alive then
                ply:QueueMessage(MSG_PRINTBOTH, "You have been promoted to " .. ROLE_STRINGS[ROLE_DETECTIVE] .. "!")
            end

            -- If the player is an Impersonator, tell all their team members when they get promoted
            if ply:IsImpersonator() then
                for _, v in pairs(GetAllPlayers()) do
                    if v ~= ply and v:IsActiveTraitorTeam() then
                        local message = "The " .. ROLE_STRINGS[ROLE_IMPERSONATOR] .. " has been promoted to " .. ROLE_STRINGS[ROLE_DETECTIVE] .. "!"
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
            if v:IsActive() and v:IsDetectiveLike() then
                v:AddCredits(1)
                LANG.Msg(v, "credit_all", { role = ROLE_STRINGS[v:GetRole()], num = 1 })
            end
        end
    end)
end)

hook.Add("TTTEndRound", "DetectiveLike_TTTEndRound", function()
    timer.Remove("DetectiveCreditTimer")
end)