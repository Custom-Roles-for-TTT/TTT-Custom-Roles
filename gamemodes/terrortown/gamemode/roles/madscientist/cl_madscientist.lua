local hook = hook

local AddHook = hook.Add
local RemoveHook = hook.Remove

-------------
-- CONVARS --
-------------

local madscientist_respawn_enabled = GetConVar("ttt_madscientist_respawn_enabled")

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "MadScientist_Translations_Initialize", function()
    -- Weapons
    LANG.AddToLanguage("english", "zombificator_help_pri", "Hold {primaryfire} to zombify dead body.")
    LANG.AddToLanguage("english", "zombificator_help_sec", "The revived player will become a zombie.")

    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_madscientist", "Can use their zombification device to revive players as Zombies. They win by turning everyone into a Zombie.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_madscientist", [[You are {role}! Try to spread your virus to
everyone! Using your zombification device on a dead
body will revive them as {azombie}.]])
end)

--------------
-- TUTORIAL --
--------------

local function MadScientist_TTTTutorialRoleText(role, titleLabel)
    if role == ROLE_MADSCIENTIST then
        local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
        local roleTeam = player.GetRoleTeam(ROLE_MADSCIENTIST, true)
        local roleTeamString, roleColor = GetRoleTeamInfo(roleTeam, true)

        local html = "The " .. ROLE_STRINGS[ROLE_MADSCIENTIST] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. string.lower(roleTeamString) .. " team</span> whose goal is to resurrect dead bodies as their <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>" .. ROLE_STRINGS[ROLE_ZOMBIE] .. " minions</span>."

        -- Respawn
        if madscientist_respawn_enabled:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>If the " .. ROLE_STRINGS[ROLE_MADSCIENTIST] .. " is killed they will <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>respawn as " .. ROLE_STRINGS_EXT[ROLE_ZOMBIE] .. " thrall</spawn>.</span>"
        end

        return html
    end
end

------------------
-- REGISTRATION --
------------------

ROLE_REGISTER_HOOKS[ROLE_MADSCIENTIST] = function()
    AddHook("TTTTutorialRoleText", "MadScientist_TTTTutorialRoleText", MadScientist_TTTTutorialRoleText)
end

ROLE_UNREGISTER_HOOKS[ROLE_MADSCIENTIST] = function()
    RemoveHook("TTTTutorialRoleText", "MadScientist_TTTTutorialRoleText")
end