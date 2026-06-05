AddCSLuaFile()

local hook = hook
local math = math
local player = player
local timer = timer

local AddHook = hook.Add
local RemoveHook = hook.Remove
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

local function Paladin_RoleFeatures_TTTBeginRound()
    local paladinHeal = paladin_heal_rate:GetInt()
    local paladinHealSelf = paladin_heal_self:GetBool()
    local paladinRadius = paladin_aura_radius:GetFloat() * UNITS_PER_METER
    local paladinRadiusSqr = paladinRadius * paladinRadius
    timer.Create("paladinheal", 1, 0, function()
        for _, p in PlayerIterator() do
            if p:IsActivePaladin() and not p:IsRoleAbilityDisabled() then
                for _, v in PlayerIterator() do
                    if v:IsActive() and (not v:IsPaladin() or paladinHealSelf) and v:GetPos():DistToSqr(p:GetPos()) <= paladinRadiusSqr and v:Health() < v:GetMaxHealth() then
                        local health = math.min(v:GetMaxHealth(), v:Health() + paladinHeal)
                        CallHook("TTTPaladinAuraHealed", nil, p, v, health - v:Health())
                        v:SetHealth(health)
                    end
                end
            end
        end
    end)
end

local function Paladin_RoleFeatures_TTTEndRound()
    if timer.Exists("paladinheal") then timer.Remove("paladinheal") end
end

------------------
-- DAMAGE SCALE --
------------------

local function Paladin_ScalePlayerDamage(ply, hitgroup, dmginfo)
    if GetRoundState() < ROUND_ACTIVE then return end

    local att = dmginfo:GetAttacker()
    if not IsPlayer(att) or att:IsPaladin() or (ply:IsPaladin() and not paladin_protect_self:GetBool()) then return end

    local withPaladin = false
    local radius = paladin_aura_radius:GetFloat() * UNITS_PER_METER
    local radiusSqr = radius * radius
    for _, v in PlayerIterator() do
        if v:IsActivePaladin() and v:GetPos():DistToSqr(ply:GetPos()) <= radiusSqr and not v:IsRoleAbilityDisabled() then
            withPaladin = true
            break
        end
    end
    if withPaladin then
        local reduction = paladin_damage_reduction:GetFloat()
        dmginfo:ScaleDamage(1 - reduction)
    end
end

------------------
-- REGISTRATION --
------------------

ROLE_REGISTER_HOOKS[ROLE_PALADIN] = function()
    AddHook("ScalePlayerDamage", "Paladin_ScalePlayerDamage", Paladin_ScalePlayerDamage)
    AddHook("TTTBeginRound", "Paladin_RoleFeatures_TTTBeginRound", Paladin_RoleFeatures_TTTBeginRound)
    AddHook("TTTEndRound", "Paladin_RoleFeatures_TTTEndRound", Paladin_RoleFeatures_TTTEndRound)
end

ROLE_UNREGISTER_HOOKS[ROLE_PALADIN] = function()
    RemoveHook("ScalePlayerDamage", "Paladin_ScalePlayerDamage")
    RemoveHook("TTTBeginRound", "Paladin_RoleFeatures_TTTBeginRound")
    RemoveHook("TTTEndRound", "Paladin_RoleFeatures_TTTEndRound")
end