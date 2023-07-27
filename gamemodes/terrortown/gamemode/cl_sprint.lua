local hook = hook

local AddHook = hook.Add

local crosshairSize = nil

AddHook("TTTSprintStateChange", "Sprinting_Crosshair_TTTSprintStateChange", function(ply, sprinting, _)
    if ply ~= LocalPlayer() then return end
    if sprinting and crosshairSize ~= nil then return end

    if sprinting then
        crosshairSize = GetConVar("ttt_crosshair_size"):GetFloat()
        RunConsoleCommand("ttt_crosshair_size", crosshairSize + 1)
    elseif crosshairSize then
        RunConsoleCommand("ttt_crosshair_size", crosshairSize)
        crosshairSize = nil
    end
end)