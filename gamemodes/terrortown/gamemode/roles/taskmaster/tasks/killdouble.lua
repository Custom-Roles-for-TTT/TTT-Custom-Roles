local CurTime = CurTime
local hook = hook
local math = math
local net = net
local table = table
local util = util

local MathMax = math.max

local TASK = {}

TASK.id = "killdouble"
TASK.isKillTask = true

local taskmaster_killdouble_time = CreateConVar("ttt_taskmaster_killdouble_time", "5", FCVAR_REPLICATED, "The time (in seconds) the taskmaster has between kills to complete the 'Get a Double Kill' task", 0, 30)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_killdouble_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    return "Get a Double Kill"
end

TASK.Description = function(ply)
    local description =  "Kill two players within "
    local time = taskmaster_killdouble_time:GetInt()
    description = description .. time .. " second"
    if time ~= 1 then
        description = description .. "s"
    end
    return description .. " of each other"
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_KillDouble_Assigned")
    util.AddNetworkString("TTT_Taskmaster_KillDouble_Cleanup")

    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_PROGRESSBAR
    }

    TASK.OnTaskAssigned = function(ply)
        hook.Add("PlayerDeath", "Taskmaster_KillPistol_PlayerDeath_" .. ply:SteamID64(), function(victim, inflictor, attacker)
            if not IsPlayer(victim) then return end
            if not IsPlayer(attacker) or not attacker:IsActiveTaskmaster() or attacker ~= ply then return end

            if not ply.Task_KillDoubleLastKill or CurTime() > ply.Task_KillDoubleLastKill + taskmaster_killdouble_time:GetInt() then
                ply:SetProperty("Task_KillDoubleLastKill", CurTime(), ply)
            else
                ply:CompleteTask(TASK.id)
            end
        end)

        net.Start("TTT_Taskmaster_KillDouble_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        ply:ClearProperty("Task_KillDoubleLastKill", ply)

        hook.Remove("PlayerDeath", "Taskmaster_KillPistol_PlayerDeath_" .. ply:SteamID64())

        net.Start("TTT_Taskmaster_KillDouble_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    TASK.Initialize = function()
        LANG.AddToLanguage("english", "taskmaster_killdouble", "KILL ANOTHER - {time}")
    end

    net.Receive("TTT_Taskmaster_KillDouble_Assigned", function()
        local client = LocalPlayer()
        local time = taskmaster_killdouble_time:GetInt()

        hook.Add("HUDPaint", "Taskmaster_KillDouble_HUDPaint_" .. client:SteamID64(), function()
            if not client:IsActiveTaskmaster() then return end

            local startTime = client.Task_KillDoubleLastKill
            if not startTime or CurTime() > startTime + time then return end

            local PT = LANG.GetParamTranslation
            local elapsed = MathMax(0, CurTime() - startTime)
            local remaining = time - elapsed
            local message = PT("taskmaster_killdouble", { time = util.SimpleTime(remaining, "%02i:%02i") })
            local color = Color(0, 255, 0, 155)

            local x = ScrW() / 2.0
            local y = ScrH() / 2.0
            y = y + (y / 3)

            local w = 300
            local progress = elapsed / time

            CRHUD:PaintProgressBar(x, y, w, color, message, 1 - progress)
        end)
    end)

    net.Receive("TTT_Taskmaster_KillDouble_Cleanup", function()
        hook.Remove("HUDPaint", "Taskmaster_KillDouble_HUDPaint_" .. LocalPlayer():SteamID64())
    end)
end

TASKMASTER.RegisterTask(TASK)