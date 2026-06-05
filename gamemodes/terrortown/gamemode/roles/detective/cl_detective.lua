local hook = hook

local AddHook = hook.Add
local RemoveHook = hook.Remove

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "Detective_Translations_Initialize", function()
    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_detective", "Base version of the detectives who can use their DNA scanner to track down killers.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_detective", [[You are {role}! HQ has given you special resources to find the {traitors}.
Use them to help the {innocents} survive, but be careful:
the {traitors} will be looking to take you down first!

Press {menukey} to receive your equipment!]])
end)

--------------
-- TUTORIAL --
--------------

local function Detective_TTTTutorialRoleText(role, titleLabel)
    if role == ROLE_DETECTIVE then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local html = "The " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose job is to find and eliminate their enemies."

        if GetConVar("ttt_detectives_search_only"):GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>" .. ROLE_STRINGS_PLURAL[ROLE_DETECTIVE] .. " are the only roles allowed to <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>search bodies</span> to find information about who they were and how they died."
        end

        html = html .. "<span style='display: block; margin-top: 10px;'>Other players will know you are " .. ROLE_STRINGS_EXT[ROLE_DETECTIVE] .. " just by <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>looking at you</span>"
        local special_detective_mode = GetConVar("ttt_detectives_hide_special_mode"):GetInt()
        if special_detective_mode > SPECIAL_DETECTIVE_HIDE_NONE then
            html = html .. ", but not what specific type of " .. ROLE_STRINGS[ROLE_DETECTIVE]
            if special_detective_mode == SPECIAL_DETECTIVE_HIDE_FOR_ALL then
                html = html .. ". <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Not even you know what type of " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " you are</span>"
            end
        end
        html = html .. ".</span>"

        return html
    end
end

------------------
-- REGISTRATION --
------------------

ROLE_REGISTER_HOOKS[ROLE_DETECTIVE] = function()
    AddHook("TTTTutorialRoleText", "Detective_TTTTutorialRoleText", Detective_TTTTutorialRoleText)
end

ROLE_UNREGISTER_HOOKS[ROLE_DETECTIVE] = function()
    RemoveHook("TTTTutorialRoleText", "Detective_TTTTutorialRoleText")
end