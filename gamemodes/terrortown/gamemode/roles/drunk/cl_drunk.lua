local hook = hook
local net = net
local surface = surface
local util = util

local MathMax = math.max

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Drunk_Translations_Initialize", function()
    -- HUD
    LANG.AddToLanguage("english", "drunk_hud", "You will sober up in: {time}")

    -- Events
    LANG.AddToLanguage("english", "ev_drunk", "{player} remembered they are {team}")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_drunk", [[You are {role}!  You have forgotten what team you are on!
Wait until you sober up and remember. Try to lay low in the meantime.]])
end)

-- If this is an independent Vampire, replace the "comrades" list with a generic kill message
hook.Add("TTTRolePopupParams", "Drunk_TTTRolePopupParams", function(cli)
    if cli:IsVampire() and cli:IsIndependentTeam() then
        return {comrades = "\n\nKill all others to win!"}
    end
end)

-------------
-- SCORING --
-------------

-- Register the scoring events for the vampire
hook.Add("Initialize", "Drunk_Scoring_Initialize", function()
    local drunk_icon = Material("icon16/drink_empty.png")
    local Event = CLSCORE.DeclareEventDisplay
    local PT = LANG.GetParamTranslation

    Event(EVENT_DRUNKSOBER, {
        text = function(e)
            return PT("ev_drunk", {player = e.ply, team = e.team})
        end,
        icon = function(e)
            return drunk_icon, "Drunk Sober"
        end})
end)

net.Receive("TTT_DrunkSober", function(len)
    local name = net.ReadString()
    local team = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_DRUNKSOBER,
        ply = name,
        team = team
    })
end)

-- Show the player's starting role color if they used to be a drunk
-- Also if they were a drunk that changed to a jester role, keep them in the independent section in case there is another jester in the same round
hook.Add("TTTScoringSummaryRender", "Drunk_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
    if IsPlayer(ply) and ply:GetNWBool("WasDrunk", false) then
        local groupRole = groupingRole
        if JESTER_ROLES[finalRole] then
            groupRole = ROLE_DRUNK
        end
        return roleFileName, groupRole, ROLE_COLORS[ROLE_DRUNK]
    end
end)

---------
-- HUD --
---------

hook.Add("TTTHUDInfoPaint", "Drunk_TTTHUDInfoPaint", function(client, label_left, label_top)
    local hide_role = false
    if ConVarExists("ttt_hide_role") then
        hide_role = GetConVar("ttt_hide_role"):GetBool()
    end

    if hide_role then return end

    if client:IsDrunk() then
        surface.SetFont("TabLarge")
        surface.SetTextColor(255, 255, 255, 230)

        local remaining = MathMax(0, GetGlobalFloat("ttt_drunk_remember", 0) - CurTime())
        local text = LANG.GetParamTranslation("drunk_hud", { time = util.SimpleTime(remaining, "%02i:%02i") })
        local _, h = surface.GetTextSize(text)

        surface.SetTextPos(label_left, ScrH() - label_top - h)
        surface.DrawText(text)
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Drunk_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_DRUNK then
        local roleColor = GetRoleTeamColor(ROLE_TEAM_INDEPENDENT)
        local html = "The " .. ROLE_STRINGS[ROLE_DRUNK] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independent</span> role who can't quite remember what team they really belong to."

        -- Sober on Timer
        html = html .. "<span style='display: block; margin-top: 10px;'>After some time has passed <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>the " .. ROLE_STRINGS[ROLE_DRUNK] .. "</span> will sober up and remember what role they are.</span>"

        -- Sober on Team Death
        html = html .. "<span style='display: block; margin-top: 10px;'>If there is only one team remaining, <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>the " .. ROLE_STRINGS[ROLE_DRUNK] .. "</span> will instantly sober up and remember they are "
        if GetGlobalBool("ttt_drunk_become_clown", false) then
            local jesterColor = GetRoleTeamColor(ROLE_TEAM_JESTER)
            html = html .. "<span style='color: rgb(" .. jesterColor.r .. ", " .. jesterColor.g .. ", " .. jesterColor.b .. ")'>" .. ROLE_STRINGS_EXT[ROLE_CLOWN] .. "</span>, ready to go on a rampage"
        else
            html = html .. "a member of the losing team. Their only goal then becomes to avenge their dead comrades"
        end
        html = html .. ".</span>"

        return html
    end
end)
