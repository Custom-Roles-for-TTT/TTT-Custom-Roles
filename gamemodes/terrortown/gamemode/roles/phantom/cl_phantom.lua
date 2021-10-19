------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Phantom_Translations_Initialize", function()
    -- HUD
    LANG.AddToLanguage("english", "haunt_title", "WILLPOWER")
    LANG.AddToLanguage("english", "haunt_move", "MOVE KEYS: Move (Cost: {num}%)")
    LANG.AddToLanguage("english", "haunt_jump", "SPACE: Jump (Cost: {num}%)")
    LANG.AddToLanguage("english", "haunt_drop", "RIGHT CLICK: Drop (Cost: {num}%)")
    LANG.AddToLanguage("english", "haunt_attack", "LEFT CLICK: Attack (Cost: {num}%)")

    -- Event
    LANG.AddToLanguage("english", "ev_haunt", "{victim} started haunting {attacker}")

    -- Weapons
    LANG.AddToLanguage("english", "exor_help_pri", "{primaryfire} to cleanse another player.")
    LANG.AddToLanguage("english", "exor_help_sec", "{secondaryfire} to cleanse yourself.")
    LANG.AddToLanguage("english", "exor_desc", "Use on a player to exorcise a {phantom}")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_phantom", [[You are {role}! Try to survive and help your {innocent} friends!
You will haunt the player who kills you causing black smoke to appear.
If the player you are haunting dies you will be respawned!]])
end)

-------------
-- SCORING --
-------------

hook.Add("Initialize", "Phantom_Scoring_Initialize", function()
    local haunt_icon = Material("icon16/group.png")
    local PT = LANG.GetParamTranslation
    local Event = CLSCORE.DeclareEventDisplay
    Event(EVENT_HAUNT, {
        text = function(e)
            return PT("ev_haunt", {victim = e.vic, attacker = e.att})
        end,
        icon = function(e)
            return haunt_icon, "Haunt"
        end})
end)

net.Receive("TTT_PhantomHaunt", function(len)
    local victim = net.ReadString()
    local attacker = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_HAUNT,
        vic = victim,
        att = attacker
    })
end)

--------------
-- HAUNTING --
--------------

hook.Add("TTTSpectatorShowHUD", "Phantom_Haunting_TTTSpectatorShowHUD", function(cli, tgt)
    if not cli:IsPhantom() then return end

    local L = LANG.GetUnsafeLanguageTable()
    local willpower_colors = {
        border = COLOR_WHITE,
        background = Color(17, 115, 135, 222),
        fill = Color(82, 226, 255, 255)
    }
    local powers = {
        [L.haunt_move] = GetGlobalInt("ttt_phantom_killer_haunt_move_cost", 25),
        [L.haunt_jump] = GetGlobalInt("ttt_phantom_killer_haunt_jump_cost", 50),
        [L.haunt_drop] = GetGlobalInt("ttt_phantom_killer_haunt_drop_cost", 75),
        [L.haunt_attack] = GetGlobalInt("ttt_phantom_killer_haunt_attack_cost", 100)
    }
    local max_power = GetGlobalInt("ttt_phantom_killer_haunt_power_max", 100)
    local current_power = cli:GetNWInt("HauntingPower", 0)

    HUD:PaintPowersHUD(powers, max_power, current_power, willpower_colors, L.haunt_title)
end)

hook.Add("TTTShouldPlayerSmoke", "Phantom_Haunting_TTTShouldPlayerSmoke", function(v, client, shouldSmoke, smokeColor, smokeParticle, smokeOffset)
    if v:GetNWBool("Haunted", false) and GetGlobalBool("ttt_phantom_killer_smoke", false) then
        return true
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Phantom_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_PHANTOM then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local html = "The " .. ROLE_STRINGS[ROLE_PHANTOM] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose goal is to help defeat their team's enemies."

        -- Respawn
        html = html .. "<span style='display: block; margin-top: 10px;'>If the " .. ROLE_STRINGS[ROLE_PHANTOM] .. " is killed, they will <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>be resurrected</span> if the person that killed them then dies.</span>"

        -- Smoke
        if GetGlobalBool("ttt_phantom_killer_smoke", false) then
            html = html .. "<span style='display: block; margin-top: 10px;'>Before the " .. ROLE_STRINGS[ROLE_PHANTOM] .. " is respawned, their killer is enveloped in a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>shroud of smoke</span>, revealing themselves as the " .. ROLE_STRINGS[ROLE_PHANTOM] .. "'s killer to other players.</span>"
        end

        -- Haunting
        if GetGlobalBool("ttt_phantom_killer_haunt", true) then
            local max = GetGlobalInt("ttt_phantom_killer_haunt_power_max", 100)
            local move_cost = GetGlobalInt("ttt_phantom_killer_haunt_move_cost", 25)
            local jump_cost = GetGlobalInt("ttt_phantom_killer_haunt_jump_cost", 50)
            local drop_cost = GetGlobalInt("ttt_phantom_killer_haunt_drop_cost", 75)
            local attack_cost = GetGlobalInt("ttt_phantom_killer_haunt_attack_cost", 100)

            -- Haunting powers
            if move_cost > 0 or jump_cost > 0 or drop_cost > 0 or attack_cost > 0 then
                html = html .. "<span style='display: block; margin-top: 10px'>While dead, the " .. ROLE_STRINGS[ROLE_PHANTOM] .. " will haunt their killer, generating up to <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. max .. " haunting power</span> over time. This haunting power can be used on the following actions:</span>"

                html = html .. "<ul style='margin-top: 0'>"
                if move_cost > 0 then
                    html = html .. "<li>Move Target (Cost: " .. move_cost .. ") - <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Move the target</span> in the direction you choose using your movement keys</li>"
                end
                if jump_cost > 0 then
                    html = html .. "<li>Jump (Cost: " .. jump_cost .. ") - <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Make the target jump</span> using your jump key</li>"
                end
                if drop_cost > 0 then
                    html = html .. "<li>Drop Weapon (Cost: " .. drop_cost .. ") - Make the target <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>drop their weapon</span> using your weapon drop key</li>"
                end
                if attack_cost > 0 then
                    html = html .. "<li>Attack (Cost: " .. attack_cost .. ") - Make the target <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>attack with their current weapon</span> using your primary attack key</li>"
                end
                html = html .. "</ul>"
            end
        end

        return html
    end
end)