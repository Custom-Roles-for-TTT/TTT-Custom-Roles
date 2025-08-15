local CurTime = CurTime
local hook = hook
local math = math
local net = net
local table = table
local util = util

local MathMax = math.max

local TASK = {}

TASK.id = "holstered"

local taskmaster_holstered_time = CreateConVar("ttt_taskmaster_holstered_time", "60", FCVAR_REPLICATED, "The time (in seconds) a player must stay holstered to complete the 'Holstered' task", 1, 240)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_holstered_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    local time = taskmaster_holstered_time:GetInt()
    local name = "Stay Holstered for " .. time .. " Second"
    if time ~= 1 then
        name = name .. "s"
    end
    return name
end

TASK.Description = function(ply)
    local time = taskmaster_holstered_time:GetInt()
    local desc = "Use the 'Holstered' weapon for " .. time .. " second"
    if time ~= 1 then
        desc = desc .. "s consecutively"
    end
    return desc
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_Holstered_Assigned")
    util.AddNetworkString("TTT_Taskmaster_Holstered_Cleanup")

    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_PROGRESSBAR
    }

    TASK.OnTaskAssigned = function(ply)
        local time = taskmaster_holstered_time:GetInt()
        timer.Create("TTTTaskmasterHolsteredTimer", 0.1, 0, function()
            if not IsPlayer(ply) then return end
            if not ply:Alive() or ply:IsSpec() then
                ply:ClearProperty("Task_HolsteredStart", ply)
                return
            end

            local wepClass = WEPS.GetClass(ply:GetActiveWeapon())
            if wepClass == "weapon_ttt_unarmed" then
                -- Just starting
                if not ply.Task_HolsteredStart then
                    ply:SetProperty("Task_HolsteredStart", CurTime(), ply)
                -- Long enough
                elseif CurTime() > ply.Task_HolsteredStart + time then
                    ply:CompleteTask(TASK.id)
                end
            -- Not using "holstered" anymore
            else
                ply:ClearProperty("Task_HolsteredStart", ply)
            end
        end)

        net.Start("TTT_Taskmaster_Holstered_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        timer.Remove("TTTTaskmasterHolsteredTimer")

        ply:ClearProperty("Task_HolsteredStart", ply)

        net.Start("TTT_Taskmaster_Holstered_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    net.Receive("TTT_Taskmaster_Holstered_Assigned", function()
        local client = LocalPlayer()
        local sid64 = client:SteamID64()
        local time = taskmaster_holstered_time:GetInt()

        hook.Add("HUDPaint", "Taskmaster_Holstered_HUDPaint_" .. sid64, function()
            if not client:IsActiveTaskmaster() then return end

            local startTime = client.Task_HolsteredStart
            if not startTime then return end

            local PT = LANG.GetParamTranslation
            local elapsed = MathMax(0, CurTime() - startTime)
            local remaining = time - elapsed
            local message = PT("taskmaster_holstered", { time = util.SimpleTime(remaining, "%02i:%02i") })
            local color = Color(25, 200, 25, 155)

            local x = ScrW() / 2.0
            local y = ScrH() / 2.0
            y = y + (y / 3)

            local w = 300
            local progress = elapsed / time

            CRHUD:PaintProgressBar(x, y, w, color, message, progress)
        end)
    end)

    net.Receive("TTT_Taskmaster_Holstered_Cleanup", function()
        local client = LocalPlayer()
        local sid64 = client:SteamID64()
        hook.Remove("HUDPaint", "Taskmaster_Holstered_HUDPaint_" .. sid64)
    end)
end

TASKMASTER.RegisterTask(TASK)