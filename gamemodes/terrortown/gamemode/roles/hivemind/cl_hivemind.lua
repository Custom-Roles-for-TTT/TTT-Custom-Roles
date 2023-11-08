local halo = halo
local hook = hook
local IsValid = IsValid
local pairs = pairs

local AddHook = hook.Add
local GetAllPlayers = player.GetAll
local RemoveHook = hook.Remove
local StringUpper = string.upper

-------------
-- CONVARS --
-------------

local hivemind_vision_enable = GetConVar("ttt_hivemind_vision_enable")
local hivemind_friendly_fire = GetConVar("ttt_hivemind_friendly_fire")
local hivemind_join_heal_pct = GetConVar("ttt_hivemind_join_heal_pct")
local hivemind_regen_timer = GetConVar("ttt_hivemind_regen_timer")
local hivemind_regen_per_member_amt = GetConVar("ttt_hivemind_regen_per_member_amt")
local hivemind_regen_max_pct = GetConVar("ttt_hivemind_regen_max_pct")

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "HiveMind_Translations_Initialize", function()
    -- Win conditions
    LANG.AddToLanguage("english", "win_hivemind", "We are {role}!")
    LANG.AddToLanguage("english", "ev_win_hivemind", "The {role} has assimilated everyone!")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_hivemind", [[You are {role}! Killing other
players will have them join you, merging their health
pool and available shop weapons.

Press {menukey} to receive your special equipment!]])
end)

----------------------
-- CHAT DUPLICATION --
----------------------

net.Receive("TTT_HiveMindChatDupe", function()
    local source = net.ReadEntity()
    local text = net.ReadString()

    for _, ply in ipairs(GetAllPlayers()) do
        if ply:IsActiveHiveMind() and source ~= ply then
            chat.AddText(ply, COLOR_WHITE, ": ", text)
        end
    end
end)

---------------
-- TARGET ID --
---------------

AddHook("TTTTargetIDPlayerRoleIcon", "HiveMind_TTTTargetIDPlayerRoleIcon", function(ply, cli, role, noz, colorRole, hideBeggar, showJester, hideBodysnatcher)
    if cli:IsHiveMind() and ply:IsHiveMind() then
        return ROLE_HIVEMIND
    end
end)

AddHook("TTTTargetIDPlayerRing", "HiveMind_TTTTargetIDPlayerRing", function(ent, cli, ringVisible)
    if not IsPlayer(ent) then return end
    if cli:IsHiveMind() and ent:IsHiveMind() then
        return true, ROLE_COLORS_RADAR[ROLE_HIVEMIND]
    end
end)

AddHook("TTTTargetIDPlayerText", "HiveMind_TTTTargetIDPlayerText", function(ent, cli, text, clr, secondaryText)
    if not IsPlayer(ent) then return end

    if cli:IsHiveMind() and ent:IsHiveMind() then
        return StringUpper(ROLE_STRINGS[ROLE_HIVEMIND]), ROLE_COLORS_RADAR[ROLE_HIVEMIND]
    end
end)

ROLE_IS_TARGETID_OVERRIDDEN[ROLE_HIVEMIND] = function(ply, target, showJester)
    if not ply:IsHiveMind() then return end
    if not IsPlayer(target) or not target:IsHiveMind() then return end

    ------ icon, ring, text
    return true, true, true
end

----------------
-- SCOREBOARD --
----------------

AddHook("TTTScoreboardPlayerRole", "HiveMind_TTTScoreboardPlayerRole", function(ply, cli, c, roleStr)
    if ply:IsActiveHiveMind() and cli:IsActiveHiveMind() then
        return ROLE_COLORS_SCOREBOARD[ROLE_HIVEMIND], ROLE_STRINGS_SHORT[ROLE_HIVEMIND]
    end
end)

ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_HIVEMIND] = function(ply, target, showJester)
    if not ply:IsActiveHiveMind() then return end
    if not IsPlayer(target) or not target:IsActiveHiveMind() then return end

    ------ name,  role
    return false, true
end

------------------
-- HIGHLIGHTING --
------------------

local hivemind_vision = false
local vision_enabled = false
local client = nil

local function EnableHiveMindHighlights()
    AddHook("PreDrawHalos", "HiveMind_Highlight_PreDrawHalos", function()
        local hivemind = {}
        for _, v in pairs(GetAllPlayers()) do
            if IsValid(v) and v:IsActiveHiveMind() and v ~= client then
                table.insert(hivemind, v)
            end
        end

        if #hivemind == 0 then return end

        -- Highlight the members of the hive mind in a friendly color
        halo.Add(hivemind, ROLE_COLORS[ROLE_INNOCENT], 1, 1, 1, true, true)
    end)
end

AddHook("TTTUpdateRoleState", "HiveMind_Highlight_TTTUpdateRoleState", function()
    client = LocalPlayer()
    hivemind_vision = hivemind_vision_enable:GetBool()

    -- Disable highlights on role change
    if vision_enabled then
        RemoveHook("PreDrawHalos", "HiveMind_Highlight_PreDrawHalos")
        vision_enabled = false
    end
end)

-- Handle enabling and disabling of highlighting
AddHook("Think", "HiveMind_Highlight_Think", function()
    if not IsPlayer(client) or not client:Alive() or client:IsSpec() then return end

    if hivemind_vision and client:IsHiveMind() then
        if not vision_enabled then
            EnableHiveMindHighlights()
            vision_enabled = true
        end
    else
        vision_enabled = false
    end

    if hivemind_vision and not vision_enabled then
        RemoveHook("PreDrawHalos", "HiveMind_Highlight_PreDrawHalos")
    end
end)

ROLE_IS_TARGET_HIGHLIGHTED[ROLE_HIVEMIND] = function(ply, target)
    if not ply:IsHiveMind() then return end
    if not IsPlayer(target) or not target:IsHiveMind() then return end

    return true
end

----------------
-- WIN CHECKS --
----------------

AddHook("TTTScoringWinTitle", "HiveMind_TTTScoringWinTitle", function(wintype, wintitles, title, secondary_win_role)
    if wintype == WIN_HIVEMIND then
        return { txt = "hilite_win_role_singular", params = { role = string.upper(ROLE_STRINGS[ROLE_HIVEMIND]) }, c = ROLE_COLORS[ROLE_HIVEMIND] }
    end
end)

------------
-- EVENTS --
------------

AddHook("TTTEventFinishText", "HiveMind_TTTEventFinishText", function(e)
    if e.win == WIN_HIVEMIND then
        return LANG.GetParamTranslation("ev_win_hivemind", { role = string.lower(ROLE_STRINGS[ROLE_HIVEMIND]) })
    end
end)

AddHook("TTTEventFinishIconText", "HiveMind_TTTEventFinishIconText", function(e, win_string, role_string)
    if e.win == WIN_HIVEMIND then
        return win_string, ROLE_STRINGS[ROLE_HIVEMIND]
    end
end)

----------------
-- ROLE POPUP --
----------------

AddHook("TTTTutorialRoleText", "HiveMind_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_HIVEMIND then
        local roleTeam = player.GetRoleTeam(ROLE_HIVEMIND, true)
        local roleTeamName, roleColor = GetRoleTeamInfo(roleTeam)
        local html = "The " .. ROLE_STRINGS[ROLE_HIVEMIND] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. roleTeamName .. "</span> team that wins by being the only role left alive. To accomplish this, the " .. ROLE_STRINGS[ROLE_HIVEMIND] .. " assimilates any player they kill."

        html = html .. "<span style='display: block; margin-top: 10px;'>Assimilated players will <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>respawn as part of the " .. ROLE_STRINGS[ROLE_HIVEMIND] .. "</span>.</span>"
        html = html .. "<span style='display: block; margin-top: 10px;'>When a player with a shop is assimilated, their available shop items are <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>added to the " .. ROLE_STRINGS[ROLE_HIVEMIND] .. "'s shop</span>.</span>"

        html = html .. "<span style='display: block; margin-top: 10px;'>All members of the " .. ROLE_STRINGS[ROLE_HIVEMIND] .. " have a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>shared pool of health</span> -- gaining members increases the collective's maximum health and any healing or damage done to one member affects them all.</span>"

        local join_heal_pct = hivemind_join_heal_pct:GetFloat()
        if join_heal_pct > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>When a new member joins the " .. ROLE_STRINGS[ROLE_HIVEMIND] .. ", the collective <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>is healed by " .. (join_heal_pct * 100) .. "% of their former maximum health</span>.</span>"
        end

        local regen_timer = hivemind_regen_timer:GetInt()
        if regen_timer > 0 then
            local max_pct = (hivemind_regen_max_pct:GetFloat() * 100) .. "%"
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_HIVEMIND] .. " will also <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>regenerate " .. hivemind_regen_per_member_amt:GetInt() .. " health per additional member every " .. regen_timer .. " second(s)</span>, up to " .. max_pct .. " of their maximum health.</span>"
        end

        html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_HIVEMIND] .. " also has a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>shared pool of credits</span> -- gaining or spending credits affects the collective.</span>"

        if hivemind_vision_enable:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>To help identify other members of the " .. ROLE_STRINGS[ROLE_HIVEMIND] .. ", they are <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>highlighted with a visible glow</span>.</span>"
        end

        if hivemind_friendly_fire:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>Be careful though! Members of the " .. ROLE_STRINGS[ROLE_HIVEMIND] .. " <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>CAN damage eachother</span> so watch where you're shooting.</span>"
        end

        return html
    end
end)