local hook = hook

local AddHook = hook.Add

local crosshairSize = nil

AddHook("TTTSprintStateChange", "Sprinting_Crosshair_TTTSprintStateChange", function(ply, sprinting, _)
    if ply ~= LocalPlayer() then return end

    if sprinting then
        if not crosshairSize then
            crosshairSize = GetConVar("ttt_crosshair_size"):GetInt()
        end
        RunConsoleCommand("ttt_crosshair_size", 2)
    elseif crosshairSize then
        RunConsoleCommand("ttt_crosshair_size", crosshairSize)
    end
end)