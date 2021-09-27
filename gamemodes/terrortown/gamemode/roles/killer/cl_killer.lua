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
hook.Add("TTTTargetIDPlayerKillIcon", "Killer_TTTTargetIDPlayerKillIcon", function(ply, client, showKillIcon, showJester)
    if client:IsKiller() and GetGlobalBool("ttt_killer_show_target_icon", false) and not showJester then
        return true
    end
end)

-- Show the jester role icon for any jester team player
hook.Add("TTTTargetIDPlayerRoleIcon", "Killer_TTTTargetIDPlayerRoleIcon", function(ply, client, role, noz, colorRole, hideBeggar, showJester, hideBodysnatcher)
    if client:IsKiller() and showJester then
        return ROLE_JESTER
    end
end)

------------------
-- HIGHLIGHTING --
------------------

local function EnableKillerHighlights(client)
    hook.Add("PreDrawHalos", "Killer_Highlight_PreDrawHalos", function()
        OnPlayerHighlightEnabled(client, {ROLE_KILLER}, true, false, false)
    end)
end

local killer_vision = false
local vision_enabled = false
local client = nil
hook.Add("TTTUpdateRoleState", "Killer_Highlight_TTTUpdateRoleState", function()
    client = LocalPlayer()
    killer_vision = GetGlobalBool("ttt_killer_vision_enable", false)
    print("Killer_Highlight_TTTUpdateRoleState - " .. tostring(killer_vision))

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
            EnableKillerHighlights(client)
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