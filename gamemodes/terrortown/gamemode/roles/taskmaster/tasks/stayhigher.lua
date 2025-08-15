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

TASK.id = "stayhigher"

local taskmaster_stayhigher_time = CreateConVar("ttt_taskmaster_stayhigher_time", "30", FCVAR_REPLICATED, "The time (in seconds) a player must stay higher up to complete the 'Highest Player' task", 1, 240)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_stayhigher_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    local time = taskmaster_stayhigher_time:GetInt()
    local name = "Highest For " .. time .. " Second"
    if time ~= 1 then
        name = name .. "s"
    end
    return name
end

TASK.Description = function(ply)
    local time = taskmaster_stayhigher_time:GetInt()
    local desc = "Stay higher up than all players for " .. time .. " second"
    if time ~= 1 then
        desc = desc .. "s"
    end
    return desc
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_StayHigher_Assigned")
    util.AddNetworkString("TTT_Taskmaster_StayHigher_Cleanup")

    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_PROGRESSBAR
    }

    local function GetHighestPlayer()
        local highest = nil
        for _, p in PlayerIterator() do
            if not p:Alive() or p:IsSpec() then continue end

            local pos = p:GetPos()
            if not highest or pos.z > highest.z then
                highest = {
                    ply = p,
                    z = pos.z
                }
            end
        end

        return highest.ply
    end

    TASK.OnTaskAssigned = function(ply)
        local time = taskmaster_stayhigher_time:GetInt()
        timer.Create("TTTTaskmasterStayHigherTimer", 0.1, 0, function()
            if not IsPlayer(ply) then return end
            if not ply:Alive() or ply:IsSpec() then
                ply:ClearProperty("Task_StayHigherStart", ply)
                return
            end

            local highest = GetHighestPlayer()
            if IsPlayer(highest) and highest == ply then
                -- Just starting
                if not ply.Task_StayHigherStart then
                    ply:SetProperty("Task_StayHigherStart", CurTime(), ply)
                -- Long enough
                elseif CurTime() > ply.Task_StayHigherStart + time then
                    ply:CompleteTask(TASK.id)
                end
            -- Not highest anymore
            else
                ply:ClearProperty("Task_StayHigherStart", ply)
            end
        end)

        net.Start("TTT_Taskmaster_StayHigher_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        timer.Remove("TTTTaskmasterStayHigherTimer")

        ply:ClearProperty("Task_StayHigherStart", ply)

        net.Start("TTT_Taskmaster_StayHigher_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    net.Receive("TTT_Taskmaster_StayHigher_Assigned", function()
        local client = LocalPlayer()
        local sid64 = client:SteamID64()
        local time = taskmaster_stayhigher_time:GetInt()

        hook.Add("HUDPaint", "Taskmaster_StayHigher_HUDPaint_" .. sid64, function()
            if not client:IsActiveTaskmaster() then return end

            local startTime = client.Task_StayHigherStart
            if not startTime then return end

            local PT = LANG.GetParamTranslation
            local elapsed = MathMax(0, CurTime() - startTime)
            local remaining = time - elapsed
            local message = PT("taskmaster_stayhigher", { time = util.SimpleTime(remaining, "%02i:%02i") })
            local color = Color(25, 200, 25, 155)

            local x = ScrW() / 2.0
            local y = ScrH() / 2.0
            y = y + (y / 3)

            local w = 300
            local progress = elapsed / time

            CRHUD:PaintProgressBar(x, y, w, color, message, progress)
        end)
    end)

    net.Receive("TTT_Taskmaster_StayHigher_Cleanup", function()
        local client = LocalPlayer()
        local sid64 = client:SteamID64()
        hook.Remove("HUDPaint", "Taskmaster_StayHigher_HUDPaint_" .. sid64)
    end)
end

TASKMASTER.RegisterTask(TASK)