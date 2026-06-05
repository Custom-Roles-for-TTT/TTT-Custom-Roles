AddCSLuaFile()

local hook = hook
local player = player
local timer = timer

local AddHook = hook.Add
local RemoveHook = hook.Remove
local PlayerIterator = player.Iterator

util.AddNetworkString("TTT_UpdateJesterSecondaryWins")
util.AddNetworkString("TTT_ResetJesterSecondaryWins")

-------------
-- CONVARS --
-------------

CreateConVar("ttt_jester_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that a jester was killed. Killer is notified unless \"ttt_jester_notify_killer\" is disabled", 0, 4)
CreateConVar("ttt_jester_notify_killer", "1", FCVAR_NONE, "Whether to notify a jester's killer", 0, 1)
CreateConVar("ttt_jester_notify_sound", "0", FCVAR_NONE, "Whether to play a cheering sound when a jester is killed", 0, 1)
CreateConVar("ttt_jester_notify_confetti", "0", FCVAR_NONE, "Whether to throw confetti when a jester is a killed", 0, 1)
local jester_win_ends_round = CreateConVar("ttt_jester_win_ends_round", "1", FCVAR_NONE, "Whether the jester winning causes the round to end", 0, 1)

local jester_win_by_traitors = GetConVar("ttt_jester_win_by_traitors")

----------------
-- WIN CHECKS --
----------------

local function JesterKilledNotification(attacker, victim)
    JesterTeamKilledNotification(attacker, victim,
        -- getkillstring
        function()
            return attacker:Nick() .. " was dumb enough to kill the " .. ROLE_STRINGS[ROLE_JESTER] .. "!"
        end,
        -- shouldshow
        function()
            -- Don't announce anything if the game doesn't end here and the Jester was killed by a traitor
            return not (not jester_win_by_traitors:GetBool() and attacker:IsTraitorTeam())
        end)
end

local function HandleJesterWin()
    -- If we're not ending the round, just reuse the existing variable and
    -- set it to something valid so the win check logic sees it's been updated
    if not jester_win_ends_round:GetBool() then
        net.Start("TTT_UpdateJesterSecondaryWins")
        net.Broadcast()
        return
    end

    -- If we're debugging, don't end the round
    if GetConVar("ttt_debug_preventwin"):GetBool() then
        return
    end

    -- Stop the win checks so someone else doesn't steal the jester's win
    StopWinChecks()
    -- Delay the actual end for a second so the message and sound have a chance to generate a reaction
    timer.Simple(1, function() EndRound(WIN_JESTER) end)
end

local function Jester_WinCheck_PlayerDeath(victim, infl, attacker)
    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    if not valid_kill then return end

    if victim:IsJester() then
        JesterKilledNotification(attacker, victim)
        victim:SetNWString("JesterKiller", attacker:Nick())

        -- If the attacker was a traitor and the jester doesn't win when killed by a traitor, then don't continue
        if attacker:IsTraitorTeam() and not jester_win_by_traitors:GetBool() then return end
        -- If their ability was disabled then they don't win the round either
        if victim:IsRoleAbilityDisabled() then
            victim.JesterShouldWin = true
            return
        end

        HandleJesterWin()
    end
end

local function Jester_TTTOnRoleAbilityEnabled(ply)
    if not IsPlayer(ply) or not ply:IsJester() then return end
    if ply:Alive() or not ply:IsSpec() then return end
    if not ply.JesterShouldWin then return end
    ply.JesterShouldWin = false
    HandleJesterWin()
end

local function Jester_TTTPrintResultMessage(type)
    if type == WIN_JESTER then
        LANG.Msg("win_jester", { role = ROLE_STRINGS[ROLE_JESTER] })
        ServerLog("Result: " .. ROLE_STRINGS[ROLE_JESTER] .. " wins.\n")
        return true
    end
end

AddHook("TTTPrepareRound", "Jester_TTTPrepareRound", function()
    for _, v in PlayerIterator() do
        v.JesterShouldWin = false
        v:SetNWString("JesterKiller", "")
    end

    net.Start("TTT_ResetJesterSecondaryWins")
    net.Broadcast()
end)

local function Jester_TTTBeginRound()
    net.Start("TTT_ResetJesterSecondaryWins")
    net.Broadcast()
end

------------------
-- REGISTRATION --
------------------

ROLE_REGISTER_HOOKS[ROLE_JESTER] = function()
    AddHook("PlayerDeath", "Jester_WinCheck_PlayerDeath", Jester_WinCheck_PlayerDeath)
    AddHook("TTTBeginRound", "Jester_TTTBeginRound", Jester_TTTBeginRound)
    AddHook("TTTOnRoleAbilityEnabled", "Jester_TTTOnRoleAbilityEnabled", Jester_TTTOnRoleAbilityEnabled)
    AddHook("TTTPrintResultMessage", "Jester_TTTPrintResultMessage", Jester_TTTPrintResultMessage)
end

ROLE_UNREGISTER_HOOKS[ROLE_JESTER] = function()
    RemoveHook("PlayerDeath", "Jester_WinCheck_PlayerDeath")
    RemoveHook("TTTBeginRound", "Jester_TTTBeginRound")
    RemoveHook("TTTOnRoleAbilityEnabled", "Jester_TTTOnRoleAbilityEnabled")
    RemoveHook("TTTPrintResultMessage", "Jester_TTTPrintResultMessage")
end