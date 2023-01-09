AddCSLuaFile()

local hook = hook
local pairs = pairs
local player = player
local timer = timer

local GetAllPlayers = player.GetAll

resource.AddFile("materials/particle/heart.vmt")

-------------
-- CONVARS --
-------------

CreateConVar("ttt_cupid_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that a cupid was killed", 0, 4)
CreateConVar("ttt_cupid_notify_sound", "0", FCVAR_NONE, "Whether to play a cheering sound when a cupid is killed", 0, 1)
CreateConVar("ttt_cupid_notify_confetti", "0", FCVAR_NONE, "Whether to throw confetti when a cupid is a killed", 0, 1)
CreateConVar("ttt_cupid_lovers_notify_mode", "1", FCVAR_NONE, "Who is notified with cupid makes two players fall in love", 0, 3)
local cupids_are_independent = CreateConVar("ttt_cupids_are_independent", "0", FCVAR_NONE, "Whether cupids should be treated as members of the independent team", 0, 1)
local cupid_can_damage_lovers = CreateConVar("ttt_cupid_can_damage_lovers", "0", FCVAR_NONE, "Whether cupid should be able to damage the lovers", 0, 1)
local cupid_lovers_can_damage_lovers = CreateConVar("ttt_cupid_lovers_can_damage_lovers", "1", FCVAR_NONE, "Whether the lovers should be able to damage each other", 0, 1)
local cupid_lovers_can_damage_cupid = CreateConVar("ttt_cupid_lovers_can_damage_cupid", "0", FCVAR_NONE, "Whether the lovers should be able to damage cupid", 0, 1)
local cupid_lover_vision_enable = CreateConVar("ttt_cupid_lover_vision_enable", "1", FCVAR_NONE, "Whether the lovers can see outlines of each other through walls", 0, 1)

hook.Add("TTTSyncGlobals", "Cupid_TTTSyncGlobals", function()
    SetGlobalBool("ttt_cupids_are_independent", cupids_are_independent:GetBool())
    SetGlobalBool("ttt_cupid_lover_vision_enable", cupid_lover_vision_enable:GetBool())
end)

----------------
-- DEATH LINK --
----------------

hook.Add("TTTBeginRound", "Cupid_TTTBeginRound", function()
    timer.Create("TTTCupidTimer", 0.1, 0, function()
        for _, v in pairs(GetAllPlayers()) do
            local lover = v:GetNWString("TTTCupidLover", "")
            if lover ~= "" then
                if v:IsActive() and not player.GetBySteamID64(lover):IsActive() then
                    v:Kill()
                    v:PrintMessage(HUD_PRINTCENTER, "Your lover has died!")
                    v:PrintMessage(HUD_PRINTTALK, "Your lover has died!")
                end
            end
        end
    end)
end)


-------------
-- CLEANUP --
-------------

hook.Add("TTTPrepareRound", "Cupid_TTTPrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        v:SetNWString("TTTCupidShooter", "")
        v:SetNWString("TTTCupidLover", "")
        v:SetNWString("TTTCupidTarget1", "")
        v:SetNWString("TTTCupidTarget2", "")
    end
end)

------------
-- DAMAGE --
------------

hook.Add("ScalePlayerDamage", "Cupid_ScalePlayerDamage", function(ply, hitgroup, dmginfo)
    local att = dmginfo:GetAttacker()
    local target = ply:SteamID64()
    if IsPlayer(att) and GetRoundState() >= ROUND_ACTIVE then
        if (att:IsCupid() and (att:GetNWString("TTTCupidTarget1", "") == target or att:GetNWString("TTTCupidTarget2", "") == target) and not cupid_can_damage_lovers:GetBool())
                or (att:GetNWString("TTTCupidLover", "") == target and not cupid_lovers_can_damage_lovers:GetBool())
                or (att:GetNWString("TTTCupidShooter", "") == target and not cupid_lovers_can_damage_cupid:GetBool()) then
            dmginfo:ScaleDamage(0)
        end
    end
end)

--------------------------
-- DISCONNECTION CHECKS --
--------------------------

hook.Add("PlayerDisconnected", "Cupid_PlayerDisconnected", function(ply)
    local sid64 = ply:SteamID64()

    for _, p in pairs(GetAllPlayers()) do
        if p:GetNWString("TTTCupidLover", "") == sid64 then
            p:PrintMessage(HUD_PRINTCENTER, "Your lover has disappeared ;_;")
            p:PrintMessage(HUD_PRINTTALK, "Your lover has disappeared ;_;")
            p:SetNWString("TTTCupidLover", "")
        elseif p:GetNWString("TTTCupidTarget1", "") == sid64 then
            p:PrintMessage(HUD_PRINTCENTER, "A player hit by your arrow has disconnected")
            p:PrintMessage(HUD_PRINTTALK, "A player hit by your arrow has disconnected")
            local target2 = p:GetNWString("TTTCupidTarget2", "")
            if target2 == "" then
                p:SetNWString("TTTCupidTarget1", "")
            else
                p:SetNWString("TTTCupidTarget1", target2)
                p:SetNWString("TTTCupidTarget2", "")
                p:Give("weapon_cup_bow")
            end
        elseif p:GetNWString("TTTCupidTarget2", "") == sid64 then
            p:PrintMessage(HUD_PRINTCENTER, "A player hit by your arrow has disconnected")
            p:PrintMessage(HUD_PRINTTALK, "A player hit by your arrow has disconnected")
            p:SetNWString("TTTCupidTarget2", "")
            p:Give("weapon_cup_bow")
        end
    end
end)

---------------------------------
-- PLAYER DEATH DURING PAIRING --
---------------------------------

hook.Add("PlayerDeath", "Cupid_PlayerDeath", function(ply)
    local sid64 = ply:SteamID64()

    for _, p in pairs(GetAllPlayers()) do
        if p:GetNWString("TTTCupidTarget1", "") == sid64 and p:GetNWString("TTTCupidTarget2", "") == "" then
            p:PrintMessage(HUD_PRINTCENTER, "The player hit by your arrow has died")
            p:PrintMessage(HUD_PRINTTALK, "The player hit by your arrow has died")
            p:SetNWString("TTTCupidTarget1", "")
            ply:SetNWString("TTTCupidShooter", "")
        end
    end
end)

----------------
-- WIN CHECKS --
----------------

hook.Add("TTTCheckForWin", "Cupid_TTTCheckForWin", function(victim, infl, attacker)
    local cupidWin = true
    local playerAlive = false
    for _, v in pairs(GetAllPlayers()) do
        if v:Alive() and v:IsTerror() then
            if not v:IsCupid() then
                playerAlive = true
            end

            local lover = v:GetNWString("TTTCupidLover", "")
            if lover ~= "" then
                local loverPly = player.GetBySteamID64(lover)
                if not IsPlayer(loverPly) or not loverPly:Alive() or not loverPly:IsTerror() then
                    cupidWin = false
                    break
                end
            elseif not v:IsCupid() then
                cupidWin = false
                break
            end
        end
    end

    if cupidWin and playerAlive then
        return WIN_CUPID
    end
end)

hook.Add("TTTPrintResultMessage", "Cupid_TTTPrintResultMessage", function(type)
    if type == WIN_CUPID then
        LANG.Msg("win_lovers", { role = ROLE_STRINGS_PLURAL[ROLE_CUPID] })
        ServerLog("Result: " .. ROLE_STRINGS[ROLE_CUPID] .. " wins.\n")
        return true
    end
end)