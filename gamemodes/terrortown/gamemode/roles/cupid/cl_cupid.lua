local hook = hook

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Cupid_Translations_Initialize", function()
    -- Win conditions
    LANG.AddToLanguage("english", "win_lovers_primary", "The lovers have outlasted everyone!")
    LANG.AddToLanguage("english", "hilite_lovers_primary", "THE LOVERS WIN")
    LANG.AddToLanguage("english", "ev_win_lovers_primary", "The lovers won the round!")

    LANG.AddToLanguage("english", "win_lovers_secondary", "The lovers has survived!")
    LANG.AddToLanguage("english", "hilite_lovers_secondary", "AND THE LOVERS WIN")
    LANG.AddToLanguage("english", "ev_win_lovers_secondary", "The lovers also won the round!")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_cupid_jester", [[You are {role}! {traitors} think you are {ajester} and you
deal no damage. However, you can use your bow to make two
players fall in love so that they win/die together.]])
    LANG.AddToLanguage("english", "info_popup_cupid_indep", [[You are {role}! You can use your bow to make two
players fall in love so that they win/die together.]])
end)

----------------
-- WIN CHECKS --
----------------

hook.Add("TTTScoringWinTitle", "Cupid_TTTScoringWinTitle", function(wintype, wintitles, title, secondary_win_role)
    if wintype == WIN_CUPID then
        return { txt = "hilite_lovers_primary" }
    end
end)

hook.Add("TTTScoringSecondaryWins", "Cupid_TTTScoringSecondaryWins", function(wintype, secondary_wins)
    if wintype == WIN_CUPID then return end

    for _, p in ipairs(player.GetAll()) do
        local lover = p:GetNWString("TTTCupidLover", "")
        if p:IsActive() and lover ~= "" then
            if player.GetBySteamID64(lover):IsActive() then -- This shouldn't be necessary because if one lover dies the other should too but we check just in case
                table.insert(secondary_wins, {
                    rol = ROLE_CUPID,
                    txt = LANG.GetTranslation("hilite_lovers_secondary"),
                    col = ROLE_COLORS[ROLE_CUPID]
                })
            end
            return
        end
    end
end)

------------
-- EVENTS --
------------

hook.Add("TTTEventFinishText", "Cupid_TTTEventFinishText", function(e)
    if e.win == WIN_CUPID then
        return LANG.GetTranslation("ev_win_lovers_primary")
    end
end)

hook.Add("TTTEventFinishIconText", "Cupid_TTTEventFinishIconText", function(e, win_string, role_string)
    if e.win == WIN_CUPID then
        return win_string, ROLE_STRINGS[ROLE_CUPID]
    end
end)

-- TODO: Secondary win event

------------
-- HEARTS --
------------

hook.Add("TTTShouldPlayerSmoke", "Cupid_TTTShouldPlayerSmoke", function(ply, cli, shouldSmoke, smokeColor, smokeParticle, smokeOffset)
    local target = ply:SteamID64()
    if (cli:IsCupid() and (target == cli:GetNWString("TTTCupidTarget1", "") or target == cli:GetNWString("TTTCupidTarget2", "")))
        or (target == cli:GetNWString("TTTCupidLover", "")) then
        return true, Color(230, 90, 200, 255), "particle/heart.vmt"
    end
end)

---------------
-- TARGET ID --
---------------

hook.Add("TTTTargetIDPlayerRoleIcon", "Cupid_TTTTargetIDPlayerRoleIcon", function(ply, client, role, noz, colorRole, hideBeggar, showJester, hideBodysnatcher)
    if ply:IsActiveCupid() and ply:SteamID64() == client:GetNWString("TTTCupidShooter", "") then
        return ROLE_CUPID, true
    elseif ply:SteamID64() == client:GetNWString("TTTCupidLover", "") then
        return role, true
    end
end)

hook.Add("TTTTargetIDPlayerRing", "Cupid_TTTTargetIDPlayerRing", function(ent, client, ringVisible)
    if IsPlayer(ent) then
        if ent:IsActiveCupid() and ent:SteamID64() == client:GetNWString("TTTCupidShooter", "") then
            return true, ROLE_COLORS_RADAR[ROLE_CUPID]
        elseif ent:SteamID64() == client:GetNWString("TTTCupidLover", "") then
            return true, ROLE_COLORS_RADAR[ent:GetRole()]
        end
    end
end)

hook.Add("TTTTargetIDPlayerText", "Cupid_TTTTargetIDPlayerText", function(ent, client, text, clr, secondaryText)
    if IsPlayer(ent) then
        if ent:IsActiveCupid() and ent:SteamID64() == client:GetNWString("TTTCupidShooter", "") then
            return StringUpper(ROLE_STRINGS[ROLE_CUPID]), ROLE_COLORS_RADAR[ROLE_CUPID]
        elseif ent:SteamID64() == client:GetNWString("TTTCupidLover", "") then
            return StringUpper(ROLE_STRINGS[ent:GetRole()]), ROLE_COLORS_RADAR[ent:GetRole()]
        end
    end
end)

hook.Add("TTTTargetIDPlayerHintText", "Cupid_TTTTargetIDPlayerHintText", function(ent, client, text, clr)
    if IsPlayer(ent) and ent:SteamID64() == client:GetNWString("TTTCupidLover", "") then
        return "LOVER", Color(230, 90, 200, 255)
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Cupid_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_CUPID then
        local roleTeam = player.GetRoleTeam(ROLE_CUPID, true)
        local roleTeamName, roleColor = GetRoleTeamInfo(roleTeam)
        local html = "The " .. ROLE_STRINGS[ROLE_CUPID] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. roleTeamName .. "</span> role"

        -- TODO: Cupid tutorial

        return html
    end
end)