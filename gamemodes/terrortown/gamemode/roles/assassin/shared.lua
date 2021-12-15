AddCSLuaFile()

local hook = hook

-- Initialize role features
ROLE_SHOULD_DELAY_ANNOUNCEMENTS[ROLE_ASSASSIN] = true

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_ASSASSIN] = {
            EQUIP_ARMOR,
            EQUIP_RADAR,
            EQUIP_DISGUISE
        }
    end
end
InitializeEquipment()

hook.Add("Initialize", "Assassin_Shared_Initialize", function()
    InitializeEquipment()
end)
hook.Add("TTTPrepareRound", "Assassin_Shared_TTTPrepareRound", function()
    InitializeEquipment()
end)