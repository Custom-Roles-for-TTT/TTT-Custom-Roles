local TASK = {}

TASK.id = "firebullets"

local taskmaster_firebullets_times = CreateConVar("ttt_taskmaster_firebullets_times", "100", FCVAR_REPLICATED, "The jump of times a player must fire a bullet to complete the 'Fire X Bullets' task", 1, 1000)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_firebullets_times",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    local times = taskmaster_firebullets_times:GetInt()
    local name = "Fire " .. times .. " Bullet"
    if times ~= 1 then
        name = name .. "s"
    end

    local progress = 0
    if (table.HasValue(ply.taskmasterCompletedTasks, TASK.id)) then
        progress = times
    else
        progress = ply.Task_FireBulletsCount
    end

    return name .. " (" .. progress .. "/" .. times .. ")"
end

TASK.Description = function(ply)
    local times = taskmaster_firebullets_times:GetInt()
    local desc = "Fire " .. times .. " time"
    if times ~= 1 then
        desc = desc .. "s"
    end
    return desc .. " from a gun"
end

if SERVER then
    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {}

    TASK.OnTaskAssigned = function(ply)
        local times = taskmaster_firebullets_times:GetInt()
        ply:SetProperty("Task_FireBulletsCount", 0, ply)
        hook.Add("PostEntityFireBullets", "Taskmaster_FireBullets_PostEntityFireBullets_" .. ply:SteamID64(), function(entity, data)
            if not IsPlayer(entity) then return end
            if entity ~= ply then return end
            ply:SetProperty("Task_FireBulletsCount", ply.Task_FireBulletsCount + 1, ply)
            if ply.Task_FireBulletsCount >= times then
                ply:CompleteTask(TASK.id)
            end
        end)
    end

    TASK.OnTaskRemoved = function(ply)
        hook.Remove("PostEntityFireBullets", "Taskmaster_FireBullets_PostEntityFireBullets_" .. ply:SteamID64())

        ply:ClearProperty("Task_FireBulletsCount", ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

TASKMASTER.RegisterTask(TASK)