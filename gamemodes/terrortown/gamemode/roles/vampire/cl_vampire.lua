local hook = hook
local IsValid = IsValid
local net = net
local player = player
local string = string

local RemoveHook = hook.Remove

-------------
-- CONVARS --
-------------

local vampire_show_target_icon = GetConVar("ttt_vampire_show_target_icon")
local vampire_vision_enabled = GetConVar("ttt_vampire_vision_enabled")
local vampire_prime_death_mode = GetConVar("ttt_vampire_prime_death_mode")
local vampire_damage_reduction = GetConVar("ttt_vampire_damage_reduction")

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

    -- Fangs
    LANG.AddToLanguage("english", "vam_fangs_help_pri", "Hold {primaryfire} to suck blood")
    LANG.AddToLanguage("english", "vam_fangs_help_sec", "Press {secondaryfire} to fade from view")
    LANG.AddToLanguage("english", "vam_fangs_convert", "CONVERT")
    LANG.AddToLanguage("english", "vam_fangs_converting", "CONVERTING")
    LANG.AddToLanguage("english", "vam_fangs_kill", "KILL")
    LANG.AddToLanguage("english", "vam_fangs_killing", "KILLING")

    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_vampire", "Can drain players and bodies of blood to heal, leaving only a pile of bones behind as evidence.")
    LANG.AddToLanguage("english", "cheatsheet_desc_vampire_no_bones", "Can drain players and bodies of blood to heal, leaving behind no evidence.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_vampire", [[You are {role}! {comrades}

You can use your fangs (hold left-click) to drink blood and refill your health or to fade from view (right-click).

Press {menukey} to receive your special equipment!]])
end)

-- If this is an independent Vampire, replace the "comrades" list with a generic kill message
hook.Add("TTTRolePopupParams", "Vampire_TTTRolePopupParams", function(cli)
    if cli:IsVampire() and cli:IsIndependentTeam() then
        return {comrades = "\n\nKill all others to win!"}
    end
end)

hook.Add("TTTCheatSheetRoleStringOverride", "Vampire_TTTCheatSheetRoleStringOverride", function(cli, roleString)
    if not cvars.Bool("ttt_vampire_drop_bones", true) then
        return roleString .. "_no_bones"
    end
end)

---------------
-- TARGET ID --
---------------

-- Show skull icon over all non-jester team heads
hook.Add("TTTTargetIDPlayerTargetIcon", "Vampire_TTTTargetIDPlayerTargetIcon", function(ply, cli, showJester)
    if cli:IsVampire() and vampire_show_target_icon:GetBool() and not showJester and not cli:IsSameTeam(ply) then
        return "kill", true, ROLE_COLORS_SPRITE[ROLE_VAMPIRE], "down"
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
    if not IsPlayer(ply) then return end

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
        local allies
        local showJesters
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
    vampire_vision = vampire_vision_enabled:GetBool()
    jesters_visible_to_traitors = GetConVar("ttt_jesters_visible_to_traitors"):GetBool()
    jesters_visible_to_monsters = GetConVar("ttt_jesters_visible_to_monsters"):GetBool()
    jesters_visible_to_independents = INDEPENDENT_ROLES[ROLE_VAMPIRE] and GetConVar("ttt_vampire_can_see_jesters"):GetBool()

    -- Disable highlights on role change
    if vision_enabled then
        RemoveHook("PreDrawHalos", "Vampire_Highlight_PreDrawHalos")
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

    if vampire_vision and not vision_enabled then
        RemoveHook("PreDrawHalos", "Vampire_Highlight_PreDrawHalos")
    end
end)

ROLE_IS_TARGET_HIGHLIGHTED[ROLE_VAMPIRE] = function(ply, target)
    if not ply:IsVampire() then return end

    local hasFangs = ply.GetActiveWeapon and IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "weapon_vam_fangs"
    return vampire_vision and hasFangs
end

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Vampire_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_VAMPIRE then
        -- Use this for highlighting things like "blood"
        local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
        local roleTeam = player.GetRoleTeam(ROLE_VAMPIRE, true)
        local roleTeamName, roleColor = GetRoleTeamInfo(roleTeam, true)

        local html = "The " .. ROLE_STRINGS[ROLE_VAMPIRE] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. roleTeamName .. " team</span>."

        -- Draining
        html = html .. "<span style='display: block; margin-top: 10px;'>They can heal themselves by <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>draining blood</span> from "
        local drainEnabled = GetConVar("ttt_vampire_drain_enabled"):GetBool()
        if drainEnabled then
            html = html .. "both living players and "
        end
        html = html .. "corpses using their fangs (Hold the attack button down when near a target).</span>"

        -- Fade
        html = html .. "<span style='display: block; margin-top: 10px;'>By using the secondary attack with their fangs, they can also <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>fade from view</span> and gain a temporary speed bonus. This is useful for either chasing down prey or running away from conflict.</span>"

        -- Convert
        if drainEnabled and GetConVar("ttt_vampire_convert_enabled"):GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>"
            if GetConVar("ttt_vampire_prime_only_convert"):GetBool() then
                html = html .. "Prime "
            end
            html = html .. ROLE_STRINGS_PLURAL[ROLE_VAMPIRE] .. " can convert living targets to their team by <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>draining their blood</span> the correct amount (Look for the message on the drain progress bar for when to release).</span>"

            -- Prime Death Mode
            local primeMode = vampire_prime_death_mode:GetInt()
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
        local hasVision = vampire_vision_enabled:GetBool()
        if hasVision then
            html = html .. "<span style='display: block; margin-top: 10px;'>Their <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>hunger for blood</span> helps them see their targets through walls by highlighting their enemies.</span>"
        end

        -- Target ID
        if vampire_show_target_icon:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>Their targets can"
            if hasVision then
                html = html .. " also"
            end
            html = html .. " be identified by the <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>skull</span> icon floating over their heads.</span>"
        end

        -- Damage reduction
        if vampire_damage_reduction:GetFloat() > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>To help keep them alive, the " .. ROLE_STRINGS[ROLE_VAMPIRE] .. " takes <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>less damage from bullets</span>.</span>"
        end

        return html
    end
end)