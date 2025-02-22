---- Help screen

local concommand = concommand
local cvars = cvars
local hook = hook
local ipairs = ipairs
local pairs = pairs
local surface = surface
local string = string
local table = table
local timer = timer
local vgui = vgui
local util = util

local GetTranslation = LANG.GetTranslation
local GetPTranslation = LANG.GetParamTranslation
local HookCall = hook.Call

surface.CreateFont("TutorialTitle", {
    font = "Trebuchet MS",
    size = 30,
    weight = 900 })

local overrideModeCVar = nil

CreateClientConVar("ttt_spectator_mode", "0", true, false)
CreateClientConVar("ttt_mute_team_check", "0", true, false)
CreateClientConVar("ttt_show_raw_karma_value", "0", true, false)
CreateClientConVar("ttt_show_karma_total_pct", "0", true, false)
CreateClientConVar("ttt_color_mode", "default", true, false)

CreateClientConVar("ttt_custom_inn_color_r", "25", true, false)
CreateClientConVar("ttt_custom_inn_color_g", "200", true, false)
CreateClientConVar("ttt_custom_inn_color_b", "25", true, false)

CreateClientConVar("ttt_custom_spec_inn_color_r", "245", true, false)
CreateClientConVar("ttt_custom_spec_inn_color_g", "200", true, false)
CreateClientConVar("ttt_custom_spec_inn_color_b", "0", true, false)

CreateClientConVar("ttt_custom_tra_color_r", "200", true, false)
CreateClientConVar("ttt_custom_tra_color_g", "25", true, false)
CreateClientConVar("ttt_custom_tra_color_b", "25", true, false)

CreateClientConVar("ttt_custom_spec_tra_color_r", "245", true, false)
CreateClientConVar("ttt_custom_spec_tra_color_g", "106", true, false)
CreateClientConVar("ttt_custom_spec_tra_color_b", "0", true, false)

CreateClientConVar("ttt_custom_det_color_r", "25", true, false)
CreateClientConVar("ttt_custom_det_color_g", "25", true, false)
CreateClientConVar("ttt_custom_det_color_b", "200", true, false)

CreateClientConVar("ttt_custom_spec_det_color_r", "40", true, false)
CreateClientConVar("ttt_custom_spec_det_color_g", "180", true, false)
CreateClientConVar("ttt_custom_spec_det_color_b", "200", true, false)

CreateClientConVar("ttt_custom_jes_color_r", "180", true, false)
CreateClientConVar("ttt_custom_jes_color_g", "23", true, false)
CreateClientConVar("ttt_custom_jes_color_b", "253", true, false)

CreateClientConVar("ttt_custom_ind_color_r", "112", true, false)
CreateClientConVar("ttt_custom_ind_color_g", "50", true, false)
CreateClientConVar("ttt_custom_ind_color_b", "0", true, false)

CreateClientConVar("ttt_custom_mon_color_r", "69", true, false)
CreateClientConVar("ttt_custom_mon_color_g", "97", true, false)
CreateClientConVar("ttt_custom_mon_color_b", "0", true, false)
UpdateRoleColours()

CreateClientConVar("ttt_avoid_detective", "0", true, true)
CreateClientConVar("ttt_hide_ammo", "0", true, false)

local hide_role = CreateClientConVar("ttt_hide_role", "0", true, false)

CreateClientConVar("ttt_bypass_culling", "1", true, true, "Whether to bypass vis leafs and culling in maps for player icons and highlighting", 0, 1)

HELPSCRN = {}

local dframe = nil
hook.Add("OnPauseMenuShow", "Help_OnPauseMenuShow", function()
    -- If we needed to close the help menu, don't open the pause menu too
    if IsValid(dframe) then
        dframe:Close()
        dframe = nil
        return false
    end
end)

function HELPSCRN:Show()
    if IsValid(dframe) then return end
    local margin = 15

    dframe = vgui.Create("DFrame")
    local w, h = 630, 470
    dframe:SetSize(w, h)
    dframe:Center()
    dframe:SetTitle(GetTranslation("help_title"))
    dframe:ShowCloseButton(true)

    local dbut = vgui.Create("DButton", dframe)
    local bw, bh = 50, 25
    dbut:SetSize(bw, bh)
    dbut:SetPos(w - bw - margin, h - bh - margin / 2)
    dbut:SetText(GetTranslation("close"))
    dbut.DoClick = function()
        dframe:Close()
        dframe = nil
    end

    local dtabs = vgui.Create("DPropertySheet", dframe)
    dtabs:SetPos(margin, margin * 2)
    dtabs:SetSize(w - margin * 2, h - margin * 3 - bh)

    local padding = dtabs:GetPadding() * 2

    -- Tutorial
    local tutparent = vgui.Create("DPanel", dtabs)
    tutparent:SetPaintBackground(false)
    tutparent:StretchToParent(margin, 0, 0, 0)

    self.TutorialPanel = self:CreateTutorial(tutparent)

    dtabs:AddSheet(GetTranslation("help_tut"), tutparent, "icon16/book_open.png", false, false, GetTranslation("help_tut_tip"))

    -- Config
    local dsettings = vgui.Create("DScrollPanel", dtabs)
    dsettings:StretchToParent(0, 0, padding, 0)
    dsettings:SetPadding(10)

    self:CreateConfig(dsettings)
    HookCall("TTTSettingsConfigTabSections", nil, dsettings)

    dtabs:AddSheet(GetTranslation("help_settings"), dsettings, "icon16/wrench.png", false, false, GetTranslation("help_settings_tip"))

    -- Roles
    local droles = vgui.Create("DScrollPanel", dtabs)
    droles:StretchToParent(0, 0, padding, 0)
    droles:SetPadding(10)

    if self:CreateRoles(droles) then
        dtabs:AddSheet(GetTranslation("help_roles"), droles, "icon16/group.png", false, false, GetTranslation("help_roles_tip"))
    else
        droles:Remove()
    end

    HookCall("TTTSettingsTabs", GAMEMODE, dtabs)

    dframe:MakePopup()
end

local function ShowTTTHelp(ply, cmd, args)
    HELPSCRN:Show()
end
concommand.Add("ttt_helpscreen", ShowTTTHelp)

-- Some spectator mode bookkeeping

local function SpectateCallback(cv, old, new)
    local num = tonumber(new)
    if num and (num == 0 or num == 1) then
        RunConsoleCommand("ttt_spectate", num)
    end
end
cvars.AddChangeCallback("ttt_spectator_mode", SpectateCallback)

local function MuteTeamCallback(cv, old, new)
    local num = tonumber(new)
    if num and (num == 0 or num == 1) then
        RunConsoleCommand("ttt_mute_team", num)
    end
end
cvars.AddChangeCallback("ttt_mute_team_check", MuteTeamCallback)

--- Tutorial

local fontStyle = "font-family: arial; font-weight: 600;"
local keyMappingStyles = "font-size: 12px; color: black; display: inline-block; padding: 0px 3px; height: 16px; border-width: 4px; border-style: solid; border-left-color: rgb(221, 221, 221); border-bottom-color: rgb(119, 119, 102); border-right-color: rgb(119, 119, 119); border-top-color: rgb(255, 255, 255); background-color: rgb(204, 204, 187);"

local function TutorialOverview(pnl, lbl)
    local html = vgui.Create("DHTML", pnl)
    html:Dock(FILL)

    -- Open the page
    local htmlData = "<div style='width: 100%; height: 93%; top: 20px; position: relative; padding-top: 10px;'>"

    -- First line
        htmlData = htmlData .. "<div style='margin-top: 10px; text-align: center; height: 40px;'>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'>It's mostly about</span>"
            local color = ROLE_COLORS[ROLE_TRAITOR]
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white; text-shadow: black 1px 1px; margin-left: 5px; margin-right: 5px; padding: 5px 10px 5px 8px; border-radius: 3px; background-color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>" .. ROLE_STRINGS[ROLE_TRAITOR] .. "</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'>versus</span>"
            color = ROLE_COLORS[ROLE_INNOCENT]
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white; text-shadow: black 1px 1px; margin-left: 5px; margin-right: 5px; padding: 5px 10px 5px 8px; border-radius: 3px; background-color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>" .. ROLE_STRINGS[ROLE_INNOCENT] .. "</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'>but there are others...</span>"
        htmlData = htmlData .. "</div>"

    -- Second line
        htmlData = htmlData .. "<div style='text-align: center; height: 40px;'>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'>A small group of " .. ROLE_STRINGS_PLURAL[ROLE_TRAITOR] .. " is </span>"
            color = ROLE_COLORS[ROLE_INNOCENT]
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>randomly picked.</span>"
        htmlData = htmlData .. "</div>"

    -- Third line
        htmlData = htmlData .. "<div style='text-align: center; height: 40px;'>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'>Together they have to </span>"
            color = ROLE_COLORS[ROLE_TRAITOR]
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>kill all the " .. ROLE_STRINGS_PLURAL[ROLE_INNOCENT] .. ".</span>"
        htmlData = htmlData .. "</div>"

    -- Fourth line
        htmlData = htmlData .. "<div style='text-align: center; height: 40px;'>"
            color = ROLE_COLORS[ROLE_INNOCENT]
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>The " .. ROLE_STRINGS_PLURAL[ROLE_INNOCENT] .. "</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'> do not know </span>"
            color = ROLE_COLORS[ROLE_TRAITOR]
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>who is " .. ROLE_STRINGS_EXT[ROLE_TRAITOR] .. "</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'> and </span>"
            color = ROLE_COLORS[ROLE_INNOCENT]
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>who is not.</span>"
        htmlData = htmlData .. "</div>"

    -- Fifth line
        htmlData = htmlData .. "<div style='text-align: center; height: 40px;'>"
            color = ROLE_COLORS[ROLE_TRAITOR]
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>The " .. ROLE_STRINGS_PLURAL[ROLE_TRAITOR] .. "</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'> need stealth and guile: they are </span>"
            color = ROLE_COLORS[ROLE_INNOCENT]
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>outnumbered.</span>"
        htmlData = htmlData .. "</div>"

    -- Sixth line
        htmlData = htmlData .. "<div style='text-align: center; height: 40px;'>"
            color = GetRoleTeamColor(ROLE_TEAM_INDEPENDENT)
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>The Independents</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'> work alone, trying to win against everyone else.</span>"
        htmlData = htmlData .. "</div>"

    -- Seventh line
        htmlData = htmlData .. "<div style='text-align: center; height: 40px;'>"
            color = GetRoleTeamColor(ROLE_TEAM_JESTER)
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>The Jesters</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'>, meanwhile, try to trick the other players into aiding them.</span>"
        htmlData = htmlData .. "</div>"

    -- Close the page
    htmlData = htmlData .. "</div>"

    html:SetHTML(htmlData)
end

local function TutorialPlayerDeath(pnl, lbl)
    local html = vgui.Create("DHTML", pnl)
    html:Dock(FILL)

    -- Open the page
    local htmlData = "<div style='width: 100%; height: 93%; top: 20px; position: relative; padding-top: 10px;'>"

    -- First line
        htmlData = htmlData .. "<div style='margin-top: 10px; text-align: center; height: 40px;'>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'>If you die, you will not respawn until next round.</span>"
        htmlData = htmlData .. "</div>"

    -- Second line
        htmlData = htmlData .. "<div style='text-align: center; height: 40px;'>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'>" .. ROLE_STRINGS_PLURAL[ROLE_INNOCENT] .. " </span>"
            local color = ROLE_COLORS[ROLE_INNOCENT]
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>will not know</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'> you are dead...</span>"
        htmlData = htmlData .. "</div>"

    -- Third line
        htmlData = htmlData .. "<div style='text-align: center; height: 40px; margin-top: -15px;'>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'>...until they find your </span>"
            color = ROLE_COLORS[ROLE_INNOCENT]
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>corpse.</span>"
        htmlData = htmlData .. "</div>"

    -- Fourth line
        htmlData = htmlData .. "<div style='text-align: center; height: 40px;'>"
            color = Color(0, 200, 0, 100)
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white; text-shadow: black 1px 1px; margin-left: 5px; margin-right: 5px; padding: 2px 10px 2px 8px; border-radius: 8px; background-color: rgba(" .. color.r .. ", " .. color.g .. "," .. color.b .. ", " .. color.a .. ");'>" .. GetTranslation("terrorists") .. "</span>"
            htmlData = htmlData .. "<img style='position: relative; top: 4px;' src='asset://garrysmod/gamemodes/terrortown/content/materials/vgui/ttt/help/tut02_death_arrow.png' width='36' height='21'></img>"
            color = Color(130, 190, 130, 100)
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white; text-shadow: black 1px 1px; margin-left: 5px; margin-right: 5px; padding: 2px 10px; border-radius: 8px; background-color: rgba(" .. color.r .. ", " .. color.g .. "," .. color.b .. ", " .. color.a .. ");'>" .. GetTranslation("sb_mia") .. "</span>"
            htmlData = htmlData .. "<img style='position: relative; top: 4px;' src='asset://garrysmod/gamemodes/terrortown/content/materials/vgui/ttt/help/tut02_found_arrow.png' width='39' height='22'></img>"
            color = Color(130, 170, 10, 100)
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white; text-shadow: black 1px 1px; margin-left: 5px; margin-right: 5px; padding: 2px 10px; border-radius: 8px; background-color: rgba(" .. color.r .. ", " .. color.g .. "," .. color.b .. ", " .. color.a .. ");'>" .. GetTranslation("sb_confirmed") .. "</span>"
            htmlData = htmlData .. "<img style='position: relative; top: 50px;' src='asset://garrysmod/gamemodes/terrortown/content/materials/vgui/ttt/help/tut02_corpse_info.png' width='382' height='62'></img>"
        htmlData = htmlData .. "</div>"

    -- Fifth line
        htmlData = htmlData .. "<div style='text-align: center; height: 40px;'>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'>Corpses may have </span>"
            color = ROLE_COLORS[ROLE_INNOCENT]
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>information</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'> that leads to the killer.</span>"
        htmlData = htmlData .. "</div>"

    -- Close the page
    htmlData = htmlData .. "</div>"

    html:SetHTML(htmlData)
end

local function TutorialSpecialEquipment(pnl, lbl)
    local html = vgui.Create("DHTML", pnl)
    html:Dock(FILL)

    -- Open the page
    local htmlData = "<div style='width: 100%; height: 93%; top: 20px; position: relative; padding-top: 10px;'>"

    -- First line
        htmlData = htmlData .. "<div style='margin-top: 10px; text-align: center; height: 40px;'>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'>Some roles can buy </span>"
            local color = ROLE_COLORS[ROLE_TRAITOR]
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>special equipment.</span>"
        htmlData = htmlData .. "</div>"

    -- Second line
        htmlData = htmlData .. "<div style='text-align: center; height: 40px;'>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'>Their </span>"
            color = ROLE_COLORS[ROLE_TRAITOR]
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>Equipment menu</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'> can be opened by pressing </span>"
            local key = Key("+menu_context", "C")
            htmlData = htmlData .. "<span style='" .. fontStyle .. keyMappingStyles .. "'>" .. key .. "</span>"
            htmlData = htmlData .. "<img style='position: relative; top: 10px;' src='asset://garrysmod/gamemodes/terrortown/content/materials/vgui/ttt/help/tut03_shop.png' width='567' height='129'></img>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " display: block; margin-top: 15px; color: white;'>Roles from all teams can have access to an equipment menu.</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " display: block; color: white;'>Check your specific role's page for more details.</span>"
        htmlData = htmlData .. "</div>"

    -- Close the page
    htmlData = htmlData .. "</div>"

    html:SetHTML(htmlData)
end

local function TutorialUsefulKeys(pnl, lbl)
    lbl:SetText("You may find the following keys useful:")
    lbl:SizeToContents()
    lbl:CenterHorizontal()

    local html = vgui.Create("DHTML", pnl)
    html:Dock(FILL)

    -- Open the page
    local htmlData = "<div style='width: 100%; height: 93%; top: 20px; position: relative; padding-top: 10px;'>"

    -- First line
        htmlData = htmlData .. "<div style='height: 40px;'>"
            local key = Key("+menu", "Q")
            htmlData = htmlData .. "<span style='" .. fontStyle .. keyMappingStyles .. "'>" .. key .. "</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'> will </span>"
            local color = ROLE_COLORS[ROLE_INNOCENT]
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>drop</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'> your weapon so you can pick up another.</span>"
        htmlData = htmlData .. "</div>"

    -- Second line
        htmlData = htmlData .. "<div style='height: 40px;'>"
            key = Key("+menu_context", "C")
            htmlData = htmlData .. "<span style='" .. fontStyle .. keyMappingStyles .. "'>" .. key .. "</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'> will open the </span>"
            color = ROLE_COLORS[ROLE_TRAITOR]
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>Equipment menu</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'>, if your role has one.</span>"
        htmlData = htmlData .. "</div>"

    -- Third line (only if voice is enabled)
    if GetGlobalBool("sv_voiceenable") then
        htmlData = htmlData .. "<div style='height: 40px;'>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'>Set a key for </span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white; font-style: italic;'>Suit Zoom</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'> to send voicechat </span>"
            color = ROLE_COLORS[ROLE_TRAITOR]
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>only to " .. ROLE_STRINGS_PLURAL[ROLE_TRAITOR] .. ".</span>"
        htmlData = htmlData .. "</div>"
    end

    -- Fourth line
        htmlData = htmlData .. "<div style='height: 40px;'>"
            key = Key("gm_showhelp", "F1")
            htmlData = htmlData .. "<span style='" .. fontStyle .. keyMappingStyles .. "'>" .. key .. "</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'> shows this </span>"
            color = ROLE_COLORS[ROLE_INNOCENT]
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>Help and Settings</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'> menu.</span>"
        htmlData = htmlData .. "</div>"

    -- Fifth line
        htmlData = htmlData .. "<div style='height: 40px;'>"
            key = string.upper(GetConVar("ttt_radio_button"):GetString())
            htmlData = htmlData .. "<span style='" .. fontStyle .. keyMappingStyles .. "'>" .. key .. "</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'> will open the </span>"
            color = ROLE_COLORS[ROLE_INNOCENT]
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>Radio Commands</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'> menu.</span>"
        htmlData = htmlData .. "</div>"

    -- Sixth line
        htmlData = htmlData .. "<div style='height: 40px;'>"
            key = Key("+speed", "Shift")
            htmlData = htmlData .. "<span style='" .. fontStyle .. keyMappingStyles .. "'>" .. key .. "</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'> will allow you to </span>"
            color = ROLE_COLORS[ROLE_INNOCENT]
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>sprint</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'> while you have the stamina.</span>"
        htmlData = htmlData .. "</div>"

    -- Close the page
    htmlData = htmlData .. "</div>"

    html:SetHTML(htmlData)
end

local function TutorialKarma(pnl, lbl)
    local html = vgui.Create("DHTML", pnl)
    html:Dock(FILL)

    -- Open the page
    local htmlData = "<div style='width: 100%; height: 93%; top: 20px; position: relative; padding-top: 10px;'>"

    -- First line
        htmlData = htmlData .. "<div style='margin-top: 15px; height: 40px;'>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'>Your </span>"
            local color = GetRoleTeamColor(ROLE_TEAM_INNOCENT)
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>Karma</span>"
            local starting_karma = GetGlobalInt("ttt_karma_starting", 1000)
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'> starts at " .. starting_karma .. " and goes down if you </span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>damage players</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'> who are on your own side. It does down less if their Karma is lower.</span>"
        htmlData = htmlData .. "</div>"

    -- Second line
        htmlData = htmlData .. "<div style='margin-top: 15px; height: 40px;'>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'>If your Karma is low when a round starts, you get a </span>"
            color = GetRoleTeamColor(ROLE_TEAM_INNOCENT)
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>penalty to your weapon damage</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'> that round.</span>"
        htmlData = htmlData .. "</div>"

    -- Third line
        htmlData = htmlData .. "<div style='margin-top: 15px; height: 40px;'>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'>By playing </span>"
            color = GetRoleTeamColor(ROLE_TEAM_INNOCENT)
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>clean rounds</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'> where you don't harm teammates, you regain Karma. Some roles will also get Karma for </span>"
            color = ROLE_COLORS[ROLE_INNOCENT]
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'> hurting their enemies.</span>"
        htmlData = htmlData .. "</div>"

    -- Fourth line
        htmlData = htmlData .. "<div style='margin-top: 15px; height: 40px;'>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'>The Karma value shown on the scoreboard updates only </span>"
            color = GetRoleTeamColor(ROLE_TEAM_INNOCENT)
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. color.r .. ", " .. color.g .. "," .. color.b .. ");'>after the round ends</span>"
            htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'>. During a round, someone's true Karma might be lower.</span>"
        htmlData = htmlData .. "</div>"

    -- Close the page
    htmlData = htmlData .. "</div>"

    html:SetHTML(htmlData)
end

local tutorialPages = {
    [1] = {title = "Overview", body = TutorialOverview},
    [2] = {title = "Player Death", body = TutorialPlayerDeath},
    [3] = {title = "Special Equipment", body = TutorialSpecialEquipment},
    [4] = {title = "Useful Keys", body = TutorialUsefulKeys},
    [5] = {title = "Karma", body = TutorialKarma, enabled = function() return GetGlobalBool("ttt_karma", false) end}
}
local maxPages = table.Count(tutorialPages)
local enabledRoles = {}
local enabledPages = {}

local function UpdateTitle(lbl, text)
    lbl:SetFont("TutorialTitle")
    lbl:SetText(text)
    lbl:SizeToContents()
    lbl:CenterHorizontal()
end

local function ShowTutorialPage(pnl, page)
    pnl:Clear()
    pnl:SetBackgroundColor(COLOR_BLACK)

    local titleLabel = vgui.Create("DLabel", pnl)

    if page <= #enabledPages then
        local pageInfo = enabledPages[page]
        UpdateTitle(titleLabel, pageInfo.title)
        pageInfo.body(pnl, titleLabel)
    else
        local role = enabledRoles[page - #enabledPages]
        local roleName = ROLE_STRINGS[role]
        UpdateTitle(titleLabel, roleName)

        -- Add the role icon next to the label
        local roleFileName = ROLE_STRINGS_SHORT[role]
        local roleIcon = vgui.Create("DImage", pnl)
        roleIcon:SetSize(16, 16)
        roleIcon:SetMaterial(ROLE_TAB_ICON_MATERIALS[roleFileName])
        roleIcon:MoveLeftOf(titleLabel)
        -- Center it vertically within the title bar and give it a little space from the role name
        roleIcon:SetPos(roleIcon:GetX() - 3, roleIcon:GetY() + 7)

        -- If nobody wants to handle this page themselves,
        if not HookCall("TTTTutorialRolePage", nil, role, pnl, titleLabel, roleIcon) then
            local roleText = HookCall("TTTTutorialRoleText", nil, role, titleLabel, roleIcon)

            local html = vgui.Create("DHTML", pnl)
            html:Dock(FILL)
            -- Leave a gap for the title at the top
            html:DockMargin(0, 30, 0, 0)

            -- Open the page
            local htmlData = "<div style='width: 100%; height: 93%;" .. fontStyle .. "; color: white;'>"

            -- If the role didn't provide details, use some generic info
            if not roleText or #roleText == 0 then
                htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'>This is some generic information about the " .. roleName .. " role because the role author hasn't defined specifics.</span>"

                -- Team
                htmlData = htmlData .. "<div style='margin-top: 5px;'>"
                    local roleTeam = player.GetRoleTeam(role, true)
                    local roleTeamString, roleTeamColor = GetRoleTeamInfo(roleTeam, true)
                    htmlData = htmlData .. "<span style='" .. fontStyle .. " color: white;'>Role Team: </span>"
                    htmlData = htmlData .. "<span style='" .. fontStyle .. " color: rgb(" .. roleTeamColor.r .. ", " .. roleTeamColor.g .. ", " .. roleTeamColor.b .. ");'>" .. roleTeamString .. "</span>"
                htmlData = htmlData .. "</div>"
            else
                htmlData = htmlData .. roleText
            end

            -- Allow other addons to add more information to this role's tutorial text
            local updatedHtml = HookCall("TTTTutorialRoleTextExtra", nil, role, titleLabel, roleIcon, htmlData)
            if updatedHtml and #updatedHtml > 0 then
                htmlData = updatedHtml
            end

            -- Close the page
            htmlData = htmlData .. "</div>"

            html:SetHTML(htmlData)
        end

        -- Allow other addons to add more information to this role's tutorial page
        HookCall("TTTTutorialRolePageExtra", nil, role, pnl, titleLabel, roleIcon)
    end
end

local function ShowRoleTutorial(role)
    local client = LocalPlayer()
    -- Always show the page for your role, even if it's not enabled
    if IsValid(client) and client:GetDisplayedRole() == role then return true end

    -- If the role can spawn, show the page
    if util.CanRoleSpawn(role) then return true end

    -- Otherwise check if there are special rules for this role
    if HookCall("TTTTutorialRoleEnabled", nil, role) then
        return true
    end
    return false
end

function HELPSCRN:CreateTutorial(parent)
    -- Get the list of enabled roles
    table.Empty(enabledRoles)
    for r = ROLE_INNOCENT, ROLE_MAX do
        if ShowRoleTutorial(r) then
            table.insert(enabledRoles, r)
        end
    end
    table.sort(enabledRoles, function(a, b)
        return ROLE_STRINGS[a] < ROLE_STRINGS[b]
    end)

    -- Get the list of enables pages
    table.Empty(enabledPages)
    for _, page in ipairs(tutorialPages) do
        if not page.enabled or page.enabled() then
            table.insert(enabledPages, page)
        end
    end

    maxPages = #enabledPages + #enabledRoles

    local bw, bh = 88, 30

    local tut = vgui.Create("DPanel", parent)
    tut:StretchToParent(0, 0, 0, 0)
    tut:SetVerticalScrollbarEnabled(false)
    tut:SetTall(330)

    tut.current = 1
    ShowTutorialPage(tut, tut.current)

    tut.PageSelect = vgui.Create("DComboBox", parent)
    tut.PageSelect:SetSize(bw * 2, bh)
    tut.PageSelect:MoveBelow(tut)
    tut.PageSelect:SetSortItems(false)
    for i = 1, maxPages do
        local name
        if i <= #enabledPages then
            name = enabledPages[i].title
        else
            local role = enabledRoles[i - #enabledPages]
            name = ROLE_STRINGS[role]
        end
        tut.PageSelect:AddChoice(name, i, i == 1)
    end

    tut.PageBar = vgui.Create("TTTProgressBar", parent)
    tut.PageBar:SetSize(198, bh)
    tut.PageBar:MoveBelow(tut)
    tut.PageBar:AlignLeft((bw * 2) + 5)
    tut.PageBar:SetMin(1)
    tut.PageBar:SetMax(maxPages)
    tut.PageBar:SetValue(1)
    tut.PageBar:SetColor(Color(0, 200, 0))

    -- fixing your panels...
    tut.PageBar.UpdateText = function(s)
        s.Label:SetText(Format("%i / %i", s.m_iValue, s.m_iMax))
        s:PerformLayout()
    end

    tut.PageBar:UpdateText()

    tut.NextButton = vgui.Create("DButton", parent)
    tut.NextButton:SetFont("Trebuchet22")
    tut.NextButton:SetSize(bw, bh)
    tut.NextButton:SetText(GetTranslation("next"))
    tut.NextButton:CopyPos(tut.PageBar)
    tut.NextButton:AlignRight(1)

    tut.RoleButton = vgui.Create("DButton", parent)
    tut.RoleButton:SetSize(24, bh)
    tut.RoleButton:SetText("")
    tut.RoleButton:SetImage("icon16/arrow_in.png")
    tut.RoleButton:SetTooltip(GetTranslation("help_tut_find_role"))
    tut.RoleButton:CopyPos(tut.PageBar)
    tut.RoleButton:MoveLeftOf(tut.NextButton)

    tut.PreviousButton = vgui.Create("DButton", parent)
    tut.PreviousButton:SetFont("Trebuchet22")
    tut.PreviousButton:SetSize(bw, bh)
    tut.PreviousButton:SetText(GetTranslation("prev"))
    tut.PreviousButton:CopyPos(tut.PageBar)
    tut.PreviousButton:MoveLeftOf(tut.RoleButton)

    tut.PageSelect.OnSelect = function(pnl, index, label, data)
        tut.current = data
        tut.PageBar:SetValue(tut.current)
        ShowTutorialPage(tut, tut.current)
    end

    tut.NextButton.DoClick = function()
        if tut.current < maxPages then
            tut.PageSelect:ChooseOptionID(tut.current + 1)
        end
    end

    tut.PreviousButton.DoClick = function()
        if tut.current > 1 then
            tut.PageSelect:ChooseOptionID(tut.current - 1)
        end
    end

    tut.RoleButton.DoClick = function()
        local client = LocalPlayer()
        if not IsValid(client) then return end

        local role = client:GetDisplayedRole()
        HELPSCRN:OpenRoleTutorial(role)
    end

    return tut
end

function HELPSCRN:OpenRoleTutorial(role)
    if role <= ROLE_NONE or role > ROLE_MAX then return end

    if hide_role:GetBool() then return end

    -- Open the window if it isn't already
    if not IsValid(dframe) then
        self:Show()
    end

    local page = nil
    for i = #enabledPages, maxPages do
        if role == enabledRoles[i - #enabledPages] then
            page = i
            break
        end
    end

    if not page then return end

    self.TutorialPanel.PageSelect:ChooseOptionID(page)
end

function HELPSCRN:CreateConfig(dsettings)
    --- Interface area

    local dgui = vgui.Create("DForm", dsettings)
    dgui:Dock(TOP)
    dgui:DockMargin(0, 0, 5, 10)
    dgui:SetName(GetTranslation("set_title_gui"))

    dgui:CheckBox(GetTranslation("set_tips"), "ttt_tips_enable")

    local cb = dgui:NumSlider(GetTranslation("set_startpopup"), "ttt_startpopup_duration", 0, 60, 0)
    if cb.Label then
        cb.Label:SetWrap(true)
    end
    cb:SetTooltip(GetTranslation("set_startpopup_tip"))

    cb = dgui:NumSlider(GetTranslation("set_cross_opacity"), "ttt_ironsights_crosshair_opacity", 0, 1, 1)
    if cb.Label then
        cb.Label:SetWrap(true)
    end
    cb:SetTooltip(GetTranslation("set_cross_opacity"))

    cb = dgui:NumSlider(GetTranslation("set_cross_brightness"), "ttt_crosshair_brightness", 0, 1, 1)
    if cb.Label then
        cb.Label:SetWrap(true)
    end

    cb = dgui:NumSlider(GetTranslation("set_cross_size"), "ttt_crosshair_size", 0.1, 3, 1)
    if cb.Label then
        cb.Label:SetWrap(true)
    end

    dgui:CheckBox(GetTranslation("set_cross_disable"), "ttt_disable_crosshair")

    dgui:CheckBox(GetTranslation("set_minimal_id"), "ttt_minimal_targetid")

    dgui:CheckBox(GetTranslation("set_healthlabel"), "ttt_health_label")

    cb = dgui:CheckBox(GetTranslation("set_lowsights"), "ttt_ironsights_lowered")
    cb:SetTooltip(GetTranslation("set_lowsights_tip"))

    cb = dgui:CheckBox(GetTranslation("set_fastsw"), "ttt_weaponswitcher_fast")
    cb:SetTooltip(GetTranslation("set_fastsw_tip"))

    cb = dgui:CheckBox(GetTranslation("set_fastsw_menu"), "ttt_weaponswitcher_displayfast")
    cb:SetTooltip(GetTranslation("set_fastswmenu_tip"))

    cb = dgui:CheckBox(GetTranslation("set_wswitch"), "ttt_weaponswitcher_stay")
    cb:SetTooltip(GetTranslation("set_wswitch_tip"))

    cb = dgui:CheckBox(GetTranslation("set_swselect"), "ttt_weaponswitcher_close")
    cb:SetTooltip(GetTranslation("set_swselect_tip"))

    dgui:CheckBox(GetTranslation("set_cues"), "ttt_cl_soundcues")

    cb = dgui:CheckBox(GetTranslation("set_msg_cue"), "ttt_cl_msg_soundcue")
    cb:SetTooltip(GetTranslation("set_msg_cue_tip"))

    cb = dgui:CheckBox(GetTranslation("set_raw_karma"), "ttt_show_raw_karma_value")
    cb:SetTooltip(GetTranslation("set_raw_karma_tip"))

    cb = dgui:CheckBox(GetTranslation("set_karma_total_pct"), "ttt_show_karma_total_pct")
    cb:SetTooltip(GetTranslation("set_karma_total_pct_tip"))

    cb = dgui:CheckBox(GetTranslation("set_hide_role"), "ttt_hide_role")
    cb:SetTooltip(GetTranslation("set_hide_role_tip"))

    cb = dgui:CheckBox(GetTranslation("set_hide_ammo"), "ttt_hide_ammo")
    cb:SetTooltip(GetTranslation("set_hide_ammo_tip"))

    cb = dgui:TextEntry(GetTranslation("set_radio_button"), "ttt_radio_button")
    cb:SetTooltip(GetTranslation("set_radio_button_tip"))

    cb = dgui:CheckBox(GetTranslation("set_bypass_culling"), "ttt_bypass_culling")
    cb:SetTooltip(GetTranslation("set_bypass_culling_tip"))

    local combo, _ = dgui:ComboBox(GetTranslation("set_distance_unit"), "ttt_distance_unit")
    combo:SetTooltip(GetTranslation("set_distance_unit_tip"))
    combo:SetSortItems(false)
    combo:AddChoice("None", 0)
    combo:AddChoice("Meters", 1)
    combo:AddChoice("Feet", 2)

    cb = dgui:TextEntry(GetTranslation("set_cheatsheat_hotkey"), "ttt_cheatsheat_hotkey")
    cb:SetTooltip(GetTranslation("set_cheatsheat_hotkey_tip"))

    HookCall("TTTSettingsConfigTabFields", nil, "Interface", dgui)

    dsettings:AddItem(dgui)

    --- Gameplay area

    local dplay = vgui.Create("DForm", dsettings)
    dplay:Dock(TOP)
    dplay:DockMargin(0, 0, 5, 10)
    dplay:SetName(GetTranslation("set_title_play"))

    cb = dplay:CheckBox(GetPTranslation("set_avoid_det", {detective = ROLE_STRINGS[ROLE_DETECTIVE]}), "ttt_avoid_detective")
    cb:SetTooltip(GetPTranslation("set_avoid_det_tip", {detective = ROLE_STRINGS[ROLE_DETECTIVE], traitor = ROLE_STRINGS[ROLE_TRAITOR]}))

    cb = dplay:CheckBox(GetTranslation("set_specmode"), "ttt_spectator_mode")
    cb:SetTooltip(GetTranslation("set_specmode_tip"))

    -- For some reason this one defaulted to on, unlike other checkboxes, so
    -- force it to the actual value of the cvar (which defaults to off)
    local mute = dplay:CheckBox(GetTranslation("set_mute"), "ttt_mute_team_check")
    mute:SetValue(GetConVar("ttt_mute_team_check"):GetBool())
    mute:SetTooltip(GetTranslation("set_mute_tip"))

    HookCall("TTTSettingsConfigTabFields", nil, "Gameplay", dplay)

    dsettings:AddItem(dplay)

    -- Color area

    if overrideModeCVar == nil then
        overrideModeCVar = GetConVar("ttt_color_mode_override")
    end

    -- Don't allow color config when the server is overriding the value
    if not overrideModeCVar or overrideModeCVar:GetString() == "none" then
        local dcolor = vgui.Create("DForm", dsettings)
        dcolor:Dock(TOP)
        dcolor:DockMargin(0, 0, 5, 10)
        dcolor:DoExpansion(false)
        dcolor:SetName(GetTranslation("set_color_mode"))

        local dcol = vgui.Create("DComboBox", dcolor)
        dcol:SetConVar("ttt_color_mode")
        dcol:SetSortItems(false)
        dcol:AddChoice("Default", "default")
        dcol:AddChoice("Simplified", "simple")
        dcol:AddChoice("Protanomaly", "protan")
        dcol:AddChoice("Deuteranomaly", "deutan")
        dcol:AddChoice("Tritanomaly", "tritan")
        dcol:AddChoice("Custom", "custom")

        dcol.OnSelect = function(idx, val, data)
            local mode = data -- For some reason it grabs the name and not the actual data so fix that here
            if mode == "Default" then mode = "default"
            elseif mode == "Simplified" then mode = "simple"
            elseif mode == "Protanomaly" then mode = "protan"
            elseif mode == "Deuteranomaly" then mode = "deutan"
            elseif mode == "Tritanomaly" then mode = "tritan"
            elseif mode == "Custom" then mode = "custom"
            end
            RunConsoleCommand("ttt_color_mode", mode)
            timer.Simple(0.5, function() UpdateRoleColours() end)
        end

        dcolor:AddItem(dcol)

        local dcolinn = vgui.Create("DColorMixer", dcolor)
        dcolinn:SetAlphaBar(false)
        dcolinn:SetWangs(false)
        dcolinn:SetPalette(false)
        dcolinn:SetLabel("Custom innocent color:")
        dcolinn:SetConVarR("ttt_custom_inn_color_r")
        dcolinn:SetConVarG("ttt_custom_inn_color_g")
        dcolinn:SetConVarB("ttt_custom_inn_color_b")
        dcolinn.ValueChanged = function(col)
            timer.Simple(0.5, function() UpdateRoleColours() end)
        end

        dcolor:AddItem(dcolinn)

        local dcolspecinn = vgui.Create("DColorMixer", dcolor)
        dcolspecinn:SetAlphaBar(false)
        dcolspecinn:SetWangs(false)
        dcolspecinn:SetPalette(false)
        dcolspecinn:SetLabel("Custom special innocent color:")
        dcolspecinn:SetConVarR("ttt_custom_spec_inn_color_r")
        dcolspecinn:SetConVarG("ttt_custom_spec_inn_color_g")
        dcolspecinn:SetConVarB("ttt_custom_spec_inn_color_b")
        dcolspecinn.ValueChanged = function(col)
            timer.Simple(0.5, function() UpdateRoleColours() end)
        end

        dcolor:AddItem(dcolspecinn)

        local dcoltra = vgui.Create("DColorMixer", dcolor)
        dcoltra:SetAlphaBar(false)
        dcoltra:SetWangs(false)
        dcoltra:SetPalette(false)
        dcoltra:SetLabel("Custom traitor color:")
        dcoltra:SetConVarR("ttt_custom_tra_color_r")
        dcoltra:SetConVarG("ttt_custom_tra_color_g")
        dcoltra:SetConVarB("ttt_custom_tra_color_b")
        dcoltra.ValueChanged = function(col)
            timer.Simple(0.5, function() UpdateRoleColours() end)
        end

        dcolor:AddItem(dcoltra)

        local dcolspectra = vgui.Create("DColorMixer", dcolor)
        dcolspectra:SetAlphaBar(false)
        dcolspectra:SetWangs(false)
        dcolspectra:SetPalette(false)
        dcolspectra:SetLabel("Custom special traitor color:")
        dcolspectra:SetConVarR("ttt_custom_spec_tra_color_r")
        dcolspectra:SetConVarG("ttt_custom_spec_tra_color_g")
        dcolspectra:SetConVarB("ttt_custom_spec_tra_color_b")
        dcolspectra.ValueChanged = function(col)
            timer.Simple(0.5, function() UpdateRoleColours() end)
        end

        dcolor:AddItem(dcolspectra)

        local dcoldet = vgui.Create("DColorMixer", dcolor)
        dcoldet:SetAlphaBar(false)
        dcoldet:SetWangs(false)
        dcoldet:SetPalette(false)
        dcoldet:SetLabel("Custom detective color:")
        dcoldet:SetConVarR("ttt_custom_det_color_r")
        dcoldet:SetConVarG("ttt_custom_det_color_g")
        dcoldet:SetConVarB("ttt_custom_det_color_b")
        dcoldet.ValueChanged = function(col)
            timer.Simple(0.5, function() UpdateRoleColours() end)
        end

        dcolor:AddItem(dcoldet)

        local dcolspecdet = vgui.Create("DColorMixer", dcolor)
        dcolspecdet:SetAlphaBar(false)
        dcolspecdet:SetWangs(false)
        dcolspecdet:SetPalette(false)
        dcolspecdet:SetLabel("Custom detective color:")
        dcolspecdet:SetConVarR("ttt_custom_spec_det_color_r")
        dcolspecdet:SetConVarG("ttt_custom_spec_det_color_g")
        dcolspecdet:SetConVarB("ttt_custom_spec_det_color_b")
        dcolspecdet.ValueChanged = function(col)
            timer.Simple(0.5, function() UpdateRoleColours() end)
        end

        dcolor:AddItem(dcolspecdet)

        local dcoljes = vgui.Create("DColorMixer", dcolor)
        dcoljes:SetAlphaBar(false)
        dcoljes:SetWangs(false)
        dcoljes:SetPalette(false)
        dcoljes:SetLabel("Custom jester color:")
        dcoljes:SetConVarR("ttt_custom_jes_color_r")
        dcoljes:SetConVarG("ttt_custom_jes_color_g")
        dcoljes:SetConVarB("ttt_custom_jes_color_b")
        dcoljes.ValueChanged = function(col)
            timer.Simple(0.5, function() UpdateRoleColours() end)
        end

        dcolor:AddItem(dcoljes)

        local dcolind = vgui.Create("DColorMixer", dcolor)
        dcolind:SetAlphaBar(false)
        dcolind:SetWangs(false)
        dcolind:SetPalette(false)
        dcolind:SetLabel("Custom independent color:")
        dcolind:SetConVarR("ttt_custom_ind_color_r")
        dcolind:SetConVarG("ttt_custom_ind_color_g")
        dcolind:SetConVarB("ttt_custom_ind_color_b")
        dcolind.ValueChanged = function(col)
            timer.Simple(0.5, function() UpdateRoleColours() end)
        end

        dcolor:AddItem(dcolind)

        local dcolmon = vgui.Create("DColorMixer", dcolor)
        dcolmon:SetAlphaBar(false)
        dcolmon:SetWangs(false)
        dcolmon:SetPalette(false)
        dcolmon:SetLabel("Custom monster color:")
        dcolmon:SetConVarR("ttt_custom_mon_color_r")
        dcolmon:SetConVarG("ttt_custom_mon_color_g")
        dcolmon:SetConVarB("ttt_custom_mon_color_b")
        dcolmon.ValueChanged = function(col)
            timer.Simple(0.5, function() UpdateRoleColours() end)
        end

        dcolor:AddItem(dcolmon)

        HookCall("TTTSettingsConfigTabFields", nil, "Color", dcolor)

        dsettings:AddItem(dcolor)
    end

    --- Language area

    local dlanguage = vgui.Create("DForm", dsettings)
    dlanguage:Dock(TOP)
    dlanguage:DockMargin(0, 0, 5, 10)
    dlanguage:DoExpansion(false)
    dlanguage:SetName(GetTranslation("set_title_lang"))

    local dlang = vgui.Create("DComboBox", dlanguage)
    dlang:SetConVar("ttt_language")

    dlang:AddChoice("Server default", "auto")
    for _, lang in pairs(LANG.GetLanguages()) do
        dlang:AddChoice(string.Capitalize(lang), lang)
    end
    -- Why is DComboBox not updating the cvar by default?
    dlang.OnSelect = function(idx, val, data)
        RunConsoleCommand("ttt_language", data)
    end
    dlang.Think = dlang.ConVarStringThink

    dlanguage:Help(GetTranslation("set_lang"))
    dlanguage:AddItem(dlang)

    HookCall("TTTSettingsConfigTabFields", nil, "Language", dlanguage)

    dsettings:AddItem(dlanguage)
end

local roleExpandState = {}
function HELPSCRN:CreateRoles(droles)
    -- Preprocess the roles so we can sort them by name later
    local enabled_roles = {}
    for r = ROLE_NONE + 1, ROLE_MAX do
        -- Skip disabled roles
        if not DEFAULT_ROLES[r] and not util.CanRoleSpawn(r) then continue end

        table.insert(enabled_roles, {role = r, role_string = ROLE_STRINGS[r]})
    end

    local has_section = false
    -- Add a section for each role that has settings, in alphabetical order
    for r, info in SortedPairsByMemberValue(enabled_roles, "role_string") do
        local drole = vgui.Create("DForm", droles)
        drole:Dock(TOP)
        drole:DockMargin(0, 0, 5, 10)
        drole:DoExpansion(roleExpandState[r] or false)
        drole:SetName(info.role_string)
        -- Keep track of the expanded state so you don't have to open it multiple times
        drole.OnToggle = function(panel, state)
            roleExpandState[r] = state
        end

        -- Only add a section for this role if something adds to the form
        local add_section = HookCall("TTTSettingsRolesTabSections", nil, info.role, drole)
        if add_section then
            has_section = true
            droles:AddItem(drole)
        else
            drole:Remove()
        end
    end

    return has_section
end