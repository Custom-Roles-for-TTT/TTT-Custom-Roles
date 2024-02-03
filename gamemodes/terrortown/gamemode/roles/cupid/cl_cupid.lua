local halo = halo
local hook = hook
local ipairs = ipairs
local table = table

local GetAllPlayers = player.GetAll
local HaloAdd = halo.Add
local AddHook = hook.Add
local RemoveHook = hook.Remove
local TableInsert = table.insert
local StringUpper = string.upper

-------------
-- CONVARS --
-------------

local cupid_lover_vision_enabled = GetConVar("ttt_cupid_lover_vision_enabled")
local cupid_is_independent = GetConVar("ttt_cupid_is_independent")
local cupid_lovers_notify_mode = GetConVar("ttt_cupid_lovers_notify_mode")
local cupid_can_damage_lovers = GetConVar("ttt_cupid_can_damage_lovers")
local cupid_lovers_can_damage_lovers = GetConVar("ttt_cupid_lovers_can_damage_lovers")
local cupid_lovers_can_damage_cupid = GetConVar("ttt_cupid_lovers_can_damage_cupid")

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "Cupid_Translations_Initialize", function()
    -- Win conditions
    LANG.AddToLanguage("english", "win_lovers", "The lovers have outlasted everyone!")
    LANG.AddToLanguage("english", "hilite_lovers_primary", "THE LOVERS WIN")
    LANG.AddToLanguage("english", "hilite_lovers_secondary", "AND THE LOVERS WIN")
    LANG.AddToLanguage("english", "ev_win_lovers", "The lovers won the round!")

    -- SCOREBOARD
    LANG.AddToLanguage("english", "scoreboard_cupid_your_lover", "YOUR LOVER")
    LANG.AddToLanguage("english", "scoreboard_cupid_lover", "LOVER")

    -- Scoring
    LANG.AddToLanguage("english", "score_cupid_pairnames", "{lover1} and {lover2}")
    LANG.AddToLanguage("english", "score_cupid_paired", "Paired")

    -- Event
    LANG.AddToLanguage("english", "ev_cupid_paired", "{cupid} made {lover1} and {lover2} fall in love")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_cupid_jester", [[You are {role}! {traitors} think you are {ajester} and you
deal no damage. However, you can use your bow to make two
players fall in love so that they win/die together.]])
    LANG.AddToLanguage("english", "info_popup_cupid_indep", [[You are {role}! You can use your bow to make two
players fall in love so that they win/die together.]])
end)

AddHook("TTTRolePopupRoleStringOverride", "Cupid_TTTRolePopupRoleStringOverride", function(cli, roleString)
    if not IsPlayer(cli) or not cli:IsCupid() then return end

    if cupid_is_independent:GetBool() then
        return roleString .. "_indep"
    end
    return roleString .. "_jester"
end)

----------------
-- WIN CHECKS --
----------------

AddHook("TTTScoringWinTitle", "Cupid_TTTScoringWinTitle", function(wintype, wintitles, title, secondary_win_role)
    if wintype == WIN_CUPID then
        return { txt = "hilite_lovers_primary", c = ROLE_COLORS[ROLE_CUPID] }
    end
end)

AddHook("TTTScoringSecondaryWins", "Cupid_TTTScoringSecondaryWins", function(wintype, secondary_wins)
    if wintype == WIN_CUPID then return end

    for _, p in ipairs(GetAllPlayers()) do
        local lover = p:GetNWString("TTTCupidLover", "")
        if p:Alive() and not p:IsSpec() and #lover > 0 then
            local loverPly = player.GetBySteamID64(lover)
            -- This shouldn't be necessary because if one lover dies the other should too but we check just in case
            if IsPlayer(loverPly) and loverPly:Alive() and not loverPly:IsSpec() then
                TableInsert(secondary_wins, {
                    rol = ROLE_CUPID,
                    txt = LANG.GetTranslation("hilite_lovers_secondary"),
                    col = ROLE_COLORS[ROLE_CUPID]
                })
                return
            end
        end
    end
end)

------------
-- EVENTS --
------------

AddHook("TTTEventFinishText", "Cupid_TTTEventFinishText", function(e)
    if e.win == WIN_CUPID then
        return LANG.GetTranslation("ev_win_lovers")
    end
end)

AddHook("TTTEventFinishIconText", "Cupid_TTTEventFinishIconText", function(e, win_string, role_string)
    if e.win == WIN_CUPID then
        return win_string, ROLE_STRINGS[ROLE_CUPID]
    end
end)

AddHook("TTTEndRound", "Cupid_SecondaryWinEvent_TTTEndRound", function()
    for _, p in ipairs(GetAllPlayers()) do
        local lover = p:GetNWString("TTTCupidLover", "")
        if p:IsActive() and #lover > 0 then
            local loverPly = player.GetBySteamID64(lover)
            -- This shouldn't be necessary because if one lover dies the other should too but we check just in case
            if IsPlayer(loverPly) and loverPly:IsActive() then
                CLSCORE:AddEvent({ -- Log the win event with an offset to force it to the end
                    id = EVENT_FINISH,
                    win = WIN_CUPID
                }, 1)
                return
            end
        end
    end
end)

-- Register the scoring events for cupid
AddHook("Initialize", "Cupid_Scoring_Initialize", function()
    local heart_icon = Material("icon16/heart.png")
    local Event = CLSCORE.DeclareEventDisplay
    local PT = LANG.GetParamTranslation
    Event(EVENT_CUPIDPAIRED, {
        text = function(e)
            return PT("ev_cupid_paired", {cupid = e.cupid, lover1 = e.lover1, lover2 = e.lover2})
         end,
        icon = function(e)
            return heart_icon, "Paired"
        end})
end)

net.Receive("TTT_CupidPaired", function(len)
    local cupid = net.ReadString()
    local lover1 = net.ReadString()
    local lover2 = net.ReadString()
    local sid64 = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_CUPIDPAIRED,
        cupid = cupid,
        lover1 = lover1,
        lover2 = lover2,
        sid64 = sid64,
        bonus = 1
    })
end)

-------------
-- SCORING --
-------------

-- Show who the cupid paired (if anyone)
AddHook("TTTScoringSummaryRender", "Cupid_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
    if not IsPlayer(ply) then return end

    if ply:IsCupid() then
        local lover1_sid64 = ply:GetNWString("TTTCupidTarget1", "")
        local lover2_sid64 = ply:GetNWString("TTTCupidTarget2", "")
        if #lover1_sid64 == 0 or #lover2_sid64 == 0 then return end

        local lover1 = player.GetBySteamID64(lover1_sid64)
        if not IsPlayer(lover1) then return end

        local lover2 = player.GetBySteamID64(lover2_sid64)
        if not IsPlayer(lover2) then return end

        local lover1_name = lover1:Nick()
        local lover2_name = lover2:Nick()

        return roleFileName, groupingRole, roleColor, name, LANG.GetParamTranslation("score_cupid_pairnames", {lover1=lover1_name, lover2=lover2_name}), LANG.GetTranslation("score_cupid_paired")
    end
end)

------------
-- HEARTS --
------------

local heart_color = Color(230, 90, 200, 255)

AddHook("TTTShouldPlayerSmoke", "Cupid_TTTShouldPlayerSmoke", function(ply, cli, shouldSmoke, smokeColor, smokeParticle, smokeOffset)
    local target = ply:SteamID64()
    if (cli:IsCupid() and (target == cli:GetNWString("TTTCupidTarget1", "") or target == cli:GetNWString("TTTCupidTarget2", "")))
        or (target == cli:GetNWString("TTTCupidLover", "")) then
        return true, heart_color, "particle/heart.vmt"
    end
end)

---------------
-- TARGET ID --
---------------

-- Show lover icon over all lover players
hook.Add("TTTTargetIDPlayerTargetIcon", "Cupid_TTTTargetIDPlayerTargetIcon", function(ply, cli, showJester)
    local target = ply:SteamID64()
    if cli:IsCupid() and (target == cli:GetNWString("TTTCupidTarget1", "") or target == cli:GetNWString("TTTCupidTarget2", "")) then
        return "lover", false, heart_color, "up"
    elseif target == cli:GetNWString("TTTCupidLover", "") then
        return "lover", true, heart_color, "up"
    end
end)

AddHook("TTTTargetIDPlayerRoleIcon", "Cupid_TTTTargetIDPlayerRoleIcon", function(ply, cli, role, noz, colorRole, hideBeggar, showJester, hideBodysnatcher)
    if ply:IsActiveCupid() and ply:SteamID64() == cli:GetNWString("TTTCupidShooter", "") then
        return ROLE_CUPID, true
    elseif ply:SteamID64() == cli:GetNWString("TTTCupidLover", "") then
        return ply:GetRole(), true, ply:GetRole()
    end
end)

AddHook("TTTTargetIDPlayerRing", "Cupid_TTTTargetIDPlayerRing", function(ent, cli, ringVisible)
    if not IsPlayer(ent) then return end

    if ent:IsActiveCupid() and ent:SteamID64() == cli:GetNWString("TTTCupidShooter", "") then
        return true, ROLE_COLORS_RADAR[ROLE_CUPID]
    elseif ent:SteamID64() == cli:GetNWString("TTTCupidLover", "") then
        return true, ROLE_COLORS_RADAR[ent:GetRole()]
    end
end)

AddHook("TTTTargetIDPlayerText", "Cupid_TTTTargetIDPlayerText", function(ent, cli, text, clr, secondaryText)
    if not IsPlayer(ent) then return end

    if ent:IsActiveCupid() and ent:SteamID64() == cli:GetNWString("TTTCupidShooter", "") then
        return StringUpper(ROLE_STRINGS[ROLE_CUPID]), ROLE_COLORS_RADAR[ROLE_CUPID]
    elseif ent:SteamID64() == cli:GetNWString("TTTCupidLover", "") then
        return StringUpper(ROLE_STRINGS[ent:GetRole()]), ROLE_COLORS_RADAR[ent:GetRole()], LANG.GetTranslation("scoreboard_cupid_lover"), heart_color
    end
end)

ROLE_IS_TARGETID_OVERRIDDEN[ROLE_CUPID] = function(ply, target, showJester)
    if (target:IsActiveCupid() and target:SteamID64() == ply:GetNWString("TTTCupidShooter", "")) or
        (target:SteamID64() == ply:GetNWString("TTTCupidLover", "")) then
        ------ icon, ring, text
        return true, true, true
    end
end

----------------
-- SCOREBOARD --
----------------

AddHook("TTTScoreboardPlayerRole", "Cupid_TTTScoreboardPlayerRole", function(ply, cli, c, roleStr)
    if ply:IsActiveCupid() and ply:SteamID64() == cli:GetNWString("TTTCupidShooter", "") then
        return ROLE_COLORS_SCOREBOARD[ROLE_CUPID], ROLE_STRINGS_SHORT[ROLE_CUPID]
    elseif ply:SteamID64() == cli:GetNWString("TTTCupidLover", "") then
        return ROLE_COLORS_SCOREBOARD[ply:GetRole()], ROLE_STRINGS_SHORT[ply:GetRole()], ply:GetRole()
    elseif ply:SteamID64() == cli:GetNWString("TTTCupidTarget1", "") or ply:SteamID64() == cli:GetNWString("TTTCupidTarget2", "") then
        return c, roleStr, ROLE_CUPID
    end
end)

AddHook("TTTScoreboardPlayerName", "Cupid_TTTScoreboardPlayerName", function(ply, cli, nickTxt)
    if ply:SteamID64() == cli:GetNWString("TTTCupidLover", "") then
        return ply:Nick() .. " (" .. LANG.GetTranslation("scoreboard_cupid_your_lover") .. ")"
    elseif ply:SteamID64() == cli:GetNWString("TTTCupidTarget1", "") or ply:SteamID64() == cli:GetNWString("TTTCupidTarget2", "") then
        return ply:Nick() .. " (" .. LANG.GetTranslation("scoreboard_cupid_lover") .. ")"
    end
end)

ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_CUPID] = function(ply, target, showJester)
    local name = false
    -- Cupid itself only gets the role info shown
    local role = target:IsActiveCupid() and target:SteamID64() == ply:GetNWString("TTTCupidShooter", "")

    -- The lovers get role and color shown
    if (target:SteamID64() == ply:GetNWString("TTTCupidLover", "")) or
        (target:SteamID64() == ply:GetNWString("TTTCupidTarget1", "") or target:SteamID64() == ply:GetNWString("TTTCupidTarget2", "")) then
        name = true
        role = true
    end

    ------ name, role
    return name, role
end

------------------
-- HIGHLIGHTING --
------------------

local lover_vision = false
local vision_enabled = false
local client = nil

local function EnableLoverHighlights()
    AddHook("PreDrawHalos", "Cupid_Highlight_PreDrawHalos", function()
        local lover = client:GetNWString("TTTCupidLover", "")
        local loverPly = player.GetBySteamID64(lover)
        if not IsPlayer(loverPly) or not loverPly:IsActive() then return end

        HaloAdd({ loverPly }, heart_color, 1, 1, 1, true, true)
    end)
end

AddHook("TTTUpdateRoleState", "Cupid_Highlight_TTTUpdateRoleState", function()
    client = LocalPlayer()
    lover_vision = cupid_lover_vision_enabled:GetBool()

    -- Disable highlights on role change
    if vision_enabled then
        RemoveHook("PreDrawHalos", "Cupid_Highlight_PreDrawHalos")
        vision_enabled = false
    end
end)

AddHook("Think", "Cupid_Highlight_Think", function()
    if not IsPlayer(client) or not client:Alive() or client:IsSpec() then return end

    local lover = client:GetNWString("TTTCupidLover", "")
    if lover_vision and #lover > 0 then
        if not vision_enabled then
            EnableLoverHighlights()
            vision_enabled = true
        end
    else
        vision_enabled = false
    end

    if lover_vision and not vision_enabled then
        RemoveHook("PreDrawHalos", "Cupid_Highlight_PreDrawHalos")
    end
end)

--------------
-- TUTORIAL --
--------------

AddHook("TTTTutorialRoleText", "Cupid_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_CUPID then
        local roleTeam = player.GetRoleTeam(ROLE_CUPID, true)
        local roleTeamName, roleColor = GetRoleTeamInfo(roleTeam)
        local html = "The " .. ROLE_STRINGS[ROLE_CUPID] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. roleTeamName .. "</span> team that wins by making two players fall in love and helping them win together. However, players that fall in love die together and cannot survive while the other is dead."

        -- Bow weapon
        html = html .. "<span style='display: block; margin-top: 10px;'>They are given a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>bow</span> that will cause a player to fall in love when they are shot. Once two players have fallen in love they win the round by surviving until the end of the round or being the last players left standing.</span>"

        -- Lovers created notifications
        local lovers_notify_mode = cupid_lovers_notify_mode:GetInt()
        html = html .. "<span style='display: block; margin-top: 10px;'>When the " .. ROLE_STRINGS[ROLE_CUPID] .. " makes two players fall in love, an announcement is shown <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>"
        if lovers_notify_mode == ANNOUNCE_REVEAL_NONE then
            html = html .. "only to them"
        elseif lovers_notify_mode == ANNOUNCE_REVEAL_INNOCENTS then
            html = html .. "to all " .. LANG.GetTranslation("innocents")
        elseif lovers_notify_mode == ANNOUNCE_REVEAL_TRAITORS then
            html = html .. "to all " .. LANG.GetTranslation("traitors")
        else
            html = html .. "to everyone"
        end
        html = html .. "</span>.</span>"

        -- Win condition
        html = html .. "<span style='display: block; margin-top: 10px;'>As <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. ROLE_STRINGS_EXT[ROLE_CUPID] .. "</span> you do not need to survive until the end of the round to win. As long as the lovers survive you still win.</span>"

        -- Friendly fire
        -- Cupid -> Lovers
        if roleTeam ~= ROLE_TEAM_JESTER and not cupid_can_damage_lovers:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_CUPID] .. " can fight alongside the lovers without worrying, as they <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>cannot damage</span> the players they made fall in love.</span>"
        end

        -- Lover -> Lover
        if not cupid_lovers_can_damage_lovers:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>To help the lovers stay alive, they <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>cannot damage</span> eachother.</span>"
        end

        -- Lovers -> Cupid
        if not cupid_lovers_can_damage_cupid:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>To help prevent friendly fire, the lovers <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>cannot damage</span> " .. ROLE_STRINGS[ROLE_CUPID] .. ".</span>"
        end

        return html
    end
end)