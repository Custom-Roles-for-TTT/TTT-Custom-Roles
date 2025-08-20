local hook = hook
local table = table

local TableHasValue = table.HasValue

local TASK = {}

TASK.id = "crowbar"

local taskmaster_crowbar_times = CreateConVar("ttt_taskmaster_crowbar_times", "50", FCVAR_REPLICATED, "The number of times a player must use their crowbar to complete the 'Swing Crowbar' task", 1, 240)
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_crowbar_times",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

TASK.Name = function(ply)
    local times = taskmaster_crowbar_times:GetInt()
    local name = "Swing a Crowbar " .. times .. " Time"
    if times ~= 1 then
        name = name .. "s"
    end

    if not ply then return name end

    local progress
    if TableHasValue(ply.TaskmasterCompletedTasks, TASK.id) then
        progress = times
    else
        progress = ply.Task_CrowbarCount or 0
    end

    return name .. " (" .. progress .. "/" .. times .. ")"
end

TASK.Description = function(ply)
    local times = taskmaster_crowbar_times:GetInt()
    local desc = "Attack with a crowbar " .. times .. " time"
    if times ~= 1 then
        desc = desc .. "s"
    end
    return desc
end

if SERVER then
    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {}

    local function SetupPrimaryAttack(ply, wep)
        if wep.Task_CrowbarPrimaryAttack then return end

        local times = taskmaster_crowbar_times:GetInt()
        ply:SetProperty("Task_CrowbarCount", 0, ply)
        wep.Task_CrowbarPrimaryAttack = wep.PrimaryAttack
        wep.PrimaryAttack = function(this, worldsnd)
            wep.Task_CrowbarPrimaryAttack(wep, worldsnd)
            ply:SetProperty("Task_CrowbarCount", ply.Task_CrowbarCount + 1, ply)
            if ply.Task_CrowbarCount >= times then
                ply:CompleteTask(TASK.id)
            end
        end
    end

    local function ClearPrimaryAttack(wep)
        if not wep.Task_CrowbarPrimaryAttack then return end
        wep.PrimaryAttack = wep.Task_CrowbarPrimaryAttack
        wep.Task_CrowbarPrimaryAttack = nil
    end

    TASK.OnTaskAssigned = function(ply)
        local crowbar = ply:GetWeapon("weapon_zm_improvised")
        if IsValid(crowbar) then
            SetupPrimaryAttack(ply, crowbar)
        end

        local sid64 = ply:SteamID64()
        hook.Add("WeaponEquip", "Taskmaster_Crowbar_WeaponEquip_" .. sid64, function(wep, owner)
            if owner ~= ply then return end
            if WEPS.GetClass(wep) ~= "weapon_zm_improvised" then return end
            SetupPrimaryAttack(ply, wep)
        end)

        hook.Add("PlayerDroppedWeapon", "Taskmaster_Crowbar_PlayerDroppedWeapon_" .. sid64, function( owner, wep)
            if owner ~= ply then return end
            if WEPS.GetClass(wep) ~= "weapon_zm_improvised" then return end
            ClearPrimaryAttack(wep)
        end)
    end

    TASK.OnTaskRemoved = function(ply)
        ClearPrimaryAttack(ply)

        local sid64 = ply:SteamID64()
        hook.Remove("WeaponEquip", "Taskmaster_Crowbar_WeaponEquip_" .. sid64)
        hook.Remove("PlayerDroppedWeapon", "Taskmaster_Crowbar_PlayerDroppedWeapon_" .. sid64)

        ply:ClearProperty("Task_CrowbarCount", ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

TASKMASTER.RegisterTask(TASK)