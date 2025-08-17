local hook = hook
local player = player

local PlayerIterator = player.Iterator

local TASK = {}

TASK.id = "killonehit"
TASK.isKillTask = true

TASK.Name = function(ply)
    return "Kill a Player in One Hit"
end

TASK.Description = function(ply)
    return "Kill another player with a single attack"
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_KillOneHit_Assigned")
    util.AddNetworkString("TTT_Taskmaster_KillOneHit_Cleanup")

    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_TARGETID_PLAYERTEXT
    }

    TASK.OnTaskAssigned = function(ply)
        local sid64 = ply:SteamID64()

        hook.Add("PlayerDeath", "Taskmaster_KillOneHit_PlayerDeath_" .. sid64, function(victim, inflictor, attacker)
            if not IsPlayer(victim) then return end
            if not IsPlayer(attacker) or not attacker:IsActiveTaskmaster() or attacker ~= ply then return end

            if not victim.Task_KillOneHitAttacked or CurTime() < victim.Task_KillOneHitAttacked + 0.1 then -- Allow for a very small delay to account for things such as shotgun pellets
                ply:CompleteTask(TASK.id)
            end
        end)

        hook.Add("PostEntityTakeDamage", "Taskmaster_KillOneHit_PostEntityTakeDamage_" .. sid64, function(entity, dmginfo, wasDamageTaken)
            if not wasDamageTaken then return end
            if not IsPlayer(entity) then return end

            local attacker = dmginfo:GetAttacker()
            if not IsPlayer(attacker) or attacker ~= ply then return end

            if not entity.Task_KillOneHitAttacked then
                entity:SetProperty("Task_KillOneHitAttacked", CurTime(), ply)
            end
        end)

        net.Start("TTT_Taskmaster_KillOneHit_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        for _, p in PlayerIterator() do
            if ply == p then continue end
            p:ClearProperty("Task_KillOneHitAttacked", ply)
        end

        local sid64 = ply:SteamID64()

        hook.Remove("PlayerDeath", "Taskmaster_KillOneHit_PlayerDeath_" .. sid64)
        hook.Remove("PostEntityTakeDamage", "Taskmaster_KillOneHit_PostEntityTakeDamage_" .. sid64)

        net.Start("TTT_Taskmaster_KillOneHit_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    net.Receive("TTT_Taskmaster_KillOneHit_Assigned", function()
        hook.Add("TTTTargetIDPlayerText", "Taskmaster_KillOneHit_TTTTargetIDPlayerText_" .. LocalPlayer():SteamID64(), function(ent, cli, text, col, secondaryText)
            if not cli:IsActiveTaskmaster() or not IsPlayer(ent) then return end

            if ent.Task_KillOneHitAttacked then
                return "DAMAGED", ROLE_COLORS_RADAR[ROLE_TRAITOR]
            else
                return "UNHARMED", ROLE_COLORS_RADAR[ROLE_INNOCENT]
            end
        end)
    end)

    net.Receive("TTT_Taskmaster_KillOneHit_Cleanup", function()
        hook.Remove("TTTTargetIDPlayerText", "Taskmaster_KillOneHit_TTTTargetIDPlayerText_"  .. LocalPlayer():SteamID64())
    end)
end

TASKMASTER.RegisterTask(TASK)