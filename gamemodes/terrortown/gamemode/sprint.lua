local hook = hook
local net = net
local util = util

local AddHook = hook.Add

util.AddNetworkString("TTT_SprintSpeedSet")
util.AddNetworkString("TTT_SprintGetConVars")

-- sprint convars
local sprintEnabled = CreateConVar("ttt_sprint_enabled", "1", FCVAR_SERVER_CAN_EXECUTE, "Whether sprint is enabled")
local speedMultiplier = CreateConVar("ttt_sprint_bonus_rel", "0.4", FCVAR_SERVER_CAN_EXECUTE, "The relative speed bonus given while sprinting. Def: 0.4")
local recovery = CreateConVar("ttt_sprint_regenerate_innocent", "0.08", FCVAR_SERVER_CAN_EXECUTE, "Sets stamina regeneration for innocents. Def: 0.08")
local traitorRecovery = CreateConVar("ttt_sprint_regenerate_traitor", "0.12", FCVAR_SERVER_CAN_EXECUTE, "Sets stamina regeneration speed for traitors. Def: 0.12")
local consumption = CreateConVar("ttt_sprint_consume", "0.2", FCVAR_SERVER_CAN_EXECUTE, "Sets stamina consumption speed. Def: 0.2")

AddHook("TTTSyncGlobals", "Sprint_TTTSyncGlobals", function()
    SetGlobalBool("ttt_sprint_enabled", GetConVar("ttt_sprint_enabled"):GetBool())
end)

-- Sprint
net.Receive("TTT_SprintSpeedSet", function(len, ply)
    if not sprintEnabled:GetBool() then
        ply.mult = nil
        return
    end

    if net.ReadBool() then
        ply.mult = 1 + speedMultiplier:GetFloat()
    else
        ply.mult = nil
    end
end)

-- Send ConVars if requested
net.Receive("TTT_SprintGetConVars", function(len, ply)
    local convars = {
        [1] = sprintEnabled:GetBool(),
        [2] = speedMultiplier:GetFloat(),
        [3] = recovery:GetFloat(),
        [4] = traitorRecovery:GetFloat(),
        [5] = consumption:GetFloat()
    }
    net.Start("TTT_SprintGetConVars")
    net.WriteTable(convars)
    net.Send(ply)
end)

-- return Speed
hook.Add("TTTPlayerSpeedModifier", "TTTSprintPlayerSpeed", function(ply, _, _)
    return GetSprintMultiplier(ply, sprintEnabled:GetBool() and ply.mult ~= nil)
end)