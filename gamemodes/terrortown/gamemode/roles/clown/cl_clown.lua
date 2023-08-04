local hook = hook
local net = net
local string = string

local StringUpper = string.upper

-------------
-- CONVARS --
-------------

local clown_hide_when_active = GetConVar("ttt_clown_hide_when_active")
local clown_use_traps_when_active = GetConVar("ttt_clown_use_traps_when_active")
local clown_show_target_icon = GetConVar("ttt_clown_show_target_icon")
local clown_heal_on_activate = GetConVar("ttt_clown_heal_on_activate")
local clown_heal_bonus = GetConVar("ttt_clown_heal_bonus")
local clown_damage_bonus = GetConVar("ttt_clown_damage_bonus")

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Clown_Translations_Initialize", function()
    -- Events
    LANG.AddToLanguage("english", "ev_clown", "The clown, {player}, went on a rampage")

    -- Win conditions
    LANG.AddToLanguage("english", "win_clown", "The {role} has murdered you all!")
    LANG.AddToLanguage("english", "ev_win_clown", "The vicious {role} won the round!")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_clown", [[You are {role}! {traitors} think you are {ajester} and you
deal no damage. However if one team would win the round instead you
become hostile, are revealed to all players and can deal damage as
normal. Be the last player standing to win.]])
end)

---------------
-- TARGET ID --
---------------

-- Show skull icon over the target's head
hook.Add("TTTTargetIDPlayerTargetIcon", "Clown_TTTTargetIDPlayerTargetIcon", function(ply, cli, showJester)
    if cli:IsClown() and cli:IsRoleActive() and clown_show_target_icon:GetBool() and not showJester then
        return "kill", true, ROLE_COLORS_SPRITE[ROLE_CLOWN], "down"
    end
end)

local function IsClownActive(ply)
    return IsPlayer(ply) and ply:IsClown() and ply:IsRoleActive()
end

local function IsClownVisible(ply)
    return IsClownActive(ply) and not clown_hide_when_active:GetBool()
end

hook.Add("TTTTargetIDPlayerRoleIcon", "Clown_TTTTargetIDPlayerRoleIcon", function(ply, cli, role, noz, color_role, hideBeggar, showJester, hideBodysnatcher)
    -- If the local client is an activated clown and the target is a jester, show the jester icon
    if IsClownActive(cli) and ply:ShouldActLikeJester() then
        local icon_overridden, _, _ = ply:IsTargetIDOverridden(cli)
        if icon_overridden then return end

        return ROLE_NONE, false, ROLE_JESTER
    end
    -- Show the clown icon if the target is an activated clown
    if IsClownVisible(ply) then
        return ROLE_CLOWN, false, ROLE_CLOWN
    end
end)

hook.Add("TTTTargetIDPlayerRing", "Clown_TTTTargetIDPlayerRing", function(ent, cli, ring_visible)
    if GetRoundState() < ROUND_ACTIVE then return end

    -- If the local client is an activated clown and the target is a jester, show the jester information
    if IsPlayer(ent) and IsClownActive(cli) and ent:ShouldActLikeJester() then
        local _, ring_overridden, _ = ent:IsTargetIDOverridden(cli)
        if ring_overridden then return end

        return true, ROLE_COLORS_RADAR[ROLE_JESTER]
    end
    -- Show the clown information and color when you look at the target
    if IsClownVisible(ent) then
        return true, ROLE_COLORS_RADAR[ROLE_CLOWN]
    end
end)

hook.Add("TTTTargetIDPlayerText", "Clown_TTTTargetIDPlayerText", function(ent, cli, text, col, secondary_text)
    if GetRoundState() < ROUND_ACTIVE then return end

    -- If the local client is an activated clown and the target is a jester, show the jester information
    if IsPlayer(ent) and IsClownActive(cli) and ent:ShouldActLikeJester() then
        local _, _, text_overridden = ent:IsTargetIDOverridden(cli)
        if text_overridden then return end

        local role_string = LANG.GetParamTranslation("target_unknown_team", { targettype = LANG.GetTranslation("jester")})
        return StringUpper(role_string), ROLE_COLORS_RADAR[ROLE_JESTER]
    end
    if IsClownVisible(ent) then
        return StringUpper(ROLE_STRINGS[ROLE_CLOWN]), ROLE_COLORS_RADAR[ROLE_CLOWN]
    end
end)

ROLE_IS_TARGETID_OVERRIDDEN[ROLE_CLOWN] = function(ply, target)
    if not IsPlayer(target) then return end

    local icon_overridden = false
    local ring_overridden = false
    local text_overridden = false
    local target_jester = IsClownActive(ply) and target:ShouldActLikeJester()
    -- We only care about whether these are overridden if the target is a tester
    if target_jester then
        icon_overridden, ring_overridden, text_overridden = target:IsTargetIDOverridden(ply)
    end
    local visible = IsClownVisible(target)

    ------ icon
    return (target_jester and not icon_overridden) or visible,
    ------- ring
            (target_jester and not ring_overridden) or visible,
    ------- text
            (target_jester and not text_overridden) or visible
end

-------------
-- SCORING --
-------------

-- Register the scoring events for the clown
hook.Add("Initialize", "Clown_Scoring_Initialize", function()
    local clown_icon = Material("icon16/emoticon_evilgrin.png")
    local Event = CLSCORE.DeclareEventDisplay
    local PT = LANG.GetParamTranslation
    Event(EVENT_CLOWNACTIVE, {
        text = function(e)
            return PT("ev_clown", {player = e.ply})
        end,
        icon = function(e)
            return clown_icon, "Killer Clown"
        end})
end)

net.Receive("TTT_ClownActivate", function()
    local ent = net.ReadEntity()
    if not IsPlayer(ent) then return end

    -- Set the traitor button availability state to match the setting
    TRAITOR_BUTTON_ROLES[ROLE_CLOWN] = clown_use_traps_when_active:GetBool()

    ent:Celebrate("clown.wav", true)

    local name = ent:Nick()
    CLSCORE:AddEvent({
        id = EVENT_CLOWNACTIVE,
        ply = name
    })
end)

----------------
-- SCOREBOARD --
----------------

hook.Add("TTTScoreboardPlayerRole", "Clown_TTTScoreboardPlayerRole", function(ply, cli, color, roleFileName)
    -- If the local client is an activated clown and the target is a jester, show the jester icon
    if IsClownActive(cli) and ply:ShouldActLikeJester() then
        local _, role_overridden = ply:IsScoreboardInfoOverridden(cli)
        if role_overridden then return end

        return ROLE_COLORS_SCOREBOARD[ROLE_JESTER], ROLE_STRINGS_SHORT[ROLE_NONE]
    end
    if IsClownVisible(ply) then
        return ROLE_COLORS_SCOREBOARD[ROLE_CLOWN], ROLE_STRINGS_SHORT[ROLE_CLOWN]
    end
end)

ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_CLOWN] = function(ply, target)
    if not IsPlayer(target) then return end

    local role_overridden = false
    local target_jester = IsClownActive(ply) and target:ShouldActLikeJester()
    -- We only care about whether these are overridden if the target is a tester
    if target_jester then
        _, role_overridden = target:IsScoreboardInfoOverridden(ply)
    end
    local visible = IsClownVisible(target)

    ------ name,  role
    return false, (target_jester and not role_overridden) or visible
end

-------------------
-- ROLE FEATURES --
-------------------

hook.Add("TTTPrepareRound", "Clown_RoleFeatures_PrepareRound", function()
    -- Disable traitor buttons for clown until they are activated (and the setting is enabled)
    TRAITOR_BUTTON_ROLES[ROLE_CLOWN] = false
end)

----------------
-- WIN CHECKS --
----------------

hook.Add("TTTScoringWinTitle", "Clown_TTTScoringWinTitle", function(wintype, wintitles, title, secondary_win_role)
    if wintype == WIN_CLOWN then
        return { txt = "hilite_win_role_singular", params = { role = StringUpper(ROLE_STRINGS[ROLE_CLOWN]) }, c = ROLE_COLORS[ROLE_JESTER] }
    end
end)

------------
-- EVENTS --
------------

hook.Add("TTTEventFinishText", "Clown_TTTEventFinishText", function(e)
    if e.win == WIN_CLOWN then
        return LANG.GetParamTranslation("ev_win_clown", { role = string.lower(ROLE_STRINGS[ROLE_CLOWN]) })
    end
end)

hook.Add("TTTEventFinishIconText", "Clown_TTTEventFinishIconText", function(e, win_string, role_string)
    if e.win == WIN_CLOWN then
        return win_string, ROLE_STRINGS[ROLE_CLOWN]
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Clown_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_CLOWN then
        -- Use this for highlighting things like "kill"
        local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
        local roleColor = GetRoleTeamColor(ROLE_TEAM_JESTER)
        local html = "The " .. ROLE_STRINGS[ROLE_CLOWN] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>jester</span> role whose goal is to survive long enough that only them and one team remains."

        html = html .. "<span style='display: block; margin-top: 10px;'>When a team would normally win, the " .. ROLE_STRINGS[ROLE_CLOWN] .. " <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>activates</span> which allows them to <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>go on a rampage</span> and win by surprise.</span>"

        if clown_damage_bonus:GetFloat() > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>Once the " .. ROLE_STRINGS[ROLE_CLOWN] .. " has activated, they <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>do more damage</span>.</span>"
        end

        -- Target ID
        if clown_show_target_icon:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>Their targets can be identified by the <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>KILL</span> icon floating over their heads.</span>"
        end

        -- Hide When Active
        if clown_hide_when_active:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>When activated they are also <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>hidden</span> from players who could normally <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>see them through walls</span>.</span>"
        end

        -- Shop
        html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_CLOWN] .. " has access to a <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>weapon shop</span>"
        if GetConVar("ttt_clown_shop_active_only"):GetBool() then
            html = html .. ", but only <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>after they activate</span>"
        elseif GetConVar("ttt_clown_shop_delay"):GetBool() then
            html = html .. ", but they are only given their purchased weapons <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>after they activate</span>"
        end
        html = html .. ".</span>"

        -- Traitor Traps
        if clown_use_traps_when_active:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'><span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>Traitor traps</span> also become available when <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>the " .. ROLE_STRINGS[ROLE_CLOWN] .." is activated</span>.</span>"
        end

        if clown_heal_on_activate:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>When the " .. ROLE_STRINGS[ROLE_CLOWN] .." is activated, they will also be <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>healed to maximum health</span>"
            if clown_heal_bonus:GetInt() > 0 then
                html = html .. " and even <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>given a little extra</span>"
            end
            html = html .. ".</span>"
        end

        return html
    end
end)