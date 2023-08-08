local hook = hook
local net = net

-------------
-- CONVARS --
-------------

local swapper_killer_health = GetConVar("ttt_swapper_killer_health")
local swapper_healthstation_reduce_max = GetConVar("ttt_swapper_healthstation_reduce_max")


------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Swapper_Translations_Initialize", function()
    -- Event
    LANG.AddToLanguage("english", "ev_swap", "{victim} swapped with {attacker}")

    -- Scoring
    LANG.AddToLanguage("english", "score_swapper_killed", "Killed")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_swapper", [[You are {role}! {traitors} think you are {ajester} and you
deal no damage however, if anyone kills you, they become
the {swapper} and you take their role and can join the fight.]])
end)

-------------
-- SCORING --
-------------

-- Register the scoring events for the swapper
hook.Add("Initialize", "Swapper_Scoring_Initialize", function()
    local swap_icon = Material("icon16/arrow_refresh_small.png")
    local Event = CLSCORE.DeclareEventDisplay
    local PT = LANG.GetParamTranslation
    Event(EVENT_SWAPPER, {
        text = function(e)
            return PT("ev_swap", {victim = e.vic, attacker = e.att})
        end,
        icon = function(e)
            return swap_icon, "Swapped"
        end})
end)

net.Receive("TTT_SwapperSwapped", function(len)
    local victim = net.ReadString()
    local attacker = net.ReadString()
    local vicsid = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_SWAPPER,
        vic = victim,
        att = attacker,
        sid64 = vicsid,
        bonus = 2
    })
end)

-- Show who the current swapper killed (if anyone)
hook.Add("TTTScoringSummaryRender", "Swapper_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
    if not IsPlayer(ply) then return end

    if ply:IsSwapper() then
        local swappedWith = ply:GetNWString("SwappedWith", "")
        if swappedWith ~= "" then
            return roleFileName, groupingRole, roleColor, name, swappedWith, LANG.GetTranslation("score_swapper_killed")
        end
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Swapper_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_SWAPPER then
        local roleColor = GetRoleTeamColor(ROLE_TEAM_JESTER)
        local html = "The " .. ROLE_STRINGS[ROLE_SWAPPER] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>jester</span> role whose goal is to be killed by another player and steal their role."

        html = html .. "<span style='display: block; margin-top: 10px;'>After <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>swapping</span>, they take over the goal of their new role.</span>"

        if swapper_killer_health:GetInt() > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>Be careful, the player who <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>kills the " .. ROLE_STRINGS[ROLE_SWAPPER] .."</span> then <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>becomes the " .. ROLE_STRINGS[ROLE_SWAPPER] .."</span>. Make sure to not kill them back!</span>"
        end

        if swapper_healthstation_reduce_max:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>When the " .. ROLE_STRINGS[ROLE_SWAPPER] .. " uses a health station, their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>maximum health is reduced</span> toward their current health instead of them being healed.</span>"
        end

        return html
    end
end)