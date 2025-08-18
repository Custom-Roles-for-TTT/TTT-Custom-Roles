local CurTime = CurTime
local cvars = cvars
local ents = ents
local hook = hook
local math = math
local net = net
local table = table
local timer = timer
local util = util

local EntsFindByClass = ents.FindByClass
local MathMax = math.max
local MathFloor = math.floor
local TableHasValue = table.HasValue

local TASK = {}

TASK.id = "crouchnearbody"

local taskmaster_crouchnearbody_range = CreateConVar("ttt_taskmaster_crouchnearbody_range", "1", FCVAR_REPLICATED, "The distance (in meters) away a player must stay within to count for the 'Crouch Near Body' task", 1, 100)
local taskmaster_crouchnearbody_time = CreateConVar("ttt_taskmaster_crouchnearbody_time", "20", FCVAR_REPLICATED, "The time (in seconds) a player must stay near a body to count for the 'Crouch Near Body' task", 1, 240)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_crouchnearbody_range",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_crouchnearbody_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    local time = taskmaster_crouchnearbody_time:GetInt()

    local progress = 0
    if TableHasValue(ply.taskmasterCompletedTasks, TASK.id) then
        progress = time
    else
        local startTime = ply.Task_CrouchNearBodyStart
        if startTime then
            progress = MathFloor(MathMax(0, CurTime() - startTime))
        end
    end

    return "Crouch Near a Body (" .. progress .. "/" .. time .. ")"
end

TASK.Description = function(ply)
    local unit
    if SERVER then
        unit = 1
    else
        unit = cvars.Number("ttt_distance_unit", 1)
    end
    local range = taskmaster_crouchnearbody_range:GetInt()
    local description = "Crouch within "
    if unit == 1 then
        description = description .. range .. " meter"
        if range ~= 1 then
            description = description .. "s"
        end
    elseif unit == 2 then
        local convertedRange = math.ceil(range * FEET_PER_METER)
        description = description .. convertedRange
        if convertedRange == 1 then
            description = description .. " foot"
        else
            description = description .. " feet"
        end
    else
        local convertedRange = math.ceil(range * UNITS_PER_METER)
        description = description .. convertedRange .. " unit"
        if convertedRange ~= 1 then
            description = description .. "s"
        end
    end
    local time = taskmaster_crouchnearbody_time:GetInt()
    description = description .. " of a dead body for " .. time .. " second"
    if time == 1 then
        return description
    end
    return description .. "s"
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_CrouchNearBody_Assigned")
    util.AddNetworkString("TTT_Taskmaster_CrouchNearBody_Cleanup")

    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_PROGRESSBAR
    }

    TASK.OnTaskAssigned = function(ply)
        local range = taskmaster_crouchnearbody_range:GetInt() * UNITS_PER_METER
        local rangeSqr = range * range
        local time = taskmaster_crouchnearbody_time:GetInt()
        timer.Create("TTTTaskmasterCrouchNearBodyTimer", 0.1, 0, function()
            if not IsPlayer(ply) then return end
            if not ply:Alive() or ply:IsSpec() or not ply:Crouching() then
                ply:ClearProperty("Task_CrouchNearBodyStart", ply)
                return
            end

            for _, corpse in ipairs(EntsFindByClass("prop_ragdoll")) do
                local sourcePlayer = CORPSE.GetPlayer(corpse)
                if not IsPlayer(sourcePlayer) then continue end
                if sourcePlayer:Alive() or not sourcePlayer:IsSpec() then continue end

                -- Within range
                if ply:GetPos():DistToSqr(corpse:GetPos()) <= rangeSqr then
                    -- Just starting
                    if not ply.Task_CrouchNearBodyStart then
                        ply:SetProperty("Task_CrouchNearBodyStart", CurTime(), ply)
                    -- Long enough
                    elseif CurTime() > ply.Task_CrouchNearBodyStart + time then
                        ply:CompleteTask(TASK.id)
                    end
                -- Not within range
                else
                    ply:ClearProperty("Task_CrouchNearBodyStart", ply)
                end
            end
        end)

        net.Start("TTT_Taskmaster_CrouchNearBody_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        timer.Remove("TTTTaskmasterCrouchNearBodyTimer")

        ply:ClearProperty("Task_CrouchNearBodyStart", ply)

        net.Start("TTT_Taskmaster_CrouchNearBody_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    TASK.Initialize = function()
        LANG.AddToLanguage("english", "taskmaster_crouchnearbody", "CROUCH NEAR BODY - {time}")
    end

    net.Receive("TTT_Taskmaster_CrouchNearBody_Assigned", function()
        local client = LocalPlayer()
        local sid64 = client:SteamID64()
        local time = taskmaster_crouchnearbody_time:GetInt()

        hook.Add("HUDPaint", "Taskmaster_CrouchNearBody_HUDPaint_" .. sid64, function()
            if not client:IsActiveTaskmaster() then return end

            local startTime = client.Task_CrouchNearBodyStart
            if not startTime then return end

            local PT = LANG.GetParamTranslation
            local elapsed = MathMax(0, CurTime() - startTime)
            local remaining = time - elapsed
            local message = PT("taskmaster_crouchnearbody", { time = util.SimpleTime(remaining, "%02i:%02i") })
            local color = Color(0, 255, 0, 155)

            local x = ScrW() / 2.0
            local y = ScrH() / 2.0
            y = y + (y / 3)

            local w = 300
            local progress = elapsed / time

            CRHUD:PaintProgressBar(x, y, w, color, message, progress)
        end)
    end)

    net.Receive("TTT_Taskmaster_CrouchNearBody_Cleanup", function()
        local client = LocalPlayer()
        local sid64 = client:SteamID64()
        hook.Remove("HUDPaint", "Taskmaster_CrouchNearBody_HUDPaint_" .. sid64)
    end)
end

TASKMASTER.RegisterTask(TASK)