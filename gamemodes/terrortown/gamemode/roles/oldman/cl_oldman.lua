local hook = hook
local net = net
local string = string
local table = table

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "OldMan_Translations_Initialize", function()
    -- Win conditions
    LANG.AddToLanguage("english", "ev_win_oldman", "The {role} has somehow survived and also won the round!")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_oldman", [[You are {role}! The slightest breeze could kill
you if you aren't careful. You don't care who wins as long
as you are alive at the end of the round.]])
end)

-------------
-- SCORING --
-------------

-- Track when the oldman wins
local oldman_wins = false
net.Receive("TTT_UpdateOldManWins", function()
    -- Log the win event with an offset to force it to the end
    if net.ReadBool() then
        oldman_wins = true
        CLSCORE:AddEvent({
            id = EVENT_FINISH,
            win = WIN_OLDMAN
        }, 1)
    end
end)

hook.Add("TTTPrepareRound", "OldMan_WinTracking_TTTPrepareRound", function()
    oldman_wins = false
end)

----------------
-- WIN CHECKS --
----------------

hook.Add("TTTScoringSecondaryWins", "OldMan_TTTScoringSecondaryWins", function(wintype, secondary_wins)
    if oldman_wins then
        table.insert(secondary_wins, ROLE_OLDMAN)
    end
end)

------------
-- EVENTS --
------------

hook.Add("TTTEventFinishText", "OldMan_TTTEventFinishText", function(e)
    if e.win == WIN_OLDMAN then
        return LANG.GetParamTranslation("ev_win_oldman", { role = string.lower(ROLE_STRINGS[ROLE_OLDMAN]) })
    end
end)

hook.Add("TTTEventFinishIconText", "OldMan_TTTEventFinishIconText", function(e, win_string, role_string)
    if e.win == WIN_OLDMAN then
        return "ev_win_icon_also", ROLE_STRINGS[ROLE_OLDMAN]
    end
end)

---------------
-- TARGET ID --
---------------

local function IsOldManVisible(ply)
    return IsPlayer(ply) and ply:IsOldMan() and ply:IsRoleActive() and not GetGlobalBool("ttt_oldman_hide_when_active", false)
end

-- Show the old man icon if the player is an activated old man
hook.Add("TTTTargetIDPlayerRoleIcon", "OldMan_TTTTargetIDPlayerRoleIcon", function(ply, cli, role, noz, color_role, hideBeggar, showJester, hideBodysnatcher)
    if IsOldManVisible(ply) then
        return ROLE_OLDMAN, false, ROLE_OLDMAN
    end
end)

-- Show the old man information and color when you look at the player
hook.Add("TTTTargetIDPlayerRing", "OldMan_TTTTargetIDPlayerRing", function(ent, client, ring_visible)
    if GetRoundState() < ROUND_ACTIVE then return end

    if IsOldManVisible(ent) then
        return true, ROLE_COLORS_RADAR[ROLE_OLDMAN]
    end
end)

hook.Add("TTTTargetIDPlayerText", "OldMan_TTTTargetIDPlayerText", function(ent, client, text, col, secondary_text)
    if GetRoundState() < ROUND_ACTIVE then return end

    if IsOldManVisible(ent) then
        return string.upper(ROLE_STRINGS[ROLE_OLDMAN]), ROLE_COLORS_RADAR[ROLE_OLDMAN]
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "OldMan_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_OLDMAN then
        local roleColor = GetRoleTeamColor(ROLE_TEAM_INDEPENDENT)
        local html = "The " .. ROLE_STRINGS[ROLE_OLDMAN] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independent</span> role whose goal is just to survive until the end of the round."

        -- Use this for highlighting things like "kill"
        local traitorColor = ROLE_COLORS[ROLE_TRAITOR]

        -- Adrenaline Rush
        local rushTime = GetGlobalInt("ttt_oldman_adrenaline_rush", 5)
        if rushTime > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>If the " .. ROLE_STRINGS[ROLE_OLDMAN] .. " is hit by enough damage that would kill them, they experience <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>an adrenaline rush</span> and fight off death for " .. rushTime .. " seconds. After their adrenaline runs out, <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>they die</span>. This gives them just long enough for the " .. ROLE_STRINGS[ROLE_OLDMAN] .. " to exact revenge against their killer.</span>"
            if GetGlobalBool("ttt_oldman_adrenaline_shotgun", true) then
                html = html .. "<span style='display: block; margin-top: 10px;'>During the adrenaline rush, the " .. ROLE_STRINGS[ROLE_OLDMAN] .. " is given a <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>double-barrel shotgun</span> with two shots so they cannot be caught unarmed.</span>"
            end
        end

        -- Health Drain
        local drainTo = GetGlobalInt("ttt_oldman_drain_health_to", 0)
        if drainTo > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>To give the " .. ROLE_STRINGS[ROLE_OLDMAN] .. " a sense of urgency, their <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>health will slowly drain down to " .. drainTo .. "</span>, over time.</span>"
        end

        return html
    end
end)