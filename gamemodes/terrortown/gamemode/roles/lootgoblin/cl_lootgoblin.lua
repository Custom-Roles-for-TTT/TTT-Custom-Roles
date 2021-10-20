------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "LootGoblin_Translations_Initialize", function()
    -- Win conditions
    LANG.AddToLanguage("english", "ev_win_lootgoblin", "The {role} has escaped and also won the round!")

    -- HUD
    LANG.AddToLanguage("english", "lootgoblin_hud", "You will transform in: {time}")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_lootgoblin", [[You are {role}! All you want to do is hoard your
loot! But be careful... Everyone is out to kill
you and steal it for themselves!]])
end)

---------------
-- TARGET ID --
---------------

-- Reveal the loot goblin to all players once activated
hook.Add("TTTTargetIDPlayerRoleIcon", "LootGoblin_TTTTargetIDPlayerRoleIcon", function(ply, client, role, noz, colorRole, hideBeggar, showJester, hideBodysnatcher)
    if ply:IsActiveLootGoblin() and ply:IsRoleActive() then
        return ROLE_LOOTGOBLIN, false
    end
end)

hook.Add("TTTTargetIDPlayerRing", "LootGoblin_TTTTargetIDPlayerRing", function(ent, client, ringVisible)
    if IsPlayer(ent) and ent:IsActiveLootGoblin() and ent:IsRoleActive() then
        return true, ROLE_COLORS_RADAR[ROLE_LOOTGOBLIN]
    end
end)

hook.Add("TTTTargetIDPlayerText", "LootGoblin_TTTTargetIDPlayerText", function(ent, client, text, clr, secondaryText)
    if IsPlayer(ent) and ent:IsActiveLootGoblin() and ent:IsRoleActive() then
        return string.upper(ROLE_STRINGS[ROLE_LOOTGOBLIN]), ROLE_COLORS_RADAR[ROLE_LOOTGOBLIN]
    end
end)

----------------
-- SCOREBOARD --
----------------

hook.Add("TTTScoreboardPlayerRole", "LootGoblin_TTTScoreboardPlayerRole", function(ply, client, color, roleFileName)
    if ply:IsActiveLootGoblin() and ply:IsRoleActive() then
        return ROLE_COLORS_SCOREBOARD[ROLE_LOOTGOBLIN], ROLE_STRINGS_SHORT[ROLE_LOOTGOBLIN]
    end
end)

-------------
-- SCORING --
-------------

-- Track when the loot goblin wins
local lootgoblin_wins = false
net.Receive("TTT_UpdateLootGoblinWins", function()
    -- Log the win event with an offset to force it to the end
    if net.ReadBool() then
        lootgoblin_wins = true
        CLSCORE:AddEvent({
            id = EVENT_FINISH,
            win = WIN_LOOTGOBLIN
        }, 1)
    end
end)

hook.Add("TTTPrepareRound", "LootGoblin_WinTracking_TTTPrepareRound", function()
    lootgoblin_wins = false
end)

----------------
-- WIN CHECKS --
----------------

hook.Add("TTTScoringWinTitle", "LootGoblin_TTTScoringWinTitle", function(wintype, wintitles, title, secondary_win_role)
    if lootgoblin_wins then
        return title, ROLE_LOOTGOBLIN
    end
end)

------------
-- EVENTS --
------------

hook.Add("TTTEventFinishText", "LootGoblin_TTTEventFinishText", function(e)
    if e.win == WIN_LOOTGOBLIN then
        return LANG.GetParamTranslation("ev_win_lootgoblin", { role = ROLE_STRINGS[ROLE_LOOTGOBLIN]:lower() })
    end
end)

hook.Add("TTTEventFinishIconText", "LootGoblin_TTTEventFinishIconText", function(e, win_string, role_string)
    if e.win == WIN_LOOTGOBLIN then
        return "ev_win_icon_also", ROLE_STRINGS[ROLE_LOOTGOBLIN]
    end
end)

---------
-- HUD --
---------

hook.Add("TTTHUDInfoPaint", "LootGoblin_TTTHUDInfoPaint", function(client, label_left, label_top)
    if client:IsActiveLootGoblin() and not client:IsRoleActive() then
        surface.SetFont("TabLarge")
        surface.SetTextColor(255, 255, 255, 230)

        local remaining = math.max(0, GetGlobalFloat("ttt_lootgoblin_activate", 0) - CurTime())

        text = LANG.GetParamTranslation("lootgoblin_hud", { time = util.SimpleTime(remaining, "%02i:%02i") })
        local _, h = surface.GetTextSize(text)

        surface.SetTextPos(label_left, ScrH() - label_top - h)
        surface.DrawText(text)
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "LootGoblin_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_LOOTGOBLIN then
        local roleColor = GetRoleTeamColor(ROLE_TEAM_JESTER)
        local html = "The " .. ROLE_STRINGS[ROLE_LOOTGOBLIN] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>jester</span> role who likes to hoard loot."

        -- Activation Timer
        html = html .. "<span style='display: block; margin-top: 10px;'>After some time has passed, <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>the " .. ROLE_STRINGS[ROLE_LOOTGOBLIN] .. "</span> will transform and be revealed to players.</span>"

        -- Drop loot on death
        html = html .. "<span style='display: block; margin-top: 10px;'>Once they have activated, <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>the " .. ROLE_STRINGS[ROLE_LOOTGOBLIN] .. "</span> will drop a large number of items and credits when killed.</span>"

        -- Win condition
        html = html .. "<span style='display: block; margin-top: 10px;'>If <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>the " .. ROLE_STRINGS[ROLE_LOOTGOBLIN] .. "</span> survives until another team wins the round, they will share the win with winning team.</span>"

        return html
    end
end)