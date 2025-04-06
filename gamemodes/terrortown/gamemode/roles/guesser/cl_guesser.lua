local hook = hook
local string = string

local AddHook = hook.Add
local StringUpper = string.upper

-------------
-- CONVARS --
-------------

local guesser_show_team_threshold = GetConVar("ttt_guesser_show_team_threshold")
local guesser_show_role_threshold = GetConVar("ttt_guesser_show_role_threshold")
local guesser_can_guess_detectives = GetConVar("ttt_guesser_can_guess_detectives")
local guesser_warn_all = GetConVar("ttt_guesser_warn_all")
local glitch_mode = GetConVar("ttt_glitch_mode")
local hide_role = GetConVar("ttt_hide_role")

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "Guesser_Translations_Initialize", function()
    -- Weapons
    LANG.AddToLanguage("english", "guessingdevice_help_pri", "Press {primaryfire} to guess a player's role.")
    LANG.AddToLanguage("english", "guessingdevice_help_sec", "Press {secondaryfire} to select a role.")
    LANG.AddToLanguage("english", "guessingdevice_title", "Role Guesser Selection")

    -- HUD
    LANG.AddToLanguage("english", "guesser_selection", "Role Selected: ")

    -- Target ID
    LANG.AddToLanguage("english", "guesser_unguessable", "UNGUESSABLE")

    -- Scoring
    LANG.AddToLanguage("english", "score_guesser_guessed_by", "Guessed by")

    -- Events
    LANG.AddToLanguage("english", "ev_guesser_correct", "{guesser} correctly guessed {victim}'s role")

    LANG.AddToLanguage("english", "ev_guesser_incorrect", "{guesser} incorrectly guessed {victim}'s role")

    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_guesser", "Must guess another player's role to swap roles with them. If they guess wrong, they die.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_guesser", [[You are {role}! {traitors} think you are {ajester} and you deal no
damage. However, you can use your role guesser to try and guess a player's role. Guess
correctly to steal their role. Guess incorrectly and you die. You are immortal and if
players try to damage you, you will slowly learn information about their role.]])
end)

-------------
-- SCORING --
-------------

-- Register the scoring events for the guesser
hook.Add("Initialize", "Guesser_Scoring_Initialize", function()
    local swap_icon = Material("icon16/arrow_refresh_small.png")
    local fail_icon = Material("icon16/cancel.png")
    local Event = CLSCORE.DeclareEventDisplay
    local PT = LANG.GetParamTranslation
    Event(EVENT_GUESSERCORRECT, {
        text = function(e)
            return PT("ev_guesser_correct", {victim = e.victim, guesser = e.guesser})
        end,
        icon = function(e)
            return swap_icon, "Guessed Correctly"
        end})
    Event(EVENT_GUESSERINCORRECT, {
        text = function(e)
            return PT("ev_guesser_incorrect", {victim = e.victim, guesser = e.guesser})
        end,
        icon = function(e)
            return fail_icon, "Guessed Incorrectly"
        end})
end)

net.Receive("TTT_GuesserGuessed", function()
    local correct = net.ReadBool()
    local victim = net.ReadString()
    local guesser = net.ReadString()
    CLSCORE:AddEvent({
        id = correct and EVENT_GUESSERCORRECT or EVENT_GUESSERINCORRECT,
        victim = victim,
        guesser = guesser
    })
end)

hook.Add("TTTScoringSummaryRender", "Guesser_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
    if not IsPlayer(ply) then return end

    if ply:IsGuesser() then
        local guessedBy = ply:GetNWString("TTTGuesserGuessedBy", "")
        if #guessedBy > 0 then
            return roleFileName, groupingRole, roleColor, name, guessedBy, LANG.GetTranslation("score_guesser_guessed_by")
        end
    end
end)

---------------
-- TARGET ID --
---------------

local function GetTeamRole(ply, cli)
    local glitchMode = glitch_mode:GetInt()

    -- Treat hidden beggars and bodysnatchers as if they are still on the jester team
    if (ply:GetNWBool("WasBeggar", false) and not cli:ShouldRevealBeggar(ply)) or
            (ply:GetNWBool("WasBodysnatcher", false) and not cli:ShouldRevealBodysnatcher(ply)) then
        return ROLE_JESTER
    elseif ply:IsGlitch() then
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

local function GetScanState(ply)
    local damage = ply:GetNWFloat("TTTGuesserDamageDealt", 0)
    local state = GUESSER_SCANNED_ROLE
    if damage < guesser_show_team_threshold:GetInt() then
        state = GUESSER_UNSCANNED
    elseif damage < guesser_show_role_threshold:GetInt() then
        state = GUESSER_SCANNED_TEAM
    end
    return state
end

hook.Add("TTTTargetIDPlayerRoleIcon", "Guesser_TTTTargetIDPlayerRoleIcon", function(ply, cli, role, noz, colorRole, hideBeggar, showJester, hideBodysnatcher)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not cli:IsGuesser() then return end

    local state = GetScanState(ply)
    if state <= GUESSER_UNSCANNED then return end

    local newRole = role
    local newNoZ = noz
    local newColorRole = colorRole

    if state == GUESSER_SCANNED_TEAM then
        newColorRole = GetTeamRole(ply, cli)
        newRole = ROLE_NONE
    end

    if state == GUESSER_SCANNED_ROLE then
        newColorRole = ply:GetRole()
        newRole = ply:GetRole()
    end

    return newRole, newNoZ, newColorRole
end)

hook.Add("TTTTargetIDPlayerRing", "Guesser_TTTTargetIDPlayerRing", function(ent, cli, ringVisible)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not IsPlayer(ent) then return end
    if not cli:IsGuesser() then return end

    local state = GetScanState(ent)
    if state <= GUESSER_UNSCANNED then return end

    local newRingVisible = ringVisible
    local newColor = false

    if state == GUESSER_SCANNED_TEAM then
        newColor = ROLE_COLORS_RADAR[GetTeamRole(ent, cli)]
        newRingVisible = true
    elseif state == GUESSER_SCANNED_ROLE then
        newColor = ROLE_COLORS_RADAR[ent:GetRole()]
        newRingVisible = true
    end

    return newRingVisible, newColor
end)

hook.Add("TTTTargetIDPlayerText", "Guesser_TTTTargetIDPlayerText", function(ent, cli, text, col, secondaryText)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not IsPlayer(ent) then return end
    if not cli:IsGuesser() then return end

    local state = GetScanState(ent)
    if state <= GUESSER_UNSCANNED then return end

    local newText = text
    local newColor = col

    if state == GUESSER_SCANNED_TEAM then
        local T = LANG.GetTranslation
        local PT = LANG.GetParamTranslation
        local role = GetTeamRole(ent, cli)
        newColor = ROLE_COLORS_RADAR[role]

        local labelName = "target_unknown_team"
        local labelParam

        if TRAITOR_ROLES[role] then
            local glitchMode = glitch_mode:GetInt()
            if glitchMode == GLITCH_SHOW_AS_TRAITOR or glitchMode == GLITCH_HIDE_SPECIAL_TRAITOR_ROLES then
                labelParam = T("traitor")
            elseif glitchMode == GLITCH_SHOW_AS_SPECIAL_TRAITOR then
                labelName = "target_unconfirmed_role"
                labelParam = ROLE_STRINGS[role]
            end
        elseif DETECTIVE_ROLES[role] then labelParam = T("detective")
        elseif INNOCENT_ROLES[role] then labelParam = T("innocent")
        elseif INDEPENDENT_ROLES[role] then labelParam = T("independent")
        elseif JESTER_ROLES[role] then labelParam = T("jester")
        elseif MONSTER_ROLES[role] then labelParam = T("monster") end

        if not (TRAITOR_ROLES[role] and not GetGlobalBool("ttt_glitch_round", false)) then
            newText = PT(labelName, { targettype = StringUpper(labelParam) })
        end
    elseif state == GUESSER_SCANNED_ROLE then
        newColor = ROLE_COLORS_RADAR[ent:GetRole()]
        newText = StringUpper(ROLE_STRINGS[ent:GetRole()])
    end

    if ent:GetNWBool("TTTGuesserWasGuesser", false) then
        local T = LANG.GetTranslation
        if newText == nil then
            return T("guesser_unguessable"), ROLE_COLORS[ROLE_GUESSER]
        end
        return newText, newColor, T("guesser_unguessable"), ROLE_COLORS[ROLE_GUESSER]
    end

    return newText, newColor, false
end)

ROLE_IS_TARGETID_OVERRIDDEN[ROLE_GUESSER] = function(ply, target, showJester)
    if not IsPlayer(target) then return end
    if not ply:IsGuesser() then return end

    local state = GetScanState(target)
    if state <= GUESSER_UNSCANNED then return end

    ------ icon, ring, text
    return true, true, true
end

----------------
-- SCOREBOARD --
----------------

hook.Add("TTTScoreboardPlayerRole", "Guesser_TTTScoreboardPlayerRole", function(ply, cli, c, roleStr)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not IsPlayer(ply) then return end
    if not cli:IsGuesser() then return end

    local state = GetScanState(ply)
    if state <= GUESSER_UNSCANNED then return end

    local newColor = c
    local newRoleStr = roleStr

    if state == GUESSER_SCANNED_TEAM then
        newColor = ROLE_COLORS_SCOREBOARD[GetTeamRole(ply, cli)]
        newRoleStr = "nil"
    elseif state == GUESSER_SCANNED_ROLE then
        newColor = ROLE_COLORS_SCOREBOARD[ply:GetRole()]
        newRoleStr = ROLE_STRINGS_SHORT[ply:GetRole()]
    end

    return newColor, newRoleStr
end)

ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_GUESSER] = function(ply, target)
    if not IsPlayer(target) then return end
    if not ply:IsGuesser() then return end

    local state = GetScanState(target)
    if state <= GUESSER_UNSCANNED then return end

    ------ name,  role
    return false, true
end

---------
-- HUD --
---------

AddHook("TTTHUDInfoPaint", "Guesser_TTTHUDInfoPaint", function(client, label_left, label_top, active_labels)
    if hide_role:GetBool() then return end

    if client:IsGuesser() then
        surface.SetFont("TabLarge")
        surface.SetTextColor(255, 255, 255, 230)

        local text = LANG.GetTranslation("guesser_selection")
        local w, h = surface.GetTextSize(text)

        -- Move this up based on how many other labels here are
        label_top = label_top + (20 * #active_labels)

        surface.SetTextPos(label_left, ScrH() - label_top - h)
        surface.DrawText(text)

        local role = client:GetNWInt("TTTGuesserSelection", ROLE_NONE)
        if role == ROLE_NONE then
            text = "None"
        else
            text = ROLE_STRINGS[role]
            local color = ROLE_COLORS_RADAR[role]
            if not DEFAULT_ROLES[role] and ROLE_STARTING_TEAM[role] then
                color = GetRoleTeamColor(ROLE_STARTING_TEAM[role], "radar")
            end
            surface.SetTextColor(color)
        end
        surface.SetTextPos(label_left + w, ScrH() - label_top - h)
        surface.DrawText(text)

        -- Track that the label was added so others can position accurately
        table.insert(active_labels, "guesser")
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Guesser_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_GUESSER then
        local roleColor = GetRoleTeamColor(ROLE_TEAM_JESTER)
        local detectiveColor = ROLE_COLORS[ROLE_DETECTIVE]
        local html = "The " .. ROLE_STRINGS[ROLE_GUESSER] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>jester</span> role whose goal is to figure out and steal the roles of other players."

        html = html .. "<span style='display: block; margin-top: 10px;'>If the " .. ROLE_STRINGS[ROLE_GUESSER] .. " <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>correctly guesses</span> the role of another player, the " .. ROLE_STRINGS[ROLE_GUESSER] .. " swaps roles with the player they guessed and takes over the goal of their new role. However if they <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>incorrectly guess</span> another player's role the " .. ROLE_STRINGS[ROLE_GUESSER] .. " dies instead.</span>"

        html = html .. "<span style='display: block; margin-top: 10px;'>After swapping roles, the new " .. ROLE_STRINGS[ROLE_GUESSER] .. " <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>cannot guess</span> the roles of any players that were previously " .. ROLE_STRINGS_EXT[ROLE_GUESSER] .. " and must guess someone else's role instead.</span>"

        local unguessableRoles = {}
        local unguessableRolesString = GetConVar("ttt_guesser_unguessable_roles"):GetString()
        if #unguessableRolesString > 0 then
            unguessableRoles = string.Explode(",", unguessableRolesString)
        end
        local bannedRoles = ""
        local addComma = false
        for k, v in pairs(unguessableRoles) do
            local bannedRole = table.KeyFromValue(ROLE_STRINGS_RAW, v)
            if bannedRole then
                if addComma then bannedRoles = bannedRoles .. "," end
                bannedRoles = bannedRoles .. " " .. ROLE_STRINGS[bannedRole]
                addComma = true
            end
        end
        if not guesser_can_guess_detectives:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_GUESSER] .. " <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>cannot</span> guess the roles of <span style='color: rgb(" .. detectiveColor.r .. ", " .. detectiveColor.g .. ", " .. detectiveColor.b .. ")'>detectives</span>"
            if #bannedRoles > 0 then
                html = html .. " or any of the following roles:" .. bannedRoles
            end
            html = html .. ".</span>"
        elseif #bannedRoles > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_GUESSER] .. " <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>cannot</span> guess any of the following roles:" .. bannedRoles .. ".</span>"
        end

        if guesser_warn_all:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>All players are <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>warned</span> when there is "  .. ROLE_STRINGS_EXT[ROLE_GUESSER] .. " in the game.</span>"
        end

        return html
    end
end)