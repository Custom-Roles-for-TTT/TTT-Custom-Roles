local CurTime = CurTime
local hook = hook
local math = math
local net = net
local table = table
local timer = timer
local util = util

local MathCos = math.cos
local MathMax = math.max
local MathPi = math.pi
local MathRand = math.Rand
local MathSin = math.sin

local TASK = {}

TASK.id = "stayinarea"

local taskmaster_stayinarea_range = CreateConVar("ttt_taskmaster_stayinarea_range", "5", FCVAR_REPLICATED, "The distance (in meters) away from the location that a player must stay within to count for the 'Stay in Area' task", 1, 100)
local taskmaster_stayinarea_time = CreateConVar("ttt_taskmaster_stayinarea_time", "30", FCVAR_REPLICATED, "The time (in seconds) a player must stay inside the target area to count for the 'Stay in Area' task", 1, 240)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_stayinarea_range",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_stayinarea_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    local time = taskmaster_stayinarea_time:GetInt()
    local name = "Stay in Area for " .. time .. " Second"
    if time ~= 1 then
        name = name .. "s"
    end
    return name
end

TASK.Description = function(ply)
    local time = taskmaster_stayinarea_time:GetInt()
    local desc = "Stay in the marked area for " .. time .. " second"
    if time ~= 1 then
        desc = desc .. "s"
    end
    return desc
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_StayInArea_Assigned")
    util.AddNetworkString("TTT_Taskmaster_StayInArea_Cleanup")

    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_PROGRESSBAR,
        TASKMASTER_TF_PARTICLERADIUS
    }

    TASK.OnTaskAssigned = function(ply)
        ply:SetProperty("Task_StayInAreaLocation", ply:GetPos(), ply)

        local range = taskmaster_stayinarea_range:GetInt() * UNITS_PER_METER
        local rangeSqr = range * range
        local time = taskmaster_stayinarea_time:GetInt()
        timer.Create("TTTTaskmasterStayInAreaTimer", 0.1, 0, function()
            if not IsPlayer(ply) then return end

            -- Within range
            if ply:Alive() and not ply:IsSpec() and ply:GetPos():DistToSqr(ply.Task_StayInAreaLocation) <= rangeSqr then
                -- Just starting
                if not ply.Task_StayInAreaStart then
                    ply:SetProperty("Task_StayInAreaStart", CurTime(), ply)
                -- Long enough
                elseif CurTime() > ply.Task_StayInAreaStart + time then
                    ply:CompleteTask(TASK.id)
                end
            -- Not within range
            else
                ply:ClearProperty("Task_StayInAreaStart", ply)
            end
        end)

        net.Start("TTT_Taskmaster_StayInArea_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        timer.Remove("TTTTaskmasterStayInAreaTimer")

        ply:ClearProperty("Task_StayInAreaLocation", ply)
        ply:ClearProperty("Task_StayInAreaStart", ply)

        hook.Remove("PostPlayerDeath", "Taskmaster_StayInArea_PostPlayerDeath_" .. ply:SteamID64())

        net.Start("TTT_Taskmaster_StayInArea_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    net.Receive("TTT_Taskmaster_StayInArea_Assigned", function()
        local client = LocalPlayer()
        local sid64 = client:SteamID64()
        local range = taskmaster_stayinarea_range:GetInt() * UNITS_PER_METER
        local rangeSqr = range * range
        local time = taskmaster_stayinarea_time:GetInt()

        local particleVelocity = Vector(0, 0, 40)
        hook.Add("TTTPlayerAliveClientThink", "Taskmaster_StayInArea_TTTPlayerAliveClientThink_" .. sid64, function(cli, ply)
            local shouldDraw = false
            local pos = ply.Task_StayInAreaLocation
            if ply == cli and ply:IsActiveTaskmaster() and pos then
                if not ply.TaskmasterRadiusEmitter then ply.TaskmasterRadiusEmitter = ParticleEmitter(pos) end
                if not ply.TaskmasterRadiusNextPart then ply.TaskmasterRadiusNextPart = CurTime() end
                if not ply.TaskmasterRadiusDir then ply.TaskmasterRadiusDir = 0 end
                -- Use DistToSqr as it's more efficient and this is called very frequently
                local distance = ply:GetPos():DistToSqr(pos)
                -- 9000000 = 3000^2
                if ply.TaskmasterRadiusNextPart < CurTime() and distance <= 9000000 then
                    for _ = 1, 48 do
                        ply.TaskmasterRadiusEmitter:SetPos(pos)
                        ply.TaskmasterRadiusNextPart = CurTime() + 0.005
                        ply.TaskmasterRadiusDir = ply.TaskmasterRadiusDir + MathPi / 12
                        local vec = Vector(MathSin(ply.TaskmasterRadiusDir) * range, MathCos(ply.TaskmasterRadiusDir) * range, 10)
                        local particle = ply.TaskmasterRadiusEmitter:Add("particle/wisp.vmt", pos + vec)
                        particle:SetVelocity(particleVelocity)
                        particle:SetDieTime(0.25)
                        particle:SetStartAlpha(60)
                        particle:SetEndAlpha(0)
                        particle:SetStartSize(3)
                        particle:SetEndSize(2)
                        particle:SetRoll(MathRand(0, MathPi))
                        particle:SetRollDelta(0)
                        local color = ROLE_COLORS[ROLE_TRAITOR]
                        if distance <= rangeSqr then
                            color = ROLE_COLORS[ROLE_INNOCENT]
                        end
                        particle:SetColor(color.r, color.g, color.b)
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

        hook.Add("HUDPaint", "Taskmaster_StayInArea_HUDPaint_" .. sid64, function()
            if not client:IsActiveTaskmaster() then return end

            local startTime = client.Task_StayInAreaStart
            if not startTime then return end

            local PT = LANG.GetParamTranslation
            local elapsed = MathMax(0, CurTime() - startTime)
            local remaining = time - elapsed
            local message = PT("taskmaster_stayinarea", { time = util.SimpleTime(remaining, "%02i:%02i") })
            local color = Color(25, 200, 25, 155)

            local x = ScrW() / 2.0
            local y = ScrH() / 2.0
            y = y + (y / 3)

            local w = 300
            local progress = elapsed / time

            CRHUD:PaintProgressBar(x, y, w, color, message, progress)
        end)
    end)

    net.Receive("TTT_Taskmaster_StayInArea_Cleanup", function()
        local client = LocalPlayer()
        local sid64 = client:SteamID64()
        hook.Remove("TTTPlayerAliveClientThink", "Taskmaster_StayInArea_TTTPlayerAliveClientThink_" .. sid64)
        hook.Remove("HUDPaint", "Taskmaster_StayInArea_HUDPaint_" .. sid64)

        if client.TaskmasterRadiusEmitter then
            client.TaskmasterRadiusEmitter:Finish()
            client.TaskmasterRadiusEmitter = nil
            client.TaskmasterRadiusDir = nil
            client.TaskmasterRadiusNextPart = nil
        end
    end)
end

TASKMASTER.RegisterTask(TASK)