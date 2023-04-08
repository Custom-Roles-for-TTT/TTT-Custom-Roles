local hook = hook
local math = math

local MathCos = math.cos
local MathSin = math.sin
local GetAllPlayers = player.GetAll

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Sponge_Translations_Initialize", function()
    -- Win conditions
    LANG.AddToLanguage("english", "win_sponge", "The {role} has absorbed themselves to death!")
    LANG.AddToLanguage("english", "ev_win_sponge", "The absorbant {role} won the round!")

    -- Scoring
    LANG.AddToLanguage("english", "score_sponge_killedby", "Killed by")
    LANG.AddToLanguage("english", "score_sponge_damaging", "{attacker} damaging")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_sponge", [[You are {role}! You want to die but you
deal no damage so you must be killed by absorbing
damage done to other players. Absorb damage by
keeping players inside your visible aura.]])
end)

-------------------
-- ROLE FEATURES --
-------------------

hook.Add("TTTPlayerAliveClientThink", "Sponge_RoleFeatures_TTTPlayerAliveClientThink", function(client, ply)
    if ply:GetRole() == ROLE_SPONGE then
        local ply_pos = ply:GetPos()
        if not ply.SpongeAuraEmitter then ply.SpongeAuraEmitter = ParticleEmitter(ply_pos) end
        if not ply.SpongeAuraNextPart then ply.SpongeAuraNextPart = CurTime() end
        if not ply.SpongeAuraDir then ply.SpongeAuraDir = 0 end
        local pos = ply_pos + Vector(0, 0, 30)
        if ply.SpongeAuraNextPart < CurTime() and client:GetPos():Distance(pos) <= 3000 then
            ply.SpongeAuraEmitter:SetPos(pos)
            ply.SpongeAuraNextPart = CurTime() + 0.02
            ply.SpongeAuraDir = ply.SpongeAuraDir + 0.05
            local radius = GetGlobalFloat("ttt_sponge_aura_radius", UNITS_PER_FIVE_METERS)
            local vec = Vector(MathSin(ply.SpongeAuraDir) * radius, MathCos(ply.SpongeAuraDir) * radius, 10)
            local particle = ply.SpongeAuraEmitter:Add("particle/sponge.vmt", ply_pos + vec)
            particle:SetVelocity(Vector(0, 0, 20))
            particle:SetDieTime(1)
            particle:SetStartAlpha(200)
            particle:SetEndAlpha(0)
            particle:SetStartSize(3)
            particle:SetEndSize(2)
            particle:SetRoll(0)
            particle:SetRollDelta(0)
            local color = ROLE_COLORS[ROLE_SPONGE]
            -- If all living players are within the aura, change the color to red
            if ply:GetNWBool("SpongeAllInRadius", false) then
                color = COLOR_RED
            end
            particle:SetColor(color.r, color.g, color.b)
        end
    elseif ply.SpongeAuraEmitter then
        ply.SpongeAuraEmitter:Finish()
        ply.SpongeAuraEmitter = nil
        ply.SpongeAuraDir = nil
        ply.SpongeAuraNextPart = nil
    end
end)

local client = nil
hook.Add("HUDPaintBackground", "Sponge_HUDPaintBackground", function()
    if not client then client = LocalPlayer() end

    if not IsPlayer(client) then return end
    if not client:Alive() then return end
    if client:IsSapper() then return end

    local inside = false
    local allInside = false
    for _, p in pairs(GetAllPlayers()) do
        if p:IsSponge() and client:GetPos():Distance(p:GetPos()) <= GetGlobalFloat("ttt_sponge_aura_radius", UNITS_PER_FIVE_METERS) then
            inside = true
            if p:GetNWBool("SpongeAllInRadius", false) then
                allInside = true
            end
            break
        end
    end
    local mat = Material("particle/sponge.vmt")
    CRHUD:PaintStatusEffect(inside and not allInside, ROLE_COLORS[ROLE_SPONGE], mat, "SpongeAura")
    CRHUD:PaintStatusEffect(allInside, COLOR_RED, mat, "SpongeDisabledAura")
end)

----------------
-- WIN CHECKS --
----------------

hook.Add("TTTScoringWinTitle", "Sponge_TTTScoringWinTitle", function(wintype, wintitles, title, secondary_win_role)
    if wintype == WIN_SPONGE then
        return { txt = "hilite_win_role_singular", params = { role = string.upper(ROLE_STRINGS[ROLE_SPONGE]) }, c = ROLE_COLORS[ROLE_SPONGE] }
    end
end)

------------
-- EVENTS --
------------

hook.Add("TTTEventFinishText", "Sponge_TTTEventFinishText", function(e)
    if e.win == WIN_SPONGE then
        return LANG.GetParamTranslation("ev_win_sponge", { role = string.lower(ROLE_STRINGS[ROLE_SPONGE]) })
    end
end)

hook.Add("TTTEventFinishIconText", "Sponge_TTTEventFinishIconText", function(e, win_string, role_string)
    if e.win == WIN_SPONGE then
        return win_string, ROLE_STRINGS[ROLE_SPONGE]
    end
end)

-------------
-- SCORING --
-------------

-- Show who killed the sponge (if anyone)
hook.Add("TTTScoringSummaryRender", "Sponge_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
    if not IsPlayer(ply) then return end

    if ply:IsSponge() then
        local spongeKiller = ply:GetNWString("SpongeKiller", "")
        local spongeProtecting = ply:GetNWString("SpongeProtecting", "")
        if spongeKiller ~= "" then
            if spongeProtecting ~= "" then
                return roleFileName, groupingRole, roleColor, name, spongeProtecting, LANG.GetParamTranslation("score_sponge_damaging", {attacker = spongeKiller})
            end
            return roleFileName, groupingRole, roleColor, name, spongeKiller, LANG.GetTranslation("score_sponge_killedby")
        end
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Sponge_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_SPONGE then
        local roleColor = GetRoleTeamColor(ROLE_TEAM_JESTER)
        local html =  "The " .. ROLE_STRINGS[ROLE_SPONGE] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>jester</span> role whose goal is to be killed by another player."

        local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
        html = html .. "<span style='display: block; margin-top: 10px;'>The main way " .. ROLE_STRINGS_PLURAL[ROLE_SPONGE] .. " take damage is by absorbing it from other players who are <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>damaged within their aura</span>. Keep other players close to secure the win!</span>"

        html = html .. "<span style='display: block; margin-top: 10px;'>Be careful! If all players are within the " .. ROLE_STRINGS[ROLE_SPONGE] .. "'s aura, <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>it will stop working</span>. Watch out for when it changes color to red!</span>"

        html = html .. "<span style='display: block; margin-top: 10px;'>Another thing to watch out for: The aura will <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>shrink in size</span> as more players die!</span>"

        return html
    end
end)