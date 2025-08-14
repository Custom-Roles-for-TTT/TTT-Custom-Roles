local CurTime = CurTime
local cvars = cvars
local hook = hook
local math = math
local net = net
local table = table

local MathCos = math.cos
local MathPi = math.pi
local MathRand = math.Rand
local MathSin = math.sin

local TASK = {}

TASK.id = "killfaraway"
TASK.isKillTask = true

local taskmaster_killfaraway_range = CreateConVar("ttt_taskmaster_killfaraway_range", "25", FCVAR_REPLICATED, "The minimum distance (in meters) away a player can be to count for the 'Kill a Faraway Player' task", 0, 100)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_killfaraway_range",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    return "Kill a Faraway Player"
end

TASK.Description = function(ply)
    local unit
    if SERVER then
        unit = 1
    else
        unit = cvars.Number("ttt_distance_unit", 1)
    end
    local range = taskmaster_killfaraway_range:GetInt()
    local description = "Kill another player from outside "
    if unit == 1 then
        description = description .. range .. " meter"
        if range ~= 1 then
            description = description .. "s"
        end
    elseif unit == 2 then
        local convertedRange = math.ceil(range * FEET_PER_METER)
        description = description .. convertedRange
        if convertedRange == 1 then
            description = description .. " foot"
        else
            description = description .. " feet"
        end
    else
        local convertedRange = math.ceil(range * UNITS_PER_METER)
        description = description .. convertedRange .. " unit"
        if convertedRange ~= 1 then
            description = description .. "s"
        end
    end
    return description
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_KillFaraway_Assigned")
    util.AddNetworkString("TTT_Taskmaster_KillFaraway_Cleanup")

    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_TARGETID_PLAYERTEXT,
        TASKMASTER_TF_PARTICLERADIUS
    }

    TASK.OnTaskAssigned = function(ply)
        hook.Add("PlayerDeath", "Taskmaster_KillFaraway_PlayerDeath_" .. ply:SteamID64(), function(victim, inflictor, attacker)
            if not IsPlayer(victim) then return end
            if not IsPlayer(attacker) or not attacker:IsActiveTaskmaster() or attacker ~= ply then return end

            local distanceSqr = victim:GetPos():DistToSqr(attacker:GetPos())
            local range = taskmaster_killfaraway_range:GetInt() * UNITS_PER_METER
            local rangeSqr = range * range

            if distanceSqr >= rangeSqr then
                ply:CompleteTask(TASK.id)
            end
        end)

        net.Start("TTT_Taskmaster_KillFaraway_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        hook.Remove("PlayerDeath", "Taskmaster_KillFaraway_PlayerDeath_" .. ply:SteamID64())
        net.Start("TTT_Taskmaster_KillFaraway_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    net.Receive("TTT_Taskmaster_KillFaraway_Assigned", function()
        local sid64 = LocalPlayer():SteamID64()
        local range = taskmaster_killfaraway_range:GetInt() * UNITS_PER_METER
        local rangeSqr = range * range

        hook.Add("TTTTargetIDPlayerText", "Taskmaster_KillFaraway_TTTTargetIDPlayerText_" .. sid64, function(ent, cli, text, col, secondaryText)
            if not cli:IsActiveTaskmaster() or not IsPlayer(ent) then return end

            local distanceSqr = ent:GetPos():DistToSqr(cli:GetPos())
            if distanceSqr >= rangeSqr then
                return "IN RANGE", ROLE_COLORS_RADAR[ROLE_INNOCENT]
            else
                return "TOO CLOSE", ROLE_COLORS_RADAR[ROLE_TRAITOR]
            end
        end)

        local particleVelocity = Vector(0, 0, 80)
        hook.Add("TTTPlayerAliveClientThink", "Taskmaster_KillFaraway_TTTPlayerAliveClientThink_" .. sid64, function(cli, ply)
            local shouldDraw = false
            if ply == cli and cli:IsActiveTaskmaster() then
                local pos = ply:GetPos()
                if not ply.TaskmasterRadiusEmitter then ply.TaskmasterRadiusEmitter = ParticleEmitter(pos) end
                if not ply.TaskmasterRadiusNextPart then ply.TaskmasterRadiusNextPart = CurTime() end
                if not ply.TaskmasterRadiusDir then ply.TaskmasterRadiusDir = 0 end
                if ply.TaskmasterRadiusNextPart < CurTime() then
                    for _ = 1, 48 do
                        ply.TaskmasterRadiusEmitter:SetPos(pos)
                        ply.TaskmasterRadiusNextPart = CurTime() + 0.005
                        ply.TaskmasterRadiusDir = ply.TaskmasterRadiusDir + MathPi / 24
                        local vec = Vector(MathSin(ply.TaskmasterRadiusDir) * range, MathCos(ply.TaskmasterRadiusDir) * range, 10)
                        local particle = ply.TaskmasterRadiusEmitter:Add("particle/wisp.vmt", pos + vec)
                        particle:SetVelocity(particleVelocity)
                        particle:SetDieTime(0.5)
                        particle:SetStartAlpha(200)
                        particle:SetEndAlpha(0)
                        particle:SetStartSize(3)
                        particle:SetEndSize(2)
                        particle:SetRoll(MathRand(0, MathPi))
                        particle:SetRollDelta(0)
                        particle:SetColor(255, 255, 255)
                    end
                    ply.TaskmasterRadiusDir = ply.TaskmasterRadiusDir + 0.02
                end
                shouldDraw = true
            end

            if not shouldDraw and ply.TaskmasterRadiusEmitter then
                ply.TaskmasterRadiusEmitter:Finish()
                ply.TaskmasterRadiusEmitter = nil
                ply.TaskmasterRadiusDir = nil
                ply.TaskmasterRadiusNextPart = nil
            end
        end)
    end)

    net.Receive("TTT_Taskmaster_KillFaraway_Cleanup", function()
        local client = LocalPlayer()
        local sid64 = client:SteamID64()
        hook.Remove("TTTTargetIDPlayerText", "Taskmaster_KillFaraway_TTTTargetIDPlayerText_"  .. sid64)
        hook.Remove("TTTPlayerAliveClientThink", "Taskmaster_KillFaraway_TTTPlayerAliveClientThink_" .. sid64)

        if client.TaskmasterRadiusEmitter then
            client.TaskmasterRadiusEmitter:Finish()
            client.TaskmasterRadiusEmitter = nil
            client.TaskmasterRadiusDir = nil
            client.TaskmasterRadiusNextPart = nil
        end
    end)
end

TASKMASTER.RegisterTask(TASK)