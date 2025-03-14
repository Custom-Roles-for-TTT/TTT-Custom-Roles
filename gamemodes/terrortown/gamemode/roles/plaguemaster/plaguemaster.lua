AddCSLuaFile()

local hook = hook
local player = player
local util = util

util.AddNetworkString("TTT_PlaguemasterPlagued")

local AddHook = hook.Add
local PlayerIterator = player.Iterator

-------------
-- CONVARS --
-------------

local plaguemaster_immune = GetConVar("ttt_plaguemaster_immune")
local plaguemaster_plague_length = GetConVar("ttt_plaguemaster_plague_length")
local plaguemaster_spread_distance = GetConVar("ttt_plaguemaster_spread_distance")
local plaguemaster_spread_require_los = GetConVar("ttt_plaguemaster_spread_require_los")
local plaguemaster_spread_time = GetConVar("ttt_plaguemaster_spread_time")
local plaguemaster_warning_time = GetConVar("ttt_plaguemaster_warning_time")
local plaguemaster_dart_replace_timer = GetConVar("ttt_plaguemaster_dart_replace_timer")

------------
-- PLAGUE --
------------

local function SetSpreadStart(ply, source)
    local time = CurTime()
    local sid64 = source:SteamID64()
    ply.TTTPlaguemasterSpreadStartTimes[sid64] = time
    if not ply.TTTPlaguemasterCurrentSource then
        ply.TTTPlaguemasterCurrentSource = sid64
        ply.TTTPlaguemasterOriginalSource = source.TTTPlaguemasterOriginalSource
        ply:SetProperty("TTTPlaguemasterSpreadStart", time, ply)
    end
end

local function ClearSpreadStart(ply, sid64)
    -- Track the spread start from different sources so if one person moves out of range it doesn't reset progress from everyone
    if ply.TTTPlaguemasterSpreadStartTimes[sid64] then
        ply.TTTPlaguemasterSpreadStartTimes[sid64] = nil
    end
    ply.TTTPlaguemasterWarned = false

    -- If this player was the current source, find the next earliest source
    if ply.TTTPlaguemasterCurrentSource == sid64 then
        local earliest = nil
        for src64, t in pairs(ply.TTTPlaguemasterSpreadStartTimes) do
            local source = player.GetBySteamID64(src64)
            if not source then continue end

            if not earliest or earliest.time < t then
                earliest = {
                    source = src64,
                    origSource = source.TTTPlaguemasterOriginalSource,
                    time = t
                }
            end
        end

        -- If there was one, save it
        if earliest then
            ply.TTTPlaguemasterCurrentSource = earliest.source
            ply.TTTPlaguemasterOriginalSource = earliest.origSource
            ply:SetProperty("TTTPlaguemasterSpreadStart", earliest.time, ply)
        -- If not, clear it
        else
            ply.TTTPlaguemasterCurrentSource = nil
            ply.TTTPlaguemasterOriginalSource = nil
            ply:ClearProperty("TTTPlaguemasterSpreadStart", ply)
        end
    end
end

AddHook("TTTPlayerAliveThink", "Plaguemaster_Plague_TTTPlayerAliveThink", function(ply)
    local plague_start = ply.TTTPlaguemasterStartTime
    if not plague_start then return end

    local plague_length = plaguemaster_plague_length:GetInt()
    local warning_time = plaguemaster_warning_time:GetInt()
    local elapsed_time = CurTime() - plague_start
    if elapsed_time >= plague_length then
        ply:SetProperty("TTTPlaguemasterPlagueDeath", true)
        ply:QueueMessage(MSG_PRINTBOTH, "You have succumbed to the plague!")
        ply:Kill()
        return
    elseif not ply.TTTPlaguemasterWarned and warning_time > 0 and (plague_length - elapsed_time) <= warning_time then
        ply.TTTPlaguemasterWarned = true
        ply:QueueMessage(MSG_PRINTBOTH, "The plague is spreading throughout your body, it will kill you soon!")
    end

    -- Check for players within radius and (optionally LOS) to spread the plague
    local spread_time = plaguemaster_spread_time:GetInt()
    local spread_distance = plaguemaster_spread_distance:GetInt()
    local spread_require_los = plaguemaster_spread_require_los:GetBool()
    local sid64 = ply:SteamID64()
    local immune = plaguemaster_immune:GetBool()
    for _, v in PlayerIterator() do
        if v == ply then continue end
        if not v:Alive() or v:IsSpec() then continue end
        -- Don't bother checking players that already have the plague
        if v.TTTPlaguemasterStartTime then continue end
        if v:IsPlaguemaster() and immune then continue end

        if not v.TTTPlaguemasterSpreadStartTimes then
            v.TTTPlaguemasterSpreadStartTimes = {}
        end

        local distance = v:GetPos():Distance(ply:GetPos())
        if distance > spread_distance then
            ClearSpreadStart(v, sid64)
            continue
        end

        if spread_require_los and not ply:IsLineOfSightClear(v) then
            ClearSpreadStart(v, sid64)
            continue
        end

        -- If we haven't started spreading to this target, mark the start time
        if not v.TTTPlaguemasterSpreadStartTimes[sid64] then
            SetSpreadStart(v, ply)

            -- If this is a plaguemaster that hasn't been warned, warn them
            if v:IsPlaguemaster() and not v.TTTPlaguemasterWarned then
                v.TTTPlaguemasterWarned = true
                v:ClearQueuedMessage("plmInfectionWarning")
                v:QueueMessage(MSG_PRINTBOTH, "You are in range of someone with the plague!", 5, "plmInfectionWarning")
            end
        -- If we've been spreading the plague to this target for long enough, give them the plague
        elseif (CurTime() - v.TTTPlaguemasterSpreadStartTimes[sid64]) >= spread_time then
            v:SetProperty("TTTPlaguemasterStartTime", CurTime())
            net.Start("TTT_PlaguemasterPlagued")
                net.WriteString(v:Nick())
                net.WriteString(ply:Nick())
            net.Broadcast()
            -- Also clear their spread list so other players with the plague don't reset their plague state
            ClearSpreadStart(v, sid64)
            v.TTTPlaguemasterSpreadStartTimes = {}
        end
    end
end)

-- Clear the plague from anyone this player is spreading to
AddHook("PostPlayerDeath", "Plaguemaster_PostPlayerDeath", function(ply)
    local plague_start = ply.TTTPlaguemasterStartTime
    if not plague_start then return end

    local sid64 = ply:SteamID64()
    local plague_active = false
    local living_players = 0
    local original_source = ply.TTTPlaguemasterOriginalSource
    for _, v in PlayerIterator() do
        if v == ply then continue end

        -- Keep track if anyone still has the plague started by the original source
        if v:Alive() and not v:IsSpec() then
            living_players = living_players + 1
            if v.TTTPlaguemasterOriginalSource == original_source then
                plague_active = true
            end
        end

        if not v.TTTPlaguemasterSpreadStartTimes then
            v.TTTPlaguemasterSpreadStartTimes = {}
        end

        if v.TTTPlaguemasterSpreadStartTimes[sid64] then
            ClearSpreadStart(v, sid64)
        end
    end

    local dart_replace_timer = plaguemaster_dart_replace_timer:GetInt()
    -- If nobody has the plague and we're set to replace their dart gun, let them know and start the timer
    if living_players > 1 and not plague_active and dart_replace_timer > 0 then
        local source = player.GetBySteamID64(original_source)
        if not IsPlayer(source) then return end

        source:QueueMessage(MSG_PRINTBOTH, "Your plague has died out. You will be given a replacement dart gun in " .. dart_replace_timer .. " seconds.")
        timer.Create("TTTPlaguemasterDartReplace_" .. original_source, dart_replace_timer, 1, function()
            if not IsPlayer(source) then return end

            source:QueueMessage(MSG_PRINTBOTH, "You have been given a replacement dart gun. Choose a new victim and restart your plague.")
            source:Give("weapon_plm_dartgun")
        end)
    end
end)

----------------
-- WIN CHECKS --
----------------

AddHook("TTTCheckForWin", "Plaguemaster_TTTCheckForWin", function()
    local plaguemaster_alive = false
    local other_alive = false
    for _, v in PlayerIterator() do
        if v:IsActive() then
            if v:IsPlaguemaster() then
                plaguemaster_alive = true
            elseif not v:ShouldActLikeJester() and not ROLE_HAS_PASSIVE_WIN[v:GetRole()] then
                other_alive = true
            end
        end
    end

    if plaguemaster_alive and not other_alive then
        return WIN_PLAGUEMASTER
    elseif plaguemaster_alive then
        return WIN_NONE
    end
end)

AddHook("TTTPrintResultMessage", "Plaguemaster_TTTPrintResultMessage", function(type)
    if type == WIN_PLAGUEMASTER then
        LANG.Msg("win_plaguemaster", { role = ROLE_STRINGS[ROLE_PLAGUEMASTER] })
        ServerLog("Result: " .. ROLE_STRINGS[ROLE_PLAGUEMASTER] .. " wins.\n")
        return true
    end
end)

-------------
-- CLEANUP --
-------------

local function ClearPlaguemasterState(ply)
    ply:ClearProperty("TTTPlaguemasterStartTime")
    ply:ClearProperty("TTTPlaguemasterSpreadStart", ply)
    ply:ClearProperty("TTTPlaguemasterPlagueDeath")
    ply.TTTPlaguemasterWarned = false
    ply.TTTPlaguemasterSpreadStartTimes = {}
    ply.TTTPlaguemasterCurrentSource = nil
    ply.TTTPlaguemasterOriginalSource = nil
    timer.Remove("TTTPlaguemasterDartReplace_" .. ply:SteamID64())
end

AddHook("TTTPrepareRound", "Plaguemaster_PrepareRound", function()
    for _, v in PlayerIterator() do
        ClearPlaguemasterState(v)
    end
end)

hook.Add("TTTPlayerSpawnForRound", "Plaguemaster_TTTPlayerSpawnForRound", function(ply, dead_only)
    ClearPlaguemasterState(ply)
end)

----------
-- CURE --
----------

hook.Add("TTTCanPlayerBeCured", "Plaguemaster_TTTCanPlayerBeCured", function(ply)
    if ply.TTTPlaguemasterStartTime then
        return true
    end
end)

hook.Add("TTTCurePlayer", "Plaguemaster_TTTCurePlayer", function(ply)
    if not ply.TTTPlaguemasterStartTime then return end
    ClearPlaguemasterState(ply)
end)