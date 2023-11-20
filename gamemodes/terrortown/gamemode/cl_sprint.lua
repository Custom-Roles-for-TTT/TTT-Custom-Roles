local hook = hook

local AddHook = hook.Add

local crosshairSize = nil
local sizeConvar = nil

AddHook("TTTSprintStateChange", "Sprinting_Crosshair_TTTSprintStateChange", function(ply, sprinting, _)
    if ply ~= LocalPlayer() then return end
    if sprinting and crosshairSize ~= nil then return end

    if not sizeConvar then
        sizeConvar = GetConVar("ttt_crosshair_size")
    end

    -- Sanity check
    if not sizeConvar then return end

    if sprinting then
        crosshairSize = sizeConvar:GetFloat()
        sizeConvar:SetFloat(crosshairSize + 1)
    elseif crosshairSize then
        sizeConvar:SetFloat(crosshairSize)
        crosshairSize = nil
    end
end)