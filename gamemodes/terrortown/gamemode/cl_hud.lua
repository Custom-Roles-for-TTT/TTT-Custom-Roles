-- HUD HUD HUD

HUD = {}

local surface = surface
local draw = draw
local math = math
local string = string

local GetTranslation = LANG.GetTranslation
local GetPTranslation = LANG.GetParamTranslation
local GetLang = LANG.GetUnsafeLanguageTable
local interp = string.Interp

local hide_role = false

-- Fonts
surface.CreateFont("TraitorState", {
    font = "Trebuchet24",
    size = 28,
    weight = 1000
})
surface.CreateFont("TraitorStateSmall", {
    font = "Trebuchet24",
    size = 24,
    weight = 1000
})
surface.CreateFont("TimeLeft", {
    font = "Trebuchet24",
    size = 24,
    weight = 800
})
surface.CreateFont("HealthAmmo", {
    font = "Trebuchet24",
    size = 24,
    weight = 750
})
surface.CreateFont("UseHintCaption", {
    font = "Trebuchet24",
    size = 24,
    weight = 750
})
surface.CreateFont("UseHint", {
    font = "Trebuchet24",
    size = 18,
    weight = 750
})
-- Color presets
local bg_colors = {
    background_main = Color(0, 0, 10, 200),
    noround = Color(100, 100, 100, 255),
    hidden = Color(75, 75, 75, 200)
};

local health_colors = {
    border = COLOR_WHITE,
    background = Color(100, 25, 25, 222),
    fill = Color(200, 50, 50, 255)
};

local overhealth_colors = {
    border = COLOR_WHITE,
    background = Color(0, 0, 0, 0),
    fill = Color(255, 150, 175, 255)
};

local extraoverhealth_colors = {
    border = COLOR_WHITE,
    background = Color(0, 0, 0, 0),
    fill = Color(255, 200, 255, 255)
};

local ammo_colors = {
    border = COLOR_WHITE,
    background = Color(100, 60, 0, 222),
    fill = Color(205, 155, 0, 255)
};

local sprint_colors = {
    border = COLOR_WHITE,
    background = Color(30, 60, 100, 222),
    fill = Color(75, 150, 255, 255)
};

local infection_colors = {
    border = COLOR_WHITE,
    background = Color(191, 91, 22, 222),
    fill = Color(255, 127, 39, 255)
};


-- Modified RoundedBox
local Tex_Corner8 = surface.GetTextureID("gui/corner8")
local function RoundedMeter(bs, x, y, w, h, color)
    surface.SetDrawColor(clr(color))

    surface.DrawRect(x + bs, y, w - bs * 2, h)
    surface.DrawRect(x, y + bs, bs, h - bs * 2)

    surface.SetTexture(Tex_Corner8)
    surface.DrawTexturedRectRotated(x + bs / 2, y + bs / 2, bs, bs, 0)
    surface.DrawTexturedRectRotated(x + bs / 2, y + h - bs / 2, bs, bs, 90)

    if w > 14 then
        surface.DrawRect(x + w - bs, y + bs, bs, h - bs * 2)
        surface.DrawTexturedRectRotated(x + w - bs / 2, y + bs / 2, bs, bs, 270)
        surface.DrawTexturedRectRotated(x + w - bs / 2, y + h - bs / 2, bs, bs, 180)
    else
        surface.DrawRect(x + math.max(w - bs, bs), y, bs / 2, h)
    end

end

---- The bar painting is loosely based on:
---- http://wiki.garrysmod.com/?title=Creating_a_HUD

-- Paints a graphical meter bar
function HUD:PaintBar(r, x, y, w, h, colors, value)
    -- Background
    -- slightly enlarged to make a subtle border
    draw.RoundedBox(8, x - 1, y - 1, w + 2, h + 2, colors.background)

    -- Fill
    local width = w * math.Clamp(value, 0, 1)

    if width > 0 then
        RoundedMeter(r, x, y, width, h, colors.fill)
    end
end

function HUD:PaintPowersHUD(powers, max_power, current_power, colors, title, subtitle)
    local margin = 10
    local width, height = 200, 25
    local x = ScrW() / 2 - width / 2
    local y = margin / 2 + height
    local power_percentage = current_power / max_power

    HUD:PaintBar(8, x, y, width, height, colors, power_percentage)

    local color = bg_colors.background_main

    draw.SimpleText(title, "HealthAmmo", ScrW() / 2, y, color, TEXT_ALIGN_CENTER)
    if subtitle and #subtitle > 0 then
        draw.SimpleText(subtitle, "TabLarge", ScrW() / 2, margin, COLOR_WHITE, TEXT_ALIGN_CENTER)
    end

    if powers and table.Count(powers) > 0 then
        local command_count = 0
        for _, p in pairs(powers) do
            if p > 0 then
                command_count = command_count + 1
            end
        end

        local current_command = 1
        for t, p in pairs(powers) do
            if p > 0 then
                local percentage = math.Round(100 * (p / max_power))
                draw.SimpleText(interp(t, { num = percentage }), "TabLarge", ScrW() / 4 + ((ScrW() / (2 * (command_count + 1))) * current_command), margin, current_power >= p and COLOR_GREEN or COLOR_RED, TEXT_ALIGN_CENTER)
                current_command = current_command + 1
            end
        end
    end
end

local roundstate_string = {
    [ROUND_WAIT] = "round_wait",
    [ROUND_PREP] = "round_prep",
    [ROUND_ACTIVE] = "round_active",
    [ROUND_POST] = "round_post"
};

-- Returns player's ammo information
local function GetAmmo(ply)
    local weap = ply:GetActiveWeapon()
    if not weap or not ply:Alive() then return -1 end

    local ammo_inv = weap:Ammo1() or 0
    local ammo_clip = weap:Clip1() or 0
    local ammo_max = weap.Primary.ClipSize or 0

    return ammo_clip, ammo_max, ammo_inv
end

local function DrawBg(x, y, width, height, client)
    -- Traitor area sizes
    local th = 30
    local tw = 170

    -- Adjust for these
    y = y - th
    height = height + th

    -- main bg area, invariant
    -- encompasses entire area
    draw.RoundedBox(8, x, y, width, height, bg_colors.background_main)

    -- main border, traitor based
    local col = ROLE_COLORS[client:GetRole()]
    if GAMEMODE.round_state ~= ROUND_ACTIVE then
        col = bg_colors.noround
    elseif hide_role then
        col = bg_colors.hidden
    end

    draw.RoundedBoxEx(8, x, y, tw, th, col, true, false, false, true)
end

function HUD:ShadowedText(text, font, x, y, color, xalign, yalign)
    draw.SimpleText(text, font, x + 2, y + 2, COLOR_BLACK, xalign, yalign)
    draw.SimpleText(text, font, x, y, color, xalign, yalign)
end

local margin = 10

-- Paint infection progress
local function InfectPaint(client)
    local L = GetLang()

    local width, height = 200, 25
    local x = ScrW() / 2 - width / 2
    local y = margin / 2 + height

    local infect_time = GetGlobalInt("ttt_parasite_infection_time", 90)
    local progress = client:GetNWInt("InfectionProgress", 0)
    local progress_percentage = progress / infect_time

    HUD:PaintBar(8, x, y, width, height, infection_colors, progress_percentage)

    local color = bg_colors.background_main

    draw.SimpleText(L.infect_title, "HealthAmmo", ScrW() / 2, y, color, TEXT_ALIGN_CENTER)
    draw.SimpleText(L.infect_help, "TabLarge", ScrW() / 2, margin, COLOR_WHITE, TEXT_ALIGN_CENTER)
end

-- Paint punch-o-meter
local function PunchPaint(client)
    local L = GetLang()
    local punch = client:GetNWFloat("specpunches", 0)

    local width, height = 200, 25
    local x = ScrW() / 2 - width / 2
    local y = margin / 2 + height

    HUD:PaintBar(8, x, y, width, height, ammo_colors, punch)

    local color = bg_colors.background_main

    draw.SimpleText(L.punch_title, "HealthAmmo", ScrW() / 2, y, color, TEXT_ALIGN_CENTER)
    draw.SimpleText(L.punch_help, "TabLarge", ScrW() / 2, margin, COLOR_WHITE, TEXT_ALIGN_CENTER)

    local bonus = client:GetNWInt("bonuspunches", 0)
    if bonus ~= 0 then
        local text
        if bonus < 0 then
            text = interp(L.punch_bonus, { num = bonus })
        else
            text = interp(L.punch_malus, { num = bonus })
        end

        draw.SimpleText(text, "TabLarge", ScrW() / 2, y * 2, COLOR_WHITE, TEXT_ALIGN_CENTER)
    end
end

local key_params = { usekey = Key("+use", "USE") }

local function SpecHUDPaint(client)
    local L = GetLang() -- for fast direct table lookups

    -- Draw round state
    local x = margin
    local height = 32
    local width = 250
    local round_y = ScrH() - height - margin

    -- move up a little on low resolutions to allow space for spectator hints
    if ScrW() < 1000 then round_y = round_y - 15 end

    local time_x = x + 170
    local time_y = round_y + 4

    draw.RoundedBox(8, x, round_y, width, height, bg_colors.background_main)
    draw.RoundedBox(8, x, round_y, time_x - x, height, bg_colors.noround)

    local text = L[roundstate_string[GAMEMODE.round_state]]
    HUD:ShadowedText(text, "TraitorState", x + margin, round_y, COLOR_WHITE)

    -- Draw round/prep/post time remaining
    text = util.SimpleTime(math.max(0, GetGlobalFloat("ttt_round_end", 0) - CurTime()), "%02i:%02i")
    HUD:ShadowedText(text, "TimeLeft", time_x + margin, time_y, COLOR_WHITE)

    local tgt = client:GetObserverTarget()
    if client:ShouldShowSpectatorHUD() then
        hook.Run("TTTSpectatorShowHUD", client, tgt)
    elseif client:GetNWBool("Infecting") then
        InfectPaint(client)
    elseif IsPlayer(tgt) then
        HUD:ShadowedText(tgt:Nick(), "TimeLeft", ScrW() / 2, margin, COLOR_WHITE, TEXT_ALIGN_CENTER)
    elseif IsValid(tgt) and tgt:GetNWEntity("spec_owner", nil) == client then
        PunchPaint(client)
    else
        HUD:ShadowedText(interp(L.spec_help, key_params), "TabLarge", ScrW() / 2, margin, COLOR_WHITE, TEXT_ALIGN_CENTER)
    end
end

local ttt_health_label = CreateClientConVar("ttt_health_label", "0", true)

local function InfoPaint(client)
    local L = GetLang()

    local width = 250
    local height = 94

    local x = margin
    local y = ScrH() - margin - height

    if ConVarExists("ttt_hide_role") then
        hide_role = GetConVar("ttt_hide_role"):GetBool()
    end

    DrawBg(x, y, width, height, client)

    local bar_height = 25
    local bar_width = width - (margin * 2)

    -- Draw health
    local health = math.max(0, client:Health())
    local maxHealth = math.max(0, client:GetMaxHealth())
    local health_y = y + margin

    HUD:PaintBar(8, x + margin, health_y, bar_width, bar_height, health_colors, health / maxHealth)
    HUD:PaintBar(8, x + margin, health_y, bar_width, bar_height, overhealth_colors, math.max(0, health - maxHealth) / maxHealth)
    HUD:PaintBar(8, x + margin, health_y, bar_width, bar_height, extraoverhealth_colors, math.max(0, health - (2 * maxHealth)) / maxHealth)

    HUD:ShadowedText(tostring(health), "HealthAmmo", bar_width, health_y, COLOR_WHITE, TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT)

    if ttt_health_label:GetBool() then
        local health_status = util.HealthToString(health, client:GetMaxHealth())
        draw.SimpleText(L[health_status], "TabLarge", x + margin * 2, health_y + bar_height / 2, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Draw ammo
    if client:GetActiveWeapon().Primary then
        local ammo_clip, ammo_max, ammo_inv = GetAmmo(client)
        if ammo_clip ~= -1 then
            local ammo_y = health_y + bar_height + margin
            HUD:PaintBar(8, x + margin, ammo_y, bar_width, bar_height, ammo_colors, ammo_clip / ammo_max)
            local text = string.format("%i + %02i", ammo_clip, ammo_inv)

            HUD:ShadowedText(text, "HealthAmmo", bar_width, ammo_y, COLOR_WHITE, TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT)
        end
    end

    local sprint_y = health_y + (2 * (bar_height + margin))
    bar_height = 4

    HUD:PaintBar(2, x + margin, sprint_y, bar_width, bar_height, sprint_colors, client:GetNWFloat("sprintMeter", 0) / 100)

    -- Draw traitor state
    local round_state = GAMEMODE.round_state

    local traitor_y = y - 30
    local text = nil
    if round_state == ROUND_ACTIVE then
        if hide_role then
            text = GetTranslation("hidden")
        else
            text = client:GetRoleString()
        end
    else
        text = L[roundstate_string[round_state]]
    end

    if #text > 10 then
        HUD:ShadowedText(text, "TraitorStateSmall", x + margin + 74, traitor_y + 2, COLOR_WHITE, TEXT_ALIGN_CENTER)
    else
        HUD:ShadowedText(text, "TraitorState", x + margin + 74, traitor_y, COLOR_WHITE, TEXT_ALIGN_CENTER)
    end

    -- Draw round time
    local is_haste = HasteMode() and round_state == ROUND_ACTIVE
    local is_traitor = client:IsActiveTraitorTeam() or client:IsActiveMonsterTeam()

    local endtime = GetGlobalFloat("ttt_round_end", 0) - CurTime()

    local font = "TimeLeft"
    local color = COLOR_WHITE
    local rx = x + margin + 170
    local ry = traitor_y + 3

    -- Time displays differently depending on whether haste mode is on,
    -- whether the player is traitor or not, and whether it is overtime.
    if is_haste then
        local hastetime = GetGlobalFloat("ttt_haste_end", 0) - CurTime()
        if hastetime < 0 then
            if (not is_traitor) or (math.ceil(CurTime()) % 7 <= 2) then
                -- innocent or blinking "overtime"
                text = L.overtime
                font = "Trebuchet18"

                -- need to hack the position a little because of the font switch
                ry = ry + 5
                rx = rx - 3
            else
                -- traitor and not blinking "overtime" right now, so standard endtime display
                text = util.SimpleTime(math.max(0, endtime), "%02i:%02i")
                color = COLOR_RED
            end
        else
            -- still in starting period
            local t = hastetime
            if is_traitor and math.ceil(CurTime()) % 6 < 2 then
                t = endtime
                color = COLOR_RED
            end
            text = util.SimpleTime(math.max(0, t), "%02i:%02i")
        end
    else
        -- bog standard time when haste mode is off (or round not active)
        text = util.SimpleTime(math.max(0, endtime), "%02i:%02i")
    end

    HUD:ShadowedText(text, font, rx, ry, color)

    local label_top = 140
    local label_left = 36
    if client:HasEquipmentItem(EQUIP_RADAR) then
        label_top = label_top + 20
    end
    if client:HasEquipmentItem(EQUIP_DISGUISE) and client:GetNWBool("disguised", false) then
        label_top = label_top + 20
    end

    -- Allow other addons to add stuff to the player info HUD
    hook.Run("TTTHUDInfoPaint", client, label_left, label_top)

    if client:IsDetectiveLike() and not client:IsDetectiveTeam() then
        surface.SetFont("TabLarge")
        surface.SetTextColor(255, 255, 255, 230)

        text = GetPTranslation("detective_promotion_hud", { detective = ROLE_STRINGS[ROLE_DETECTIVE] })
        local _, h = surface.GetTextSize(text)

        surface.SetTextPos(label_left, ScrH() - label_top - h)
        surface.DrawText(text)
    end
end

-- Paints player status HUD element in the bottom left
function GM:HUDPaint()
    local client = LocalPlayer()

    if hook.Call("HUDShouldDraw", GAMEMODE, "TTTTargetID") then
        hook.Call("HUDDrawTargetID", GAMEMODE)
    end

    if hook.Call("HUDShouldDraw", GAMEMODE, "TTTMStack") then
        MSTACK:Draw(client)
    end

    if (not client:Alive()) or client:Team() == TEAM_SPEC then
        if hook.Call("HUDShouldDraw", GAMEMODE, "TTTSpecHUD") then
            SpecHUDPaint(client)
        end

        return
    end

    if hook.Call("HUDShouldDraw", GAMEMODE, "TTTRadar") then
        RADAR:Draw(client)
    end

    if hook.Call("HUDShouldDraw", GAMEMODE, "TTTTButton") then
        TBHUD:Draw(client)
    end

    if hook.Call("HUDShouldDraw", GAMEMODE, "TTTWSwitch") then
        WSWITCH:Draw(client)
    end

    if hook.Call("HUDShouldDraw", GAMEMODE, "TTTVoice") then
        VOICE.Draw(client)
    end

    if hook.Call("HUDShouldDraw", GAMEMODE, "TTTDisguise") then
        DISGUISE.Draw(client)
    end

    if hook.Call("HUDShouldDraw", GAMEMODE, "TTTPickupHistory") then
        hook.Call("HUDDrawPickupHistory", GAMEMODE)
    end

    -- Draw bottom left info panel
    if hook.Call("HUDShouldDraw", GAMEMODE, "TTTInfoPanel") then
        InfoPaint(client)
    end
end

-- Hide the standard HUD stuff
local hud = { ["CHudHealth"] = true, ["CHudBattery"] = true, ["CHudAmmo"] = true, ["CHudSecondaryAmmo"] = true }
function GM:HUDShouldDraw(name)
    if hud[name] then return false end

    return self.BaseClass.HUDShouldDraw(self, name)
end

