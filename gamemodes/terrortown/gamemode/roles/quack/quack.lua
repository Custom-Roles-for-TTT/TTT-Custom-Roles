AddCSLuaFile()

local hook = hook
local IsValid = IsValid

-------------
-- CONVARS --
-------------

local quack_phantom_cure = CreateConVar("ttt_quack_phantom_cure", "0")
local quack_station_bomb = CreateConVar("ttt_quack_station_bomb", "0")

hook.Add("TTTSyncGlobals", "Quack_TTTSyncGlobals", function()
    SetGlobalBool("ttt_quack_phantom_cure", quack_phantom_cure:GetBool())
    SetGlobalBool("ttt_quack_station_bomb", quack_station_bomb:GetBool())
end)

-------------------
-- ROLE FEATURES --
-------------------

-- Quacks are immune to explosions
hook.Add("EntityTakeDamage", "Quack_EntityTakeDamage", function(ent, dmginfo)
    if not IsValid(ent) then return end

    if GetRoundState() >= ROUND_ACTIVE and ent:IsPlayer() then
        if ent:IsQuack() and dmginfo:IsExplosionDamage() then
            dmginfo:ScaleDamage(0)
            dmginfo:SetDamage(0)
        end
    end
end)