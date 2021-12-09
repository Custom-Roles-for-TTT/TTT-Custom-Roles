local hook = hook
local IsPlayer = IsPlayer
local net = net
local string = string

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

-- Show "KILL" icon over the target's head
hook.Add("TTTTargetIDPlayerKillIcon", "Clown_TTTTargetIDPlayerKillIcon", function(ply, cli, showKillIcon, showJester)
    if cli:IsClown() and cli:IsRoleActive() and GetGlobalBool("ttt_clown_show_target_icon", false) and not showJester then
        return true
    end
end)

local function IsClownVisible(ply)
    return IsPlayer(ply) and ply:IsClown() and ply:IsRoleActive() and not GetGlobalBool("ttt_clown_hide_when_active", false)
end

-- Show the clown icon if the player is an activated clown
hook.Add("TTTTargetIDPlayerRoleIcon", "Clown_TTTTargetIDPlayerRoleIcon", function(ply, cli, role, noz, color_role, hideBeggar, showJester, hideBodysnatcher)
    if IsClownVisible(ply) then
        return ROLE_CLOWN, false, ROLE_CLOWN
    end
end)

-- Show the clown information and color when you look at the player
hook.Add("TTTTargetIDPlayerRing", "Clown_TTTTargetIDPlayerRing", function(ent, client, ring_visible)
    if GetRoundState() < ROUND_ACTIVE then return end

    if IsClownVisible(ent) then
        return true, ROLE_COLORS_RADAR[ROLE_CLOWN]
    end
end)

hook.Add("TTTTargetIDPlayerText", "Clown_TTTTargetIDPlayerText", function(ent, client, text, col, secondary_text)
    if GetRoundState() < ROUND_ACTIVE then return end

    if IsClownVisible(ent) then
        return string.upper(ROLE_STRINGS[ROLE_CLOWN]), ROLE_COLORS_RADAR[ROLE_CLOWN]
    end
end)

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
    TRAITOR_BUTTON_ROLES[ROLE_CLOWN] = GetGlobalBool("ttt_clown_use_traps_when_active", false)

    ent:Celebrate("clown.wav", true)

    local name = ent:Nick()
    CLSCORE:AddEvent({
        id = EVENT_CLOWNACTIVE,
        ply = name
    })
end)

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
        return { txt = "hilite_win_role_singular", params = { role = string.upper(ROLE_STRINGS[ROLE_CLOWN]) }, c = ROLE_COLORS[ROLE_JESTER] }
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

        -- Target ID
        if GetGlobalBool("ttt_clown_show_target_icon", false) then
            html = html .. "<span style='display: block; margin-top: 10px;'>Their targets can be identified by the <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>KILL</span> icon floating over their heads.</span>"
        end

        -- Hide When Active
        if GetGlobalBool("ttt_clown_hide_when_active", false) then
            html = html .. "<span style='display: block; margin-top: 10px;'>When activated they are also <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>hidden</span> from players who could normally <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>see them through walls</span>.</span>"
        end

        -- Shop
        html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_CLOWN] .. " has access to a <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>weapon shop</span>"
        if GetGlobalBool("ttt_clown_shop_active_only", true) then
            html = html .. ", but only <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>after they activate</span>"
        elseif GetGlobalBool("ttt_clown_shop_delay", false) then
            html = html .. ", but they are only given their purchased weapons <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>after they activate</span>"
        end
        html = html .. ".</span>"

        -- Traitor Traps
        if GetGlobalBool("ttt_clown_use_traps_when_active", false) then
            html = html .. "<span style='display: block; margin-top: 10px;'><span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>Traitor traps</span> also become available when <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>the " .. ROLE_STRINGS[ROLE_CLOWN] .." is activated</span>.</span>"
        end

        return html
    end
end)