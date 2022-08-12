AddCSLuaFile()

local hook = hook
local IsValid = IsValid
local pairs = pairs
local player = player
local util = util

local GetAllPlayers = player.GetAll

util.AddNetworkString("Sapper_ShowDamageAura")

-------------
-- CONVARS --
-------------

local sapper_aura_radius = CreateConVar("ttt_sapper_aura_radius", "5", FCVAR_NONE, "The radius of the sapper's aura in meters", 1, 30)
local sapper_protect_self = CreateConVar("ttt_sapper_protect_self", "1")
local sapper_fire_immune = CreateConVar("ttt_sapper_fire_immune", "0")
local sapper_can_see_c4 = CreateConVar("ttt_sapper_can_see_c4", "0")
local sapper_c4_guaranteed_defuse = CreateConVar("ttt_sapper_c4_guaranteed_defuse", "0")

hook.Add("TTTSyncGlobals", "Sapper_TTTSyncGlobals", function()
    SetGlobalFloat("ttt_sapper_aura_radius", sapper_aura_radius:GetInt() * 52.49)
    SetGlobalBool("ttt_sapper_protect_self", sapper_protect_self:GetBool())
    SetGlobalBool("ttt_sapper_fire_immune", sapper_fire_immune:GetBool())
    SetGlobalBool("ttt_sapper_can_see_c4", sapper_can_see_c4:GetBool())
    SetGlobalBool("ttt_sapper_c4_guaranteed_defuse", sapper_c4_guaranteed_defuse:GetBool())
end)

-------------------
-- ROLE FEATURES --
-------------------

hook.Add("EntityTakeDamage", "Sapper_EntityTakeDamage", function(ent, dmginfo)
    if not IsValid(ent) then return end

    if GetRoundState() >= ROUND_ACTIVE and ent:IsPlayer() and (dmginfo:IsExplosionDamage() or (sapper_fire_immune:GetBool() and dmginfo:IsDamageType(DMG_BURN))) then
        if not ent:IsSapper() or sapper_protect_self:GetBool() then
            local sapper = nil
            local radius = GetGlobalFloat("ttt_sapper_aura_radius", 262.45)
            for _, v in pairs(GetAllPlayers()) do
                if v:IsActiveSapper() and v:GetPos():Distance(ent:GetPos()) <= radius then
                    sapper = v
                    break
                end
            end
            if IsPlayer(sapper) then
                dmginfo:ScaleDamage(0)
                dmginfo:SetDamage(0)

                net.Start("Sapper_ShowDamageAura")
                net.WriteEntity(sapper)
                net.Broadcast()
            end
        end
    end
end)

-- Let the sapper always defuse the C4 if this succeeds
hook.Add("TTTC4Disarm", "Sapper_TTTC4Disarm", function(bomb, result, ply)
    if result then return end
    if not IsPlayer(ply) then return end
    if not ply:IsSapper() then return end
    if not sapper_c4_guaranteed_defuse:GetBool() then return end
    return true
end)