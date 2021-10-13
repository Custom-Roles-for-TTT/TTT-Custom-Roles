------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Quack_Translations_Initialize", function()
    -- Fake Cure
    LANG.AddToLanguage("english", "fake_cure_desc", "Use on a player to trick them into thinking you cured the {parasite}.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_quack", [[You are {role}! {comrades}

Try to convince others that you are a real {doctor}! However, your tools harm
instead of heal. You know that the best cure for any ailment is death.

Press {menukey} to receive your special equipment!]])
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Quack_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_QUACK then
        local roleColor = ROLE_COLORS[ROLE_TRAITOR]
        local html = "The " .. ROLE_STRINGS[ROLE_QUACK] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>traitor team</span> whose goal is imitate the " .. ROLE_STRINGS[ROLE_DOCTOR] .. " and \"heal\" their patients... <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>to death</span>."

        html = html .. "<span style='display: block; margin-top: 10px;'>Use the equipment shop to buy <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>a bomb station</span> or <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>fake " .. ROLE_STRINGS[ROLE_PARASITE]:lower() .. " cure</span> to help administer \"treatments\".</span>"

        if GetGlobalBool("ttt_quack_phantom_cure", false) then
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_QUACK] .. " can also <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>buy an Exorcism Device</span> which can be used to remove a haunting " .. ROLE_STRINGS[ROLE_PHANTOM] .. ".</span>"
        end

        return html
    end
end)