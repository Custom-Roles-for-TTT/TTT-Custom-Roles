local CurTime = CurTime
local hook = hook
local math = math
local net = net
local table = table
local timer = timer
local util = util

local MathMax = math.max

local TASK = {}

TASK.id = "takedamage"

local taskmaster_takedamage_time = CreateConVar("ttt_taskmaster_takedamage_time", "60", FCVAR_REPLICATED, "The time (in seconds) a player must survive without taking further damage to complete the 'Take Damage' task", 1, 240)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_takedamage_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    return "Take Damage"
end

TASK.Description = function(ply)
    local time = taskmaster_takedamage_time:GetInt()
    local desc = "Take damage and survive for " .. time .. " second"
    if time ~= 1 then
        desc = desc .. "s"
    end
    return desc
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_TakeDamage_Assigned")
    util.AddNetworkString("TTT_Taskmaster_TakeDamage_Cleanup")

    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_PROGRESSBAR
    }

    TASK.OnTaskAssigned = function(ply)
        local time = taskmaster_takedamage_time:GetInt()
        timer.Create("TTTTaskmasterTakeDamageTimer", 0.1, 0, function()
            if not IsPlayer(ply) then return end
            if not ply:Alive() or ply:IsSpec() then return end
            if not ply.Task_TakeDamageStart then return end
            if CurTime() <= ply.Task_TakeDamageStart + time then return end

            ply:CompleteTask(TASK.id)
        end)

        hook.Add("PostEntityTakeDamage", "Taskmaster_TakeDamage_PostEntityTakeDamage_" .. ply:SteamID64(), function(entity, dmginfo, wasDamageTaken)
            if not wasDamageTaken then return end
            if entity ~= ply then return end
            ply:SetProperty("Task_TakeDamageStart", CurTime(), ply)
        end)

        net.Start("TTT_Taskmaster_TakeDamage_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        timer.Remove("TTTTaskmasterTakeDamageTimer")

        hook.Remove("PostEntityTakeDamage", "Taskmaster_TakeDamage_PostEntityTakeDamage_" .. ply:SteamID64())

        ply:ClearProperty("Task_TakeDamageStart", ply)

        net.Start("TTT_Taskmaster_TakeDamage_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    net.Receive("TTT_Taskmaster_TakeDamage_Assigned", function()
        local client = LocalPlayer()
        local time = taskmaster_takedamage_time:GetInt()

        hook.Add("HUDPaint", "Taskmaster_TakeDamage_HUDPaint_" .. client:SteamID64(), function()
            if not client:IsActiveTaskmaster() then return end

            local startTime = client.Task_TakeDamageStart
            if not startTime then return end

            local PT = LANG.GetParamTranslation
            local elapsed = MathMax(0, CurTime() - startTime)
            local remaining = time - elapsed
            local message = PT("taskmaster_takedamage", { time = util.SimpleTime(remaining, "%02i:%02i") })
            local color = Color(0, 255, 0, 155)

            local x = ScrW() / 2.0
            local y = ScrH() / 2.0
            y = y + (y / 3)

            local w = 300
            local progress = elapsed / time

            CRHUD:PaintProgressBar(x, y, w, color, message, progress)
        end)
    end)

    net.Receive("TTT_Taskmaster_TakeDamage_Cleanup", function()
        local client = LocalPlayer()
        hook.Remove("HUDPaint", "Taskmaster_TakeDamage_HUDPaint_" .. client:SteamID64())
    end)
end

TASKMASTER.RegisterTask(TASK)