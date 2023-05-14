local hook = hook
local net = net

local CallHook = hook.Call
local AddHook = hook.Add
local MathMax = math.max
local MathMin = math.min

local function ConVars()
    net.Start("TTT_SprintGetConVars")
    net.SendToServer()
end

-- Set default Values
local sprintEnabled = false
local speedMultiplier = 0.4
local defaultRecovery = 0.08
local traitorRecovery = 0.12
local consumption = 0.3
local stamina = 100
local sprinting = false
local crosshairSize = 1
local sprintTimer = CurTime()
local recoveryTimer = CurTime()

-- Receive ConVars (SERVER)
net.Receive("TTT_SprintGetConVars", function()
    local convars = net.ReadTable()
    sprintEnabled = convars[1]
    speedMultiplier = convars[2]
    defaultRecovery = convars[3]
    traitorRecovery = convars[4]
    consumption = convars[5]
end)

-- Requesting ConVars first time
ConVars()

-- Change the Speed
local function SpeedChange(bool)
    local client = LocalPlayer()
    net.Start("TTT_SprintSpeedSet")
    net.WriteBool(bool)
    if bool then
        local mul = MathMin(MathMax(speedMultiplier, 0.1), 2)
        client.mult = 1 + mul

        local tmp = GetConVar("ttt_crosshair_size")
        crosshairSize = tmp and tmp:GetString() or 1
        RunConsoleCommand("ttt_crosshair_size", "2")
    else
        client.mult = nil

        RunConsoleCommand("ttt_crosshair_size", crosshairSize)
    end

    net.SendToServer()
end

-- Sprint activated (sprint if there is stamina)
local function SprintFunction()
    if not sprintEnabled then return end

    if stamina > 0 then
        if not sprinting then
            SpeedChange(true)
            sprinting = true
            sprintTimer = CurTime()
        end
        stamina = stamina - (CurTime() - sprintTimer) * (MathMin(MathMax(consumption, 0.1), 5) * 250)
        local result = CallHook("TTTSprintStaminaPost", nil, LocalPlayer(), stamina, sprintTimer, consumption)
        -- Use the overwritten stamina if one is provided
        if result then
            stamina = result
        end
        sprintTimer = CurTime()
    else
        if sprinting then
            SpeedChange(false)
            sprinting = false
        end
    end
end

AddHook("TTTPrepareRound", "TTTSprintPrepareRound", function()
    -- reset every round
    stamina = 100
    ConVars()

    -- listen for activation
    AddHook("Think", "TTTSprintThink", function()
        if not sprintEnabled then return end

        local client = LocalPlayer()
        local forward_key = CallHook("TTTSprintKey", nil, client) or IN_FORWARD
        if client:KeyDown(forward_key) and client:KeyDown(IN_SPEED) then
            -- forward + selected key
            SprintFunction()
            recoveryTimer = CurTime()
        else
            if sprinting then
                -- not sprinting
                SpeedChange(false)
                sprinting = false
                recoveryTimer = CurTime()
            end

            if GetRoundState() ~= ROUND_WAIT then
                local recovery = defaultRecovery
                if IsPlayer(client) and (client:IsTraitorTeam() or client:IsMonsterTeam() or client:IsIndependentTeam()) then
                    recovery = traitorRecovery
                end

                -- Allow things to change the recovery rate
                recovery = CallHook("TTTSprintStaminaRecovery", nil, client, recovery) or recovery

                stamina = stamina + (CurTime() - recoveryTimer) * recovery * 250
            end

            recoveryTimer = CurTime()
        end

        if stamina < 0 then
            -- prevent bugs
            stamina = 0
            SpeedChange(false)
            sprinting = false
            recoveryTimer = CurTime()
        elseif stamina > 100 then
            stamina = 100
        end
        if IsPlayer(client) then
            client:SetNWFloat("sprintMeter", stamina)
        end
    end)
end)

-- Set Sprint Speed
AddHook("TTTPlayerSpeedModifier", "TTTSprintPlayerSpeed", function(sply, _, _)
    if sply ~= LocalPlayer() then return end
    return GetSprintMultiplier(sply, sprintEnabled and sprinting)
end)