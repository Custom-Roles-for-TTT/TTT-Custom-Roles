local TASK = {}

TASK.id = "calldetective"

TASK.Name = function(ply)
    return "Call a Detective to a Body"
end

TASK.Description = function(ply)
    return "Call a detective to the body of a dead player"
end

if SERVER then
    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {}

    TASK.OnTaskAssigned = function(ply)
        hook.Add("TTTDetectiveCalledToBody", "Taskmaster_CallDetective_TTTDetectiveCalledToBody_" .. ply:SteamID64(), function(caller, owner, rag)
            if not IsPlayer(caller) then return end
            if caller ~= ply then return end
            ply:CompleteTask(TASK.id)
        end)
    end

    TASK.OnTaskRemoved = function(ply)
        hook.Remove("TTTDetectiveCalledToBody", "Taskmaster_CallDetective_TTTDetectiveCalledToBody_" .. ply:SteamID64())
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

TASKMASTER.RegisterTask(TASK)