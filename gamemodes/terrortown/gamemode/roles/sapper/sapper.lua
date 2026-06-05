AddCSLuaFile()

local hook = hook
local player = player
local util = util

local AddHook = hook.Add
local RemoveHook = hook.Remove
local PlayerIterator = player.Iterator

util.AddNetworkString("Sapper_ShowDamageAura")

-------------
-- CONVARS --
-------------

local sapper_aura_radius = GetConVar("ttt_sapper_aura_radius")
local sapper_protect_self = GetConVar("ttt_sapper_protect_self")
local sapper_fire_immune = GetConVar("ttt_sapper_fire_immune")
local sapper_c4_guaranteed_defuse = GetConVar("ttt_sapper_c4_guaranteed_defuse")

-------------------
-- ROLE FEATURES --
-------------------

local function Sapper_EntityTakeDamage(ent, dmginfo)
    if GetRoundState() ~= ROUND_ACTIVE then return end
    if not IsPlayer(ent) then return end

    if dmginfo:IsExplosionDamage() or (sapper_fire_immune:GetBool() and dmginfo:IsDamageType(DMG_BURN)) then
        local sapper = nil
        local radius = sapper_aura_radius:GetInt() * UNITS_PER_METER
        local radiusSqr = radius * radius
        for _, v in PlayerIterator() do
            if v:IsActiveSapper() and (v ~= ent or sapper_protect_self:GetBool()) and v:GetPos():DistToSqr(ent:GetPos()) <= radiusSqr then
                sapper = v
                break
            end
        end
        if IsPlayer(sapper) and not sapper:IsRoleAbilityDisabled() then
            dmginfo:ScaleDamage(0)
            dmginfo:SetDamage(0)

            net.Start("Sapper_ShowDamageAura")
                net.WritePlayer(sapper)
            net.Broadcast()
        end
    end
end

-- Let the sapper always defuse the C4 if this succeeds
local function Sapper_TTTC4Disarm(bomb, result, ply)
    if result then return end
    if not IsPlayer(ply) then return end
    if not ply:IsSapper() then return end
    if not sapper_c4_guaranteed_defuse:GetBool() then return end
    if ply:IsRoleAbilityDisabled() then return end
    return true
end

------------------
-- REGISTRATION --
------------------

ROLE_REGISTER_HOOKS[ROLE_SAPPER] = function()
    AddHook("EntityTakeDamage", "Sapper_EntityTakeDamage", Sapper_EntityTakeDamage)
    AddHook("TTTC4Disarm", "Sapper_TTTC4Disarm", Sapper_TTTC4Disarm)
end

ROLE_UNREGISTER_HOOKS[ROLE_SAPPER] = function()
    RemoveHook("EntityTakeDamage", "Sapper_EntityTakeDamage")
    RemoveHook("TTTC4Disarm", "Sapper_TTTC4Disarm")
end