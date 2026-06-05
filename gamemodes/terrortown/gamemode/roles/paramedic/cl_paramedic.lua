local hook = hook

local AddHook = hook.Add
local RemoveHook = hook.Remove

-------------
-- CONVARS --
-------------

local paramedic_defib_as_innocent = GetConVar("ttt_paramedic_defib_as_innocent")
local paramedic_defib_as_is = GetConVar("ttt_paramedic_defib_as_is")
local paramedic_defib_detectives_as_deputy = GetConVar("ttt_paramedic_defib_detectives_as_deputy")
local paramedic_device_loadout = GetConVar("ttt_paramedic_device_loadout")
local paramedic_device_shop = GetConVar("ttt_paramedic_device_shop")

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "Paramedic_Translations_Initialize", function()
    -- Weapons
    LANG.AddToLanguage("english", "defibrillator_help_pri", "Hold {primaryfire} to revive dead body.")
    LANG.AddToLanguage("english", "defibrillator_help_sec", "The revived player will be respawned at their body's location.")

    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_paramedic", "Can use their defibrillator to revive another player.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_paramedic", [[You are {role}! You can give your fellow {innocents}
a second chance with your defibrillator. Stay alive
and bring back your teams strongest player.]])
end)

--------------
-- TUTORIAL --
--------------

AddHook("TTTTutorialRoleText", "Paramedic_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_PARAMEDIC then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local html = "The " .. ROLE_STRINGS[ROLE_PARAMEDIC] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose goal is to resurrect dead players."

        -- Loadout Defib
        local inLoadout = paramedic_device_loadout:GetBool()
        if inLoadout then
            html = html .. "<span style='display: block; margin-top: 10px;'>A <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>defibrillator is given</span> to the " .. ROLE_STRINGS[ROLE_PARAMEDIC] .. " at the start of the round.</span>"
        end

        -- Shop Defib
        if paramedic_device_shop:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>They <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>can "
            if inLoadout then
                html = html .. "also "
            end
            html = html .. "buy a defibrillator</span> in the shop.</span>"
        end

        -- Respawn as Innocent
        html = html .. "<span style='display: block; margin-top: 10px;'>Any player <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>resurrected by the defibrillator</span>"
        if paramedic_defib_as_innocent:GetBool() then
            html = html .. " is converted to " .. ROLE_STRINGS_EXT[ROLE_INNOCENT]
        else
            html = html .. " retains their previous role"
            if not paramedic_defib_as_is:GetBool() then
                if paramedic_defib_detectives_as_deputy:GetBool() then
                    html = html .. ", with the exception of " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " roles (e.g. " .. ROLE_STRINGS[ROLE_DETECTIVE] .. ", " .. ROLE_STRINGS[ROLE_TRACKER] .. ", " .. ROLE_STRINGS[ROLE_PALADIN] .. ", etc.) which are converted to a promoted ".. ROLE_STRINGS[ROLE_DEPUTY]
                else
                    html = html .. ", with the exception of " .. ROLE_STRINGS[ROLE_DETECTIVE] .. "-like roles (e.g. " .. ROLE_STRINGS[ROLE_DETECTIVE] .. ", " .. ROLE_STRINGS[ROLE_DEPUTY] .. ", " .. ROLE_STRINGS[ROLE_IMPERSONATOR] .. ", etc.) which are converted to the vanilla role for their team (" .. ROLE_STRINGS[ROLE_INNOCENT] .. ", " .. ROLE_STRINGS[ROLE_TRAITOR] .. ", etc.)"
                end
            end
        end
        html = html .. ".</span>"

        return html
    end
end)