local TASK = {}

TASK.id = ""
TASK.IsKillTask = false
TASK.CompleteOnRoundEnd = false

TASK.Name = function(ply)
    return ""
end

TASK.Description = function(ply)
    return ""
end

TASK.Initialize = function()
end

if SERVER then
    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {}

    TASK.OnTaskAssigned = function(ply)
    end

    TASK.OnTaskRemoved = function(ply)
    end

    TASK.OnTaskComplete = function(ply)
    end
end

TASKMASTER.RegisterTask(TASK)