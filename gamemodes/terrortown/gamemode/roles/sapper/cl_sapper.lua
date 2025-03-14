local hook = hook
local math = math
local player = player

local MathCos = math.cos
local MathSin = math.sin
local PlayerIterator = player.Iterator

-------------
-- CONVARS --
-------------

local sapper_aura_radius = GetConVar("ttt_sapper_aura_radius")
local sapper_protect_self = GetConVar("ttt_sapper_protect_self")
local sapper_fire_immune = GetConVar("ttt_sapper_fire_immune")
local sapper_can_see_c4 = GetConVar("ttt_sapper_can_see_c4")
local sapper_c4_guaranteed_defuse = GetConVar("ttt_sapper_c4_guaranteed_defuse")

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Sapper_Translations_Initialize", function()
    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_sapper", "Has an aura that makes players immune to explosions.")

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
    local sapper = net.ReadPlayer()
    local sapperPos = sapper:GetPos()
    local pos = sapperPos + Vector(0, 0, 30)
    if client:GetPos():Distance(pos) > 3000 then return end

    local radius = sapper_aura_radius:GetInt() * UNITS_PER_METER
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
        if ply.SapAuraNextPart < CurTime() and client:GetPos():Distance(pos) <= 3000 then
            ply.SapAuraEmitter:SetPos(pos)
            ply.SapAuraNextPart = CurTime() + 0.02
            ply.SapAuraDir = ply.SapAuraDir + 0.05
            local radius = sapper_aura_radius:GetInt() * UNITS_PER_METER
            CreateParticle(ply.SapAuraDir, ply:GetPos(), radius, ply.SapAuraEmitter)
        end
    elseif ply.SapAuraEmitter then
        ply.SapAuraEmitter:Finish()
        ply.SapAuraEmitter = nil
        ply.SapAuraDir = nil
        ply.SapAuraNextPart = nil
    end
end)

local client = nil
local barrel = Material("particle/sap_barrel.vmt")
hook.Add("HUDPaintBackground", "Sapper_HUDPaintBackground", function()
    if not client then client = LocalPlayer() end

    if not IsPlayer(client) then return end
    if not client:Alive() then return end
    if client:IsSapper() then return end

    local inside = false
    for _, p in PlayerIterator() do
        if p:IsActive() and p:GetDisplayedRole() == ROLE_SAPPER and client:GetPos():Distance(p:GetPos()) <= (sapper_aura_radius:GetInt() * UNITS_PER_METER) then
            inside = true
            break
        end
    end
    CRHUD:PaintStatusEffect(inside, ROLE_COLORS[ROLE_SAPPER], barrel, "SapperAura")
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Sapper_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_SAPPER then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]

        -- Fire immunity
        local fire_immune = sapper_fire_immune:GetBool()
        local andfire = ""
        if fire_immune then
            andfire = "and fire "
        end

        local html
        if DETECTIVE_ROLES[ROLE_SAPPER] then
            local detectiveColor = ROLE_COLORS[ROLE_DETECTIVE]
            html = "The " .. ROLE_STRINGS[ROLE_SAPPER] .. " is a " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " and a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose job is to find and eliminate their enemies."
            html = html .. "<span style='display: block; margin-top: 10px;'>Instead of getting a DNA Scanner like a vanilla <span style='color: rgb(" .. detectiveColor.r .. ", " .. detectiveColor.g .. ", " .. detectiveColor.b .. ")'>" .. ROLE_STRINGS[ROLE_DETECTIVE] .. "</span>, they have an explosion " .. andfire .. "protection aura.</span>"
        else
            html = "The " .. ROLE_STRINGS[ROLE_SAPPER] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose job is to find and eliminate their enemies while helping their allies using their explosion " .. andfire .. "protection aura."
        end

        -- Protection Aura
        html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_SAPPER] .. "'s <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>explosion " .. andfire .. "protection</span> "
        if sapper_protect_self:GetBool() then
            html = html .. "applies to them as well"
        else
            html = html .. "does NOT apply to them, however"
        end
        html = html .. ".</span>"

        -- Can see C4
        if sapper_can_see_c4:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_SAPPER] .. " can also <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>see the location of planted C4</span>.</span>"
        end

        -- C4 defusal
        if sapper_c4_guaranteed_defuse:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>When defusing C4, the " .. ROLE_STRINGS[ROLE_SAPPER] .. " <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>will always succeeed</span>.</span>"
        end

        -- Hide special detectives mode
        html = html .. "<span style='display: block; margin-top: 10px;'>Other players will know you are " .. ROLE_STRINGS_EXT[ROLE_DETECTIVE] .. " just by <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>looking at you</span>"
        local special_detective_mode = GetConVar("ttt_detectives_hide_special_mode"):GetInt()
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