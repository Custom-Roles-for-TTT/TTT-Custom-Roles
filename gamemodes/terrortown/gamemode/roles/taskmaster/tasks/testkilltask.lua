local TASK = {}

TASK.id = "testkilltask"
TASK.isKillTask = true

TASK.Name = function(ply)
    return "Test Kill Task"
end

TASK.Description = function(ply)
    return "Test Kill Task Description"
end

if SERVER then
    TASK.CanAssignTask = function(ply)
        return false
    end

    TASK.RequiredFeatures = {
        --"TargetIDPlayerText",
        --"TargetIDPlayerTargetIcon",
        --"ProgressBar"
    }

    TASK.OnTaskAssigned = function(ply)
        ply:QueueMessage(MSG_PRINTBOTH, "Task Assigned: " .. TASK.Name(ply))
    end

    TASK.OnTaskRemoved = function(ply)
        ply:QueueMessage(MSG_PRINTBOTH, "Task Removed: " .. TASK.Name(ply))
    end

    TASK.OnTaskComplete = function(ply)
        ply:QueueMessage(MSG_PRINTBOTH, "Task Completed: " .. TASK.Name(ply))
    end
end

TASKMASTER.RegisterTask(TASK)