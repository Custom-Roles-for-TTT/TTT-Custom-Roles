AddCSLuaFile()

local plymeta = FindMetaTable("Player")

local hook = hook
local IsValid = IsValid
local math = math
local net = net
local pairs = pairs
local player = player
local table = table
local util = util

local PlayerIterator = player.Iterator
local MathRandom = math.random

util.AddNetworkString("TTT_VampirePrimeDeath")

-------------
-- CONVARS --
-------------

local vampire_kill_credits = CreateConVar("ttt_vampire_kill_credits", "1")
local vampire_prime_friendly_fire = CreateConVar("ttt_vampire_prime_friendly_fire", "0", FCVAR_NONE, "How to handle friendly fire damage to the prime vampire(s) from their thralls. 0 - Do nothing. 1 - Reflect damage back to the attacker (non-prime vampire). 2 - Negate damage to the prime vampire.", 0, 2)
local vampire_credits_award_pct = CreateConVar("ttt_vampire_credits_award_pct", "0.35")
local vampire_credits_award_size = CreateConVar("ttt_vampire_credits_award_size", "1")
local vampire_credits_award_repeat = CreateConVar("ttt_vampire_credits_award_repeat", "1")

local vampire_damage_reduction = GetConVar("ttt_vampire_damage_reduction")
local vampire_show_target_icon = GetConVar("ttt_vampire_show_target_icon")
local vampire_vision_enabled = GetConVar("ttt_vampire_vision_enabled")
local vampire_prime_death_mode = GetConVar("ttt_vampire_prime_death_mode")

-------------
-- CREDITS --
-------------

-- Reset credit status
hook.Add("Initialize", "Vampire_Credits_Initialize", function()
    GAMEMODE.AwardedVampireCredits = false
    GAMEMODE.AwardedVampireCreditsDead = 0
end)
hook.Add("TTTPrepareRound", "Vampire_Credits_TTTPrepareRound", function()
    GAMEMODE.AwardedVampireCredits = false
    GAMEMODE.AwardedVampireCreditsDead = 0
end)

-- Award credits for valid kill
hook.Add("DoPlayerDeath", "Vampire_Credits_DoPlayerDeath", function(victim, attacker, dmginfo)
    if GetRoundState() ~= ROUND_ACTIVE then return end
    if not IsValid(victim) then return end

    local valid_attacker = IsPlayer(attacker)
    local kill_credits = vampire_kill_credits:GetBool()
    if kill_credits and valid_attacker and not TRAITOR_ROLES[ROLE_VAMPIRE] and attacker:IsActiveVampire() and (not (victim:IsMonsterTeam() or victim:IsJesterTeam())) and (not GAMEMODE.AwardedVampireCredits or vampire_credits_award_repeat:GetBool()) then
        local ply_alive = 0
        local ply_dead = 0

        for _, ply in PlayerIterator() do
            if not ply:IsVampireAlly() then
                if ply:IsTerror() then
                    ply_alive = ply_alive + 1
                elseif ply:IsDeadTerror() then
                    ply_dead = ply_dead + 1
                end
            end
        end

        -- we check this at the death of an innocent who is still technically
        -- Alive(), so add one to dead count and sub one from living
        ply_dead = ply_dead + 1
        ply_alive = math.max(ply_alive - 1, 0)
        local ply_total = ply_alive + ply_dead

        -- Only repeat-award if we have reached the pct again since last time
        if GAMEMODE.AwardedVampireCredits then
            ply_dead = ply_dead - GAMEMODE.AwardedVampireCreditsDead
        end

        local pct = ply_dead / ply_total
        if pct >= vampire_credits_award_pct:GetFloat() then
            -- Traitors have killed sufficient people to get an award
            local amt = vampire_credits_award_size:GetInt()

            -- If size is 0, awards are off
            if amt > 0 then
                LANG.Msg(GetVampireFilter(true), "credit_all", { role = ROLE_STRINGS[ROLE_VAMPIRE], num = amt })

                for _, ply in PlayerIterator() do
                    if ply:IsActiveVampire() then
                        ply:AddCredits(amt)
                    end
                end
            end

            GAMEMODE.AwardedVampireCredits = true
            GAMEMODE.AwardedVampireCreditsDead = ply_dead + GAMEMODE.AwardedVampireCreditsDead
        end
    end
end)

-----------
-- PRIME --
-----------

-- Handle when the prime dies
hook.Add("PlayerDeath", "Vampire_PrimeDeath_PlayerDeath", function(victim, infl, attacker)
    local prime_death_mode = vampire_prime_death_mode:GetFloat()
    -- If the prime died and we're doing something when that happens
    if victim:IsVampirePrime() and prime_death_mode > VAMPIRE_DEATH_NONE then
        local living_vampire_primes = 0
        local vampires = {}
        -- Find all the living vampires and count the primes
        for _, v in PlayerIterator() do
            if v:IsActiveVampire() then
                if v:IsVampirePrime() then
                    living_vampire_primes = living_vampire_primes + 1
                end
                table.insert(vampires, v)
            end
        end

        -- If there are no more living primes, do something with the non-primes
        if living_vampire_primes == 0 and #vampires > 0 then
            net.Start("TTT_VampirePrimeDeath")
            net.WriteUInt(prime_death_mode, 4)
            net.WriteString(victim:Nick())
            net.Broadcast()

            -- Kill them
            if prime_death_mode == VAMPIRE_DEATH_KILL_CONVERTED then
                for _, vnp in pairs(vampires) do
                    vnp:QueueMessage(MSG_PRINTBOTH, "Your " .. ROLE_STRINGS[ROLE_VAMPIRE] .. " overlord has been slain and you die with them")
                    vnp:Kill()
                end
            -- Change them back to their previous roles
            elseif prime_death_mode == VAMPIRE_DEATH_REVERT_CONVERTED then
                local converted = false
                for _, vnp in pairs(vampires) do
                    local prev_role = vnp:GetVampirePreviousRole()
                    if prev_role ~= ROLE_NONE then
                        vnp:QueueMessage(MSG_PRINTBOTH, "Your " .. ROLE_STRINGS[ROLE_VAMPIRE] .. " overlord has been slain and you feel their grip over you subside")
                        vnp:SetRoleAndBroadcast(prev_role)
                        vnp:StripWeapon("weapon_vam_fangs")
                        vnp:SelectWeapon("weapon_zm_improvised")
                        converted = true
                    end
                end

                -- Tell everyone if a role was updated
                if converted then
                    SendFullStateUpdate()
                end
            end
        end
    end
end)

-- If the last vampire prime leaves, randomly choose a new one
hook.Add("PlayerDisconnected", "Vampire_Prime_PlayerDisconnected", function(ply)
    if not ply:IsVampire() then return end
    if not ply:IsVampirePrime() then return end

    local vampires = {}
    for _, v in PlayerIterator() do
        if v:IsActiveVampire() and v ~= ply then
            -- If we already have another prime, we're all set
            if v:IsVampirePrime() then
                return
            end

            table.insert(vampires, v)
        end
    end

    if #vampires == 0 then return end

    local idx = MathRandom(1, #vampires)
    local new_prime = vampires[idx]
    new_prime:SetVampirePrime(true)

    new_prime:QueueMessage(MSG_PRINTBOTH, "The prime " .. ROLE_STRINGS[ROLE_VAMPIRE] .. " has faded away and you've seized power in their absence!")
end)

-- Keep previous naming scheme for backwards compatibility
function plymeta:SetVampirePrime(p) self:SetNWBool("vampire_prime", p) end
function plymeta:SetVampirePreviousRole(r) self:SetNWInt("vampire_previous_role", r) end

-----------------
-- ROLE STATUS --
-----------------

hook.Add("TTTPlayerRoleChanged", "Vampire_RoleFeatures_TTTPlayerRoleChanged", function(ply, oldRole, role)
    if role ~= ROLE_VAMPIRE then return end
    if oldRole ~= ROLE_NONE then return end

    ply:SetVampirePrime(true)
end)

hook.Add("TTTPrepareRound", "Vampire_RoleFeatures_PrepareRound", function()
    for _, v in PlayerIterator() do
        v:SetNWInt("VampireFreezeCount", 0)
        v:SetVampirePrime(false)
        v:SetVampirePreviousRole(ROLE_NONE)
    end
end)

ROLE_MOVE_ROLE_STATE[ROLE_VAMPIRE] = function(ply, target, keep_on_source)
    if ply:IsVampirePrime() then
        if not keep_on_source then ply:SetVampirePrime(false) end
        target:SetVampirePrime(true)
    end
end

----------------
-- WIN CHECKS --
----------------

hook.Add("TTTCheckForWin", "Vampire_TTTCheckForWin", function()
    -- Only run the win check if the vampires win by themselves
    if not INDEPENDENT_ROLES[ROLE_VAMPIRE] then return end

    local vampire_alive = false
    local other_alive = false
    for _, v in PlayerIterator() do
        if v:IsActive() then
            if v:IsVampire() then
                vampire_alive = true
            elseif not v:ShouldActLikeJester() and not ROLE_HAS_PASSIVE_WIN[v:GetRole()] then
                other_alive = true
            end
        end
    end

    if vampire_alive and not other_alive then
        return WIN_VAMPIRE
    elseif vampire_alive then
        return WIN_NONE
    end
end)

hook.Add("TTTPrintResultMessage", "Vampire_TTTPrintResultMessage", function(type)
    if type == WIN_VAMPIRE then
        local plural = ROLE_STRINGS_PLURAL[ROLE_VAMPIRE]
        LANG.Msg("win_vampires", { role = plural })
        ServerLog("Result: " .. plural .. " win.\n")
        return true
    end
end)

-----------
-- KARMA --
-----------

-- Reduce karma if a vampire hurts or kills an ally
hook.Add("TTTKarmaShouldGivePenalty", "Vampire_TTTKarmaShouldGivePenalty", function(attacker, victim)
    if attacker:IsVampire() then
        return victim:IsVampireAlly()
    end
end)

------------
-- DAMAGE --
------------

-- Vampire damage scaling and friendly fire reflecting
hook.Add("ScalePlayerDamage", "Vampire_ScalePlayerDamage", function(ply, hitgroup, dmginfo)
    if GetRoundState() ~= ROUND_ACTIVE then return end

    -- Only run these checks if we're handling damage to a vampire
    if not ply:IsVampire() then return end

    -- Only scale and reflect damage from players
    local att = dmginfo:GetAttacker()
    if not IsPlayer(att) then return end

    -- Don't scale or reflect self damage
    if ply == att then return end

    -- When enabled: If the target is the prime vampire and they are attacked by a non-prime vampire then reflect the damage
    local prime_friendly_fire_mode = vampire_prime_friendly_fire:GetInt()
    if prime_friendly_fire_mode > VAMPIRE_THRALL_FF_MODE_NONE and ply:IsVampirePrime() and att:IsVampire() and not att:IsVampirePrime() then
        local custom_damage = dmginfo:GetDamageCustom()
        -- If this is set, assume that we're the ones that set it and don't check this damage info
        if custom_damage == DMG_AIRBOAT then return end

        -- Copy the original damage info and send it back on the attacker
        if prime_friendly_fire_mode == VAMPIRE_THRALL_FF_MODE_REFLECT then
            local infl = dmginfo:GetInflictor()
            if not IsValid(infl) then
                infl = game.GetWorld()
            end

            local newinfo = DamageInfo()
            -- Set this so that we can check for it since it is not normally used in GMod
            newinfo:SetDamageCustom(DMG_AIRBOAT)
            newinfo:SetDamage(dmginfo:GetDamage())
            newinfo:SetDamageType(dmginfo:GetDamageType())
            newinfo:SetAttacker(att)
            newinfo:SetInflictor(infl)
            newinfo:SetDamageForce(dmginfo:GetDamageForce())
            newinfo:SetDamagePosition(dmginfo:GetDamagePosition())
            newinfo:SetReportedPosition(dmginfo:GetReportedPosition())
            att:TakeDamageInfo(newinfo)
        end

        -- In either case, remove the damage dealt to the prime
        -- This is used by both VAMPIRE_THRALL_FF_MODE_REFLECT and VAMPIRE_THRALL_FF_MODE_IMMUNE
        dmginfo:ScaleDamage(0)
        dmginfo:SetDamage(0)
    -- Otherwise apply damage scaling
    elseif dmginfo:IsBulletDamage() then
        local reduction = vampire_damage_reduction:GetFloat()
        dmginfo:ScaleDamage(1 - reduction)
    end
end)

------------------
-- ROLE WEAPONS --
------------------

-- Make sure the vampire keeps their appropriate weapons
hook.Add("TTTPlayerAliveThink", "Vampire_TTTPlayerAliveThink", function(ply)
    if not IsValid(ply) or ply:IsSpec() or GetRoundState() ~= ROUND_ACTIVE then return end

    if ply:IsVampire() and not ply:HasWeapon("weapon_vam_fangs") then
        ply:Give("weapon_vam_fangs")
    end
end)

-- Handle role weapon assignment
hook.Add("PlayerLoadout", "Vampire_PlayerLoadout", function(ply)
    if not IsPlayer(ply) or not ply:Alive() or ply:IsSpec() or not ply:IsVampire() or GetRoundState() ~= ROUND_ACTIVE then return end

    if not ply:HasWeapon("weapon_vam_fangs") then
        ply:Give("weapon_vam_fangs")
    end
end)

-- Only allow the vampire to pick up vampire-specific weapons
hook.Add("PlayerCanPickupWeapon", "Vampire_Weapons_PlayerCanPickupWeapon", function(ply, wep)
    if not IsValid(wep) or not IsValid(ply) then return end
    if ply:IsSpec() then return end

    if wep:GetClass() == "weapon_vam_fangs" then
        return ply:IsVampire()
    end
end)

-----------------------
-- PLAYER VISIBILITY --
-----------------------

-- Add all players to the PVS for the vampire if highlighting or Kill icon are enabled
hook.Add("SetupPlayerVisibility", "Vampire_SetupPlayerVisibility", function(ply)
    if not ply:ShouldBypassCulling() then return end
    if not ply:IsActiveVampire() then return end
    if not vampire_vision_enabled:GetBool() and not vampire_show_target_icon:GetBool() then return end

    -- Only use this when the vampire would see the highlighting and icons (when they have their fangs out)
    local hasFangs = ply.GetActiveWeapon and IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "weapon_vam_fangs"
    if not hasFangs then return end

    for _, v in PlayerIterator() do
        if ply:TestPVS(v) then continue end

        local pos = v:GetPos()
        if ply:IsOnScreen(pos) then
            AddOriginToPVS(pos)
        end
    end
end)
