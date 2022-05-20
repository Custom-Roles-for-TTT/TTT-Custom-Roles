local hook = hook
local string = string

local StringUpper = string.upper

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Informant_Translations_Initialize", function()
    -- Weapons
    LANG.AddToLanguage("english", "infscanner_help_pri", "Look at a player to start scanning.")
    LANG.AddToLanguage("english", "infscanner_help_sec", "Keep light of sight or you will lose your target.")
    LANG.AddToLanguage("english", "infscanner_team", "TEAM")
    LANG.AddToLanguage("english", "infscanner_role", "ROLE")
    LANG.AddToLanguage("english", "infscanner_track", "TRACK")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_informant", [[You are {role}! {comrades}

Hold out your scanner while looking at a player to learn more about them.

Press {menukey} to receive your special equipment!]])
end)

---------------
-- TARGET ID --
---------------

local function GetTeamRole(ply)
    local glitchMode = GetGlobalInt("ttt_glitch_mode", 0)

    if ply:IsGlitch() then
        if glitchMode == GLITCH_SHOW_AS_TRAITOR or glitchMode == GLITCH_HIDE_SPECIAL_TRAITOR_ROLES then
            return ROLE_TRAITOR
        elseif glitchMode == GLITCH_SHOW_AS_SPECIAL_TRAITOR then
            return ply:GetNWInt("GlitchBluff", ROLE_TRAITOR)
        end
    elseif ply:IsTraitorTeam() then
        if glitchMode == GLITCH_SHOW_AS_TRAITOR or glitchMode == GLITCH_HIDE_SPECIAL_TRAITOR_ROLES then
            return ROLE_TRAITOR
        elseif glitchMode == GLITCH_SHOW_AS_SPECIAL_TRAITOR then
            return ply:GetRole()
        end
    elseif ply:IsDetectiveTeam() then return ROLE_DETECTIVE
    elseif ply:IsInnocentTeam() then return ROLE_INNOCENT
    elseif ply:IsIndependentTeam() then return ROLE_DRUNK
    elseif ply:IsJesterTeam() then return ROLE_JESTER
    elseif ply:IsMonsterTeam() then return ply:GetRole() end
end

hook.Add("TTTTargetIDPlayerRoleIcon", "Informant_TTTTargetIDPlayerRoleIcon", function(ply, cli, role, noz, colorRole, hideBeggar, showJester, hideBodysnatcher)
    if GetRoundState() < ROUND_ACTIVE then return end

    local override, _, _ = cli:IsTargetIDOverridden(ply, showJester)
    if override then return end

    if cli:IsInformant() or (cli:IsTraitorTeam() and GetGlobalBool("ttt_informant_share_scans", true)) then
        local state = ply:GetNWInt("TTTInformantScanStage", INFORMANT_UNSCANNED)

        local newRole = role
        local newNoZ = noZ
        local newColorRole = colorRole

        if state >= INFORMANT_SCANNED_TEAM then
            newColorRole = GetTeamRole(ply)
            newRole = ROLE_NONE
        end

        if state >= INFORMANT_SCANNED_ROLE then
            newColorRole = ply:GetRole()
            newRole = ply:GetRole()
        end

        if state == INFORMANT_SCANNED_TRACKED then
            newNoZ = true
        end

        return newRole, newNoZ, newColorRole
    end
end)

hook.Add("TTTTargetIDPlayerRing", "Informant_TTTTargetIDPlayerRing", function(ent, cli, ringVisible)
    if GetRoundState() < ROUND_ACTIVE then return end

    local _, override, _ = cli:IsTargetIDOverridden(ply)
    if override then return end

    if IsPlayer(ent) and cli:IsInformant() or (cli:IsTraitorTeam() and GetGlobalBool("ttt_informant_share_scans", true)) then
        local state = ent:GetNWInt("TTTInformantScanStage", INFORMANT_UNSCANNED)

        local newRingVisible = ringVisible
        local newColor = false

        if state == INFORMANT_SCANNED_TEAM then
            newColor = ROLE_COLORS_RADAR[GetTeamRole(ent)]
            newRingVisible = true
        elseif state >= INFORMANT_SCANNED_ROLE then
            newColor = ROLE_COLORS_RADAR[ent:GetRole()]
            newRingVisible = true
        end

        return newRingVisible, newColor
    end
end)

hook.Add("TTTTargetIDPlayerText", "Informant_TTTTargetIDPlayerText", function(ent, cli, text, col, secondaryText)
    if GetRoundState() < ROUND_ACTIVE then return end

    local _, _, override = cli:IsTargetIDOverridden(ply)
    if override then return end

    if IsPlayer(ent) and cli:IsInformant() or (cli:IsTraitorTeam() and GetGlobalBool("ttt_informant_share_scans", true)) then
        local state = ent:GetNWInt("TTTInformantScanStage", INFORMANT_UNSCANNED)

        local newText = text
        local newColor = col

        if state == INFORMANT_SCANNED_TEAM then
            local T = LANG.GetTranslation
            local PT = LANG.GetParamTranslation
            local role = GetTeamRole(ent)
            newColor = ROLE_COLORS_RADAR[role]

            local label_name = "target_unknown_team"
            local label_param
            if TRAITOR_ROLES[role] then
                if glitchMode == GLITCH_SHOW_AS_TRAITOR or glitchMode == GLITCH_HIDE_SPECIAL_TRAITOR_ROLES then
                    label_param = T("traitor")
                elseif glitchMode == GLITCH_SHOW_AS_SPECIAL_TRAITOR then
                    label_name = "label_unconfirmed_role"
                    label_param = ROLE_STRINGS[role]
                end
            elseif DETECTIVE_ROLES[role] then label_param = ROLE_STRINGS[ROLE_DETECTIVE]
            elseif INNOCENT_ROLES[role] then label_param = T("innocent")
            elseif INDEPENDENT_ROLES[role] then label_param = T("independent")
            elseif JESTER_ROLES[role] then label_param = T("jester")
            elseif MONSTER_ROLES[role] then label_param = T("monster") end

            if not (TRAITOR_ROLES[role] and not GetGlobalBool("ttt_glitch_round", false)) then
                newText = PT(label_name, { targettype = StringUpper(label_param) })
            end
        elseif state >= INFORMANT_SCANNED_ROLE then
            newColor = ROLE_COLORS_RADAR[ent:GetRole()]
            newText = StringUpper(ROLE_STRINGS[ent:GetRole()])
        end

        return newText, newColor, false
    end
end)

----------------
-- SCOREBOARD --
----------------

hook.Add("TTTScoreboardPlayerRole", "Informant_TTTScoreboardPlayerRole", function(ply, cli, c, roleStr)
    if GetRoundState() < ROUND_ACTIVE then return end

    local _, override = cli:IsScoreboardInfoOverridden(ply)
    if override then return end

    if IsPlayer(ply) and cli:IsInformant() or (cli:IsTraitorTeam() and GetGlobalBool("ttt_informant_share_scans", true)) then
        local state = ply:GetNWInt("TTTInformantScanStage", INFORMANT_UNSCANNED)

        local newColor = c
        local newRoleStr = roleStr

        if state == INFORMANT_SCANNED_TEAM then
            newColor = ROLE_COLORS_SCOREBOARD[GetTeamRole(ply)]
            newRoleStr = "nil"
        elseif state >= INFORMANT_SCANNED_ROLE then
            newColor = ROLE_COLORS_SCOREBOARD[ply:GetRole()]
            newRoleStr = ROLE_STRINGS_SHORT[ply:GetRole()]
        end

        return newColor, newRoleStr
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Informant_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_INFORMANT then
        local roleColor = ROLE_COLORS[ROLE_TRAITOR]
        local jesterColor = ROLE_COLORS[ROLE_JESTER]
        local glitchColor = ROLE_COLORS[ROLE_GLITCH]
        local html = "The " .. ROLE_STRINGS[ROLE_INFORMANT] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>traitor team</span> whose goal is to learn more about their enemies using their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>scanner</span>."

        local scanJesters = GetGlobalBool("ttt_informant_can_scan_jesters", false)
        local scanGlitches = GetGlobalBool("ttt_informant_can_scan_glitches", false)
        if not (scanJesters and scanGlitches) then
            html = html + "<span style='display: block; margin-top: 10px;'>You cannot scan "
            if not scanJesters then
                html = html + "<span style='color: rgb(" .. jesterColor.r .. ", " .. jesterColor.g .. ", " .. jesterColor.b .. ")'>jesters</span>"
            end
            if not scanJesters and not scanGlitches then
                html = html + " or "
            end
            if not scanGlitches then
                html = html + "<span style='color: rgb(" .. glitchColor.r .. ", " .. glitchColor.g .. ", " .. glitchColor.b .. ")'>glitches</span>"
            end
            html = html + ".</span>"
        end

        if GetGlobalBool("ttt_informant_share_scans", false) then
            html = html + "<span style='display: block; margin-top: 10px;'>Information you discover is automatically shared with fellow <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>traitors</span>.</span>"
        end

        return html
    end
end)