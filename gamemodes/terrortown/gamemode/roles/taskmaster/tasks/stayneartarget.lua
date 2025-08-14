local CurTime = CurTime
local cvars = cvars
local hook = hook
local math = math
local net = net
local player = player
local table = table
local util = util

local MathCos = math.cos
local MathMax = math.max
local MathPi = math.pi
local MathRand = math.Rand
local MathSin = math.sin

local TASK = {}

TASK.id = "stayneartarget"

local taskmaster_stayneartarget_range = CreateConVar("ttt_taskmaster_stayneartarget_range", "5", FCVAR_REPLICATED, "The distance (in meters) away a player must stay within to count for the 'Stay Near Target' task", 1, 100)
local taskmaster_stayneartarget_time = CreateConVar("ttt_taskmaster_stayneartarget_time", "30", FCVAR_REPLICATED, "The time (in seconds) a player must stay near their target to count for the 'Stay Near Target' task", 1, 240)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_stayneartarget_range",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_stayneartarget_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    local name = "Player"
    if IsPlayer(ply.Task_StayNearTargetPlayer) then
        name = ply.Task_StayNearTargetPlayer:Nick()
    end
    return "Stay Near " .. name
end

TASK.Description = function(ply)
    local unit
    if SERVER then
        unit = 1
    else
        unit = cvars.Number("ttt_distance_unit", 1)
    end
    local range = taskmaster_stayneartarget_range:GetInt()
    local description = "Stay within "
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

    local name = "Target"
    if IsPlayer(ply.Task_StayNearTargetPlayer) then
        name = ply.Task_StayNearTargetPlayer:Nick()
    end

    local time = taskmaster_stayneartarget_time:GetInt()
    description = description .. " of " .. name .. " for " .. time .. " second"
    if time == 1 then
        return description
    end
    return description .. "s"
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_StayNearTarget_Assigned")
    util.AddNetworkString("TTT_Taskmaster_StayNearTarget_Cleanup")

    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_TARGETID_PLAYERICON,
        TASKMASTER_TF_PROGRESSBAR,
        TASKMASTER_TF_PARTICLERADIUS
    }

    local function GetRandomTarget(ply)
        -- Find the first random living player
        for _, p in RandomPairs(player.GetAll()) do
            if not p:Alive() or p:IsSpec() then continue end
            if p == ply then continue end
            return p
        end
        return nil
    end

    TASK.OnTaskAssigned = function(ply)
        local target = GetRandomTarget(ply)

        ply:SetProperty("Task_StayNearTargetPlayer", target, ply)

        local range = taskmaster_stayneartarget_range:GetInt() * UNITS_PER_METER
        local rangeSqr = range * range
        local time = taskmaster_stayneartarget_time:GetInt()
        timer.Create("TTTTaskmasterStayNearTargetTimer", 0.1, 0, function()
            if not IsPlayer(ply) then return end
            if not IsPlayer(target) then return end

            -- Within range
            if ply:GetPos():DistToSqr(target:GetPos()) <= rangeSqr then
                -- Just starting
                if not ply.Task_StayNearTargetStart then
                    ply:SetProperty("Task_StayNearTargetStart", CurTime(), ply)
                -- Long enough
                elseif CurTime() > ply.Task_StayNearTargetStart + time then
                    ply:CompleteTask(TASK.id)
                end
            -- Not within range
            else
                ply:ClearProperty("Task_StayNearTargetStart", ply)
            end
        end)

        hook.Add("PostPlayerDeath", "Taskmaster_StayNearTarget_PostPlayerDeath_" .. ply:SteamID64(), function(victim)
            if ply.Task_StayNearTargetPlayer ~= victim then return end

            local newTarget = GetRandomTarget(ply)
            ply:QueueMessage(MSG_PRINTBOTH, "Your target for the '" .. TASK.Name(ply) .. "' task has died! Your new target is " .. newTarget:Nick())

            -- Overwrite the previous target
            target = newTarget
            ply:SetProperty("Task_StayNearTargetPlayer", newTarget, ply)
        end)

        net.Start("TTT_Taskmaster_StayNearTarget_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        timer.Remove("TTTTaskmasterStayNearTargetTimer")

        ply:ClearProperty("Task_StayNearTargetPlayer", ply)
        ply:ClearProperty("Task_StayNearTargetStart", ply)

        hook.Remove("PostPlayerDeath", "Taskmaster_StayNearTarget_PostPlayerDeath_" .. ply:SteamID64())

        net.Start("TTT_Taskmaster_StayNearTarget_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    net.Receive("TTT_Taskmaster_StayNearTarget_Assigned", function()
        local client = LocalPlayer()
        local sid64 = client:SteamID64()
        local range = taskmaster_stayneartarget_range:GetInt() * UNITS_PER_METER
        local rangeSqr = range * range
        local time = taskmaster_stayneartarget_time:GetInt()

        hook.Add("TTTTargetIDPlayerTargetIcon", "Taskmaster_StayNearTarget_TTTTargetIDPlayerTargetIcon_" .. sid64, function(ply, cli, showJester)
            if cli:IsActiveTaskmaster() and ply == cli.Task_StayNearTargetPlayer then
                local iconColor = ROLE_COLORS_SPRITE[ROLE_TRAITOR]
                if cli:GetPos():DistToSqr(ply:GetPos()) <= rangeSqr then
                    iconColor = ROLE_COLORS_SPRITE[ROLE_INNOCENT]
                end
                return "task", true, iconColor, "up"
            end
        end)

        local particleVelocity = Vector(0, 0, 40)
        hook.Add("TTTPlayerAliveClientThink", "Taskmaster_StayNearTarget_TTTPlayerAliveClientThink_" .. sid64, function(cli, ply)
            local shouldDraw = false
            local target = cli.Task_StayNearTargetPlayer
            if ply == cli and cli:IsActiveTaskmaster() and IsPlayer(target) then
                local pos = target:GetPos()
                if not ply.TaskmasterRadiusEmitter then ply.TaskmasterRadiusEmitter = ParticleEmitter(pos) end
                if not ply.TaskmasterRadiusNextPart then ply.TaskmasterRadiusNextPart = CurTime() end
                if not ply.TaskmasterRadiusDir then ply.TaskmasterRadiusDir = 0 end
                -- Use DistToSqr as it's more efficient and this is called very frequently
                -- 9000000 = 3000^2
                if ply.TaskmasterRadiusNextPart < CurTime() and cli:GetPos():DistToSqr(pos) <= 9000000 then
                    for _ = 1, 48 do
                        ply.TaskmasterRadiusEmitter:SetPos(pos)
                        ply.TaskmasterRadiusNextPart = CurTime() + 0.005
                        ply.TaskmasterRadiusDir = ply.TaskmasterRadiusDir + MathPi / 12
                        local vec = Vector(MathSin(ply.TaskmasterRadiusDir) * range, MathCos(ply.TaskmasterRadiusDir) * range, 10)
                        local particle = ply.TaskmasterRadiusEmitter:Add("particle/wisp.vmt", pos + vec)
                        particle:SetVelocity(particleVelocity)
                        particle:SetDieTime(0.25)
                        particle:SetStartAlpha(60)
                        particle:SetEndAlpha(0)
                        particle:SetStartSize(3)
                        particle:SetEndSize(2)
                        particle:SetRoll(MathRand(0, MathPi))
                        particle:SetRollDelta(0)
                        local color = ROLE_COLORS[ROLE_TRAITOR]
                        if ply:GetPos():DistToSqr(target:GetPos()) <= rangeSqr then
                            color = ROLE_COLORS[ROLE_INNOCENT]
                        end
                        particle:SetColor(color.r, color.g, color.b)
                    end
                    ply.TaskmasterRadiusDir = ply.TaskmasterRadiusDir + 0.02
                end
                shouldDraw = true
            end

            if not shouldDraw and ply.TaskmasterRadiusEmitter then
                ply.TaskmasterRadiusEmitter:Finish()
                ply.TaskmasterRadiusEmitter = nil
                ply.TaskmasterRadiusDir = nil
                ply.TaskmasterRadiusNextPart = nil
            end
        end)

        hook.Add("HUDPaint", "Taskmaster_StayNearTarget_HUDPaint_" .. sid64, function()
            if not client:IsActiveTaskmaster() then return end

            local target = client.Task_StayNearTargetPlayer
            if not IsPlayer(target) then return end

            local startTime = client.Task_StayNearTargetStart
            if not startTime then return end

            local PT = LANG.GetParamTranslation
            local elapsed = MathMax(0, CurTime() - startTime)
            local remaining = time - elapsed
            local message = PT("taskmaster_stayneartarget", { time = util.SimpleTime(remaining, "%02i:%02i") })
            local color = Color(25, 200, 25, 155)

            local x = ScrW() / 2.0
            local y = ScrH() / 2.0
            y = y + (y / 3)

            local w = 300
            local progress = elapsed / time

            CRHUD:PaintProgressBar(x, y, w, color, message, progress)
        end)
    end)

    net.Receive("TTT_Taskmaster_StayNearTarget_Cleanup", function()
        local client = LocalPlayer()
        local sid64 = client:SteamID64()
        hook.Remove("TTTTargetIDPlayerTargetIcon", "Taskmaster_StayNearTarget_TTTTargetIDPlayerTargetIcon_"  .. sid64)
        hook.Remove("TTTPlayerAliveClientThink", "Taskmaster_StayNearTarget_TTTPlayerAliveClientThink_" .. sid64)
        hook.Remove("HUDPaint", "Taskmaster_StayNearTarget_HUDPaint_" .. sid64)

        if client.TaskmasterRadiusEmitter then
            client.TaskmasterRadiusEmitter:Finish()
            client.TaskmasterRadiusEmitter = nil
            client.TaskmasterRadiusDir = nil
            client.TaskmasterRadiusNextPart = nil
        end
    end)
end

TASKMASTER.RegisterTask(TASK)