local hook = hook
local math = math
local player = player

local MathCos = math.cos
local MathSin = math.sin
local PlayerIterator = player.Iterator

-------------
-- CONVARS --
-------------

local paladin_aura_radius = GetConVar("ttt_paladin_aura_radius")
local paladin_protect_self = GetConVar("ttt_paladin_protect_self")
local paladin_heal_self = GetConVar("ttt_paladin_heal_self")
local paladin_damage_reduction = GetConVar("ttt_paladin_damage_reduction")

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Paladin_Translations_Initialize", function()
    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_paladin", "Has an aura that can heal players and reduce incoming damage.")

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
    if ply:GetDisplayedRole() == ROLE_PALADIN then
        if not ply.AuraEmitter then ply.AuraEmitter = ParticleEmitter(ply:GetPos()) end
        if not ply.AuraNextPart then ply.AuraNextPart = CurTime() end
        if not ply.AuraDir then ply.AuraDir = 0 end
        local pos = ply:GetPos() + Vector(0, 0, 30)
        if ply.AuraNextPart < CurTime() and client:GetPos():Distance(pos) <= 3000 then
            ply.AuraEmitter:SetPos(pos)
            ply.AuraNextPart = CurTime() + 0.02
            ply.AuraDir = ply.AuraDir + 0.05
            local radius = paladin_aura_radius:GetFloat() * UNITS_PER_METER
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
    elseif ply.AuraEmitter then
        ply.AuraEmitter:Finish()
        ply.AuraEmitter = nil
        ply.AuraDir = nil
        ply.AuraNextPart = nil
    end
end)

local client = nil
local shield = Material("particle/shield.vmt")
hook.Add("HUDPaintBackground", "Paladin_HUDPaintBackground", function()
    if not client then client = LocalPlayer() end

    if not IsPlayer(client) then return end
    if not client:Alive() then return end
    if client:IsPaladin() then return end

    local inside = false
    for _, p in PlayerIterator() do
        if p:IsActive() and p:GetDisplayedRole() == ROLE_PALADIN and client:GetPos():Distance(p:GetPos()) <= (paladin_aura_radius:GetFloat() * UNITS_PER_METER) then
            inside = true
            break
        end
    end
    CRHUD:PaintStatusEffect(inside, ROLE_COLORS[ROLE_PALADIN], shield, "PaladinAura")
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Paladin_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_PALADIN then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local detectiveColor = ROLE_COLORS[ROLE_DETECTIVE]
        local html = "The " .. ROLE_STRINGS[ROLE_PALADIN] .. " is a " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " and a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose job is to find and eliminate their enemies."

        -- Aura
        local has_damage_reduction = paladin_damage_reduction:GetFloat() > 0
        html = html .. "<span style='display: block; margin-top: 10px;'>Instead of getting a DNA Scanner like a vanilla <span style='color: rgb(" .. detectiveColor.r .. ", " .. detectiveColor.g .. ", " .. detectiveColor.b .. ")'>" .. ROLE_STRINGS[ROLE_DETECTIVE] .. "</span>, they have a healing"
        if has_damage_reduction then
            html = html .. " and damage reduction"
        end
        html = html .. " aura.</span>"

        -- Damage reduction
        if has_damage_reduction then
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_PALADIN] .. "'s <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>damage reduction</span> "
            if paladin_protect_self:GetBool() then
                html = html .. "applies to them as well"
            else
                html = html .. "does NOT apply to them, however"
            end
            html = html .. ".</span>"
        end

        -- Healing
        html = html .. "<span style='display: block; margin-top: 10px;'>Their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>healing</span> "
        if paladin_heal_self:GetBool() then
            html = html .. "affects them as well"
        else
            html = html .. "does NOT affect them, unfortunately"
        end
        html = html .. ".</span>"

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