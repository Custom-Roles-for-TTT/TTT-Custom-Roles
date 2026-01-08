local hook = hook
local math = math
local table = table
local util = util

local MathAbs = math.abs
local MathMin = math.min
local MathMax = math.max

local TASK = {}

TASK.id = "kill360"
TASK.IsKillTask = true

local taskmaster_kill360_time = CreateConVar("ttt_taskmaster_kill360_time", "3", FCVAR_REPLICATED, "The time (in seconds) a player has after completing a 360 to kill a player for the 'Kill a Player After a 360' task", 1, 10)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_kill360_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    return "Kill a Player After a 360"
end

TASK.Description = function(ply)
    local description =  "Kill another player within "
    local time = taskmaster_kill360_time:GetInt()
    description = description .. time .. " second"
    if time ~= 1 then
        description = description .. "s"
    end
    return description .. " of turning 360 degrees"
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_Kill360_Assigned")
    util.AddNetworkString("TTT_Taskmaster_Kill360_Cleanup")

    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_PROGRESSBAR
    }

    TASK.OnTaskAssigned = function(ply)
        local sid64 = ply:SteamID64()

        ply.Task_Kill360LastTick = CurTime()
        ply.Task_Kill360LastAngle = ply:GetAimVector():Angle().y
        ply.Task_Kill360RotationDecay = 0
        ply.Task_Kill360RotationClockwise = 0
        ply.Task_Kill360RotationCounterClockwise = 0
        ply.Task_Kill360RotationDirection = 1

        hook.Add("PlayerDeath", "Taskmaster_Kill360_PlayerDeath_" .. sid64, function(victim, inflictor, attacker)
            if not IsPlayer(victim) then return end
            if not IsPlayer(attacker) or not attacker:IsActiveTaskmaster() or attacker ~= ply then return end

            if ply.Task_Kill360Start and CurTime() < ply.Task_Kill360Start + taskmaster_kill360_time:GetInt() then
                ply:CompleteTask(TASK.id)
            end
        end)

        local rotationDecayThreshold = 90 -- The Taskmaster needs to be turning at least 90 degrees per second to avoid rotation decay
        local rotationDecayMax = 120 -- Rotation will at most decay at a rate of 120 degrees per second
        local rotationDecayIncrement = 30 -- Rotation decay will build up at a rate of 30 degrees per second while not spinning
        local rotationDecayDecrement = 60 -- Rotation decay will reduce at a rate of 60 degrees per second while spinning

        hook.Add("Think", "Taskmaster_Kill360_Think_" ..sid64, function()
            local tickLength = CurTime() - ply.Task_Kill360LastTick
            ply.Task_Kill360LastTick = CurTime()

            local angle = ply:GetAimVector():Angle().y
            local angleDiff = angle - ply.Task_Kill360LastAngle
            while angleDiff > 180 do
                angleDiff = angleDiff - 360
            end
            while angleDiff < -180 do
                angleDiff = angleDiff + 360
            end
            ply.Task_Kill360LastAngle = angle

            if ply.Task_Kill360Start and CurTime() < ply.Task_Kill360Start + taskmaster_kill360_time:GetInt() then return end

            -- If the player is turning fast enough quickly decrease the decay value, otherwise slowly increase it
            if MathAbs(angleDiff) > rotationDecayThreshold * tickLength then
                ply.Task_Kill360RotationDecay = MathMax(ply.Task_Kill360RotationDecay - (rotationDecayDecrement * tickLength), 0)
            else
                ply.Task_Kill360RotationDecay = MathMin(ply.Task_Kill360RotationDecay + (rotationDecayIncrement * tickLength), rotationDecayMax * tickLength)
            end
            ply.Task_Kill360RotationClockwise = MathMax(ply.Task_Kill360RotationClockwise + angleDiff - ply.Task_Kill360RotationDecay, 0)
            ply.Task_Kill360RotationCounterClockwise = MathMax(ply.Task_Kill360RotationCounterClockwise - angleDiff - ply.Task_Kill360RotationDecay, 0)

            -- Smoothly transition if the player changes rotation direction
            if ply.Task_Kill360RotationClockwise > ply.Task_Kill360RotationCounterClockwise and ply.Task_Kill360RotationDirection == -1 then
                ply.Task_Kill360RotationDirection = 1
                ply.Task_Kill360RotationCounterClockwise = 0
            elseif ply.Task_Kill360RotationCounterClockwise > ply.Task_Kill360RotationClockwise and ply.Task_Kill360RotationDirection == 1 then
                ply.Task_Kill360RotationDirection = -1
                ply.Task_Kill360RotationClockwise = 0
            end

            if ply.Task_Kill360RotationDirection == 1 then
                ply:SetProperty("Task_Kill360Progress", ply.Task_Kill360RotationClockwise, ply)
            else
                ply:SetProperty("Task_Kill360Progress", ply.Task_Kill360RotationCounterClockwise, ply)
            end

            -- Give the player a little bit of leeway so they don't need to reach exactly 360 degrees
            if ply.Task_Kill360RotationClockwise > 320 or ply.Task_Kill360RotationCounterClockwise > 320 then
                ply.Task_Kill360RotationClockwise = 0
                ply.Task_Kill360RotationCounterClockwise = 0
                ply:SetProperty("Task_Kill360Start", CurTime(), ply)
            end
        end)

        net.Start("TTT_Taskmaster_Kill360_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        ply:ClearProperty("Task_Kill360Start", ply)
        ply:ClearProperty("Task_Kill360Progress", ply)
        ply.Task_Kill360LastTick = nil
        ply.Task_Kill360LastAngle = nil
        ply.Task_Kill360RotationDecay = nil
        ply.Task_Kill360RotationClockwise = nil
        ply.Task_Kill360RotationCounterClockwise = nil
        ply.Task_Kill360RotationDirection = nil

        local sid64 = ply:SteamID64()

        hook.Remove("PlayerDeath", "Taskmaster_Kill360_PlayerDeath_" .. sid64)
        hook.Remove("Think", "Taskmaster_Kill360_Think_" .. sid64)

        net.Start("TTT_Taskmaster_Kill360_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    TASK.Initialize = function()
        LANG.AddToLanguage("english", "taskmaster_kill360", "KILL SOMEONE - {time}")
    end

    net.Receive("TTT_Taskmaster_Kill360_Assigned", function()
        local client = LocalPlayer()
        local time = taskmaster_kill360_time:GetInt()

        hook.Add("HUDPaint", "Taskmaster_Kill360_HUDPaint_" .. client:SteamID64(), function()
            if not client:IsActiveTaskmaster() then return end

            local progress
            local message
            local color

            local startTime = client.Task_Kill360Start
            if not startTime or CurTime() > startTime + time then
                progress = client.Task_Kill360Progress / 320
                message = "DO A 360"
                color = Color(255, 0, 0, 155)
            else
                local PT = LANG.GetParamTranslation
                local elapsed = MathMax(0, CurTime() - startTime)
                local remaining = time - elapsed
                progress = 1 - (elapsed / time)
                message = PT("taskmaster_kill360", { time = util.SimpleTime(remaining, "%02i:%02i") })
                color = Color(0, 255, 0, 155)
            end

            local x = ScrW() / 2.0
            local y = ScrH() / 2.0
            y = y + (y / 3)

            local w = 300

            CRHUD:PaintProgressBar(x, y, w, color, message, progress)
        end)
    end)

    net.Receive("TTT_Taskmaster_Kill360_Cleanup", function()
        hook.Remove("HUDPaint", "Taskmaster_Kill360_HUDPaint_" .. LocalPlayer():SteamID64())
    end)
end

TASKMASTER.RegisterTask(TASK)