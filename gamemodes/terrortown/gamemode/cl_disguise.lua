local concommand = concommand
local surface = surface
local vgui = vgui

DISGUISE = {}

local T = LANG.GetTranslation

function DISGUISE.CreateMenu(parent)
    local dform = vgui.Create("DForm", parent)
    dform:SetName(trans("disg_menutitle"))
    dform:StretchToParent(0,0,0,0)
    dform:SetAutoSize(false)

    local owned = LocalPlayer():HasEquipmentItem(EQUIP_DISGUISE)

    if not owned then
       dform:Help(T("disg_not_owned"))
       return dform
    end

    local dcheck = vgui.Create("DCheckBoxLabel", dform)
    dcheck:SetText(T("disg_enable"))
    dcheck:SetIndent(5)
    dcheck:SetValue(LocalPlayer():GetNWBool("disguised", false))
    dcheck.OnChange = function(s, val)
                         RunConsoleCommand("ttt_set_disguise", val and "1" or "0")
                      end
    dform:AddItem(dcheck)

    dform:Help(T("disg_help1"))

    dform:Help(T("disg_help2"))

    dform:SetVisible(true)

    return dform
end

function DISGUISE.Draw(client)
    if (not client) or not client:HasEquipmentItem(EQUIP_DISGUISE) then return end
    if not client:GetNWBool("disguised", false) then return end

    surface.SetFont("TabLarge")
    surface.SetTextColor(255, 0, 0, 230)

    local text = T("disg_hud")
    local _, h = surface.GetTextSize(text)

    local label_top = 140
    if client:HasEquipmentItem(EQUIP_RADAR) then
        label_top = label_top + 20
    end
    surface.SetTextPos(36, ScrH() - label_top - h)
    surface.DrawText(text)
end

concommand.Add("ttt_toggle_disguise", WEPS.DisguiseToggle)