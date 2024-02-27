local halo = halo
local hook = hook
local IsValid = IsValid
local pairs = pairs
local string = string

local RemoveHook = hook.Remove
local GetAllPlayers = player.GetAll

-------------
-- CONVARS --
-------------

local assassin_show_target_icon = GetConVar("ttt_assassin_show_target_icon")
local assassin_target_vision_enabled = GetConVar("ttt_assassin_target_vision_enabled")
local assassin_next_target_delay = GetConVar("ttt_assassin_next_target_delay")
local assassin_allow_lootgoblin_kill = GetConVar("ttt_assassin_allow_lootgoblin_kill")
local assassin_allow_zombie_kill = GetConVar("ttt_assassin_allow_zombie_kill")
local assassin_allow_vampire_kill = GetConVar("ttt_assassin_allow_vampire_kill")
local assassin_target_damage_bonus = GetConVar("ttt_assassin_target_damage_bonus")
local assassin_target_bonus_bought = GetConVar("ttt_assassin_target_bonus_bought")
local assassin_wrong_damage_penalty = GetConVar("ttt_assassin_wrong_damage_penalty")
local assassin_failed_damage_penalty = GetConVar("ttt_assassin_failed_damage_penalty")

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Assassin_Translations_Initialize", function()
    -- Target
    LANG.AddToLanguage("english", "target_assassin_target", "TARGET")
    LANG.AddToLanguage("english", "target_assassin_target_team", "{player}'s TARGET")
    LANG.AddToLanguage("english", "target_current_target", "CURRENT TARGET")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_assassin", [[You are {role}! {comrades}

Your first target is:
{assassintarget}

You will deal more to your target and less damage
to all other players. But take care as killing the wrong
player will result in you losing your damage bonus and
maybe even suffering from a penalty!

Press {menukey} to receive your special equipment!]])
end)

---------------
-- TARGET ID --
---------------

-- Show skull icon over the target's head
hook.Add("TTTTargetIDPlayerTargetIcon", "Assassin_TTTTargetIDPlayerTargetIcon", function(ply, cli, showJester)
    if cli:IsAssassin() and assassin_show_target_icon:GetBool() and cli:GetNWString("AssassinTarget") == ply:SteamID64() and not showJester and not cli:IsSameTeam(ply) then
        return "kill", true, ROLE_COLORS_SPRITE[ROLE_ASSASSIN], "down"
    end
end)

hook.Add("TTTTargetIDPlayerText", "Assassin_TTTTargetIDPlayerText", function(ent, cli, text, col, secondary_text)
    if cli:IsAssassin() and IsPlayer(ent) and ent:SteamID64() == cli:GetNWString("AssassinTarget", "") then
        if ent:GetNWBool("ParasiteInfected", false) then
            secondary_text = LANG.GetTranslation("target_infected")
        end
        return LANG.GetTranslation("target_current_target"), ROLE_COLORS_RADAR[ROLE_ASSASSIN], secondary_text
    end
end)

ROLE_IS_TARGETID_OVERRIDDEN[ROLE_ASSASSIN] = function(ply, target, showJester)
    if not ply:IsAssassin() then return end
    if not IsPlayer(target) then return end

    -- Shared logic
    local show = (target:SteamID64() == ply:GetNWString("AssassinTarget", "")) and not showJester

    ------ icon,  ring, text
    return false, false, show
end

----------------
-- SCOREBOARD --
----------------

-- Flash the assassin target's row on the scoreboard
hook.Add("TTTScoreboardPlayerRole", "Assassin_TTTScoreboardPlayerRole", function(ply, cli, c, roleStr)
    if cli:IsAssassin() and ShouldShowTraitorExtraInfo() and ply:SteamID64() == cli:GetNWString("AssassinTarget", "") then
        return c, roleStr, ROLE_ASSASSIN
    end
end)

hook.Add("TTTScoreboardPlayerName", "Assassin_TTTScoreboardPlayerName", function(ply, cli, text)
    if cli:IsAssassin() and ply:SteamID64() == cli:GetNWString("AssassinTarget", "") then
        local newText = " ("
        if ShouldShowTraitorExtraInfo() and ply:GetNWBool("ParasiteInfected", false) then
            newText = newText .. LANG.GetTranslation("target_infected") .. " | "
        end
        newText = newText .. LANG.GetTranslation("target_assassin_target") .. ")"
        return ply:Nick() .. newText
    end
end)

ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_ASSASSIN] = function(ply, target)
    if not ply:IsAssassin() then return end
    if not IsPlayer(target) then return end

    -- Shared logic
    local show = target:SteamID64() == ply:GetNWString("AssassinTarget", "")

    local name = show and ShouldShowTraitorExtraInfo()
    ------ name, role
    return name, show
end

------------------
-- HIGHLIGHTING --
------------------

local assassin_target_vision = false
local vision_enabled = false
local client = nil

local function EnableAssassinTargetHighlights()
    hook.Add("PreDrawHalos", "Assassin_Highlight_PreDrawHalos", function()
        local target_sid64 = client:GetNWString("AssassinTarget", "")
        if not target_sid64 or #target_sid64 == 0 then return end

        local target = nil
        for _, v in pairs(GetAllPlayers()) do
            if IsValid(v) and v:IsActive() and v ~= client and v:SteamID64() == target_sid64 then
                target = v
                break
            end
        end

        if not target then return end

        -- Highlight the assassin's target as a different color than their friends
        halo.Add({target}, ROLE_COLORS[ROLE_INNOCENT], 1, 1, 1, true, true)
    end)
end

hook.Add("TTTUpdateRoleState", "Assassin_Highlight_TTTUpdateRoleState", function()
    client = LocalPlayer()
    assassin_target_vision = assassin_target_vision_enabled:GetBool()

    -- Disable highlights on role change
    if vision_enabled then
        RemoveHook("PreDrawHalos", "Assassin_Highlight_PreDrawHalos")
        vision_enabled = false
    end
end)

-- Handle enabling and disabling of highlighting
hook.Add("Think", "Assassin_Highlight_Think", function()
    if not IsPlayer(client) or not client:Alive() or client:IsSpec() then return end

    if assassin_target_vision and client:IsAssassin() then
        if not vision_enabled then
            EnableAssassinTargetHighlights()
            vision_enabled = true
        end
    else
        vision_enabled = false
    end

    if assassin_target_vision and not vision_enabled then
        RemoveHook("PreDrawHalos", "Assassin_Highlight_PreDrawHalos")
    end
end)

ROLE_IS_TARGET_HIGHLIGHTED[ROLE_ASSASSIN] = function(ply, target)
    if not ply:IsAssassin() then return end
    if not IsPlayer(target) then return end

    local target_sid64 = ply:GetNWString("AssassinTarget", "")
    if not target_sid64 or #target_sid64 == 0 then return end

    local isTarget = target_sid64 == target:SteamID64()
    return assassin_target_vision and isTarget
end

----------------
-- ROLE POPUP --
----------------

hook.Add("TTTRolePopupParams", "Assassin_TTTRolePopupParams", function(cli)
    if cli:IsAssassin() then
        local target = player.GetBySteamID64(cli:GetNWString("AssassinTarget", ""))
        local targetNick = "No one"
        if IsPlayer(target) then
            targetNick = target:Nick()
        end
        return { assassintarget = string.rep(" ", 42) .. targetNick }
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Assassin_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_ASSASSIN then
        local roleColor = ROLE_COLORS[ROLE_TRAITOR]
        local html = "The " .. ROLE_STRINGS[ROLE_ASSASSIN] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>traitor team</span> whose goal is to eliminate their enemies, one target at a time."

        local delay = assassin_next_target_delay:GetInt()
        html = html .. "<span style='display: block; margin-top: 10px;'>They are assigned an initial target at the start of the round. A new target is assigned "
        if delay > 0 then
            html = html .. delay .. " seconds "
        end
        html = html .. "after their current target is <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>killed</span>.</span>"

        local hasVision = assassin_target_vision_enabled:GetBool()
        if hasVision then
            html = html .. "<span style='display: block; margin-top: 10px;'>Their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>target intel</span> helps them see their target through walls by highlighting them.</span>"
        end

        if assassin_show_target_icon:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>Their current target can"
            if hasVision then
                html = html .. " also"
            end
            html = html .. " be identified by the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>skull</span> icon floating over their head.</span>"
        end

        if GetConVar("ttt_traitors_vision_enabled"):GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'><span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Constant communication</span> with their allies allows them to quickly identify friends by highlighting them in their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>team color</span>.</span>"
        end

        local allow_lootgoblin_kill = assassin_allow_lootgoblin_kill:GetBool() and util.CanRoleSpawn(ROLE_LOOTGOBLIN)
        local allow_zombie_kill = assassin_allow_zombie_kill:GetBool() and util.CanRoleSpawn(ROLE_ZOMBIE)
        local allow_vampire_kill = assassin_allow_vampire_kill:GetBool() and util.CanRoleSpawn(ROLE_VAMPIRE)
        if allow_lootgoblin_kill or allow_zombie_kill or allow_vampire_kill then
            local allowed_roles = {}
            if allow_lootgoblin_kill then
                table.insert(allowed_roles, ROLE_STRINGS[ROLE_LOOTGOBLIN])
            end
            if allow_zombie_kill then
                table.insert(allowed_roles, ROLE_STRINGS[ROLE_ZOMBIE])
            end
            if allow_vampire_kill then
                table.insert(allowed_roles, ROLE_STRINGS[ROLE_VAMPIRE])
            end

            -- Build the table of allowed rules into a properly punctutated list with the last two elements joined by an "and"
            local allowed_string = table.concat(allowed_roles, ", ")
            local allowed_replace = " and"
            if #allowed_roles > 2 then
                allowed_replace  = "," .. allowed_replace
            end
            allowed_string = string.gsub(allowed_string, "(.*),(.*)", "%1" .. allowed_replace .. "%2")

            html = html .. "<span style='display: block; margin-top: 10px;'>The following role(s) are still killable even if they <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>aren't the " .. ROLE_STRINGS[ROLE_ASSASSIN] .. "'s target</span>: " .. allowed_string .. "</span>"
        end

        if assassin_target_damage_bonus:GetFloat() > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>When damaging their target, the " .. ROLE_STRINGS[ROLE_ASSASSIN] .. " gets a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>bonus to their damage</span> ("
            if not assassin_target_bonus_bought:GetBool() then
                html = html .. "not "
            end
            html = html .. "including when using weapons bought from the shop).</span>"
        end

        if assassin_wrong_damage_penalty:GetFloat() > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>When damaging a player that is not their target, the " .. ROLE_STRINGS[ROLE_ASSASSIN] .. " <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>does reduced damage</span>.</span>"
        end

        if assassin_failed_damage_penalty:GetFloat() > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>If the " .. ROLE_STRINGS[ROLE_ASSASSIN] .. " kills a player who is not their target, they <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>do reduced damage</span> for the rest of the round.</span>"
        end

        return html
    end
end)