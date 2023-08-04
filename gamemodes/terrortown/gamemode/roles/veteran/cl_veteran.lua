local hook = hook

-------------
-- CONVARS --
-------------

local veteran_full_heal = GetConVar("ttt_veteran_full_heal")
local veteran_announce = GetConVar("ttt_veteran_announce")

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Veteran_Translations_Initialize", function()
    -- Popup
    LANG.AddToLanguage("english", "info_popup_veteran", [[You are {role}! You work best under pressure.
If you are the last {innocent} player alive you will
deal extra damage.]])
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Veteran_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_VETERAN then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
        local html = "The " .. ROLE_STRINGS[ROLE_VETERAN] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose goal is to survive and help their comrades defeat their enemies."

        html = html .. "<span style='display: block; margin-top: 10px;'>When the " .. ROLE_STRINGS[ROLE_VETERAN] .. " is the <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>last remaining member</span> of the innocent team, "
        if veteran_announce:GetBool() then
            html = html .. "all players "
        else
            html = html .. "they "
        end
        html = html .. "are warned via an on-screen message and they <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>become \"active\"</span>.</span>"

        -- Shop
        html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_VETERAN] .. " has access to a <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>weapon shop</span>"
        if GetConVar("ttt_veteran_shop_active_only"):GetBool() then
            html = html .. ", but only <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>after they activate</span>"
        elseif GetConVar("ttt_veteran_shop_delay"):GetBool() then
            html = html .. ", but they are only given their purchased weapons <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>after they activate</span>"
        end
        html = html .. ".</span>"

        -- Full Heal
        if veteran_full_heal:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>An active " .. ROLE_STRINGS[ROLE_VETERAN] .. " has their <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>health fully restored</span>, allowing them a fighting chance against their remaining enemies.</span>"
        end

        return html
    end
end)