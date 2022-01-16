AddCSLuaFile()

local hook = hook
local ipairs = ipairs
local pairs = pairs
local util = util

local GetAllPlayers = player.GetAll

util.AddNetworkString("TTT_Promotion")

-- Server-side functions shared by detective-like roles (Deputy, Impersonator)

-------------------
-- ROLE FEATURES --
-------------------

function ShouldPromoteDetectiveLike()
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
            local alive = ply:Alive()
            if alive then
                ply:PrintMessage(HUD_PRINTTALK, "You have been promoted to " .. ROLE_STRINGS[ROLE_DETECTIVE] .. "!")
                ply:PrintMessage(HUD_PRINTCENTER, "You have been promoted to " .. ROLE_STRINGS[ROLE_DETECTIVE] .. "!")
            end

            -- If the player is an Impersonator, tell all their team members when they get promoted
            if ply:IsImpersonator() then
                for _, v in pairs(GetAllPlayers()) do
                    if v ~= ply and v:IsTraitorTeam() and v:Alive() and not v:IsSpec() then
                        local message = "The " .. ROLE_STRINGS[ROLE_IMPERSONATOR] .. " has been promoted to " .. ROLE_STRINGS[ROLE_DETECTIVE] .. "!"
                        if not alive then
                            message = message .. " Too bad they're dead..."
                        end
                        v:PrintMessage(HUD_PRINTTALK, message)
                        v:PrintMessage(HUD_PRINTCENTER, message)
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