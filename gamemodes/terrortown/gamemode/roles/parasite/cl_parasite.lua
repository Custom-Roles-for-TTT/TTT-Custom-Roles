local hook = hook
local net = net
local pairs = pairs

local GetAllPlayers = player.GetAll

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Parasite_Translations_Initialize", function()
    -- Weapons
    LANG.AddToLanguage("english", "cure_help_pri", "{primaryfire} to cure another player.")
    LANG.AddToLanguage("english", "cure_help_sec", "{secondaryfire} to cure yourself.")
    LANG.AddToLanguage("english", "cure_desc", [[Use on a player to cure them of {parasites}.

Using this on a player who is not infected will kill them!]])

    -- Target ID
    LANG.AddToLanguage("english", "target_infected", "INFECTED WITH PARASITE")

    -- HUD
    LANG.AddToLanguage("english", "infect_title", "INFECTION")
    LANG.AddToLanguage("english", "infect_help", "You will respawn when the infection bar is full.")

    -- Event
    LANG.AddToLanguage("english", "ev_infect", "{victim} infected {attacker}")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_parasite", [[You are {role}! {comrades}

Infect those that kill you and wait patiently for a chance to take control.
Make sure you lay low as your host must stay alive in order for you to
respawn. Try to avoid getting them cured or killed!

Press {menukey} to receive your special equipment!]])
end)

-------------
-- SCORING --
-------------

hook.Add("Initialize", "Parasite_Scoring_Initialize", function()
    local haunt_icon = Material("icon16/group.png")
    local PT = LANG.GetParamTranslation
    local Event = CLSCORE.DeclareEventDisplay
    Event(EVENT_INFECT, {
        text = function(e)
            return PT("ev_infect", {victim = e.vic, attacker = e.att})
        end,
        icon = function(e)
            return haunt_icon, "Infected"
        end})
end)

net.Receive("TTT_ParasiteInfect", function(len)
    local victim = net.ReadString()
    local attacker = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_INFECT,
        vic = victim,
        att = attacker
    })
end)

---------------
-- TARGET ID --
---------------

hook.Add("TTTTargetIDPlayerText", "Parasite_TTTTargetIDPlayerText", function(ent, cli, text, col, secondary_text)
    -- Skip this for Assassin so they can have their own Current Target logic (it also handles parasite infection there)
    if cli:IsTraitorTeam() and not cli:IsAssassin() and IsPlayer(ent) and ent:GetNWBool("ParasiteInfected", false) then
        return LANG.GetTranslation("target_infected"), ROLE_COLORS_RADAR[ROLE_PARASITE]
    end
end)

ROLE_IS_TARGETID_OVERRIDDEN[ROLE_PARASITE] = function(ply, target)
    if not ply:IsTraitorTeam() or ply:IsAssassin() then return end
    if not IsPlayer(target) then return end

    ------ icon,  ring,  text
    return false, false, target:GetNWBool("ParasiteInfected", false)
end

----------------
-- SCOREBOARD --
----------------

hook.Add("TTTScoreboardPlayerRole", "Parasite_TTTScoreboardPlayerRole", function(ply, client, c, roleStr)
    if client:IsTraitorTeam() and ShouldShowTraitorExtraInfo() and ply:GetNWBool("ParasiteInfected", false) then
        return c, roleStr, ROLE_PARASITE
    end
end)

hook.Add("TTTScoreboardPlayerName", "Parasite_TTTScoreboardPlayerName", function(ply, cli, text)
    -- Skip this for Assassin so they can have their own Current Target logic (it also handles parasite infection there)
    if not cli:IsTraitorTeam() or cli:IsAssassin() then return end
    if not ShouldShowTraitorExtraInfo() then return end

    -- Show Assassin and Parasite logic if necessary
    local infected = ply:GetNWBool("ParasiteInfected", false)
    for _, v in pairs(GetAllPlayers()) do
        if ply:Nick() == v:GetNWString("AssassinTarget", "") then
            local newText = " ("
            if infected then
                newText = newText .. LANG.GetTranslation("target_infected") .. " | "
            end
            newText = newText .. LANG.GetPTranslation("target_assassin_target_team", { player = v:Nick() }) .. ")"
            return ply:Nick() .. newText
        end
    end

    -- If we got here then we don't have to worry about the Assassin target, just check for infection
    if infected then
        return ply:Nick() .. " (" .. LANG.GetTranslation("target_infected") .. ")"
    end
end)

ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_PARASITE] = function(ply, target)
    if not ply:IsTraitorTeam() or ply:IsAssassin() then return end
    if not IsPlayer(target) then return end
    if not ShouldShowTraitorExtraInfo() then return end
    if not target:GetNWBool("ParasiteInfected", false) then return end

    ------ name, role
    return true, true
end

---------------
-- INFECTING --
---------------

hook.Add("TTTSpectatorShowHUD", "Parasite_Infecting_TTTSpectatorShowHUD", function(cli, tgt)
    if not cli:IsParasite() then return end

    local L = LANG.GetUnsafeLanguageTable()
    local infection_colors = {
        border = COLOR_WHITE,
        background = Color(191, 91, 22, 222),
        fill = Color(255, 127, 39, 255)
    }
    local max_power = GetGlobalInt("ttt_parasite_infection_time", 90)
    local current_power = cli:GetNWInt("ParasiteInfectionProgress", 0)

    CRHUD:PaintPowersHUD(nil, max_power, current_power, infection_colors, L.infect_title, L.infect_help)
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Parasite_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_PARASITE then
        local roleColor = ROLE_COLORS[ROLE_TRAITOR]
        local html = "The " .. ROLE_STRINGS[ROLE_PARASITE] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>traitor team</span> whose goal is to help defeat their team's enemies."

        -- Infection
        html = html .. "<span style='display: block; margin-top: 10px;'>If they are killed, they <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>infect their killer</span> watching and biding their time while the infection spreads.</span>"

        -- Respawn
        local infection_time = GetGlobalInt("ttt_parasite_infection_time", 45)
        html = html .. "<span style='display: block; margin-top: 10px;'>After " .. infection_time .. " seconds, the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>infection becomes terminal</span>, respawning the " .. ROLE_STRINGS[ROLE_PARASITE] .. " and killing their killer.</span>"

        html = html .. "<span style='display: block; margin-top: 10px;'>Members of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>traitor team</span> will know who is infected via text when they look at the player or the scoreboard. This helps to let them know <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>not to kill that person</span> which would prevent the " .. ROLE_STRINGS[ROLE_PARASITE] .. " from respawning.</span>"

        return html
    end
end)