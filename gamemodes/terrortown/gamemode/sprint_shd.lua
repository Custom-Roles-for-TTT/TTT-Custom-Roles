local hook = hook
local ipairs = ipairs
local math = math
local player = player

local AddHook = hook.Add
local CallHook = hook.Call
local GetAllPlayers = player.GetAll
local MathClamp = math.Clamp

local staminaMax = 100
local sprintEnabled = true
local speedMultiplier = 0.4
local defaultRecovery = 0.08
local traitorRecovery = 0.12
local consumption = 0.2

function GetSprintMultiplier(ply, sprinting)
    local mult = 1
    if IsValid(ply) then
        local mults = {}
        CallHook("TTTSpeedMultiplier", nil, ply, mults, sprinting)
        for _, m in pairs(mults) do
            mult = mult * m
        end

        if sprinting then
            mult = mult * (1 + speedMultiplier)
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

local function ResetPlayerSprintState(ply)
    -- Just in case the data tables haven't been set up yet
    if ply.SetSprintStamina then
        ply:SetSprintStamina(staminaMax)
    end
end

local function HandleSprintStaminaComsumption(ply)
    -- Decrease the player's stamina based on the amount of time since the last tick
    local stamina = ply:GetSprintStamina() - FrameTime() * (MathClamp(consumption, 0.1, 5) * 250)

    -- Allow things to change the consumption rate
    local result = CallHook("TTTSprintStaminaPost", nil, ply, stamina, CurTime() - FrameTime(), consumption)
    -- Use the overwritten stamina if one is provided
    if result then stamina = result end

    ply:SetSprintStamina(MathClamp(stamina, 0, staminaMax))
end

local function HandleSprintStaminaRecovery(ply)
    local recovery = defaultRecovery
    if ply:IsTraitorTeam() or ply:IsMonsterTeam() or ply:IsIndependentTeam() then
        recovery = traitorRecovery
    end

    -- Allow things to change the recovery rate
    recovery = CallHook("TTTSprintStaminaRecovery", nil, ply, recovery) or recovery

    -- Increase the player's stamina based on the amount of time since the last tick
    local stamina = ply:GetSprintStamina() + FrameTime() * recovery * 250
    stamina = MathClamp(stamina, 0, staminaMax)

    ply:SetSprintStamina(MathClamp(stamina, 0, staminaMax))
end

AddHook("TTTPrepareRound", "TTTSprintPrepareRound", function()
    sprintEnabled = GetGlobalBool("ttt_sprint_enabled", true)
    speedMultiplier = GetGlobalFloat("ttt_sprint_bonus_rel", "0.4")
    defaultRecovery = GetGlobalFloat("ttt_sprint_regenerate_innocent", "0.08")
    traitorRecovery = GetGlobalFloat("ttt_sprint_regenerate_traitor", "0.12")
    consumption = GetGlobalFloat("ttt_sprint_consume", "0.2")

    if SERVER then
        for _, p in ipairs(GetAllPlayers()) do
            ResetPlayerSprintState(p)
        end
    else -- CLIENT
        ResetPlayerSprintState(LocalPlayer())
    end

    -- Add all the hooks in TTTPrepareRound so addons which remove them to disable sprinting (e.g. Randomats) are undone in each new round

    AddHook("Move", "TTTSprintMove", function(ply, _)
        local forwardKey = CallHook("TTTSprintKey", nil, ply) or IN_FORWARD
        local wasSprinting = ply:GetSprinting()
        local pressingSprint = ply:KeyDown(forwardKey) and ply:KeyDown(IN_SPEED)

        -- Only do this if the sprint state is actually changing
        if wasSprinting ~= pressingSprint then
            ply:SetSprinting(pressingSprint)
            CallHook("TTTSprintStateChange", nil, ply, pressingSprint, wasSprinting)
        -- Also call this hook if the player is still holding the button down but they are out of stamina
        -- so that things are notified that they have changed back to non-sprinting speed
        elseif pressingSprint and ply:GetSprintStamina() == 0 then
            CallHook("TTTSprintStateChange", nil, ply, false, true)
        end
    end)

    AddHook("FinishMove", "TTTSprintFinishMove", function(ply, _, _)
        if GetRoundState() == ROUND_WAIT then return end
        if not IsPlayer(ply) or not ply:Alive() or ply:IsSpec() then return end

        if ply:GetSprinting() then
            HandleSprintStaminaComsumption(ply)
        else
            HandleSprintStaminaRecovery(ply)
        end
    end)

    AddHook("TTTPlayerSpeedModifier", "TTTSprintPlayerSpeed", function(ply, _, _)
        if CLIENT and ply ~= LocalPlayer() then return end
        return GetSprintMultiplier(ply, sprintEnabled and ply:GetSprinting() and ply:GetSprintStamina() > 0)
    end)
end)