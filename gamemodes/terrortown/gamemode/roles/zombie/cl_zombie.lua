------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Zombie_Translations_Initialize", function()
    -- Win conditions
    LANG.AddToLanguage("english", "win_zombies", "The {role} have taken over!")
    LANG.AddToLanguage("english", "ev_win_zombie", "The {role} infection has taken over the world!")

    -- Events
    LANG.AddToLanguage("english", "ev_zombi", "{victim} was turned into {azombie}")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_zombie", [[You are {role}! {comrades}

All damage you deal with guns is reduced.
Killing someone with your claws will turn them into {azombie}.

Press {menukey} to receive your special equipment!]])
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

-- Show "KILL" icon over all non-jester team heads when the zombie is using their claws
hook.Add("TTTTargetIDPlayerKillIcon", "Zombie_TTTTargetIDPlayerKillIcon", function(ply, cli, showKillIcon, showJester)
    if cli:IsZombie() and GetGlobalBool("ttt_zombie_show_target_icon", false) and cli.GetActiveWeapon and IsValid(cli:GetActiveWeapon()) and cli:GetActiveWeapon():GetClass() == "weapon_zom_claws" and not showJester then
        return true
    end
end)

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
    if finalRole == ROLE_ZOMBIE then
        return ROLE_STRINGS_SHORT[startingRole], startingRole
    end
end)

----------------
-- WIN CHECKS --
----------------

hook.Add("TTTScoringWinTitle", "Zombie_TTTScoringWinTitle", function(wintype, wintitles, title, secondary_win_role)
    if wintype == WIN_ZOMBIE then
        return { txt = "hilite_win_role_plural", params = { role = ROLE_STRINGS_PLURAL[ROLE_ZOMBIE]:upper() }, c = ROLE_COLORS[ROLE_ZOMBIE] }
    end
end)

------------
-- EVENTS --
------------

hook.Add("TTTEventFinishText", "Zombie_TTTEventFinishText", function(e)
    if e.win == WIN_ZOMBIE then
        return LANG.GetParamTranslation("ev_win_zombie", { role = ROLE_STRINGS[ROLE_ZOMBIE]:lower() })
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
        local hasFangs = client.GetActiveWeapon and IsValid(client:GetActiveWeapon()) and client:GetActiveWeapon():GetClass() == "weapon_zom_claws"
        local hideEnemies = not zombie_vision or not hasFangs

        -- Handle logic differently depending on which team they are on
        local allies = {}
        local showJesters = false
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
    zombie_vision = GetGlobalBool("ttt_zombie_vision_enable", false)
    jesters_visible_to_traitors = GetGlobalBool("ttt_jesters_visible_to_traitors", false)
    jesters_visible_to_monsters = GetGlobalBool("ttt_jesters_visible_to_monsters", false)
    jesters_visible_to_independents = GetGlobalBool("ttt_jesters_visible_to_independents", false)

    -- Disable highlights on role change
    if vision_enabled then
        hook.Remove("PreDrawHalos", "Zombie_Highlight_PreDrawHalos")
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

    if not vision_enabled then
        hook.Remove("PreDrawHalos", "Zombie_Highlight_PreDrawHalos")
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleEnabled", "Zombie_TTTTutorialRoleEnabled", function(role)
    if role == ROLE_ZOMBIE then
        -- Show the zombie screen if the Mad Scientist could spawn them
        return INDEPENDENT_ROLES[ROLE_ZOMBIE] and GetGlobalBool("ttt_madscientist_enabled", false)
    end
end)

hook.Add("TTTTutorialRoleText", "Zombie_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_ZOMBIE then
        return ""
    end
end)