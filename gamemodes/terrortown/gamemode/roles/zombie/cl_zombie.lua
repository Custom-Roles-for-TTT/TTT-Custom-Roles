local hook = hook
local IsValid = IsValid
local net = net
local player = player
local string = string

local RemoveHook = hook.Remove
local StringUpper = string.upper

-------------
-- CONVARS --
-------------

local zombie_show_target_icon = GetConVar("ttt_zombie_show_target_icon")
local zombie_vision_enabled = GetConVar("ttt_zombie_vision_enabled")
local zombie_damage_penalty = GetConVar("ttt_zombie_damage_penalty")
local zombie_damage_reduction = GetConVar("ttt_zombie_damage_reduction")
local zombie_spit_convert = GetConVar("ttt_zombie_spit_convert")

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Zombie_Translations_Initialize", function()
    -- Win conditions
    LANG.AddToLanguage("english", "win_zombies", "The {role} have taken over!")
    LANG.AddToLanguage("english", "ev_win_zombie", "The {role} infection has taken over the world!")

    -- Events
    LANG.AddToLanguage("english", "ev_zombi", "{victim} was turned into {azombie}")

    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_zombie", "Can turn other players into Zombies using their claws. They win by turning everyone into a Zombie.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_zombie", [[You are {role}! {comrades}

All damage you deal with guns is reduced.
Killing someone with your claws will turn them into {azombie}.

Press {menukey} to receive your special equipment!]])

    -- Zombie Claws
    LANG.AddToLanguage("english", "zom_claws_help_pri", "Press {primaryfire} to attack.")
    LANG.AddToLanguage("english", "zom_claws_help_sec", "Press {secondaryfire} to leap. Press {reload} to spit.")
    LANG.AddToLanguage("english", "zom_claws_help_sec_noleap", "Press {reload} to spit.")
    LANG.AddToLanguage("english", "zom_claws_help_sec_nospit", "Press {secondaryfire} to leap.")
end)

-- If this is an independent Zombie, replace the "comrades" list with a generic kill message
hook.Add("TTTRolePopupParams", "Zombie_TTTRolePopupParams", function(cli)
    if cli:IsZombie() and cli:IsIndependentTeam() then
        return {comrades = "\n\nKill all others to win!"}
    end
end)

---------------
-- TARGET ID --
---------------

-- Show skull icon over all non-jester team heads when the zombie is using their claws
hook.Add("TTTTargetIDPlayerTargetIcon", "Zombie_TTTTargetIDPlayerTargetIcon", function(ply, cli, showJester)
    if cli:IsZombie() and zombie_show_target_icon:GetBool() and cli.GetActiveWeapon and IsValid(cli:GetActiveWeapon()) and cli:GetActiveWeapon():GetClass() == "weapon_zom_claws" and not showJester and not cli:IsSameTeam(ply) then
        return "kill", true, ROLE_COLORS_SPRITE[ROLE_ZOMBIE], "down"
    end
end)

-- Show the correct role icon for zombies and their allies
hook.Add("TTTTargetIDPlayerRoleIcon", "Zombie_TTTTargetIDPlayerRoleIcon", function(ply, cli, role, noz, colorRole, hideBeggar, showJester, hideBodysnatcher)
    -- This logic is not needed if zombies are traitors
    -- Traitor logic is already handled elsewhere
    if TRAITOR_ROLES[ROLE_ZOMBIE] then return end

    if cli:IsActiveZombie() and ply:IsZombieAlly() then
        return ply:GetRole(), true
    elseif cli:IsZombieAlly() and ply:IsActiveZombie() then
        return ROLE_ZOMBIE, true
    end
end)

-- Show the correct target ring for zombies and their allies
hook.Add("TTTTargetIDPlayerRing", "Zombie_TTTTargetIDPlayerRing", function(ent, cli, ringVisible)
    -- This logic is not needed if zombies are traitors
    -- Traitor logic is already handled elsewhere
    if TRAITOR_ROLES[ROLE_ZOMBIE] then return end
    if not IsPlayer(ent) then return end

    if cli:IsActiveZombie() and ent:IsZombieAlly() then
        return true, ROLE_COLORS_RADAR[ent:GetRole()]
    elseif cli:IsZombieAlly() and ent:IsActiveZombie() then
        return true, ROLE_COLORS_RADAR[ROLE_ZOMBIE]
    end
end)

-- Show the correct role name for zombies and their allies
hook.Add("TTTTargetIDPlayerText", "Zombie_TTTTargetIDPlayerText", function(ent, cli, text, col)
    -- This logic is not needed if zombies are traitors
    -- Traitor logic is already handled elsewhere
    if TRAITOR_ROLES[ROLE_ZOMBIE] then return end
    if not IsPlayer(ent) then return end

    if cli:IsActiveZombie() and ent:IsZombieAlly() then
        local role = ent:GetRole()
        return StringUpper(ROLE_STRINGS[role]), ROLE_COLORS_RADAR[role]
    elseif cli:IsZombieAlly() and ent:IsActiveZombie() then
        return StringUpper(ROLE_STRINGS[ROLE_ZOMBIE]), ROLE_COLORS_RADAR[ROLE_ZOMBIE]
    end
end)

ROLE_IS_TARGETID_OVERRIDDEN[ROLE_ZOMBIE] = function(ply, target, showJester)
    if not IsPlayer(target) then return end

    -- The rest of this logic is not needed if zombies are traitors
    -- Traitor logic is already handled elsewhere
    if TRAITOR_ROLES[ROLE_ZOMBIE] then return end

    -- Override all three pieces for allies
    if (ply:IsActiveZombie() and target:IsZombieAlly()) or
        (ply:IsZombieAlly() and target:IsActiveZombie()) then
        ------ icon, ring, text
        return true, true, true
    end
end

----------------
-- SCOREBOARD --
----------------

hook.Add("TTTScoreboardPlayerRole", "Zombie_TTTScoreboardPlayerRole", function(ply, cli, color, roleFileName)
    -- This logic is not needed if zombies are traitors
    -- Traitor logic is already handled elsewhere
    if TRAITOR_ROLES[ROLE_ZOMBIE] then return end

    if cli:IsActiveZombie() and ply:IsZombieAlly() then
        return ROLE_COLORS_SCOREBOARD[ply:GetRole()], ROLE_STRINGS_SHORT[ply:GetRole()]
    elseif cli:IsZombieAlly() and ply:IsActiveZombie() then
        return ROLE_COLORS_SCOREBOARD[ROLE_ZOMBIE], ROLE_STRINGS_SHORT[ROLE_ZOMBIE]
    end
end)

ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_ZOMBIE] = function(ply, target)
    -- This logic is not needed if zombies are traitors
    -- Traitor logic is already handled elsewhere
    if TRAITOR_ROLES[ROLE_ZOMBIE] then return end

    local show = (ply:IsActiveZombie() and target:IsZombieAlly()) or
                    (ply:IsZombieAlly() and target:IsActiveZombie())

    ------ name,  role
    return false, show
end

-------------
-- SCORING --
-------------

-- Register the scoring events for the zombie
hook.Add("Initialize", "Zombie_Scoring_Initialize", function()
    local zombie_icon = Material("icon16/user_green.png")
    local Event = CLSCORE.DeclareEventDisplay
    local PT = LANG.GetParamTranslation

    Event(EVENT_ZOMBIFIED, {
        text = function(e)
            return PT("ev_zombi", {victim = e.vic, azombie = ROLE_STRINGS_EXT[ROLE_ZOMBIE]})
        end,
        icon = function(e)
            return zombie_icon, "Zombified"
        end})
end)

net.Receive("TTT_Zombified", function(len)
    local name = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_ZOMBIFIED,
        vic = name
    })
end)

-- Show the player's starting role icon if they were converted to a zombie and group them with their original team
hook.Add("TTTScoringSummaryRender", "Zombie_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
    if not IsPlayer(ply) then return end

    if finalRole == ROLE_ZOMBIE then
        return ROLE_STRINGS_SHORT[startingRole], startingRole
    end
end)

----------------
-- WIN CHECKS --
----------------

hook.Add("TTTScoringWinTitle", "Zombie_TTTScoringWinTitle", function(wintype, wintitles, title, secondary_win_role)
    if wintype == WIN_ZOMBIE then
        return { txt = "hilite_win_role_plural", params = { role = string.upper(ROLE_STRINGS_PLURAL[ROLE_ZOMBIE]) }, c = ROLE_COLORS[ROLE_ZOMBIE] }
    end
end)

------------
-- EVENTS --
------------

hook.Add("TTTEventFinishText", "Zombie_TTTEventFinishText", function(e)
    if e.win == WIN_ZOMBIE then
        return LANG.GetParamTranslation("ev_win_zombie", { role = string.lower(ROLE_STRINGS[ROLE_ZOMBIE]) })
    end
end)

hook.Add("TTTEventFinishIconText", "Zombie_TTTEventFinishIconText", function(e, win_string, role_string)
    if e.win == WIN_ZOMBIE then
        return win_string, ROLE_STRINGS_PLURAL[ROLE_ZOMBIE]
    end
end)

------------------
-- HIGHLIGHTING --
------------------

local zombie_vision = false
local jesters_visible_to_traitors = false
local jesters_visible_to_monsters = false
local jesters_visible_to_independents = false
local vision_enabled = false
local client = nil

local function EnableZombieHighlights()
    -- Handle zombie targeting and non-traitor team logic
    -- Traitor logic is handled in cl_init and does not need to be duplicated here
    hook.Add("PreDrawHalos", "Zombie_Highlight_PreDrawHalos", function()
        local hasClaws = client.GetActiveWeapon and IsValid(client:GetActiveWeapon()) and client:GetActiveWeapon():GetClass() == "weapon_zom_claws"
        local hideEnemies = not zombie_vision or not hasClaws

        -- Handle logic differently depending on which team they are on
        local allies
        local showJesters
        local traitorAllies = false
        local onlyShowEnemies = false
        if MONSTER_ROLES[ROLE_ZOMBIE] then
            allies = GetTeamRoles(MONSTER_ROLES)
            showJesters = jesters_visible_to_monsters
        elseif INDEPENDENT_ROLES[ROLE_ZOMBIE] then
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

hook.Add("TTTUpdateRoleState", "Zombie_Highlight_TTTUpdateRoleState", function()
    client = LocalPlayer()
    zombie_vision = zombie_vision_enabled:GetBool()
    jesters_visible_to_traitors = GetConVar("ttt_jesters_visible_to_traitors"):GetBool()
    jesters_visible_to_monsters = GetConVar("ttt_jesters_visible_to_monsters"):GetBool()
    jesters_visible_to_independents = INDEPENDENT_ROLES[ROLE_ZOMBIE] and GetConVar("ttt_zombie_can_see_jesters"):GetBool()

    -- Disable highlights on role change
    if vision_enabled then
        RemoveHook("PreDrawHalos", "Zombie_Highlight_PreDrawHalos")
        vision_enabled = false
    end
end)

-- Handle enabling and disabling of highlighting
hook.Add("Think", "Zombie_Highlight_Think", function()
    if not IsPlayer(client) or not client:Alive() or client:IsSpec() then return end

    if zombie_vision and client:IsZombie() then
        if not vision_enabled then
            EnableZombieHighlights()
            vision_enabled = true
        end
    else
        vision_enabled = false
    end

    if zombie_vision and not vision_enabled then
        RemoveHook("PreDrawHalos", "Zombie_Highlight_PreDrawHalos")
    end
end)

ROLE_IS_TARGET_HIGHLIGHTED[ROLE_ZOMBIE] = function(ply, target)
    if not ply:IsZombie() then return end

    local hasClaws = ply.GetActiveWeapon and IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "weapon_zom_claws"
    return zombie_vision and hasClaws
end

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Zombie_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_ZOMBIE then
        -- Use this for highlighting things like "brains"
        local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
        local roleTeam = player.GetRoleTeam(ROLE_ZOMBIE, true)
        local roleTeamString, roleTeamColor = GetRoleTeamInfo(roleTeam, true)

        local html = "The " .. ROLE_STRINGS[ROLE_ZOMBIE] .. " is a member of the <span style='color: rgb(" .. roleTeamColor.r .. ", " .. roleTeamColor.g .. ", " .. roleTeamColor.b .. ")'>" .. string.lower(roleTeamString) .. " team</span> that uses their claws to attack their enemies."

        -- Convert
        html = html .. "<span style='display: block; margin-top: 10px;'>Killing a player with their claws will <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>turn the target</span> into " .. ROLE_STRINGS_EXT[ROLE_ZOMBIE] .. " thrall.</span>"

        -- Leap
        if GetConVar("ttt_zombie_leap_enabled"):GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>By using the secondary attack with the claws, " .. ROLE_STRINGS_PLURAL[ROLE_ZOMBIE] .. " can <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>leap in the air</span> to surprise their potential targets.</span>"
        end

        -- Spit
        if GetConVar("ttt_zombie_spit_enabled"):GetBool() then
            local keyMappingStyles = "font-size: 12px; color: black; display: inline-block; padding: 0px 3px; height: 16px; border-width: 4px; border-style: solid; border-left-color: rgb(221, 221, 221); border-bottom-color: rgb(119, 119, 102); border-right-color: rgb(119, 119, 119); border-top-color: rgb(255, 255, 255); background-color: rgb(204, 204, 187);"
            html = html .. "<span style='display: block; margin-top: 10px;'>If the target is out of range of the claws, the " .. ROLE_STRINGS[ROLE_ZOMBIE] .. " can <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>spit acid</span> at them by pressing the "

            local key = Key("+reload", "R")
            html = html .. "<span style='" .. keyMappingStyles .. "'>" .. key .. "</span> key.</span>"

            html = html .. "<span style='display: block; margin-top: 10px;'>Killing a player with acid spit <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>will "
            if not zombie_spit_convert:GetBool() then
                html = html .. "not "
            end
            html = html .. "convert them</span>.</span>"
        end

        -- Eat
        if GetConVar("ttt_zombie_eat_enabled"):GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS_PLURAL[ROLE_ZOMBIE] .. "'s claws can be used to <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'> consume a player's corpse</span>, healing the " .. ROLE_STRINGS_PLURAL[ROLE_ZOMBIE] .. " in the process.</span>"
        end

        -- Vision
        local hasVision = zombie_vision_enabled:GetBool()
        if hasVision then
            html = html .. "<span style='display: block; margin-top: 10px;'>Their <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>hunger for brains</span> helps them see their targets through walls by highlighting their enemies.</span>"
        end

        -- Target ID
        if zombie_show_target_icon:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>Their targets can"
            if hasVision then
                html = html .. " also"
            end
            html = html .. " be identified by the <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>skull</span> icon floating over their heads.</span>"
        end

        -- Damage penalty
        if zombie_damage_penalty:GetFloat() > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_ZOMBIE] .. " should use their claws as much as possible and so they do <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>less damage with other weapons</span>.</span>"
        end

        -- Damage reduction
        if zombie_damage_reduction:GetFloat() > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>To help keep them alive, the " .. ROLE_STRINGS[ROLE_ZOMBIE] .. " takes <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>less damage from bullets</span>.</span>"
        end

        return html
    end
end)