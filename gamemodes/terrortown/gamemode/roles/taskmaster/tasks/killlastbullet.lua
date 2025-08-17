local hook = hook

local TASK = {}

TASK.id = "killlastbullet"
TASK.isKillTask = true

TASK.Name = function(ply)
    return "Kill a Player With Your Last Bullet"
end

TASK.Description = function(ply)
    return "Kill another player with the last bullet in your gun's clip"
end

if SERVER then
    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {}

    TASK.OnTaskAssigned = function(ply)
        hook.Add("PlayerDeath", "Taskmaster_KillLastBullet_PlayerDeath_" .. ply:SteamID64(), function(victim, inflictor, attacker)
            if not IsPlayer(victim) then return end
            if not IsPlayer(attacker) or not attacker:IsActiveTaskmaster() or attacker ~= ply then return end

            timer.Simple(0, function()
                if IsValid(inflictor) and inflictor:IsWeapon() and inflictor:GetMaxClip1() > 0 and inflictor:Clip1() == 0 then
                    ply:CompleteTask(TASK.id)
                end
            end)
        end)
    end

    TASK.OnTaskRemoved = function(ply)
        hook.Remove("PlayerDeath", "Taskmaster_KillLastBullet_PlayerDeath_" .. ply:SteamID64())
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

TASKMASTER.RegisterTask(TASK)