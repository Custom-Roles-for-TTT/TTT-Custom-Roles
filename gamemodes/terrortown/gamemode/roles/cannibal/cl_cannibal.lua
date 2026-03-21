local hook = hook

local AddHook = hook.Add

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "Cannibal_Translations_Initialize", function()
    -- Scoreboard
    LANG.AddToLanguage("english", "cannibal_eaten", "EATEN")

    -- Scoreboard
    LANG.AddToLanguage("english", "cannibal_swallowed", "SWALLOWED")

    -- Weapons
    LANG.AddToLanguage("english", "can_eater_help_pri", "{primaryfire} to eat a player.")

    -- Events
    LANG.AddToLanguage("english", "ev_cannibaleat", "{victim} was eaten by {source}")

    -- Win conditions
    LANG.AddToLanguage("english", "win_cannibal", "The {role} is finally satiated!")
    LANG.AddToLanguage("english", "ev_win_cannibal", "The gluttonous {role} has won the round!")

    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_cannibal", "Wins by eating all other living players. If they die everyone they ate is revived.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_cannibal", [[You are {role}! Eat all living players to win.

Everyone you ate will be respawned if you die.]])
end)

----------------
-- WIN CHECKS --
----------------

AddHook("TTTScoringWinTitle", "Cannibal_TTTScoringWinTitle", function(wintype, wintitles, title, secondary_win_role)
    if wintype == WIN_CANNIBAL then
        return { txt = "hilite_win_role_singular", params = { role = string.upper(ROLE_STRINGS[ROLE_CANNIBAL]) }, c = ROLE_COLORS[ROLE_CANNIBAL] }
    end
end)

------------
-- EVENTS --
------------

AddHook("TTTEventFinishText", "Cannibal_TTTEventFinishText", function(e)
    if e.win == WIN_CANNIBAL then
        return LANG.GetParamTranslation("ev_win_cannibal", { role = string.lower(ROLE_STRINGS[ROLE_CANNIBAL]) })
    end
end)

AddHook("TTTEventFinishIconText", "Cannibal_TTTEventFinishIconText", function(e, win_string, role_string)
    if e.win == WIN_CANNIBAL then
        return win_string, ROLE_STRINGS[ROLE_CANNIBAL]
    end
end)

AddHook("Initialize", "Cannibal_Events_Initialize", function()
    local eat_icon = Material("icon16/emoticon_tongue.png")
    local Event = CLSCORE.DeclareEventDisplay
    local PT = LANG.GetParamTranslation

    Event(EVENT_CANNIBALEAT, {
        text = function(e)
            return PT("ev_cannibaleat", {victim = e.vic, source = e.src})
        end,
        icon = function(e)
            return eat_icon, "Eaten"
        end})
end)

net.Receive("TTT_CannibalEaten", function(len)
    local victim = net.ReadString()
    local source = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_CANNIBALEAT,
        vic = victim,
        src = source
    })
end)

------------------
-- HIGHLIGHTING --
------------------

AddHook("TTTShouldHideFromHighlight", "Cannibal_TTTShouldHideFromHighlight", function(ply, cli)
    if ply:IsCannibal() then
        return true
    end
end)

---------------
-- TARGET ID --
---------------

AddHook("TTTTargetIDPlayerBlockIcon", "Cannibal_TTTTargetIDPlayerBlockIcon", function(ply, cli)
    if ply:IsCannibal() then
        return true
    end
end)

AddHook("TTTTargetIDPlayerText", "Cannibal_TTTTargetIDPlayerText", function(ent, cli, text, col)
    if IsPlayer(ent) and ent:IsCannibal() then
        return false
    end
end)

AddHook("TTTTargetIDPlayerRing", "Cannibal_TTTTargetIDPlayerRing", function(ent, cli, ring_visible)
    if IsPlayer(ent) and ent:IsCannibal() then
        return false
    end
end)

----------------
-- SCOREBOARD --
----------------

AddHook("TTTScoreboardPlayerRole", "Cannibal_TTTScoreboardPlayerRole", function(ply, cli, c, roleStr)
    if ply:IsCannibal() then
        return false, false
    end
end)

AddHook("TTTScoreboardPlayerName", "Cannibal_TTTScoreboardPlayerName", function(ply, cli, text)
    if not IsPlayer(ply) then return end
    if not ply.TTTCannibalEaten then return end
    if not cli:IsCannibal() then return end
    if ply.TTTCannibalEaten ~= cli:SteamID64() then return end

    return ply:Nick() .. " (" .. LANG.GetTranslation("cannibal_eaten") .. ")"
end)

ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_CANNIBAL] = function(ply, target)
    if not IsPlayer(target) then return end
    if not target.TTTCannibalEaten then return end
    if not ply:IsCannibal() then return end

    ------ name, role
    return true, false
end

local client

AddHook("TTTScoreGroup", "Cannibal_TTTScoreGroup", function(ply)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not IsPlayer(ply) then return end
    if not ply.TTTCannibalEaten then return end

    if not IsPlayer(client) then
        client = LocalPlayer()
    end

    if client:IsSpec() or client:IsTraitorTeam() or client:IsMonsterTeam() or (client:IsIndependentTeam() and cvars.Bool("ttt_" .. ROLE_STRINGS_RAW[client:GetRole()] .. "_update_scoreboard", false)) then
        return GROUP_NOTFOUND
    end
end)

---------
-- HUD --
---------

AddHook("HUDDrawScoreBoard", "Cannibal_HUDDrawScoreBoard", function()
    if not IsPlayer(client) then
        client = LocalPlayer()
    end

    if not client.TTTCannibalEaten then return end

    local bar_colors = {
        border = COLOR_WHITE,
        background = ROLE_COLORS_DARK[ROLE_CANNIBAL],
        fill = ROLE_COLORS[ROLE_CANNIBAL]
    }

    CRHUD:PaintBar(8, 20, ScrH() - 59, 230, 25, bar_colors, 1)
    draw.SimpleText(LANG.GetTranslation("cannibal_swallowed"), "HealthAmmo", 135, ScrH() - 59, Color(255, 255, 255, 200), TEXT_ALIGN_CENTER)
end)

--------------
-- TUTORIAL --
--------------

AddHook("TTTTutorialRoleText", "Cannibal_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_CANNIBAL then
        local roleTeam = player.GetRoleTeam(ROLE_CANNIBAL, true)
        local roleTeamName, roleColor = GetRoleTeamInfo(roleTeam)
        local html = "The " .. ROLE_STRINGS[ROLE_CANNIBAL] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. roleTeamName .. "</span> role whose goal is to eat all other players."

        if GetConVar("ttt_cannibal_gains_health"):GetBool() then
            local gained_health_percentage = GetConVar("ttt_cannibal_gained_health_percentage"):GetInt()
            local gained
            if gained_health_percentage > 0 then
                gained = gained_health_percentage .. "% of the victim's health"
            else
                gained = "100HP"
            end

            html = html .. "<span style='display: block; margin-top: 10px;'>When the " .. ROLE_STRINGS[ROLE_CANNIBAL] .. " eats a player, they <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>gain " .. gained .. "</span> immediately.</span>"
        end

        local eatenDetail = ""
        local deathDetail = ""

        if GetConVar("ttt_cannibal_digestion"):GetBool() then
            eatenDetail = " immediately"
            deathDetail = " undigested"
        end

        html = html .. "<span style='display: block; margin-top: 10px;'>Eaten players are not" .. eatenDetail .. " dead, but they are <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>unable to do anything</span> except talk with other eaten players and spectate the " .. ROLE_STRINGS[ROLE_CANNIBAL] .. ".</span>"

        if GetConVar("ttt_cannibal_digestion"):GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>Eaten players are <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>digested and killed </span> " .. GetConVar("ttt_cannibal_digestion_time"):GetInt() .. " seconds after being eaten.</span>"
        end

        html = html .. "<span style='display: block; margin-top: 10px;'>If the " .. ROLE_STRINGS[ROLE_CANNIBAL] .. " dies, all" .. deathDetail .. " eaten players are <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>freed</span> at the position where the " .. ROLE_STRINGS[ROLE_CANNIBAL] .. " died.</span>"

        return html
    end
end)