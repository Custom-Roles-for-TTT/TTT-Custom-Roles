local hook = hook
local net = net
local player = player
local util = util

local TASK = {}

TASK.id = "getplayertokill"

TASK.Name = function(ply)
    local name = "Target"
    if IsPlayer(ply.Task_GetPlayerToKillPlayer) then
        name = ply.Task_GetPlayerToKillPlayer:Nick()
    end
    return "Get " .. name .. " to Kill"
end

TASK.Description = function(ply)
    local name = "Target"
    if IsPlayer(ply.Task_GetPlayerToKillPlayer) then
        name = ply.Task_GetPlayerToKillPlayer:Nick()
    end

    return "Get " .. name .. " to kill another player"
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_GetPlayerToKill_Assigned")
    util.AddNetworkString("TTT_Taskmaster_GetPlayerToKill_Cleanup")

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
        ply:SetProperty("Task_GetPlayerToKillPlayer", GetRandomTarget(ply), ply)

        hook.Add("PlayerDeath", "Taskmaster_GetPlayerToKill_PlayerDeath_" .. ply:SteamID64(), function(victim, inflictor, attacker)
            if ply.Task_GetPlayerToKillPlayer ~= attacker then return end
            if victim == ply then return end
            ply:CompleteTask(TASK.id)
        end)

        hook.Add("PlayerDisconnected", "Taskmaster_GetPlayerToKill_PlayerDisconnected_" .. ply:SteamID64(), function(leaver)
            if ply.Task_GetPlayerToKillPlayer ~= leaver then return end

            local target = GetRandomTarget(ply)
            ply:QueueMessage(MSG_PRINTBOTH, "Your target for the '" .. TASK.Name(ply) .. "' task has disappeared! Your new target is " .. target:Nick())
            ply:SetProperty("Task_GetPlayerToKillPlayer", target, ply)
        end)

        net.Start("TTT_Taskmaster_GetPlayerToKill_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        timer.Remove("TTTTaskmasterGetPlayerToKillTimer")

        ply:ClearProperty("Task_GetPlayerToKillPlayer", ply)

        hook.Remove("PlayerDeath", "Taskmaster_GetPlayerToKill_PlayerDeath_" .. ply:SteamID64())
        hook.Remove("PlayerDisconnected", "Taskmaster_GetPlayerToKill_PlayerDisconnected_" .. ply:SteamID64())

        net.Start("TTT_Taskmaster_GetPlayerToKill_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    net.Receive("TTT_Taskmaster_GetPlayerToKill_Assigned", function()
        local client = LocalPlayer()
        hook.Add("TTTTargetIDPlayerTargetIcon", "Taskmaster_GetPlayerToKill_TTTTargetIDPlayerTargetIcon_" .. client:SteamID64(), function(ply, cli, showJester)
            if cli:IsActiveTaskmaster() and ply == cli.Task_GetPlayerToKillPlayer then
                local iconColor = ROLE_COLORS_SPRITE[ROLE_TRAITOR]
                return "task", true, iconColor, "up"
            end
        end)
    end)

    net.Receive("TTT_Taskmaster_GetPlayerToKill_Cleanup", function()
        local client = LocalPlayer()
        hook.Remove("TTTTargetIDPlayerTargetIcon", "Taskmaster_GetPlayerToKill_TTTTargetIDPlayerTargetIcon_"  .. client:SteamID64())
    end)
end

TASKMASTER.RegisterTask(TASK)