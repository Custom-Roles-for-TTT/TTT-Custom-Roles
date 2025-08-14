local hook = hook

local TASK = {}

TASK.id = "killmidair"
TASK.isKillTask = true

TASK.Name = function(ply)
    return "Kill a Player While Midair"
end

TASK.Description = function(ply)
    return "Kill another player while you are in the air"
end

if SERVER then
    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {}

    TASK.OnTaskAssigned = function(ply)
        hook.Add("PlayerDeath", "Taskmaster_KillMidair_PlayerDeath_" .. ply:SteamID64(), function(victim, inflictor, attacker)
            if not IsPlayer(victim) then return end
            if not IsPlayer(attacker) or not attacker:IsActiveTaskmaster() or attacker ~= ply then return end

            if not attacker:OnGround() then
                ply:CompleteTask(TASK.id)
            end
        end)
    end

    TASK.OnTaskRemoved = function(ply)
        hook.Remove("PlayerDeath", "Taskmaster_KillMidair_PlayerDeath_" .. ply:SteamID64())
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

TASKMASTER.RegisterTask(TASK)