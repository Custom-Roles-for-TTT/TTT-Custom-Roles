local hook = hook

local AddHook = hook.Add
local RemoveHook = hook.Remove

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "Traitor_Translations_Initialize", function()
    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_traitor", "Base member of the traitor team who can buy items to help defeat their enemies.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_traitor", [[You are {role}! {comrades}

Press {menukey} to receive your special equipment!]])
end)

--------------
-- TUTORIAL --
--------------

AddHook("TTTTutorialRoleText", "Traitor_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_TRAITOR then
        local roleColor = ROLE_COLORS[ROLE_TRAITOR]
        local html = "The " .. ROLE_STRINGS[ROLE_TRAITOR] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>traitor team</span> whose job is to kill all of their enemies, both innocent and independent."

        if GetConVar("ttt_traitors_vision_enabled"):GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'><span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Constant communication</span> with their allies allows them to quickly identify friends by highlighting them in their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>team color</span>.</span>"
        end

        return html
    end
end)