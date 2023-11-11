local hook = hook
local math = math
local string = string
local surface = surface
local table = table
local util = util

local MathMax = math.max
local StringUpper = string.upper

-------------
-- CONVARS --
-------------

local infected_prime = GetConVar("ttt_infected_prime")
local infected_cough_enabled = GetConVar("ttt_infected_cough_enabled")
local infected_respawn_enabled = GetConVar("ttt_infected_respawn_enabled")
local infected_show_icon = GetConVar("ttt_infected_show_icon")
local infected_succumb_time = GetConVar("ttt_infected_succumb_time")
local infected_full_health = GetConVar("ttt_infected_full_health")

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Infected_Translations_Initialize", function()
    -- Events
    LANG.AddToLanguage("english", "ev_infected_succumbed", "The {infected} ({victim}) succumbed to their disease and became {azombie}")

    -- HUD
    LANG.AddToLanguage("english", "infected_hud", "You will succumb in: {time}")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_infected", [[You are {role}! You have a secret disease
that will eventually turn you into {azombie}!
Help your team win or wait until you turn
and spread your disease to victory...]])
end)

----------------
-- ROLE POPUP --
----------------

hook.Add("TTTRolePopupParams", "Infected_TTTRolePopupParams", function(cli)
    if cli:IsInfected() then
        return { azombie = ROLE_STRINGS_EXT[ROLE_ZOMBIE] }
    end
end)

---------------
-- TARGET ID --
---------------

-- Reveal the infected to all zombie allies if enabled
hook.Add("TTTTargetIDPlayerRoleIcon", "Infected_TTTTargetIDPlayerRoleIcon", function(ply, client, role, noz, colorRole, hideInfected, showJester, hideBodysnatcher)
    if not infected_show_icon:GetBool() then return end
    if ply:IsActiveInfected() and client:IsZombieAlly() then
        return ROLE_INFECTED, false
    end
end)

hook.Add("TTTTargetIDPlayerRing", "Infected_TTTTargetIDPlayerRing", function(ent, client, ringVisible)
    if not infected_show_icon:GetBool() then return end
    if IsPlayer(ent) and ent:IsActiveInfected() and client:IsZombieAlly() then
        return true, ROLE_COLORS_RADAR[ROLE_INFECTED]
    end
end)

hook.Add("TTTTargetIDPlayerText", "Infected_TTTTargetIDPlayerText", function(ent, client, text, clr, secondaryText)
    if not infected_show_icon:GetBool() then return end
    if IsPlayer(ent) and ent:IsActiveInfected() and client:IsZombieAlly() then
        return StringUpper(ROLE_STRINGS[ROLE_INFECTED]), ROLE_COLORS_RADAR[ROLE_INFECTED]
    end
end)

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

hook.Add("TTTScoreboardPlayerRole", "Infected_TTTScoreboardPlayerRole", function(ply, client, color, roleFileName)
    if not infected_show_icon:GetBool() then return end
    if ply:IsActiveInfected() and client:IsZombieAlly() then
        return ROLE_COLORS_SCOREBOARD[ROLE_INFECTED], ROLE_STRINGS_SHORT[ROLE_INFECTED]
    end
end)

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
hook.Add("Initialize", "Infected_Scoring_Initialize", function()
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

---------
-- HUD --
---------

hook.Add("TTTHUDInfoPaint", "Infected_TTTHUDInfoPaint", function(client, label_left, label_top, active_labels)
    local hide_role = false
    if ConVarExists("ttt_hide_role") then
        hide_role = GetConVar("ttt_hide_role"):GetBool()
    end

    if hide_role then return end

    if client:IsActiveInfected() then
        surface.SetFont("TabLarge")
        surface.SetTextColor(255, 255, 255, 230)

        local remaining = MathMax(0, GetGlobalFloat("ttt_infected_succumb", 0) - CurTime())
        local text = LANG.GetParamTranslation("infected_hud", { time = util.SimpleTime(remaining, "%02i:%02i") })
        local _, h = surface.GetTextSize(text)

        -- Move this up based on how many other labels here are
        label_top = label_top + (20 * #active_labels)

        surface.SetTextPos(label_left, ScrH() - label_top - h)
        surface.DrawText(text)

        -- Track that the label was added so others can position accurately
        table.insert(active_labels, "infected")
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Infected_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_INFECTED then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
        local zombieColor = ROLE_COLORS[ROLE_ZOMBIE]
        local html = "The " .. ROLE_STRINGS[ROLE_INFECTED] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> who is hiding a secret deadly disease."

        local succumbTime = infected_succumb_time:GetInt()
        html = html .. "<span style='display: block; margin-top: 10px;'>After " .. succumbTime .. " seconds, the " .. ROLE_STRINGS[ROLE_INFECTED] .. " will <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>succumb to their disease</span> and change into <span style='color: rgb(" .. zombieColor.r .. ", " .. zombieColor.g .. ", " .. zombieColor.b .. ")'>" .. ROLE_STRINGS_EXT[ROLE_ZOMBIE] .. "</span>.</span>"

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
end)