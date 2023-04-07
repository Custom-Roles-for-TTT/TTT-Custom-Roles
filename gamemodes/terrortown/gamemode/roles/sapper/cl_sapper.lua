local hook = hook
local math = math

local MathCos = math.cos
local MathSin = math.sin

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Sapper_Translations_Initialize", function()
    -- Popup
    LANG.AddToLanguage("english", "info_popup_sapper", [[You are {role}! As {adetective}, HQ has given you special resources to find the {traitors}.
You have an explosion protection aura that is visible to everyone.
Keep your friends close but definitely don't let your enemies closer!

Press {menukey} to receive your equipment!]])
end)

-------------------
-- ROLE FEATURES --
-------------------

local function CreateParticle(auraDir, pos, radius, emitter)
    local vec = Vector(MathSin(auraDir) * radius, MathCos(auraDir) * radius, 10)
    local particle = emitter:Add("particle/sap_barrel.vmt", pos + vec)
    particle:SetVelocity(Vector(0, 0, 20))
    particle:SetDieTime(1)
    particle:SetStartAlpha(200)
    particle:SetEndAlpha(0)
    particle:SetStartSize(3)
    particle:SetEndSize(2)
    particle:SetRoll(0)
    particle:SetRollDelta(0)
    particle:SetColor(ROLE_COLORS[ROLE_SAPPER].r, ROLE_COLORS[ROLE_SAPPER].g, ROLE_COLORS[ROLE_SAPPER].b)
end

net.Receive("Sapper_ShowDamageAura", function()
    local client = LocalPlayer()
    local sapper = net.ReadEntity()
    local sapperPos = sapper:GetPos()
    local pos = sapperPos + Vector(0, 0, 30)
    if client:GetPos():Distance(pos) > 3000 then return end

    local radius = GetGlobalFloat("ttt_sapper_aura_radius", UNITS_PER_FIVE_METERS)
    local auraEmitter = ParticleEmitter(sapperPos)
    auraEmitter:SetPos(pos)

    for auraDir = 0, 6, 0.05 do
        CreateParticle(auraDir, sapperPos, radius, auraEmitter)
    end

    auraEmitter:Finish()
end)

hook.Add("TTTPlayerAliveClientThink", "Sapper_RoleFeatures_TTTPlayerAliveClientThink", function(client, ply)
    if ply:GetDisplayedRole() == ROLE_SAPPER then
        if not ply.SapAuraEmitter then ply.SapAuraEmitter = ParticleEmitter(ply:GetPos()) end
        if not ply.SapAuraNextPart then ply.SapAuraNextPart = CurTime() end
        if not ply.SapAuraDir then ply.SapAuraDir = 0 end
        local pos = ply:GetPos() + Vector(0, 0, 30)
        if ply.SapAuraNextPart < CurTime() then
            if client:GetPos():Distance(pos) <= 3000 then
                ply.SapAuraEmitter:SetPos(pos)
                ply.SapAuraNextPart = CurTime() + 0.02
                ply.SapAuraDir = ply.SapAuraDir + 0.05
                local radius = GetGlobalFloat("ttt_sapper_aura_radius", UNITS_PER_FIVE_METERS)
                CreateParticle(ply.SapAuraDir, ply:GetPos(), radius, ply.SapAuraEmitter)
            end
        end
    elseif ply.SapAuraEmitter then
        ply.SapAuraEmitter:Finish()
        ply.SapAuraEmitter = nil
        ply.SapAuraDir = nil
        ply.SapAuraNextPart = nil
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Sapper_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_SAPPER then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local detectiveColor = GetRoleTeamColor(ROLE_TEAM_DETECTIVE)
        local html = "The " .. ROLE_STRINGS[ROLE_SAPPER] .. " is a " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " and a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose job is to find and eliminate their enemies."

        local fire_immune = GetGlobalBool("ttt_sapper_fire_immune", false)
        local andfire = ""
        if fire_immune then
            andfire = "and fire "
        end
        html = html .. "<span style='display: block; margin-top: 10px;'>Instead of getting a DNA Scanner like a vanilla <span style='color: rgb(" .. detectiveColor.r .. ", " .. detectiveColor.g .. ", " .. detectiveColor.b .. ")'>" .. ROLE_STRINGS[ROLE_DETECTIVE] .. "</span>, they have an explosion " .. andfire .. "protection aura.</span>"

        -- Protection Aura
        html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_SAPPER] .. "'s <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>explosion " .. andfire .. "protection</span> "
        if GetGlobalBool("ttt_sapper_protect_self", false) then
            html = html .. "applies to them as well"
        else
            html = html .. "does NOT apply to them, however"
        end
        html = html .. ".</span>"

        if GetGlobalBool("ttt_sapper_can_see_c4", false) then
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_SAPPER] .. " can also <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>see the location of planted C4</span>.</span>"
        end

        if GetGlobalBool("ttt_sapper_c4_guaranteed_defuse", false) then
            html = html .. "<span style='display: block; margin-top: 10px;'>When defusing C4, the " .. ROLE_STRINGS[ROLE_SAPPER] .. " <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>will always succeeed</span>.</span>"
        end

        html = html .. "<span style='display: block; margin-top: 10px;'>Other players will know you are " .. ROLE_STRINGS_EXT[ROLE_DETECTIVE] .. " just by <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>looking at you</span>"
        local special_detective_mode = GetGlobalInt("ttt_detective_hide_special_mode", SPECIAL_DETECTIVE_HIDE_NONE)
        if special_detective_mode > SPECIAL_DETECTIVE_HIDE_NONE then
            html = html .. ", but not what specific type of " .. ROLE_STRINGS[ROLE_DETECTIVE]
            if special_detective_mode == SPECIAL_DETECTIVE_HIDE_FOR_ALL then
                html = html .. ". <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Not even you know what type of " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " you are</span>"
            end
        end
        html = html .. ".</span>"

        return html
    end
end)