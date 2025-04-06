local hook = hook
local net = net

-------------
-- CONVARS --
-------------

local phantom_killer_smoke = GetConVar("ttt_phantom_killer_smoke")
local phantom_killer_haunt = GetConVar("ttt_phantom_killer_haunt")
local phantom_killer_haunt_power_max = GetConVar("ttt_phantom_killer_haunt_power_max")
local phantom_killer_haunt_move_cost = GetConVar("ttt_phantom_killer_haunt_move_cost")
local phantom_killer_haunt_attack_cost = GetConVar("ttt_phantom_killer_haunt_attack_cost")
local phantom_killer_haunt_jump_cost = GetConVar("ttt_phantom_killer_haunt_jump_cost")
local phantom_killer_haunt_drop_cost = GetConVar("ttt_phantom_killer_haunt_drop_cost")
local phantom_weaker_each_respawn = GetConVar("ttt_phantom_weaker_each_respawn")
local phantom_announce_death = GetConVar("ttt_phantom_announce_death")
local phantom_killer_footstep_time = GetConVar("ttt_phantom_killer_footstep_time")
local phantom_respawn = GetConVar("ttt_phantom_respawn")

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Phantom_Translations_Initialize", function()
    -- Target ID
    LANG.AddToLanguage("english", "target_haunted", "HAUNTED BY PHANTOM")

    -- HUD
    LANG.AddToLanguage("english", "haunt_title", "WILLPOWER")
    LANG.AddToLanguage("english", "haunt_move", "Move")
    LANG.AddToLanguage("english", "haunt_move_desc", "Press movement keys to make {target} move")
    LANG.AddToLanguage("english", "haunt_jump", "Jump")
    LANG.AddToLanguage("english", "haunt_jump_desc", "Press space to make {target} jump")
    LANG.AddToLanguage("english", "haunt_drop", "Drop Weapon")
    LANG.AddToLanguage("english", "haunt_drop_desc", "Right click to make {target} drop their weapon")
    LANG.AddToLanguage("english", "haunt_attack", "Attack")
    LANG.AddToLanguage("english", "haunt_attack_desc", "Left click to make {target} attack")

    -- Event
    LANG.AddToLanguage("english", "ev_haunt", "{victim} started haunting {attacker}")

    -- Weapons
    LANG.AddToLanguage("english", "exor_help_pri", "{primaryfire} to cleanse another player.")
    LANG.AddToLanguage("english", "exor_help_sec", "{secondaryfire} to cleanse yourself.")
    LANG.AddToLanguage("english", "exor_desc", "Use on a player to exorcise a {phantom}")

    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_phantom", "Haunt's their killer for a chance to disrupt the player they are haunting and respawn if they die.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_phantom", [[You are {role}! Try to survive and help your {innocent} friends!{abilities}]])
    LANG.AddToLanguage("english", "info_popup_phantom_haunt", "You will haunt the player who kills you.")
    LANG.AddToLanguage("english", "info_popup_phantom_smoke", "Haunted players will be enveloped by black smoke.")
    LANG.AddToLanguage("english", "info_popup_phantom_respawn", "If the player you are haunting dies you will be respawned!")
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

------------------
-- CUPID LOVERS --
------------------

local function IsLoverHaunting(cli, target)
    local loverSID = cli:GetNWString("TTTCupidLover", "")
    local lover = player.GetBySteamID64(loverSID)
    return IsPlayer(target) and IsPlayer(lover) and target:GetNWBool("PhantomHaunted", false) and lover:GetNWString("PhantomHauntingTarget", "") == target:SteamID64()
end

---------------
-- TARGET ID --
---------------

hook.Add("TTTTargetIDPlayerText", "Phantom_TTTTargetIDPlayerText", function(ent, cli, text, col, secondary_text)
    if not IsPlayer(ent) then return end
    if IsLoverHaunting(cli, ent) then
        return LANG.GetTranslation("target_haunted"), ROLE_COLORS_RADAR[ROLE_PHANTOM]
    end
end)

ROLE_IS_TARGETID_OVERRIDDEN[ROLE_PHANTOM] = function(ply, target)
    if not IsPlayer(target) then return end
    if not IsLoverHaunting(ply, target) then return end

    ------ icon,  ring,  text
    return false, false, target:GetNWBool("PhantomHaunted", false)
end

----------------
-- SCOREBOARD --
----------------

hook.Add("TTTScoreboardPlayerRole", "Phantom_TTTScoreboardPlayerRole", function(ply, client, c, roleStr)
    if IsLoverHaunting(client, ply) then
        return c, roleStr, ROLE_PHANTOM
    end
end)

hook.Add("TTTScoreboardPlayerName", "Phantom_TTTScoreboardPlayerName", function(ply, cli, text)

    if IsLoverHaunting(cli, ply) then
        return ply:Nick() .. " (" .. LANG.GetTranslation("target_haunted") .. ")"
    end
end)

ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_PHANTOM] = function(ply, target)
    if not IsPlayer(target) then return end
    if not IsLoverHaunting(ply, target) then return end

    ------ name, role
    return true, true
end

--------------
-- HAUNTING --
--------------

hook.Add("TTTSpectatorShowHUD", "Phantom_Haunting_TTTSpectatorShowHUD", function(cli, tgt)
    if not cli:IsPhantom() or not IsPlayer(tgt) then return end

    local L = LANG.GetUnsafeLanguageTable()

    local willpower_colors = {
        border = COLOR_WHITE,
        background = Color(17, 115, 135, 222),
        fill = Color(82, 226, 255, 255)
    }

    local powers = {}
    local killer_haunt_move_cost = phantom_killer_haunt_move_cost:GetInt()
    if killer_haunt_move_cost > 0 then
        table.insert(powers, {name = L.haunt_move, key = "arrows", cost = killer_haunt_move_cost, desc = string.Interp(L.haunt_move_desc, {target = tgt:Nick()})})
    end
    local killer_haunt_jump_cost = phantom_killer_haunt_jump_cost:GetInt()
    if killer_haunt_jump_cost > 0 then
        table.insert(powers, {name = L.haunt_jump, key = "space", cost = killer_haunt_jump_cost, desc = string.Interp(L.haunt_jump_desc, {target = tgt:Nick()})})
    end
    local killer_haunt_drop_cost = phantom_killer_haunt_drop_cost:GetInt()
    if killer_haunt_drop_cost > 0 then
        table.insert(powers, {name = L.haunt_drop, key = "rmb", cost = killer_haunt_drop_cost, desc = string.Interp(L.haunt_drop_desc, {target = tgt:Nick()})})
    end
    local killer_haunt_attack_cost = phantom_killer_haunt_attack_cost:GetInt()
    if killer_haunt_attack_cost > 0 then
        table.insert(powers, {name = L.haunt_attack, key = "lmb", cost = killer_haunt_attack_cost, desc = string.Interp(L.haunt_attack_desc, {target = tgt:Nick()})})
    end

    if #powers == 0 then return end

    table.sort(powers, function(a, b)
        if a.cost == b.cost then
            return a.name < b.name
        else
            return a.cost < b.cost
        end
    end)

    local current_power = cli:GetNWInt("PhantomPossessingPower", 0)
    local max_power = phantom_killer_haunt_power_max:GetInt()

    CRHUD:PaintPowersHUD(cli, powers, max_power, current_power, willpower_colors, L.haunt_title)
end)

hook.Add("TTTShouldPlayerSmoke", "Phantom_Haunting_TTTShouldPlayerSmoke", function(v, client, shouldSmoke, smokeColor, smokeParticle, smokeOffset)
    if v:GetNWBool("PhantomHaunted", false) and phantom_killer_smoke:GetBool() then
        return true
    end
end)

-----------
-- POPUP --
-----------

hook.Add("TTTRolePopupParams", "Phantom_TTTRolePopupParams", function(cli)
    if not cli:IsPhantom() then return end

    local abilities = {}
    if phantom_killer_haunt:GetBool() then
        table.insert(abilities, LANG.GetTranslation("info_popup_phantom_haunt"))
    end
    if phantom_killer_smoke:GetBool() then
        table.insert(abilities, LANG.GetTranslation("info_popup_phantom_smoke"))
    end
    if phantom_respawn:GetBool() then
        table.insert(abilities, LANG.GetTranslation("info_popup_phantom_respawn"))
    end

    local abilitiesString = table.concat(abilities, "\n")
    -- If we have something here, make sure to add a newline before it
    if #abilitiesString > 0 then
        abilitiesString = "\n" .. abilitiesString
    end

    return {
        abilities = abilitiesString
    }
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Phantom_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_PHANTOM then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local html = "The " .. ROLE_STRINGS[ROLE_PHANTOM] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose goal is to help defeat their team's enemies."

        -- Respawn
        if phantom_respawn:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>If the " .. ROLE_STRINGS[ROLE_PHANTOM] .. " is killed, they will <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>be resurrected</span> if the person that killed them then dies.</span>"

            -- Weaker each respawn
            if phantom_weaker_each_respawn:GetBool() then
                html = html .. "<span style='display: block; margin-top: 10px;'>Each time the " .. ROLE_STRINGS[ROLE_PHANTOM] .. " is killed, they will respawn with <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>half as much health</span>, down to a minimum of 1hp.</span>"
            end
        end

        -- Announce death
        if phantom_announce_death:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>When the " .. ROLE_STRINGS[ROLE_PHANTOM] .. " is killed, all " .. LANG.GetTranslation("detectives") .. " (and promoted " .. LANG.GetTranslation("detective") .. "-like roles) <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>are notified</span>.<span>"
        end

        local has_smoke = phantom_killer_smoke:GetBool()
        local has_footsteps = phantom_killer_footstep_time:GetInt() > 0
        -- Smoke and Killer footsteps
        if has_smoke or has_footsteps then
            html = html .. "<span style='display: block; margin-top: 10px;'>After the " .. ROLE_STRINGS[ROLE_PHANTOM] .. " is killed, their killer "
            if has_smoke then
                html = html .. "is enveloped in a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>shroud of smoke</span>"
            end

            if has_smoke and has_footsteps then
                html = html .. " and "
            end

            if has_footsteps then
                html = html .. "leaves behind <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>bloody footprints</span>"
            end

            html = html .. ", revealing themselves as the " .. ROLE_STRINGS[ROLE_PHANTOM] .. "'s killer to other players.</span>"
        end

        -- Possessing
        if phantom_killer_haunt:GetBool() then
            local max = phantom_killer_haunt_power_max:GetInt()
            local move_cost = phantom_killer_haunt_move_cost:GetInt()
            local jump_cost = phantom_killer_haunt_jump_cost:GetInt()
            local drop_cost = phantom_killer_haunt_drop_cost:GetInt()
            local attack_cost = phantom_killer_haunt_attack_cost:GetInt()

            -- Possessing powers
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