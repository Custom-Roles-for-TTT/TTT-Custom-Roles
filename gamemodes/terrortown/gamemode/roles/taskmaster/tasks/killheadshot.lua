local hook = hook
local player = player

local PlayerIterator = player.Iterator

local TASK = {}

TASK.id = "killheadshot"
TASK.isKillTask = true

TASK.Name = function(ply)
    return "Kill a Player With a Headshot"
end

TASK.Description = function(ply)
    return "Kill another player by shooting them in the head"
end

if SERVER then
    TASK.CanAssignTask = function(ply)
        local allHaveHeadbox = true
        for _, p in PlayerIterator() do
            local missingHeadbox = true
            local set = p:GetHitboxSet()
            for hitbox = 0, p:GetHitBoxCount(set) - 1 do
                if p:GetHitBoxHitGroup(hitbox, set) == HITGROUP_HEAD then
                    missingHeadbox = false
                    break
                end
            end
            if missingHeadbox then
                allHaveHeadbox = false
                break
            end
        end
        return allHaveHeadbox
    end

    TASK.RequiredFeatures = {}

    TASK.OnTaskAssigned = function(ply)
        hook.Add("PlayerDeath", "Taskmaster_KillHeadshot_PlayerDeath_" .. ply:SteamID64(), function(victim, inflictor, attacker)
            if not IsPlayer(victim) then return end
            if not IsPlayer(attacker) or not attacker:IsActiveTaskmaster() or attacker ~= ply then return end

            if victim:GetNWBool("LastHitCrit") then
                ply:CompleteTask(TASK.id)
            end
        end)
    end

    TASK.OnTaskRemoved = function(ply)
        hook.Remove("PlayerDeath", "Taskmaster_KillHeadshot_PlayerDeath_" .. ply:SteamID64())
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

TASKMASTER.RegisterTask(TASK)