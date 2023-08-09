local hook = hook

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Guesser_Translations_Initialize", function()
    -- Weapons
    LANG.AddToLanguage("english", "guessingdevice_help_pri", "Press {primaryfire} to guess a player.")
    LANG.AddToLanguage("english", "guessingdevice_help_sec", "Press {secondaryfire} to select a role.")
    LANG.AddToLanguage("english", "guessingdevice_title", "Role Guesser Selection")

    -- HUD
    LANG.AddToLanguage("english", "guesser_selection", "Role Selected: ")
end)

---------
-- HUD --
---------

hook.Add("TTTHUDInfoPaint", "Guesser_TTTHUDInfoPaint", function(client, label_left, label_top, active_labels)
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