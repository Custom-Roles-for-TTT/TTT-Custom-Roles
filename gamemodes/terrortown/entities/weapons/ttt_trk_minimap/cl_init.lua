include("shared.lua")

local hook = hook
local math = math
local player = player
local surface = surface
local draw = draw
local table = table

local MathMax = math.max
local MathRad = math.rad
local MathCos = math.cos
local MathSin = math.sin
local MathSqrt = math.sqrt

local DrawRoundedBox = draw.RoundedBox

local SurfaceSetDrawColor = surface.SetDrawColor
local SurfaceDrawCircle = surface.DrawCircle
local SurfaceSetFont = surface.SetFont
local SurfaceSetTextColor = surface.SetTextColor
local SurfaceSetTextPos = surface.SetTextPos
local SurfaceDrawText = surface.DrawText
local SurfaceGetTextSize = surface.GetTextSize
local SurfaceDrawTexturedRectRotated = surface.DrawTexturedRectRotated

local PlayerIterator = player.Iterator

local tracker_minimap_scale          = CreateClientConVar("ttt_tracker_minimap_scale",          "1", true, false, "Overall scale multiplier for the minimap", 0.1, 3)
local tracker_minimap_lock_north     = CreateClientConVar("ttt_tracker_minimap_lock_north",     "0", true, false, "Whether the minimap is locked north or rotates with the player", 0, 1)
local tracker_minimap_show_cardinals = CreateClientConVar("ttt_tracker_minimap_show_cardinals", "2", true, false, "Cardinal direction labels to show: none (0), North only (1), all (2)", 0, 2)

local tracker_minimap_range_mult     = GetConVar("ttt_tracker_minimap_range_multiplier")
local tracker_minimap_show_colours   = GetConVar("ttt_tracker_minimap_show_colors")
local tracker_minimap_show_facing    = GetConVar("ttt_tracker_minimap_show_facing")
local tracker_minimap_show_outside   = GetConVar("ttt_tracker_minimap_show_outside_range")
local tracker_minimap_show_names     = GetConVar("ttt_tracker_minimap_show_names")
local tracker_minimap_allow_enlarge  = GetConVar("ttt_tracker_minimap_allow_enlarge")

hook.Add("Initialize", "Tracker_Minimap_Initialize_Lang", function()
    LANG.AddToLanguage("english", "item_trk_minimap",      "Minimap")
    LANG.AddToLanguage("english", "item_trk_minimap_desc", [[A minimap that shows the positions of all other players relative to you.

Player icon color will match the player's footprint color and show the direction each player is facing.]])
    LANG.AddToLanguage("english", "equip_tooltip_trackminimap", "Minimap control")
end)

local BASE_RADIUS         = 135
local BASE_MARGIN         = 14
local BASE_ARROW_W        = 17
local BASE_ARROW_H        = 21
local BASE_CIRCLE_R       = 9
local BASE_FONT_SIZE      = 14
local BASE_CARDINAL_SIZE  = 22
local BASE_RANGE_UNITS    = 2000

local MINIMAP_BG_COLOUR   = Color(0, 0, 0, 200)
local MINIMAP_RING_COLOUR = Color(180, 180, 180, 200)
local SELF_COLOUR         = Color(255, 255, 255, 255)
local CARDINAL_COLOUR     = Color(220, 220, 220, 255)
local NORTH_COLOUR        = Color(255, 80, 80, 255)
local NAME_BG_COLOUR      = Color(0, 0, 0, 200)

local scoreboard          = false

local arrow_mat = Material("vgui/ttt/equip/trk_minimap_arrow.png", "noclamp smooth")

local fonts_created = {}
local function GetFont(size)
    local key = "TrkMinimap_" .. size
    if not fonts_created[key] then
        surface.CreateFont(key, { font = "Roboto", size = size, weight = 500, antialias = true })
        fonts_created[key] = true
    end
    return key
end

local function VectorToColour(vector, alpha)
    return Color(vector.x * 255, vector.y * 255, vector.z * 255, alpha or 255)
end

local function GetPlayerColour(ply, alpha)
    if not IsValid(ply) then return Color(255, 255, 255, alpha or 255) end
    local vector = ply:GetNWVector("PlayerColor", Vector(1, 1, 1))
    return VectorToColour(vector, alpha or 255)
end

local function DrawArrow(cx, cy, w, h, angleDeg, colour)
    surface.SetMaterial(arrow_mat)
    SurfaceSetDrawColor(colour.r, colour.g, colour.b, colour.a)
    SurfaceDrawTexturedRectRotated(cx, cy, w, h, -angleDeg)
end

local function DrawFilledCircle(cx, cy, r, colour)
    draw.NoTexture()
    SurfaceSetDrawColor(colour.r, colour.g, colour.b, colour.a)
    local segs = 32
    local verts = {}
    for i = 0, segs - 1 do
        local a = (i / segs) * math.pi * 2
        table.insert(verts, { x = cx + MathCos(a) * r, y = cy + MathSin(a) * r })
    end
    surface.DrawPoly(verts)
end

local function ClampToRing(dx, dy, r)
    local dist = MathSqrt(dx * dx + dy * dy)
    dist = dist + BASE_CIRCLE_R / 2
    if dist == 0 then return 0, 0 end
    local frac = r / dist
    return dx * frac, dy * frac
end

hook.Add("ScoreboardShow", "Tracker_Minimap_ScoreboardShow", function()
    local client = LocalPlayer()
    if not IsPlayer(client) then return end
    if not client:Alive() or client:IsSpec() then return end
    if not client:HasEquipmentItem(EQUIP_TRK_MINIMAP) then return end

    scoreboard = true
end)

hook.Add("ScoreboardHide", "Tracker_Minimap_ScoreboardHide", function()
    scoreboard = false
end)

hook.Add("HUDPaint", "Tracker_Minimap_HUDPaint", function()
    local client = LocalPlayer()
    if not IsPlayer(client) then return end
    if not client:Alive() or client:IsSpec() then return end
    if not client:HasEquipmentItem(EQUIP_TRK_MINIMAP) then return end

    local scale         = tracker_minimap_scale:GetFloat()
    local radius        = BASE_RADIUS * scale
    local margin        = BASE_MARGIN * scale
    local arrowW        = BASE_ARROW_W * scale
    local arrowH        = BASE_ARROW_H * scale
    local circleR       = BASE_CIRCLE_R * scale
    local fontSize      = MathMax(6, math.Round(BASE_FONT_SIZE * scale))
    local cardinalSize  = MathMax(6, math.Round(BASE_CARDINAL_SIZE * scale))

    local rangeUnits    = BASE_RANGE_UNITS * tracker_minimap_range_mult:GetFloat()
    local lockNorth     = tracker_minimap_lock_north:GetBool()
    local showColours   = tracker_minimap_show_colours:GetBool()
    local showFacing    = tracker_minimap_show_facing:GetBool()
    local showOutside   = tracker_minimap_show_outside:GetBool()
    local showNames     = tracker_minimap_show_names:GetBool()
    local cardinalsMode = tracker_minimap_show_cardinals:GetInt()
    local allowEnlarge  = tracker_minimap_allow_enlarge:GetBool()

    local cx = margin + radius
    local cy = margin + radius

    if allowEnlarge and scoreboard and IsValid(sboard_panel) and sboard_panel:IsVisible() then
        local _, sbY, _, sbH = sboard_panel:GetBounds()
        local scoreboardBase = sbY + sbH

        local gap = ScrH() - scoreboardBase
        cx = ScrW() / 2
        cy = scoreboardBase + gap / 2
        radius = (gap / 2.5)

        local dynamicScale = radius / BASE_RADIUS
        arrowW        = BASE_ARROW_W * dynamicScale
        arrowH        = BASE_ARROW_H * dynamicScale
        circleR       = BASE_CIRCLE_R * dynamicScale
        fontSize      = MathMax(6, math.Round(BASE_FONT_SIZE * dynamicScale))
        cardinalSize  = MathMax(6, math.Round(BASE_CARDINAL_SIZE * dynamicScale))
    end

    local myPos = client:GetPos()
    local myYaw = client:EyeAngles().y

    DrawFilledCircle(cx, cy, radius, MINIMAP_BG_COLOUR)

    SurfaceSetDrawColor(MINIMAP_RING_COLOUR.r, MINIMAP_RING_COLOUR.g, MINIMAP_RING_COLOUR.b, MINIMAP_RING_COLOUR.a)
    SurfaceDrawCircle(cx, cy, radius, MINIMAP_RING_COLOUR.r, MINIMAP_RING_COLOUR.g, MINIMAP_RING_COLOUR.b, MINIMAP_RING_COLOUR.a)

    -- NESW letters
    if cardinalsMode ~= 0 then
        local function CardinalScreenAngle(worldYawDeg)
            if lockNorth then
                return MathRad(-(worldYawDeg - 90) - 90)
            else
                local delta = worldYawDeg - myYaw
                return MathRad(-delta - 90)
            end
        end

        local cardinalFont = GetFont(cardinalSize)
        local biggerCardinalFont = GetFont(cardinalSize * 1.5)

        local cardinals
        if cardinalsMode == 1 then
            cardinals = { { label = "N", yaw = 90,  colour = NORTH_COLOUR } }
        else
            cardinals = {
                { label = "N", yaw = 90,   colour = NORTH_COLOUR },
                { label = "E", yaw = 0,    colour = CARDINAL_COLOUR },
                { label = "S", yaw = -90,  colour = CARDINAL_COLOUR },
                { label = "W", yaw = 180,  colour = CARDINAL_COLOUR },
            }
        end

        local cardinalOffset = radius - cardinalSize * 0.7
        for _, c in ipairs(cardinals) do
            if c.label == "N" then
                SurfaceSetFont(biggerCardinalFont)
            else
                SurfaceSetFont(cardinalFont)
            end

            local a  = CardinalScreenAngle(c.yaw)
            local lx = cx + MathCos(a) * cardinalOffset
            local ly = cy + MathSin(a) * cardinalOffset
            local tw, th = SurfaceGetTextSize(c.label)
            SurfaceSetTextColor(c.colour.r, c.colour.g, c.colour.b, c.colour.a)
            SurfaceSetTextPos(lx - tw / 2, ly - th / 2)
            SurfaceDrawText(c.label)
        end
    end

    -- Player's arrow
    local selfAngle = lockNorth and -(myYaw - 90) or 0
    DrawArrow(cx, cy, arrowW, arrowH, selfAngle, SELF_COLOUR)

    -- Other players' arrows/blips
    local unitsPerPx = rangeUnits / radius

    for _, ply in PlayerIterator() do
        if not IsValid(ply) or ply == client then continue end
        if not ply:Alive() or ply:IsSpec() then continue end

        local theirPos  = ply:GetPos()
        local dx_world  = theirPos.x - myPos.x
        local dy_world  = theirPos.y - myPos.y

        local rotAngle = lockNorth and 0 or MathRad(myYaw - 90)
        local cosA = MathCos(rotAngle)
        local sinA = MathSin(rotAngle)

        local sx =  dx_world * cosA + dy_world * sinA
        local sy = -dx_world * sinA + dy_world * cosA

        local px =  sx / unitsPerPx
        local py = -sy / unitsPerPx

        local dist = MathSqrt(px * px + py * py)
        local outsideRange = dist > radius

        if outsideRange then
            if not showOutside then continue end
            px, py = ClampToRing(px, py, radius)
        end

        local blipX = cx + px
        local blipY = cy + py

        local colour = showColours and GetPlayerColour(ply, 255) or Color(255, 255, 255, 255)

        if showFacing and not outsideRange then
            local theirYaw = ply:EyeAngles().y
            local arrowAngle = lockNorth and -(theirYaw - 90) or -(theirYaw - myYaw)
            DrawArrow(blipX, blipY, arrowW, arrowH, arrowAngle, colour)
        else
            DrawFilledCircle(blipX, blipY, outsideRange and (circleR * 0.8) or circleR, colour)
        end

        -- Name labels
        if showNames and not outsideRange then
            local nameFont = GetFont(fontSize)
            SurfaceSetFont(nameFont)
            local name = ply:Nick()
            local tw, th = SurfaceGetTextSize(name)
            local labelY = blipY + (arrowH / 2) + 2
            local bgPad  = 2
            DrawRoundedBox(2,
                blipX - tw / 2 - bgPad,
                labelY - bgPad,
                tw + bgPad * 2,
                th + bgPad * 2,
                NAME_BG_COLOUR
            )
            SurfaceSetTextColor(colour.r, colour.g, colour.b, 255)
            SurfaceSetTextPos(blipX - tw / 2, labelY)
            SurfaceDrawText(name)
        end
    end
end)