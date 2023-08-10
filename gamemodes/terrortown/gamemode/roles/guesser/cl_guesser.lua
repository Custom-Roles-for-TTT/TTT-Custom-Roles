local hook = hook

local AddHook = hook.Add

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "Guesser_Translations_Initialize", function()
    -- Weapons
    LANG.AddToLanguage("english", "guessingdevice_help_pri", "Press {primaryfire} to guess a player.")
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

    -- Events
    LANG.AddToLanguage("english", "ev_guesser_incorrect", "{guesser} incorrectly guessed {victim}'s role")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_guesser", [[You are {role}! {traitors} think you are {ajester} and you deal no
    damage. However, you can use your role guesser to try and guess a player's
    role. Guess correctly to steal their role. Guess incorrectly and you die.]])
end)

-------------
-- SCORING --
-------------

-- Register the scoring events for the swapper
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

net.Receive("TTT_GuesserGuessed", function(_)
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
        if guessedBy ~= "" then
            return roleFileName, groupingRole, roleColor, name, guessedBy, LANG.GetTranslation("score_guesser_guessed_by")
        end
    end
end)

---------------
-- TARGET ID --
---------------

AddHook("TTTTargetIDPlayerText", "Guesser_TTTTargetIDPlayerText", function(ent, cli, text, col, secondaryText)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not cli:IsGuesser() then return end
    if not IsPlayer(ent) then return end
    if not ent:GetNWBool("TTTGuesserWasGuesser", false) then return end

    local T = LANG.GetTranslation
    if text == nil then
        return T("guesser_unguessable"), ROLE_COLORS[ROLE_GUESSER]
    end
    return text, col, T("guesser_unguessable"), ROLE_COLORS[ROLE_GUESSER]
end)

---------
-- HUD --
---------

AddHook("TTTHUDInfoPaint", "Guesser_TTTHUDInfoPaint", function(client, label_left, label_top, active_labels)
    local hide_role = false
    if ConVarExists("ttt_hide_role") then
        hide_role = GetConVar("ttt_hide_role"):GetBool()
    end

    if hide_role then return end

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
            surface.SetTextColor(ROLE_COLORS_RADAR[role])
        end
        surface.SetTextPos(label_left + w, ScrH() - label_top - h)
        surface.DrawText(text)

        -- Track that the label was added so others can position accurately
        table.insert(active_labels, "guesser")
    end
end)