------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Killer_Translations_Initialize", function()
    LANG.AddToLanguage("english", "win_killer", "The {role} has murdered you all!")
    LANG.AddToLanguage("english", "ev_win_killer", "The butchering {role} won the round!")
end)

---------------
-- TARGET ID --
---------------

-- Show "KILL" icon over all non-jester team heads
hook.Add("TTTTargetIDPlayerKillIcon", "Killer_TTTTargetIDPlayerKillIcon", function(ply, cli, showKillIcon, showJester)
    if cli:IsKiller() and GetGlobalBool("ttt_killer_show_target_icon", false) and not showJester then
        return true
    end
end)

-- Show the jester role icon for any jester team player
hook.Add("TTTTargetIDPlayerRoleIcon", "Killer_TTTTargetIDPlayerRoleIcon", function(ply, cli, role, noz, colorRole, hideBeggar, showJester, hideBodysnatcher)
    if cli:IsKiller() and showJester then
        return ROLE_JESTER
    end
end)

------------------
-- HIGHLIGHTING --
------------------

local killer_vision = false
local vision_enabled = false
local client = nil

local function EnableKillerHighlights()
    hook.Add("PreDrawHalos", "Killer_Highlight_PreDrawHalos", function()
        OnPlayerHighlightEnabled(client, {ROLE_KILLER}, true, false, false)
    end)
end

hook.Add("TTTUpdateRoleState", "Killer_Highlight_TTTUpdateRoleState", function()
    client = LocalPlayer()
    killer_vision = GetGlobalBool("ttt_killer_vision_enable", false)

    -- Disable highlights on role change
    if vision_enabled then
        hook.Remove("PreDrawHalos", "Killer_Highlight_PreDrawHalos")
        vision_enabled = false
    end
end)

-- Handle enabling and disabling of highlighting
hook.Add("Think", "Killer_Highlight_Think", function()
    if not IsPlayer(client) or not client:Alive() or client:IsSpec() then return end

    if killer_vision and client:IsKiller() then
        if not vision_enabled then
            EnableKillerHighlights()
            vision_enabled = true
        end
    else
        vision_enabled = false
    end

    if not vision_enabled then
        hook.Remove("PreDrawHalos", "Killer_Highlight_PreDrawHalos")
    end
end)

----------------
-- WIN CHECKS --
----------------

hook.Add("TTTScoringWinTitle", "Killer_TTTScoringWinTitle", function(wintype, wintitles, title, secondary_win_role)
    if wintype == WIN_KILLER then
        return { txt = "hilite_win_role_singular", params = { role = ROLE_STRINGS[ROLE_KILLER]:upper() }, c = ROLE_COLORS[ROLE_KILLER] }
    end
end)

------------
-- EVENTS --
------------

hook.Add("TTTEventFinishText", "Killer_TTTEventFinishText", function(e)
    if e.win == WIN_KILLER then
        return LANG.GetParamTranslation("ev_win_killer", { role = ROLE_STRINGS[ROLE_KILLER]:lower() })
    end
end)

hook.Add("TTTEventFinishIconText", "Killer_TTTEventFinishIconText", function(e, win_string, role_string)
    if e.win == WIN_KILLER then
        return win_string, ROLE_STRINGS[ROLE_KILLER]
    end
end)

-----------
-- SMOKE --
-----------

hook.Add("TTTShouldPlayerSmoke", "Killer_TTTShouldPlayerSmoke", function(ply, cli, shouldSmoke, smokeColor, smokeParticle, smokeOffset)
    if ply:IsKiller() and ply:GetNWBool("KillerSmoke", false) then
        return true
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Killer_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_KILLER then
        local roleColor = GetRoleTeamColor(ROLE_TEAM_INDEPENDENT)
        local html = "The " .. ROLE_STRINGS[ROLE_KILLER] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independent</span> role whose goal is to be the last player standing."

        roleColor = ROLE_COLORS[ROLE_TRAITOR]
        if GetGlobalBool("ttt_killer_knife_enabled", false) then
            html = html .. "<span style='display: block; margin-top: 10px;'>They are given a knife that does high damage to aid in their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>slaughter.</span></span>"
        end

        if GetGlobalBool("ttt_killer_smoke_enabled", false) then
            html = html .. "<span style='display: block; margin-top: 10px;'>If they don't <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>kill</span> often enough they will begin to smoke, alerting the other players.</span>"
        end

        local hasVision = GetGlobalBool("ttt_killer_vision_enable", false)
        if hasVision then
            html = html .. "<span style='display: block; margin-top: 10px;'>Their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>blood lust</span> helps them see their targets through walls by highlighting their enemies.</span>"
        end

        if GetGlobalBool("ttt_killer_show_target_icon", false) then
            html = html .. "<span style='display: block; margin-top: 10px;'>Their targets can"
            if hasVision then
                html = html .. " also"
            end
            html = html .. " be identified by the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>KILL</span> icon floating over their heads.</span>"
        end

        return html
    end
end)