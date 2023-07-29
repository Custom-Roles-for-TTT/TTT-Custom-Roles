AddCSLuaFile()

local hook = hook
local IsValid = IsValid

-------------------
-- ROLE FEATURES --
-------------------

-- Quacks are immune to explosions
hook.Add("EntityTakeDamage", "Quack_EntityTakeDamage", function(ent, dmginfo)
    if not IsValid(ent) then return end

    if GetRoundState() == ROUND_ACTIVE and ent:IsPlayer() then
        if ent:IsQuack() and dmginfo:IsExplosionDamage() then
            dmginfo:ScaleDamage(0)
            dmginfo:SetDamage(0)
        end
    end
end)