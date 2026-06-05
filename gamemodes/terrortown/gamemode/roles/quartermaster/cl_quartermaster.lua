local hook = hook

local AddHook = hook.Add

-------------
-- CONVARS --
-------------

local quartermaster_limited_loot = GetConVar("ttt_quartermaster_limited_loot")

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "Quartermaster_Translations_Initialize", function()
    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_quartermaster", "Can buy items available to Traitors as weapon crates for other players.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_quartermaster", [[You are {role}! As {adetective}, HQ has given you special resources to find the {traitors}.
You've infiltrated their supply lines, allowing you to drop weapons crates of goodies for your allies.

Press {menukey} to procure special equipment for others!]])
end)

----------------
-- ROLE POPUP --
----------------

AddHook("TTTTutorialRoleText", "Quartermaster_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_QUARTERMASTER then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local detectiveColor = ROLE_COLORS[ROLE_DETECTIVE]
        local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
        local html = "The " .. ROLE_STRINGS[ROLE_QUARTERMASTER] .. " is a " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " and a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose job is to find and eliminate their enemies."

        html = html .. "<span style='display: block; margin-top: 10px;'>Instead of getting a DNA Scanner like a vanilla <span style='color: rgb(" .. detectiveColor.r .. ", " .. detectiveColor.g .. ", " .. detectiveColor.b .. ")'>" .. ROLE_STRINGS[ROLE_DETECTIVE] .. "</span>, they have the ability to buy crates <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>full of traitor weapons</span> to give to their allies.</span>"

        html = html .. "<span style='display: block; margin-top: 10px;'>" .. ROLE_STRINGS_PLURAL[ROLE_QUARTERMASTER] .. " <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>cannot open the crates they drop</span>, however, so be sure to <span style='color: rgb(" .. detectiveColor.r .. ", " .. detectiveColor.g .. ", " .. detectiveColor.b .. ")'>keep your allies well-stocked</span>.</span>"

        if quartermaster_limited_loot:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>Each player can only <span style='color: rgb(" .. detectiveColor.r .. ", " .. detectiveColor.g .. ", " .. detectiveColor.b .. ")'>open one crate per round</span> so make sure you give them something good.</span>"
        end

        return html
    end
end)