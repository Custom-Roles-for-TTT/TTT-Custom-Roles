local hook = hook
local table = table

local TableHasValue = table.HasValue

local TASK = {}

TASK.id = "jump"

local taskmaster_jump_times = CreateConVar("ttt_taskmaster_jump_times", "100", FCVAR_REPLICATED, "The jump of times a player must jump to complete the 'Jump X Times' task", 1, 500)
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

    local progress
    if TableHasValue(ply.taskmasterCompletedTasks, TASK.id) then
        progress = times
    else
        progress = ply.Task_JumpCount
    end

    return name .. " (" .. progress .. "/" .. times .. ")"
end

TASK.Description = function(ply)
    local times = taskmaster_jump_times:GetInt()
    local desc = "Jump in the air " .. times .. " time"
    if times ~= 1 then
        desc = desc .. "s"
    end
    return desc
end

if SERVER then
    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {}

    TASK.OnTaskAssigned = function(ply)
        local times = taskmaster_jump_times:GetInt()
        ply:SetProperty("Task_JumpCount", 0, ply)
        hook.Add("OnPlayerJump", "Taskmaster_Jump_OnPlayerJump_" .. ply:SteamID64(), function(caller)
            if not IsPlayer(caller) then return end
            if caller ~= ply then return end
            ply:SetProperty("Task_JumpCount", ply.Task_JumpCount + 1, ply)
            if ply.Task_JumpCount >= times then
                ply:CompleteTask(TASK.id)
            end
        end)
    end

    TASK.OnTaskRemoved = function(ply)
        hook.Remove("OnPlayerJump", "Taskmaster_Jump_OnPlayerJump_" .. ply:SteamID64())

        ply:ClearProperty("Task_JumpCount", ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

TASKMASTER.RegisterTask(TASK)