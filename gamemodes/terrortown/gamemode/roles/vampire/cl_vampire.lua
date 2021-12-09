local hook = hook
local IsPlayer = IsPlayer
local IsValid = IsValid
local net = net
local player = player
local string = string

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Vampire_Translations_Initialize", function()
    -- Win conditions
    LANG.AddToLanguage("english", "win_vampires", "The {role} have taken over!")
    LANG.AddToLanguage("english", "ev_win_vampire", "The {role} have sucked the life out of everyone!")

    -- Events
    LANG.AddToLanguage("english", "ev_vampi", "{victim} was turned into {avampire}")
    LANG.AddToLanguage("english", "ev_vampi_revert_converted", "The last {vampire} Prime ({prime}) was killed and all their thralls had their humanity restored")
    LANG.AddToLanguage("english", "ev_vampi_kill_converted", "The last {vampire} Prime ({prime}) was killed and took all their thralls with them")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_vampire", [[You are {role}! {comrades}

You can use your fangs (left-click) to drink blood and refill your health or to fade from view (right-click).
    
Press {menukey} to receive your special equipment!]])
end)

-- If this is an independent Vampire, replace the "comrades" list with a generic kill message
hook.Add("TTTRolePopupParams", "Vampire_TTTRolePopupParams", function(cli)
    if cli:IsVampire() and cli:IsIndependentTeam() then
        return {comrades = "\n\nKill all others to win!"}
    end
end)

---------------
-- TARGET ID --
---------------

-- Show "KILL" icon over all non-jester team heads
hook.Add("TTTTargetIDPlayerKillIcon", "Vampire_TTTTargetIDPlayerKillIcon", function(ply, cli, showKillIcon, showJester)
    if cli:IsVampire() and GetGlobalBool("ttt_vampire_show_target_icon", false) and not showJester then
        return true
    end
end)

-------------
-- SCORING --
-------------

-- Register the scoring events for the vampire
hook.Add("Initialize", "Vampire_Scoring_Initialize", function()
    local vampire_icon = Material("icon16/user_gray.png")
    local heart_icon = Material("icon16/heart.png")
    local wrong_icon   = Material("icon16/cross.png")
    local Event = CLSCORE.DeclareEventDisplay
    local PT = LANG.GetParamTranslation

    Event(EVENT_VAMPIFIED, {
        text = function(e)
            return PT("ev_vampi", {victim = e.vic, avampire = ROLE_STRINGS_EXT[ROLE_VAMPIRE]})
        end,
        icon = function(e)
            return vampire_icon, "Vampified"
        end})

    Event(EVENT_VAMPPRIME_DEATH, {
        text = function(e)
            if e.mode == VAMPIRE_DEATH_REVERT_CONVERTED then
               return PT("ev_vampi_revert_converted", {prime = e.prime, vampire = ROLE_STRINGS[ROLE_VAMPIRE]})
            elseif e.mode == VAMPIRE_DEATH_KILL_CONVERTED then
               return PT("ev_vampi_kill_converted", {prime = e.prime, vampire = ROLE_STRINGS[ROLE_VAMPIRE]})
            end
        end,
        icon = function(e)
            if e.mode == VAMPIRE_DEATH_REVERT_CONVERTED then
               return heart_icon, "Restored"
            elseif e.mode == VAMPIRE_DEATH_KILL_CONVERTED then
               return wrong_icon, "Killed"
            end
        end})
end)

net.Receive("TTT_Vampified", function(len)
    local name = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_VAMPIFIED,
        vic = name
    })
end)

net.Receive("TTT_VampirePrimeDeath", function(len)
    local mode = net.ReadUInt(4)
    local name = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_VAMPPRIME_DEATH,
        mode = mode,
        prime = name
    })
end)

-- Show the player's starting role icon if they were converted to a vampire and group them with their original team
hook.Add("TTTScoringSummaryRender", "Vampire_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
    if finalRole == ROLE_VAMPIRE then
        return ROLE_STRINGS_SHORT[startingRole], startingRole
    end
end)

----------------
-- WIN CHECKS --
----------------

hook.Add("TTTScoringWinTitle", "Vampire_TTTScoringWinTitle", function(wintype, wintitles, title, secondary_win_role)
    if wintype == WIN_VAMPIRE then
        return { txt = "hilite_win_role_plural", params = { role = string.upper(ROLE_STRINGS_PLURAL[ROLE_VAMPIRE]) }, c = ROLE_COLORS[ROLE_VAMPIRE] }
    end
end)

------------
-- EVENTS --
------------

hook.Add("TTTEventFinishText", "Vampire_TTTEventFinishText", function(e)
    if e.win == WIN_VAMPIRE then
        return LANG.GetParamTranslation("ev_win_vampire", { role = string.lower(ROLE_STRINGS[ROLE_VAMPIRE]) })
    end
end)

hook.Add("TTTEventFinishIconText", "Vampire_TTTEventFinishIconText", function(e, win_string, role_string)
    if e.win == WIN_VAMPIRE then
        return win_string, ROLE_STRINGS[ROLE_VAMPIRE]
    end
end)

------------------
-- HIGHLIGHTING --
------------------

local vampire_vision = false
local jesters_visible_to_traitors = false
local jesters_visible_to_monsters = false
local jesters_visible_to_independents = false
local vision_enabled = false
local client = nil

local function EnableVampireHighlights()
    -- Handle vampire targeting and non-traitor team logic
    -- Traitor logic is handled in cl_init and does not need to be duplicated here
    hook.Add("PreDrawHalos", "Vampire_Highlight_PreDrawHalos", function()
        local hasFangs = client.GetActiveWeapon and IsValid(client:GetActiveWeapon()) and client:GetActiveWeapon():GetClass() == "weapon_vam_fangs"
        local hideEnemies = not vampire_vision or not hasFangs

        -- Handle logic differently depending on which team they are on
        local allies = {}
        local showJesters = false
        local traitorAllies = false
        local onlyShowEnemies = false
        if MONSTER_ROLES[ROLE_VAMPIRE] then
            allies = GetTeamRoles(MONSTER_ROLES)
            showJesters = jesters_visible_to_monsters
        elseif INDEPENDENT_ROLES[ROLE_VAMPIRE] then
            allies = GetTeamRoles(INDEPENDENT_ROLES)
            showJesters = jesters_visible_to_independents
        else
            allies = GetTeamRoles(TRAITOR_ROLES)
            showJesters = jesters_visible_to_traitors
            traitorAllies = true
            onlyShowEnemies = true
        end

        OnPlayerHighlightEnabled(client, allies, showJesters, hideEnemies, traitorAllies, onlyShowEnemies)
    end)
end

hook.Add("TTTUpdateRoleState", "Vampire_Highlight_TTTUpdateRoleState", function()
    client = LocalPlayer()
    vampire_vision = GetGlobalBool("ttt_vampire_vision_enable", false)
    jesters_visible_to_traitors = GetGlobalBool("ttt_jesters_visible_to_traitors", false)
    jesters_visible_to_monsters = GetGlobalBool("ttt_jesters_visible_to_monsters", false)
    jesters_visible_to_independents = GetGlobalBool("ttt_jesters_visible_to_independents", false)

    -- Disable highlights on role change
    if vision_enabled then
        hook.Remove("PreDrawHalos", "Vampire_Highlight_PreDrawHalos")
        vision_enabled = false
    end
end)

-- Handle enabling and disabling of highlighting
hook.Add("Think", "Vampire_Highlight_Think", function()
    if not IsPlayer(client) or not client:Alive() or client:IsSpec() then return end

    if vampire_vision and client:IsVampire() then
        if not vision_enabled then
            EnableVampireHighlights()
            vision_enabled = true
        end
    else
        vision_enabled = false
    end

    if not vision_enabled then
        hook.Remove("PreDrawHalos", "Vampire_Highlight_PreDrawHalos")
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Vampire_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_VAMPIRE then
        -- Use this for highlighting things like "blood"
        local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
        local roleTeam = player.GetRoleTeam(ROLE_VAMPIRE, true)
        local roleTeamString, roleTeamColor = GetRoleTeamInfo(roleTeam, true)

        local html = "The " .. ROLE_STRINGS[ROLE_VAMPIRE] .. " is a member of the <span style='color: rgb(" .. roleTeamColor.r .. ", " .. roleTeamColor.g .. ", " .. roleTeamColor.b .. ")'>" .. string.lower(roleTeamString) .. " team</span>."

        -- Draining
        html = html .. "<span style='display: block; margin-top: 10px;'>They can heal themselves by <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>draining blood</span> from "
        local drainEnabled = GetGlobalBool("ttt_vampire_drain_enable", true)
        if drainEnabled then
            html = html .. "both living players and "
        end
        html = html .. "corpses using their fangs (Hold the attack button down when near a target).</span>"

        -- Fade
        html = html .. "<span style='display: block; margin-top: 10px;'>By using the secondary attack with their fangs, they can also <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>fade from view</span> and gain a temporary speed bonus. This is useful for either chasing down prey or running away from conflict.</span>"

        -- Convert
        if drainEnabled and GetGlobalBool("ttt_vampire_convert_enable", false) then
            html = html .. "<span style='display: block; margin-top: 10px;'>"
            if GetGlobalBool("ttt_vampire_prime_only_convert", true) then
                html = html .. "Prime "
            end
            html = html .. ROLE_STRINGS_PLURAL[ROLE_VAMPIRE] .. " can convert living targets to their team by <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>draining their blood</span> the correct amount (Look for the message on the drain progress bar for when to release).</span>"

            -- Prime Death Mode
            local primeMode = GetGlobalInt("ttt_vampire_prime_death_mode", VAMPIRE_DEATH_NONE)
            if primeMode > VAMPIRE_DEATH_NONE then
                html = html .. "<span style='display: block; margin-top: 10px;'>If the Prime " .. ROLE_STRINGS[ROLE_VAMPIRE] .. " is killed, all of the " .. ROLE_STRINGS[ROLE_VAMPIRE] .. " spawn they made will be "

                if primeMode == VAMPIRE_DEATH_KILL_CONVERTED then
                    html = html .. "<span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>killed as well</span>"
                else
                    html = html .. "<span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>returned to their original role</span>"
                end

                html = html .. ".</span>"
            end
        end

        -- Vision
        local hasVision = GetGlobalBool("ttt_vampire_vision_enable", false)
        if hasVision then
            html = html .. "<span style='display: block; margin-top: 10px;'>Their <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>hunger for blood</span> helps them see their targets through walls by highlighting their enemies.</span>"
        end

        -- Target ID
        if GetGlobalBool("ttt_vampire_show_target_icon", false) then
            html = html .. "<span style='display: block; margin-top: 10px;'>Their targets can"
            if hasVision then
                html = html .. " also"
            end
            html = html .. " be identified by the <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>KILL</span> icon floating over their heads.</span>"
        end

        return html
    end
end)