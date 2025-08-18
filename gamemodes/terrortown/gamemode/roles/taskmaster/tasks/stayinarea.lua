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
local MathFloor = math.floor
local TableHasValue = table.HasValue

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

    local progress = 0
    if TableHasValue(ply.taskmasterCompletedTasks, TASK.id) then
        progress = time
    else
        local startTime = ply.Task_StayInAreaStart
        if startTime then
            progress = MathFloor(MathMax(0, CurTime() - startTime))
        end
    end

    return name .. " (" .. progress .. "/" .. time .. ")"
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
    TASK.Initialize = function()
        LANG.AddToLanguage("english", "taskmaster_stayinarea", "STAY IN AREA - {time}")
    end

    local function DrawLink(ply, targetPos)
        if not ply.TaskmasterStayInAreaLinkEmitter then ply.TaskmasterStayInAreaLinkEmitter = ParticleEmitter(targetPos) end
        if not ply.TaskmasterStayInAreaLinkNextPart then ply.TaskmasterStayInAreaLinkNextPart = CurTime() end
        if not ply.TaskmasterStayInAreaLinkOffset then ply.TaskmasterStayInAreaLinkOffset = 0 end
        local startPos = ply:GetPos() + Vector(0, 0, 30)
        local endPos = targetPos + Vector(0, 0, 30)
        local dir = endPos - startPos
        dir = dir:GetNormalized() * 50
        if ply.TaskmasterStayInAreaLinkNextPart < CurTime() then
            local pos = startPos + (dir * ply.TaskmasterStayInAreaLinkOffset)
            -- Use DistToSqr as it's more efficient and this is called very frequently
            -- 9000000 = 3000^2
            while startPos:DistToSqr(pos) <= 9000000 and startPos:DistToSqr(pos) <= startPos:DistToSqr(endPos) do
                ply.TaskmasterStayInAreaLinkEmitter:SetPos(pos)
                ply.TaskmasterStayInAreaLinkNextPart = CurTime() + 0.02
                local particle = ply.TaskmasterStayInAreaLinkEmitter:Add("particle/wisp.vmt", pos)
                particle:SetVelocity(vector_origin)
                particle:SetDieTime(0.25)
                particle:SetStartAlpha(200)
                particle:SetEndAlpha(0)
                particle:SetStartSize(3)
                particle:SetEndSize(2)
                particle:SetRoll(MathRand(0, MathPi))
                particle:SetRollDelta(0)
                local color = ROLE_COLORS[ROLE_TRAITOR]
                particle:SetColor(color.r, color.g, color.b)
                pos:Add(dir)
            end
            ply.TaskmasterStayInAreaLinkOffset = ply.TaskmasterStayInAreaLinkOffset + 0.04
            if ply.TaskmasterStayInAreaLinkOffset > 1 then
                ply.TaskmasterStayInAreaLinkOffset = 0
            end
        end
    end

    local function RemoveLink(ply)
        if ply.TaskmasterStayInAreaLinkEmitter then
            ply.TaskmasterStayInAreaLinkEmitter:Finish()
            ply.TaskmasterStayInAreaLinkEmitter = nil
            ply.TaskmasterStayInAreaLinkNextPart = nil
            ply.TaskmasterStayInAreaLinkOffset = nil
        end
    end

    local function RemoveRadius(ply)
        if ply.TaskmasterRadiusEmitter then
            ply.TaskmasterRadiusEmitter:Finish()
            ply.TaskmasterRadiusEmitter = nil
            ply.TaskmasterRadiusNextPart = nil
            ply.TaskmasterRadiusDir = nil
        end
    end

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

                if distance > rangeSqr then
                    DrawLink(ply, pos)
                else
                    RemoveLink(ply)
                end
                shouldDraw = true
            end

            if not shouldDraw then
                RemoveRadius(ply)
                RemoveLink(ply)
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
            local color = Color(0, 255, 0, 155)

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

        RemoveRadius(client)
        RemoveLink(client)
    end)
end

TASKMASTER.RegisterTask(TASK)