local hook = hook

local MathCos = math.cos
local MathSin = math.sin

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Paladin_Translations_Initialize", function()
    -- Popup
    LANG.AddToLanguage("english", "info_popup_paladin", [[You are {role}! As {adetective}, HQ has given you special resources to find the {traitors}.
You have a healing aura that is visible to everyone.
Keep your friends close but definitely don't let your enemies closer!

Press {menukey} to receive your equipment!]])
end)

-------------------
-- ROLE FEATURES --
-------------------

hook.Add("TTTPlayerAliveClientThink", "Paladin_RoleFeatures_TTTPlayerAliveClientThink", function(client, ply)
    if ply:IsPaladin() and not GetGlobalBool("ttt_detective_hide_special", false) then
        if not ply.AuraEmitter then ply.AuraEmitter = ParticleEmitter(ply:GetPos()) end
        if not ply.AuraNextPart then ply.AuraNextPart = CurTime() end
        if not ply.AuraDir then ply.AuraDir = 0 end
        local pos = ply:GetPos() + Vector(0, 0, 30)
        if ply.AuraNextPart < CurTime() then
            if client:GetPos():Distance(pos) <= 3000 then
                ply.AuraEmitter:SetPos(pos)
                ply.AuraNextPart = CurTime() + 0.02
                ply.AuraDir = ply.AuraDir + 0.05
                local radius = GetGlobalFloat("ttt_paladin_aura_radius", 262.45)
                local vec = Vector(MathSin(ply.AuraDir) * radius, MathCos(ply.AuraDir) * radius, 10)
                local particle = ply.AuraEmitter:Add("particle/shield.vmt", ply:GetPos() + vec)
                particle:SetVelocity(Vector(0, 0, 20))
                particle:SetDieTime(1)
                particle:SetStartAlpha(200)
                particle:SetEndAlpha(0)
                particle:SetStartSize(3)
                particle:SetEndSize(2)
                particle:SetRoll(0)
                particle:SetRollDelta(0)
                particle:SetColor(ROLE_COLORS[ROLE_PALADIN].r, ROLE_COLORS[ROLE_PALADIN].g, ROLE_COLORS[ROLE_PALADIN].b)
            end
        end
    elseif ply.AuraEmitter then
        ply.AuraEmitter:Finish()
        ply.AuraEmitter = nil
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Paladin_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_PALADIN then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local detectiveColor = GetRoleTeamColor(ROLE_TEAM_DETECTIVE)
        local html = "The " .. ROLE_STRINGS[ROLE_PALADIN] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose job is to find and eliminate their enemies."

        html = html .. "<span style='display: block; margin-top: 10px;'>Instead of getting a DNA Scanner like a vanilla <span style='color: rgb(" .. detectiveColor.r .. ", " .. detectiveColor.g .. ", " .. detectiveColor.b .. ")'>" .. ROLE_STRINGS[ROLE_DETECTIVE] .. "</span>, they have a healing and damage reduction aura.</span>"

        -- Damage Reduction
        html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_PALADIN] .. "'s <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>damage reduction</span> "
        if GetGlobalBool("ttt_paladin_protect_self", false) then
            html = html .. "applies to them as well"
        else
            html = html .. "does NOT apply to them, however"
        end
        html = html .. ".</span>"

        -- Healing
        html = html .. "<span style='display: block; margin-top: 10px;'>Their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>healing</span> "
        if GetGlobalBool("ttt_paladin_heal_self", true) then
            html = html .. "affects them as well"
        else
            html = html .. "does NOT affect them, unfortunately"
        end
        html = html .. ".</span>"

        return html
    end
end)