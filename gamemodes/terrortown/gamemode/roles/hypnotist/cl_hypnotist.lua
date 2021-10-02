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
        local roleColor = ROLE_COLORS[ROLE_TRAITOR]
        local html = "The " .. ROLE_STRINGS[ROLE_HYPNOTIST] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>traitor team</span> whose goal is to revive a dead player as an ally using their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>brainwashing device</span>."

        html = html .. "<span style='display: block; margin-top: 10px;'>The <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>brainwashing device</span> is "

        local inLoadout = GetGlobalBool("ttt_hypnotist_device_loadout", true)
        if inLoadout then
            html = html .. "given to the player at the start of the round"
        end

        if GetGlobalBool("ttt_hypnotist_device_shop", false) then
            if inLoadout then
                html = html .. " and is "
            end
            html = html .. "purchasable in the equipment shop"
        end
        html = html .. ".</span>"

        return html
    end
end)