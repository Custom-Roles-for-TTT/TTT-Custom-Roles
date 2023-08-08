local hook = hook

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Guesser_Translations_Initialize", function()
    -- Weapons
    LANG.AddToLanguage("english", "guessingdevice_help_pri", "Press {primaryfire} to guess a player.")
    LANG.AddToLanguage("english", "guessingdevice_help_sec", "Press {secondaryfire} to select a role.")
    LANG.AddToLanguage("english", "guessingdevice_title", "Role Guesser Selection")
end)