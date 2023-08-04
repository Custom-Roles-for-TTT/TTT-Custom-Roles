local hook = hook

-------------
-- CONVARS --
-------------

local deputy_use_detective_icon = GetConVar("ttt_deputy_use_detective_icon")
local deputy_damage_penalty = GetConVar("ttt_deputy_damage_penalty")

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Deputy_Translations_Initialize", function()
    -- Popup
    LANG.AddToLanguage("english", "info_popup_deputy", [[You are {role}! If the {detective} dies you will take
over and gain the ability to buy shop items and search bodies.]])
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleEnabled", "Deputy_TTTTutorialRoleEnabled", function(role)
    if role == ROLE_DEPUTY then
        -- Show the deputy screen if the marshal could spawn them
        return GetConVar("ttt_marshal_enabled"):GetBool()
    end
end)

hook.Add("TTTTutorialRoleText", "Deputy_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_DEPUTY then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local html = "The " .. ROLE_STRINGS[ROLE_DEPUTY] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose goal is to help their team while they wait for the " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " to die."

        -- Promotion
        html = html .. "<span style='display: block; margin-top: 10px;'>After the " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " is killed, <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>the " .. ROLE_STRINGS[ROLE_DEPUTY] .. " is \"promoted\"</span> and then must assume their role as the new " .. ROLE_STRINGS[ROLE_DETECTIVE] .. ".</span>"
        html = html .. "<span style='display: block; margin-top: 10px;'>They have <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>all the powers of " .. ROLE_STRINGS_EXT[ROLE_DETECTIVE] .. "</span> including " .. ROLE_STRINGS[ROLE_DETECTIVE] .. "-only weapons and the ability to search bodies.</span>"

        -- Damage penalty
        if deputy_damage_penalty:GetFloat() > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>Be careful though! Before the " .. ROLE_STRINGS[ROLE_DEPUTY] .. " has been promoted, they <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>do less damage</span>.</span>"
        end

        -- Icon
        html = html .. "<span style='display: block; margin-top: 10px;'>Once promoted, <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>all players</span> will see the "
        if deputy_use_detective_icon:GetBool() then
            html = html .. ROLE_STRINGS[ROLE_DETECTIVE]
        else
            html = html .. ROLE_STRINGS[ROLE_DEPUTY]
        end
        html = html .. " icon over the " .. ROLE_STRINGS[ROLE_DEPUTY] .. "'s head.</span>"

        -- Shop
        html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_DEPUTY] .. " has access to a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>weapon shop</span>"
        if GetConVar("ttt_deputy_shop_active_only"):GetBool() then
            html = html .. ", but only <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>after they are promoted</span>"
        elseif GetConVar("ttt_deputy_shop_delay"):GetBool() then
            html = html .. ", but they are only given their purchased weapons <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>after they are promoted</span>"
        end
        html = html .. ".</span>"

        return html
    end
end)