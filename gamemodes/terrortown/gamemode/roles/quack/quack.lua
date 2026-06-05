AddCSLuaFile()

local hook = hook
local player = player

local AddHook = hook.Add
local RemoveHook = hook.Remove
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

ROLE_REGISTER_HOOKS[ROLE_QUACK] = function()
    AddHook("EntityTakeDamage", "Quack_EntityTakeDamage", Quack_EntityTakeDamage)
    AddHook("TTTFakeCurePlayer", "Quack_TTTFakeCurePlayer", Quack_TTTFakeCurePlayer)
end

ROLE_UNREGISTER_HOOKS[ROLE_QUACK] = function()
    RemoveHook("EntityTakeDamage", "Quack_EntityTakeDamage")
    RemoveHook("TTTFakeCurePlayer", "Quack_TTTFakeCurePlayer")
end