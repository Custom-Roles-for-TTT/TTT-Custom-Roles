local hook = hook
local net = net
local string = string

local AddHook = hook.Add

-------------
-- CONVARS --
-------------

local jester_win_by_traitors = GetConVar("ttt_jester_win_by_traitors")
local jester_healthstation_reduce_max = GetConVar("ttt_jester_healthstation_reduce_max")

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "Jester_Translations_Initialize", function()
    -- Win conditions
    LANG.AddToLanguage("english", "win_jester", "The {role} has fooled you all!")
    LANG.AddToLanguage("english", "ev_win_jester", "The tricky {role} won the round!")

    -- Scoring
    LANG.AddToLanguage("english", "score_jester_killedby", "Killed by")

    -- Radio
    LANG.AddToLanguage("english", "radio_jes_celebrate", "{jester} Celebrate")

    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_jester", "Wins the round if they can get another player to kill them.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_jester", [[You are {role}! You want to die but you
deal no damage so you must be killed by some one else.]])
end)

----------------
-- WIN CHECKS --
----------------

local function Jester_TTTScoringWinTitle(wintype, wintitles, title, secondary_win_role)
    if wintype == WIN_JESTER then
        return { txt = "hilite_win_role_singular", params = { role = string.upper(ROLE_STRINGS[ROLE_JESTER]) }, c = ROLE_COLORS[ROLE_JESTER] }
    end
end

-- Track when the jester gets a secondary win
local jester_secondary_wins = false
local function Jester_TTTScoringSecondaryWins(wintype, secondary_wins)
    if jester_secondary_wins then
        table.insert(secondary_wins, ROLE_JESTER)
    end
end

------------
-- EVENTS --
------------

local function Jester_TTTEventFinishText(e)
    if e.win == WIN_JESTER then
        return LANG.GetParamTranslation("ev_win_jester", { role = string.lower(ROLE_STRINGS[ROLE_JESTER]) })
    end
end

local function Jester_TTTEventFinishIconText(e, win_string, role_string)
    if e.win == WIN_JESTER then
        return win_string, ROLE_STRINGS[ROLE_JESTER]
    end
end

-------------
-- SCORING --
-------------

net.Receive("TTT_UpdateJesterSecondaryWins", function()
    jester_secondary_wins = true
end)

local function ResetJesterSecondaryWin()
    jester_secondary_wins = false
end
net.Receive("TTT_ResetJesterSecondaryWins", ResetJesterSecondaryWin)
AddHook("TTTPrepareRound", "Jester_WinTracking_TTTPrepareRound", ResetJesterSecondaryWin)
AddHook("TTTBeginRound", "Jester_WinTracking_TTTBeginRound", ResetJesterSecondaryWin)

-- Show who killed the jester (if anyone)
local function Jester_TTTScoringSummaryRender(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
    if not IsPlayer(ply) then return end

    if ply:IsJester() then
        local jesterKiller = ply:GetNWString("JesterKiller", "")
        if #jesterKiller > 0 then
            return roleFileName, groupingRole, roleColor, name, jesterKiller, LANG.GetTranslation("score_jester_killedby")
        end
    end
end

--------------
-- TUTORIAL --
--------------

AddHook("TTTTutorialRoleText", "Jester_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_JESTER then
        local roleColor = GetRoleTeamColor(ROLE_TEAM_JESTER)
        local html =  "The " .. ROLE_STRINGS[ROLE_JESTER] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>jester</span> role whose goal is to be killed by another player."

        if not jester_win_by_traitors:GetBool() then
            local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
            html = html .. "<span style='display: block; margin-top: 10px;'>Be careful! Jesters <span style='text-decoration: underline'>DO NOT</span> win if they are killed by a member of the <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>traitor team</span>!</span>"
        end

        if jester_healthstation_reduce_max:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>When the " .. ROLE_STRINGS[ROLE_JESTER] .. " uses a health station, their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>maximum health is reduced</span> toward their current health instead of them being healed.</span>"
        end

        return html
    end
end)

------------------
-- REGISTRATION --
------------------

ROLE_REGISTERED_HOOKS[ROLE_JESTER] = {
    ["TTTEventFinishIconText"] = Jester_TTTEventFinishIconText,
    ["TTTEventFinishText"] = Jester_TTTEventFinishText,
    ["TTTScoringSecondaryWins"] = Jester_TTTScoringSecondaryWins,
    ["TTTScoringSummaryRender"] = Jester_TTTScoringSummaryRender,
    ["TTTScoringWinTitle"] = Jester_TTTScoringWinTitle
}