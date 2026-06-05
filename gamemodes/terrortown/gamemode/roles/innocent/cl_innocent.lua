local hook = hook

local AddHook = hook.Add

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "Innocent_Translations_Initialize", function()
    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_innocent", "Base member of the innocent team that has no special abilities.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_innocent", [[You are {role}! But there are {traitors} around...
Who can you trust, and who is out to fill you with bullets?

Watch your back and work with your comrades to get out of this alive!]])
end)

--------------
-- TUTORIAL --
--------------

AddHook("TTTTutorialRoleText", "Innocent_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_INNOCENT then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        return "The " .. ROLE_STRINGS[ROLE_INNOCENT] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> with no special abilities."
    end
end)