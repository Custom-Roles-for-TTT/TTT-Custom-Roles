-- Some popup window stuff

local GetTranslation = LANG.GetTranslation
local GetPTranslation = LANG.GetParamTranslation

---- Round start

local function GetTextForRole(role)
    local menukey = Key("+menu_context", "C")

    if role == ROLE_REVENGER then
        local sid = LocalPlayer():GetNWString("RevengerLover", "")
        local lover = player.GetBySteamID64(sid)
        local name = "someone"
        if IsValid(lover) and lover:IsPlayer() then name = lover:Nick() end
        return GetPTranslation("info_popup_revenger", { lover = name })

    elseif role == ROLE_HYPNOTIST then
        local traitors = {}
        local glitches = {}
        for _, ply in ipairs(player.GetAll()) do
            if ply:IsTraitorTeam() then
                table.insert(traitors, ply)
            elseif ply:IsGlitch() then
                table.insert(traitors, ply)
                table.insert(glitches, ply)
            end
        end

        local text
        if #traitors > 1 then
            local traitorlist = ""

            for k, ply in ipairs(traitors) do
                if ply ~= LocalPlayer() then
                    traitorlist = traitorlist .. string.rep(" ", 42) .. ply:Nick() .. "\n"
                end
            end

            if #glitches > 0 then
                text = GetPTranslation("info_popup_hypnotist_glitch", { menukey = menukey, traitorlist = traitorlist })
            else
                text = GetPTranslation("info_popup_hypnotist", { menukey = menukey, traitorlist = traitorlist })
            end
        else
            text = GetPTranslation("info_popup_hypnotist_alone", { menukey = menukey })
        end

        return text

    elseif role == ROLE_IMPERSONATOR then
        local traitors = {}
        local glitches = {}
        for _, ply in ipairs(player.GetAll()) do
            if ply:IsTraitorTeam() then
                table.insert(traitors, ply)
            elseif ply:IsGlitch() then
                table.insert(traitors, ply)
                table.insert(glitches, ply)
            end
        end

        local text
        if #traitors > 1 then
            local traitorlist = ""

            for k, ply in ipairs(traitors) do
                if ply ~= LocalPlayer() then
                    traitorlist = traitorlist .. string.rep(" ", 42) .. ply:Nick() .. "\n"
                end
            end

            if #glitches > 0 then
                text = GetPTranslation("info_popup_impersonator_glitch", { menukey = menukey, traitorlist = traitorlist })
            else
                text = GetPTranslation("info_popup_impersonator", { menukey = menukey, traitorlist = traitorlist })
            end
        else
            text = GetPTranslation("info_popup_impersonator_alone", { menukey = menukey })
        end

        return text

    elseif role == ROLE_TRAITOR then
        local traitors = {}
        local glitches = {}
        for _, ply in ipairs(player.GetAll()) do
            if ply:IsTraitorTeam() then
                table.insert(traitors, ply)
            elseif ply:IsGlitch() then
                table.insert(traitors, ply)
                table.insert(glitches, ply)
            end
        end

        local text
        if #traitors > 1 then
            local traitorlist = ""

            for _, ply in ipairs(traitors) do
                if ply ~= LocalPlayer() then
                    traitorlist = traitorlist .. string.rep(" ", 42) .. ply:Nick() .. "\n"
                end
            end

            if #glitches > 0 then
                text = GetPTranslation("info_popup_traitor_glitch", { menukey = menukey, traitorlist = traitorlist })
            else
                text = GetPTranslation("info_popup_traitor", { menukey = menukey, traitorlist = traitorlist })
            end
        else
            text = GetPTranslation("info_popup_traitor_alone", { menukey = menukey })
        end

        return text
    else
        return GetPTranslation("info_popup_" .. ROLE_STRINGS[role], { menukey = menukey })
    end
end

local startshowtime = CreateConVar("ttt_startpopup_duration", "17", FCVAR_ARCHIVE)
-- shows info about goal and fellow traitors (if any)
local function RoundStartPopup()
    -- based on Derma_Message

    if startshowtime:GetInt() <= 0 then return end

    if not LocalPlayer() then return end

    local dframe = vgui.Create("Panel")
    dframe:SetDrawOnTop(true)
    dframe:SetMouseInputEnabled(false)
    dframe:SetKeyboardInputEnabled(false)

    local color = Color(0, 0, 0, 200)
    dframe.Paint = function(s)
        draw.RoundedBox(8, 0, 0, s:GetWide(), s:GetTall(), color)
    end

    local text = GetTextForRole(LocalPlayer():GetRole())

    local dtext = vgui.Create("DLabel", dframe)
    dtext:SetFont("TabLarge")
    dtext:SetText(text)
    dtext:SizeToContents()
    dtext:SetContentAlignment(5)
    dtext:SetTextColor(color_white)

    local w, h = dtext:GetSize()
    local m = 10

    dtext:SetPos(m, m)

    dframe:SetSize(w + m * 2, h + m * 2)
    dframe:Center()

    dframe:AlignBottom(10)

    timer.Simple(startshowtime:GetInt(), function() dframe:Remove() end)
end
concommand.Add("ttt_cl_startpopup", RoundStartPopup)

--- Idle message

local function IdlePopup()
    local w, h = 300, 180

    local dframe = vgui.Create("DFrame")
    dframe:SetSize(w, h)
    dframe:Center()
    dframe:SetTitle(GetTranslation("idle_popup_title"))
    dframe:SetVisible(true)
    dframe:SetMouseInputEnabled(true)

    local inner = vgui.Create("DPanel", dframe)
    inner:StretchToParent(5, 25, 5, 45)

    local idle_limit = GetGlobalInt("ttt_idle_limit", 300) or 300

    local text = vgui.Create("DLabel", inner)
    text:SetWrap(true)
    text:SetText(GetPTranslation("idle_popup", { num = idle_limit, helpkey = Key("gm_showhelp", "F1") }))
    text:SetDark(true)
    text:StretchToParent(10, 5, 10, 5)

    local bw, bh = 75, 25
    local cancel = vgui.Create("DButton", dframe)
    cancel:SetPos(10, h - 40)
    cancel:SetSize(bw, bh)
    cancel:SetText(GetTranslation("idle_popup_close"))
    cancel.DoClick = function() dframe:Close() end

    local disable = vgui.Create("DButton", dframe)
    disable:SetPos(w - 185, h - 40)
    disable:SetSize(175, bh)
    disable:SetText(GetTranslation("idle_popup_off"))
    disable.DoClick = function()
        RunConsoleCommand("ttt_spectator_mode", "0")
        dframe:Close()
    end

    dframe:MakePopup()

end
concommand.Add("ttt_cl_idlepopup", IdlePopup)
