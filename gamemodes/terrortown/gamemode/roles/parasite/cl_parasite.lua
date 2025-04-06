local hook = hook
local net = net
local player = player

local PlayerIterator = player.Iterator

------------------
-- ROLE CONVARS --
------------------

local parasite_infection_time = GetConVar("ttt_parasite_infection_time")
local parasite_infection_transfer = GetConVar("ttt_parasite_infection_transfer")
local parasite_respawn_mode = GetConVar("ttt_parasite_respawn_mode")
local parasite_announce_infection = GetConVar("ttt_parasite_announce_infection")
local parasite_infection_suicide_mode = GetConVar("ttt_parasite_infection_suicide_mode")
local parasite_killer_smoke = GetConVar("ttt_parasite_killer_smoke")
local parasite_killer_footstep_time = GetConVar("ttt_parasite_killer_footstep_time")

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Parasite_Translations_Initialize", function()
    -- Target ID
    LANG.AddToLanguage("english", "target_infected", "INFECTED WITH PARASITE")

    -- HUD
    LANG.AddToLanguage("english", "infect_title", "INFECTION")
    LANG.AddToLanguage("english", "infect_help", "You will respawn when the infection bar is full.")

    -- Event
    LANG.AddToLanguage("english", "ev_infect", "{victim} infected {attacker}")

    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_parasite", "Infects players that kill them and retakes control after time.")

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

------------------
-- CUPID LOVERS --
------------------

local function IsLoverInfecting(cli, target)
    local loverSID = cli:GetNWString("TTTCupidLover", "")
    local lover = player.GetBySteamID64(loverSID)
    return IsPlayer(target) and IsPlayer(lover) and target:GetNWBool("ParasiteInfected", false) and lover:GetNWString("ParasiteInfectingTarget", "") == target:SteamID64()
end

---------------
-- TARGET ID --
---------------

hook.Add("TTTTargetIDPlayerText", "Parasite_TTTTargetIDPlayerText", function(ent, cli, text, col, secondary_text)
    if not IsPlayer(ent) then return end

    -- Skip this for Assassin so they can have their own Current Target logic (it also handles parasite infection there)
    if ((ent:GetNWBool("ParasiteInfected", false) and cli:IsTraitorTeam() and ShouldShowTraitorExtraInfo()) or IsLoverInfecting(cli, ent)) and not cli:IsAssassin() then
        return LANG.GetTranslation("target_infected"), ROLE_COLORS_RADAR[ROLE_PARASITE]
    end
end)

ROLE_IS_TARGETID_OVERRIDDEN[ROLE_PARASITE] = function(ply, target)
    if not IsPlayer(target) then return end
    if not (ply:IsTraitorTeam() and ShouldShowTraitorExtraInfo() and not ply:IsAssassin()) and not IsLoverInfecting(ply, target) then return end

    ------ icon,  ring,  text
    return false, false, target:GetNWBool("ParasiteInfected", false)
end

----------------
-- SCOREBOARD --
----------------

hook.Add("TTTScoreboardPlayerRole", "Parasite_TTTScoreboardPlayerRole", function(ply, client, c, roleStr)
    if (client:IsTraitorTeam() and ShouldShowTraitorExtraInfo() and ply:GetNWBool("ParasiteInfected", false)) or IsLoverInfecting(client, ply) then
        return c, roleStr, ROLE_PARASITE
    end
end)

hook.Add("TTTScoreboardPlayerName", "Parasite_TTTScoreboardPlayerName", function(ply, cli, text)
    -- Skip this for Assassin so they can have their own Current Target logic (it also handles parasite infection there)
    local shouldShowTraitor = cli:IsTraitorTeam() and not cli:IsAssassin() and ShouldShowTraitorExtraInfo()

    -- Show Assassin and Parasite logic if necessary
    local infected = ply:GetNWBool("ParasiteInfected", false)
    if shouldShowTraitor then
        for _, v in PlayerIterator() do
            if ply:SteamID64() == v:GetNWString("AssassinTarget", "") then
                local newText = " ("
                if infected then
                    newText = newText .. LANG.GetTranslation("target_infected") .. " | "
                end
                newText = newText .. LANG.GetPTranslation("target_assassin_target_team", { player = v:Nick() }) .. ")"
                return ply:Nick() .. newText
            end
        end
    end

    -- If we got here then we don't have to worry about the Assassin target, just check for infection
    if infected and (shouldShowTraitor or IsLoverInfecting(cli, ply)) then
        return ply:Nick() .. " (" .. LANG.GetTranslation("target_infected") .. ")"
    end
end)

ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_PARASITE] = function(ply, target)
    if not IsPlayer(target) then return end
    if not target:GetNWBool("ParasiteInfected", false) then return end
    if not (ply:IsTraitorTeam() and not ply:IsAssassin() and ShouldShowTraitorExtraInfo()) and not IsLoverInfecting(ply, target) then return end

    ------ name, role
    return true, true
end

---------------
-- INFECTING --
---------------

hook.Add("TTTSpectatorShowHUD", "Parasite_Infecting_TTTSpectatorShowHUD", function(cli, tgt)
    if not cli:IsParasite() then return end

    local max_power = parasite_infection_time:GetInt()
    if max_power <= 0 then return end

    local L = LANG.GetUnsafeLanguageTable()
    local infection_colors = {
        border = COLOR_WHITE,
        background = Color(191, 91, 22, 222),
        fill = Color(255, 127, 39, 255)
    }
    local current_power = cli:GetNWInt("ParasiteInfectionProgress", 0)

    CRHUD:PaintSpectatorProgressBar(max_power, current_power, infection_colors, L.infect_title, L.infect_help)
end)

hook.Add("TTTShouldPlayerSmoke", "Parasite_Infecting_TTShouldPlayerSmoke", function(v, client, shouldSmoke, smokeColor, smokeParticle, smokeOffset)
    if v:GetNWBool("ParasiteInfected", false) and parasite_killer_smoke:GetBool() then
        return true
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Parasite_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_PARASITE then
        local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
        local roleTeam = player.GetRoleTeam(ROLE_PARASITE, true)
        local roleTeamName, roleColor = GetRoleTeamInfo(roleTeam)
        local html = "The " .. ROLE_STRINGS[ROLE_PARASITE] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. roleTeamName .. " team</span> whose goal is to help defeat their team's enemies."

        -- Infection
        html = html .. "<span style='display: block; margin-top: 10px;'>If they are killed, they <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>infect their killer</span> watching and biding their time while the infection spreads.</span>"

        -- Respawn
        local infection_time = parasite_infection_time:GetInt()
        if infection_time > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>After " .. infection_time .. " seconds, the <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>infection becomes terminal</span>, respawning the " .. ROLE_STRINGS[ROLE_PARASITE] .. " and killing their killer.</span>"
        else
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_PARASITE] .. " will <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>be resurrected</span> if the person that killed them then dies.</span>"
        end

        html = html .. "<span style='display: block; margin-top: 10px;'>Members of the <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>traitor team</span> will know who is infected via text when they look at the player or the scoreboard. This helps to let them know <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>not to kill that person</span> which would prevent the " .. ROLE_STRINGS[ROLE_PARASITE] .. " from respawning.</span>"

        local respawn_mode = parasite_respawn_mode:GetInt()
        html = html .. "<span style='display: block; margin-top: 10px;'>When the infected player succumbs to their infection, the " .. ROLE_STRINGS[ROLE_PARASITE] .. " will respawn <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>"
        if respawn_mode == PARASITE_RESPAWN_HOST then
            html = html .. "out of their host's body</span>"
        elseif respawn_mode == PARASITE_RESPAWN_BODY then
            html = html .. "out of their own body</span> (if it still exists). If it doesn't, they will instead respawn at a random location on the map"
        elseif respawn_mode == PARASITE_RESPAWN_RANDOM then
            html = html .. "at a random location</span> on the map"
        end
        html = html .. ".</span>"

        if parasite_announce_infection:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>Be careful! Infected players <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>are notified</span> when they are infected.</span>"
        end

        local cure_mode = GetConVar("ttt_doctor_cure_mode"):GetInt()
        html = html .. "<span style='display: block; margin-top: 10px;'>Some roles can buy a cure that can remove the infection from a player. If it is used on a player that isn't infected then <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>"
        if cure_mode == DOCTOR_CURE_KILL_NONE then
            html = html .. "nothing bad will happen</span>, but "
        elseif cure_mode == DOCTOR_CURE_KILL_OWNER then
            html = html .. "the player using it will be killed</span> and "
        elseif cure_mode == DOCTOR_CURE_KILL_TARGET then
            html = html .. "the target player will be killed</span> and "
        end
        html = html .. "it will get used up.</span>"

        if parasite_infection_transfer:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>If an infected player is killed, their infection <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>is transferred</span> to their killer.</span>"
        end

        local suicide_mode = parasite_infection_suicide_mode:GetInt()
        if suicide_mode > PARASITE_SUICIDE_NONE then
            html = html .. "<span style='display: block; margin-top: 10px;'>If the infected player kills themselves "
            if suicide_mode == PARASITE_SUICIDE_RESPAWN_ALL then
                html = html .. "using any method "
            elseif suicide_mode == PARASITE_SUICIDE_RESPAWN_CONSOLE then
                html = html .. "using the 'kill' console command "
            end
            html = html .. "then the " .. ROLE_STRINGS[ROLE_PARASITE] .. " <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>will respawn immediately</span>.</span>"
        end

        local has_smoke = parasite_killer_smoke:GetBool()
        local has_footsteps = parasite_killer_footstep_time:GetInt() > 0
        -- Smoke and Killer footsteps
        if has_smoke or has_footsteps then
            html = html .. "<span style='display: block; margin-top: 10px;'>After the " .. ROLE_STRINGS[ROLE_PARASITE] .. " is killed, their killer "
            if has_smoke then
                html = html .. "is enveloped in a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>shroud of smoke</span>"
            end

            if has_smoke and has_footsteps then
                html = html .. " and "
            end

            if has_footsteps then
                html = html .. "leaves behind <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>bloody footprints</span>"
            end

            html = html .. ", revealing themselves as the " .. ROLE_STRINGS[ROLE_PARASITE] .. "'s killer to other players.</span>"
        end

        return html
    end
end)