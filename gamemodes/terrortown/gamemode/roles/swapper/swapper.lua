AddCSLuaFile()

local hook = hook
local ipairs = ipairs
local IsValid = IsValid
local net = net
local pairs = pairs
local table = table
local timer = timer
local util = util

local GetAllPlayers = player.GetAll

util.AddNetworkString("TTT_SwapperSwapped")

-------------
-- CONVARS --
-------------

CreateConVar("ttt_swapper_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that the swapper is killed", 0, 4)
CreateConVar("ttt_swapper_notify_sound", "0", FCVAR_NONE, "Whether to play a cheering sound when a swapper is killed", 0, 1)
CreateConVar("ttt_swapper_notify_confetti", "0", FCVAR_NONE, "Whether to throw confetti when a swapper is a killed", 0, 1)
local swapper_killer_max_health = CreateConVar("ttt_swapper_killer_max_health", "0", FCVAR_NONE, "The maximum health value to set on the swapper's killer. Set to \"0\" to kill them", 0, 200)
local swapper_respawn_health = CreateConVar("ttt_swapper_respawn_health", "100", FCVAR_NONE, "What amount of health to give the swapper when they are killed and respawned", 1, 200)
local swapper_weapon_mode = CreateConVar("ttt_swapper_weapon_mode", "1", FCVAR_NONE, "How to handle weapons when the swapper is killed", 0, 2)
local swapper_swap_lovers = CreateConVar("ttt_swapper_swap_lovers", "1", FCVAR_NONE, "Whether the swapper should swap lovers with their attacker or not", 0, 1)

local swapper_killer_health = GetConVar("ttt_swapper_killer_health")

-----------------
-- KILL CHECKS --
-----------------

local function SwapperKilledNotification(attacker, victim)
    JesterTeamKilledNotification(attacker, victim,
        -- getkillstring
        function(ply)
            local target = "someone"
            if ply:IsTraitorTeam() or attacker:IsDetectiveLike() then
                target = ROLE_STRINGS_EXT[attacker:GetRole()] .. " (" .. attacker:Nick() .. ")"
            end
            return "The " .. ROLE_STRINGS[ROLE_SWAPPER] .. " (" .. victim:Nick() .. ") has swapped with " .. target .. "!"
        end)
end

-- Pre-generate all of this information because we need the owner's weapon info even after they've been destroyed due to (temporary) death
local function GetPlayerWeaponInfo(ply)
    local ply_weapons = {}
    for _, w in ipairs(ply:GetWeapons()) do
        local primary_ammo = nil
        local primary_ammo_type = nil
        if w.Primary and w.Primary.Ammo ~= "none" then
            primary_ammo_type = w.Primary.Ammo
            primary_ammo = ply:GetAmmoCount(primary_ammo_type)
        end

        local secondary_ammo = nil
        local secondary_ammo_type = nil
        if w.Secondary and w.Secondary.Ammo ~= "none" and w.Secondary.Ammo ~= primary_ammo_type then
            secondary_ammo_type = w.Secondary.Ammo
            secondary_ammo = ply:GetAmmoCount(secondary_ammo_type)
        end

        table.insert(ply_weapons, {
            class = WEPS.GetClass(w),
            category = w.Category,
            primary_ammo = primary_ammo,
            primary_ammo_type = primary_ammo_type,
            secondary_ammo = secondary_ammo,
            secondary_ammo_type = secondary_ammo_type
        })
    end
    return ply_weapons
end

local function GivePlayerWeaponAndAmmo(ply, weap_info)
    ply:Give(weap_info.class)
    if weap_info.primary_ammo then
        ply:SetAmmo(weap_info.primary_ammo, weap_info.primary_ammo_type)
    end
    if weap_info.secondary_ammo then
        ply:SetAmmo(weap_info.secondary_ammo, weap_info.secondary_ammo_type)
    end
end

local function StripPlayerWeaponAndAmmo(ply, weap_info)
    ply:StripWeapon(weap_info.class)
    if weap_info.primary_ammo then
        ply:SetAmmo(0, weap_info.primary_ammo_type)
    end
    if weap_info.secondary_ammo then
        ply:SetAmmo(0, weap_info.secondary_ammo_type)
    end
end

local function CopyLoverNWVars(copyTo, copyFrom, cupidSID, loverSID)
    local cupid = player.GetBySteamID64(cupidSID)
    local lover = player.GetBySteamID64(loverSID)

    copyTo:SetNWString("TTTCupidShooter", cupidSID)
    copyTo:SetNWString("TTTCupidLover", loverSID)
    if lover and IsPlayer(lover) then
        lover:SetNWString("TTTCupidLover", copyTo:SteamID64())
        lover:QueueMessage(MSG_PRINTBOTH, copyTo:Nick() .. " has swapped with " .. copyFrom:Nick() .. " and is now your lover.")
    end

    if cupid then
        if cupid:GetNWString("TTTCupidTarget1", "") == copyFrom:SteamID64() then
            cupid:SetNWString("TTTCupidTarget1", copyTo:SteamID64())
        else
            cupid:SetNWString("TTTCupidTarget2", copyTo:SteamID64())
        end
        local message = copyTo:Nick() .. " has swapped with " .. copyFrom:Nick() .. " and is now "
        if loverSID == "" then
            message = message .. "waiting to be paired with a lover."
        else
            message = message .. "in love with " .. lover:Nick() .. "."
        end
        cupid:QueueMessage(MSG_PRINTBOTH, message)

        if loverSID == "" then
            message = copyFrom:Nick() .. " had been hit by cupid's arrow so you are now waiting to be paired with a lover."
        else
            message = copyFrom:Nick() .. " was in love so you are now in love with " .. lover:Nick() .. "."
        end
        copyTo:QueueMessage(MSG_PRINTBOTH, message)
    end
end

local function SwapCupidLovers(attacker, swapper)
    local attCupidSID = attacker:GetNWString("TTTCupidShooter", "")
    local attLoverSID = attacker:GetNWString("TTTCupidLover", "")
    local swaCupidSID = swapper:GetNWString("TTTCupidShooter", "")
    local swaLoverSID = swapper:GetNWString("TTTCupidLover", "")
    CopyLoverNWVars(swapper, attacker, attCupidSID, attLoverSID)
    CopyLoverNWVars(attacker, swapper, swaCupidSID, swaLoverSID)
end

hook.Add("PlayerDeath", "Swapper_KillCheck_PlayerDeath", function(victim, infl, attacker)
    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    if not valid_kill then return end
    if not victim:IsSwapper() then return end

    victim:SetNWBool("IsSwapping", true)
    SwapperKilledNotification(attacker, victim)
    attacker:SetNWString("SwappedWith", victim:Nick())

    -- Only bother saving the attacker weapons if we're going to do something with them
    local weapon_mode = swapper_weapon_mode:GetInt()
    local attacker_weapons = nil
    if weapon_mode > SWAPPER_WEAPON_NONE then
        attacker_weapons = GetPlayerWeaponInfo(attacker)
    end
    local victim_weapons = GetPlayerWeaponInfo(victim)

    timer.Simple(0.01, function()
        local body = victim.server_ragdoll or victim:GetRagdollEntity()
        victim:SetRole(attacker:GetRole())
        victim:SpawnForRound(true)
        victim:SetHealth(swapper_respawn_health:GetInt())
        if IsValid(body) then
            victim:SetPos(FindRespawnLocation(body:GetPos()) or body:GetPos())
            victim:SetEyeAngles(Angle(0, body:GetAngles().y, 0))
            body:Remove()
        end

        attacker:MoveRoleState(victim)
        attacker:SetRole(ROLE_SWAPPER)
        SendFullStateUpdate()

        local health = swapper_killer_health:GetInt()
        local attCupidSID = attacker:GetNWString("TTTCupidShooter", "")
        local vicCupidSID = victim:GetNWString("TTTCupidShooter", "")
        if health == 0 then
            if swapper_swap_lovers:GetBool() and attCupidSID ~= "" and vicCupidSID == "" then -- If the attacker is going to die, only swap lovers if the swap doesn't cause a lover to die elsewhere
                SwapCupidLovers(attacker, victim)
            end
            attacker:Kill()
        else
            if swapper_swap_lovers:GetBool() and (attCupidSID ~= "" or vicCupidSID ~= "") and attCupidSID ~= vicCupidSID then -- If the attacker is going to live, only swap lovers if the attacker and the swapper arent in love with each other
                SwapCupidLovers(attacker, victim)
            end
            attacker:SetHealth(health)

            local max_health = swapper_killer_max_health:GetInt()
            if max_health == 0 then
                SetRoleMaxHealth(attacker)
            else
                attacker:SetMaxHealth(max_health)
            end
        end

        victim:SetNWBool("IsSwapping", false)

        timer.Simple(0.2, function()
            if weapon_mode == SWAPPER_WEAPON_ALL then
                -- Strip everything but the sure-thing weapons
                for _, w in ipairs(attacker_weapons) do
                    if w.class ~= "weapon_ttt_unarmed" and w.class ~= "weapon_zm_carry" then
                        StripPlayerWeaponAndAmmo(attacker, w)
                    end
                end

                -- Give the opposite player's weapons back
                for _, w in ipairs(attacker_weapons) do
                    GivePlayerWeaponAndAmmo(victim, w)
                end
                for _, w in ipairs(victim_weapons) do
                    GivePlayerWeaponAndAmmo(attacker, w)
                end
            else
                if weapon_mode == SWAPPER_WEAPON_ROLE then
                    -- Remove all role weapons from the attacker and give them to the victim
                    for _, w in ipairs(attacker_weapons) do
                        if w.category == WEAPON_CATEGORY_ROLE then
                            StripPlayerWeaponAndAmmo(attacker, w)
                            -- Give the attacker a regular crowbar to compensate for the killer crowbar that was removed
                            if w.class == "weapon_kil_crowbar" then
                                attacker:Give("weapon_zm_improvised")
                            end
                            GivePlayerWeaponAndAmmo(victim, w)
                        end
                    end
                end

                -- Give the victim all their weapons back
                for _, w in ipairs(victim_weapons) do
                    GivePlayerWeaponAndAmmo(victim, w)
                end
            end

            -- Have each player select their crowbar to hide role weapons
            attacker:SelectWeapon("weapon_zm_improvised")
            victim:SelectWeapon("weapon_zm_improvised")
        end)
    end)

    net.Start("TTT_SwapperSwapped")
    net.WriteString(victim:Nick())
    net.WriteString(attacker:Nick())
    net.WriteString(victim:SteamID64())
    net.Broadcast()
end)

hook.Add("TTTCupidShouldLoverSurvive", "Swapper_TTTCupidShouldLoverSurvive", function(ply, lover)
    if ply:GetNWBool("IsSwapping", false) or lover:GetNWBool("IsSwapping", false) then
        return true
    end
end)

hook.Add("TTTPrepareRound", "Swapper_PrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        v:SetNWString("SwappedWith", "")
        v:SetNWBool("IsSwapping", false)
    end
end)