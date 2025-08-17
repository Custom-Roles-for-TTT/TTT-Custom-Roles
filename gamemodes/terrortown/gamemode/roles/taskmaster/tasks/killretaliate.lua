local hook = hook
local player = player

local PlayerIterator = player.Iterator

local TASK = {}

TASK.id = "killretaliate"
TASK.isKillTask = true

TASK.Name = function(ply)
    return "Kill a Player That Attacked First"
end

TASK.Description = function(ply)
    return "Kill another player that attacked you first"
end

local TASK_KILLRETALIATE_NONE = 0
local TASK_KILLRETALIATE_THEYATTACKED = 1
local TASK_KILLRETALIATE_YOUATTACKED = 2

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_KillRetaliate_Assigned")
    util.AddNetworkString("TTT_Taskmaster_KillRetaliate_Cleanup")

    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_TARGETID_PLAYERTEXT
    }

    TASK.OnTaskAssigned = function(ply)

        for _, p in PlayerIterator() do
            if ply == p then continue end
            p:SetProperty("Task_KillRetaliateAttacked", TASK_KILLRETALIATE_NONE, ply)
        end

        local sid64 = ply:SteamID64()

        hook.Add("PlayerDeath", "Taskmaster_KillRetaliate_PlayerDeath_" .. sid64, function(victim, inflictor, attacker)
            if not IsPlayer(victim) then return end
            if not IsPlayer(attacker) or not attacker:IsActiveTaskmaster() or attacker ~= ply then return end

            if victim.Task_KillRetaliateAttacked == TASK_KILLRETALIATE_THEYATTACKED then
                ply:CompleteTask(TASK.id)
            end
        end)

        hook.Add("PostEntityTakeDamage", "Taskmaster_KillRetaliate_PostEntityTakeDamage_" .. sid64, function(entity, dmginfo, wasDamageTaken)
            if not wasDamageTaken then return end
            if not IsPlayer(entity) then return end

            local attacker = dmginfo:GetAttacker()
            if not IsPlayer(attacker) then return end

            if entity == ply and attacker.Task_KillRetaliateAttacked == TASK_KILLRETALIATE_NONE then
                attacker:SetProperty("Task_KillRetaliateAttacked", TASK_KILLRETALIATE_THEYATTACKED, ply)
            elseif attacker == ply and entity.Task_KillRetaliateAttacked == TASK_KILLRETALIATE_NONE then
                entity:SetProperty("Task_KillRetaliateAttacked", TASK_KILLRETALIATE_YOUATTACKED, ply)
            end
        end)

        net.Start("TTT_Taskmaster_KillRetaliate_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        for _, p in PlayerIterator() do
            if ply == p then continue end
            p:ClearProperty("Task_KillRetaliateAttacked", ply)
        end

        local sid64 = ply:SteamID64()

        hook.Remove("PlayerDeath", "Taskmaster_KillRetaliate_PlayerDeath_" .. sid64)
        hook.Remove("PostEntityTakeDamage", "Taskmaster_KillRetaliate_PostEntityTakeDamage_" .. sid64)

        net.Start("TTT_Taskmaster_KillRetaliate_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    net.Receive("TTT_Taskmaster_KillRetaliate_Assigned", function()
        hook.Add("TTTTargetIDPlayerText", "Taskmaster_KillRetaliate_TTTTargetIDPlayerText_" .. LocalPlayer():SteamID64(), function(ent, cli, text, col, secondaryText)
            if not cli:IsActiveTaskmaster() or not IsPlayer(ent) then return end

            local state = ent.Task_KillRetaliateAttacked

            if state == TASK_KILLRETALIATE_THEYATTACKED then
                return "AGGRESSIVE", ROLE_COLORS_RADAR[ROLE_INNOCENT]
            elseif state == TASK_KILLRETALIATE_YOUATTACKED then
                return "DEFENSIVE", ROLE_COLORS_RADAR[ROLE_TRAITOR]
            else
                return "PASSIVE", ROLE_COLORS_RADAR[ROLE_TRAITOR]
            end
        end)
    end)

    net.Receive("TTT_Taskmaster_KillRetaliate_Cleanup", function()
        hook.Remove("TTTTargetIDPlayerText", "Taskmaster_KillRetaliate_TTTTargetIDPlayerText_"  .. LocalPlayer():SteamID64())
    end)
end

TASKMASTER.RegisterTask(TASK)