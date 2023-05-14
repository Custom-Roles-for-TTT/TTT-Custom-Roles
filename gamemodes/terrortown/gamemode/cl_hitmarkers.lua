local hook = hook
local net = net
local pairs = pairs
local string = string
local surface = surface
local util = util
local vgui = vgui

local AddHook = hook.Add
local GetTranslation = LANG.GetTranslation
local HookCall = hook.Call
local MathApproach = math.Approach
local StringLower = string.lower
local StringExplode = string.Explode

-- Config menu
hook.Add("Initialize", "Hitmarkers_Initialize", function()
    LANG.AddToLanguage("english", "set_title_hitmarkers", "Hitmarkers settings")
    LANG.AddToLanguage("english", "set_label_hitmarkers", [[All changes made here are clientside and will only apply to your own menu!
Use the !hmcolor command in chat to change the marker colors.
Use the !hmcritcolor command in chat to change the color of critical hit markers.]])
    LANG.AddToLanguage("english", "set_hitmarkers_convar_enabled", "Enabled")
    LANG.AddToLanguage("english", "set_hitmarkers_convar_showcrits", "Show criticals")
    LANG.AddToLanguage("english", "set_hitmarkers_convar_hitsound", "Play hit sound")
end)

hook.Add("TTTSettingsConfigTabSections", "Hitmarkers_TTTSettingsConfigTabSections", function(dsettings)
    local dmarkers = vgui.Create("DForm", dsettings)
    dmarkers:Dock(TOP)
    dmarkers:DockMargin(0, 0, 5, 10)
    dmarkers:DoExpansion(false)
    dmarkers:SetName(GetTranslation("set_title_hitmarkers"))

    local dlabel = vgui.Create("DLabel", dmarkers)
    dlabel:SetText(GetTranslation("set_label_hitmarkers"))
    dlabel:SetTextColor(Color(0, 0, 0, 255))
    dlabel:SizeToContents()
    dmarkers:AddItem(dlabel)

    dmarkers:CheckBox(GetTranslation("set_hitmarkers_convar_enabled"), "hm_enabled")
    dmarkers:CheckBox(GetTranslation("set_hitmarkers_convar_showcrits"), "hm_showcrits")
    dmarkers:CheckBox(GetTranslation("set_hitmarkers_convar_hitsound"), "hm_hitsound")

    HookCall("TTTSettingsConfigTabFields", nil, "Hitmarkers", dmarkers)

    dsettings:AddItem(dmarkers)
end)

-- Hit Markers
-- Creator: Exho
local hm_toggle = CreateClientConVar("hm_enabled", "1", true, true)
local hm_type = CreateClientConVar("hm_hitmarkertype", "lines", true, true)
local hm_color = CreateClientConVar("hm_hitmarkercolor", "255, 255, 255", true, true)
local hm_crit = CreateClientConVar("hm_showcrits", "1", true, true)
local hm_critcolor = CreateClientConVar("hm_hitmarkercritcolor", "255, 0, 0", true, true)
local hm_sound = CreateClientConVar("hm_hitsound", "0", true, true)
local hm_DrawHitM = false
local hm_LastHitCrit = false
local hm_CanPlayS = true
local hm_Alpha = 0

local function GrabColor() -- Used for retrieving the console color
    local coltable = StringExplode(",", hm_color:GetString())
    local newcol = {}

    for k, v in pairs(coltable) do
        v = tonumber(v)
        if v == nil then -- Fixes missing values
            coltable[k] = 0
        end
    end
    newcol[1], newcol[2], newcol[3] = coltable[1] or 0, coltable[2] or 0, coltable[3] or 0 -- Fixes missing keys
    return Color(newcol[1], newcol[2], newcol[3]) -- Returns the finished color
end

local function GrabCritColor() -- Used for retrieving the console color
    local coltable = StringExplode(",", hm_critcolor:GetString())
    local newcol = {}

    for k, v in pairs(coltable) do
        v = tonumber(v)
        if v == nil then -- Fixes missing values
            coltable[k] = 0
        end
    end
    newcol[1], newcol[2], newcol[3] = coltable[1] or 0, coltable[2] or 0, coltable[3] or 0 -- Fixes missing keys
    return Color(newcol[1], newcol[2], newcol[3]) -- Returns the finished color
end

net.Receive("TTT_OpenMixer", function() -- Receive the server message
    local crit = net.ReadBool()

    -- Creating the color mixer panel
    local frame = vgui.Create("DFrame")
    if crit then
        frame:SetTitle("Hitmarker Critical Color Config")
    else
        frame:SetTitle("Hitmarker Color Config")
    end
    frame:SetSize(300, 400)
    frame:Center()
    frame:MakePopup()

    local colMix = vgui.Create("DColorMixer", frame)
    colMix:Dock(TOP)
    colMix:SetPalette(true)
    colMix:SetAlphaBar(false)
    colMix:SetWangs(false)
    -- Sets the default color to your current one
    if crit then
        colMix:SetColor(GrabCritColor())
    else
        colMix:SetColor(GrabColor())
    end

    local button = vgui.Create("DButton", frame)
    button:SetText("Set Color")
    button:SetSize(150, 70)
    button:SetPos(70, 290)
    button.DoClick = function(b) -- Concatenate your choices together and set the color
        local colors = colMix:GetColor()
        local colstring = tostring(colors.r .. ", " .. colors.g .. ", " .. colors.b)
        if crit then
            RunConsoleCommand("hm_hitmarkercritcolor", colstring)
        else
            RunConsoleCommand("hm_hitmarkercolor", colstring)
        end
    end
end)

net.Receive("TTT_DrawHitMarker", function()
    hm_DrawHitM = true
    hm_CanPlayS = true
    if net.ReadBool() then
        hm_LastHitCrit = true
    else
        hm_LastHitCrit = false
    end
    hm_Alpha = 255
end)

net.Receive("TTT_CreateBlood", function()
    local pos = net.ReadVector()
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetScale(1)
    util.Effect("bloodimpact", effect)
end)

AddHook("HUDPaint", "HitmarkerDrawer", function()
    if hm_toggle:GetBool() == false then return end -- Enables/Disables the hitmarkers
    if hm_Alpha == 0 then hm_DrawHitM = false hm_CanPlayS = true end -- Removes them after they decay

    if hm_DrawHitM == true then
        if hm_CanPlayS and hm_sound:GetBool() == true then
            surface.PlaySound("hitmarkers/mlghit.wav")
            hm_CanPlayS = false
        end

        local x = ScrW() / 2
        local y = ScrH() / 2

        hm_Alpha = MathApproach(hm_Alpha, 0, 5)
        local col = GrabColor()
        if hm_LastHitCrit and hm_crit:GetBool() then
            col = GrabCritColor()
        end
        col.a = hm_Alpha
        surface.SetDrawColor(col)

        local sel = StringLower(hm_type:GetString())
        -- The drawing part of the hitmarkers and the various types you can choose
        if sel == "lines" then
            surface.DrawLine(x - 6, y - 5, x - 11, y - 10)
            surface.DrawLine(x + 5, y - 5, x + 10, y - 10)
            surface.DrawLine(x - 6, y + 5, x - 11, y + 10)
            surface.DrawLine(x + 5, y + 5, x + 10, y + 10)
        elseif sel == "sidesqr_lines" then
            surface.DrawLine(x - 15, y, x, y + 15)
            surface.DrawLine(x + 15, y, x, y - 15)
            surface.DrawLine(x, y + 15, x + 15, y)
            surface.DrawLine(x, y - 15, x - 15, y)
            surface.DrawLine(x - 5, y - 5, x - 10, y - 10)
            surface.DrawLine(x + 5, y - 5, x + 10, y - 10)
            surface.DrawLine(x - 5, y + 5, x - 10, y + 10)
            surface.DrawLine(x + 5, y + 5, x + 10, y + 10)
        elseif sel == "sqr_rot" then
            surface.DrawLine(x - 15, y, x, y + 15)
            surface.DrawLine(x + 15, y, x, y - 15)
            surface.DrawLine(x, y + 15, x + 15, y)
            surface.DrawLine(x, y - 15, x - 15, y)
        else -- Defaults to 'lines' in case of an incorrect type
            surface.DrawLine(x - 6, y - 5, x - 11, y - 10)
            surface.DrawLine(x + 5, y - 5, x + 10, y - 10)
            surface.DrawLine(x - 6, y + 5, x - 11, y + 10)
            surface.DrawLine(x + 5, y + 5, x + 10, y + 10)
        end
    end
end)