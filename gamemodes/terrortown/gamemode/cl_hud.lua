-- HUD HUD HUD

CRHUD = {}

local pairs = pairs
local surface = surface
local table = table
local util = util

local CallHook = hook.Call
local RunHook = hook.Run
local GetTranslation = LANG.GetTranslation
local GetLang = LANG.GetUnsafeLanguageTable
local MathMax = math.max
local MathClamp = math.Clamp
local MathRound = math.Round
local MathCeil = math.ceil
local MathRand = math.Rand
local MathAbs = math.abs
local TableCount = table.Count
local interp = string.Interp
local format = string.format

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
        surface.DrawRect(x + MathMax(w - bs, bs), y, bs / 2, h)
    end

end

---- The bar painting is loosely based on:
---- http://wiki.garrysmod.com/?title=Creating_a_HUD

-- Paints a graphical meter bar
function CRHUD:PaintBar(r, x, y, w, h, colors, value)
    -- Background
    -- slightly enlarged to make a subtle border
    draw.RoundedBox(8, x - 1, y - 1, w + 2, h + 2, colors.background)

    -- Fill
    local width = w * MathClamp(value, 0, 1)

    if width > 0 then
        RoundedMeter(r, x, y, width, h, colors.fill)
    end
end

function CRHUD:PaintPowersHUD(powers, max_power, current_power, colors, title, subtitle)
    local margin = 10
    local width, height = 200, 25
    local x = ScrW() / 2 - width / 2
    local y = margin / 2 + height
    local power_percentage = current_power / max_power

    CRHUD:PaintBar(8, x, y, width, height, colors, power_percentage)

    local color = bg_colors.background_main

    draw.SimpleText(title, "HealthAmmo", ScrW() / 2, y, color, TEXT_ALIGN_CENTER)
    if subtitle and #subtitle > 0 then
        draw.SimpleText(subtitle, "TabLarge", ScrW() / 2, margin, COLOR_WHITE, TEXT_ALIGN_CENTER)
    end

    if powers and TableCount(powers) > 0 then
        local command_count = 0
        for _, p in pairs(powers) do
            if p > 0 then
                command_count = command_count + 1
            end
        end

        local current_command = 1
        for t, p in pairs(powers) do
            if p > 0 then
                local percentage = MathRound(100 * (p / max_power))
                draw.SimpleText(interp(t, { num = percentage }), "TabLarge", ScrW() / 4 + ((ScrW() / (2 * (command_count + 1))) * current_command), margin, current_power >= p and COLOR_GREEN or COLOR_RED, TEXT_ALIGN_CENTER)
                current_command = current_command + 1
            end
        end
    end
end

function CRHUD:PaintProgressBar(x, y, width, color, heading, progress, segments, titles, m)
    heading = heading or ""
    progress = progress or 1
    segments = segments or 1
    titles = titles or {}
    m = m or 10

    local left = x - width / 2
    local height = 20

    surface.SetFont("TabLarge")
    surface.SetTextColor(255, 255, 255, 180)
    surface.SetTextPos(left + 3, y - height - 15)
    surface.DrawText(heading)

    local r, g, b, a = color:Unpack()
    surface.SetDrawColor(r, g, b, a)

    if segments == 1 then
        surface.DrawOutlinedRect(left, y - height, width, height)
        surface.DrawRect(left, y - height, width * progress, height)
    elseif segments > 1 then
        local segmentWidth = (width - m * (segments - 1)) / segments
        for segment = 0, segments - 1 do
            local segmentProgress = math.Clamp(progress * segments - segment, 0, 1)
            surface.DrawOutlinedRect(left + (segmentWidth + m) * segment, y - height, segmentWidth, height)
            surface.DrawRect(left + (segmentWidth + m) * segment, y - height, segmentWidth * segmentProgress, height)
        end
        if #titles ~= segments then
            if #titles ~= 0 then
                ErrorNoHalt("Number of titles does not match the number of segments.")
            end
        else
            for segment = 0, segments - 1 do
                local offset = (segmentWidth - surface.GetTextSize(titles[segment + 1])) / 2
                surface.SetTextPos(left + (segmentWidth + m) * segment + offset, y - height + 3)
                surface.DrawText(titles[segment + 1])
            end
        end
    end
end

-- Generates a random coordinate on the bottom of the player's screen within one of 5 regions so that the particles can't clump together.
local function GenerateStatusEffectParticlePos(index)
    local segmentWidth = (ScrW() - 100) / 5
    local x = 50 + segmentWidth * (index - 1) + MathRand(0, segmentWidth)
    local y = MathRand(ScrH() - 150, ScrH() - 50)
    return x, y
end

local statusEffects = {}
function CRHUD:PaintStatusEffect(shouldPaint, color, material, identifier)
    if not statusEffects[identifier] then
        statusEffects[identifier] = {alpha=0, particles=nil, color=nil}
    end
    if not statusEffects[identifier].particles then
        statusEffects[identifier].particles = { --We split lifetime evenly and vary the order so they dont spawn in a line.
            {x=0, y=0, lifetime=0.4},
            {x=0, y=0, lifetime=1.2},
            {x=0, y=0, lifetime=1.6},
            {x=0, y=0, lifetime=0.8},
            {x=0, y=0, lifetime=2}
        }
        for i = 1, #statusEffects[identifier].particles do
            statusEffects[identifier].particles[i].x, statusEffects[identifier].particles[i].y = GenerateStatusEffectParticlePos(i)
        end
    end

    if shouldPaint and statusEffects[identifier].alpha < 1 then -- Slowly increase alpha until it reaches 1 if we should paint
        statusEffects[identifier].alpha = statusEffects[identifier].alpha + 0.01
    elseif statusEffects[identifier].alpha > 0 then -- Slowly decrease alpha until it reaches 0 if we shouldn't paint
        statusEffects[identifier].alpha = statusEffects[identifier].alpha - 0.01
    end
    statusEffects[identifier].alpha = MathClamp(statusEffects[identifier].alpha, 0, 1)

    if statusEffects[identifier].alpha > 0 then
        statusEffects[identifier].color = { -- This table is used to determine the color of the tint applied to the screen. It maxes out at 5% opacity and scales according to the current alpha value so that it fades in and out smoothly.
            ["$pp_colour_addr"] = color.r/255 * statusEffects[identifier].alpha * 0.05,
            ["$pp_colour_addg"] = color.g/255 * statusEffects[identifier].alpha * 0.05,
            ["$pp_colour_addb"] = color.b/255 * statusEffects[identifier].alpha * 0.05,
            ["$pp_colour_brightness"] = 0,
            ["$pp_colour_contrast"] = 1,
            ["$pp_colour_colour"] = 1,
            ["$pp_colour_mulr"] = 0,
            ["$pp_colour_mulg"] = 0,
            ["$pp_colour_mulb"] = 0
        }

        for i = 1, #statusEffects[identifier].particles do
            statusEffects[identifier].particles[i].lifetime = statusEffects[identifier].particles[i].lifetime - 0.01
            if statusEffects[identifier].particles[i].lifetime <= 0 then -- When a particle's lifetime reaches zero we reset it and move it to a new location
                statusEffects[identifier].particles[i].lifetime = 2
                statusEffects[identifier].particles[i].x, statusEffects[identifier].particles[i].y = GenerateStatusEffectParticlePos(i)
            end
            statusEffects[identifier].particles[i].y = statusEffects[identifier].particles[i].y - 0.25 -- Particles slowly move up over time
            local alpha = (1 - MathAbs(1 - statusEffects[identifier].particles[i].lifetime)) * statusEffects[identifier].alpha * 255 -- The alpha value of each particle fades in and out depending on remaining lifetime and reaches it's peak when lifetime is equal to 1. This is also scaled by the overall alpha value of the effect.
            surface.SetDrawColor(color.r, color.g, color.b, alpha)
            surface.SetMaterial(material)
            surface.DrawTexturedRect(statusEffects[identifier].particles[i].x, statusEffects[identifier].particles[i].y, 50, 50)
        end
    end
end

hook.Add("RenderScreenspaceEffects", "CRStatusEffects_RenderScreenspaceEffects", function()
    for _, effect in pairs(statusEffects) do
        if effect.alpha > 0 then
            DrawColorModify(effect.color)
        end
    end
end)

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

    local ammo_inv = weap.Ammo1 and weap:Ammo1() or 0
    local ammo_clip = weap.Clip1 and weap:Clip1() or 0
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
    local col = ROLE_COLORS[client:GetDisplayedRole()]
    if GAMEMODE.round_state ~= ROUND_ACTIVE then
        col = bg_colors.noround
    elseif hide_role then
        col = bg_colors.hidden
    end

    draw.RoundedBoxEx(8, x, y, tw, th, col, true, false, false, true)
end

function CRHUD:ShadowedText(text, font, x, y, color, xalign, yalign)
    draw.SimpleText(text, font, x + 2, y + 2, COLOR_BLACK, xalign, yalign)
    draw.SimpleText(text, font, x, y, color, xalign, yalign)
end

local margin = 10

-- Paint punch-o-meter
local function PunchPaint(client)
    local L = GetLang()
    local punch = client:GetNWFloat("specpunches", 0)

    local width, height = 200, 25
    local x = ScrW() / 2 - width / 2
    local y = margin / 2 + height

    CRHUD:PaintBar(8, x, y, width, height, ammo_colors, punch)

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
    CRHUD:ShadowedText(text, "TraitorState", x + margin, round_y, COLOR_WHITE)

    -- Draw round/prep/post time remaining
    text = util.SimpleTime(MathMax(0, GetGlobalFloat("ttt_round_end", 0) - CurTime()), "%02i:%02i")
    CRHUD:ShadowedText(text, "TimeLeft", time_x + margin, time_y, COLOR_WHITE)

    local tgt = client:GetObserverTarget()
    if client:ShouldShowSpectatorHUD() then
        CallHook("TTTSpectatorShowHUD", nil, client, tgt)
    elseif IsPlayer(tgt) then
        CRHUD:ShadowedText(tgt:Nick(), "TimeLeft", ScrW() / 2, margin, COLOR_WHITE, TEXT_ALIGN_CENTER)
    elseif IsValid(tgt) and tgt:GetNWEntity("spec_owner", nil) == client then
        PunchPaint(client)
    else
        CRHUD:ShadowedText(interp(L.spec_help, key_params), "TabLarge", ScrW() / 2, margin, COLOR_WHITE, TEXT_ALIGN_CENTER)
    end
end

local ttt_health_label = CreateClientConVar("ttt_health_label", "0", true)

local armor_tex = surface.GetTextureID("vgui/ttt/equip/armor")
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
    local health = MathMax(0, client:Health())
    local maxHealth = MathMax(0, client:GetMaxHealth())
    local health_y = y + margin

    CRHUD:PaintBar(8, x + margin, health_y, bar_width, bar_height, health_colors, health / maxHealth)
    CRHUD:PaintBar(8, x + margin, health_y, bar_width, bar_height, overhealth_colors, MathMax(0, health - maxHealth) / maxHealth)
    CRHUD:PaintBar(8, x + margin, health_y, bar_width, bar_height, extraoverhealth_colors, MathMax(0, health - (2 * maxHealth)) / maxHealth)

    CRHUD:ShadowedText(tostring(health), "HealthAmmo", bar_width, health_y, COLOR_WHITE, TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT)

    local health_offset = 0
    if client:HasEquipmentItem(EQUIP_ARMOR) then
        surface.SetTexture(armor_tex)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(x + margin + 5, health_y + 5, 16, 16)

        -- Move the rest of the health information it over
        health_offset = margin + 5
    end

    if ttt_health_label:GetBool() then
        local health_status = util.HealthToString(health, client:GetMaxHealth())
        draw.SimpleText(L[health_status], "TabLarge", x + health_offset + margin * 2, health_y + bar_height / 2, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Draw ammo
    if client:GetActiveWeapon().Primary and not GetConVar("ttt_hide_ammo"):GetBool() then
        local ammo_clip, ammo_max, ammo_inv = GetAmmo(client)
        if ammo_clip ~= -1 then
            local ammo_y = health_y + bar_height + margin
            CRHUD:PaintBar(8, x + margin, ammo_y, bar_width, bar_height, ammo_colors, ammo_clip / ammo_max)
            local text = format("%i + %02i", ammo_clip, ammo_inv)

            CRHUD:ShadowedText(text, "HealthAmmo", bar_width, ammo_y, COLOR_WHITE, TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT)
        end
    end

    -- Sprint stamina
    if GetGlobalBool("ttt_sprint_enabled", true) then
        local sprint_y = health_y + (2 * (bar_height + margin))
        bar_height = 4

        CRHUD:PaintBar(2, x + margin, sprint_y, bar_width, bar_height, sprint_colors, client:GetNWFloat("sprintMeter", 0) / 100)
    end

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
        CRHUD:ShadowedText(text, "TraitorStateSmall", x + margin + 74, traitor_y + 2, COLOR_WHITE, TEXT_ALIGN_CENTER)
    else
        CRHUD:ShadowedText(text, "TraitorState", x + margin + 74, traitor_y, COLOR_WHITE, TEXT_ALIGN_CENTER)
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
            if (not is_traitor) or (MathCeil(CurTime()) % 7 <= 2) then
                -- innocent or blinking "overtime"
                text = L.overtime
                font = "Trebuchet18"

                -- need to hack the position a little because of the font switch
                ry = ry + 5
                rx = rx - 3
            else
                -- traitor and not blinking "overtime" right now, so standard endtime display
                text = util.SimpleTime(MathMax(0, endtime), "%02i:%02i")
                color = COLOR_RED
            end
        else
            -- still in starting period
            local t = hastetime
            if is_traitor and MathCeil(CurTime()) % 6 < 2 then
                t = endtime
                color = COLOR_RED
            end
            text = util.SimpleTime(MathMax(0, t), "%02i:%02i")
        end
    else
        -- bog standard time when haste mode is off (or round not active)
        text = util.SimpleTime(MathMax(0, endtime), "%02i:%02i")
    end

    CRHUD:ShadowedText(text, font, rx, ry, color)

    local label_top = 140
    local label_left = 36
    if client:HasEquipmentItem(EQUIP_RADAR) then
        label_top = label_top + 20
    end
    if client:HasEquipmentItem(EQUIP_DISGUISE) and client:GetNWBool("disguised", false) then
        label_top = label_top + 20
    end

    -- Allow other addons to add stuff to the player info HUD
    local active_labels = {}
    CallHook("TTTHUDInfoPaint", nil, client, label_left, label_top, active_labels)
end

-- Paints player status HUD element in the bottom left
function GM:HUDPaint()
    local client = LocalPlayer()

    if RunHook("HUDShouldDraw", "TTTTargetID") then
        RunHook("HUDDrawTargetID")
    end

    if RunHook("HUDShouldDraw", "TTTMStack") then
        MSTACK:Draw(client)
    end

    if (not client:Alive()) or client:Team() == TEAM_SPEC then
        if RunHook("HUDShouldDraw", "TTTSpecHUD") then
            SpecHUDPaint(client)
        end

        return
    end

    if RunHook("HUDShouldDraw", "TTTRadar") then
        RADAR:Draw(client)
    end

    if RunHook("HUDShouldDraw", "TTTTButton") then
        TBHUD:Draw(client)
    end

    if RunHook("HUDShouldDraw", "TTTWSwitch") then
        WSWITCH:Draw(client)
    end

    if RunHook("HUDShouldDraw", "TTTVoice") then
        VOICE.Draw(client)
    end

    if RunHook("HUDShouldDraw", "TTTDisguise") then
        DISGUISE.Draw(client)
    end

    if RunHook("HUDShouldDraw", "TTTPickupHistory") then
        RunHook("HUDDrawPickupHistory")
    end

    -- Draw bottom left info panel
    if RunHook("HUDShouldDraw", "TTTInfoPanel") then
        InfoPaint(client)
    end
end

-- Hide the standard HUD stuff
local hud = {
    -- Stuff we replace
    ["CHudHealth"] = true,
    ["CHudAmmo"] = true,
    ["CHudSecondaryAmmo"] = true,
    -- Stuff we don't want to show
    ["CHudBattery"] = true,
    ["CHudSuitPower"] = true,
    -- Annoying damage stuff
    ["CHudPoisonDamageIndicator"] = true,
    -- This one handles a lot of things related to on-screen effects for damage. Things like:
    -- 1. The poison yellow screen flash (that doesn't happen to everyone, for some reason)
    -- 2. The high-damage red screen flash (left, right, or full-screen based on direction)
    -- 3. The death red screen flash
    -- Given that there are mods to disable this, if needed, and there are more benefits to it being enabled,
    -- we don't disable it but leave it here for documentation purposes
    --["CHudDamageIndicator"] = true
}
function GM:HUDShouldDraw(name)
    if hud[name] then return false end

    return self.BaseClass.HUDShouldDraw(self, name)
end

