AddCSLuaFile()

local hook = hook
local player = player
local timer = timer

local AddHook = hook.Add
local RemoveHook = hook.Remove
local PlayerIterator = player.Iterator
local HookCall = hook.Call

-------------
-- CONVARS --
-------------

CreateConVar("ttt_cupid_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that a cupid was killed. Killer is notified unless \"ttt_cupid_notify_killer\" is disabled", 0, 4)
CreateConVar("ttt_cupid_notify_killer", "1", FCVAR_NONE, "Whether to notify a cupid's killer", 0, 1)
CreateConVar("ttt_cupid_notify_sound", "0", FCVAR_NONE, "Whether to play a cheering sound when a cupid is killed", 0, 1)
CreateConVar("ttt_cupid_notify_confetti", "0", FCVAR_NONE, "Whether to throw confetti when a cupid is a killed", 0, 1)

local cupid_can_damage_lovers = GetConVar("ttt_cupid_can_damage_lovers")
local cupid_lovers_can_damage_lovers = GetConVar("ttt_cupid_lovers_can_damage_lovers")
local cupid_lovers_can_damage_cupid = GetConVar("ttt_cupid_lovers_can_damage_cupid")

----------------
-- DEATH LINK --
----------------

local function Cupid_TTTBeginRound()
    timer.Create("TTTCupidTimer", 0.1, 0, function()
        for _, v in PlayerIterator() do
            if not v:IsActive() then continue end

            local lover_sid64 = v:GetNWString("TTTCupidLover", "")
            if #lover_sid64 == 0 then continue end

            local lover = player.GetBySteamID64(lover_sid64)
            if not IsPlayer(lover) or lover:IsActive() then continue end
            -- Don't kill a lover if their pair used a "kill" bind
            if lover.TTTCupidKillbindUsed then continue end

            local should_survive = HookCall("TTTCupidShouldLoverSurvive", nil, v, lover)
            if type(should_survive) == "boolean" and should_survive then continue end

            v:Kill()
            v:QueueMessage(MSG_PRINTBOTH, "Your lover has died!")
        end
    end)
end

-- Keep track if a lover uses a "kill" bind so we don't punish their pair
local function Cupid_Killbind_PlayerDeath(victim, infl, attacker)
    if not IsPlayer(victim) then return end

    local lover_sid64 = victim:GetNWString("TTTCupidLover", "")
    if #lover_sid64 == 0 then return end

    -- If the victim and the inflictor and the attacker are all the same thing then they probably used the "kill" console command
    if victim == attacker and IsValid(infl) and victim == infl then
        local lover = player.GetBySteamID64(lover_sid64)
        if lover and IsPlayer(lover) and lover:Alive() then
            victim.TTTCupidKillbindUsed = true
            lover:QueueMessage(MSG_PRINTBOTH, "Your lover has died by their own hand! Try to survive without them...")
        end
    end
end

-------------
-- CLEANUP --
-------------

AddHook("TTTPrepareRound", "Cupid_TTTPrepareRound", function()
    for _, v in PlayerIterator() do
        v:SetNWString("TTTCupidShooter", "")
        v:SetNWString("TTTCupidLover", "")
        v:SetNWString("TTTCupidTarget1", "")
        v:SetNWString("TTTCupidTarget2", "")
        v.TTTCupidKillbindUsed = false
    end
    timer.Remove("TTTCupidTimer")
end)

-- Reset the "kill" bind tracking when players respawn
local function Cupid_TTTPlayerSpawnForRound(ply, dead_only)
    if not dead_only then return end
    if not IsValid(ply) then return end
    if ply:Alive() then return end

    ply.TTTCupidKillbindUsed = false
end

------------
-- DAMAGE --
------------

local function Cupid_ScalePlayerDamage(ply, hitgroup, dmginfo)
    local att = dmginfo:GetAttacker()
    local target = ply:SteamID64()
    if IsPlayer(att) and GetRoundState() == ROUND_ACTIVE then
        if (att:IsCupid() and (att:GetNWString("TTTCupidTarget1", "") == target or att:GetNWString("TTTCupidTarget2", "") == target) and not cupid_can_damage_lovers:GetBool())
                or (att:GetNWString("TTTCupidLover", "") == target and not cupid_lovers_can_damage_lovers:GetBool())
                or (att:GetNWString("TTTCupidShooter", "") == target and not cupid_lovers_can_damage_cupid:GetBool()) then
            dmginfo:ScaleDamage(0)
        end
    end
end

-- Don't penalize karma for lovers who kill members on their team when their lover is not
local function Cupid_TTTKarmaShouldGivePenalty(attacker, victim)
    -- We only care about attackers who have lovers
    local attLover = attacker:GetNWString("TTTCupidLover", "")
    if not attLover or #attLover == 0 then return end

    -- Specifically lovers that are alive
    local lover = player.GetBySteamID64(attLover)
    if not lover or not IsPlayer(lover) then return end

    -- If the attacker and their lover are on the same team then just let normal karma rules work
    if not attacker:IsSameTeam(lover) then return end

    -- Otherwise, if the attacker and their victim are on the same team, block karma penalties
    if attacker:IsSameTeam(victim) then
        return true
    end
end

--------------------------
-- DISCONNECTION CHECKS --
--------------------------

local function Cupid_PlayerDisconnected(ply)
    local sid64 = ply:SteamID64()

    for _, p in PlayerIterator() do
        if p:GetNWString("TTTCupidLover", "") == sid64 then
            p:QueueMessage(MSG_PRINTBOTH, "Your lover has disappeared ;_;")
            p:SetNWString("TTTCupidLover", "")
        elseif p:GetNWString("TTTCupidTarget1", "") == sid64 then
            p:QueueMessage(MSG_PRINTBOTH, "A player hit by your arrow has disconnected")

            local target2Sid64 = p:GetNWString("TTTCupidTarget2", "")
            local target2 = player.GetBySteamID64(target2Sid64)
            -- Make sure the other lover is still alive
            if not target2 or not target2:Alive() or target2:IsSpec() then continue end

            if #target2Sid64 == 0 then
                p:SetNWString("TTTCupidTarget1", "")
            else
                p:SetNWString("TTTCupidTarget1", target2Sid64)
                p:SetNWString("TTTCupidTarget2", "")
                p:Give("weapon_cup_bow")
            end
        elseif p:GetNWString("TTTCupidTarget2", "") == sid64 then
            p:QueueMessage(MSG_PRINTBOTH, "A player hit by your arrow has disconnected")

            local target1Sid64 = p:GetNWString("TTTCupidTarget1", "")
            local target1 = player.GetBySteamID64(target1Sid64)
            -- Make sure the other lover is still alive
            if not target1 or not target1:Alive() or target1:IsSpec() then continue end

            p:SetNWString("TTTCupidTarget2", "")
            p:Give("weapon_cup_bow")
        end
    end
end

---------------------------------
-- PLAYER DEATH DURING PAIRING --
---------------------------------

local function Cupid_PlayerDeath(ply)
    local sid64 = ply:SteamID64()

    for _, p in PlayerIterator() do
        local target2 = p:GetNWString("TTTCupidTarget2", "")
        if p:GetNWString("TTTCupidTarget1", "") == sid64 and #target2 == 0 then
            p:QueueMessage(MSG_PRINTBOTH, "The player hit by your arrow has died")
            p:SetNWString("TTTCupidTarget1", "")
            ply:SetNWString("TTTCupidShooter", "")
        end
    end
end

----------------
-- WIN CHECKS --
----------------

local function Cupid_TTTCheckForWin()
    local cupidWin = true
    local loverAlive = false
    for _, v in PlayerIterator() do
        if not v:Alive() or v:IsSpec() then
            continue
        end

        local lover = v:GetNWString("TTTCupidLover", "")
        if #lover > 0 then
            local loverPly = player.GetBySteamID64(lover)
            if not IsPlayer(loverPly) or not loverPly:IsActive() then
                cupidWin = false
                break
            end
            loverAlive = true
        elseif not v:IsCupid() and not v:ShouldActLikeJester() and not ROLE_HAS_PASSIVE_WIN[v:GetRole()] then
            cupidWin = false
            break
        end
    end

    if cupidWin and loverAlive then
        return WIN_CUPID
    end
end

local function Cupid_TTTPrintResultMessage(win_type)
    if win_type == WIN_CUPID then
        LANG.Msg("win_lovers", { role = ROLE_STRINGS_PLURAL[ROLE_CUPID] })
        ServerLog("Result: " .. ROLE_STRINGS[ROLE_CUPID] .. " wins.\n")
        return true
    end
end

------------------
-- REGISTRATION --
------------------

ROLE_REGISTER_HOOKS[ROLE_CUPID] = function()
    AddHook("PlayerDeath", "Cupid_Killbind_PlayerDeath", Cupid_Killbind_PlayerDeath)
    AddHook("PlayerDeath", "Cupid_PlayerDeath", Cupid_PlayerDeath)
    AddHook("PlayerDisconnected", "Cupid_PlayerDisconnected", Cupid_PlayerDisconnected)
    AddHook("ScalePlayerDamage", "Cupid_ScalePlayerDamage", Cupid_ScalePlayerDamage)
    AddHook("TTTBeginRound", "Cupid_TTTBeginRound", Cupid_TTTBeginRound)
    AddHook("TTTCheckForWin", "Cupid_TTTCheckForWin", Cupid_TTTCheckForWin)
    AddHook("TTTKarmaShouldGivePenalty", "Cupid_TTTKarmaShouldGivePenalty", Cupid_TTTKarmaShouldGivePenalty)
    AddHook("TTTPlayerSpawnForRound", "Cupid_TTTPlayerSpawnForRound", Cupid_TTTPlayerSpawnForRound)
    AddHook("TTTPrintResultMessage", "Cupid_TTTPrintResultMessage", Cupid_TTTPrintResultMessage)
end

ROLE_UNREGISTER_HOOKS[ROLE_CUPID] = function()
    RemoveHook("PlayerDeath", "Cupid_Killbind_PlayerDeath")
    RemoveHook("PlayerDeath", "Cupid_PlayerDeath")
    RemoveHook("PlayerDisconnected", "Cupid_PlayerDisconnected")
    RemoveHook("ScalePlayerDamage", "Cupid_ScalePlayerDamage")
    RemoveHook("TTTBeginRound", "Cupid_TTTBeginRound")
    RemoveHook("TTTCheckForWin", "Cupid_TTTCheckForWin")
    RemoveHook("TTTKarmaShouldGivePenalty", "Cupid_TTTKarmaShouldGivePenalty")
    RemoveHook("TTTPlayerSpawnForRound", "Cupid_TTTPlayerSpawnForRound")
    RemoveHook("TTTPrintResultMessage", "Cupid_TTTPrintResultMessage")
end