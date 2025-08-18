local hook = hook

local TASK = {}

TASK.id = "killaiming"
TASK.IsKillTask = true

TASK.Name = function(ply)
    return "Kill a Player While Aiming"
end

TASK.Description = function(ply)
    return "Kill another player while aiming down sights"
end

if SERVER then
    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {}

    TASK.OnTaskAssigned = function(ply)
        hook.Add("PlayerDeath", "Taskmaster_KillAiming_PlayerDeath_" .. ply:SteamID64(), function(victim, inflictor, attacker)
            if not IsPlayer(victim) then return end
            if not IsPlayer(attacker) or not attacker:IsActiveTaskmaster() or attacker ~= ply then return end

            if IsValid(inflictor) and inflictor:IsWeapon() and inflictor.GetIronsights and inflictor:GetIronsights() then
                ply:CompleteTask(TASK.id)
            end
        end)
    end

    TASK.OnTaskRemoved = function(ply)
        hook.Remove("PlayerDeath", "Taskmaster_KillAiming_PlayerDeath_" .. ply:SteamID64())
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

TASKMASTER.RegisterTask(TASK)