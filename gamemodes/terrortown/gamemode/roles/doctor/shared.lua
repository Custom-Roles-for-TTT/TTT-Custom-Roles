AddCSLuaFile()

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_DOCTOR] = {
            "weapon_ttt_health_station",
            "weapon_par_cure"
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Doctor_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Doctor_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)