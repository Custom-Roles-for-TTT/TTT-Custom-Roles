AddCSLuaFile()

local player = player

local PlayerIterator = player.Iterator

-------------------
-- ROLE FEATURES --
-------------------

-- Quacks are immune to explosions
local function Quack_EntityTakeDamage(ent, dmginfo)
    if GetRoundState() ~= ROUND_ACTIVE then return end
    if not IsPlayer(ent) then return end

    if ent:IsQuack() and dmginfo:IsExplosionDamage() then
        dmginfo:ScaleDamage(0)
        dmginfo:SetDamage(0)
    end
end

----------
-- CURE --
----------

local function Quack_TTTFakeCurePlayer(ply)
    if not ply:GetNWBool("ParasiteInfected", false) then return end

    for _, v in PlayerIterator() do
        if v:GetNWString("ParasiteInfectingTarget", "") == ply:SteamID64() then
            v:QueueMessage(MSG_PRINTCENTER, "A fake cure has been used on your host.")
        end
    end
end

------------------
-- REGISTRATION --
------------------

ROLE_REGISTERED_HOOKS[ROLE_QUACK] = {
    ["EntityTakeDamage"] = Quack_EntityTakeDamage,
    ["TTTFakeCurePlayer"] = Quack_TTTFakeCurePlayer
}