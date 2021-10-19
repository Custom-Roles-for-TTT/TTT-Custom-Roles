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
        local html = "The " .. ROLE_STRINGS[ROLE_PHANTOM] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose goal is to resurrect dead players."

        return html
    end
end)