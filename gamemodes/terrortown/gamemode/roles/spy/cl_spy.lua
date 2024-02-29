local hook = hook
local GetConVar = GetConVar

-------------
-- CONVARS --
-------------

local spy_steal_model = GetConVar("ttt_spy_steal_model")
local spy_steal_name = GetConVar("ttt_spy_steal_name")
local spy_flare_gun_loadout = GetConVar("ttt_spy_flare_gun_loadout")
local spy_flare_gun_shop = GetConVar("ttt_spy_flare_gun_shop")

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Spy_Translations_Initialize", function()
    -- Popup
    LANG.AddToLanguage("english", "info_popup_spy", [[You are {role}! {comrades}

When you kill a player, you steal their identity.

Press {menukey} to receive your special equipment!]])
end)

----------------
-- ROLE STATE --
----------------

-- If enabled, the Spy's disguise changes their name to the player they last killed
hook.Add("TTTTargetIDPlayerName", "Spy_TTTTargetIDPlayerName", function(ply, cli, text, clr)
    if not spy_steal_name:GetBool() then return end
    if not ply:IsActiveSpy() then return end

    local disguiseName = ply:GetNWString("TTTSpyDisguiseName", nil)
    if not disguiseName or #disguiseName == 0 then return end

    -- Show the overwritten name alongside their real name for allies
    if ply == cli or cli:IsTraitorTeam() then
        return LANG.GetParamTranslation("player_name_disguised", { name=ply:Nick(), disguise=disguiseName }), clr
    end

    return disguiseName, clr
end)

local client
hook.Add("TTTChatPlayerName", "Spy_TTTChatPlayerName", function(ply, team_chat)
    if not spy_steal_name:GetBool() then return end
    if not ply:IsActiveSpy() then return end

    local disguiseName = ply:GetNWString("TTTSpyDisguiseName", nil)
    if not disguiseName or #disguiseName == 0 then return end

    if not IsPlayer(client) then
        client = LocalPlayer()
    end

    -- Don't override the name for team chat
    if team_chat then return end

    -- Show the overwritten name alongside their real name for allies
    if ply == client or client:IsTraitorTeam() then
        return LANG.GetParamTranslation("player_name_disguised", { name=ply:Nick(), disguise=disguiseName })
    end

    return disguiseName
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Spy_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_SPY then
        local roleColor = ROLE_COLORS[ROLE_TRAITOR]
        local html = "The " .. ROLE_STRINGS[ROLE_SPY] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>traitor team</span> whose goal is to sow confusion by stealing the identity of other players. </span>"
        local model = spy_steal_model:GetBool()
        local name = spy_steal_name:GetBool()

        if model or name then
            html = html .. "On killing a player, the " .. ROLE_STRINGS[ROLE_SPY] .. " copies their "

            if model then
                html = html .. "playermodel"

                if name then
                    html = html .. " and "
                end
            end

            if name then
                html = html .. "name"
            end

            html = html .. ", and always takes on the identity of the last player they killed.</span>"
        end

        local inLoadout = spy_flare_gun_loadout:GetBool()
        local inShop = spy_flare_gun_shop:GetBool()

        if inLoadout or inShop then
            html = html .. "<span style='display: block; margin-top: 10px;'>A <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>flare gun</span> is "

            if inLoadout then
                html = html .. "given to the " .. ROLE_STRINGS[ROLE_SPY] .. " at the start of the round"
            end

            if inShop then
                if inLoadout then
                    html = html .. " and is "
                end

                html = html .. "purchasable in the equipment shop"
            end

            html = html .. ".</span>"
        end

        if GetConVar("ttt_traitors_vision_enabled"):GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'><span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Constant communication</span> with their allies allows them to quickly identify friends by highlighting them in their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>team color</span>.</span>"
        end

        return html
    end
end)