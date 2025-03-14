AddCSLuaFile()

local hook = hook
local player = player
local timer = timer

local PlayerIterator = player.Iterator

-------------
-- CONVARS --
-------------

CreateConVar("ttt_sponge_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that a sponge was killed. Killer is notified unless \"ttt_sponge_notify_killer\" is disabled", 0, 4)
CreateConVar("ttt_sponge_notify_killer", "1", FCVAR_NONE, "Whether to notify a sponge's killer", 0, 1)
CreateConVar("ttt_sponge_notify_sound", "0", FCVAR_NONE, "Whether to play a cheering sound when a sponge is killed", 0, 1)
CreateConVar("ttt_sponge_notify_confetti", "0", FCVAR_NONE, "Whether to throw confetti when a sponge is a killed", 0, 1)
local sponge_aura_float_time = CreateConVar("ttt_sponge_aura_float_time", "0", FCVAR_NONE, "The amount of time (in seconds) a player can spend outside the Sponge's aura before they are no longer considered inside", 0, 10)

local sponge_aura_radius = GetConVar("ttt_sponge_aura_radius")
local sponge_aura_shrink = GetConVar("ttt_sponge_aura_shrink")
local sponge_aura_mode = GetConVar("ttt_sponge_aura_mode")

hook.Add("TTTSyncGlobals", "Sponge_TTTSyncGlobals", function()
    SetGlobalFloat("ttt_sponge_aura_radius", sponge_aura_radius:GetInt() * UNITS_PER_METER)
end)

---------------------
-- DAMAGE TRANSFER --
---------------------

local function ShouldRedirectDamage(sponge, victim, attacker)
    local radius = GetGlobalFloat("ttt_sponge_aura_radius", UNITS_PER_SIX_METERS)

    local auraEndTime = victim:GetNWFloat("SpongeAuraEndTime", -1)
    if victim:GetPos():Distance(sponge:GetPos()) <= radius or (auraEndTime ~= -1 and auraEndTime > CurTime()) then
        if sponge_aura_mode:GetInt() == SPONGE_ALL_PLAYERS then
            local living_players = player.GetLivingInRadius(sponge:GetPos(), radius)
            if #living_players == #util.GetAlivePlayers() then return false end
            return true
        else
            if not IsPlayer(attacker) then return false end
            local attAuraEndTime = attacker:GetNWFloat("SpongeAuraEndTime", -1)
            if attacker:GetPos():Distance(sponge:GetPos()) <= radius or (attAuraEndTime ~= -1 and attAuraEndTime > CurTime()) then return false end
            return true
        end
    end

    return false
end

hook.Add("EntityTakeDamage", "Sponge_EntityTakeDamage", function(target, dmginfo)
    if not IsPlayer(target) then return end
    -- Don't transfer damage done to sponges, even if two sponges are next to each other
    -- This prevents an infinite loop of transferring the damage back and forth
    if target:IsSponge() then return end

    -- Check if this player is within the radius of any living sponge
    for _, p in PlayerIterator() do
        if p == target then continue end
        if not p:Alive() or p:IsSpec() then continue end
        if not p:IsSponge() then continue end

        if not ShouldRedirectDamage(p, target, dmginfo:GetAttacker()) then continue end

        -- Transfer the damage to the sponge instead
        -- But before we do, check if they are going to be killed by it and record that for scoring
        local damage = dmginfo:GetDamage()
        if damage >= p:Health() then
            p:SetNWString("SpongeProtecting", target:Nick())
        end
        p:TakeDamageInfo(dmginfo)
        dmginfo:SetDamage(0)
    end
end)

hook.Add("TTTDrawHitMarker", "Sponge_TTTDrawHitMarker", function(victim, dmginfo)
    if not IsPlayer(victim) then return end
    if victim:IsSponge() then
        return true, false, false, true
    end

    for _, p in PlayerIterator() do
        if p == victim then continue end
        if not p:Alive() or p:IsSpec() then continue end
        if not p:IsSponge() then continue end

        if not ShouldRedirectDamage(p, victim, dmginfo:GetAttacker()) then continue end

        return true, false, false, true
    end
end)

----------
-- AURA --
----------

-- Calculate how much the radius should decrease per player death
local diff_per_death = 0
hook.Add("TTTBeginRound", "Sponge_AuraSize_TTTBeginRound", function()
    if sponge_aura_shrink:GetBool() then
        local radius = GetGlobalFloat("ttt_sponge_aura_radius", UNITS_PER_SIX_METERS)
        local starting_players = #util.GetAlivePlayers()
        diff_per_death = radius / starting_players
    else
        diff_per_death = 0
    end
end)

-- Decrease the aura radius for each player death
local aura_deaths = {}
hook.Add("PostPlayerDeath", "Sponge_AuraSize_PostPlayerDeath", function(ply)
    local radius = GetGlobalFloat("ttt_sponge_aura_radius", UNITS_PER_SIX_METERS)
    SetGlobalFloat("ttt_sponge_aura_radius", radius - diff_per_death)
    aura_deaths[ply:SteamID64()] = true
end)

-- Increase the aura radius for each player who died but then respawned
hook.Add("PlayerSpawn", "Sponge_AuraSize_PlayerSpawn", function(ply, transition)
    if transition or not IsValid(ply) then return end

    local sid64 = ply:SteamID64()
    if not aura_deaths[sid64] then return end

    local radius = GetGlobalFloat("ttt_sponge_aura_radius", UNITS_PER_SIX_METERS)
    SetGlobalFloat("ttt_sponge_aura_radius", radius + diff_per_death)
    aura_deaths[sid64] = false
end)

hook.Add("TTTPrepareRound", "Sponge_AuraSize_PrepareRound", function()
    table.Empty(aura_deaths)
end)

-- Flag a sponge when all living players are within their radius
hook.Add("Think", "Sponge_Aura_Think", function()
    local radius = GetGlobalFloat("ttt_sponge_aura_radius", UNITS_PER_SIX_METERS)
    local alive_players = #util.GetAlivePlayers()
    local floatTime = sponge_aura_float_time:GetInt()
    for _, p in PlayerIterator() do
        if not p:Alive() or p:IsSpec() then continue end
        if not p:IsSponge() then continue end

        local playersInRadius = 1
        for _, v in PlayerIterator() do
            if not p:Alive() or p:IsSpec() then continue end
            if v == p then continue end
            if v:GetPos():Distance(p:GetPos()) <= radius then
                v:SetNWFloat("SpongeAuraEndTime", CurTime() + floatTime)
                playersInRadius = playersInRadius + 1
            else
                local auraEndTime = v:GetNWFloat("SpongeAuraEndTime", -1)
                if auraEndTime ~= -1 and auraEndTime > CurTime() then
                    playersInRadius = playersInRadius + 1
                end
            end
        end

        if sponge_aura_mode:GetInt() == SPONGE_ALL_PLAYERS then
            local all_in_radius = p:GetNWBool("SpongeAllInRadius", false)
            local should_all_in_radius = alive_players == playersInRadius
            if all_in_radius ~= should_all_in_radius then
                p:SetNWBool("SpongeAllInRadius", should_all_in_radius)
            end
        end
    end
end)

-----------------------
-- ROLE INTERACTIONS --
-----------------------

-- The sponge is viewable to everyone so the informant's default scan stage should be "ROLE" since their role is already known
hook.Add("TTTInformantDefaultScanStage", "Sponge_TTTInformantDefaultScanStage", function(ply, oldRole, newRole)
    if ply:IsSponge() then
        return INFORMANT_SCANNED_ROLE
    end
end)

----------------
-- WIN CHECKS --
----------------

local function SpongeKilledNotification(attacker, victim)
    JesterTeamKilledNotification(attacker, victim,
        -- getkillstring
        function()
            return attacker:Nick() .. " was overfilled the damage " .. ROLE_STRINGS[ROLE_SPONGE] .. "!"
        end)
end

hook.Add("PlayerDeath", "Sponge_WinCheck_PlayerDeath", function(victim, infl, attacker)
    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    if not valid_kill then return end

    if victim:IsSponge() then
        SpongeKilledNotification(attacker, victim)
        victim:SetNWString("SpongeKiller", attacker:Nick())

        -- If we're debugging, don't end the round
        if GetConVar("ttt_debug_preventwin"):GetBool() then
            return
        end

        -- Stop the win checks so someone else doesn't steal the sponge's win
        StopWinChecks()
        -- Delay the actual end for a second so the message and sound have a chance to generate a reaction
        timer.Simple(1, function() EndRound(WIN_SPONGE) end)
    end
end)

hook.Add("TTTPrintResultMessage", "Sponge_TTTPrintResultMessage", function(type)
    if type == WIN_SPONGE then
        LANG.Msg("win_sponge", { role = ROLE_STRINGS[ROLE_SPONGE] })
        ServerLog("Result: " .. ROLE_STRINGS[ROLE_SPONGE] .. " wins.\n")
        return true
    end
end)

hook.Add("TTTPrepareRound", "Sponge_PrepareRound", function()
    for _, v in PlayerIterator() do
        v:SetNWString("SpongeKiller", "")
        v:SetNWString("SpongeProtecting", "")
        v:SetNWFloat("SpongeAuraEndTime", -1)
        v:SetNWBool("SpongeAllInRadius", false)
    end
end)