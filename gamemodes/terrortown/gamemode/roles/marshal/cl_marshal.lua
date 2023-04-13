local hook = hook

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Marshal_Translations_Initialize", function()
    -- Weapons
    LANG.AddToLanguage("english", "marshalbadge_help_pri", "Hold {primaryfire} to deputize a player.")
    LANG.AddToLanguage("english", "marshalbadge_help_sec", "The target player will become " .. ROLE_STRINGS_EXT[ROLE_DEPUTY] .. " or " .. ROLE_STRINGS[ROLE_IMPERSONATOR])

    -- Event
    LANG.AddToLanguage("english", "ev_marshal_deputize", "{target} was deputized by {marshal}")

    -- Announcement
    LANG.AddToLanguage("english", "marshal_deputize_announce", "{amarshal} has promoted {target} to be {adeputy}")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_marshal", [[You are {role}! As {adetective}, HQ has given you special resources to find the {traitors}.
You have a {deputy} Badge that can turn any player into a {deputy}.
Be careful, though! If used on a bad player, they will become {animpersonator} instead!

Press {menukey} to receive your equipment!]])
end)

hook.Add("TTTRolePopupParams", "Marshal_TTTRolePopupParams", function(client)
    return { animpersonator = ROLE_STRINGS_EXT[ROLE_IMPERSONATOR] }
end)

-------------
-- SCORING --
-------------

-- Register the scoring events for the marshal
hook.Add("Initialize", "Marshal_Scoring_Initialize", function()
    local traitor_icon = Material("icon16/star.png")
    local Event = CLSCORE.DeclareEventDisplay
    local PT = LANG.GetParamTranslation
    Event(EVENT_DEPUTIZED, {
        text = function(e)
            return PT("ev_marshal_deputize", {target = e.tar, marshal = e.ply})
         end,
        icon = function(e)
            return traitor_icon, "Deputized"
        end})
end)

net.Receive("TTT_Deputized", function(len)
    local marshalname = net.ReadString()
    local targetname = net.ReadString()
    local targetsid = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_DEPUTIZED,
        tar = targetname,
        ply = marshalname,
        sid64 = targetsid,
        bonus = 1
    })

    -- Announce to this player
    if GetGlobalBool("ttt_marshal_announce_deputy", true) then
        local PT = LANG.GetParamTranslation
        local client = LocalPlayer()
        local message = PT("marshal_deputize_announce", {
            target = targetname,
            amarshal = string.Capitalize(ROLE_STRINGS_EXT[ROLE_MARSHAL]),
            adeputy = ROLE_STRINGS_EXT[ROLE_DEPUTY]
        })
        client:PrintMessage(HUD_PRINTTALK, message)
        client:PrintMessage(HUD_PRINTCENTER, message)
    end
end)

--------------
-- TUTORIAL --
--------------

local function GetChanceTutorialString(chance, targetTeam, roleColor, detectiveColor, traitorColor)
    local html = "<span style='display: block; margin-top: 10px;'>"
    if chance == -1 then
        html = html .. "Members of the " .. targetTeam .. " team cannot be deputized."
    else
        local pct = math.Round(math.Clamp(chance, 0.1, 1.0) * 100)
        html = html .. "When deputizing a " .. targetTeam .. " team member, there is a <span style='color: rgb(" .. detectiveColor.r .. ", " .. detectiveColor.g .. ", " .. detectiveColor.b .. ")'>" .. pct .. "%</span> chance that they will become <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. ROLE_STRINGS_EXT[ROLE_DEPUTY] .. "</span>. If that fails, they will become <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>".. ROLE_STRINGS_EXT[ROLE_IMPERSONATOR] .. "</span> instead"
    end

    return html .. ".</span>"
end

hook.Add("TTTTutorialRoleText", "Marshal_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_MARSHAL then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
        local detectiveColor = GetRoleTeamColor(ROLE_TEAM_DETECTIVE)
        local html = "The " .. ROLE_STRINGS[ROLE_MARSHAL] .. " is a " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " and a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose job is to find and eliminate their enemies."

        html = html .. "<span style='display: block; margin-top: 10px;'>Instead of getting a DNA Scanner like a vanilla <span style='color: rgb(" .. detectiveColor.r .. ", " .. detectiveColor.g .. ", " .. detectiveColor.b .. ")'>" .. ROLE_STRINGS[ROLE_DETECTIVE] .. "</span>, they have the ability to promote another player to be their " .. ROLE_STRINGS[ROLE_DEPUTY] .. ".</span>"

        if GetGlobalBool("ttt_marshal_announce_deputy", true) then
            html = html .. "<span style='display: block; margin-top: 10px;'>When a player is deputized it will be <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>announced to everybody</span>.</span>"
        end

        local monster_deputy_chance = GetGlobalFloat("ttt_marshal_monster_deputy_chance", "0.5")
        html = html .. GetChanceTutorialString(monster_deputy_chance, "monster", roleColor, detectiveColor, traitorColor)

        local jester_deputy_chance = GetGlobalFloat("ttt_marshal_jester_deputy_chance", "0.5")
        html = html .. GetChanceTutorialString(jester_deputy_chance, "jester", roleColor, detectiveColor, traitorColor)

        local independent_deputy_chance = GetGlobalFloat("ttt_marshal_independent_deputy_chance", "0.5")
        html = html .. GetChanceTutorialString(independent_deputy_chance, "independent", roleColor, detectiveColor, traitorColor)

        return html
    end
end)