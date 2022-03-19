AddCSLuaFile()

local hook = hook
local pairs = pairs
local timer = timer

local GetAllPlayers = player.GetAll

-------------
-- CONVARS --
-------------

CreateConVar("ttt_jester_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that the jester is killed", 0, 4)
CreateConVar("ttt_jester_notify_sound", "0")
CreateConVar("ttt_jester_notify_confetti", "0")
local jester_healthstation_reduce_max = CreateConVar("ttt_jester_healthstation_reduce_max", "1")
local jester_win_by_traitors = CreateConVar("ttt_jester_win_by_traitors", "1")

hook.Add("TTTSyncGlobals", "Jester_TTTSyncGlobals", function()
    SetGlobalBool("ttt_jester_win_by_traitors", jester_win_by_traitors:GetBool())
    SetGlobalBool("ttt_jester_healthstation_reduce_max", jester_healthstation_reduce_max:GetBool())
end)

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

hook.Add("PlayerDeath", "Jester_WinCheck_PlayerDeath", function(victim, infl, attacker)
    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    if not valid_kill then return end

    if victim:IsJester() then
        JesterKilledNotification(attacker, victim)
        victim:SetNWString("JesterKiller", attacker:Nick())

        -- Don't end the round if the jester was killed by a traitor
        -- and the functionality that blocks Jester wins from traitor deaths is enabled
        if jester_win_by_traitors:GetBool() or not attacker:IsTraitorTeam() then
            -- Stop the win checks so someone else doesn't steal the jester's win
            StopWinChecks()
            -- Delay the actual end for a second so the message and sound have a chance to generate a reaction
            timer.Simple(1, function() EndRound(WIN_JESTER) end)
        end
    end
end)

hook.Add("TTTPrintResultMessage", "Killer_TTTPrintResultMessage", function(type)
    if type == WIN_JESTER then
        LANG.Msg("win_jester", { role = ROLE_STRINGS_PLURAL[ROLE_JESTER] })
        ServerLog("Result: " .. ROLE_STRINGS[ROLE_JESTER] .. " wins.\n")
    end
end)

hook.Add("TTTPrepareRound", "Jester_PrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        v:SetNWString("JesterKiller", "")
    end
end)