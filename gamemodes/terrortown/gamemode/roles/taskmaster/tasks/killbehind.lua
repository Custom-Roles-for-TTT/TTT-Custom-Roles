local hook = hook
local math = math
local net = net
local table = table

local MathCos = math.cos
local MathRad = math.rad

local TASK = {}

TASK.id = "killbehind"
TASK.isKillTask = true

local taskmaster_killbehind_angle = CreateConVar("ttt_taskmaster_killbehind_view_angle", "75", FCVAR_REPLICATED, "The angle (in degrees) from a player's eye angle within which the Taskmaster is 'spotted'  for the 'Kill a Player From Behind' task", 0, 180)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_killbehind_view_angle",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    return "Kill a Player From Behind"
end

TASK.Description = function(ply)
    return "Kill another player while they are looking away from you"
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_KillBehind_Assigned")
    util.AddNetworkString("TTT_Taskmaster_KillBehind_Cleanup")

    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_TARGETID_PLAYERTEXT
    }

    TASK.OnTaskAssigned = function(ply)
        hook.Add("PlayerDeath", "Taskmaster_KillBehind_PlayerDeath_" .. ply:SteamID64(), function(victim, inflictor, attacker)
            if not IsPlayer(victim) then return end
            if not IsPlayer(attacker) or not attacker:IsActiveTaskmaster() or attacker ~= ply then return end

            local maxAngleCos = MathCos(MathRad(taskmaster_killbehind_angle:GetInt()))
            local aimVector = victim:GetAimVector()
            local attackVector = attacker:GetPos() - victim:GetShootPos()
            local angleCos = aimVector:Dot(attackVector) / attackVector:Length()

            if angleCos <= maxAngleCos then
                ply:CompleteTask(TASK.id)
            end
        end)

        net.Start("TTT_Taskmaster_KillBehind_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        hook.Remove("PlayerDeath", "Taskmaster_KillBehind_PlayerDeath_" .. ply:SteamID64())
        net.Start("TTT_Taskmaster_KillBehind_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    net.Receive("TTT_Taskmaster_KillBehind_Assigned", function()
        local maxAngleCos = MathCos(MathRad(taskmaster_killbehind_angle:GetInt()))

        hook.Add("TTTTargetIDPlayerText", "Taskmaster_KillBehind_TTTTargetIDPlayerText_" .. LocalPlayer():SteamID64(), function(ent, cli, text, col, secondaryText)
            if not cli:IsActiveTaskmaster() or not IsPlayer(ent) then return end

            local aimVector = ent:GetAimVector()
            local attackVector = cli:GetPos() - ent:GetShootPos()
            local angleCos = aimVector:Dot(attackVector) / attackVector:Length()

            if angleCos <= maxAngleCos then
                return "HIDDEN", ROLE_COLORS_RADAR[ROLE_INNOCENT]
            else
                return "SPOTTED", ROLE_COLORS_RADAR[ROLE_TRAITOR]
            end
        end)
    end)

    net.Receive("TTT_Taskmaster_KillBehind_Cleanup", function()
        hook.Remove("TTTTargetIDPlayerText", "Taskmaster_KillBehind_TTTTargetIDPlayerText_"  .. LocalPlayer():SteamID64())
    end)
end

TASKMASTER.RegisterTask(TASK)