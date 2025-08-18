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

TASK.id = "carrycorpse"

local taskmaster_carrycorpse_time = CreateConVar("ttt_taskmaster_carrycorpse_time", "60", FCVAR_REPLICATED, "The time (in seconds) a player must carry a player corpse to complete the 'Carry Corpse' task", 1, 240)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_carrycorpse_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    local time = taskmaster_carrycorpse_time:GetInt()
    local name = "Carry a Corpse for " .. time .. " Second"
    if time ~= 1 then
        name = name .. "s"
    end

    local progress = 0
    if TableHasValue(ply.taskmasterCompletedTasks, TASK.id) then
        progress = time
    else
        local startTime = ply.Task_CarryCorpseStart
        if startTime then
            progress = MathFloor(MathMax(0, CurTime() - startTime))
        end
    end

    return name .. " (" .. progress .. "/" .. time .. ")"
end

TASK.Description = function(ply)
    local time = taskmaster_carrycorpse_time:GetInt()
    local desc = "Carry a dead player's corpse for " .. time .. " second"
    if time ~= 1 then
        desc = desc .. "s consecutively"
    end
    return desc
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_CarryCorpse_Assigned")
    util.AddNetworkString("TTT_Taskmaster_CarryCorpse_Cleanup")

    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_PROGRESSBAR
    }

    TASK.OnTaskAssigned = function(ply)
        local time = taskmaster_carrycorpse_time:GetInt()
        timer.Create("TTTTaskmasterCarryCorpseTimer", 0.1, 0, function()
            if not IsPlayer(ply) then return end

            local wep = ply:GetActiveWeapon()
            local wepClass = WEPS.GetClass(wep)
            if wepClass == "weapon_zm_carry" and IsRagdoll(wep.EntHolding) and IsPlayer(CORPSE.GetPlayer(wep.EntHolding)) then
                -- Just starting
                if not ply.Task_CarryCorpseStart then
                    ply:SetProperty("Task_CarryCorpseStart", CurTime(), ply)
                -- Long enough
                elseif CurTime() > ply.Task_CarryCorpseStart + time then
                    ply:CompleteTask(TASK.id)
                end
            -- Not carrying a corpse anymore
            else
                ply:ClearProperty("Task_CarryCorpseStart", ply)
            end
        end)

        net.Start("TTT_Taskmaster_CarryCorpse_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        timer.Remove("TTTTaskmasterCarryCorpseTimer")

        ply:ClearProperty("Task_CarryCorpseStart", ply)

        net.Start("TTT_Taskmaster_CarryCorpse_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    TASK.Initialize = function()
        LANG.AddToLanguage("english", "taskmaster_carrycorpse", "CARRY CORPSE - {time}")
    end

    net.Receive("TTT_Taskmaster_CarryCorpse_Assigned", function()
        local client = LocalPlayer()
        local sid64 = client:SteamID64()
        local time = taskmaster_carrycorpse_time:GetInt()

        hook.Add("HUDPaint", "Taskmaster_CarryCorpse_HUDPaint_" .. sid64, function()
            if not client:IsActiveTaskmaster() then return end

            local startTime = client.Task_CarryCorpseStart
            if not startTime then return end

            local PT = LANG.GetParamTranslation
            local elapsed = MathMax(0, CurTime() - startTime)
            local remaining = time - elapsed
            local message = PT("taskmaster_carrycorpse", { time = util.SimpleTime(remaining, "%02i:%02i") })
            local color = Color(0, 255, 0, 155)

            local x = ScrW() / 2.0
            local y = ScrH() / 2.0
            y = y + (y / 3)

            local w = 300
            local progress = elapsed / time

            CRHUD:PaintProgressBar(x, y, w, color, message, progress)
        end)
    end)

    net.Receive("TTT_Taskmaster_CarryCorpse_Cleanup", function()
        local client = LocalPlayer()
        local sid64 = client:SteamID64()
        hook.Remove("HUDPaint", "Taskmaster_CarryCorpse_HUDPaint_" .. sid64)
    end)
end

TASKMASTER.RegisterTask(TASK)