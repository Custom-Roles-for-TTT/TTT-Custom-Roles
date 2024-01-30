local hook = hook

local client

-------------
-- CONVARS --
-------------

local arsonist_douse_time = GetConVar("ttt_arsonist_douse_time")
local arsonist_douse_notify_delay_min = GetConVar("ttt_arsonist_douse_notify_delay_min")
local arsonist_douse_notify_delay_max = GetConVar("ttt_arsonist_douse_notify_delay_max")

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Arsonist_Translations_Initialize", function()
    -- Weapons
    LANG.AddToLanguage("english", "arsonistigniter_help_pri", "Press {primaryfire} to ignite doused players.")
    LANG.AddToLanguage("english", "arsonistigniter_help_sec", "Can only be used once")

    -- Body Search
    LANG.AddToLanguage("english", "arsonist_body_doused", "They were doused {time} ago by {anarsonist}!")

    -- Events
    LANG.AddToLanguage("english", "ev_arsonignite", "Everyone was ignited by the {arsonist}")

    -- Win conditions
    LANG.AddToLanguage("english", "win_arsonist", "The {role} has burnt everyone to a crisp!")
    LANG.AddToLanguage("english", "ev_win_arsonist", "The blazing {role} has won the round!")

    -- HUD
    LANG.AddToLanguage("english", "arsdouse_dousing", "DOUSING {target}")
    LANG.AddToLanguage("english", "arsdouse_dousing_corpse", "DOUSING {target}'s CORPSE")
    LANG.AddToLanguage("english", "arsdouse_doused", "DOUSED")
    LANG.AddToLanguage("english", "arsdouse_failed", "DOUSING FAILED")
    LANG.AddToLanguage("english", "arsonist_hud", "Dousing complete. Igniter active.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_arsonist", [[You are {role}! Get close to other players
to douse them in gasoline.

Once every player has been doused you can use your igniter to set them
all ablaze. Be the last person standing to win!]])
end)

---------------
-- TARGET ID --
---------------

-- Show douse icon over all undoused players
hook.Add("TTTTargetIDPlayerTargetIcon", "Arsonist_TTTTargetIDPlayerTargetIcon", function(ply, cli, showJester)
    if cli:IsArsonist() and not cli:GetNWBool("TTTArsonistDouseComplete", false) and ply:GetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED) < ARSONIST_DOUSED then
        return "douse", false, ROLE_COLORS_SPRITE[ROLE_ARSONIST], "down"
    end
end)

-- Show "DOUSED" label on players who have been doused
hook.Add("TTTTargetIDPlayerText", "Arsonist_TTTTargetIDPlayerText", function(ent, cli, text, col, secondaryText)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not cli:IsArsonist() then return end

    -- If this is a player, check their doused state
    if IsPlayer(ent) then
        local state = ent:GetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED)
        if state ~= ARSONIST_DOUSED then return end
    -- Otherise if this is a ragdoll we just need to check the flag on it directly
    elseif IsRagdoll(ent) and not ent:GetNWBool("TTTArsonistDoused", false) then
        return
    end

    local T = LANG.GetTranslation
    if text == nil then
        return T("arsdouse_doused"), ROLE_COLORS[ROLE_TRAITOR]
    end
    return text, col, T("arsdouse_doused"), ROLE_COLORS[ROLE_TRAITOR]
end)

-- NOTE: ROLE_IS_TARGETID_OVERRIDDEN is not required since only secondary text is being changed and that is not tracked there

----------------
-- SCOREBOARD --
----------------

-- Show "DOUSED" label on the players who have been doused
hook.Add("TTTScoreboardPlayerName", "Arsonist_TTTScoreboardPlayerName", function(ply, cli, text)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not cli:IsArsonist() then return end

    local state = ply:GetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED)
    if state ~= ARSONIST_DOUSED then return end

    local T = LANG.GetTranslation
    return text .. " (" .. T("arsdouse_doused") .. ")"
end)

ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_ARSONIST] = function(ply, target)
    if not ply:IsArsonist() then return end
    if not IsPlayer(target) then return end

    local state = target:GetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED)
    if state ~= ARSONIST_DOUSED then return end

    ------ name, role
    return true, false
end

--------------------
-- BODY SEARCHING --
--------------------

hook.Add("TTTBodySearchPopulate", "Arsonist_TTTBodySearchPopulate", function(search, raw)
    local rag = Entity(raw.eidx)
    if not IsValid(rag) then return end

    local ply = CORPSE.GetPlayer(rag)
    if not IsPlayer(ply) then return end

    local state = ply:GetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED)
    if state ~= ARSONIST_DOUSED then return end

    local douseTime = ply:GetNWInt("TTTArsonistDouseTime", -1)
    if douseTime < 0 then return end

    local time = util.SimpleTime(CurTime() - douseTime, "%02i:%02i")
    local message = LANG.GetParamTranslation("arsonist_body_doused", {time = time, anarsonist = ROLE_STRINGS_EXT[ROLE_ARSONIST]})

    local roleString = ROLE_STRINGS_SHORT[ROLE_ARSONIST]
    local img = util.GetRoleIconPath(roleString, "icon", "vtf")
    search["arsonistdouse"] = {
        text = message,
        img = img,
        color = ROLE_COLORS[ROLE_ARSONIST],
        p = 3
    }
end)

-------------
-- SCORING --
-------------

-- Register the scoring events for the arsonist
hook.Add("Initialize", "Arsonist_Scoring_Initialize", function()
    local arsonist_icon = Material("icon16/asterisk_orange.png")
    local Event = CLSCORE.DeclareEventDisplay
    local PT = LANG.GetParamTranslation

    Event(EVENT_ARSONISTIGNITED, {
        text = function(e)
            return PT("ev_arsonignite", {arsonist = ROLE_STRINGS[ROLE_ARSONIST]})
        end,
        icon = function(e)
            return arsonist_icon, "Ignited"
        end})
end)

net.Receive("TTT_ArsonistIgnited", function(len)
    CLSCORE:AddEvent({
        id = EVENT_ARSONISTIGNITED
    })
end)

----------------
-- WIN CHECKS --
----------------

hook.Add("TTTScoringWinTitle", "Arsonist_TTTScoringWinTitle", function(wintype, wintitles, title, secondary_win_role)
    if wintype == WIN_ARSONIST then
        return { txt = "hilite_win_role_singular", params = { role = string.upper(ROLE_STRINGS[ROLE_ARSONIST]) }, c = ROLE_COLORS[ROLE_ARSONIST] }
    end
end)

------------
-- EVENTS --
------------

hook.Add("TTTEventFinishText", "Arsonist_TTTEventFinishText", function(e)
    if e.win == WIN_ARSONIST then
        return LANG.GetParamTranslation("ev_win_arsonist", { role = string.lower(ROLE_STRINGS[ROLE_ARSONIST]) })
    end
end)

hook.Add("TTTEventFinishIconText", "Arsonist_TTTEventFinishIconText", function(e, win_string, role_string)
    if e.win == WIN_ARSONIST then
        return win_string, ROLE_STRINGS[ROLE_ARSONIST]
    end
end)

-----------------
-- DOUSING HUD --
-----------------

hook.Add("HUDPaint", "Arsonist_HUDPaint", function()
    if not client then
        client = LocalPlayer()
    end

    if not IsValid(client) or client:IsSpec() or GetRoundState() ~= ROUND_ACTIVE then return end
    if not client:IsArsonist() then return end

    local target_sid64 = client:GetNWString("TTTArsonistDouseTarget", "")
    if not target_sid64 or #target_sid64 == 0 then return end

    local target = player.GetBySteamID64(target_sid64)
    if not IsPlayer(target) then return end

    local state = target:GetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED)
    if state == ARSONIST_UNDOUSED then return end

    local douse_time = arsonist_douse_time:GetInt()
    local end_time = client:GetNWFloat("TTTArsonistDouseStartTime", -1) + douse_time

    local x = ScrW() / 2.0
    local y = ScrH() / 2.0

    y = y + (y / 3)

    local w = 300
    local T = LANG.GetTranslation
    local PT = LANG.GetParamTranslation

    if state == ARSONIST_DOUSING_LOST then
        local color = Color(200 + math.sin(CurTime() * 32) * 50, 0, 0, 155)
        CRHUD:PaintProgressBar(x, y, w, color, T("arsdouse_failed"), 1)
    elseif state >= ARSONIST_DOUSING then
        if end_time < 0 then return end

        local placeholder = "arsdouse_dousing"
        if not target:Alive() or target:IsSpec() then
            placeholder = "arsdouse_dousing_corpse"
        end
        local text = PT(placeholder, {target = target:Nick()})
        local color = Color(0, 255, 0, 155)
        if state == ARSONIST_DOUSING_LOSING then
            color = Color(255, 255, 0, 155)
        end

        local progress = math.min(1, 1 - ((end_time - CurTime()) / douse_time))
        CRHUD:PaintProgressBar(x, y, w, color, text, progress)
    end
end)

hook.Add("TTTHUDInfoPaint", "Arsonist_TTTHUDInfoPaint", function(cli, label_left, label_top, active_labels)
    if GetConVar("ttt_arsonist_early_ignite"):GetBool() then return end

    local hide_role = false
    if ConVarExists("ttt_hide_role") then
        hide_role = GetConVar("ttt_hide_role"):GetBool()
    end

    if hide_role then return end

    if cli:IsArsonist() and cli:GetNWBool("TTTArsonistDouseComplete", false) then
        surface.SetFont("TabLarge")
        surface.SetTextColor(255, 255, 255, 230)

        local text = LANG.GetTranslation("arsonist_hud")
        local _, h = surface.GetTextSize(text)

        -- Move this up based on how many other labels here are
        label_top = label_top + (20 * #active_labels)

        surface.SetTextPos(label_left, ScrH() - label_top - h)
        surface.DrawText(text)

        -- Track that the label was added so others can position accurately
        table.insert(active_labels, "arsonist")
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Arsonist_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_ARSONIST then
        local roleColor = GetRoleTeamColor(ROLE_TEAM_INDEPENDENT)
        local html = "The " .. ROLE_STRINGS[ROLE_ARSONIST] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independent</span> role whose goal is to be the last player standing."

        -- Use this for highlighting things like "burn"
        roleColor = ROLE_COLORS[ROLE_TRAITOR]

        html = html .. "<span style='display: block; margin-top: 10px;'>To help accomplish this, they can <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>douse players in gasoline</span> by standing near them.</span>"

        local early_ignite = GetConVar("ttt_arsonist_early_ignite"):GetBool()
        if early_ignite then
            html = html .. "<span style='display: block; margin-top: 10px;'>They can use their igniter to <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>burn</span> all the doused players at any time. The igniter can only be used once, though, so plan accordingly.</span>"
        else
            html = html .. "<span style='display: block; margin-top: 10px;'>Once every player has been doused, they can use their igniter to <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>burn</span> all the doused players.</span>"
        end
        -- Show a warning about the notification delay if its enabled
        local delay_min = arsonist_douse_notify_delay_min:GetInt()
        local delay_max = arsonist_douse_notify_delay_max:GetInt()
        if delay_min > delay_max then
            delay_min = delay_max
        end

        if delay_min > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>Be careful though! Players <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>are notified when they are doused</span> after a short delay. Be sure to be sneaky or blend in with other players to disguise that you are the " .. ROLE_STRINGS[ROLE_ARSONIST] .. ".</span>"
        end

        html = html .. "<span style='display: block; margin-top: 10px;'>You can also <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>douse player corpses</span>"
        if not early_ignite then
            html = html .. ", but they are not required to activate your igniter"
        end
        html = html .. ".</span>"

        return html
    end
end)