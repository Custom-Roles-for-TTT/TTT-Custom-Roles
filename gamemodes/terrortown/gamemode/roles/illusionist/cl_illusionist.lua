local hook = hook

local AddHook = hook.Add

-------------
-- CONVARS --
-------------

local illusionist_hides_monsters = GetConVar("ttt_illusionist_hides_monsters")
local illusionist_traitor_credits = GetConVar("ttt_illusionist_traitor_credits")

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "Illusionist_Translations_Initialize", function()
    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_illusionist", "Prevents traitors from knowing who their team mates are.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_illusionist", [[You are {role}! As {adetective}, HQ has given you special resources to find the {traitors}.
Your presence prevents the {traitors} from learning who their comrades are. Use this confusion to your
advantage and watch your back! If you die, they will learn the identities of their fellow {traitors}.

Press {menukey} to receive your equipment!]])
end)

---------------
-- TARGET ID --
---------------

AddHook("TTTTargetIDPlayerRoleIcon", "Illusionist_TTTTargetIDPlayerRoleIcon", function(ply, cli, role, noz, color_role, hideBeggar, showJester, hideBodysnatcher)
    if GetGlobalBool("ttt_illusionist_alive", false) and ((cli:IsActiveTraitorTeam() and (ply:IsTraitorTeam() or ply:IsGlitch())) or (cli:IsActiveMonsterTeam() and ply:IsMonsterTeam() and illusionist_hides_monsters:GetBool())) then
        local icon_overridden, _, _ = cli:IsTargetIDOverridden(ply)
        if icon_overridden then return end

        return false
    end
end)

AddHook("TTTTargetIDPlayerRing", "Illusionist_TTTTargetIDPlayerRing", function(ent, cli, ring_visible)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not IsPlayer(ent) then return end

    if GetGlobalBool("ttt_illusionist_alive", false) and ((cli:IsActiveTraitorTeam() and (ent:IsTraitorTeam() or ent:IsGlitch())) or (cli:IsActiveMonsterTeam() and ent:IsMonsterTeam() and illusionist_hides_monsters:GetBool())) then
        local _, ring_overridden, _ = cli:IsTargetIDOverridden(ent)
        if ring_overridden then return end

        return false
    end
end)

AddHook("TTTTargetIDPlayerText", "Illusionist_TTTTargetIDPlayerText", function(ent, cli, text, col, secondary_text)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not IsPlayer(ent) then return end

    if GetGlobalBool("ttt_illusionist_alive", false) and ((cli:IsActiveTraitorTeam() and (ent:IsTraitorTeam() or ent:IsGlitch())) or (cli:IsActiveMonsterTeam() and ent:IsMonsterTeam() and illusionist_hides_monsters:GetBool())) then
        local _, _, text_overridden = cli:IsTargetIDOverridden(ent)
        if text_overridden then return end

        return false
    end
end)

----------------
-- SCOREBOARD --
----------------

AddHook("TTTScoreboardPlayerRole", "Illusionist_TTTScoreboardPlayerRole", function(ply, cli, color, roleFileName)
    if GetGlobalBool("ttt_illusionist_alive", false) and ply ~= cli and ((cli:IsActiveTraitorTeam() and (ply:IsTraitorTeam() or ply:IsGlitch())) or (cli:IsActiveMonsterTeam() and ply:IsMonsterTeam() and illusionist_hides_monsters:GetBool())) then
        local _, role_overridden = cli:IsScoreboardInfoOverridden(ply)
        if role_overridden then return end

        return false, false
    end
end)

-----------
-- RADAR --
-----------

AddHook("TTTRadarPlayerRender", "Illusionist_TTTRadarPlayerRender", function(cli, tgt, color, hidden)
    if hidden then return end
    if cli == tgt then return end
    if not GetGlobalBool("ttt_illusionist_alive", false) then return end

    if (cli:IsActiveTraitorTeam() and (TRAITOR_ROLES[tgt.role] or tgt.role == ROLE_GLITCH)) or
        (cli:IsActiveMonsterTeam() and MONSTER_ROLES[tgt.role] and illusionist_hides_monsters:GetBool()) then
        return ColorAlpha(ROLE_COLORS_RADAR[ROLE_INNOCENT], color.a)
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Illusionist_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_ILLUSIONIST then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local detectiveColor = ROLE_COLORS[ROLE_DETECTIVE]
        local html = "The " .. ROLE_STRINGS[ROLE_ILLUSIONIST] .. " is a " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " and a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose job is to find and eliminate their enemies."

        html = html .. "<span style='display: block; margin-top: 10px;'>Instead of getting a DNA Scanner like a vanilla <span style='color: rgb(" .. detectiveColor.r .. ", " .. detectiveColor.g .. ", " .. detectiveColor.b .. ")'>" .. ROLE_STRINGS[ROLE_DETECTIVE] .. "</span>, they have the ability to prevent traitors"

        local hides_monsters = illusionist_hides_monsters:GetBool()
        if hides_monsters then
            html = html .. " and monsters"
        end

        html = html .. " from learning who is on their team.</span>"

        html = html .. "<span style='display: block; margin-top: 10px;'>As long as " .. ROLE_STRINGS_EXT[ROLE_ILLUSIONIST] .. " is alive, their enemies will not know who their allies are. However the moment the " .. ROLE_STRINGS[ROLE_ILLUSIONIST] .. " is killed, traitors</span>"

        if hides_monsters then
            html = html .. " and monsters"
        end

        html = html .. " will learn who is on their team.</span>"

        local traitor_credits = illusionist_traitor_credits:GetInt()
        if traitor_credits > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>Traitors"

            if hides_monsters then
                html = html .. " and monsters"
            end

            html = html .. " will be given "

            if traitor_credits == 1 then
                html = html .. "an extra credit"
            else
                html = html .. tostring(traitor_credits) .. " extra credits"
            end

            html = html .. " at the start of the round if there is " .. ROLE_STRINGS_EXT[ROLE_ILLUSIONIST] .. " in play.</span>"
        end

        return html
    end
end)