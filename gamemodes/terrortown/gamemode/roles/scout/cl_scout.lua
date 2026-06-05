local hook = hook
local string = string

local AddHook = hook.Add
local RemoveHook = hook.Remove
local StringLower = string.lower

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "Scout_Translations_Initialize", function()
    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_scout", "Learns which traitor roles are in play.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_scout", [[You are {role}! You know which {traitor}
roles are in play. Use your intel to help your fellow {innocents}!]])
end)

--------------
-- TUTORIAL --
--------------

local function Scout_TTTTutorialRoleText(role, titleLabel)
    if role == ROLE_SCOUT then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local html = "The " .. ROLE_STRINGS[ROLE_SCOUT] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> who knows which traitor"

        local revealJesters = GetConVar("ttt_scout_reveal_jesters"):GetBool()
        local revealIndependents = GetConVar("ttt_scout_reveal_independents"):GetBool()
        local revealMonsters = GetConVar("ttt_scout_reveal_monsters"):GetBool()

        local roles = {}
        if revealJesters then
            table.insert(roles, StringLower(LANG.GetTranslation("jester")))
        end
        if revealIndependents then
            table.insert(roles, StringLower(LANG.GetTranslation("independent")))
        end
        if revealMonsters then
            table.insert(roles, StringLower(LANG.GetTranslation("monster")))
        end

        local rolesString = ""
        if #roles > 1 then
            rolesString = ", " .. table.concat(roles, ", ", 1, #roles - 1) .. ", and " .. roles[#roles]
        elseif #roles == 1 then
            rolesString = " and " .. roles[1]
        end

        html = html .. rolesString .. " roles are in play."

        local delayIntel = GetConVar("ttt_scout_delay_intel"):GetInt()
        if delayIntel > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>This information is revealed to the Scout after <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. delayIntel .. " second(s)</span>.</span>"
        end

        return html
    end
end

------------------
-- REGISTRATION --
------------------

ROLE_REGISTER_HOOKS[ROLE_SCOUT] = function()
    AddHook("TTTTutorialRoleText", "Scout_TTTTutorialRoleText", Scout_TTTTutorialRoleText)
end

ROLE_UNREGISTER_HOOKS[ROLE_SCOUT] = function()
    RemoveHook("TTTTutorialRoleText", "Scout_TTTTutorialRoleText")
end