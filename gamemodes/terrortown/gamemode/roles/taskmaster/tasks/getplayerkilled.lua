local hook = hook
local net = net
local player = player
local util = util

local TASK = {}

TASK.id = "getplayerkilled"

TASK.Name = function(ply)
    local name = "Target"
    if IsPlayer(ply.Task_GetPlayerKilledPlayer) then
        name = ply.Task_GetPlayerKilledPlayer:Nick()
    end
    return "Get " .. name .. " Killed"
end

TASK.Description = function(ply)
    local name = "target"
    if IsPlayer(ply.Task_GetPlayerKilledPlayer) then
        name = ply.Task_GetPlayerKilledPlayer:Nick()
    end

    return "Get " .. name .. " killed by another player (not you)"
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_GetPlayerKilled_Assigned")
    util.AddNetworkString("TTT_Taskmaster_GetPlayerKilled_Cleanup")

    local function GetRandomTarget(ply)
        -- Find the first random living player
        for _, p in RandomPairs(player.GetAll()) do
            if not p:Alive() or p:IsSpec() then continue end
            if p == ply then continue end
            return p
        end
        return nil
    end

    TASK.CanAssignTask = function(ply)
        return GetRandomTarget(ply) ~= nil
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_TARGETID_PLAYERICON
    }

    TASK.OnTaskAssigned = function(ply)
        ply:SetProperty("Task_GetPlayerKilledPlayer", GetRandomTarget(ply), ply)

        hook.Add("PlayerDeath", "Taskmaster_GetPlayerKilled_PlayerDeath_" .. ply:SteamID64(), function(victim, inflictor, attacker)
            if ply.Task_GetPlayerKilledPlayer ~= victim then return end
            if attacker == ply then
                local target = GetRandomTarget(ply)
                if target then
                    ply:QueueMessage(MSG_PRINTBOTH, "You killed your target for the '" .. TASK.Name(ply) .. "' task! Your new target is " .. target:Nick())
                    ply:SetProperty("Task_GetPlayerKilledPlayer", target, ply)
                else
                    ply:QueueMessage(MSG_PRINTBOTH, "You killed your target for the '" .. TASK.Name(ply) .. "' task! There are no new valid targets and you must reroll.")
                end
            else
                ply:CompleteTask(TASK.id)
            end
        end)

        hook.Add("PlayerDisconnected", "Taskmaster_GetPlayerKilled_PlayerDisconnected_" .. ply:SteamID64(), function(leaver)
            if ply.Task_GetPlayerKilledPlayer ~= leaver then return end

            local target = GetRandomTarget(ply)
            if target then
                ply:QueueMessage(MSG_PRINTBOTH, "Your target for the '" .. TASK.Name(ply) .. "' task has disappeared! Your new target is " .. target:Nick())
                ply:SetProperty("Task_GetPlayerKilledPlayer", target, ply)
            else
                ply:QueueMessage(MSG_PRINTBOTH, "Your target for the '" .. TASK.Name(ply) .. "' task has disappeared!  There are no new valid targets and you must reroll.")
            end
        end)

        net.Start("TTT_Taskmaster_GetPlayerKilled_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskComplete = function(ply)
        timer.Remove("TTTTaskmasterGetPlayerKilledTimer")

        hook.Remove("PlayerDeath", "Taskmaster_GetPlayerKilled_PlayerDeath_" .. ply:SteamID64())
        hook.Remove("PlayerDisconnected", "Taskmaster_GetPlayerKilled_PlayerDisconnected_" .. ply:SteamID64())

        net.Start("TTT_Taskmaster_GetPlayerKilled_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        TASK.OnTaskComplete(ply)
        ply:ClearProperty("Task_GetPlayerKilledPlayer", ply) -- Don't clear the player name if the task was completed so it still shows up in the task name/description
    end
end

if CLIENT then
    net.Receive("TTT_Taskmaster_GetPlayerKilled_Assigned", function()
        local client = LocalPlayer()
        hook.Add("TTTTargetIDPlayerTargetIcon", "Taskmaster_GetPlayerKilled_TTTTargetIDPlayerTargetIcon_" .. client:SteamID64(), function(ply, cli, showJester)
            if cli:IsActiveTaskmaster() and ply == cli.Task_GetPlayerKilledPlayer then
                local iconColor = ROLE_COLORS_SPRITE[ROLE_TASKMASTER]
                return "task", true, iconColor, "up"
            end
        end)
    end)

    net.Receive("TTT_Taskmaster_GetPlayerKilled_Cleanup", function()
        local client = LocalPlayer()
        hook.Remove("TTTTargetIDPlayerTargetIcon", "Taskmaster_GetPlayerKilled_TTTTargetIDPlayerTargetIcon_"  .. client:SteamID64())
    end)
end

TASKMASTER.RegisterTask(TASK)