-- Traitor radar rendering

local hook = hook
local math = math
local net = net
local pairs = pairs
local surface = surface
local table = table
local timer = timer
local util = util
local vgui = vgui

local CallHook = hook.Call

RADAR = {}
RADAR.targets = {}
RADAR.enable = false
RADAR.duration = 30
RADAR.endtime = 0
RADAR.bombs = {}
RADAR.bombs_count = 0
RADAR.repeating = true
RADAR.samples = {}
RADAR.samples_count = 0

RADAR.called_corpses = {}
RADAR.teleport_marks = {}

local detectives_corpse_call_expiration = GetConVar("ttt_detectives_corpse_call_expiration")

function RADAR:EndScan()
    self.enable = false
    self.endtime = CurTime()
end

function RADAR:Clear()
    self:EndScan()
    self.bombs = {}
    self.samples = {}

    self.bombs_count = 0
    self.samples_count = 0
end

function RADAR:Timeout()
    self:EndScan()

    if self.repeating and LocalPlayer() and LocalPlayer():HasEquipmentItem(EQUIP_RADAR) then
        RunConsoleCommand("ttt_radar_scan")
    end
end

-- cache stuff we'll be drawing
function RADAR.CacheEnts()
    local corpse_call_expiration = detectives_corpse_call_expiration:GetInt()
    if corpse_call_expiration > 0 then
        -- also do some corpse cleanup here
        for k, corpse in pairs(RADAR.called_corpses) do
            if (corpse.called + corpse_call_expiration) < CurTime() then
                RADAR.called_corpses[k] = nil -- will make # inaccurate, no big deal
            end
        end
    end

    if RADAR.bombs_count == 0 then return end

    -- Update bomb positions for those we know about
    for idx, b in pairs(RADAR.bombs) do
        local ent = Entity(idx)
        if IsValid(ent) then
            b.pos = ent:GetPos()
        end
    end
end

function RADAR.Bought(is_item, id)
    if is_item and id == EQUIP_RADAR then
        RunConsoleCommand("ttt_radar_scan")
    end
end
hook.Add("TTTBoughtItem", "RadarBoughtItem", RADAR.Bought)

local DISTANCE_UNIT_SOURCE = 0
local DISTANCE_UNIT_METERS = 1
local DISTANCE_UNIT_FEET = 2

local distance_unit = CreateClientConVar("ttt_distance_unit", "1", true, false, "What unit to use when displaying distance. 0 - None (Source). 1 - Meters. 2 - Feet", DISTANCE_UNIT_SOURCE, DISTANCE_UNIT_FEET)

local meters_per_unit = 1 / UNITS_PER_METER
local feet_per_unit = 1 / UNITS_PER_FOOT

local function GetReadableDistance(distance)
    local unit = distance_unit:GetInt()
    if unit == DISTANCE_UNIT_METERS then
        return math.ceil(distance * meters_per_unit) .. "m"
    elseif unit == DISTANCE_UNIT_FEET then
        return math.ceil(distance * feet_per_unit) .. "ft"
    end
    return math.ceil(distance)
end

function RADAR:DrawTarget(tgt, size, offset, no_shrink)
    local scrpos = tgt.pos:ToScreen() -- sweet
    local sz = (IsOffScreen(scrpos) and (not no_shrink)) and size / 2 or size

    scrpos.x = math.Clamp(scrpos.x, sz, ScrW() - sz)
    scrpos.y = math.Clamp(scrpos.y, sz, ScrH() - sz)

    if IsOffScreen(scrpos) then return end

    surface.DrawTexturedRect(scrpos.x - sz, scrpos.y - sz, sz * 2, sz * 2)

    -- Drawing full size?
    if sz == size then
        local text = GetReadableDistance(LocalPlayer():GetPos():Distance(tgt.pos))
        local w, h = surface.GetTextSize(text)

        -- Show range to target
        surface.SetTextPos(scrpos.x - w / 2, scrpos.y + (offset * sz) - h / 2)
        surface.DrawText(text)

        if tgt.t then
            -- Show time
            text = util.SimpleTime(tgt.t - CurTime(), "%02i:%02i")
            w, _ = surface.GetTextSize(text)

            surface.SetTextPos(scrpos.x - w / 2, scrpos.y + sz / 2)
            surface.DrawText(text)
        elseif tgt.nick then
            -- Show nickname
            text = tgt.nick
            w, _ = surface.GetTextSize(text)

            surface.SetTextPos(scrpos.x - w / 2, scrpos.y + sz / 2)
            surface.DrawText(text)
        end
    end
end

local indicator = surface.GetTextureID("effects/select_ring")
local c4warn = surface.GetTextureID("vgui/ttt/icon_c4warn")
local sample_scan = surface.GetTextureID("vgui/ttt/sample_scan")
local beacon_back = surface.GetTextureID("vgui/ttt/beacon_back")
local beacon_det = surface.GetTextureID("vgui/ttt/beacon_det")
local tele_mark = surface.GetTextureID("vgui/ttt/tele_mark")

local GetPTranslation = LANG.GetParamTranslation
local FormatTime = util.SimpleTime

local near_cursor_dist = 180

function RADAR:Draw(client)
    if not client then return end

    surface.SetFont("HudSelectionText")

    -- C4 warnings
    if self.bombs_count ~= 0 and client:CanSeeC4() then
        surface.SetTexture(c4warn)
        surface.SetTextColor(200, 55, 55, 220)
        surface.SetDrawColor(255, 255, 255, 200)

        for _, bomb in pairs(self.bombs) do
            self:DrawTarget(bomb, 24, 0, true)
        end
    end

    -- Corpse calls
    if client:IsActiveDetectiveLike() and #self.called_corpses then
        surface.SetTexture(beacon_back)
        surface.SetTextColor(0, 0, 0, 0)
        surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_DETECTIVE])

        for _, corpse in pairs(self.called_corpses) do
            self:DrawTarget(corpse, 16, 0.5)
        end

        surface.SetTexture(beacon_det)
        surface.SetTextColor(255, 255, 255, 255)
        surface.SetDrawColor(255, 255, 255, 255)

        for _, corpse in pairs(self.called_corpses) do
            self:DrawTarget(corpse, 16, 0.5)
        end
    end

    -- Teleport marks
    if client:IsActive() and #self.teleport_marks then
        surface.SetTexture(tele_mark)
        surface.SetTextColor(255, 255, 255, 240)
        surface.SetDrawColor(255, 255, 255, 230)

        for _, mark in pairs(self.teleport_marks) do
            self:DrawTarget(mark, 16, 0.5)
        end
    end

    -- Samples
    if self.samples_count ~= 0 then
        surface.SetTexture(sample_scan)
        surface.SetTextColor(200, 50, 50, 255)
        surface.SetDrawColor(255, 255, 255, 240)

        for _, sample in pairs(self.samples) do
            self:DrawTarget(sample, 16, 0.5, true)
        end
    end

    CallHook("TTTRadarRender", nil, client)

    -- Player radar
    if not self.enable then return end

    surface.SetTexture(indicator)

    local remaining = math.max(0, RADAR.endtime - CurTime())
    local alpha_base = 50 + 180 * (remaining / RADAR.duration)

    local mpos = Vector(ScrW() / 2, ScrH() / 2, 0)

    local glitchMode = GetConVar("ttt_glitch_mode"):GetInt()
    local beggarMode = GetConVar("ttt_beggar_reveal_traitor"):GetInt()
    local bodysnatcherMode = GetConVar("ttt_bodysnatcher_reveal_traitor"):GetInt()
    local role, alpha, scrpos, md
    for _, tgt in pairs(RADAR.targets) do
        alpha = alpha_base

        scrpos = tgt.pos:ToScreen()
        if scrpos.visible then
            md = mpos:Distance(Vector(scrpos.x, scrpos.y, 0))
            if md < near_cursor_dist then
                alpha = math.Clamp(alpha * (md / near_cursor_dist), 40, 230)
            end

            role = tgt.role or ROLE_INNOCENT

            local color
            if client:IsTraitorTeam() then
                local hideSpecialTraitors = glitchMode == GLITCH_HIDE_SPECIAL_TRAITOR_ROLES and GetGlobalBool("ttt_glitch_round", false)
                local hideBeggar = tgt.was_beggar and (beggarMode == BEGGAR_REVEAL_NONE or beggarMode == BEGGAR_REVEAL_INNOCENTS)
                local hideBodysnatcher = tgt.was_bodysnatcher and not (bodysnatcherMode == BODYSNATCHER_REVEAL_ALL or bodysnatcherMode == BODYSNATCHER_REVEAL_ROLES_THAT_CAN_SEE_JESTER or (TRAITOR_ROLES[role] and bodysnatcherMode == BODYSNATCHER_REVEAL_TEAM))
                local showJester = (tgt.should_act_like_jester or
                                    ((role == ROLE_TRAITOR or role == ROLE_INNOCENT) and hideBeggar and JESTER_ROLES[ROLE_BEGGAR]) or
                                    (hideBodysnatcher and JESTER_ROLES[ROLE_BODYSNATCHER])) and
                                        not client:ShouldHideJesters()
                if showJester then
                    color = ColorAlpha(ROLE_COLORS_RADAR[ROLE_JESTER], alpha)
                -- Hide these if we're told to but they aren't jesters
                elseif hideBeggar or hideBodysnatcher then
                    color = ColorAlpha(ROLE_COLORS_RADAR[ROLE_INNOCENT], alpha)
                elseif (role == ROLE_TRAITOR or role == ROLE_GLITCH or (hideSpecialTraitors and TRAITOR_ROLES[role])) then
                    color = ColorAlpha(ROLE_COLORS_RADAR[ROLE_TRAITOR], alpha)
                elseif TRAITOR_ROLES[role] then
                    color = ColorAlpha(GetRoleTeamColor(ROLE_TEAM_TRAITOR, "radar"), alpha)
                else
                    color = ColorAlpha(ROLE_COLORS_RADAR[ROLE_INNOCENT], alpha)
                end
            elseif client:IsDetectiveLike() then
                if role == ROLE_DETECTIVE then
                    color = ColorAlpha(ROLE_COLORS_RADAR[ROLE_DETECTIVE], alpha)
                elseif DETECTIVE_ROLES[role] then
                    color = ColorAlpha(GetRoleTeamColor(ROLE_TEAM_DETECTIVE, "radar"), alpha)
                else
                    color = ColorAlpha(ROLE_COLORS_RADAR[ROLE_INNOCENT], alpha)
                end
            else
                color = ColorAlpha(ROLE_COLORS_RADAR[ROLE_INNOCENT], alpha)
            end

            -- If the target is an active clown but they should be hidden, hide them from the radar
            local hidden = tgt.killer_clown_active and GetConVar("ttt_clown_hide_when_active"):GetBool()

            local newColor, newHidden = CallHook("TTTRadarPlayerRender", nil, client, tgt, color, hidden)
            if newColor then color = newColor end
            if type(newHidden) == "boolean" then hidden = newHidden end

            if color and not hidden then
                surface.SetDrawColor(color)
                surface.SetTextColor(color)
                self:DrawTarget(tgt, 24, 0)
            end
        end
    end

    -- Time until next scan
    surface.SetFont("TabLarge")
    surface.SetTextColor(255, 0, 0, 230)

    local text = GetPTranslation("radar_hud", { time = FormatTime(remaining, "%02i:%02i") })
    local _, h = surface.GetTextSize(text)

    surface.SetTextPos(36, ScrH() - 140 - h)
    surface.DrawText(text)
end

local function ReceiveC4Warn()
    local idx = net.ReadUInt(16)
    local armed = net.ReadBit() == 1

    if armed then
        local pos = net.ReadVector()
        local etime = net.ReadFloat()

        RADAR.bombs[idx] = { pos = pos, t = etime }
    else
        RADAR.bombs[idx] = nil
    end

    RADAR.bombs_count = table.Count(RADAR.bombs)
end
net.Receive("TTT_C4Warn", ReceiveC4Warn)

local function ReceiveCorpseCall()
    local pos = net.ReadVector()
    local sid = net.ReadString()

    -- If this sid already has a corpse call, update the position
    for _, r in ipairs(RADAR.called_corpses) do
        if r.sid == sid then
            r.pos = pos
            r.called = CurTime()
            return
        end
    end

    -- If not, add it
    table.insert(RADAR.called_corpses, { sid = sid, pos = pos, called = CurTime() })
end
net.Receive("TTT_CorpseCall", ReceiveCorpseCall)

local function RemoveCorpseCall()
    local sid = net.ReadString()

    -- Remove the radar icon for the searched corpse
    if RADAR and RADAR.called_corpses then
        for i, v in pairs(RADAR.called_corpses) do
            if v.sid == sid then
                table.remove(RADAR.called_corpses, i)
                return
            end
        end
    end
end
net.Receive("TTT_RemoveCorpseCall", RemoveCorpseCall)

local function ReceiveTeleportMark()
    local pos = net.ReadVector()
    pos.z = pos.z + 50
    RADAR.teleport_marks = {}
    table.insert(RADAR.teleport_marks, { pos = pos, called = CurTime() })
end
net.Receive("TTT_TeleportMark", ReceiveTeleportMark)

local function ClearRadarExtras()
    RADAR.called_corpses = {}
    RADAR.teleport_marks = {}
end
net.Receive("TTT_ClearRadarExtras", ClearRadarExtras)

local function ReceiveRadarScan()
    local num_targets = net.ReadUInt(8)

    RADAR.targets = {}
    for _ = 1, num_targets do
        local role = net.ReadInt(8)

        local pos = Vector()
        pos.x = net.ReadInt(15)
        pos.y = net.ReadInt(15)
        pos.z = net.ReadInt(15)

        local was_beggar = net.ReadBool()
        local was_bodysnatcher = net.ReadBool()
        local killer_clown_active = net.ReadBool()
        local should_act_like_jester = net.ReadBool()
        local sid64 = net.ReadString()

        table.insert(RADAR.targets, {
            role = role,
            pos = pos,
            was_beggar = was_beggar,
            was_bodysnatcher = was_bodysnatcher,
            killer_clown_active = killer_clown_active,
            should_act_like_jester = should_act_like_jester,
            sid64 = sid64
        })
    end

    RADAR.enable = true
    RADAR.endtime = CurTime() + RADAR.duration

    timer.Create("radartimeout", RADAR.duration + 1, 1, function() RADAR:Timeout() end)
end
net.Receive("TTT_Radar", ReceiveRadarScan)

local GetTranslation = LANG.GetTranslation
function RADAR.CreateMenu(parent, frame)
    local dform = vgui.Create("DForm", parent)
    dform:SetName(GetTranslation("radar_menutitle"))
    dform:StretchToParent(0, 0, 0, 0)
    dform:SetAutoSize(false)

    local owned = LocalPlayer():HasEquipmentItem(EQUIP_RADAR)

    if not owned then
        dform:Help(GetTranslation("radar_not_owned"))
        return dform
    end

    local bw, bh = 100, 25
    local dscan = vgui.Create("DButton", dform)
    dscan:SetSize(bw, bh)
    dscan:SetText(GetTranslation("radar_scan"))
    dscan.DoClick = function(s)
        s:SetDisabled(true)
        RunConsoleCommand("ttt_radar_scan")
        frame:Close()
    end
    dform:AddItem(dscan)

    local dlabel = vgui.Create("DLabel", dform)
    dlabel:SetText(GetPTranslation("radar_help", { num = RADAR.duration }))
    dlabel:SetWrap(true)
    dlabel:SetTall(50)
    dform:AddItem(dlabel)

    local dcheck = vgui.Create("DCheckBoxLabel", dform)
    dcheck:SetText(GetTranslation("radar_auto"))
    dcheck:SetIndent(5)
    dcheck:SetValue(RADAR.repeating)
    dcheck.OnChange = function(s, val)
        RADAR.repeating = val
    end
    dform:AddItem(dcheck)

    dform.Think = function(s)
        if RADAR.enable or not owned then
            dscan:SetDisabled(true)
        else
            dscan:SetDisabled(false)
        end
    end

    dform:SetVisible(true)

    return dform
end

