local hook = hook

local TASK = {}

TASK.id = "survive"
TASK.CompleteOnRoundEnd = true

TASK.Name = function(ply)
    return "Survive"
end

TASK.Description = function(ply)
    return "Survive until the end of the round"
end

if SERVER then
    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {}

    TASK.OnTaskAssigned = function(ply)
        hook.Add("TTTWinCheckComplete", "Taskmaster_Survive_TTTWinCheckComplete_" .. ply:SteamID64(), function(win)
            if not IsPlayer(ply) then return end
            if not ply:Alive() or ply:IsSpec() then return end
            ply:CompleteTask(TASK.id)
        end)
    end

    TASK.OnTaskRemoved = function(ply)
        hook.Remove("TTTWinCheckComplete", "Taskmaster_Survive_TTTWinCheckComplete_" .. ply:SteamID64())
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

TASKMASTER.RegisterTask(TASK)