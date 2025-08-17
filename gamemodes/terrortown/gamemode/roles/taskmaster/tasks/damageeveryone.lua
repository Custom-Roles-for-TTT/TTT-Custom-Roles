local hook = hook
local net = net
local player = player
local table = table
local timer = timer
local util = util

local PlayerIterator = player.Iterator
local TableHasValue = table.HasValue
local TableInsert = table.insert

local TASK = {}

TASK.id = "damageeveryone"

TASK.Name = function(ply)
    local damaged = ply.Task_DamageEveryoneDamaged or {}
    local total = 0
    local progress = 0
    for _, p in PlayerIterator() do
        if ply == p then continue end
        if not p:Alive() or p:IsSpec() then continue end
        total = total + 1
        if TableHasValue(damaged, p:SteamID64()) then
            progress = progress + 1
        end
    end

    if (table.HasValue(ply.taskmasterCompletedTasks, TASK.id)) then
        progress = total
    end

    return "Damage Everyone Else (" .. progress .. "/" .. total .. ")"
end

TASK.Description = function(ply)
    return "Deal damage to all other living players"
end

if SERVER then
    util.AddNetworkString("TTT_Taskmaster_DamageEveryone_Assigned")
    util.AddNetworkString("TTT_Taskmaster_DamageEveryone_Cleanup")

    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {
        TASKMASTER_TF_TARGETID_PLAYERICON
    }

    TASK.OnTaskAssigned = function(ply)
        hook.Add("PostEntityTakeDamage", "Taskmaster_DamageEveryone_PostEntityTakeDamage_" .. ply:SteamID64(), function(entity, dmginfo, wasDamageTaken)
            if not wasDamageTaken then return end
            if entity == ply then return end

            local attacker = dmginfo:GetAttacker()
            if not IsPlayer(attacker) or attacker ~= ply then return end

            local vicSid64 = entity:SteamID64()
            local damaged = ply.Task_DamageEveryoneDamaged or {}
            if TableHasValue(damaged, vicSid64) then return end

            TableInsert(damaged, vicSid64)
            ply:SetProperty("Task_DamageEveryoneDamaged", damaged, ply)
        end)

        timer.Create("TTTTaskmasterDamageEveryoneTimer", 0.1, 0, function()
            if not IsPlayer(ply) then return end

            local damaged = ply.Task_DamageEveryoneDamaged or {}
            for _, p in PlayerIterator() do
                if ply == p then continue end
                if not p:Alive() or p:IsSpec() then continue end

                -- If this player hasn't been damaged yet, we're not done
                if not TableHasValue(damaged, p:SteamID64()) then return end
            end

            ply:CompleteTask(TASK.id)
        end)

        net.Start("TTT_Taskmaster_DamageEveryone_Assigned")
        net.Send(ply)
    end

    TASK.OnTaskRemoved = function(ply)
        hook.Remove("PostEntityTakeDamage", "Taskmaster_DamageEveryone_PostEntityTakeDamage_" .. ply:SteamID64())
        timer.Remove("TTTTaskmasterDamageEveryoneTimer")

        ply:ClearProperty("Task_DamageEveryoneDamaged", ply)

        net.Start("TTT_Taskmaster_DamageEveryone_Cleanup")
        net.Send(ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

if CLIENT then
    net.Receive("TTT_Taskmaster_DamageEveryone_Assigned", function()
        local client = LocalPlayer()
        hook.Add("TTTTargetIDPlayerTargetIcon", "Taskmaster_DamageEveryone_TTTTargetIDPlayerTargetIcon_" .. client:SteamID64(), function(ply, cli, showJester)
            if cli:IsActiveTaskmaster() and not TableHasValue(cli.Task_DamageEveryoneDamaged, ply:SteamID64()) then
                local iconColor = ROLE_COLORS_SPRITE[ROLE_TASKMASTER]
                return "task", true, iconColor, "down"
            end
        end)
    end)

    net.Receive("TTT_Taskmaster_DamageEveryone_Cleanup", function()
        local client = LocalPlayer()
        hook.Remove("TTTTargetIDPlayerTargetIcon", "Taskmaster_DamageEveryone_TTTTargetIDPlayerTargetIcon_"  .. client:SteamID64())
    end)
end

TASKMASTER.RegisterTask(TASK)