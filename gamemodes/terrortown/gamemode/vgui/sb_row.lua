---- Scoreboard player score row, based on sandbox version

include("sb_info.lua")

local draw = draw
local hook = hook
local ipairs = ipairs
local IsValid = IsValid
local pairs = pairs
local surface = surface
local table = table
local timer = timer
local vgui = vgui

local CallHook = hook.Call
local RunHook = hook.Run
local GetTranslation = LANG.GetTranslation
local MathClamp = math.Clamp
local MathMax = math.max
local MathMin = math.min
local MathRound = math.Round
local MathSin = math.sin

SB_ROW_HEIGHT = 24 --16

local PANEL = {}

function PANEL:Init()
    -- cannot create info card until player state is known
    self.info = nil

    self.open = false

    self.cols = {}
    self:AddColumn(GetTranslation("sb_ping"), function(ply) return ply:Ping() end)
    if GetConVar("ttt_scoreboard_deaths"):GetBool() then
        self:AddColumn(GetTranslation("sb_deaths"), function(ply) return ply:Deaths() end)
    end
    if GetConVar("ttt_scoreboard_score"):GetBool() then
        self:AddColumn(GetTranslation("sb_score"), function(ply) return ply:Frags() end)
    end

    if KARMA.IsEnabled() then
        self:AddColumn(GetTranslation("sb_karma"), function(ply)
            if GetConVar("ttt_show_raw_karma_value"):GetBool() then
                return MathRound(ply:GetBaseKarma())
            elseif GetConVar("ttt_show_karma_total_pct"):GetBool() then
                local k = ply:GetBaseKarma()
                local max = GetGlobalInt("ttt_karma_max", 1000)
                local pct = MathRound(MathClamp(k / max, 0.1, 1.0) * 100)
                return pct .. "%"
            else
                local dmgpct = 100
                if ply:GetBaseKarma() < 1000 then
                    local k = ply:GetBaseKarma() - 1000
                    if GetGlobalBool("ttt_karma_strict", false) then
                        dmgpct = MathRound(MathClamp(1 + (0.0007 * k) + (-0.000002 * (k ^ 2)), 0.1, 1.0) * 100)
                    elseif GetGlobalBool("ttt_karma_lenient", false) then
                        dmgpct = MathRound(MathClamp(1 + (0.0005 * k) + (-0.0000005 * (k ^ 2)), 0.1, 1.0) * 100)
                    else
                        dmgpct = MathRound(MathClamp(1 + (-0.0000025 * (k ^ 2)), 0.1, 1.0) * 100)
                    end
                end
                return dmgpct .. "%"
            end
        end)
    end

    -- Let hooks add their custom columns
    CallHook("TTTScoreboardColumns", nil, self)

    for _, c in ipairs(self.cols) do
        c:SetMouseInputEnabled(false)
    end

    self.tag = vgui.Create("DLabel", self)
    self.tag:SetText("")
    self.tag:SetMouseInputEnabled(false)

    self.sresult = vgui.Create("DImage", self)
    self.sresult:SetSize(16, 16)
    self.sresult:SetMouseInputEnabled(false)

    self.avatar = vgui.Create("AvatarImage", self)
    self.avatar:SetSize(SB_ROW_HEIGHT, SB_ROW_HEIGHT)
    self.avatar:SetMouseInputEnabled(false)

    self.nick = vgui.Create("DLabel", self)
    self.nick:SetMouseInputEnabled(false)

    self.voice = vgui.Create("DImageButton", self)
    self.voice:SetSize(16, 16)

    self:SetCursor("hand")
end

function PANEL:AddColumn(label, func, width, _, _)
    local lbl = vgui.Create("DLabel", self)
    lbl.GetPlayerText = func
    lbl.IsHeading = false
    lbl.Width = width or 50 -- Retain compatibility with existing code

    table.insert(self.cols, lbl)
    return lbl
end

-- Mirror sb_main, of which it and this file both call using the
--    TTTScoreboardColumns hook, but it is useless in this file
-- Exists only so the hook wont return an error if it tries to
--    use the AddFakeColumn function of `sb_main`, which would
--    cause this file to raise a `function not found` error or others
function PANEL:AddFakeColumn() end

local namecolor = {
    default = COLOR_WHITE,
    admin = Color(220, 180, 0, 255),
    dev = Color(100, 240, 105, 255)
}

local defaultcolor = Color(0, 0, 0, 0)

function GM:TTTScoreboardColorForPlayer(ply)
    if not IsValid(ply) then return namecolor.default end

    if ply:SteamID() == "STEAM_0:0:1963640" then
        return namecolor.dev
    elseif (ply:IsAdmin() or ply:IsSuperAdmin()) and GetGlobalBool("ttt_highlight_admins", true) then
        return namecolor.admin
    end
    return namecolor.default
end

local function GetGlitchedRole(p, glitchMode)
    -- Use the player's role if they are a traitor, otherwise this is a glitch and we should use their fake role
    local role = p:IsTraitorTeam() and p:GetRole() or p:GetNWInt("GlitchBluff", ROLE_TRAITOR)
    -- Only hide vanilla traitors
    if glitchMode == GLITCH_SHOW_AS_TRAITOR then
        if role == ROLE_TRAITOR then
            return ROLE_NONE, ROLE_TRAITOR
        end
        return role, nil
    -- Hide all traitors, but show whether they are special or not based on the color
    elseif glitchMode == GLITCH_SHOW_AS_SPECIAL_TRAITOR then
        return ROLE_NONE, role
    end

    -- Hide all traitors, period
    return ROLE_NONE, ROLE_TRAITOR
end

function GM:TTTScoreboardRowColorForPlayer(ply)
    if not IsValid(ply) or GetRoundState() == ROUND_WAIT or GetRoundState() == ROUND_PREP then return defaultcolor end

    local client = LocalPlayer()
    if (ScoreGroup(ply) == GROUP_SEARCHED and ply.search_result and ply.search_result.role > ROLE_NONE) or ply == client then
        return ply:GetRole()
    end

    if ply:GetDetectiveLike() then
        return ply:GetDisplayedRole()
    elseif ply:ShouldRevealRoleWhenActive() and ply:IsRoleActive() then
        return ply:GetRole()
    end

    local hideBeggar = ply:GetNWBool("WasBeggar", false) and not client:ShouldRevealBeggar(ply)
    local hideBodysnatcher = ply:GetNWBool("WasBodysnatcher", false) and not client:ShouldRevealBodysnatcher(ply)
    local showJester = (ply:ShouldActLikeJester() or ((ply:IsTraitor() or ply:IsInnocent()) and hideBeggar) or hideBodysnatcher) and not client:ShouldHideJesters()

    if client:IsTraitorTeam() then
        if showJester then
            return ROLE_JESTER
        elseif ply:IsTraitorTeam() then
            return ply:GetRole()
        elseif ply:IsGlitch() then
            if client:IsZombie() then
                return ROLE_ZOMBIE
            else
                return ply:GetNWInt("GlitchBluff", ROLE_TRAITOR)
            end
        end
    elseif client:IsIndependentTeam() then
        if showJester and cvars.Bool("ttt_" .. ROLE_STRINGS_RAW[client:GetRole()] .. "_can_see_jesters", false) then
            return ROLE_JESTER
        end
    elseif client:IsMonsterTeam() then
        if showJester then
            return ROLE_JESTER
        elseif ply:IsMonsterTeam() then
            return ply:GetRole()
        end
    end

    return defaultcolor
end

local function ColorForPlayer(ply)
    if IsValid(ply) then
        local c = RunHook("TTTScoreboardColorForPlayer", ply)

        -- verify that we got a proper color
        if c and istable(c) and c.r and c.b and c.g and c.a then
            return c
        else
            ErrorNoHalt("TTTScoreboardColorForPlayer hook returned something that isn't a color!\n")
        end
    end
    return namecolor.default
end

local function DrawFlashingBorder(width, role)
    surface.SetDrawColor(ColorAlpha(ROLE_COLORS[role], MathRound(MathSin(RealTime() * 8) / 2 + 0.5) * 20))
    surface.DrawRect(0, 0, width, SB_ROW_HEIGHT)
    surface.SetDrawColor(ROLE_COLORS_DARK[role])
    surface.DrawOutlinedRect(SB_ROW_HEIGHT, 0, width - SB_ROW_HEIGHT, SB_ROW_HEIGHT)
    surface.DrawOutlinedRect(1 + SB_ROW_HEIGHT, 1, width - 2 - SB_ROW_HEIGHT, SB_ROW_HEIGHT - 2)
end

function PANEL:Paint(width, height)
    if not IsValid(self.Player) then return end

    --   if ( self.Player:GetFriendStatus() == "friend" ) then
    --      color = Color( 236, 181, 113, 255 )
    --   end

    local ply = self.Player
    local c = RunHook("TTTScoreboardRowColorForPlayer", ply)

    -- Use the default color for players without roles
    if type(c) == "number" and c <= ROLE_NONE then
        c = defaultcolor
    end

    local client = LocalPlayer()
    local roleStr = ""
    local role = c
    if c ~= defaultcolor then
        local color = nil

        if client:IsTraitorTeam() then
            if GetGlobalBool("ttt_glitch_round", false) and (ply:IsTraitorTeam() or (ply:IsGlitch() and not GetGlobalBool("ttt_zombie_round", false))) and client ~= ply then
                local glitch_role, color_role = GetGlitchedRole(ply, GetConVar("ttt_glitch_mode"):GetInt())
                role = glitch_role
                if color_role then
                    color = ROLE_COLORS_SCOREBOARD[color_role]
                else
                    color = ROLE_COLORS_SCOREBOARD[role]
                end
            elseif ply:IsImpersonator() then
                if ply:IsRoleActive() and GetConVar("ttt_impersonator_use_detective_icon"):GetBool() then
                    role = ROLE_DETECTIVE
                end
                color = ROLE_COLORS_SCOREBOARD[ROLE_IMPERSONATOR]
            end
        end

        -- Swap the deputy/impersonator icons depending on which settings are enabled
        -- Only do this if we haven't set a value above
        if not color and ply:IsDetectiveLike() then
            if ply:IsDetectiveTeam() then
                local disp_role, changed = ply:GetDisplayedRole()
                -- If the displayed role was changed, use it for the color but use the question mark for the icon
                if changed then
                    color = ROLE_COLORS_SCOREBOARD[ROLE_DETECTIVE]
                    role = ROLE_NONE
                else
                    role = disp_role
                end
            elseif GetConVar("ttt_deputy_use_detective_icon"):GetBool() then
                role = ROLE_DETECTIVE
            else
                role = ROLE_DEPUTY
            end
        end

        c = color or ROLE_COLORS_SCOREBOARD[role]
        -- Show the question mark icon for jesters who haven't been searched
        if role == ROLE_JESTER and not ply:GetNWBool("body_searched", false) then
            roleStr = ROLE_STRINGS_SHORT[ROLE_NONE]
        else
            roleStr = ROLE_STRINGS_SHORT[role]
        end

        if ply:ShouldRevealRoleWhenActive() and ply:IsRoleActive() then
            c = ROLE_COLORS_SCOREBOARD[role]
            roleStr = ROLE_STRINGS_SHORT[role]
        end
    end

    -- Allow external addons (like new roles) to manipulate how a player appears on the scoreboard
    local new_color, new_role_str, flash_role = CallHook("TTTScoreboardPlayerRole", nil, ply, client, c, roleStr)
    if new_color then c = new_color end
    if new_role_str then roleStr = new_role_str end

    if c then
        surface.SetDrawColor(c)
    end
    surface.DrawRect(0, 0, width, SB_ROW_HEIGHT)

    if roleStr and ROLE_TAB_ICON_MATERIALS[roleStr] then
        self.sresult:SetMaterial(ROLE_TAB_ICON_MATERIALS[roleStr])
        self.sresult:SetVisible(true)
    else
        self.sresult:SetVisible(false)
    end

    if GetRoundState() >= ROUND_ACTIVE and flash_role and flash_role > ROLE_NONE and flash_role <= ROLE_MAX then
        DrawFlashingBorder(width, flash_role)
    end

    if ply == client then
        surface.SetDrawColor(200, 200, 200, MathClamp(MathSin(RealTime() * 2) * 50, 0, 100))
        surface.DrawRect(0, 0, width, SB_ROW_HEIGHT)
    end

    return true
end

function PANEL:SetPlayer(ply)
    self.Player = ply
    self.avatar:SetPlayer(ply)

    if not self.info then
        local g = ScoreGroup(ply)
        if g == GROUP_TERROR and ply ~= LocalPlayer() then
            self.info = vgui.Create("TTTScorePlayerInfoTags", self)
            self.info:SetPlayer(ply)

            self:InvalidateLayout()
        elseif g == GROUP_SEARCHED or g == GROUP_NOTFOUND then
            self.info = vgui.Create("TTTScorePlayerInfoSearch", self)
            self.info:SetPlayer(ply)
            self:InvalidateLayout()
        end
    else
        self.info:SetPlayer(ply)

        self:InvalidateLayout()
    end

    self.voice.DoClick = function()
        if IsValid(ply) and ply ~= LocalPlayer() then
            ply:SetMuted(not ply:IsMuted())
        end
    end

    self.voice.DoRightClick = function()
        if IsValid(ply) and ply ~= LocalPlayer() then
           self:ShowMicVolumeSlider()
        end
     end

    self:UpdatePlayerData()
end

function PANEL:GetPlayer() return self.Player end

function PANEL:UpdatePlayerData(force)
    if not IsValid(self.Player) then return end

    local ply = self.Player
    for i = 1, #self.cols do
        -- Set text from function, passing the label along so stuff like text
        -- color can be changed
        self.cols[i]:SetText(self.cols[i].GetPlayerText(ply, self.cols[i]))
    end

    local client = LocalPlayer()
    self.nick:SetText(ply:Nick())
    if GetRoundState() >= ROUND_ACTIVE then
        local nick_override = CallHook("TTTScoreboardPlayerName", nil, ply, client, self.nick:GetText())
        if nick_override then self.nick:SetText(nick_override) end
    end

    self.nick:SizeToContents()
    self.nick:SetTextColor(ColorForPlayer(ply))

    local ptag = ply.sb_tag
    if ScoreGroup(ply) ~= GROUP_TERROR then
        ptag = nil
    end

    self.tag:SetText(ptag and GetTranslation(ptag.txt) or "")
    self.tag:SetTextColor(ptag and ptag.color or COLOR_WHITE)

    -- cols are likely to need re-centering
    self:LayoutColumns()

    if self.info then
        self.info:UpdatePlayerData(force)
    end

    if self.Player ~= client then
        local muted = self.Player:IsMuted()
        self.voice:SetImage(muted and "icon16/sound_mute.png" or "icon16/sound.png")
    else
        self.voice:Hide()
    end
end

function PANEL:ApplySchemeSettings()
    for _, v in pairs(self.cols) do
        v:SetFont("treb_small")
        v:SetTextColor(COLOR_WHITE)
    end

    self.nick:SetFont("treb_small")
    self.nick:SetTextColor(ColorForPlayer(self.Player))

    local ptag = self.Player and self.Player.sb_tag
    self.tag:SetTextColor(ptag and ptag.color or COLOR_WHITE)
    self.tag:SetFont("treb_small")

    self.sresult:SetImage("icon16/magnifier.png")
    self.sresult:SetImageColor(COLOR_WHITE)
end

function PANEL:LayoutColumns()
    local cx = self:GetWide()
    for k, v in ipairs(self.cols) do
        v:SizeToContents()
        cx = cx - v.Width
        v:SetPos(cx - v:GetWide() / 2, (SB_ROW_HEIGHT - v:GetTall()) / 2)
    end

    cx = cx - 70
    self.sresult:SetPos(cx - 8, (SB_ROW_HEIGHT - 16) / 2)

    self.tag:SizeToContents()
    cx = cx - (self.tag:GetWide() / 2) - 50
    self.tag:SetPos(cx - self.tag:GetWide() / 2, (SB_ROW_HEIGHT - self.tag:GetTall()) / 2)
end

function PANEL:PerformLayout()
    self.avatar:SetPos(0, 0)
    self.avatar:SetSize(SB_ROW_HEIGHT, SB_ROW_HEIGHT)

    local fw = sboard_panel.ply_frame:GetWide()
    self:SetWide(sboard_panel.ply_frame.scroll.Enabled and fw - 16 or fw)

    if not self.open then
        self:SetSize(self:GetWide(), SB_ROW_HEIGHT)

        if self.info then self.info:SetVisible(false) end
    elseif self.info then
        self:SetSize(self:GetWide(), 100 + SB_ROW_HEIGHT)

        self.info:SetVisible(true)
        self.info:SetPos(5, SB_ROW_HEIGHT + 5)
        self.info:SetSize(self:GetWide(), 100)
        self.info:PerformLayout()

        self:SetSize(self:GetWide(), SB_ROW_HEIGHT + self.info:GetTall())
    end

    self.nick:SizeToContents()

    self.nick:SetPos(SB_ROW_HEIGHT + 10, (SB_ROW_HEIGHT - self.nick:GetTall()) / 2)

    self:LayoutColumns()

    self.voice:SetVisible(not self.open)
    self.voice:SetSize(16, 16)
    self.voice:DockMargin(4, 4, 4, 4)
    self.voice:Dock(RIGHT)
end

function PANEL:DoClick(x, y)
    self:SetOpen(not self.open)
end

function PANEL:SetOpen(o)
    if self.open then
        surface.PlaySound("ui/buttonclickrelease.wav")
    else
        surface.PlaySound("ui/buttonclick.wav")
    end

    self.open = o

    self:PerformLayout()
    self:GetParent():PerformLayout()
    sboard_panel:PerformLayout()
end

function PANEL:DoRightClick()
    local menu = DermaMenu()
    menu.Player = self:GetPlayer()

    local close = CallHook("TTTScoreboardMenu", nil, menu)
    if close then
        menu:Remove()
        return
    end

    menu:Open()
end

function PANEL:ShowMicVolumeSlider()
    local width = 300
    local height = 50
    local padding = 10

    local sliderHeight = 16
    local sliderDisplayHeight = 8

    local x = MathMax(gui.MouseX() - width, 0)
    local y = MathMin(gui.MouseY(), ScrH() - height)

    local currentPlayerVolume = self:GetPlayer():GetVoiceVolumeScale()
    currentPlayerVolume = currentPlayerVolume ~= nil and currentPlayerVolume or 1

    -- Frame for the slider
    local frame = vgui.Create("DFrame", self)
    frame:SetPos(x, y)
    frame:SetSize(width, height)
    frame:MakePopup()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:SetSizable(false)
    frame.Paint = function(s, w, h)
        draw.RoundedBox(5, 0, 0, w, h, Color(24, 25, 28, 255))
    end

    -- Automatically close after 10 seconds (something may have gone wrong)
    timer.Simple(10, function() if IsValid(frame) then frame:Close() end end)

    -- "Player volume"
    local label = vgui.Create("DLabel", frame)
    label:SetPos(padding, padding)
    label:SetFont("cool_small")
    label:SetSize(width - padding * 2, 20)
    label:SetColor(COLOR_WHITE)
    label:SetText(LANG.GetTranslation("sb_playervolume"))

    -- Slider
    local slider = vgui.Create("DSlider", frame)
    slider:SetHeight(sliderHeight)
    slider:Dock(TOP)
    slider:DockMargin(padding, 0, padding, 0)
    slider:SetSlideX(currentPlayerVolume)
    slider:SetLockY(0.5)
    slider.TranslateValues = function(s, sx, sy)
        if IsValid(self:GetPlayer()) then self:GetPlayer():SetVoiceVolumeScale(sx) end
        return sx, sy
    end

    -- Close the slider panel once the player has selected a volume
    slider.OnMouseReleased = function(panel, mcode) frame:Close() end
    slider.Knob.OnMouseReleased = function(panel, mcode) frame:Close() end

    -- Slider rendering
    -- Render slider bar
    slider.Paint = function(s, w, h)
        local volumePercent = slider:GetSlideX()

        -- Filled in box
        draw.RoundedBox(5, 0, sliderDisplayHeight / 2, w * volumePercent, sliderDisplayHeight, Color(200, 46, 46, 255))

        -- Grey box
        draw.RoundedBox(5, w * volumePercent, sliderDisplayHeight / 2, w * (1 - volumePercent), sliderDisplayHeight, Color(79, 84, 92, 255))
    end

    -- Render slider "knob" & text
    slider.Knob.Paint = function(s, w, h)
        if slider:IsEditing() then
            local textValue = MathRound(slider:GetSlideX() * 100) .. "%"
            local textPadding = 5

            -- The position of the text and size of rounded box are not relative to the text size. May cause problems if font size changes
            draw.RoundedBox(
                5, -- Radius
                -sliderHeight * 0.5 - textPadding, -- X
                -25, -- Y
                sliderHeight * 2 + textPadding * 2, -- Width
                sliderHeight + textPadding * 2, -- Height
                Color(52, 54, 57, 255)
            )
            draw.DrawText(textValue, "cool_small", sliderHeight / 2, -20, COLOR_WHITE, TEXT_ALIGN_CENTER)
        end

        draw.RoundedBox(100, 0, 0, sliderHeight, sliderHeight, COLOR_WHITE)
    end
 end

vgui.Register("TTTScorePlayerRow", PANEL, "DButton")
