include("shared.lua")

local hook = hook
local math = math
local net = net
local pairs = pairs
local surface = surface
local table = table
local timer = timer
local vgui = vgui

TRACKRADAR = {}
TRACKRADAR.targets = {}
TRACKRADAR.enable = false
TRACKRADAR.duration = 30
TRACKRADAR.endtime = 0
TRACKRADAR.repeating = true

hook.Add("Initialize", "Tracker_TrackingRadar_Initialize_Lang", function()
    LANG.AddToLanguage("english", "item_track_radar", "Tracking Radar")
    LANG.AddToLanguage("english", "item_track_radar_desc", [[Allows you to scan for all players, living and dead.

The scan icon color will match the
player's footprint color.

Starts automatic scans as soon as you
buy it. Configure it in the Tracking Radar
tab of this menu.]])

    LANG.AddToLanguage("english", "equip_tooltip_trackradar", "Tracking Radar control")

    LANG.AddToLanguage("english", "trackradar_name", "Tracking Radar")
    LANG.AddToLanguage("english", "trackradar_menutitle", "Tracking Radar control")
    LANG.AddToLanguage("english", "trackradar_not_owned", "You are not carrying a Tracking Radar!")
    LANG.AddToLanguage("english", "trackradar_scan", "Perform scan")
    LANG.AddToLanguage("english", "trackradar_auto", "Auto-repeat scan")
    LANG.AddToLanguage("english", "trackradar_help", "Scan results show for {num} seconds, after which the Tracking Radar will have recharged and can be used again.")
    LANG.AddToLanguage("english", "trackradar_charging", "Your Tracking Radar is still charging!")
    LANG.AddToLanguage("english", "trackradar_hud", "Tracking Radar ready for next scan in: {time}")
end)

function TRACKRADAR.Bought(is_item, id)
    if is_item and id == EQUIP_TRK_TRACKRADAR then
        RunConsoleCommand("ttt_trackradar_scan")
    end
end
hook.Add("TTTBoughtItem", "TrackRadarBoughtItem", TRACKRADAR.Bought)

function TRACKRADAR:EndScan()
    self.enable = false
    self.endtime = CurTime()
end

function TRACKRADAR:Clear()
    self:EndScan()
end
hook.Add("InitPostEntity", "TrackRadar_InitPostEntity", function()
    TRACKRADAR:Clear()
end)
hook.Add("TTTPrepareRound", "TrackRadar_InitPostEntity", function()
    TRACKRADAR:Clear()
end)

function TRACKRADAR:Timeout()
    self:EndScan()

    if self.repeating and LocalPlayer() and LocalPlayer():HasEquipmentItem(EQUIP_TRK_TRACKRADAR) then
        RunConsoleCommand("ttt_trackradar_scan")
    end
end

local beacon_back = surface.GetTextureID("vgui/ttt/beacon_back")
local beacon_trk = surface.GetTextureID("vgui/ttt/beacon_trk")

local GetPTranslation = LANG.GetParamTranslation
local FormatTime = util.SimpleTime

function TRACKRADAR:Draw(client)
    if not client then return end

    surface.SetFont("HudSelectionText")

    if not self.enable then return end

    surface.SetTexture(beacon_back)
    surface.SetTextColor(0, 0, 0, 0)

    for _, target in pairs(self.targets) do
        local r, g, b = target.col:Unpack()
        surface.SetDrawColor(r, g, b, 230)
        RADAR:DrawTarget(target, 16, 0.5)
    end

    surface.SetTexture(beacon_trk)
    surface.SetTextColor(255, 255, 255, 255)
    surface.SetDrawColor(255, 255, 255, 255)

    for _, target in pairs(self.targets) do
        RADAR:DrawTarget(target, 16, 0.5)
    end
end
hook.Add("HUDPaint", "TrackRadarHUDPaint", function()
    TRACKRADAR:Draw(LocalPlayer())
end)

hook.Add("TTTHUDInfoPaint", "TrackRadar_TTTHUDInfoPaint", function(cli, label_left, label_top, active_labels)
    if not IsPlayer(cli) then return end
    if not cli:Alive() or cli:IsSpec() then return end
    if not cli:HasEquipmentItem(EQUIP_TRK_TRACKRADAR) then return end

    -- Time until next scan
    surface.SetFont("TabLarge")
    surface.SetTextColor(255, 0, 0, 230)

    local remaining = math.max(0, TRACKRADAR.endtime - CurTime())
    local text = GetPTranslation("trackradar_hud", { time = FormatTime(remaining, "%02i:%02i") })
    local _, h = surface.GetTextSize(text)

    -- Move this up based on how many other labels here are
    label_top = label_top + (20 * #active_labels)

    surface.SetTextPos(label_left, ScrH() - label_top - h)
    surface.DrawText(text)

    -- Track that the label was added so others can position accurately
    table.insert(active_labels, "trackradar")
end)

local function ReceiveTrackRadarScan()
    local num_targets = net.ReadUInt(8)

    TRACKRADAR.targets = {}
    for _ = 1, num_targets do
        local pos = Vector()
        pos.x = net.ReadInt(32)
        pos.y = net.ReadInt(32)
        pos.z = net.ReadInt(32)

        local col = Vector()
        col.x = net.ReadFloat() * 255
        col.y = net.ReadFloat() * 255
        col.z = net.ReadFloat() * 255

        table.insert(TRACKRADAR.targets, { pos = pos, col = col })
    end

    TRACKRADAR.enable = true
    TRACKRADAR.endtime = CurTime() + TRACKRADAR.duration

    timer.Create("trackradartimeout", TRACKRADAR.duration + 1, 1, function() TRACKRADAR:Timeout() end)
end
net.Receive("TTT_TrackRadar", ReceiveTrackRadarScan)

local GetTranslation = LANG.GetTranslation
function TRACKRADAR.CreateMenu(parent, frame)
    local dform = vgui.Create("DForm", parent)
    dform:SetName(GetTranslation("trackradar_menutitle"))
    dform:StretchToParent(0, 0, 0, 0)
    dform:SetAutoSize(false)

    local owned = LocalPlayer():HasEquipmentItem(EQUIP_TRK_TRACKRADAR)

    if not owned then
        dform:Help(GetTranslation("trackradar_not_owned"))
        return dform
    end

    local bw, bh = 100, 25
    local dscan = vgui.Create("DButton", dform)
    dscan:SetSize(bw, bh)
    dscan:SetText(GetTranslation("trackradar_scan"))
    dscan.DoClick = function(s)
        s:SetDisabled(true)
        RunConsoleCommand("ttt_trackradar_scan")
        frame:Close()
    end
    dform:AddItem(dscan)

    local dlabel = vgui.Create("DLabel", dform)
    dlabel:SetText(GetPTranslation("trackradar_help", { num = TRACKRADAR.duration }))
    dlabel:SetWrap(true)
    dlabel:SetTall(50)
    dform:AddItem(dlabel)

    local dcheck = vgui.Create("DCheckBoxLabel", dform)
    dcheck:SetText(GetTranslation("trackradar_auto"))
    dcheck:SetIndent(5)
    dcheck:SetValue(TRACKRADAR.repeating)
    dcheck.OnChange = function(s, val)
        TRACKRADAR.repeating = val
    end
    dform:AddItem(dcheck)

    dform.Think = function(s)
        if TRACKRADAR.enable or not owned then
            dscan:SetDisabled(true)
        else
            dscan:SetDisabled(false)
        end
    end

    dform:SetVisible(true)

    return dform
end
hook.Add("TTTEquipmentTabs", "TrackRadarConfigTab", function(dsheet, dframe)
    if LocalPlayer():HasEquipmentItem(EQUIP_TRK_TRACKRADAR) then
        local tradar = TRACKRADAR.CreateMenu(dsheet, dframe)
        dsheet:AddSheet(GetTranslation("trackradar_name"), tradar, "icon16/magnifier.png", false, false, GetTranslation("equip_tooltip_trackradar"))
        return true
    end
end)