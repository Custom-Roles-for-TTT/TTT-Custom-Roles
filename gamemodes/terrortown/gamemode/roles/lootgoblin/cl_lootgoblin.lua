local hook = hook
local net = net
local surface = surface
local string = string
local table = table
local util = util

local MathMax = math.max
local GetAllPlayers = player.GetAll
local TableInsert = table.insert

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "LootGoblin_Translations_Initialize", function()
    -- Win conditions
    LANG.AddToLanguage("english", "ev_win_lootgoblin", "The {role} has escaped and also won the round!")

    -- HUD
    LANG.AddToLanguage("english", "lootgoblin_hud", "You will transform in: {time}")

    -- ConVars
    LANG.AddToLanguage("english", "lootgoblin_config_radar_sound", "Play radar ping sound")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_lootgoblin", [[You are {role}! All you want to do is hoard your
loot! But be careful... Everyone is out to kill
you and steal it for themselves!]])
end)

-------------
-- CONVARS --
-------------

local lootgoblin_regen_mode = GetConVar("ttt_lootgoblin_regen_mode")
local lootgoblin_radar_enabled = GetConVar("ttt_lootgoblin_radar_enabled")
local lootgoblin_radar_timer = GetConVar("ttt_lootgoblin_radar_timer")
local lootgoblin_active_display = GetConVar("ttt_lootgoblin_active_display")
local lootgoblin_announce = GetConVar("ttt_lootgoblin_announce")
local lootgoblin_cackle_enabled = GetConVar("ttt_lootgoblin_cackle_enabled")
local lootgoblin_jingle_enabled = GetConVar("ttt_lootgoblin_jingle_enabled")
local lootgoblin_speed_mult = GetConVar("ttt_lootgoblin_speed_mult")
local lootgoblin_sprint_recovery = GetConVar("ttt_lootgoblin_sprint_recovery")
local lootgoblin_drop_timer = GetConVar("ttt_lootgoblin_drop_timer")

local lootgoblin_radar_beep_sound = CreateClientConVar("ttt_lootgoblin_radar_beep_sound", "1", true, false, "Whether the loot goblin's radar should play a beep sound whenever the location updates", 0, 1)
local lootgoblin_radar_beep_sound_override = GetConVar("ttt_lootgoblin_radar_beep_sound_override")

hook.Add("TTTSettingsRolesTabSections", "LootGoblin_TTTSettingsRolesTabSections", function(role, parentForm)
    if role ~= ROLE_LOOTGOBLIN then return end
    if not lootgoblin_radar_enabled:GetBool() then return end
    if lootgoblin_radar_beep_sound_override:GetInt() ~= 0 then return end

    parentForm:CheckBox(LANG.GetTranslation("lootgoblin_config_radar_sound"), "ttt_lootgoblin_radar_beep_sound")
    return true
end)

-----------
-- RADAR --
-----------

local beacon_back = surface.GetTextureID("vgui/ttt/beacon_back")
local beacon_gob = surface.GetTextureID("vgui/ttt/beacon_gob")
local lootgoblins = {}

hook.Add("TTTRadarRender", "LootGoblin_TTTRadarRender", function(cli)
    if #lootgoblins then
        surface.SetTexture(beacon_back)
        surface.SetTextColor(0, 0, 0, 0)
        surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_LOOTGOBLIN])

        for _, target in pairs(lootgoblins) do
            RADAR:DrawTarget(target, 16, 0.5)
        end

        surface.SetTexture(beacon_gob)
        surface.SetTextColor(255, 255, 255, 255)
        surface.SetDrawColor(255, 255, 255, 255)

        for _, target in pairs(lootgoblins) do
            RADAR:DrawTarget(target, 16, 0.5)
        end
    end
end)

local beep_success = Sound("buttons/blip2.wav")
local function SetLootGoblinPosition()
    local cli = LocalPlayer()
    if not cli:IsActiveLootGoblin() then
        lootgoblins = {}
        local beepSoundOverride = lootgoblin_radar_beep_sound_override:GetInt()
        for k, v in ipairs(GetAllPlayers()) do
            if v:IsActiveLootGoblin() and v:IsRoleActive() then
                lootgoblins[k] = { pos = v:GetNWVector("TTTLootGoblinRadar", vector_origin) }
                if cli:IsActive() and beepSoundOverride == 1 or (beepSoundOverride ~= 2 and lootgoblin_radar_beep_sound:GetBool()) then surface.PlaySound(beep_success) end
            end
        end
    end
end

local function UpdateLootGoblin()
    if timer.Exists("updatelootgoblin") then timer.Remove("updatelootgoblin") end
    local active = net.ReadBool()
    if active then
        SetLootGoblinPosition()
        timer.Create("updatelootgoblin", lootgoblin_radar_timer:GetInt(), 0, SetLootGoblinPosition)
    else
        lootgoblins = {}
    end
end
net.Receive("TTT_LootGoblinRadar", UpdateLootGoblin)

hook.Add("TTTEndRound", "LootGoblin_Radar_TTTEndRound", function()
    if timer.Exists("updatelootgoblin") then timer.Remove("updatelootgoblin") end
end)

-------------
-- SCORING --
-------------

-- Track when the loot goblin wins
local lootgoblin_wins = false
net.Receive("TTT_UpdateLootGoblinWins", function()
    -- Log the win event with an offset to force it to the end
    if net.ReadBool() then
        lootgoblin_wins = true
        CLSCORE:AddEvent({
            id = EVENT_FINISH,
            win = WIN_LOOTGOBLIN
        }, 1)
    end
end)

local function ResetLootGoblinWin()
    lootgoblin_wins = false
end
net.Receive("TTT_ResetLootGoblinWins", ResetLootGoblinWin)
hook.Add("TTTPrepareRound", "LootGoblin_WinTracking_TTTPrepareRound", ResetLootGoblinWin)
hook.Add("TTTBeginRound", "LootGoblin_WinTracking_TTTBeginRound", ResetLootGoblinWin)

----------------
-- WIN CHECKS --
----------------

hook.Add("TTTScoringSecondaryWins", "LootGoblin_TTTScoringSecondaryWins", function(wintype, secondary_wins)
    if lootgoblin_wins then
        TableInsert(secondary_wins, ROLE_LOOTGOBLIN)
    end
end)

------------
-- EVENTS --
------------

hook.Add("TTTEventFinishText", "LootGoblin_TTTEventFinishText", function(e)
    if e.win == WIN_LOOTGOBLIN then
        return LANG.GetParamTranslation("ev_win_lootgoblin", { role = string.lower(ROLE_STRINGS[ROLE_LOOTGOBLIN]) })
    end
end)

hook.Add("TTTEventFinishIconText", "LootGoblin_TTTEventFinishIconText", function(e, win_string, role_string)
    if e.win == WIN_LOOTGOBLIN then
        return "ev_win_icon_also", ROLE_STRINGS[ROLE_LOOTGOBLIN]
    end
end)

---------
-- HUD --
---------

hook.Add("TTTHUDInfoPaint", "LootGoblin_TTTHUDInfoPaint", function(client, label_left, label_top, active_labels)
    local hide_role = false
    if ConVarExists("ttt_hide_role") then
        hide_role = GetConVar("ttt_hide_role"):GetBool()
    end

    if hide_role then return end

    if client:IsActiveLootGoblin() and not client:IsRoleActive() then
        surface.SetFont("TabLarge")
        surface.SetTextColor(255, 255, 255, 230)

        local remaining = MathMax(0, GetGlobalFloat("ttt_lootgoblin_activate", 0) - CurTime())
        local text = LANG.GetParamTranslation("lootgoblin_hud", { time = util.SimpleTime(remaining, "%02i:%02i") })
        local _, h = surface.GetTextSize(text)

        -- Move this up based on how many other labels here are
        label_top = label_top + (20 * #active_labels)

        surface.SetTextPos(label_left, ScrH() - label_top - h)
        surface.DrawText(text)

        -- Track that the label was added so others can position accurately
        TableInsert(active_labels, "lootgoblin")
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "LootGoblin_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_LOOTGOBLIN then
        local roleColor = GetRoleTeamColor(ROLE_TEAM_JESTER)
        local html = "The " .. ROLE_STRINGS[ROLE_LOOTGOBLIN] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>jester</span> role who likes to hoard loot."

        -- Activation Timer
        html = html .. "<span style='display: block; margin-top: 10px;'>After some time has passed, <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>the " .. ROLE_STRINGS[ROLE_LOOTGOBLIN] .. "</span> will transform"
        if lootgoblin_active_display:GetBool() then
            html = html .. "and be revealed to players."
        end
        html = html .. "</span>"

        -- Transformation announcement
        local announce = lootgoblin_announce:GetInt()
        if announce > JESTER_NOTIFY_NONE then
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_LOOTGOBLIN] .. "'s transformation will be <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>announced to "
            if announce == JESTER_NOTIFY_DETECTIVE then
                html = html .. "all " .. LANG.GetTranslation("detectives")
            elseif announce == JESTER_NOTIFY_TRAITOR then
                html = html .. "all " .. LANG.GetTranslation("traitors")
            elseif announce == JESTER_NOTIFY_DETECTIVE_AND_TRAITOR then
                html = html .. "all " .. LANG.GetTranslation("detectives") .. " and " .. LANG.GetTranslation("traitors")
            else
                html = html .. "everyone"
            end
            html = html .. "</span>.</span>"
        end

        -- Drop loot on death
        html = html .. "<span style='display: block; margin-top: 10px;'>Once they have activated, <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>the " .. ROLE_STRINGS[ROLE_LOOTGOBLIN] .. "</span> will drop a large number of items and credits when killed.</span>"

        local drop_timer = lootgoblin_drop_timer:GetInt()
        if drop_timer > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>While alive and activated, <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>the " .. ROLE_STRINGS[ROLE_LOOTGOBLIN] .. "</span> will periodically drop items on the ground behind them.</span>"
        end

        -- Win condition
        html = html .. "<span style='display: block; margin-top: 10px;'>If <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>the " .. ROLE_STRINGS[ROLE_LOOTGOBLIN] .. "</span> survives until another team wins the round, they will share the win with that team.</span>"

        -- Regeneration
        local regenMode = lootgoblin_regen_mode:GetInt()
        if regenMode > LOOTGOBLIN_REGEN_MODE_NONE then
            html = html .. "<span style='display: block; margin-top: 10px;'>While activated, <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>the " .. ROLE_STRINGS[ROLE_LOOTGOBLIN] .. "</span> will regenerate health "

            if regenMode == LOOTGOBLIN_REGEN_MODE_ALWAYS then
                html = html .. "constantly"
            elseif regenMode == LOOTGOBLIN_REGEN_MODE_STILL then
                html = html .. "while not moving"
            else
                html = html .. "after taking damage"
            end

            html = html .. ".</span>"
        end

        -- Radar
        if lootgoblin_radar_enabled:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>Once activated, the " .. ROLE_STRINGS[ROLE_LOOTGOBLIN] .. "'s <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>location will be periodically shown</span> to other players. The location is delayed to allow the " .. ROLE_STRINGS[ROLE_LOOTGOBLIN] .. " the chance to run away.</span>"
        end

        -- Cackle
        if lootgoblin_cackle_enabled:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>After activation, the " .. ROLE_STRINGS[ROLE_LOOTGOBLIN] .. " will occasionally <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>cackle deviously</span> to taunt their pursuers.</span>"
        end

        -- Jingle
        if lootgoblin_jingle_enabled:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>When active, the " .. ROLE_STRINGS[ROLE_LOOTGOBLIN] .. " will <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>make jingling sounds</span> when they move, making them easier to track.</span>"
        end

        -- Speed boost
        if lootgoblin_speed_mult:GetFloat() > 1 then
            html = html .. "<span style='display: block; margin-top: 10px;'>To help the " .. ROLE_STRINGS[ROLE_LOOTGOBLIN] .. " avoid capture, they gain a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>speed boost</span> while active.</span>"
        end

        -- Sprint stamina recovery boost
        if lootgoblin_sprint_recovery:GetFloat() > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_LOOTGOBLIN] .. " gets a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>boost to their sprint stamina recovery</span> to aid in running away from damage.</span>"
        end

        return html
    end
end)
