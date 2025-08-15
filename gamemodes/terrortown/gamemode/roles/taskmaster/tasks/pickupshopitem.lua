local TASK = {}

TASK.id = "pickupshopitem"

TASK.Name = function(ply)
    return "Pick up Shop Item"
end

TASK.Description = function(ply)
    return "Pick up a shop item dropped on the ground"
end

if SERVER then
    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {}

    TASK.OnTaskAssigned = function(ply)
        hook.Add("WeaponEquip", "Taskmaster_PickUpShopItem_WeaponEquip_" .. ply:SteamID64(), function(wep, caller)
            if not IsPlayer(caller) then return end
            if caller ~= ply then return end
            if not IsValid(wep) or not wep.CanBuy or #wep.CanBuy == 0 then return end
            ply:CompleteTask(TASK.id)
        end)
    end

    TASK.OnTaskRemoved = function(ply)
        hook.Remove("WeaponEquip", "Taskmaster_PickUpShopItem_WeaponEquip_" .. ply:SteamID64())
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

TASKMASTER.RegisterTask(TASK)