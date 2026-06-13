local hook = hook
local math = math
local net = net
local util = util

local AddHook = hook.Add
local MathMax = math.max
local MathSin = math.sin

-------------
-- CONVARS --
-------------

local plaguemaster_immune = GetConVar("ttt_plaguemaster_immune")
local plaguemaster_plague_length = GetConVar("ttt_plaguemaster_plague_length")
local plaguemaster_spread_distance = GetConVar("ttt_plaguemaster_spread_distance")
local plaguemaster_spread_require_los = GetConVar("ttt_plaguemaster_spread_require_los")
local plaguemaster_spread_time = GetConVar("ttt_plaguemaster_spread_time")
local plaguemaster_warning_time = GetConVar("ttt_plaguemaster_warning_time")
local plaguemaster_body_search_mode = GetConVar("ttt_plaguemaster_body_search_mode")

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "Plaguemaster_Translations_Initialize", function()
    -- Body Search
    LANG.AddToLanguage("english", "plaguemaster_body_plagued", "They were infected {time} ago by {aplaguemaster}'s plague!")

    -- Events
    LANG.AddToLanguage("english", "ev_plaguemasterplague", "{victim} caught the {plaguemaster}'s plague from {source}")

    -- Win conditions
    LANG.AddToLanguage("english", "win_plaguemaster", "The {role}'s plague has conquered!")
    LANG.AddToLanguage("english", "ev_win_plaguemaster", "The infectious {role} has won the round!")

    -- HUD
    LANG.AddToLanguage("english", "plaguemaster_hud_death", "DYING FROM PLAGUE IN {time}")
    LANG.AddToLanguage("english", "plaguemaster_hud_spread", "CATCHING PLAGUE IN {time}")
    LANG.AddToLanguage("english", "plaguemaster_plagued", "PLAGUED")

    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_plaguemaster", "Can spread their plague to players, killing them after a time. They win if they are the last player alive.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_plaguemaster", [[You are {role}! Use your Dart Gun to give a player the plague.

Players with your plague will automatically spread it to others
and will die after a time!]])
end)

---------------
-- TARGET ID --
---------------

-- Show "PLAGUED" label on players who have been infected
local function Plaguemaster_TTTTargetIDPlayerText(ent, cli, text, col, secondaryText)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not IsPlayer(ent) then return end
    if not cli:IsPlaguemaster() then return end

    local plague_start = ent.TTTPlaguemasterStartTime
    if not plague_start then return end

    local T = LANG.GetTranslation
    if text == nil then
        return T("plaguemaster_plagued"), ROLE_COLORS[ROLE_TRAITOR]
    end
    return text, col, T("plaguemaster_plagued"), ROLE_COLORS[ROLE_TRAITOR]
end

-- NOTE: ROLE_IS_TARGETID_OVERRIDDEN is not required since only secondary text is being changed and that is not tracked there

--------------------
-- BODY SEARCHING --
--------------------

local function Plaguemaster_TTTBodySearchPopulate(search, raw)
    local rag = Entity(raw.eidx)
    if not IsValid(rag) then return end

    local ply = CORPSE.GetPlayer(rag)
    if not IsPlayer(ply) then return end

    local search_mode = plaguemaster_body_search_mode:GetInt()
    if search_mode == PLAGUEMASTER_SEARCH_DONT_SHOW then return end

    local plague_death = ply.TTTPlaguemasterPlagueDeath
    if search_mode == PLAGUEMASTER_SEARCH_SHOW_KILLED and not plague_death then return end

    local plague_start = ply.TTTPlaguemasterStartTime
    if not plague_start then return end

    local time = util.SimpleTime(CurTime() - plague_start, "%02i:%02i")
    local message = LANG.GetParamTranslation("plaguemaster_body_plagued", {time = time, aplaguemaster = ROLE_STRINGS_EXT[ROLE_PLAGUEMASTER]})

    search["plaguemasterplague"] = {
        text = message,
        img = "vgui/ttt/icon_plaguemasterplague",
        text_icon = time,
        p = 10
    }
end

-------------
-- SCORING --
-------------

-- Register the scoring events for the plaguemaster
AddHook("Initialize", "Plaguemaster_Scoring_Initialize", function()
    local plaguemaster_icon = Material("icon16/asterisk_yellow.png")
    local Event = CLSCORE.DeclareEventDisplay
    local PT = LANG.GetParamTranslation

    Event(EVENT_PLAGUEMASTERPLAGUED, {
        text = function(e)
            return PT("ev_plaguemasterplague", {victim = e.vic, source = e.src, plaguemaster = ROLE_STRINGS[ROLE_PLAGUEMASTER]})
        end,
        icon = function(e)
            return plaguemaster_icon, "Plagued"
        end})
end)

net.Receive("TTT_PlaguemasterPlagued", function(len)
    local victim = net.ReadString()
    local source = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_PLAGUEMASTERPLAGUED,
        vic = victim,
        src = source
    })
end)

----------------
-- WIN CHECKS --
----------------

local function Plaguemaster_TTTScoringWinTitle(wintype, wintitles, title, secondary_win_role)
    if wintype == WIN_PLAGUEMASTER then
        return { txt = "hilite_win_role_singular", params = { role = string.upper(ROLE_STRINGS[ROLE_PLAGUEMASTER]) }, c = ROLE_COLORS[ROLE_PLAGUEMASTER] }
    end
end

------------
-- EVENTS --
------------

local function Plaguemaster_TTTEventFinishText(e)
    if e.win == WIN_PLAGUEMASTER then
        return LANG.GetParamTranslation("ev_win_plaguemaster", { role = string.lower(ROLE_STRINGS[ROLE_PLAGUEMASTER]) })
    end
end

local function Plaguemaster_TTTEventFinishIconText(e, win_string, role_string)
    if e.win == WIN_PLAGUEMASTER then
        return win_string, ROLE_STRINGS[ROLE_PLAGUEMASTER]
    end
end

---------
-- HUD --
---------
local client = nil

local function Plaguemaster_HUDPaint()
    if not IsPlayer(client) then
        client = LocalPlayer()
    end

    if not IsValid(client) or client:IsSpec() or GetRoundState() ~= ROUND_ACTIVE then return end
    if not client:IsPlaguemaster() then return end

    local progress = 0
    local message = ""

    if client.TTTPlaguemasterSpreadStart then
        local spread_time = plaguemaster_spread_time:GetInt()
        local remaining = MathMax(0, (client.TTTPlaguemasterSpreadStart + spread_time) - CurTime())
        progress = 1 - (remaining / spread_time)
        message = LANG.GetParamTranslation("plaguemaster_hud_spread", { time = util.SimpleTime(remaining, "%02i:%02i") })
    elseif client.TTTPlaguemasterStartTime then
        local plague_length = plaguemaster_plague_length:GetInt()
        local remaining = MathMax(0, (client.TTTPlaguemasterStartTime + plague_length) - CurTime())
        progress = 1 - (remaining / plague_length)
        message = LANG.GetParamTranslation("plaguemaster_hud_death", { time = util.SimpleTime(remaining, "%02i:%02i") })
    end

    if progress == 0 then return end

    local x = ScrW() / 2.0
    local y = ScrH() / 1.5
    local w = 300
    local color = Color(200 + MathSin(CurTime() * 32) * 50, 0, 0, 155)

    CRHUD:PaintProgressBar(x, y, w, color, message, progress)
end

--------------
-- TUTORIAL --
--------------

AddHook("TTTTutorialRoleText", "Plaguemaster_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_PLAGUEMASTER then
        local roleColor = GetRoleTeamColor(ROLE_TEAM_INDEPENDENT)
        local html = "The " .. ROLE_STRINGS[ROLE_PLAGUEMASTER] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independent</span> role whose goal is to spread their plague using their dart gun and be the last player standing."

        -- Use this for highlighting
        roleColor = ROLE_COLORS[ROLE_TRAITOR]

        html = html .. "<span style='display: block; margin-top: 10px;'>The plague is <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>spread between players</span> when they are within " .. plaguemaster_spread_distance:GetInt() .. " units of each other for " .. plaguemaster_spread_time:GetInt() .. " seconds.</span>"
        if plaguemaster_spread_require_los:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>Spreading the plague requires that the plague carrier and target have a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>clear line-of-sight</span> between them.</span>"
        end

        html = html .. "<span style='display: block; margin-top: 10px;'>A player with the plague will <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>succumb to the plague and die</span> after " .. plaguemaster_plague_length:GetInt() .. " seconds.</span>"

        local warning_time = plaguemaster_warning_time:GetInt()
        if warning_time > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>" .. warning_time .. " seconds before their death, a player with the plague <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>will be warned</span> of their coming demise.</span>"
        end

        local detectiveColor = ROLE_COLORS[ROLE_DETECTIVE]
        local doctorColor = ROLE_COLORS[ROLE_DOCTOR]
        html = html .. "<span style='display: block; margin-top: 10px;'>The plague <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>can be removed</span> from a single player if a cure is used on them. Cures can be bought by <span style='color: rgb(" .. detectiveColor.r .. ", " .. detectiveColor.g .. ", " .. detectiveColor.b .. ")'>Detectives</span> and <span style='color: rgb(" .. doctorColor.r .. ", " .. doctorColor.g .. ", " .. doctorColor.b .. ")'>Doctors</span> by default.</span>"

        if plaguemaster_immune:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_PLAGUEMASTER] .. " <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>is immune</span> to the plague.</span>"
        else
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_PLAGUEMASTER] .. " <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>is NOT immune</span> to the plague and will be warned when they get too close to a plague-ridden player.</span>"
            html = html .. "<span style='display: block; margin-top: 10px;'>They are also told <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>how much time they have left</span> before death if they have caught the plague.</span>"
        end

        local cure_mode = GetConVar("ttt_doctor_cure_mode"):GetInt()
        html = html .. "<span style='display: block; margin-top: 10px;'>Some roles can buy a cure that can remove the infection from a player. If it is used on a player that isn't infected then <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>"
        if cure_mode == DOCTOR_CURE_KILL_NONE then
            html = html .. "nothing bad will happen</span>, but "
        elseif cure_mode == DOCTOR_CURE_KILL_OWNER then
            html = html .. "the player using it will be killed</span> and "
        elseif cure_mode == DOCTOR_CURE_KILL_TARGET then
            html = html .. "the target player will be killed</span> and "
        end
        html = html .. "it will get used up.</span>"

        return html
    end
end)

------------------
-- REGISTRATION --
------------------

ROLE_REGISTERED_HOOKS[ROLE_PLAGUEMASTER] = {
    ["HUDPaint"] = Plaguemaster_HUDPaint,
    ["TTTBodySearchPopulate"] = Plaguemaster_TTTBodySearchPopulate,
    ["TTTEventFinishIconText"] = Plaguemaster_TTTEventFinishIconText,
    ["TTTEventFinishText"] = Plaguemaster_TTTEventFinishText,
    ["TTTScoringWinTitle"] = Plaguemaster_TTTScoringWinTitle,
    ["TTTTargetIDPlayerText"] = Plaguemaster_TTTTargetIDPlayerText
}