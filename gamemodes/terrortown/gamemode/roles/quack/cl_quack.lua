local hook = hook
local string = string

-------------
-- CONVARS --
-------------

local quack_phantom_cure = GetConVar("ttt_quack_phantom_cure")
local quack_station_bomb = GetConVar("ttt_quack_station_bomb")

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Quack_Translations_Initialize", function()
    -- Weapons
    LANG.AddToLanguage("english", "fake_cure_desc", "Use on a player to trick them into thinking you cured them.")

    LANG.AddToLanguage("english", "bstation_name", "Bomb Station")
    LANG.AddToLanguage("english", "bstation_hint", "Hold {usekey} to fake receiving health. Charge: {num}.")
    LANG.AddToLanguage("english", "bstation_broken", "Your Bomb Station has been destroyed!")
    LANG.AddToLanguage("english", "bstation_help", "{primaryfire} places the Bomb Station.")
    LANG.AddToLanguage("english", "bstation_desc", [[
Appears as a health station to non-{traitors}.

Detonates when used by a non-{traitor}.
{traitors} can use to deplete fake charge.]])

    LANG.AddToLanguage("english", "stationb_name", "Station Bomb")
    LANG.AddToLanguage("english", "stationb_help", "Hold {primaryfire} to add a bomb to a Health Station.")
    LANG.AddToLanguage("english", "stationb_desc", [[
Converts a {healthstation}
into a {bombstation}.]])

    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_quack", "Can buy healing items and fake healing items that kill players instead of healing them.")

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

        html = html .. "<span style='display: block; margin-top: 10px;'>Use the equipment shop to buy <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>a bomb station</span> or <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>fake " .. string.lower(ROLE_STRINGS[ROLE_PARASITE]) .. " cure</span> to help administer \"treatments\".</span>"

        if quack_phantom_cure:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_QUACK] .. " can also <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>buy an Exorcism Device</span> which can be used to remove a haunting " .. ROLE_STRINGS[ROLE_PHANTOM] .. ".</span>"
        end

        if quack_station_bomb:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>There is also a buyable <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Station Bomb</span> which can be used to convert someone's Health Station into a Bomb Station.</span>"
        end

        return html
    end
end)