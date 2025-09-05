local hook = hook
local ipairs = ipairs
local table = table
local math = math

local MathRandom = math.random
local TableInsert = table.insert

local TASK = {}

TASK.id = "killweapon"
TASK.IsKillTask = true

TASK.Name = function(ply)
    local weapon = "Specific Weapon"
    if CLIENT and ply and ply.Task_KillWeaponClass then
        for _, wep in ipairs(weapons.GetList()) do
            if ply.Task_KillWeaponClass == WEPS.GetClass(wep) then
                weapon = LANG.TryTranslation(wep.PrintName)
                break
            end
        end
    end

    local article = "a"
    if StartsWithVowel(weapon) then
        article = article .. "n"
    end
    return "Kill a Player With " .. article .. " " .. weapon
end

TASK.Description = function(ply)
    local weapon = "specific weapon"
    if CLIENT and ply and ply.Task_KillWeaponClass then
        for _, wep in ipairs(weapons.GetList()) do
            if ply.Task_KillWeaponClass == WEPS.GetClass(wep) then
                weapon = LANG.TryTranslation(wep.PrintName)
                break
            end
        end
    end
    return "Kill another player using a " .. weapon
end

if SERVER then
    TASK.CanAssignTask = function(ply)
        return true
    end

    TASK.RequiredFeatures = {}

    TASK.OnTaskAssigned = function(ply)
        local weps = {}
        for _, wep in ipairs(weapons.GetList()) do
            if wep.AutoSpawnable and wep.Kind == WEAPON_HEAVY and wep.Primary and wep.Primary.ClipMax and wep.Primary.Ammo and wep.Primary.Damage then
                TableInsert(weps, wep)
            end
        end
        ply:SetProperty("Task_KillWeaponClass", weps[MathRandom(#weps)].ClassName, ply)

        local equipped = false
        local active = ply:GetActiveWeapon()
        if active and active.Kind == WEAPON_HEAVY then
            equipped = true
        end

        for _, wep in pairs(ply:GetWeapons()) do
            if wep.Kind == WEAPON_HEAVY then
                ply:StripWeapon(wep:GetClass())
            end
        end

        local weapon = ply:Give(ply.Task_KillWeaponClass)
        local ammoMax = weapon.Primary.ClipMax
        local ammoType = weapon.Primary.Ammo
        weapon.AllowDrop = false

        if equipped then
            ply:SetFOV(0, 0.2)
            ply:SelectWeapon(ply.Task_KillWeaponClass)
        end

        local sid64 = ply:SteamID64()

        hook.Add("PlayerDeath", "Taskmaster_KillWeapon_PlayerDeath_" .. sid64, function(victim, inflictor, attacker)
            if not IsPlayer(victim) then return end
            if not IsPlayer(attacker) or not attacker:IsActiveTaskmaster() or attacker ~= ply then return end

            if IsValid(inflictor) and inflictor:IsWeapon() and inflictor:GetClass() == ply.Task_KillWeaponClass then
                ply:CompleteTask(TASK.id)
            end
        end)

        hook.Add("Think", "Taskmaster_KillWeapon_Think_" ..sid64, function()
            ply:SetAmmo(ammoMax, ammoType)
        end)
    end

    TASK.OnTaskRemoved = function(ply)
        hook.Remove("PlayerDeath", "Taskmaster_KillWeapon_PlayerDeath_" .. ply:SteamID64())
        hook.Remove("Think", "Taskmaster_KillWeapon_Think_" .. ply:SteamID64())

        for _, wep in pairs(ply:GetWeapons()) do
            if wep:GetClass() == ply.Task_KillWeaponClass then
                wep.AllowDrop = true
            end
        end

        ply:ClearProperty("Task_KillWeaponClass", ply)
    end

    TASK.OnTaskComplete = TASK.OnTaskRemoved
end

TASKMASTER.RegisterTask(TASK)