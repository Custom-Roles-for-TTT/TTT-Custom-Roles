AddCSLuaFile()

local plymeta = FindMetaTable("Player")

local hook = hook
local ipairs = ipairs
local IsValid = IsValid
local math = math
local net = net
local pairs = pairs
local resource = resource
local table = table
local util = util

local GetAllPlayers = player.GetAll

util.AddNetworkString("TTT_VampirePrimeDeath")

resource.AddSingleFile("sound/weapons/ttt/fade.wav")
resource.AddSingleFile("sound/weapons/ttt/unfade.wav")
resource.AddSingleFile("sound/weapons/ttt/vampireeat.wav")

-------------
-- CONVARS --
-------------

local vampires_are_monsters = CreateConVar("ttt_vampires_are_monsters", "0")
local vampires_are_independent = CreateConVar("ttt_vampires_are_independent", "0")
local vampire_show_target_icon = CreateConVar("ttt_vampire_show_target_icon", "0")
local vampire_damage_reduction = CreateConVar("ttt_vampire_damage_reduction", "0", FCVAR_NONE, "The fraction an attacker's bullet damage will be reduced by when they are shooting a vampire", 0, 1)
local vampire_prime_death_mode = CreateConVar("ttt_vampire_prime_death_mode", "0", FCVAR_NONE, "What to do when the prime vampire(s) (e.g. players who spawn as vampires originally) are killed. 0 - Do nothing. 1 - Kill all vampire thralls (non-prime vampires). 2 - Revert all vampire thralls (non-prime vampires) to their original role", 0, 2)
local vampire_vision_enable = CreateConVar("ttt_vampire_vision_enable", "0")
local vampire_kill_credits = CreateConVar("ttt_vampire_kill_credits", "1")
local vampire_loot_credits = CreateConVar("ttt_vampire_loot_credits", "1")

hook.Add("TTTSyncGlobals", "Vampire_TTTSyncGlobals", function()
    SetGlobalBool("ttt_vampires_are_monsters", vampires_are_monsters:GetBool())
    SetGlobalBool("ttt_vampires_are_independent", vampires_are_independent:GetBool())
    SetGlobalBool("ttt_vampire_show_target_icon", vampire_show_target_icon:GetBool())
    SetGlobalBool("ttt_vampire_vision_enable", vampire_vision_enable:GetBool())
    SetGlobalBool("ttt_vampire_convert_enable", GetConVar("ttt_vampire_convert_enable"):GetBool())
    SetGlobalBool("ttt_vampire_drain_enable", GetConVar("ttt_vampire_drain_enable"):GetBool())
    SetGlobalBool("ttt_vampire_prime_only_convert", GetConVar("ttt_vampire_prime_only_convert"):GetBool())
    SetGlobalBool("ttt_vampire_loot_credits", vampire_loot_credits:GetBool())
    SetGlobalInt("ttt_vampire_prime_death_mode", vampire_prime_death_mode:GetInt())
end)

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
    if kill_credits and valid_attacker and not TRAITOR_ROLES[ROLE_VAMPIRE] and attacker:IsActiveVampire() and (not (victim:IsMonsterTeam() or victim:IsJesterTeam())) and (not GAMEMODE.AwardedVampireCredits or GetConVar("ttt_credits_award_repeat"):GetBool()) then
        local ply_alive = 0
        local ply_dead = 0
        local ply_total = 0

        for _, ply in pairs(GetAllPlayers()) do
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
        ply_total = ply_alive + ply_dead

        -- Only repeat-award if we have reached the pct again since last time
        if GAMEMODE.AwardedVampireCredits then
            ply_dead = ply_dead - GAMEMODE.AwardedVampireCreditsDead
        end

        local pct = ply_dead / ply_total
        if pct >= GetConVar("ttt_credits_award_pct"):GetFloat() then
            -- Traitors have killed sufficient people to get an award
            local amt = GetConVar("ttt_credits_award_size"):GetInt()

            -- If size is 0, awards are off
            if amt > 0 then
                LANG.Msg(GetVampireFilter(true), "credit_all", { role = ROLE_STRINGS[ROLE_VAMPIRE], num = amt })

                for _, ply in pairs(GetAllPlayers()) do
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
        -- Find all the living vampires anmd count the primes
        for _, v in pairs(GetAllPlayers()) do
            if v:Alive() and v:IsTerror() and v:IsVampire() then
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
                    vnp:PrintMessage(HUD_PRINTTALK, "Your " .. ROLE_STRINGS[ROLE_VAMPIRE] .. " overlord has been slain and you die with them")
                    vnp:PrintMessage(HUD_PRINTCENTER, "Your " .. ROLE_STRINGS[ROLE_VAMPIRE] .. " overlord has been slain and you die with them")
                    vnp:Kill()
                end
            -- Change them back to their previous roles
            elseif prime_death_mode == VAMPIRE_DEATH_REVERT_CONVERTED then
                local converted = false
                for _, vnp in pairs(vampires) do
                    local prev_role = vnp:GetVampirePreviousRole()
                    if prev_role ~= ROLE_NONE then
                        vnp:PrintMessage(HUD_PRINTTALK, "Your " .. ROLE_STRINGS[ROLE_VAMPIRE] .. " overlord has been slain and you feel their grip over you subside")
                        vnp:PrintMessage(HUD_PRINTCENTER, "Your " .. ROLE_STRINGS[ROLE_VAMPIRE] .. " overlord has been slain and you feel their grip over you subside")
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

function plymeta:SetVampirePrime(p) self:SetNWBool("vampire_prime", p) end
function plymeta:SetVampirePreviousRole(r) self:SetNWInt("vampire_previous_role", r) end

-----------------
-- ROLE STATUS --
-----------------

hook.Add("TTTBeginRound", "Vampire_RoleFeatures_PrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        if v:IsVampire() then
            v:SetVampirePrime(true)
        end
    end
end)

hook.Add("TTTPrepareRound", "Vampire_RoleFeatures_PrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        v:SetNWInt("VampireFreezeCount", 0)
        -- Keep previous naming scheme for backwards compatibility
        v:SetNWBool("vampire_prime", false)
        v:SetNWInt("vampire_previous_role", ROLE_NONE)
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
    for _, v in ipairs(GetAllPlayers()) do
        if v:Alive() and v:IsTerror() then
            if v:IsVampire() then
                vampire_alive = true
            elseif not v:ShouldActLikeJester() then
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

hook.Add("ScalePlayerDamage", "Vampire_ScalePlayerDamage", function(ply, hitgroup, dmginfo)
    local att = dmginfo:GetAttacker()
    -- Only apply damage scaling after the round starts
    if IsPlayer(att) and GetRoundState() >= ROUND_ACTIVE then
        if dmginfo:IsBulletDamage() and ply:IsVampire() then
            local reduction = vampire_damage_reduction:GetFloat()
            dmginfo:ScaleDamage(1 - reduction)
        end
    end
end)

------------------
-- ROLE WEAPONS --
------------------

-- Make sure the vampire keeps their appropriate weapons
hook.Add("TTTPlayerAliveThink", "Vampire_TTTPlayerAliveThink", function(ply)
    if not IsValid(ply) or ply:IsSpec() or GetRoundState() ~= ROUND_ACTIVE then return end

    if ply:IsVampire() then
        if not ply:HasWeapon("weapon_vam_fangs") then
            ply:Give("weapon_vam_fangs")
        end
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
    if ply:IsSpec() then return false end

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
    if not vampire_vision_enable:GetBool() and not vampire_show_target_icon:GetBool() then return end

    -- Only use this when the vampire would see the highlighting and icons (when they have their fangs out)
    local hasFangs = ply.GetActiveWeapon and IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "weapon_vam_fangs"
    if not hasFangs then return end

    for _, v in ipairs(GetAllPlayers()) do
        if ply:TestPVS(v) then continue end

        local pos = v:GetPos()
        if ply:IsOnScreen(pos) then
            AddOriginToPVS(pos)
        end
    end
end)