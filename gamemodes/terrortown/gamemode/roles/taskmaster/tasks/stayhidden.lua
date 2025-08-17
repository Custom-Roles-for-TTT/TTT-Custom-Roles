local CurTime = CurTime
local hook = hook
local math = math
local net = net
local player = player
local table = table
local timer = timer
local util = util

local MathMax = math.max
local MathFloor = math.floor
local PlayerIterator = player.Iterator
local TableHasValue = table.HasValue

local TASK = {}

TASK.id = "stayhidden"

local taskmaster_stayhidden_time = CreateConVar("ttt_taskmaster_stayhidden_time", "30", FCVAR_REPLICATED, "The time (in seconds) a player must hide to complete for the 'Stay Hidden' task", 1, 240)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_stayhidden_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    local time = taskmaster_stayhidden_time:GetInt()
    local name = "Stay Hidden for " .. time .. " Second"
    if time ~= 1 then
        name = name .. "s"
    end

    local progress
    if TableHasValue(ply.taskmasterCompletedTasks, TASK.id) then
        progress = time
    else
        local startTime = ply.Task_StayHiddenStart
        if startTime then
            progress = MathFloor(MathMax(0, CurTime() - startTime))
        end
    end

    return name .. " (" .. progress .. "/" .. time .. ")"
end

TASK.Description = function(ply)
    local time = taskmaster_stayhidden_time:GetInt()
    local desc = "Stay hidden from other players for " .. time .. " second"
    if time ~= 1 then
        desc = desc .. "s"
    end
    return desc
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_StayHidden_Assigned")
    util.AddNetworkString("TTT_Taskmaster_StayHidden_Cleanup")

    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_PROGRESSBAR
    }

    local function IsTargetInView(ply, target)
        if not IsValid(ply) then return false end

        local tr = ply:GetEyeTrace(MASK_SHOT)
        return tr.Entity == target
    end

    local function IsHidden(ply)
        for _, p in PlayerIterator() do
            if ply == p then continue end

            -- Check IsOnScreen first because math is more efficient then sending traces this often
            if p:IsOnScreen(ply, 0.35) and IsTargetInView(p, ply) then
                return false
            end
        end
        return true
    end

    TASK.OnTaskAssigned = function(ply)
        local time = taskmaster_stayhidden_time:GetInt()
        timer.Create("TTTTaskmasterStayHiddenTimer", 0.1, 0, function()
            if not IsPlayer(ply) then return end

            if ply:Alive() and not ply:IsSpec() and IsHidden(ply) then
                -- Just starting
                if not ply.Task_StayHiddenStart then
                    ply:SetProperty("Task_StayHiddenStart", CurTime(), ply)
                -- Long enough
                elseif CurTime() > ply.Task_StayHiddenStart + time then
                    ply:CompleteTask(TASK.id)
                end
            -- Not within hidden
            else
                ply:ClearProperty("Task_StayHiddenStart", ply)
            end
        end)

        net.Start("TTT_Taskmaster_StayHidden_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        timer.Remove("TTTTaskmasterStayHiddenTimer")

        ply:ClearProperty("Task_StayHiddenStart", ply)

        net.Start("TTT_Taskmaster_StayHidden_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    net.Receive("TTT_Taskmaster_StayHidden_Assigned", function()
        local client = LocalPlayer()
        local time = taskmaster_stayhidden_time:GetInt()

        hook.Add("HUDPaint", "Taskmaster_StayHidden_HUDPaint_" .. client:SteamID64(), function()
            if not client:IsActiveTaskmaster() then return end

            local startTime = client.Task_StayHiddenStart
            if not startTime then return end

            local PT = LANG.GetParamTranslation
            local elapsed = MathMax(0, CurTime() - startTime)
            local remaining = time - elapsed
            local message = PT("taskmaster_stayhidden", { time = util.SimpleTime(remaining, "%02i:%02i") })
            local color = Color(0, 255, 0, 155)

            local x = ScrW() / 2.0
            local y = ScrH() / 2.0
            y = y + (y / 3)

            local w = 300
            local progress = elapsed / time

            CRHUD:PaintProgressBar(x, y, w, color, message, progress)
        end)
    end)

    net.Receive("TTT_Taskmaster_StayHidden_Cleanup", function()
        local client = LocalPlayer()
        hook.Remove("HUDPaint", "Taskmaster_StayHidden_HUDPaint_" .. client:SteamID64())
    end)
end

TASKMASTER.RegisterTask(TASK)