local hook = hook
local math = math
local net = net
local string = string
local surface = surface
local table = table
local util = util

local MathMax = math.max
local MathSin = math.sin
local MathCos = math.cos
local MathPi = math.pi
local MathRand = math.Rand
local AddHook = hook.Add
local StringUpper = string.upper

-------------
-- CONVARS --
-------------

local shadow_start_timer = GetConVar("ttt_shadow_start_timer")
local shadow_buffer_timer = GetConVar("ttt_shadow_buffer_timer")
local shadow_delay_timer_min = GetConVar("ttt_shadow_delay_timer_min")
local shadow_delay_timer_max = GetConVar("ttt_shadow_delay_timer_max")
local shadow_alive_radius = GetConVar("ttt_shadow_alive_radius")
local shadow_dead_radius = GetConVar("ttt_shadow_dead_radius")
local shadow_target_buff = GetConVar("ttt_shadow_target_buff")
local shadow_target_buff_delay = GetConVar("ttt_shadow_target_buff_delay")
local shadow_soul_link = GetConVar("ttt_shadow_soul_link")
local shadow_weaken_health_to = GetConVar("ttt_shadow_weaken_health_to")
local shadow_weaken_health_to_death = GetConVar("ttt_shadow_weaken_health_to_death")
local shadow_target_notify_mode = GetConVar("ttt_shadow_target_notify_mode")
local shadow_speed_mult = GetConVar("ttt_shadow_speed_mult")
local shadow_sprint_recovery = GetConVar("ttt_shadow_sprint_recovery")
local shadow_failure_mode = GetConVar("ttt_shadow_failure_mode")
local shadow_target_buff_show_progress = GetConVar("ttt_shadow_target_buff_show_progress")
local hide_role = GetConVar("ttt_hide_role")

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "Shadow_Translations_Initialize", function()
    -- HUD
    LANG.AddToLanguage("english", "shadow_delay_target", "Target identified in: {time}")
    LANG.AddToLanguage("english", "shadow_find_target", "FIND YOUR TARGET - {time}")
    LANG.AddToLanguage("english", "shadow_return_target", "RETURN TO YOUR TARGET - {time}")
    LANG.AddToLanguage("english", "shadow_buff_progress", "BUFF ACTIVATION - {time}")
    LANG.AddToLanguage("english", "shadow_buff_hud_active", "Target {buff} active")
    LANG.AddToLanguage("english", "shadow_buff_hud_time", "Time until target {buff} active: {time}")
    LANG.AddToLanguage("english", "shadow_buff_1", "health regen")
    LANG.AddToLanguage("english", "shadow_buff_2", "respawn")
    LANG.AddToLanguage("english", "shadow_buff_3", "damage bonus")
    LANG.AddToLanguage("english", "shadow_buff_4", "team join")
    LANG.AddToLanguage("english", "shadow_buff_5", "role steal")

    -- Target ID
    LANG.AddToLanguage("english", "shadow_target", "YOUR TARGET")

    -- Win conditions
    LANG.AddToLanguage("english", "ev_win_shadow", "The {role} stayed close to their target and also won the round!")

    -- Scoreboard
    LANG.AddToLanguage("english", "score_shadow_following", "Following")

    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_shadow", "Needs to stay close to their target or there will be consequences.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_shadow", [[You are {role}! Find your target quickly
and stay close to them. If you don't, you will be punished.

Survive until the end of the round to win.]])
end)

----------------------
-- HELPER FUNCTIONS --
----------------------

-- Apparently GetRagdollEntity is a shared method but it doesn't seem to work on the client
local function ClientGetRagdollEntity(sid64)
    local bodies = ents.FindByClass("prop_ragdoll")
    for _, v in pairs(bodies) do
        local body = CORPSE.GetPlayer(v)
        if IsPlayer(body) and body:SteamID64() == sid64 then
            return v
        end
    end
    return nil
end

-------------
-- SCORING --
-------------

-- Track when the shadow wins
local shadow_wins = false
net.Receive("TTT_UpdateShadowWins", function()
    -- Log the win event with an offset to force it to the end
    shadow_wins = true
    CLSCORE:AddEvent({
        id = EVENT_FINISH,
        win = WIN_SHADOW
    }, 1)
end)

local function ResetShadowWin()
    shadow_wins = false
end
net.Receive("TTT_ResetShadowWins", ResetShadowWin)
hook.Add("TTTPrepareRound", "Shadow_WinTracking_TTTPrepareRound", ResetShadowWin)
hook.Add("TTTBeginRound", "Shadow_WinTracking_TTTBeginRound", ResetShadowWin)

----------------
-- WIN CHECKS --
----------------

AddHook("TTTScoringSecondaryWins", "Shadow_TTTScoringSecondaryWins", function(wintype, secondary_wins)
    if shadow_wins then
        table.insert(secondary_wins, ROLE_SHADOW)
    end
end)

------------
-- EVENTS --
------------

AddHook("TTTEventFinishText", "Shadow_TTTEventFinishText", function(e)
    if e.win == WIN_SHADOW then
        return LANG.GetParamTranslation("ev_win_shadow", { role = string.lower(ROLE_STRINGS[ROLE_SHADOW]) })
    end
end)

AddHook("TTTEventFinishIconText", "Shadow_TTTEventFinishIconText", function(e, win_string, role_string)
    if e.win == WIN_SHADOW then
        return "ev_win_icon_also", ROLE_STRINGS[ROLE_SHADOW]
    end
end)

-------------
-- SCORING --
-------------

AddHook("TTTScoringSummaryRender", "Shadow_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
    if not IsPlayer(ply) then return end

    if ply:IsShadow() then
        local targetSID = ply:GetNWString("ShadowTarget", "")
        if #targetSID == 0 then return end

        local target = player.GetBySteamID64(targetSID)
        if not IsPlayer(target) then return end

        return roleFileName, groupingRole, roleColor, name, target:Nick(), LANG.GetTranslation("score_shadow_following")
    end
end)

---------------
-- TARGET ID --
---------------

-- Show shadow target icon over the shadow's target
hook.Add("TTTTargetIDPlayerTargetIcon", "Shadow_TTTTargetIDPlayerTargetIcon", function(ply, cli, showJester)
    if cli:IsShadow() and ply:SteamID64() == cli:GetNWString("ShadowTarget", "") then
        local iconColor = ROLE_COLORS_SPRITE[ROLE_TRAITOR]
        if cli:GetPos():Distance(ply:GetPos()) <= shadow_alive_radius:GetFloat() * UNITS_PER_METER then
            iconColor = ROLE_COLORS_SPRITE[ROLE_INNOCENT]
        end
        return "shadow", true, iconColor, "up"
    end
end)

AddHook("TTTTargetIDPlayerRoleIcon", "Shadow_TTTTargetIDPlayerRoleIcon", function(ply, cli, role, noz, colorRole, hideBeggar, showJester, hideBodysnatcher)
    if shadow_target_notify_mode:GetInt() == SHADOW_NOTIFY_IDENTIFY and ply:IsActiveShadow() and ply:GetNWString("ShadowTarget", "") == cli:SteamID64() then
        return ROLE_SHADOW, true
    end
end)

AddHook("TTTTargetIDPlayerRing", "Shadow_TTTTargetIDPlayerRing", function(ent, cli, ringVisible)
    if not IsPlayer(ent) then return end

    if shadow_target_notify_mode:GetInt() == SHADOW_NOTIFY_IDENTIFY and ent:IsActiveShadow() and ent:GetNWString("ShadowTarget", "") == cli:SteamID64() then
        return true, ROLE_COLORS_RADAR[ROLE_SHADOW]
    end
end)

AddHook("TTTTargetIDPlayerText", "Shadow_TTTTargetIDPlayerText", function(ent, cli, text, clr, secondaryText)
    if not IsPlayer(ent) then return end

    if cli:IsActiveShadow() and ent:SteamID64() == cli:GetNWString("ShadowTarget", "") then
        if text == nil then
            return LANG.GetTranslation("shadow_target"), ROLE_COLORS_RADAR[ROLE_SHADOW]
        end
        return text, clr, LANG.GetTranslation("shadow_target"), ROLE_COLORS_RADAR[ROLE_SHADOW]
    elseif shadow_target_notify_mode:GetInt() == SHADOW_NOTIFY_IDENTIFY and ent:IsActiveShadow() and ent:GetNWString("ShadowTarget", "") == cli:SteamID64() then
        return StringUpper(ROLE_STRINGS[ROLE_SHADOW]), ROLE_COLORS_RADAR[ROLE_SHADOW]
    end
end)

----------------
-- SCOREBOARD --
----------------

AddHook("TTTScoreboardPlayerRole", "Shadow_TTTScoreboardPlayerRole", function(ply, cli, c, roleStr)
    if cli:IsActiveShadow() and ply:SteamID64() == cli:GetNWString("ShadowTarget", "") then
        return c, roleStr, ROLE_SHADOW
    elseif shadow_target_notify_mode:GetInt() == SHADOW_NOTIFY_IDENTIFY and ply:IsShadow() and ply:GetNWString("ShadowTarget", "") == cli:SteamID64() then
        return ROLE_COLORS_SCOREBOARD[ROLE_SHADOW], ROLE_STRINGS_SHORT[ROLE_SHADOW]
    end
end)

AddHook("TTTScoreboardPlayerName", "Shadow_TTTScoreboardPlayerName", function(ply, cli, text)
    if cli:IsActiveShadow() and ply:SteamID64() == cli:GetNWString("ShadowTarget", "") then
        return ply:Nick() .. " (" .. LANG.GetTranslation("shadow_target") .. ")"
    end
end)

------------------
-- HIGHLIGHTING --
------------------

local vision_enabled = false
local client = nil

local function EnableShadowTargetHighlights()
    AddHook("PreDrawHalos", "Shadow_Highlight_PreDrawHalos", function()
        local sid64 = client:GetNWString("ShadowTarget", "")
        if #sid64 == 0 then return end

        local target = player.GetBySteamID64(sid64)
        if not IsValid(target) then return end

        local ent
        local r = shadow_alive_radius:GetFloat() * UNITS_PER_METER
        if target:IsActive() then
            ent = target
        else
            ent = ClientGetRagdollEntity(sid64)
            r = shadow_dead_radius:GetFloat() * UNITS_PER_METER
        end
        if not IsValid(ent) then return end

        local color = ROLE_COLORS[ROLE_TRAITOR]
        if client:GetPos():Distance(ent:GetPos()) <= r then
            color = ROLE_COLORS[ROLE_INNOCENT]
        end

        halo.Add({ent}, color, 1, 1, 1, true, true)
    end)
end

AddHook("TTTUpdateRoleState", "Shadow_Highlight_TTTUpdateRoleState", function()
    client = client or LocalPlayer()

    -- Disable highlights on role change
    if vision_enabled then
        hook.Remove("PreDrawHalos", "Shadow_Highlight_PreDrawHalos")
        vision_enabled = false
    end
end)

-- Handle enabling and disabling of highlighting
AddHook("Think", "Shadow_Highlight_Think", function()
    if not IsPlayer(client) then return end

    if client:IsActiveShadow() and client:Alive() then
        if not vision_enabled then
            EnableShadowTargetHighlights()
            vision_enabled = true
        end
    elseif vision_enabled then
        hook.Remove("PreDrawHalos", "Shadow_Highlight_PreDrawHalos")
        vision_enabled = false
    end
end)

---------------
-- PARTICLES --
---------------

local function DrawRadius(ply, ent, r)
    if not ent.RadiusEmitter then ent.RadiusEmitter = ParticleEmitter(ent:GetPos()) end
    if not ent.RadiusNextPart then ent.RadiusNextPart = CurTime() end
    if not ent.RadiusDir then ent.RadiusDir = 0 end
    local pos = ent:GetPos() + Vector(0, 0, 30)

    if ent.RadiusNextPart < CurTime() and ply:GetPos():Distance(pos) <= 3000 then
        for _ = 1, 24 do
            ent.RadiusEmitter:SetPos(pos)
            ent.RadiusNextPart = CurTime() + 0.02
            ent.RadiusDir = ent.RadiusDir + MathPi / 12
            local vec = Vector(MathSin(ent.RadiusDir) * r, MathCos(ent.RadiusDir) * r, 10)
            local particle = ent.RadiusEmitter:Add("particle/wisp.vmt", ent:GetPos() + vec)
            particle:SetVelocity(Vector(0, 0, 80))
            particle:SetDieTime(0.5)
            particle:SetStartAlpha(200)
            particle:SetEndAlpha(0)
            particle:SetStartSize(3)
            particle:SetEndSize(2)
            particle:SetRoll(MathRand(0, MathPi))
            particle:SetRollDelta(0)
            local color = ROLE_COLORS[ROLE_TRAITOR]
            if ply:GetPos():Distance(ent:GetPos()) <= r then
                color = ROLE_COLORS[ROLE_INNOCENT]
            end
            particle:SetColor(color.r, color.g, color.b)
        end
        ent.RadiusDir = ent.RadiusDir + 0.02
    end
end

local function RemoveRadius(ent)
    if ent.RadiusEmitter then
        ent.RadiusEmitter:Finish()
        ent.RadiusEmitter = nil
        ent.RadiusDir = nil
        ent.RadiusNextPart = nil
    end
end

local function DrawLink(ply, ent)
    if not ent.LinkEmitter then ent.LinkEmitter = ParticleEmitter(ent:GetPos()) end
    if not ent.LinkNextPart then ent.LinkNextPart = CurTime() end
    if not ent.LinkOffset then ent.LinkOffset = 0 end
    local startPos = ply:GetPos() + Vector(0, 0, 30)
    local endPos = ent:GetPos() + Vector(0, 0, 30)
    local dir = endPos - startPos
    dir = dir:GetNormalized() * 50
    if ent.LinkNextPart < CurTime() then
        local pos = startPos + (dir * ent.LinkOffset)
        while startPos:Distance(pos) <= 3000 and startPos:Distance(pos) <= startPos:Distance(endPos) do
            ent.LinkEmitter:SetPos(pos)
            ent.LinkNextPart = CurTime() + 0.02
            local particle = ent.LinkEmitter:Add("particle/wisp.vmt", pos)
            particle:SetVelocity(vector_origin)
            particle:SetDieTime(0.25)
            particle:SetStartAlpha(200)
            particle:SetEndAlpha(0)
            particle:SetStartSize(3)
            particle:SetEndSize(2)
            particle:SetRoll(MathRand(0, MathPi))
            particle:SetRollDelta(0)
            local color = ROLE_COLORS[ROLE_TRAITOR]
            particle:SetColor(color.r, color.g, color.b)
            pos:Add(dir)
        end
        ent.LinkOffset = ent.LinkOffset + 0.04
        if ent.LinkOffset > 1 then
            ent.LinkOffset = 0
        end
    end
end

local function RemoveLink(ent)
    if ent.LinkEmitter then
        ent.LinkEmitter:Finish()
        ent.LinkEmitter = nil
        ent.LinkNextPart = nil
        ent.LinkOffset = nil
    end
end

local targetPlayer = nil
local targetBody = nil

local function TargetCleanup()
    if IsValid(targetPlayer) then
        RemoveRadius(targetPlayer)
        RemoveLink(targetPlayer)
    end
    if IsValid(targetBody) then
        RemoveRadius(targetBody)
        RemoveLink(targetBody)
    end
    targetPlayer = nil
    targetBody = nil
end

AddHook("Think", "Shadow_Think", function()
    if not IsPlayer(client) then
        client = LocalPlayer()
    end

    if client:IsActiveShadow() then
        targetPlayer = targetPlayer or player.GetBySteamID64(client:GetNWString("ShadowTarget", ""))
        if IsValid(targetPlayer) then
            if targetPlayer:IsActive() then
                local alive_radius = shadow_alive_radius:GetFloat() * UNITS_PER_METER
                DrawRadius(client, targetPlayer, alive_radius)
                if client:GetPos():Distance(targetPlayer:GetPos()) > alive_radius then
                    DrawLink(client, targetPlayer)
                end
            else
                RemoveRadius(targetPlayer)
                RemoveLink(targetPlayer)
                targetBody = targetBody or ClientGetRagdollEntity(client:GetNWString("ShadowTarget", ""))
                if IsValid(targetBody) then
                    local dead_radius = shadow_dead_radius:GetFloat() * UNITS_PER_METER
                    DrawRadius(client, targetBody, dead_radius)
                    if client:GetPos():Distance(targetBody:GetPos()) > dead_radius then
                        DrawLink(client, targetBody)
                    end
                end
            end
        end
    else
        TargetCleanup()
    end
end)

AddHook("TTTEndRound", "Shadow_ClearCache_TTTEndRound", function()
    TargetCleanup()
end)

---------
-- HUD --
---------

AddHook("TTTHUDInfoPaint", "Shadow_Delay_TTTHUDInfoPaint", function(cli, label_left, label_top, active_labels)
    if hide_role:GetBool() then return end

    if cli:IsActiveShadow() and not cli:IsRoleActive() then
        local target = cli:GetNWString("ShadowTarget", "")
        if target and #target > 0 then return end

        surface.SetFont("TabLarge")
        surface.SetTextColor(255, 255, 255, 230)

        local remaining = MathMax(0, cli:GetNWFloat("ShadowTimer", -1) - CurTime())
        local text = LANG.GetParamTranslation("shadow_delay_target", { time = util.SimpleTime(remaining, "%02i:%02i") })
        local _, h = surface.GetTextSize(text)

        -- Move this up based on how many other labels here are
        label_top = label_top + (20 * #active_labels)

        surface.SetTextPos(label_left, ScrH() - label_top - h)
        surface.DrawText(text)

        -- Track that the label was added so others can position accurately
        table.insert(active_labels, "shadow")
    end
end)

AddHook("HUDPaint", "Shadow_HUDPaint", function()
    if not IsPlayer(client) then
        client = LocalPlayer()
    end

    if not IsValid(client) or client:IsSpec() or GetRoundState() ~= ROUND_ACTIVE then return end

    if client:IsActiveShadow() then
        local targetSid64 = client:GetNWString("ShadowTarget", "")
        if not targetSid64 or #targetSid64 == 0 then return end

        local t = client:GetNWFloat("ShadowTimer", -1)
        local bt = client:GetNWFloat("ShadowBuffTimer", -1)

        local PT = LANG.GetParamTranslation
        local remaining = nil
        local message = nil
        local total = nil
        local color = nil

        if t > 0 or t == SHADOW_FORCED_PROGRESS_BAR then
            remaining = MathMax(0, t - CurTime())
            if client:IsRoleActive() then
                message = PT("shadow_return_target", { time = util.SimpleTime(remaining, "%02i:%02i") })
                total = shadow_buffer_timer:GetInt()
            else
                message = PT("shadow_find_target", { time = util.SimpleTime(remaining, "%02i:%02i") })
                total = shadow_start_timer:GetInt()
            end
            color = Color(200 + MathSin(CurTime() * 32) * 50, 0, 0, 155)
        elseif shadow_target_buff_show_progress:GetBool() and bt > 0 then
            local target = player.GetBySteamID64(targetSid64)
            if not IsPlayer(target) then return end
            -- If their target player has already had their buff and can't get it again, don't bother showing the HUD info
            if target:GetNWBool("ShadowBuffDepleted", false) then return end

            remaining = MathMax(0, bt - CurTime())
            if remaining <= 0 then return end

            message = PT("shadow_buff_progress", { time = util.SimpleTime(remaining, "%02i:%02i") })
            total = shadow_target_buff_delay:GetInt()
            color = Color(25, 200, 25, 155)
        end

        -- If we didn't get everything set, forget it
        if remaining == nil or message == nil or total == nil or color == nil then return end

        local x = ScrW() / 2.0
        local y = ScrH() / 2.0
        y = y + (y / 3)

        local w = 300
        local progress = 1 - (remaining / total)

        CRHUD:PaintProgressBar(x, y, w, color, message, progress)
    end
end)

AddHook("TTTHUDInfoPaint", "Shadow_Buff_TTTHUDInfoPaint", function(cli, label_left, label_top, active_labels)
    if not cli:IsShadow() then return end
    if hide_role:GetBool() then return end

    local shadowBuff = shadow_target_buff:GetInt()
    if shadowBuff <= SHADOW_BUFF_NONE then return end

    local buffTimer = cli:GetNWFloat("ShadowBuffTimer", -1)
    if buffTimer < 0 then return end

    local target = player.GetBySteamID64(cli:GetNWString("ShadowTarget", ""))
    if not IsPlayer(target) then return end
    -- If their target player has already had their buff and can't get it again, don't bother showing the HUD info
    if target:GetNWBool("ShadowBuffDepleted", false) then return end

    surface.SetFont("TabLarge")
    surface.SetTextColor(255, 255, 255, 230)

    local remaining = MathMax(0, buffTimer - CurTime())
    local buff = LANG.GetTranslation("shadow_buff_" .. shadowBuff)
    local text
    if remaining == 0 then
        text = LANG.GetParamTranslation("shadow_buff_hud_active", { buff = buff })
    else
        -- If we're showing a progress bar, don't bother with the label
        if shadow_target_buff_show_progress:GetBool() then return end

        text = LANG.GetParamTranslation("shadow_buff_hud_time", { buff = buff, time = util.SimpleTime(remaining, "%02i:%02i") })
    end
    local _, h = surface.GetTextSize(text)

    -- Move this up based on how many other labels here are
    label_top = label_top + (20 * #active_labels)

    surface.SetTextPos(label_left, ScrH() - label_top - h)
    surface.DrawText(text)

    -- Track that the label was added so others can position accurately
    table.insert(active_labels, "shadow")
end)

--------------
-- TUTORIAL --
--------------

AddHook("TTTTutorialRoleText", "Shadow_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_SHADOW then
        local roleTeam = player.GetRoleTeam(ROLE_SHADOW, true)
        local roleTeamName, roleColor = GetRoleTeamInfo(roleTeam)
        local html = "The " .. ROLE_STRINGS[ROLE_SHADOW] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. roleTeamName .. "</span> role that needs to stay close to their target without dying."

        local soul_link = shadow_soul_link:GetInt()
        if soul_link == SHADOW_SOUL_LINK_BOTH then
            html = html .. " If the shadow dies, their target dies and vice-versa."
        elseif soul_link == SHADOW_SOUL_LINK_TARGET then
            html = html .. " If the shadow's target dies, the shadow dies instantly."
        elseif roleTeam ~= ROLE_TEAM_JESTER then
            html = html .. " If the shadow kills their target, they die instantly."
        end

        local buff = shadow_target_buff:GetInt()
        -- If the shadow is stealing their target's role, they don't win just by surviving
        if buff ~= SHADOW_BUFF_STEAL_ROLE then
            html = html .. " If the shadow survives until the end of the round they win."
        end

        local start_timer = shadow_start_timer:GetInt()
        local buffer_timer = shadow_buffer_timer:GetInt()
        local delay_min = shadow_delay_timer_min:GetInt()
        local delay_max = shadow_delay_timer_max:GetInt()
        local delay = ""
        if delay_min > 0 and delay_max > 0 then
            delay = " after a delay between " .. delay_min .. " and " .. delay_max .. " seconds"
        end
        html = html .. "<span style='display: block; margin-top: 10px;'>They can see their target through walls and are given <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. start_timer .. " seconds</span> to find them at the start of the round" .. delay .. ". Once the shadow has found their target, they are given a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. buffer_timer .. " second</span> warning if they start to get too far away. If either of these timers run out before the shadow can find their target, the shadow "

        if shadow_weaken_health_to:GetInt() > 0 then
            html = html .. "has their health temporarily reduced over time. Once they get close to their target again, though, they will start to recover their max health back to normal"
            if shadow_weaken_health_to_death:GetBool() then
                html = html .. ". If they stay away for too long, however, the " .. ROLE_STRINGS[ROLE_SHADOW] .. " <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>will die</span>"
            end
        else
            local failure_mode = shadow_failure_mode:GetInt()
            if failure_mode == SHADOW_FAILURE_JESTER then
                html = html .. "becomes a " .. ROLE_STRINGS[ROLE_JESTER]
            elseif failure_mode == SHADOW_FAILURE_SWAPPER then
                html = html .. "becomes a " .. ROLE_STRINGS[ROLE_SWAPPER]
            else
                html = html .. "dies"
            end
        end
        html = html .. ".</span>"

        html = html .. "<span style='display: block; margin-top: 10px;'>If your target dies you still need to stay close to their body. Staying too far away from their body for more than <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. buffer_timer .. " seconds</span> will kill you.</span>"

        if buff ~= SHADOW_BUFF_NONE then
            local buffDelay = shadow_target_buff_delay:GetInt()
            local buffType = LANG.GetTranslation("shadow_buff_" .. buff)
            html = html .. "<span style='display: block; margin-top: 10px;'>If you stay with your target for " .. buffDelay .. " seconds "
            if buff == SHADOW_BUFF_TEAM_JOIN then
                html = html .. "you will <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>join their team</span>!"
            elseif buff == SHADOW_BUFF_STEAL_ROLE then
                html = html .. "you will <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>steal their role</span>!"
            else
                html = html .. "they will <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>receive a " .. buffType .. "</span>! Beware, however, that if you get too far away the buff will disappear and you'll have to wait all over again."
            end
            html = html .. "</span>"

            if buff == SHADOW_BUFF_RESPAWN then
                html = html .. "<span style='display: block; margin-top: 10px;'>The first time your target dies while the buff is active, they will <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>respawn</span> after a short delay.</span>"
            end
        end

        local has_speed_mult = shadow_speed_mult:GetFloat() > 1
        local has_sprint_recovery = shadow_sprint_recovery:GetFloat() > 0
        if has_speed_mult or has_sprint_recovery then
            html = html .. "<span style='display: block; margin-top: 10px;'>When the " .. ROLE_STRINGS[ROLE_SHADOW] .. " is outside of their target's radius, they "
            if has_speed_mult then
                html = html .. "get a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>speed bonus</span>"
            end

            if has_speed_mult and has_sprint_recovery then
                html = html .. " and "
            end

            if has_sprint_recovery then
                html = html .. "<span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>recover sprint stamina faster</span>"
            end
            html = html .. ".</span>"
        end

        return html
    end
end)