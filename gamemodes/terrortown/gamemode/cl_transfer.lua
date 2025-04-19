local hook = hook
local player = player
local vgui = vgui

local CallHook = hook.Call
local PlayerIterator = player.Iterator

--- Credit transfer tab for equipment menu
local GetTranslation = LANG.GetTranslation
function CreateTransferMenu(parent)
    local dform = vgui.Create("DForm", parent)
    dform:SetName(GetTranslation("xfer_menutitle"))
    dform:StretchToParent(0, 0, 0, 0)
    dform:SetAutoSize(false)

    local client = LocalPlayer()
    if client:GetCredits() <= 0 then
        dform:Help(GetTranslation("xfer_no_credits"))
        return dform
    end

    local bw, bh = 100, 20
    local dsubmit = vgui.Create("DButton", dform)
    dsubmit:SetSize(bw, bh)
    dsubmit:SetDisabled(true)
    dsubmit:SetText(GetTranslation("xfer_send"))

    local selected_sid64 = nil

    local dpick = vgui.Create("DComboBox", dform)
    dpick.OnSelect = function(s, idx, val, data)
        if data then
            selected_sid64 = data
            dsubmit:SetDisabled(false)
        end
    end

    dpick:SetWide(250)

    -- fill combobox
    for _, p in PlayerIterator() do
        if not IsValid(p) or p == client then continue end
        if not p:IsActive() then continue end

        local canSend = client:IsSameTeam(p)
        local newCanSend = CallHook("TTTPlayerCanSendCreditsTo", nil, client, p, canSend)
        if type(newCanSend) == "boolean" then canSend = newCanSend end
        if canSend then
            dpick:AddChoice(p:Nick(), p:SteamID64())
        end
    end

    -- select first player by default
    if dpick:GetOptionText(1) then dpick:ChooseOptionID(1) end

    dsubmit.DoClick = function(s)
        if selected_sid64 then
            if player.GetBySteamID64(selected_sid64):IsActiveGlitch() then
                RunConsoleCommand("ttt_fake_transfer_credits", selected_sid64, "1")
            else
                RunConsoleCommand("ttt_transfer_credits", selected_sid64, "1")
            end
        end
    end

    dsubmit.Think = function(s)
        if LocalPlayer():GetCredits() < 1 then
            s:SetDisabled(true)
        end
    end

    dform:AddItem(dpick)
    dform:AddItem(dsubmit)

    local roleTeam = LocalPlayer():GetRoleTeam(true)
    dform:Help(LANG.GetParamTranslation("xfer_help", { role = GetRoleTeamName(roleTeam) }))

    return dform
end
