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

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Phantom_Translations_Initialize", function()
    -- Target ID
    LANG.AddToLanguage("english", "target_haunted", "HAUNTED BY PHANTOM")

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
    if not cli:IsPhantom() then return end

    local L = LANG.GetUnsafeLanguageTable()
    local willpower_colors = {
        border = COLOR_WHITE,
        background = Color(17, 115, 135, 222),
        fill = Color(82, 226, 255, 255)
    }
    local powers = {
        [L.haunt_move] = phantom_killer_haunt_move_cost:GetInt(),
        [L.haunt_jump] = phantom_killer_haunt_jump_cost:GetInt(),
        [L.haunt_drop] = phantom_killer_haunt_drop_cost:GetInt(),
        [L.haunt_attack] = phantom_killer_haunt_attack_cost:GetInt()
    }
    local max_power = phantom_killer_haunt_power_max:GetInt()
    local current_power = cli:GetNWInt("PhantomPossessingPower", 0)

    CRHUD:PaintPowersHUD(powers, max_power, current_power, willpower_colors, L.haunt_title)
end)

hook.Add("TTTShouldPlayerSmoke", "Phantom_Haunting_TTTShouldPlayerSmoke", function(v, client, shouldSmoke, smokeColor, smokeParticle, smokeOffset)
    if v:GetNWBool("PhantomHaunted", false) and phantom_killer_smoke:GetBool() then
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
        if phantom_killer_smoke:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>Before the " .. ROLE_STRINGS[ROLE_PHANTOM] .. " is respawned, their killer is enveloped in a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>shroud of smoke</span>, revealing themselves as the " .. ROLE_STRINGS[ROLE_PHANTOM] .. "'s killer to other players.</span>"
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