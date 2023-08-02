include("shared.lua")

local hook = hook
local math = math
local net = net
local pairs = pairs
local surface = surface
local table = table
local timer = timer
local vgui = vgui

DEATHRADAR = {}
DEATHRADAR.targets = {}
DEATHRADAR.enable = false
DEATHRADAR.duration = 30
DEATHRADAR.endtime = 0
DEATHRADAR.repeating = true

hook.Add("Initialize", "MadScientist_DeathRadar_Initialize_Lang", function()
    LANG.AddToLanguage("english", "item_death_radar", "Death Radar")
    LANG.AddToLanguage("english", "item_death_radar_desc", [[Allows you to scan for dead bodies.

Starts automatic scans as soon as you
buy it. Configure it in the Death Radar tab
of this menu.]])

    LANG.AddToLanguage("english", "equip_tooltip_deathradar", "Death Radar control")

    LANG.AddToLanguage("english", "deathradar_name", "Death Radar")
    LANG.AddToLanguage("english", "deathradar_menutitle", "Death Radar control")
    LANG.AddToLanguage("english", "deathradar_not_owned", "You are not carrying a Death Radar!")
    LANG.AddToLanguage("english", "deathradar_scan", "Perform scan")
    LANG.AddToLanguage("english", "deathradar_auto", "Auto-repeat scan")
    LANG.AddToLanguage("english", "deathradar_help", "Scan results show for {num} seconds, after which the Death Radar will have recharged and can be used again.")
    LANG.AddToLanguage("english", "deathradar_charging", "Your Death Radar is still charging!")
    LANG.AddToLanguage("english", "deathradar_hud", "Death Radar ready for next scan in: {time}")
end)

function DEATHRADAR.Bought(is_item, id)
    if is_item and id == EQUIP_MAD_DEATHRADAR then
        RunConsoleCommand("ttt_deathradar_scan")
    end
end
hook.Add("TTTBoughtItem", "DeathRadarBoughtItem", DEATHRADAR.Bought)

function DEATHRADAR:EndScan()
    self.enable = false
    self.endtime = CurTime()
end

function DEATHRADAR:Clear()
    self:EndScan()
end
hook.Add("InitPostEntity", "DeathRadar_InitPostEntity", function()
    DEATHRADAR:Clear()
end)
hook.Add("TTTPrepareRound", "DeathRadar_InitPostEntity", function()
    DEATHRADAR:Clear()
end)

function DEATHRADAR:Timeout()
    self:EndScan()

    if self.repeating and LocalPlayer() and LocalPlayer():HasEquipmentItem(EQUIP_MAD_DEATHRADAR) then
        RunConsoleCommand("ttt_deathradar_scan")
    end
end

local beacon_back = surface.GetTextureID("vgui/ttt/beacon_back")
local beacon_skull = surface.GetTextureID("vgui/ttt/beacon_skull")

local GetPTranslation = LANG.GetParamTranslation
local FormatTime = util.SimpleTime

function DEATHRADAR:Draw(client)
    if not client then return end

    surface.SetFont("HudSelectionText")

    if not self.enable then return end

    surface.SetTexture(beacon_back)
    surface.SetTextColor(0, 0, 0, 0)
    surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_MADSCIENTIST])

    for _, target in pairs(self.targets) do
        RADAR:DrawTarget(target, 16, 0.5)
    end

    surface.SetTexture(beacon_skull)
    surface.SetTextColor(255, 255, 255, 255)
    surface.SetDrawColor(255, 255, 255, 255)

    for _, target in pairs(self.targets) do
        RADAR:DrawTarget(target, 16, 0.5)
    end
end
hook.Add("HUDPaint", "DeathRadarHUDPaint", function()
    DEATHRADAR:Draw(LocalPlayer())
end)

hook.Add("TTTHUDInfoPaint", "DeathRadar_TTTHUDInfoPaint", function(cli, label_left, label_top, active_labels)
    if not IsPlayer(cli) then return end
    if not cli:Alive() or cli:IsSpec() then return end
    if not cli:HasEquipmentItem(EQUIP_MAD_DEATHRADAR) then return end

    -- Time until next scan
    surface.SetFont("TabLarge")
    surface.SetTextColor(255, 0, 0, 230)

    local remaining = math.max(0, DEATHRADAR.endtime - CurTime())
    local text = GetPTranslation("deathradar_hud", { time = FormatTime(remaining, "%02i:%02i") })
    local _, h = surface.GetTextSize(text)

    -- Move this up based on how many other labels here are
    label_top = label_top + (20 * #active_labels)

    surface.SetTextPos(label_left, ScrH() - label_top - h)
    surface.DrawText(text)

    -- Track that the label was added so others can position accurately
    table.insert(active_labels, "deathradar")
end)

local function ReceiveDeathRadarScan()
    local num_targets = net.ReadUInt(8)

    DEATHRADAR.targets = {}
    for _ = 1, num_targets do
        local pos = Vector()
        pos.x = net.ReadInt(32)
        pos.y = net.ReadInt(32)
        pos.z = net.ReadInt(32)

        table.insert(DEATHRADAR.targets, { pos = pos })
    end

    DEATHRADAR.enable = true
    DEATHRADAR.endtime = CurTime() + DEATHRADAR.duration

    timer.Create("deathradartimeout", DEATHRADAR.duration + 1, 1, function() DEATHRADAR:Timeout() end)
end
net.Receive("TTT_DeathRadar", ReceiveDeathRadarScan)

local GetTranslation = LANG.GetTranslation
function DEATHRADAR.CreateMenu(parent, frame)
    local dform = vgui.Create("DForm", parent)
    dform:SetName(GetTranslation("deathradar_menutitle"))
    dform:StretchToParent(0, 0, 0, 0)
    dform:SetAutoSize(false)

    local owned = LocalPlayer():HasEquipmentItem(EQUIP_MAD_DEATHRADAR)

    if not owned then
        dform:Help(GetTranslation("deathradar_not_owned"))
        return dform
    end

    local bw, bh = 100, 25
    local dscan = vgui.Create("DButton", dform)
    dscan:SetSize(bw, bh)
    dscan:SetText(GetTranslation("deathradar_scan"))
    dscan.DoClick = function(s)
        s:SetDisabled(true)
        RunConsoleCommand("ttt_deathradar_scan")
        frame:Close()
    end
    dform:AddItem(dscan)

    local dlabel = vgui.Create("DLabel", dform)
    dlabel:SetText(GetPTranslation("deathradar_help", { num = DEATHRADAR.duration }))
    dlabel:SetWrap(true)
    dlabel:SetTall(50)
    dform:AddItem(dlabel)

    local dcheck = vgui.Create("DCheckBoxLabel", dform)
    dcheck:SetText(GetTranslation("deathradar_auto"))
    dcheck:SetIndent(5)
    dcheck:SetValue(DEATHRADAR.repeating)
    dcheck.OnChange = function(s, val)
        DEATHRADAR.repeating = val
    end
    dform:AddItem(dcheck)

    dform.Think = function(s)
        if DEATHRADAR.enable or not owned then
            dscan:SetDisabled(true)
        else
            dscan:SetDisabled(false)
        end
    end

    dform:SetVisible(true)

    return dform
end
hook.Add("TTTEquipmentTabs", "DeathRadarConfigTab", function(dsheet, dframe)
    if LocalPlayer():HasEquipmentItem(EQUIP_MAD_DEATHRADAR) then
        local dradar = DEATHRADAR.CreateMenu(dsheet, dframe)
        dsheet:AddSheet(GetTranslation("deathradar_name"), dradar, "icon16/magnifier.png", false, false, GetTranslation("equip_tooltip_deathradar"))
        return true
    end
end)