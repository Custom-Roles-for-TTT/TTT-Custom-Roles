local hook = hook
local table = table

local TableHasValue = table.HasValue

local TASK = {}

TASK.id = "weaponpickups"

local taskmaster_weaponpickups_count = CreateConVar("ttt_taskmaster_weaponpickups_count", "20", FCVAR_REPLICATED, "The number of unique weapons a player must pick up to complete the 'Pick Up Weapons' task", 1, 240)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_weaponpickups_count",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    local count = taskmaster_weaponpickups_count:GetInt()
    local name = "Pick up " .. count .. " Weapon"
    if count ~= 1 then
        name = name .. "s"
    end

    local progress
    if TableHasValue(ply.taskmasterCompletedTasks, TASK.id) then
        progress = count
    else
        progress = ply.Task_WeaponPickupsCount
    end

    return name .. " (" .. progress .. "/" .. count .. ")"
end

TASK.Description = function(ply)
    local count = taskmaster_weaponpickups_count:GetInt()
    local desc = "Pick up " .. count
    if count == 1 then
        return desc .. "weapon"
    end
    return desc .. " unique weapons from the ground"
end

if SERVER then
    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {}

    TASK.OnTaskAssigned = function(ply)
        local count = taskmaster_weaponpickups_count:GetInt()
        ply:SetProperty("Task_WeaponPickupsCount", 0, ply)
        hook.Add("WeaponEquip", "Taskmaster_WeaponPickup_WeaponEquip_" .. ply:SteamID64(), function(wep, owner)
            if owner ~= ply then return end
            if not IsValid(wep) then return end
            if wep.Task_WeaponPickupsUsed then return end
            wep.Task_WeaponPickupsUsed = true
            ply:SetProperty("Task_WeaponPickupsCount", ply.Task_WeaponPickupsCount + 1, ply)
            if ply.Task_WeaponPickupsCount >= count then
                ply:CompleteTask(TASK.id)
            end
        end)
    end

    TASK.OnTaskRemoved = function(ply)
        hook.Remove("WeaponEquip", "Taskmaster_WeaponPickup_WeaponEquip_" .. ply:SteamID64())

        ply:ClearProperty("Task_WeaponPickupsCount", ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

TASKMASTER.RegisterTask(TASK)