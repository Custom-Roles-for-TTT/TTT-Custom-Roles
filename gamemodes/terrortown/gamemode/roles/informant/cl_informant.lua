local hook = hook

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Glitch_Translations_Initialize", function()
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
    if cli:IsInformant() or (cli:IsTraitorTeam() and SetGlobalBool("ttt_informant_share_scans", true)) then
        local state = ply:GetNWInt("TTTInformantScanStage", 0)

        local newRole = role
        local newNoZ = noZ
        local newColorRole = colorRole

        if state >= INFORMANT_SCANNED_TEAM then
            newColorRole = GetTeamRole(ply)
            newRole = ROLE_NONE
        end

        if state >= INFORMANT_SCANNED_ROLE then
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

    if IsPlayer(ent) and cli:IsInformant() or (cli:IsTraitorTeam() and SetGlobalBool("ttt_informant_share_scans", true)) then
        local state = ent:GetNWInt("TTTInformantScanStage", 0)

        local newRingVisible = ringVisible
        local newColor = false

        if state == INFORMANT_SCANNED_TEAM then
            newColor = ROLE_COLORS_RADAR[GetTeamRole(ply)]
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

    if IsPlayer(ent) and cli:IsInformant() or (cli:IsTraitorTeam() and SetGlobalBool("ttt_informant_share_scans", true)) then
        local state = ent:GetNWInt("TTTInformantScanStage", 0)

        local newText = text
        local newColor = col

        if state == INFORMANT_SCANNED_TEAM then
            local role = GetTeamRole(ply)
            newColor = ROLE_COLORS_RADAR[role]

            if TRAITOR_ROLES[role] then
                if glitchMode == GLITCH_SHOW_AS_TRAITOR or glitchMode == GLITCH_HIDE_SPECIAL_TRAITOR_ROLES then
                    newText = "UNKNOWN TRAITOR"
                elseif glitchMode == GLITCH_SHOW_AS_SPECIAL_TRAITOR then
                    newText = "UNCONFIRMED " StringUpper(ROLE_STRINGS[role])
                end
            elseif DETECTIVE_ROLES[role] then newText = "UNKNOWN DETECTIVE"
            elseif INNOCENT_ROLES[role] then newText = "UNKNOWN INNOCENT"
            elseif INDEPENDENT_ROLES[role] then newText = "UNKNOWN INDEPENDENT"
            elseif JESTER_ROLES[role] then newText = "UNKNOWN JESTER"
            elseif MONSTER_ROLES[role] then newText = "UNKNOWN MONSTER" end
        elseif state >= INFORMANT_SCANNED_ROLE then
            newColor = ROLE_COLORS_RADAR[ent:GetRole()]
            newText = StringUpper(ROLE_STRINGS[ply:GetRole()])
        end

        return newText, newColor, false
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Informant_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_INFORMANT then
        local roleColor = ROLE_COLORS[ROLE_TRAITOR]
        local html = "The " .. ROLE_STRINGS[ROLE_INFORMANT] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>traitor team</span> whose goal is to learn more about their enemies using their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>scanner</span>."

        return html
    end
end)