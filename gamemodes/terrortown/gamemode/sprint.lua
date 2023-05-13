local hook = hook

local AddHook = hook.Add

local sprintEnabled = CreateConVar("ttt_sprint_enabled", "1", FCVAR_SERVER_CAN_EXECUTE, "Whether sprint is enabled")
local speedMultiplier = CreateConVar("ttt_sprint_bonus_rel", "0.4", FCVAR_SERVER_CAN_EXECUTE, "The relative speed bonus given while sprinting. Def: 0.4")
local recovery = CreateConVar("ttt_sprint_regenerate_innocent", "0.08", FCVAR_SERVER_CAN_EXECUTE, "Sets stamina regeneration for innocents. Def: 0.08")
local traitorRecovery = CreateConVar("ttt_sprint_regenerate_traitor", "0.12", FCVAR_SERVER_CAN_EXECUTE, "Sets stamina regeneration speed for traitors. Def: 0.12")
local consumption = CreateConVar("ttt_sprint_consume", "0.2", FCVAR_SERVER_CAN_EXECUTE, "Sets stamina consumption speed. Def: 0.2")

AddHook("TTTSyncGlobals", "Sprinting_TTTSyncGlobals", function()
    SetGlobalBool("ttt_sprint_enabled", sprintEnabled:GetBool())
    SetGlobalFloat("ttt_sprint_bonus_rel", speedMultiplier:GetFloat())
    SetGlobalFloat("ttt_sprint_regenerate_innocent", recovery:GetFloat())
    SetGlobalFloat("ttt_sprint_regenerate_traitor", traitorRecovery:GetFloat())
    SetGlobalFloat("ttt_sprint_consume", consumption:GetFloat())
end)