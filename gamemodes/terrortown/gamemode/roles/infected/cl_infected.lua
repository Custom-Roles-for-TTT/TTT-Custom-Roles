local hook = hook
local math = math
local net = net
local string = string
local surface = surface
local table = table
local util = util

local AddHook = hook.Add
local RemoveHook = hook.Remove
local MathMax = math.max
local StringUpper = string.upper

-------------
-- CONVARS --
-------------

local infected_block_win = GetConVar("ttt_infected_block_win")
local infected_is_jester = GetConVar("ttt_infected_is_jester")
local infected_is_independent = GetConVar("ttt_infected_is_independent")
local infected_prime = GetConVar("ttt_infected_prime")
local infected_cough_enabled = GetConVar("ttt_infected_cough_enabled")
local infected_respawn_enabled = GetConVar("ttt_infected_respawn_enabled")
local infected_show_icon = GetConVar("ttt_infected_show_icon")
local infected_succumb_time = GetConVar("ttt_infected_succumb_time")
local infected_full_health = GetConVar("ttt_infected_full_health")
local hide_role = GetConVar("ttt_hide_role")

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "Infected_Translations_Initialize", function()
    -- Win conditions
    LANG.AddToLanguage("english", "win_infected", "The {role} has eliminated everyone before succumbing to their infection!")
    LANG.AddToLanguage("english", "ev_win_infected", "The {role} has beat their infection... through murder!")

    -- Events
    LANG.AddToLanguage("english", "ev_infected_succumbed", "The {infected} ({victim}) succumbed to their disease and became {azombie}")

    -- HUD
    LANG.AddToLanguage("english", "infected_hud", "You will succumb in: {time}")

    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_infected", "Turns into a Zombie if the round goes on for too long.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_infected", [[You are {role}! You have a secret disease
that will eventually turn you into {azombie}!
Help your team win or wait until you turn
and spread your disease to victory...]])
    LANG.AddToLanguage("english", "info_popup_infected_jester", [[You are {role}! You have a secret disease
that will eventually turn you into {azombie}!
Bide your time and wait until you turn
and spread your disease to victory...]])
    LANG.AddToLanguage("english", "info_popup_infected_indep", [[You are {role}! You have a secret disease
that will eventually turn you into {azombie}!
Work on eliminating your enemies or wait until you turn
and spread your disease to victory...]])
end)

----------------
-- ROLE POPUP --
----------------

local function Infected_TTTRolePopupParams(cli)
    if cli:IsInfected() then
        return { azombie = ROLE_STRINGS_EXT[ROLE_ZOMBIE] }
    end
end

local function Infected_TTTRolePopupRoleStringOverride(cli, roleString)
    if not IsPlayer(cli) or not cli:IsInfected() then return end

    if infected_is_independent:GetBool() then
        return roleString .. "_indep"
    elseif infected_is_jester:GetBool() then
        return roleString .. "_jester"
    end
end

---------------
-- TARGET ID --
---------------

-- Reveal the infected to all zombie allies if enabled
local function Infected_TTTTargetIDPlayerRoleIcon(ply, client, role, noz, colorRole, hideInfected, showJester, hideBodysnatcher)
    if not infected_show_icon:GetBool() then return end
    if ply:IsActiveInfected() and client:IsZombieAlly() then
        return ROLE_INFECTED, false
    end
end

local function Infected_TTTTargetIDPlayerRing(ent, client, ringVisible)
    if not infected_show_icon:GetBool() then return end
    if IsPlayer(ent) and ent:IsActiveInfected() and client:IsZombieAlly() then
        return true, ROLE_COLORS_RADAR[ROLE_INFECTED]
    end
end

local function Infected_TTTTargetIDPlayerText(ent, client, text, clr, secondaryText)
    if not infected_show_icon:GetBool() then return end
    if IsPlayer(ent) and ent:IsActiveInfected() and client:IsZombieAlly() then
        return StringUpper(ROLE_STRINGS[ROLE_INFECTED]), ROLE_COLORS_RADAR[ROLE_INFECTED]
    end
end

ROLE_IS_TARGETID_OVERRIDDEN[ROLE_INFECTED] = function(ply, target)
    if not infected_show_icon:GetBool() then return end
    if not IsPlayer(target) then return end
    if not target:IsActiveInfected() then return end
    if not ply:IsZombieAlly() then return end

    ------ icon, ring, text
    return true, true, true
end

----------------
-- SCOREBOARD --
----------------

local function Infected_TTTScoreboardPlayerRole(ply, client, color, roleFileName)
    if not infected_show_icon:GetBool() then return end
    if ply:IsActiveInfected() and client:IsZombieAlly() then
        return ROLE_COLORS_SCOREBOARD[ROLE_INFECTED], ROLE_STRINGS_SHORT[ROLE_INFECTED]
    end
end

ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_INFECTED] = function(ply, target)
    if not infected_show_icon:GetBool() then return end
    if not IsPlayer(target) then return end
    if not target:IsActiveInfected() then return end
    if not ply:IsZombieAlly() then return end

    ------ name,  role
    return false, true
end

-------------
-- SCORING --
-------------

-- Register the scoring event for the infected
AddHook("Initialize", "Infected_Scoring_Initialize", function()
    local zombie_icon = Material("icon16/user_green.png")
    local Event = CLSCORE.DeclareEventDisplay
    local PT = LANG.GetParamTranslation

    Event(EVENT_INFECTEDSUCCUMBED, {
        text = function(e)
            return PT("ev_infected_succumbed", {victim = e.vic, infected = ROLE_STRINGS[ROLE_INFECTED], azombie = ROLE_STRINGS_EXT[ROLE_ZOMBIE]})
        end,
        icon = function(e)
            return zombie_icon, "Succumbed"
        end})
end)

net.Receive("TTT_InfectedSuccumbed", function(len)
    local victim = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_INFECTEDSUCCUMBED,
        vic = victim
    })
end)

----------------
-- WIN CHECKS --
----------------

local function Infected_TTTScoringWinTitle(wintype, wintitles, title, secondary_win_role)
    if wintype == WIN_INFECTED then
        return { txt = "hilite_win_role_singular", params = { role = string.upper(ROLE_STRINGS[ROLE_INFECTED]) }, c = ROLE_COLORS[ROLE_INFECTED] }
    end
end

------------
-- EVENTS --
------------

local function Infected_TTTEventFinishText(e)
    if e.win == WIN_INFECTED then
        return LANG.GetParamTranslation("ev_win_infected", { role = string.lower(ROLE_STRINGS[ROLE_INFECTED]) })
    end
end

local function Infected_TTTEventFinishIconText(e, win_string, role_string)
    if e.win == WIN_INFECTED then
        return win_string, ROLE_STRINGS[ROLE_INFECTED]
    end
end

---------
-- HUD --
---------

local function Infected_TTTHUDInfoPaint(client, label_left, label_top, active_labels)
    if hide_role:GetBool() then return end

    if client:IsActiveInfected() then
        surface.SetFont("TabLarge")
        surface.SetTextColor(255, 255, 255, 230)

        local remaining = MathMax(0, GetGlobalFloat("ttt_infected_succumb", 0) - CurTime())
        local text = LANG.GetParamTranslation("infected_hud", { time = util.SimpleTime(remaining, "%02i:%02i") })
        local _, h = surface.GetTextSize(text)

        -- Move this up based on how many other labels there are
        label_top = label_top + (20 * #active_labels)

        surface.SetTextPos(label_left, ScrH() - label_top - h)
        surface.DrawText(text)

        -- Track that the label was added so others can position accurately
        table.insert(active_labels, "infected")
    end
end

--------------
-- TUTORIAL --
--------------

local function Infected_TTTTutorialRoleText(role, titleLabel)
    if role == ROLE_INFECTED then
        local roleTeam = player.GetRoleTeam(ROLE_INFECTED, true)
        local roleTeamString, roleTeamColor = GetRoleTeamInfo(roleTeam, true)
        local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
        local zombieColor = ROLE_COLORS[ROLE_ZOMBIE]
        local html = "The " .. ROLE_STRINGS[ROLE_INFECTED] .. " is a member of the <span style='color: rgb(" .. roleTeamColor.r .. ", " .. roleTeamColor.g .. ", " .. roleTeamColor.b .. ")'>" .. string.lower(roleTeamString) .. " team</span> who is hiding a secret deadly disease."

        local succumbTime = infected_succumb_time:GetInt()
        html = html .. "<span style='display: block; margin-top: 10px;'>After " .. succumbTime .. " seconds, the " .. ROLE_STRINGS[ROLE_INFECTED] .. " will <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>succumb to their disease</span> and change into <span style='color: rgb(" .. zombieColor.r .. ", " .. zombieColor.g .. ", " .. zombieColor.b .. ")'>" .. ROLE_STRINGS_EXT[ROLE_ZOMBIE] .. "</span>.</span>"

        -- If we're not an innocent and respawn blocking is enabled, let the player know
        if roleTeam ~= ROLE_TEAM_INNOCENT and infected_block_win:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>" .. ROLE_STRINGS[ROLE_INFECTED] .. ".</span>"
            html = html .. "<span style='display: block; margin-top: 10px;'>When a team would normally win, the " .. ROLE_STRINGS[ROLE_INFECTED] .. " <span style='color: rgb(" .. roleTeamColor.r .. ", " .. roleTeamColor.g .. ", " .. roleTeamColor.b .. ")'>immediately succumbs</span> to their infection, changing into <span style='color: rgb(" .. zombieColor.r .. ", " .. zombieColor.g .. ", " .. zombieColor.b .. ")'>" .. ROLE_STRINGS_EXT[ROLE_ZOMBIE] .. "</span> and allowing them to <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>go on a rampage</span> and win by surprise.</span>"
        end

        if infected_show_icon:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>Before the " .. ROLE_STRINGS[ROLE_INFECTED] .. "'s infection has taken hold, they are <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>identifiable</span> to their future <span style='color: rgb(" .. zombieColor.r .. ", " .. zombieColor.g .. ", " .. zombieColor.b .. ")'>" .. ROLE_STRINGS[ROLE_ZOMBIE] .. " comrades</span> via role icons and displayed colors.</span>"
        end

        if infected_full_health:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>Once the " .. ROLE_STRINGS[ROLE_INFECTED] .. " has succumbed to their infection, they are <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>healed back to full health</span>.</span>"
        end

        if infected_respawn_enabled:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_INFECTED] .. " will also turn into " .. ROLE_STRINGS_EXT[ROLE_ZOMBIE] .. " if <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>they are killed</span>.</span>"
        end

        if infected_prime:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_INFECTED] .. " will come back back as a <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>prime " .. ROLE_STRINGS[ROLE_ZOMBIE] .. "</span>, meaning they have all the abilities and stat bonuses that " .. ROLE_STRINGS_EXT[ROLE_ZOMBIE] .. " spawning into the round normally would have.</span>"
        end

        if infected_cough_enabled:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>While the " .. ROLE_STRINGS[ROLE_INFECTED] .. " is still alive, they will <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>periodically cough</span> which other players who are observant can use to identify them.</span>"
        end

        return html
    end
end

------------------
-- REGISTRATION --
------------------

ROLE_REGISTER_HOOKS[ROLE_INFECTED] = function()
    AddHook("TTTEventFinishIconText", "Infected_TTTEventFinishIconText", Infected_TTTEventFinishIconText)
    AddHook("TTTEventFinishText", "Infected_TTTEventFinishText", Infected_TTTEventFinishText)
    AddHook("TTTHUDInfoPaint", "Infected_TTTHUDInfoPaint", Infected_TTTHUDInfoPaint)
    AddHook("TTTRolePopupParams", "Infected_TTTRolePopupParams", Infected_TTTRolePopupParams)
    AddHook("TTTRolePopupRoleStringOverride", "Infected_TTTRolePopupRoleStringOverride", Infected_TTTRolePopupRoleStringOverride)
    AddHook("TTTScoreboardPlayerRole", "Infected_TTTScoreboardPlayerRole", Infected_TTTScoreboardPlayerRole)
    AddHook("TTTScoringWinTitle", "Infected_TTTScoringWinTitle", Infected_TTTScoringWinTitle)
    AddHook("TTTTargetIDPlayerRing", "Infected_TTTTargetIDPlayerRing", Infected_TTTTargetIDPlayerRing)
    AddHook("TTTTargetIDPlayerRoleIcon", "Infected_TTTTargetIDPlayerRoleIcon", Infected_TTTTargetIDPlayerRoleIcon)
    AddHook("TTTTargetIDPlayerText", "Infected_TTTTargetIDPlayerText", Infected_TTTTargetIDPlayerText)
    AddHook("TTTTutorialRoleText", "Infected_TTTTutorialRoleText", Infected_TTTTutorialRoleText)
end

ROLE_UNREGISTER_HOOKS[ROLE_INFECTED] = function()
    RemoveHook("TTTEventFinishIconText", "Infected_TTTEventFinishIconText")
    RemoveHook("TTTEventFinishText", "Infected_TTTEventFinishText")
    RemoveHook("TTTHUDInfoPaint", "Infected_TTTHUDInfoPaint")
    RemoveHook("TTTRolePopupParams", "Infected_TTTRolePopupParams")
    RemoveHook("TTTRolePopupRoleStringOverride", "Infected_TTTRolePopupRoleStringOverride")
    RemoveHook("TTTScoreboardPlayerRole", "Infected_TTTScoreboardPlayerRole")
    RemoveHook("TTTScoringWinTitle", "Infected_TTTScoringWinTitle")
    RemoveHook("TTTTargetIDPlayerRing", "Infected_TTTTargetIDPlayerRing")
    RemoveHook("TTTTargetIDPlayerRoleIcon", "Infected_TTTTargetIDPlayerRoleIcon")
    RemoveHook("TTTTargetIDPlayerText", "Infected_TTTTargetIDPlayerText")
    RemoveHook("TTTTutorialRoleText", "Infected_TTTTutorialRoleText")
end