local hook = hook
local string = string

local AddHook = hook.Add
local RemoveHook = hook.Remove

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "Doctor_Translations_Initialize", function()
    -- Weapons
    LANG.AddToLanguage("english", "cure_help_pri", "{primaryfire} to cure another player.")
    LANG.AddToLanguage("english", "cure_help_sec", "{secondaryfire} to cure yourself.")
    LANG.AddToLanguage("english", "cure_desc", [[Use on a player to cure them.

Using this on a player who is not infected will kill them!]])

    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_doctor", "Has access to healing items that can help heal themselves and their teammates.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_doctor", [[You are {role}! You're here to keep your teammates alive.
Use your tools to keep fellow {innocents} in the fight!

Press {menukey} to receive your special equipment!]])
end)

--------------
-- TUTORIAL --
--------------

local function Doctor_TTTTutorialRoleText(role, titleLabel)
    if role == ROLE_DOCTOR then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local html = "The " .. ROLE_STRINGS[ROLE_DOCTOR] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose goal is to heal their patients."

        html = html .. "<span style='display: block; margin-top: 10px;'>Use the equipment shop to buy <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>a health station</span> or <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. string.lower(ROLE_STRINGS[ROLE_PARASITE]) .. " cure</span> to help administer treatments.</span>"

        return html
    end
end

------------------
-- REGISTRATION --
------------------

ROLE_REGISTER_HOOKS[ROLE_DOCTOR] = function()
    AddHook("TTTTutorialRoleText", "Doctor_TTTTutorialRoleText", Doctor_TTTTutorialRoleText)
end

ROLE_UNREGISTER_HOOKS[ROLE_DOCTOR] = function()
    RemoveHook("TTTTutorialRoleText", "Doctor_TTTTutorialRoleText")
end