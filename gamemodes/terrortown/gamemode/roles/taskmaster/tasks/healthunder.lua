local CurTime = CurTime
local hook = hook
local math = math
local net = net
local table = table
local timer = timer
local util = util

local MathMax = math.max

local TASK = {}

TASK.id = "healthunder"

local taskmaster_healthunder_amount = CreateConVar("ttt_taskmaster_healthunder_amount", "15", FCVAR_REPLICATED, "The amount of health a player must stay under to complete the 'Health Under' task", 1, 240)
local taskmaster_healthunder_time = CreateConVar("ttt_taskmaster_healthunder_time", "60", FCVAR_REPLICATED, "The time (in seconds) a player must stay under the target health to complete the 'Health Under' task", 1, 240)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_healthunder_amount",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_healthunder_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    local amount = taskmaster_healthunder_amount:GetInt()
    return "Stay Under " .. amount .. " HP"
end

TASK.Description = function(ply)
    local time = taskmaster_healthunder_time:GetInt()
    local amount = taskmaster_healthunder_amount:GetInt()
    local desc = "Stay under " .. amount .. " health for " .. time .. " second"
    if time ~= 1 then
        desc = desc .. "s"
    end
    return desc
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_HealthUnder_Assigned")
    util.AddNetworkString("TTT_Taskmaster_HealthUnder_Cleanup")

    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_PROGRESSBAR
    }

    TASK.OnTaskAssigned = function(ply)
        local amount = taskmaster_healthunder_amount:GetInt()
        local time = taskmaster_healthunder_time:GetInt()
        timer.Create("TTTTaskmasterHealthUnderTimer", 0.1, 0, function()
            if not IsPlayer(ply) then return end

            if ply:Alive() and not ply:IsSpec() and ply:Health() < amount then
                -- Just starting
                if not ply.Task_HealthUnderStart then
                    ply:SetProperty("Task_HealthUnderStart", CurTime(), ply)
                -- Long enough
                elseif CurTime() > ply.Task_HealthUnderStart + time then
                    ply:CompleteTask(TASK.id)
                end
            -- Not under target health anymore
            else
                ply:ClearProperty("Task_HealthUnderStart", ply)
            end
        end)

        net.Start("TTT_Taskmaster_HealthUnder_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        timer.Remove("TTTTaskmasterHealthUnderTimer")

        ply:ClearProperty("Task_HealthUnderStart", ply)

        net.Start("TTT_Taskmaster_HealthUnder_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    net.Receive("TTT_Taskmaster_HealthUnder_Assigned", function()
        local client = LocalPlayer()
        local time = taskmaster_healthunder_time:GetInt()

        hook.Add("HUDPaint", "Taskmaster_HealthUnder_HUDPaint_" .. client:SteamID64(), function()
            if not client:IsActiveTaskmaster() then return end

            local startTime = client.Task_HealthUnderStart
            if not startTime then return end

            local PT = LANG.GetParamTranslation
            local elapsed = MathMax(0, CurTime() - startTime)
            local remaining = time - elapsed
            local message = PT("taskmaster_healthunder", { time = util.SimpleTime(remaining, "%02i:%02i") })
            local color = Color(25, 200, 25, 155)

            local x = ScrW() / 2.0
            local y = ScrH() / 2.0
            y = y + (y / 3)

            local w = 300
            local progress = elapsed / time

            CRHUD:PaintProgressBar(x, y, w, color, message, progress)
        end)
    end)

    net.Receive("TTT_Taskmaster_HealthUnder_Cleanup", function()
        local client = LocalPlayer()
        hook.Remove("HUDPaint", "Taskmaster_HealthUnder_HUDPaint_" .. client:SteamID64())
    end)
end

TASKMASTER.RegisterTask(TASK)