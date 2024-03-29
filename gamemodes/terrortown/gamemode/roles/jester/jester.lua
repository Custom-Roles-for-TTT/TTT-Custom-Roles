AddCSLuaFile()

local hook = hook
local pairs = pairs

local GetAllPlayers = player.GetAll

-------------
-- CONVARS --
-------------

CreateConVar("ttt_jester_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that the jester is killed", 0, 4)
CreateConVar("ttt_jester_notify_sound", "0", FCVAR_NONE, "Whether to play a cheering sound when a jester is killed", 0, 1)
CreateConVar("ttt_jester_notify_confetti", "0", FCVAR_NONE, "Whether to throw confetti when a jester is a killed", 0, 1)

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

local jesterWinTime = nil
hook.Add("PlayerDeath", "Jester_WinCheck_PlayerDeath", function(victim, infl, attacker)
    if jesterWinTime then return end

    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    if not valid_kill then return end

    if victim:IsJester() then
        JesterKilledNotification(attacker, victim)
        victim:SetNWString("JesterKiller", attacker:Nick())

        -- If we're debugging, don't end the round
        if GetConVar("ttt_debug_preventwin"):GetBool() then
            return
        end

        -- Don't end the round if the jester was killed by a traitor
        -- and the functionality that blocks Jester wins from traitor deaths is enabled
        if jester_win_by_traitors:GetBool() or not attacker:IsTraitorTeam() then
            -- Delay the actual end for a second so the message and sound have a chance to generate a reaction
            jesterWinTime = CurTime() + 1
        end
    end
end)

hook.Add("TTTCheckForWin", "Jester_TTTCheckForWin", function()
    if jesterWinTime then
        if CurTime() > jesterWinTime then
            jesterWinTime = nil
            return WIN_JESTER
        end

        return WIN_NONE
    end
end)

hook.Add("TTTPrintResultMessage", "Jester_TTTPrintResultMessage", function(type)
    if type == WIN_JESTER then
        LANG.Msg("win_jester", { role = ROLE_STRINGS[ROLE_JESTER] })
        ServerLog("Result: " .. ROLE_STRINGS[ROLE_JESTER] .. " wins.\n")
        return true
    end
end)

hook.Add("TTTPrepareRound", "Jester_PrepareRound", function()
    jesterWinTime = nil

    for _, v in pairs(GetAllPlayers()) do
        v:SetNWString("JesterKiller", "")
    end
end)