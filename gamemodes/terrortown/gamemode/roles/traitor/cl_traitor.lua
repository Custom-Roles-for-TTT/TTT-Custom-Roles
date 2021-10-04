------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Traitor_Translations_Initialize", function()
    -- Popups
    LANG.AddToLanguage("english", "info_popup_traitor_comrades", [[Work with fellow {traitors} to kill all others.
But take care, or your treason may be discovered...

These are your comrades:
{traitorlist}]])

    LANG.AddToLanguage("english", "info_popup_traitor_alone", [[You have no fellow {traitors} this round.

Kill all others to win!]])

    LANG.AddToLanguage("english", "info_popup_traitor_glitch", [[Work with fellow {traitors} to kill all others.
BUT BEWARE! There was {aglitch} in the system and one among you does not seek the same goal.

These may or may not be your comrades:
{traitorlist}]])

    LANG.AddToLanguage("english", "info_popup_traitor", [[You are {role}! {comrades}

Press {menukey} to receive your special equipment!]])
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Traitor_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_TRAITOR then
        local roleColor = ROLE_COLORS[ROLE_TRAITOR]
        local html = "The " .. ROLE_STRINGS[ROLE_TRAITOR] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>traitor team</span> whose job is to kill all of their enemies, both innocent and independent."

        if GetGlobalBool("ttt_traitor_vision_enable", false) then
            html = html .. "<span style='display: block; margin-top: 10px;'><span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Constant communication</span> with their allies allows them to quickly identify friends by highlighting them in their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>team color</span>.</span>"
        end

        return html
    end
end)