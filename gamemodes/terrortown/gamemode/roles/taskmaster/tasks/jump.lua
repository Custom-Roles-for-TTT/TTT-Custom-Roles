local TASK = {}

TASK.id = "jump"

local taskmaster_jump_times = CreateConVar("ttt_taskmaster_jump_times", "25", FCVAR_REPLICATED, "The jump of times a player must jump to complete the 'Jump X Times' task", 1, 100)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_jump_times",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    local times = taskmaster_jump_times:GetInt()
    local name = "Jump " .. times .. " Time"
    if times ~= 1 then
        name = name .. "s"
    end
    return name
end

TASK.Description = function(ply)
    local times = taskmaster_jump_times:GetInt()
    local name = "Jump in the air " .. times .. " time"
    if times ~= 1 then
        name = name .. "s"
    end
    return name
end

if SERVER then
    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {}

    TASK.OnTaskAssigned = function(ply)
        local times = taskmaster_jump_times:GetInt()
        local count = 0
        hook.Add("OnPlayerJump", "Taskmaster_Jump_OnPlayerJump_" .. ply:SteamID64(), function(caller)
            if not IsPlayer(caller) then return end
            if caller ~= ply then return end
            count = count + 1
            if count >= times then
                ply:CompleteTask(TASK.id)
            end
        end)
    end

    TASK.OnTaskRemoved = function(ply)
        hook.Remove("OnPlayerJump", "Taskmaster_Jump_OnPlayerJump_" .. ply:SteamID64())
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

TASKMASTER.RegisterTask(TASK)