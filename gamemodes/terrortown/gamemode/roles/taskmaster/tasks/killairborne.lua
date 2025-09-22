local hook = hook
local net = net

local TASK = {}

TASK.id = "killairborne"
TASK.IsKillTask = true

TASK.Name = function(ply)
    return "Kill an Airborne Player"
end

TASK.Description = function(ply)
    return "Kill another player while they are in the air"
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_KillAirborne_Assigned")
    util.AddNetworkString("TTT_Taskmaster_KillAirborne_Cleanup")

    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_TARGETID_PLAYERTEXT
    }

    TASK.OnTaskAssigned = function(ply)
        hook.Add("PlayerDeath", "Taskmaster_KillAirborne_PlayerDeath_" .. ply:SteamID64(), function(victim, inflictor, attacker)
            if not IsPlayer(victim) then return end
            if not IsPlayer(attacker) or not attacker:IsActiveTaskmaster() or attacker ~= ply then return end

            if not victim:OnGround() then
                ply:CompleteTask(TASK.id)
            end
        end)

        net.Start("TTT_Taskmaster_KillAirborne_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        hook.Remove("PlayerDeath", "Taskmaster_KillAirborne_PlayerDeath_" .. ply:SteamID64())
        net.Start("TTT_Taskmaster_KillAirborne_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    net.Receive("TTT_Taskmaster_KillAirborne_Assigned", function()
        hook.Add("TTTTargetIDPlayerText", "Taskmaster_KillAirborne_TTTTargetIDPlayerText_" .. LocalPlayer():SteamID64(), function(ent, cli, text, col, secondaryText)
            if not cli:IsActiveTaskmaster() or not IsPlayer(ent) then return end

            if ent:OnGround() then
                return "GROUNDED", ROLE_COLORS_RADAR[ROLE_TRAITOR]
            else
                return "AIRBORNE", ROLE_COLORS_RADAR[ROLE_INNOCENT]
            end
        end)
    end)

    net.Receive("TTT_Taskmaster_KillAirborne_Cleanup", function()
        hook.Remove("TTTTargetIDPlayerText", "Taskmaster_KillAirborne_TTTTargetIDPlayerText_"  .. LocalPlayer():SteamID64())
    end)
end

TASKMASTER.RegisterTask(TASK)