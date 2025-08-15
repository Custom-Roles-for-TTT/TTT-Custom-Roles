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
    local name = "Target"
    if IsPlayer(ply.Task_GetPlayerKilledPlayer) then
        name = ply.Task_GetPlayerKilledPlayer:Nick()
    end

    return "Get " .. name .. " killed by another player"
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_GetPlayerKilled_Assigned")
    util.AddNetworkString("TTT_Taskmaster_GetPlayerKilled_Cleanup")

    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_TARGETID_PLAYERICON
    }

    local function GetRandomTarget(ply)
        -- Find the first random living player
        for _, p in RandomPairs(player.GetAll()) do
            if not p:Alive() or p:IsSpec() then continue end
            if p == ply then continue end
            return p
        end
        return nil
    end

    TASK.OnTaskAssigned = function(ply)
        ply:SetProperty("Task_GetPlayerKilledPlayer", GetRandomTarget(ply), ply)

        hook.Add("PlayerDeath", "Taskmaster_GetPlayerKilled_PlayerDeath_" .. ply:SteamID64(), function(victim, inflictor, attacker)
            if ply.Task_GetPlayerKilledPlayer ~= victim then return end
            if attacker == ply then return end
            ply:CompleteTask(TASK.id)
        end)

        hook.Add("PlayerDisconnected", "Taskmaster_GetPlayerKilled_PlayerDisconnected_" .. ply:SteamID64(), function(leaver)
            if ply.Task_GetPlayerKilledPlayer ~= leaver then return end

            local target = GetRandomTarget(ply)
            ply:QueueMessage(MSG_PRINTBOTH, "Your target for the '" .. TASK.Name(ply) .. "' task has disappeared! Your new target is " .. target:Nick())
            ply:SetProperty("Task_GetPlayerKilledPlayer", target, ply)
        end)

        net.Start("TTT_Taskmaster_GetPlayerKilled_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        timer.Remove("TTTTaskmasterGetPlayerKilledTimer")

        ply:ClearProperty("Task_GetPlayerKilledPlayer", ply)

        hook.Remove("PlayerDeath", "Taskmaster_GetPlayerKilled_PlayerDeath_" .. ply:SteamID64())
        hook.Remove("PlayerDisconnected", "Taskmaster_GetPlayerKilled_PlayerDisconnected_" .. ply:SteamID64())

        net.Start("TTT_Taskmaster_GetPlayerKilled_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    net.Receive("TTT_Taskmaster_GetPlayerKilled_Assigned", function()
        local client = LocalPlayer()
        hook.Add("TTTTargetIDPlayerTargetIcon", "Taskmaster_GetPlayerKilled_TTTTargetIDPlayerTargetIcon_" .. client:SteamID64(), function(ply, cli, showJester)
            if cli:IsActiveTaskmaster() and ply == cli.Task_GetPlayerKilledPlayer then
                local iconColor = ROLE_COLORS_SPRITE[ROLE_TRAITOR]
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