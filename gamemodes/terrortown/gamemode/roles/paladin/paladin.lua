AddCSLuaFile()

local hook = hook
local math = math
local pairs = pairs
local timer = timer

local GetAllPlayers = player.GetAll
local CallHook = hook.Call

-------------
-- CONVARS --
-------------

local paladin_aura_radius = CreateConVar("ttt_paladin_aura_radius", "5", FCVAR_NONE, "The radius of the paladin's aura in meters", 1, 30)
local paladin_damage_reduction = CreateConVar("ttt_paladin_damage_reduction", "0.3", FCVAR_NONE, "The fraction an attacker's damage will be reduced by when they are shooting a player inside the paladin's aura", 0, 1)
local paladin_heal_rate = CreateConVar("ttt_paladin_heal_rate", "1", FCVAR_NONE, "The amount of heal a player inside the paladin's aura will heal each second", 0, 10)
local paladin_protect_self = CreateConVar("ttt_paladin_protect_self", "0")
local paladin_heal_self = CreateConVar("ttt_paladin_heal_self", "1")

hook.Add("TTTSyncGlobals", "Paladin_TTTSyncGlobals", function()
    SetGlobalFloat("ttt_paladin_aura_radius", paladin_aura_radius:GetInt() * 52.49)
    SetGlobalBool("ttt_paladin_protect_self", paladin_protect_self:GetBool())
    SetGlobalBool("ttt_paladin_heal_self", paladin_heal_self:GetBool())
end)

-------------------
-- ROLE FEATURES --
-------------------

hook.Add("TTTBeginRound", "Paladin_RoleFeatures_TTTBeginRound", function()
    local paladinHeal = paladin_heal_rate:GetInt()
    local paladinHealSelf = paladin_heal_self:GetBool()
    local paladinRadius = GetGlobalFloat("ttt_paladin_aura_radius", 262.45)
    timer.Create("paladinheal", 1, 0, function()
        for _, p in pairs(GetAllPlayers()) do
            if p:IsActivePaladin() then
                for _, v in pairs(GetAllPlayers()) do
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
    local att = dmginfo:GetAttacker()
    if IsPlayer(att) and GetRoundState() >= ROUND_ACTIVE then
        if not ply:IsPaladin() or paladin_protect_self:GetBool() then
            local withPaladin = false
            local radius = GetGlobalFloat("ttt_paladin_aura_radius", 262.45)
            for _, v in pairs(GetAllPlayers()) do
                if v:IsActivePaladin() and v:GetPos():Distance(ply:GetPos()) <= radius then
                    withPaladin = true
                    break
                end
            end
            if withPaladin and not att:IsPaladin() then
                local reduction = paladin_damage_reduction:GetFloat()
                dmginfo:ScaleDamage(1 - reduction)
            end
        end
    end
end)