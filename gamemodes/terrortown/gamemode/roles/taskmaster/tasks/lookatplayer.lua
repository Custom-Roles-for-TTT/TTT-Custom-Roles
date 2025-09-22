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

TASK.id = "lookatplayer"

local taskmaster_lookatplayer_time = CreateConVar("ttt_taskmaster_lookatplayer_time", "30", FCVAR_REPLICATED, "The time (in seconds) a player must look at their target to complete for the 'Look at Player' task", 1, 240)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_lookatplayer_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    local name = "Look at "
    if ply and IsPlayer(ply.Task_LookAtPlayerPlayer) then
        name = name .. ply.Task_LookAtPlayerPlayer:Nick()
    else
        name = name .. "Target"
    end

    if not ply then return name end

    local time = taskmaster_lookatplayer_time:GetInt()
    local progress = 0
    if TableHasValue(ply.TaskmasterCompletedTasks, TASK.id) then
        progress = time
    else
        local startTime = ply.Task_LookAtPlayerStart
        if startTime then
            progress = MathFloor(MathMax(0, CurTime() - startTime))
        end
    end

    return name .. " (" .. progress .. "/" .. time .. ")"
end

TASK.Description = function(ply)
    local name = "target"
    if ply and IsPlayer(ply.Task_LookAtPlayerPlayer) then
        name = ply.Task_LookAtPlayerPlayer:Nick()
    end
    local time = taskmaster_lookatplayer_time:GetInt()
    local desc = "Look at " .. name .. " continuously for " .. time .. " second"
    if time ~= 1 then
        desc = desc .. "s"
    end
    return desc
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_LookAtPlayer_Assigned")
    util.AddNetworkString("TTT_Taskmaster_LookAtPlayer_Cleanup")

    local function GetRandomTarget(ply)
        -- Find the first random living player
        for _, p in RandomPairs(player.GetAll()) do
            if not p:Alive() or p:IsSpec() then continue end
            if p == ply then continue end
            return p
        end
        return nil
    end

    TASK.CanAssignTask = function(ply)
        return GetRandomTarget(ply) ~= nil
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_TARGETID_PLAYERICON,
        TASKMASTER_TF_PROGRESSBAR
    }

    local function IsTargetInView(ply)
        if not IsValid(ply) then return false end

        local tr = ply:GetEyeTrace(MASK_SHOT)
        return tr.Entity == ply.Task_LookAtPlayerPlayer
    end

    TASK.OnTaskAssigned = function(ply)
        ply:SetProperty("Task_LookAtPlayerPlayer", GetRandomTarget(ply), ply)

        local sid64 = ply:SteamID64()
        local time = taskmaster_lookatplayer_time:GetInt()
        timer.Create("TTTTaskmasterLookAtPlayerTimer_" .. ply:SteamID64(), 0.1, 0, function()
            if not IsPlayer(ply) then return end
            if not IsPlayer(ply.Task_LookAtPlayerPlayer) then return end

            -- Check IsOnScreen first because math is more efficient then sending traces this often
            if ply:Alive() and not ply:IsSpec() and ply:IsOnScreen(ply.Task_LookAtPlayerPlayer, 0.35) and IsTargetInView(ply) then
                -- Just starting
                if not ply.Task_LookAtPlayerStart then
                    ply:SetProperty("Task_LookAtPlayerStart", CurTime(), ply)
                -- Long enough
                elseif CurTime() > ply.Task_LookAtPlayerStart + time then
                    ply:CompleteTask(TASK.id)
                end
            -- Not looking at the player
            else
                ply:ClearProperty("Task_LookAtPlayerStart", ply)
            end
        end)

        hook.Add("PlayerDeath", "Taskmaster_LookAtPlayer_PlayerDeath_" .. sid64, function(victim, inflictor, attacker)
            if ply.Task_LookAtPlayerPlayer ~= victim then return end

            local target = GetRandomTarget(ply)
            if target then
                ply:QueueMessage(MSG_PRINTBOTH, "Your target for the '" .. TASK.Name(ply) .. "' task has died! Your new target is " .. target:Nick())
                ply:SetProperty("Task_LookAtPlayerPlayer", target, ply)
            else
                ply:QueueMessage(MSG_PRINTBOTH, "Your target for the '" .. TASK.Name(ply) .. "' task has died! There are no new valid targets and you must reroll.")
            end
        end)

        hook.Add("PlayerDisconnected", "Taskmaster_LookAtPlayer_PlayerDisconnected_" .. sid64, function(leaver)
            if ply.Task_LookAtPlayerPlayer ~= leaver then return end

            local target = GetRandomTarget(ply)
            if target then
                ply:QueueMessage(MSG_PRINTBOTH, "Your target for the '" .. TASK.Name(ply) .. "' task has disappeared! Your new target is " .. target:Nick())
                ply:SetProperty("Task_LookAtPlayerPlayer", target, ply)
            else
                ply:QueueMessage(MSG_PRINTBOTH, "Your target for the '" .. TASK.Name(ply) .. "' task has disappeared!  There are no new valid targets and you must reroll.")
            end
        end)

        net.Start("TTT_Taskmaster_LookAtPlayer_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskComplete = function(ply)
        timer.Remove("TTTTaskmasterLookAtPlayerTimer_" .. ply:SteamID64())

        local sid64 = ply:SteamID64()
        hook.Remove("PlayerDeath", "Taskmaster_LookAtPlayer_PlayerDeath_" .. sid64)
        hook.Remove("PlayerDisconnected", "Taskmaster_LookAtPlayer_PlayerDisconnected_" .. sid64)

        ply:ClearProperty("Task_LookAtPlayerStart", ply)

        net.Start("TTT_Taskmaster_LookAtPlayer_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        TASK.OnTaskComplete(ply)
        ply:ClearProperty("Task_LookAtPlayerPlayer", ply) -- Don't clear the player name if the task was completed so it still shows up in the task name/description
    end
end

if CLIENT then
    TASK.Initialize = function()
        LANG.AddToLanguage("english", "taskmaster_lookatplayer", "KEEP LOOKING - {time}")
    end

    net.Receive("TTT_Taskmaster_LookAtPlayer_Assigned", function()
        local client = LocalPlayer()
        local sid64 = client:SteamID64()
        local time = taskmaster_lookatplayer_time:GetInt()

        hook.Add("TTTTargetIDPlayerTargetIcon", "Taskmaster_LookAtPlayer_TTTTargetIDPlayerTargetIcon_" .. sid64, function(ply, cli, showJester)
            if cli:IsActiveTaskmaster() and ply == cli.Task_LookAtPlayerPlayer then
                local iconColor = ROLE_COLORS_SPRITE[ROLE_INNOCENT]
                return "task", true, iconColor, "up"
            end
        end)

        hook.Add("HUDPaint", "Taskmaster_LookAtPlayer_HUDPaint_" .. sid64, function()
            if not client:IsActiveTaskmaster() then return end

            local startTime = client.Task_LookAtPlayerStart
            if not startTime then return end

            local PT = LANG.GetParamTranslation
            local elapsed = MathMax(0, CurTime() - startTime)
            local remaining = time - elapsed
            local message = PT("taskmaster_lookatplayer", { time = util.SimpleTime(remaining, "%02i:%02i") })
            local color = Color(0, 255, 0, 155)

            local x = ScrW() / 2.0
            local y = ScrH() / 2.0
            y = y + (y / 3)

            local w = 300
            local progress = elapsed / time

            CRHUD:PaintProgressBar(x, y, w, color, message, progress)
        end)
    end)

    net.Receive("TTT_Taskmaster_LookAtPlayer_Cleanup", function()
        local client = LocalPlayer()
        local sid64 = client:SteamID64()
        hook.Remove("TTTTargetIDPlayerTargetIcon", "Taskmaster_LookAtPlayer_TTTTargetIDPlayerTargetIcon_"  .. sid64)
        hook.Remove("HUDPaint", "Taskmaster_LookAtPlayer_HUDPaint_" .. sid64)
    end)
end

TASKMASTER.RegisterTask(TASK)