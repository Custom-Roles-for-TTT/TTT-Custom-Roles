local CurTime = CurTime
local hook = hook
local math = math
local net = net
local player = player
local table = table
local timer = timer
local util = util

local MathMax = math.max
local PlayerIterator = player.Iterator

local TASK = {}

TASK.id = "staylower"

local taskmaster_staylower_time = CreateConVar("ttt_taskmaster_staylower_time", "30", FCVAR_REPLICATED, "The time (in seconds) a player must stay lower down to complete the 'Lowest Player' task", 1, 240)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_staylower_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    local time = taskmaster_staylower_time:GetInt()
    local name = "Lowest for " .. time .. " Second"
    if time ~= 1 then
        name = name .. "s"
    end
    return name
end

TASK.Description = function(ply)
    local time = taskmaster_staylower_time:GetInt()
    local desc = "Stay lower down than all players for " .. time .. " second"
    if time ~= 1 then
        desc = desc .. "s"
    end
    return desc
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_StayLower_Assigned")
    util.AddNetworkString("TTT_Taskmaster_StayLower_Cleanup")

    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_PROGRESSBAR
    }

    local function GetLowestPlayer()
        local lowest = nil
        for _, p in PlayerIterator() do
            if not p:Alive() or p:IsSpec() then continue end

            local pos = p:GetPos()
            if not lowest or pos.z < lowest.z then
                lowest = {
                    ply = p,
                    z = pos.z
                }
            end
        end

        return lowest.ply
    end

    TASK.OnTaskAssigned = function(ply)
        local time = taskmaster_staylower_time:GetInt()
        timer.Create("TTTTaskmasterStayLowerTimer", 0.1, 0, function()
            if not IsPlayer(ply) then return end
            if not ply:Alive() or ply:IsSpec() then
                ply:ClearProperty("Task_StayLowerStart", ply)
                return
            end

            local lowest = GetLowestPlayer()
            if IsPlayer(lowest) and lowest == ply then
                -- Just starting
                if not ply.Task_StayLowerStart then
                    ply:SetProperty("Task_StayLowerStart", CurTime(), ply)
                -- Long enough
                elseif CurTime() > ply.Task_StayLowerStart + time then
                    ply:CompleteTask(TASK.id)
                end
            -- Not lowest anymore
            else
                ply:ClearProperty("Task_StayLowerStart", ply)
            end
        end)

        net.Start("TTT_Taskmaster_StayLower_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        timer.Remove("TTTTaskmasterStayLowerTimer")

        ply:ClearProperty("Task_StayLowerStart", ply)

        net.Start("TTT_Taskmaster_StayLower_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    net.Receive("TTT_Taskmaster_StayLower_Assigned", function()
        local client = LocalPlayer()
        local sid64 = client:SteamID64()
        local time = taskmaster_staylower_time:GetInt()

        hook.Add("HUDPaint", "Taskmaster_StayLower_HUDPaint_" .. sid64, function()
            if not client:IsActiveTaskmaster() then return end

            local startTime = client.Task_StayLowerStart
            if not startTime then return end

            local PT = LANG.GetParamTranslation
            local elapsed = MathMax(0, CurTime() - startTime)
            local remaining = time - elapsed
            local message = PT("taskmaster_staylower", { time = util.SimpleTime(remaining, "%02i:%02i") })
            local color = Color(25, 200, 25, 155)

            local x = ScrW() / 2.0
            local y = ScrH() / 2.0
            y = y + (y / 3)

            local w = 300
            local progress = elapsed / time

            CRHUD:PaintProgressBar(x, y, w, color, message, progress)
        end)
    end)

    net.Receive("TTT_Taskmaster_StayLower_Cleanup", function()
        local client = LocalPlayer()
        local sid64 = client:SteamID64()
        hook.Remove("HUDPaint", "Taskmaster_StayLower_HUDPaint_" .. sid64)
    end)
end

TASKMASTER.RegisterTask(TASK)