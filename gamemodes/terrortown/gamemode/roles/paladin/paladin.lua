AddCSLuaFile()

local hook = hook
local math = math
local player = player
local timer = timer

local PlayerIterator = player.Iterator
local CallHook = hook.Call

-------------
-- CONVARS --
-------------

local paladin_heal_rate = CreateConVar("ttt_paladin_heal_rate", "1", FCVAR_NONE, "The amount of heal a player inside the paladin's aura will heal each second", 0, 10)

local paladin_aura_radius = GetConVar("ttt_paladin_aura_radius")
local paladin_protect_self = GetConVar("ttt_paladin_protect_self")
local paladin_heal_self = GetConVar("ttt_paladin_heal_self")
local paladin_damage_reduction = GetConVar("ttt_paladin_damage_reduction")

-------------------
-- ROLE FEATURES --
-------------------

hook.Add("TTTBeginRound", "Paladin_RoleFeatures_TTTBeginRound", function()
    local paladinHeal = paladin_heal_rate:GetInt()
    local paladinHealSelf = paladin_heal_self:GetBool()
    local paladinRadius = paladin_aura_radius:GetFloat() * UNITS_PER_METER
    timer.Create("paladinheal", 1, 0, function()
        for _, p in PlayerIterator() do
            if p:IsActivePaladin() then
                for _, v in PlayerIterator() do
                    if v:IsActive() and (not v:IsPaladin() or paladinHealSelf) and v:GetPos():Distance(p:GetPos()) <= paladinRadius and v:Health() < v:GetMaxHealth() then
                        local health = math.min(v:GetMaxHealth(), v:Health() + paladinHeal)
                        CallHook("TTTPaladinAuraHealed", nil, p, v, health - v:Health())
                        v:SetHealth(health)
                    end
                end
            end
        end
    end)
end)

hook.Add("TTTEndRound", "Paladin_RoleFeatures_TTTEndRound", function()
    if timer.Exists("paladinheal") then timer.Remove("paladinheal") end
end)

------------------
-- DAMAGE SCALE --
------------------

hook.Add("ScalePlayerDamage", "Paladin_ScalePlayerDamage", function(ply, hitgroup, dmginfo)
    if GetRoundState() < ROUND_ACTIVE then return end

    local att = dmginfo:GetAttacker()
    if not IsPlayer(att) or att:IsPaladin() or (ply:IsPaladin() and not paladin_protect_self:GetBool()) then return end

    local withPaladin = false
    local radius = paladin_aura_radius:GetFloat() * UNITS_PER_METER
    for _, v in PlayerIterator() do
        if v:IsActivePaladin() and v:GetPos():Distance(ply:GetPos()) <= radius then
            withPaladin = true
            break
        end
    end
    if withPaladin then
        local reduction = paladin_damage_reduction:GetFloat()
        dmginfo:ScaleDamage(1 - reduction)
    end
end)