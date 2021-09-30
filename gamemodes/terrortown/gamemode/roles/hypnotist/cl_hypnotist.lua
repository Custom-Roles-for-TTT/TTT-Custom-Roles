------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Hypnotist_Translations_Initialize", function()
    -- Popup
    LANG.AddToLanguage("english", "info_popup_hypnotist", [[You are {role}! {comrades}

You can use your brain washing device on a corpse to revive them as {atraitor}.

Press {menukey} to receive your special equipment!]])
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Hypnotist_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_HYPNOTIST then
        -- TODO
        return ""
    end
end)