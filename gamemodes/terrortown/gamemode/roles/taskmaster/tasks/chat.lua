local hook = hook
local table = table

local TableHasValue = table.HasValue

local TASK = {}

TASK.id = "chat"

local taskmaster_chat_times = CreateConVar("ttt_taskmaster_chat_times", "25", FCVAR_REPLICATED, "The number of text messages a player must sent to complete the 'Send X Messages' task", 1, 100)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_chat_times",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    local times = taskmaster_chat_times:GetInt()
    local name = "Send " .. times .. " Message"
    if times ~= 1 then
        name = name .. "s"
    end

    if not ply then return name end

    local progress
    if TableHasValue(ply.TaskmasterCompletedTasks, TASK.id) then
        progress = times
    else
        progress = ply.Task_ChatCount or 0
    end

    return name .. " (" .. progress .. "/" .. times .. ")"
end

TASK.Description = function(ply)
    local times = taskmaster_chat_times:GetInt()
    local desc = "Send " .. times .. " message"
    if times ~= 1 then
        desc = desc .. "s"
    end
    return desc .. " in text chat"
end

if SERVER then
    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {}

    TASK.OnTaskAssigned = function(ply)
        local times = taskmaster_chat_times:GetInt()
        ply:SetProperty("Task_ChatCount", 0, ply)
        hook.Add("PlayerSay", "Taskmaster_Chat_PlayerSay_" .. ply:SteamID64(), function(sender, text, teamChat)
            if not IsPlayer(sender) then return end
            if sender ~= ply then return end
            if not ply:Alive() or ply:IsSpec() then return end

            ply:SetProperty("Task_ChatCount", ply.Task_ChatCount + 1, ply)
            if ply.Task_ChatCount >= times then
                ply:CompleteTask(TASK.id)
            end
        end)
    end

    TASK.OnTaskRemoved = function(ply)
        hook.Remove("PlayerSay", "Taskmaster_Chat_PlayerSay_" .. ply:SteamID64())

        ply:ClearProperty("Task_ChatCount", ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

TASKMASTER.RegisterTask(TASK)