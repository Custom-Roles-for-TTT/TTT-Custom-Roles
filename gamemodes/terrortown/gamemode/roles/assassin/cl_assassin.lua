local halo = halo
local hook = hook
local IsValid = IsValid
local pairs = pairs
local string = string

local GetAllPlayers = player.GetAll

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

-- Show "KILL" icon over the target's head
hook.Add("TTTTargetIDPlayerKillIcon", "Assassin_TTTTargetIDPlayerKillIcon", function(ply, cli, showKillIcon, showJester)
    if cli:IsAssassin() and GetGlobalBool("ttt_assassin_show_target_icon", false) and cli:GetNWString("AssassinTarget") == ply:Nick() and not showJester then
        return true
    end
end)

hook.Add("TTTTargetIDPlayerText", "Assassin_TTTTargetIDPlayerText", function(ent, cli, text, col, secondary_text)
    if cli:IsAssassin() and IsPlayer(ent) and ent:Nick() == cli:GetNWString("AssassinTarget", "") then
        if ent:GetNWBool("Infected", false) then
            secondary_text = LANG.GetTranslation("target_infected")
        end
        return LANG.GetTranslation("target_current_target"), ROLE_COLORS_RADAR[ROLE_ASSASSIN], secondary_text
    end
end)

----------------
-- SCOREBOARD --
----------------

-- Flash the assassin target's row on the scoreboard
hook.Add("TTTScoreboardPlayerRole", "Assassin_TTTScoreboardPlayerRole", function(ply, cli, c, roleStr)
    if cli:IsAssassin() and ply:Nick() == cli:GetNWString("AssassinTarget", "") then
        return c, roleStr, ROLE_ASSASSIN
    end
end)

hook.Add("TTTScoreboardPlayerName", "Assassin_TTTScoreboardPlayerName", function(ply, cli, text)
    if cli:IsAssassin() and ply:Nick() == cli:GetNWString("AssassinTarget", "") then
        local newText = " ("
        if ply:GetNWBool("Infected", false) then
            newText = newText .. LANG.GetTranslation("target_infected") .. " | "
        end
        newText = newText .. LANG.GetTranslation("target_assassin_target") .. ")"
        return ply:Nick() .. newText
    end
end)

------------------
-- HIGHLIGHTING --
------------------

local assassin_target_vision = false
local vision_enabled = false
local client = nil

local function EnableAssassinTargetHighlights()
    hook.Add("PreDrawHalos", "Assassin_Highlight_PreDrawHalos", function()
        local target_nick = client:GetNWString("AssassinTarget", "")
        if not target_nick or #target_nick == 0 then return end

        local target = nil
        for _, v in pairs(GetAllPlayers()) do
            if IsValid(v) and v:Alive() and not v:IsSpec() and v ~= client and v:Nick() == target_nick then
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
    assassin_target_vision = GetGlobalBool("ttt_assassin_target_vision_enable", false)

    -- Disable highlights on role change
    if vision_enabled then
        hook.Remove("PreDrawHalos", "Assassin_Highlight_PreDrawHalos")
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

    if not vision_enabled then
        hook.Remove("PreDrawHalos", "Assassin_Highlight_PreDrawHalos")
    end
end)

----------------
-- ROLE POPUP --
----------------

hook.Add("TTTRolePopupParams", "Assassin_TTTRolePopupParams", function(cli)
    if cli:IsAssassin() then
        return { assassintarget = string.rep(" ", 42) .. cli:GetNWString("AssassinTarget", "") }
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Assassin_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_ASSASSIN then
        local roleColor = ROLE_COLORS[ROLE_TRAITOR]
        local html = "The " .. ROLE_STRINGS[ROLE_ASSASSIN] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>traitor team</span> whose goal is to eliminate their enemies, one target at a time."

        local delay = GetGlobalInt("ttt_assassin_next_target_delay", 0)
        html = html .. "<span style='display: block; margin-top: 10px;'>They are assigned an initial target at the start of the round. A new target is assigned "
        if delay > 0 then
            html = html .. delay .. " seconds "
        end
        html = html .. "after their current target is <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>killed</span>.</span>"

        local hasVision = GetGlobalBool("ttt_assassin_target_vision_enable", false)
        if hasVision then
            html = html .. "<span style='display: block; margin-top: 10px;'>Their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>target intel</span> helps them see their target through walls by highlighting them.</span>"
        end

        if GetGlobalBool("ttt_assassin_show_target_icon", false) then
            html = html .. "<span style='display: block; margin-top: 10px;'>Their current target can"
            if hasVision then
                html = html .. " also"
            end
            html = html .. " be identified by the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>KILL</span> icon floating over their head.</span>"
        end

        if GetGlobalBool("ttt_traitor_vision_enable", false) then
            html = html .. "<span style='display: block; margin-top: 10px;'><span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Constant communication</span> with their allies allows them to quickly identify friends by highlighting them in their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>team color</span>.</span>"
        end

        return html
    end
end)