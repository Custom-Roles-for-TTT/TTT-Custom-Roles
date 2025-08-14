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
    return name
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
        local count = 0
        hook.Add("PlayerSay", "Taskmaster_Chat_PlayerSay_" .. ply:SteamID64(), function(sender, text, teamChat)
            if not IsPlayer(sender) then return end
            if sender ~= ply then return end
            count = count + 1
            if count >= times then
                ply:CompleteTask(TASK.id)
            end
        end)
    end

    TASK.OnTaskRemoved = function(ply)
        hook.Remove("PlayerSay", "Taskmaster_Chat_PlayerSay_" .. ply:SteamID64())
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

TASKMASTER.RegisterTask(TASK)