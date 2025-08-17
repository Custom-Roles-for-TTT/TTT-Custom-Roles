local hook = hook
local net = net
local player = player
local util = util

local TASK = {}

TASK.id = "killtarget"
TASK.isKillTask = true

TASK.Name = function(ply)
    local name = "Target"
    if IsPlayer(ply.Task_KillTargetPlayer) then
        name = ply.Task_KillTargetPlayer:Nick()
    end
    return "Kill " .. name
end

TASK.Description = function(ply)
    local name = "target"
    if IsPlayer(ply.Task_KillTargetPlayer) then
        name = ply.Task_KillTargetPlayer:Nick()
    end
    return "Kill " .. name .. " by any means necessary"
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_KillTarget_Assigned")
    util.AddNetworkString("TTT_Taskmaster_KillTarget_Cleanup")

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
        local sid64 = ply:SteamID64()

        ply:SetProperty("Task_KillTargetPlayer", GetRandomTarget(ply), ply)

        hook.Add("PlayerDeath", "Taskmaster_KillTarget_PlayerDeath_" .. sid64, function(victim, inflictor, attacker)
            if not IsPlayer(victim) then return end
            if not IsPlayer(attacker) or not attacker:IsActiveTaskmaster() or attacker ~= ply then return end

            if victim == ply.Task_KillTargetPlayer then
                ply:CompleteTask(TASK.id)
            end
        end)

        hook.Add("PostPlayerDeath", "Taskmaster_KillTarget_PostPlayerDeath_" .. sid64, function(victim)
            if ply.Task_KillTargetPlayer ~= victim then return end

            local target = GetRandomTarget(ply)
            ply:QueueMessage(MSG_PRINTBOTH, "Your target for the '" .. TASK.Name(ply) .. "' task has died! Your new target is " .. target:Nick())
            ply:SetProperty("Task_KillTargetPlayer", target, ply)
        end)

        hook.Add("PlayerDisconnected", "Taskmaster_KillTarget_PlayerDisconnected_" .. sid64, function(leaver)
            if ply.Task_KillTargetPlayer ~= leaver then return end

            local target = GetRandomTarget(ply)
            ply:QueueMessage(MSG_PRINTBOTH, "Your target for the '" .. TASK.Name(ply) .. "' task has disappeared! Your new target is " .. target:Nick())
            ply:SetProperty("Task_KillTargetPlayer", target, ply)
        end)

        net.Start("TTT_Taskmaster_KillTarget_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskComplete = function(ply)
        local sid64 = ply:SteamID64()

        hook.Remove("PlayerDeath", "Taskmaster_KillTarget_PlayerDeath_" .. sid64)
        hook.Remove("PostPlayerDeath", "Taskmaster_KillTarget_PostPlayerDeath_" .. sid64)
        hook.Remove("PlayerDisconnected", "Taskmaster_KillTarget_PlayerDisconnected_" .. sid64)

        net.Start("TTT_Taskmaster_KillTarget_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        TASK.OnTaskComplete(ply)
        ply:ClearProperty("Task_KillTargetPlayer", ply)
    end
end

if CLIENT then
    net.Receive("TTT_Taskmaster_KillTarget_Assigned", function()
        hook.Add("TTTTargetIDPlayerTargetIcon", "Taskmaster_KillTarget_TTTTargetIDPlayerTargetIcon_" .. LocalPlayer():SteamID64(), function(ply, cli, showJester)
            if cli:IsActiveTaskmaster() and ply == cli.Task_KillTargetPlayer then
                return "task", true, ROLE_COLORS_SPRITE[ROLE_TASKMASTER], "down"
            end
        end)
    end)

    net.Receive("TTT_Taskmaster_KillTarget_Cleanup", function()
        hook.Remove("TTTTargetIDPlayerTargetIcon", "Taskmaster_KillTarget_TTTTargetIDPlayerTargetIcon_"  .. LocalPlayer():SteamID64())
    end)
end

TASKMASTER.RegisterTask(TASK)