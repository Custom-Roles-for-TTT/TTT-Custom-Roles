local hook = hook
local IsValid = IsValid
local pairs = pairs

local CallHook = hook.Call

function GetSprintMultiplier(ply, sprinting)
    local mult = 1
    if IsValid(ply) then
        local mults = {}
        CallHook("TTTSpeedMultiplier", nil, ply, mults, sprinting)
        for _, m in pairs(mults) do
            mult = mult * m
        end

        if sprinting and ply.mult then
            mult = mult * ply.mult
        end

        local wep = ply:GetActiveWeapon()
        if IsValid(wep) then
            local weaponClass = wep:GetClass()
            if weaponClass == "genji_melee" then
                return 1.4 * mult
            elseif weaponClass == "weapon_ttt_homebat" then
                return 1.25 * mult
            end
        end
    end

    return mult
end