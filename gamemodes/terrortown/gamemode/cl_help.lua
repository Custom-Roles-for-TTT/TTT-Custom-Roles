---- Help screen

local concommand = concommand
local cvars = cvars
local file = file
local hook = hook
local ipairs = ipairs
local pairs = pairs
local surface = surface
local string = string
local table = table
local timer = timer
local vgui = vgui

local GetTranslation = LANG.GetTranslation
local GetPTranslation = LANG.GetParamTranslation

surface.CreateFont("TutorialTitle", {
    font = "Trebuchet MS",
    size = 30,
    weight = 900 })

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
CreateClientConVar("ttt_hide_role", "0", true, false)
CreateClientConVar("ttt_hide_ammo", "0", true, false)

HELPSCRN = {}

local dframe
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
    dbut.DoClick = function() dframe:Close() end

    local dtabs = vgui.Create("DPropertySheet", dframe)
    dtabs:SetPos(margin, margin * 2)
    dtabs:SetSize(w - margin * 2, h - margin * 3 - bh)

    local padding = dtabs:GetPadding()

    padding = padding * 2

    local tutparent = vgui.Create("DPanel", dtabs)
    tutparent:SetPaintBackground(false)
    tutparent:StretchToParent(margin, 0, 0, 0)

    self:CreateTutorial(tutparent)

    dtabs:AddSheet(GetTranslation("help_tut"), tutparent, "icon16/book_open.png", false, false, GetTranslation("help_tut_tip"))

    local dsettings = vgui.Create("DPanelList", dtabs)
    dsettings:StretchToParent(0, 0, padding, 0)
    dsettings:EnableVerticalScrollbar(true)
    dsettings:SetPadding(10)
    dsettings:SetSpacing(10)

    --- Interface area

    local dgui = vgui.Create("DForm", dsettings)
    dgui:SetName(GetTranslation("set_title_gui"))

    local cb = nil

    dgui:CheckBox(GetTranslation("set_tips"), "ttt_tips_enable")

    cb = dgui:NumSlider(GetTranslation("set_startpopup"), "ttt_startpopup_duration", 0, 60, 0)
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

    cb = dgui:CheckBox(GetTranslation("set_cues"), "ttt_cl_soundcues")

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

    dsettings:AddItem(dgui)

    local dcolor = vgui.Create("DForm", dsettings)
    dcolor:SetName(GetTranslation("set_color_mode"))
    dcolor:DoExpansion(false)

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

    dsettings:AddItem(dcolor)

    --- Gameplay area

    local dplay = vgui.Create("DForm", dsettings)
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

    dsettings:AddItem(dplay)

    --- Language area
    local dlanguage = vgui.Create("DForm", dsettings)
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

    dsettings:AddItem(dlanguage)

    dtabs:AddSheet(GetTranslation("help_settings"), dsettings, "icon16/wrench.png", false, false, GetTranslation("help_settings_tip"))

    -- BEM settings

    padding = dtabs:GetPadding()
    padding = padding * 2

    dsettings = vgui.Create("DPanelList", dtabs)
    dsettings:StretchToParent(0, 0, padding, 0)
    dsettings:EnableVerticalScrollbar(true)
    dsettings:SetPadding(10)
    dsettings:SetSpacing(10)

    -- info text
    local dlabel = vgui.Create("DLabel", dsettings)
    dlabel:SetText("All changes made here are clientside and will only apply to your own menu!")
    dlabel:SetTextColor(Color(0, 0, 0, 255))
    dsettings:AddItem(dlabel)

    -- layout section
    local dlayout = vgui.Create("DForm", dsettings)
    dlayout:SetName("Item List Layout")

    dlayout:NumSlider("Number of columns (def. 4)", "ttt_bem_cols", 1, 20, 0)
    dlayout:NumSlider("Number of rows (def. 5)", "ttt_bem_rows", 1, 20, 0)
    dlayout:NumSlider("Icon size (def. 64)", "ttt_bem_size", 32, 128, 0)

    dsettings:AddItem(dlayout)

    -- marker section
    local dmarker = vgui.Create("DForm", dsettings)
    dmarker:SetName("Item Marker Settings")

    dmarker:CheckBox("Show slot marker", "ttt_bem_marker_slot")
    dmarker:CheckBox("Show custom item marker", "ttt_bem_marker_custom")
    dmarker:CheckBox("Show favourite item marker", "ttt_bem_marker_fav")
    dmarker:CheckBox("Show loadout items", "ttt_show_loadout_equipment")

    dsettings:AddItem(dmarker)

    dtabs:AddSheet("BEM settings", dsettings, "icon16/cog.png", false, false, "Better Equipment Menu Settings")

    -- Hitmarkers Settings

    padding = dtabs:GetPadding()
    padding = padding * 2

    dsettings = vgui.Create("DPanelList", dtabs)
    dsettings:StretchToParent(0, 0, padding, 0)
    dsettings:EnableVerticalScrollbar(true)
    dsettings:SetPadding(10)
    dsettings:SetSpacing(10)

    dlabel = vgui.Create("DLabel", dsettings)
    dlabel:SetText("All changes made here are clientside and will only apply to your own menu!\nUse the !hmcolor command in chat to change the marker colors.\nUse the !hmcritcolor command in chat to change the color of critical hit markers.")
    dlabel:SetTextColor(Color(0, 0, 0, 255))
    dlabel:SizeToContents()
    dsettings:AddItem(dlabel)

    local dmarkers = vgui.Create("DForm", dsettings)
    dmarkers:SetName("Hitmarkers")

    dmarkers:CheckBox("Enabled", "hm_enabled")
    dmarkers:CheckBox("Show criticals", "hm_showcrits")
    dmarkers:CheckBox("Play hit sound", "hm_hitsound")

    dsettings:AddItem(dmarkers)

    dtabs:AddSheet("HM settings", dsettings, "icon16/cross.png", false, false, "Hitmarker settings")

    hook.Call("TTTSettingsTabs", GAMEMODE, dtabs)

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
        if file.Exists("materials/vgui/ttt/roles/" .. roleFileName .. "/tab_" .. roleFileName .. ".png", "GAME") then
            roleIcon:SetImage("vgui/ttt/roles/" .. roleFileName .. "/tab_" .. roleFileName .. ".png")
        else
            roleIcon:SetImage("vgui/ttt/tab_" .. roleFileName .. ".png")
        end
        roleIcon:MoveLeftOf(titleLabel)
        -- Center it vertically within the title bar and give it a little space from the role name
        roleIcon:SetPos(roleIcon:GetX() - 3, roleIcon:GetY() + 7)

        -- If nobody wants to handle this page themselves,
        if not hook.Call("TTTTutorialRolePage", nil, role, pnl, titleLabel, roleIcon) then
            local roleText = hook.Call("TTTTutorialRoleText", nil, role, titleLabel, roleIcon)

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
            local updatedHtml = hook.Call("TTTTutorialRoleTextExtra", nil, role, titleLabel, roleIcon, htmlData)
            if updatedHtml and #updatedHtml > 0 then
                htmlData = updatedHtml
            end

            -- Close the page
            htmlData = htmlData .. "</div>"

            html:SetHTML(htmlData)
        end

        -- Allow other addons to add more information to this role's tutorial page
        hook.Call("TTTTutorialRolePageExtra", nil, role, pnl, titleLabel, roleIcon)
    end
end

local function ShowRoleTutorial(role)
    -- If the role is enabled, show the page
    if DEFAULT_ROLES[role] then return true end
    if GetGlobalBool("ttt_" .. ROLE_STRINGS_RAW[role] .. "_enabled", false) then
        return true
    end

    -- Otherwise check if there are special rules for this role
    if hook.Call("TTTTutorialRoleEnabled", nil, role) then
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

    local pageSelect = vgui.Create("DComboBox", parent)
    pageSelect:SetSize(bw * 2, bh)
    pageSelect:MoveBelow(tut)
    pageSelect:SetSortItems(false)
    for i = 1, maxPages do
        local name
        if i <= #enabledPages then
            name = enabledPages[i].title
        else
            local role = enabledRoles[i - #enabledPages]
            name = ROLE_STRINGS[role]
        end
        pageSelect:AddChoice(name, i, i == 1)
    end

    local bar = vgui.Create("TTTProgressBar", parent)
    bar:SetSize(198, bh)
    bar:MoveBelow(tut)
    bar:AlignLeft((bw * 2) + 5)
    bar:SetMin(1)
    bar:SetMax(maxPages)
    bar:SetValue(1)
    bar:SetColor(Color(0, 200, 0))

    -- fixing your panels...
    bar.UpdateText = function(s)
        s.Label:SetText(Format("%i / %i", s.m_iValue, s.m_iMax))
        s:PerformLayout()
    end

    bar:UpdateText()

    local bnext = vgui.Create("DButton", parent)
    bnext:SetFont("Trebuchet22")
    bnext:SetSize(bw, bh)
    bnext:SetText(GetTranslation("next"))
    bnext:CopyPos(bar)
    bnext:AlignRight(1)

    local brole = vgui.Create("DButton", parent)
    brole:SetSize(24, bh)
    brole:SetText("")
    brole:SetImage("icon16/arrow_in.png")
    brole:SetTooltip(GetTranslation("help_tut_find_role"))
    brole:CopyPos(bar)
    brole:MoveLeftOf(bnext)

    local bprev = vgui.Create("DButton", parent)
    bprev:SetFont("Trebuchet22")
    bprev:SetSize(bw, bh)
    bprev:SetText(GetTranslation("prev"))
    bprev:CopyPos(bar)
    bprev:MoveLeftOf(brole)

    pageSelect.OnSelect = function(pnl, index, label, data)
        tut.current = data
        bar:SetValue(tut.current)
        ShowTutorialPage(tut, tut.current)
    end

    bnext.DoClick = function()
        if tut.current < maxPages then
            pageSelect:ChooseOptionID(tut.current + 1)
        end
    end

    bprev.DoClick = function()
        if tut.current > 1 then
            pageSelect:ChooseOptionID(tut.current - 1)
        end
    end

    brole.DoClick = function()
        local client = LocalPlayer()
        local role = client:GetRole()
        if not IsValid(client) or role <= ROLE_NONE or role > ROLE_MAX then return end

        local page = nil
        for i = #enabledPages, maxPages do
            if role == enabledRoles[i - #enabledPages] then
                page = i
                break
            end
        end

        if not page then return end

        pageSelect:ChooseOptionID(page)
    end
end
