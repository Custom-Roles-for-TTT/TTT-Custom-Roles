local hook = hook
local table = table

local TableHasValue = table.HasValue

local TASK = {}

TASK.id = "dodamage"

local taskmaster_dodamage_amount = CreateConVar("ttt_taskmaster_dodamage_amount", "200", FCVAR_REPLICATED, "The amount of damage a player must do to complete the 'Do X Damage' task", 1, 1000)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_dodamage_amount",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    local amount = taskmaster_dodamage_amount:GetInt()

    local progress = 0
    if TableHasValue(ply.taskmasterCompletedTasks, TASK.id) then
        progress = amount
    else
        progress = ply.Task_DoDamageTotal
    end

    return "Deal " .. amount .. " Damage (" .. progress .. "/" .. amount .. ")"
end

TASK.Description = function(ply)
    local amount = taskmaster_dodamage_amount:GetInt()
    return "Deal " .. amount .. " damage to props and other players"
end

if SERVER then
    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {}

    TASK.OnTaskAssigned = function(ply)
        local amount = taskmaster_dodamage_amount:GetInt()
        ply:SetProperty("Task_DoDamageTotal", 0, ply)
        hook.Add("PostEntityTakeDamage", "Taskmaster_DoDamage_PostEntityTakeDamage_" .. ply:SteamID64(), function(entity, dmginfo, wasDamageTaken)
            if not wasDamageTaken then return end
            if entity == ply then return end

            local attacker = dmginfo:GetAttacker()
            if not IsPlayer(attacker) or attacker ~= ply then return end

            ply:SetProperty("Task_DoDamageTotal", ply.Task_DoDamageTotal + dmginfo:GetDamage(), ply)
            if ply.Task_DoDamageTotal >= amount then
                ply:CompleteTask(TASK.id)
            end
        end)
    end

    TASK.OnTaskRemoved = function(ply)
        hook.Remove("PostEntityTakeDamage", "Taskmaster_DoDamage_PostEntityTakeDamage_" .. ply:SteamID64())

        ply:ClearProperty("Task_DoDamageTotal", ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

TASKMASTER.RegisterTask(TASK)