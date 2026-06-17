local hook = hook
local string = string

local AddHook = hook.Add
local RemoveHook = hook.Remove

-------------
-- CONVARS --
-------------

local killer_knife_enabled = GetConVar("ttt_killer_knife_enabled")
local killer_crowbar_enabled = GetConVar("ttt_killer_crowbar_enabled")
local killer_smoke_enabled = GetConVar("ttt_killer_smoke_enabled")
local killer_show_target_icon = GetConVar("ttt_killer_show_target_icon")
local killer_vision_enabled = GetConVar("ttt_killer_vision_enabled")
local killer_warn = GetConVar("ttt_killer_warn")
local killer_warn_all = GetConVar("ttt_killer_warn_all")
local killer_can_see_jesters = GetConVar("ttt_killer_can_see_jesters")

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "Killer_Translations_Initialize", function()
    -- Win conditions
    LANG.AddToLanguage("english", "win_killer", "The {role} has murdered you all!")
    LANG.AddToLanguage("english", "ev_win_killer", "The butchering {role} won the round!")

    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_killer", "Spawns with a knife and throwable crowbar. They win if they are the last player alive.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_killer", [[You are {role}! Try to kill everyone and be the last one standing!

Press {menukey} to receive your special equipment!]])

    -- Killer's Knife
    LANG.AddToLanguage("english", "kil_knife_desc", [[
Gravely wounds living targets quietly.
Kills wounded targets instantly and
silently.

Can drop a smoke grenade using alternate fire.]])

    -- Killer's Crowbar
    LANG.AddToLanguage("english", "kil_crowbar_name", "Throwable Crowbar")
    LANG.AddToLanguage("english", "kil_crowbar_desc", [[
Used to blend in with other players and do minor damage.

Can be thrown using alternate fire.]])
end)

---------------
-- TARGET ID --
---------------

-- Show skull icon over all non-jester team heads
local function Killer_TTTTargetIDPlayerTargetIcon(ply, cli, showJester)
    if cli:IsKiller() and killer_show_target_icon:GetBool() and not showJester and not cli:IsSameTeam(ply) then
        return "kill", true, ROLE_COLORS_SPRITE[ROLE_KILLER], "down"
    end
end

------------------
-- HIGHLIGHTING --
------------------

local killer_vision = false
local vision_enabled = false
local can_see_jesters = false
local client = nil

local function EnableKillerHighlights()
    AddHook("PreDrawHalos", "Killer_Highlight_PreDrawHalos", function()
        OnPlayerHighlightEnabled(client, {}, can_see_jesters, false, false)
    end)
end

local function Killer_Highlight_TTTUpdateRoleState()
    client = LocalPlayer()
    killer_vision = killer_vision_enabled:GetBool()
    can_see_jesters = killer_can_see_jesters:GetBool()

    -- Disable highlights on role change
    if vision_enabled then
        RemoveHook("PreDrawHalos", "Killer_Highlight_PreDrawHalos")
        vision_enabled = false
    end
end

-- Handle enabling and disabling of highlighting
local function Killer_Highlight_Think()
    if not IsPlayer(client) or not client:Alive() or client:IsSpec() then return end

    if killer_vision and client:IsKiller() and not client:IsRoleAbilityDisabled() then
        if not vision_enabled then
            EnableKillerHighlights()
            vision_enabled = true
        end
    else
        vision_enabled = false
    end

    if killer_vision and not vision_enabled then
        RemoveHook("PreDrawHalos", "Killer_Highlight_PreDrawHalos")
    end
end

ROLE_IS_TARGET_HIGHLIGHTED[ROLE_KILLER] = function(ply, target)
    if not ply:IsKiller() then return end
    return killer_vision
end

----------------
-- WIN CHECKS --
----------------

local function Killer_TTTScoringWinTitle(wintype, wintitles, title, secondary_win_role)
    if wintype == WIN_KILLER then
        return { txt = "hilite_win_role_singular", params = { role = string.upper(ROLE_STRINGS[ROLE_KILLER]) }, c = ROLE_COLORS[ROLE_KILLER] }
    end
end

------------
-- EVENTS --
------------

local function Killer_TTTEventFinishText(e)
    if e.win == WIN_KILLER then
        return LANG.GetParamTranslation("ev_win_killer", { role = string.lower(ROLE_STRINGS[ROLE_KILLER]) })
    end
end

local function Killer_TTTEventFinishIconText(e, win_string, role_string)
    if e.win == WIN_KILLER then
        return win_string, ROLE_STRINGS[ROLE_KILLER]
    end
end

-----------
-- SMOKE --
-----------

local function Killer_TTTShouldPlayerSmoke(ply, cli, shouldSmoke, smokeColor, smokeParticle, smokeOffset)
    if ply:IsKiller() and ply:GetNWBool("KillerSmoke", false) then
        return true
    end
end

--------------
-- TUTORIAL --
--------------

AddHook("TTTTutorialRoleText", "Killer_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_KILLER then
        local roleColor = GetRoleTeamColor(ROLE_TEAM_INDEPENDENT)
        local html = "The " .. ROLE_STRINGS[ROLE_KILLER] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independent</span> role whose goal is to be the last player standing."

        -- Use this for highlighting things like "kill"
        roleColor = ROLE_COLORS[ROLE_TRAITOR]

        -- Warning
        if killer_warn:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>"
            if killer_warn_all:GetBool() then
                html = html .. "All players"
            else
                html = html .. LANG.GetTranslation("traitors")
            end
            html = html .. " are <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>warned</span> when there is "  .. ROLE_STRINGS_EXT[ROLE_KILLER] .. " in the game.</span>"
        end

        -- Knife
        if killer_knife_enabled:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>They are given a knife that does high damage to aid in their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>slaughter</span>.</span>"
        end

        -- Crowbar
        if killer_crowbar_enabled:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>They have a special crowbar that <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>can be thrown</span>.</span>"
        end

        -- Smoke
        if killer_smoke_enabled:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>If they don't <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>kill</span> often enough they will begin to smoke, alerting the other players.</span>"
        end

        -- Vision
        local hasVision = killer_vision_enabled:GetBool()
        if hasVision then
            html = html .. "<span style='display: block; margin-top: 10px;'>Their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>blood lust</span> helps them see their targets through walls by highlighting their enemies.</span>"
        end

        -- Target ID
        if killer_show_target_icon:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>Their targets can"
            if hasVision then
                html = html .. " also"
            end
            html = html .. " be identified by the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>skull</span> icon floating over their heads.</span>"
        end

        return html
    end
end)

------------------
-- REGISTRATION --
------------------

ROLE_REGISTERED_HOOKS[ROLE_KILLER] = {
    ["Think"] = Killer_Highlight_Think,
    ["TTTEventFinishIconText"] = Killer_TTTEventFinishIconText,
    ["TTTEventFinishText"] = Killer_TTTEventFinishText,
    ["TTTScoringWinTitle"] = Killer_TTTScoringWinTitle,
    ["TTTShouldPlayerSmoke"] = Killer_TTTShouldPlayerSmoke,
    ["TTTTargetIDPlayerTargetIcon"] = Killer_TTTTargetIDPlayerTargetIcon,
    ["TTTUpdateRoleState"] = Killer_Highlight_TTTUpdateRoleState
}

AddHook("TTTPrepareRound", "Killer_TTTPrepareRound", function()
    vision_enabled = false
    RemoveHook("PreDrawHalos", "Killer_Highlight_PreDrawHalos")
end)