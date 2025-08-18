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

TASK.id = "crouch"

local taskmaster_crouch_time = CreateConVar("ttt_taskmaster_crouch_time", "40", FCVAR_REPLICATED, "The time (in seconds) a player must stay crouched to complete the 'Crouch Near Body' task", 1, 240)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_crouch_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    local time = taskmaster_crouch_time:GetInt()
    local name = "Crouch for " .. time .. " Second"
    if time ~= 1 then
        name = name .. "s"
    end

    local progress = 0
    if TableHasValue(ply.taskmasterCompletedTasks, TASK.id) then
        progress = time
    else
        local startTime = ply.Task_CrouchStart
        if startTime then
            progress = MathFloor(MathMax(0, CurTime() - startTime))
        end
    end

    return name .. " (" .. progress .. "/" .. time .. ")"
end

TASK.Description = function(ply)
    local time = taskmaster_crouch_time:GetInt()
    local desc = "Crouch continuously for " .. time .. " second"
    if time ~= 1 then
        desc = desc .. "s"
    end
    return desc
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_Crouch_Assigned")
    util.AddNetworkString("TTT_Taskmaster_Crouch_Cleanup")

    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_PROGRESSBAR
    }

    TASK.OnTaskAssigned = function(ply)
        local time = taskmaster_crouch_time:GetInt()
        timer.Create("TTTTaskmasterCrouchTimer", 0.1, 0, function()
            if not IsPlayer(ply) then return end

            if ply:Alive() and not ply:IsSpec() and ply:Crouching() then
                -- Just starting
                if not ply.Task_CrouchStart then
                    ply:SetProperty("Task_CrouchStart", CurTime(), ply)
                -- Long enough
                elseif CurTime() > ply.Task_CrouchStart + time then
                    ply:CompleteTask(TASK.id)
                end
            -- Not crouching anymore
            else
                ply:ClearProperty("Task_CrouchStart", ply)
            end
        end)

        net.Start("TTT_Taskmaster_Crouch_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        timer.Remove("TTTTaskmasterCrouchTimer")

        ply:ClearProperty("Task_CrouchStart", ply)

        net.Start("TTT_Taskmaster_Crouch_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    TASK.Initialize = function()
        LANG.AddToLanguage("english", "taskmaster_crouch", "STAY CROUCHING - {time}")
    end

    net.Receive("TTT_Taskmaster_Crouch_Assigned", function()
        local client = LocalPlayer()
        local time = taskmaster_crouch_time:GetInt()

        hook.Add("HUDPaint", "Taskmaster_Crouch_HUDPaint_" .. client:SteamID64(), function()
            if not client:IsActiveTaskmaster() then return end

            local startTime = client.Task_CrouchStart
            if not startTime then return end

            local PT = LANG.GetParamTranslation
            local elapsed = MathMax(0, CurTime() - startTime)
            local remaining = time - elapsed
            local message = PT("taskmaster_crouch", { time = util.SimpleTime(remaining, "%02i:%02i") })
            local color = Color(0, 255, 0, 155)

            local x = ScrW() / 2.0
            local y = ScrH() / 2.0
            y = y + (y / 3)

            local w = 300
            local progress = elapsed / time

            CRHUD:PaintProgressBar(x, y, w, color, message, progress)
        end)
    end)

    net.Receive("TTT_Taskmaster_Crouch_Cleanup", function()
        local client = LocalPlayer()
        hook.Remove("HUDPaint", "Taskmaster_Crouch_HUDPaint_" .. client:SteamID64())
    end)
end

TASKMASTER.RegisterTask(TASK)