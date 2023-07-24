local hook = hook
local GetConVar = GetConVar

------------------
-- TRANSLATIONS --
------------------
hook.Add("Initialize", "Spy_Translations_Initialize", function()
    -- Popup
    LANG.AddToLanguage("english", "info_popup_spy", [[You are {role}! {comrades}  
  
    You steal the identity of the last player you kill.
      
    Press {menukey} to receive your special equipment!]])
end)

----------------
-- ROLE STATE --
----------------
hook.Add("TTTTargetIDPlayerName", "Spy_TTTTargetIDPlayerName", function(ply, client, text, clr)
    -- If enabled, the Spy's disguise changes their name to the player they last killed
    if ply:IsSpy() and ply:GetNWString("TTTSpyDisguiseName", false) and not client:IsTraitorTeam() and GetConVar("ttt_spy_steal_name"):GetBool() then
        text = ply:GetNWString("TTTSpyDisguiseName")
    end

    return text, clr
end)

--------------
-- TUTORIAL --
--------------
hook.Add("TTTTutorialRoleText", "Spy_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_SPY then
        local roleColor = ROLE_COLORS[ROLE_TRAITOR]
        local html = "The " .. ROLE_STRINGS[ROLE_SPY] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>traitor team</span> whose goal is to sew confusion by stealing the identity of other players.</span>"
        local model = GetConVar("ttt_spy_steal_model"):GetBool()
        local hands = GetConVar("ttt_spy_steal_model_hands"):GetBool()
        local name = GetConVar("ttt_spy_steal_name"):GetBool()

        if model or hands or name then
            html = html .. "On killing a player, the " .. ROLE_STRINGS[ROLE_SPY] .. " changes the following: "
        end

        if model then
            html = html .. "playermodel, "
        end

        if hands then
            html = html .. "1st-person hands, "
        end

        if name then
            html = html .. "name, "
        end

        if model or hands or name then
            html = html .. " and so takes on the identity of the victim.</span>"
        end

        html = html .. "<span style='display: block; margin-top: 10px;'>The <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>flare gun</span> is "
        local inLoadout = GetConVar("ttt_spy_flare_gun_loadout"):GetBool()

        if inLoadout then
            html = html .. "given to the " .. ROLE_STRINGS[ROLE_SPY] .. " at the start of the round"
        end

        if GetConVar("ttt_spy_flare_gun_shop"):GetBool() then
            if inLoadout then
                html = html .. " and is "
            end

            html = html .. "purchasable in the equipment shop"
        end

        html = html .. ".</span>"

        if GetGlobalBool("ttt_traitor_vision_enable", false) then
            html = html .. "<span style='display: block; margin-top: 10px;'><span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Constant communication</span> with their allies allows them to quickly identify friends by highlighting them in their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>team color</span>.</span>"
        end

        return html
    end
end)