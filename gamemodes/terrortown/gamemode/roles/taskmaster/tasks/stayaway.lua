local CurTime = CurTime
local hook = hook
local math = math
local net = net
local player = player
local table = table
local util = util

local MathMax = math.max
local PlayerIterator = player.Iterator

local TASK = {}

TASK.id = "stayaway"

local taskmaster_stayaway_range = CreateConVar("ttt_taskmaster_stayaway_range", "25", FCVAR_REPLICATED, "The distance (in meters) a player must stay away from other people to count for the 'Stay Away' task", 1, 100)
local taskmaster_stayaway_time = CreateConVar("ttt_taskmaster_stayaway_time", "30", FCVAR_REPLICATED, "The time (in seconds) a player must stay away from other people to count for the 'Stay Away' task", 1, 240)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_stayaway_range",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_stayaway_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    local time = taskmaster_stayaway_time:GetInt()
    local name = "Stay Away for " .. time .. " Second"
    if time ~= 1 then
        name = name .. "s"
    end
    return name
end

TASK.Description = function(ply)
    local time = taskmaster_stayaway_time:GetInt()
    local desc = "Stay away from other players for " .. time .. " second"
    if time ~= 1 then
        desc = desc .. "s"
    end
    return desc
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_StayAway_Assigned")
    util.AddNetworkString("TTT_Taskmaster_StayAway_Cleanup")

    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_PROGRESSBAR
    }

    local function GetNearestPlayer(ply)
        local pos = ply:GetPos()
        local nearest = nil
        for _, p in PlayerIterator() do
            if p == ply then continue end
            if not p:Alive() or p:IsSpec() then continue end

            local dist = pos:DistToSqr(p:GetPos())
            if not nearest or dist < nearest.dist then
                nearest = {
                    ply = p,
                    dist = dist
                }
            end
        end

        return nearest
    end

    TASK.OnTaskAssigned = function(ply)
        local range = taskmaster_stayaway_range:GetInt() * UNITS_PER_METER
        local rangeSqr = range * range
        local time = taskmaster_stayaway_time:GetInt()
        timer.Create("TTTTaskmasterStayAwayTimer", 0.1, 0, function()
            if not IsPlayer(ply) then return end

            -- Within range
            local nearest = GetNearestPlayer(ply)
            if ply:Alive() and not ply:IsSpec() and nearest.dist >= rangeSqr then
                -- Just starting
                if not ply.Task_StayAwayStart then
                    ply:SetProperty("Task_StayAwayStart", CurTime(), ply)
                -- Long enough
                elseif CurTime() > ply.Task_StayAwayStart + time then
                    ply:CompleteTask(TASK.id)
                end
            -- Not within range
            else
                ply:ClearProperty("Task_StayAwayStart", ply)
            end
        end)

        net.Start("TTT_Taskmaster_StayAway_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        timer.Remove("TTTTaskmasterStayAwayTimer")

        ply:ClearProperty("Task_StayAwayLocation", ply)
        ply:ClearProperty("Task_StayAwayStart", ply)

        hook.Remove("PostPlayerDeath", "Taskmaster_StayAway_PostPlayerDeath_" .. ply:SteamID64())

        net.Start("TTT_Taskmaster_StayAway_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    net.Receive("TTT_Taskmaster_StayAway_Assigned", function()
        local client = LocalPlayer()
        local time = taskmaster_stayaway_time:GetInt()

        hook.Add("HUDPaint", "Taskmaster_StayAway_HUDPaint_" .. client:SteamID64(), function()
            if not client:IsActiveTaskmaster() then return end

            local startTime = client.Task_StayAwayStart
            if not startTime then return end

            local PT = LANG.GetParamTranslation
            local elapsed = MathMax(0, CurTime() - startTime)
            local remaining = time - elapsed
            local message = PT("taskmaster_stayaway", { time = util.SimpleTime(remaining, "%02i:%02i") })
            local color = Color(25, 200, 25, 155)

            local x = ScrW() / 2.0
            local y = ScrH() / 2.0
            y = y + (y / 3)

            local w = 300
            local progress = elapsed / time

            CRHUD:PaintProgressBar(x, y, w, color, message, progress)
        end)
    end)

    net.Receive("TTT_Taskmaster_StayAway_Cleanup", function()
        local client = LocalPlayer()
        hook.Remove("HUDPaint", "Taskmaster_StayAway_HUDPaint_" .. client:SteamID64())
    end)
end

TASKMASTER.RegisterTask(TASK)