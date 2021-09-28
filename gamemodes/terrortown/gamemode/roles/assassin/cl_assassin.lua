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
    local additionalText = ""
    if cli:IsAssassin() and ply:Nick() == cli:GetNWString("AssassinTarget", "") then
        additionalText = LANG.GetTranslation("target_assassin_target")
    elseif cli:IsTraitorTeam() then
        for _, v in pairs(player.GetAll()) do
            if v:IsAssassin() and ply:Nick() == v:GetNWString("AssassinTarget", "") and v:Alive() and not v:IsSpec() then
                additionalText = LANG.GetParamTranslation("target_assassin_target_team", { player = v:Nick() })
                break
            end
        end
    end

    if #additionalText > 0 then
        local parenLoc, _ = string.find(text, ")")
        if parenLoc then
            local startText = string.sub(text, 1, parenLoc - 1)
            return startText .. " | " .. additionalText .. ")"
        else
            return text .. " (" .. additionalText .. ")"
        end
    end
end)

------------------
-- HIGHLIGHTING --
------------------

local assassin_target_vision = false
local vision_enabled = false
local client = nil

local function EnableAssassinTargetHighlights()
    print("EnableAssassinTargetHighlights")
    hook.Add("PreDrawHalos", "Assassin_Highlight_PreDrawHalos", function()
        local target_nick = client:GetNWString("AssassinTarget", "")
        if not target_nick or target_nick:len() == 0 then return end

        local target = nil
        for _, v in pairs(player.GetAll()) do
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