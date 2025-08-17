local CurTime = CurTime
local hook = hook
local math = math
local net = net
local table = table
local timer = timer
local util = util

local MathMax = math.max
local MathFloor = math.floor
local TableHasValue = table.HasValue

local TASK = {}

TASK.id = "standonplayer"

local taskmaster_standonplayer_time = CreateConVar("ttt_taskmaster_standonplayer_time", "15", FCVAR_REPLICATED, "The time (in seconds) a player must stay stand on top of another player to complete the 'Stand On Player' task", 1, 240)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_standonplayer_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    local time = taskmaster_standonplayer_time:GetInt()
    local name = "Stand on a Player for " .. time .. " Second"
    if time ~= 1 then
        name = name .. "s"
    end

    local progress = 0
    if TableHasValue(ply.taskmasterCompletedTasks, TASK.id) then
        progress = time
    else
        local startTime = ply.Task_StandOnPlayerStart
        if startTime then
            progress = MathFloor(MathMax(0, CurTime() - startTime))
        end
    end

    return name .. " (" .. progress .. "/" .. time .. ")"
end

TASK.Description = function(ply)
    local time = taskmaster_standonplayer_time:GetInt()
    local desc = "Stand on another player continuously for " .. time .. " second"
    if time ~= 1 then
        desc = desc .. "s"
    end
    return desc
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_StandOnPlayer_Assigned")
    util.AddNetworkString("TTT_Taskmaster_StandOnPlayer_Cleanup")

    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_PROGRESSBAR
    }

    TASK.OnTaskAssigned = function(ply)
        local time = taskmaster_standonplayer_time:GetInt()
        timer.Create("TTTTaskmasterStandOnPlayerTimer", 0.1, 0, function()
            if not IsPlayer(ply) then return end

            if ply:Alive() and not ply:IsSpec() and IsPlayer(ply:GetGroundEntity()) then
                -- Just starting
                if not ply.Task_StandOnPlayerStart then
                    ply:SetProperty("Task_StandOnPlayerStart", CurTime(), ply)
                -- Long enough
                elseif CurTime() > ply.Task_StandOnPlayerStart + time then
                    ply:CompleteTask(TASK.id)
                end
            -- Not standing on another player anymore
            else
                ply:ClearProperty("Task_StandOnPlayerStart", ply)
            end
        end)

        net.Start("TTT_Taskmaster_StandOnPlayer_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        timer.Remove("TTTTaskmasterStandOnPlayerTimer")

        ply:ClearProperty("Task_StandOnPlayerStart", ply)

        net.Start("TTT_Taskmaster_StandOnPlayer_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    net.Receive("TTT_Taskmaster_StandOnPlayer_Assigned", function()
        local client = LocalPlayer()
        local sid64 = client:SteamID64()
        local time = taskmaster_standonplayer_time:GetInt()

        hook.Add("HUDPaint", "Taskmaster_StandOnPlayer_HUDPaint_" .. sid64, function()
            if not client:IsActiveTaskmaster() then return end

            local startTime = client.Task_StandOnPlayerStart
            if not startTime then return end

            local PT = LANG.GetParamTranslation
            local elapsed = MathMax(0, CurTime() - startTime)
            local remaining = time - elapsed
            local message = PT("taskmaster_standonplayer", { time = util.SimpleTime(remaining, "%02i:%02i") })
            local color = Color(0, 255, 0, 155)

            local x = ScrW() / 2.0
            local y = ScrH() / 2.0
            y = y + (y / 3)

            local w = 300
            local progress = elapsed / time

            CRHUD:PaintProgressBar(x, y, w, color, message, progress)
        end)
    end)

    net.Receive("TTT_Taskmaster_StandOnPlayer_Cleanup", function()
        local client = LocalPlayer()
        local sid64 = client:SteamID64()
        hook.Remove("HUDPaint", "Taskmaster_StandOnPlayer_HUDPaint_" .. sid64)
    end)
end

TASKMASTER.RegisterTask(TASK)