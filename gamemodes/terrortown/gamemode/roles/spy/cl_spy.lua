local hook = hook

local AddHook = hook.Add
local RemoveHook = hook.Remove

-------------
-- CONVARS --
-------------

local spy_steal_mode = GetConVar("ttt_spy_steal_mode")
local spy_steal_model = GetConVar("ttt_spy_steal_model")
local spy_steal_name = GetConVar("ttt_spy_steal_name")
local spy_flare_gun_loadout = GetConVar("ttt_spy_flare_gun_loadout")
local spy_flare_gun_shop = GetConVar("ttt_spy_flare_gun_shop")

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "Spy_Translations_Initialize", function()
    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_spy", "Steals the name and player model of players they kill.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_spy", [[You are {role}! {comrades}

When you kill a player, you steal their identity.

Press {menukey} to receive your special equipment!]])
    LANG.AddToLanguage("english", "info_popup_spy_search", [[You are {role}! {comrades}

When you search a player's body, you steal their identity.

Press {menukey} to receive your special equipment!]])
end)

local function Spy_TTTRolePopupRoleStringOverride(cli, roleString)
    if not IsPlayer(cli) or not cli:IsSpy() then return end

    if spy_steal_mode:GetInt() == SPY_STEAL_MODE_SEARCH then
        return roleString .. "_search"
    end
    return roleString
end

----------------
-- ROLE STATE --
----------------

-- If enabled, the Spy's disguise changes their name to the player they last killed
local function Spy_TTTTargetIDPlayerName(ply, cli, text, clr)
    if not spy_steal_name:GetBool() then return end
    if not ply:IsActiveSpy() then return end

    local disguiseName = ply:GetNWString("TTTSpyDisguiseName", "")
    if not disguiseName or #disguiseName == 0 then return end

    -- Show the overwritten name alongside their real name for allies
    if ply == cli or (cli:IsTraitorTeam() and ShouldShowTraitorExtraInfo()) then
        return LANG.GetParamTranslation("player_name_disguised", { name=ply:Nick(), disguise=disguiseName }), clr
    end

    return disguiseName, clr
end

local client
local function Spy_TTTChatPlayerName(ply, team_chat)
    if not spy_steal_name:GetBool() then return end
    if not ply:IsActiveSpy() then return end

    local disguiseName = ply:GetNWString("TTTSpyDisguiseName", "")
    if not disguiseName or #disguiseName == 0 then return end

    if not IsPlayer(client) then
        client = LocalPlayer()
    end

    -- Don't override the name for team chat
    if team_chat then return end

    -- Show the overwritten name alongside their real name for allies
    if ply == client or (client:IsTraitorTeam() and ShouldShowTraitorExtraInfo()) then
        return LANG.GetParamTranslation("player_name_disguised", { name=ply:Nick(), disguise=disguiseName })
    end

    return disguiseName
end

--------------
-- TUTORIAL --
--------------

local function Spy_TTTTutorialRoleText(role, titleLabel)
    if role == ROLE_SPY then
        local roleColor = ROLE_COLORS[ROLE_TRAITOR]
        local html = "The " .. ROLE_STRINGS[ROLE_SPY] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>traitor team</span> whose goal is to sow confusion by stealing the identity of other players. </span>"

        local mode = spy_steal_mode:GetInt()
        local model = spy_steal_model:GetBool()
        local name = spy_steal_name:GetBool()

        if mode > SPY_STEAL_MODE_DISABLE and (model or name) then
            html = html .. "Upon "
            if mode == SPY_STEAL_MODE_SEARCH then
                html = html .. "searching a body"
            else
                html = html .. "killing a player"
            end
            html = html .. ", the " .. ROLE_STRINGS[ROLE_SPY] .. " copies their "

            if model then
                html = html .. "playermodel"

                if name then
                    html = html .. " and "
                end
            end

            if name then
                html = html .. "name"
            end

            html = html .. ", and always takes on the identity of the target.</span>"
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
end

------------------
-- REGISTRATION --
------------------

ROLE_REGISTER_HOOKS[ROLE_SPY] = function()
    AddHook("TTTChatPlayerName", "Spy_TTTChatPlayerName", Spy_TTTChatPlayerName)
    AddHook("TTTRolePopupRoleStringOverride", "Spy_TTTRolePopupRoleStringOverride", Spy_TTTRolePopupRoleStringOverride)
    AddHook("TTTTargetIDPlayerName", "Spy_TTTTargetIDPlayerName", Spy_TTTTargetIDPlayerName)
    AddHook("TTTTutorialRoleText", "Spy_TTTTutorialRoleText", Spy_TTTTutorialRoleText)
end

ROLE_UNREGISTER_HOOKS[ROLE_SPY] = function()
    RemoveHook("TTTChatPlayerName", "Spy_TTTChatPlayerName")
    RemoveHook("TTTRolePopupRoleStringOverride", "Spy_TTTRolePopupRoleStringOverride")
    RemoveHook("TTTTargetIDPlayerName", "Spy_TTTTargetIDPlayerName")
    RemoveHook("TTTTutorialRoleText", "Spy_TTTTutorialRoleText")
end