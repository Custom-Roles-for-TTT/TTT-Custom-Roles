local hook = hook
local net = net
local player = player
local util = util

local TASK = {}

TASK.id = "getplayertokill"

TASK.Name = function(ply)
    local name = "Target"
    if ply and IsPlayer(ply.Task_GetPlayerToKillPlayer) then
        name = ply.Task_GetPlayerToKillPlayer:Nick()
    end
    return "Get " .. name .. " to Kill"
end

TASK.Description = function(ply)
    local name = "target"
    if ply and IsPlayer(ply.Task_GetPlayerToKillPlayer) then
        name = ply.Task_GetPlayerToKillPlayer:Nick()
    end
    return "Get " .. name .. " to kill another player (not you)"
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_GetPlayerToKill_Assigned")
    util.AddNetworkString("TTT_Taskmaster_GetPlayerToKill_Cleanup")

    local function GetRandomTarget(ply)
        local passive = nil
        -- Find the first random living player
        for _, p in RandomPairs(player.GetAll()) do
            if p == ply then continue end
            if not p:Alive() or p:IsSpec() then continue end
            if p:ShouldActLikeJester() then continue end
            -- They just want live, they aren't going to kill anyone
            if ROLE_HAS_PASSIVE_WIN[p:GetRole()] then
                passive = p
                continue
            end
            return p
        end

        -- Return the passive winner (if we have one) as a last resort
        return passive
    end

    TASK.CanAssignTask = function(ply)
        return GetRandomTarget(ply) ~= nil
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_TARGETID_PLAYERICON
    }

    TASK.OnTaskAssigned = function(ply)
        ply:SetProperty("Task_GetPlayerToKillPlayer", GetRandomTarget(ply), ply)

        hook.Add("PlayerDeath", "Taskmaster_GetPlayerToKill_PlayerDeath_" .. ply:SteamID64(), function(victim, inflictor, attacker)
            if ply.Task_GetPlayerToKillPlayer == attacker and attacker ~= victim then
                if victim == ply then return end
                ply:CompleteTask(TASK.id)
            elseif ply.Task_GetPlayerToKillPlayer == victim then
                local target = GetRandomTarget(ply)
                if target then
                    ply:QueueMessage(MSG_PRINTBOTH, "Your target for the '" .. TASK.Name(ply) .. "' task has died! Your new target is " .. target:Nick())
                    ply:SetProperty("Task_GetPlayerToKillPlayer", target, ply)
                else
                    ply:QueueMessage(MSG_PRINTBOTH, "Your target for the '" .. TASK.Name(ply) .. "' task has died! There are no new valid targets and you must reroll.")
                end
            end
        end)

        hook.Add("PlayerDisconnected", "Taskmaster_GetPlayerToKill_PlayerDisconnected_" .. ply:SteamID64(), function(leaver)
            if ply.Task_GetPlayerToKillPlayer ~= leaver then return end

            local target = GetRandomTarget(ply)
            if target then
                ply:QueueMessage(MSG_PRINTBOTH, "Your target for the '" .. TASK.Name(ply) .. "' task has disappeared! Your new target is " .. target:Nick())
                ply:SetProperty("Task_GetPlayerToKillPlayer", target, ply)
            else
                ply:QueueMessage(MSG_PRINTBOTH, "Your target for the '" .. TASK.Name(ply) .. "' task has disappeared!  There are no new valid targets and you must reroll.")
            end
        end)

        net.Start("TTT_Taskmaster_GetPlayerToKill_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskComplete = function(ply)
        timer.Remove("TTTTaskmasterGetPlayerToKillTimer")

        hook.Remove("PlayerDeath", "Taskmaster_GetPlayerToKill_PlayerDeath_" .. ply:SteamID64())
        hook.Remove("PlayerDisconnected", "Taskmaster_GetPlayerToKill_PlayerDisconnected_" .. ply:SteamID64())

        net.Start("TTT_Taskmaster_GetPlayerToKill_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        TASK.OnTaskComplete(ply)
        ply:ClearProperty("Task_GetPlayerToKillPlayer", ply) -- Don't clear the player name if the task was completed so it still shows up in the task name/description
    end
end

if CLIENT then
    net.Receive("TTT_Taskmaster_GetPlayerToKill_Assigned", function()
        local client = LocalPlayer()
        hook.Add("TTTTargetIDPlayerTargetIcon", "Taskmaster_GetPlayerToKill_TTTTargetIDPlayerTargetIcon_" .. client:SteamID64(), function(ply, cli, showJester)
            if cli:IsActiveTaskmaster() and ply == cli.Task_GetPlayerToKillPlayer then
                local iconColor = ROLE_COLORS_SPRITE[ROLE_TASKMASTER]
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