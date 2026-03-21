AddCSLuaFile()

local hook = hook
local player = player

local AddHook = hook.Add
local PlayerIterator = player.Iterator

util.AddNetworkString("TTT_CannibalEaten")

CANNIBAL = {
    playerWeapons = {}
}

-------------
-- CONVARS --
-------------

local cannibal_damage_penalty = CreateConVar("ttt_cannibal_damage_penalty", "0", FCVAR_NONE, "The fraction a Cannibal's damage will be scaled by when they are attacking", 0, 1)
CreateConVar("ttt_cannibal_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that a Cannibal was killed. Killer is notified unless \"ttt_cannibal_notify_killer\" is disabled", 0, 4)
CreateConVar("ttt_cannibal_notify_killer", "1", FCVAR_NONE, "Whether to notify a Cannibal's killer", 0, 1)
CreateConVar("ttt_cannibal_notify_sound", "0", FCVAR_NONE, "Whether to play a cheering sound when a Cannibal is killed", 0, 1)
CreateConVar("ttt_cannibal_notify_confetti", "0", FCVAR_NONE, "Whether to throw confetti when a Cannibal is a killed", 0, 1)

--------------------
-- PLAYER RESPAWN --
--------------------

local function ReleaseEatenPlayers(ply, message)
    local cannibalSID64 = ply:SteamID64()
    for _, v in PlayerIterator() do
        if v.TTTCannibalEaten and v.TTTCannibalEaten == cannibalSID64 then
            -- Set this to prevent the player from getting their loadout back
            v.Resurrecting = true
            v:ClearProperty("TTTCannibalEaten")
            v:SetParent(nil)
            v:SpectateEntity(nil)
            v:UnSpectate()
            v:DrawViewModel(true)
            v:DrawWorldModel(true)
            v:SetNoDraw(false)
            if IsValid(v.hat) then
                v.hat:SetNoDraw(false)
            end
            v:Spawn()
            local pos = ply:GetPos()
            v:SetPos(FindRespawnLocation(pos) or pos)
            v:SetEyeAngles(Angle(0, ply:GetAngles().y, 0))

            local sID64 = v:SteamID64()

            timer.Remove("TTTCannibalDigestion_" .. sID64)

            for _, data in ipairs(CANNIBAL.playerWeapons[sID64]) do
                local wep = v:Give(data.class)
                if not IsValid(wep) then continue end

                if wep.SetClip1 then
                    wep:SetClip1(data.clip1)
                end

                if wep.SetClip2 then
                    wep:SetClip2(data.clip2)
                end

                if TTTPAP and data.PAPUpgrade then
                    TTTPAP:ApplyUpgrade(wep, data.PAPUpgrade)
                end
            end
            CANNIBAL.playerWeapons[sID64] = nil

            v:QueueMessage(MSG_PRINTBOTH, message)
        end
    end
end

local function CannibalKilledNotification(attacker, victim)
    JesterTeamKilledNotification(attacker, victim,
    -- getkillstring
            function()
                return attacker:Nick() .. " gutted the " .. ROLE_STRINGS[ROLE_CANNIBAL] .. "!"
            end)
end

AddHook("PlayerDeath", "Cannibal_PlayerDeath", function(victim, infl, attacker)
    if not IsPlayer(victim) then return end
    if not victim:IsCannibal() then return end

    ReleaseEatenPlayers(victim, victim:Nick() .. " died and you have escaped!")

    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    if not valid_kill then return end

    CannibalKilledNotification(attacker, victim)
end)

AddHook("PlayerDisconnected", "Cannibal_PlayerDisconnected", function(ply)
    if not ply:IsCannibal() then return end

    ReleaseEatenPlayers(ply, ply:Nick() .. " disconnected and you have escaped!")
end)

AddHook("TTTPlayerRoleChanged", "Cannibal_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if not IsPlayer(ply) then return end
    if oldRole ~= ROLE_CANNIBAL or newRole == ROLE_CANNIBAL then return end

    ReleaseEatenPlayers(ply, ply:Nick() .. " lost their appetite and spat you out!")
end)

AddHook("TTTOnRoleAbilityDisabled", "Cannibal_TTTOnRoleAbilityDisabled", function(ply)
    if not IsPlayer(ply) then return end
    if not ply:IsCannibal() then return end

    ReleaseEatenPlayers(ply, ply:Nick() .. " felt unwell and spat you out!")
end)
-------------------------
-- EATEN PLAYER BLOCKS --
-------------------------

AddHook("PlayerCanPickupWeapon", "Cannibal_PlayerCanPickupWeapon", function(ply, wep)
    if not IsValid(ply) then return end

    if ply.TTTCannibalEaten then return false end
end)

local function ShouldBlockCommunications(listener, speaker)
    if not speaker.TTTCannibalEaten then return false end
    if listener.TTTCannibalEaten and listener.TTTCannibalEaten == speaker.TTTCannibalEaten then return false end
    return true
end

AddHook("PlayerCanSeePlayersChat", "Cannibal_PlayerCanSeePlayersChat", function(text, team_only, listener, speaker)
    if not IsPlayer(listener) or not IsPlayer(speaker) then return end

    if ShouldBlockCommunications(listener, speaker) then
        return false
    end
end)

AddHook("PlayerCanHearPlayersVoice", "Cannibal_PlayerCanHearPlayersVoice", function(listener, speaker)
    if not IsPlayer(listener) or not IsPlayer(speaker) then return end

    if ShouldBlockCommunications(listener, speaker) then
        return false, false
    end
end)

------------
-- DAMAGE --
------------

hook.Add("ScalePlayerDamage", "Cannibal_ScalePlayerDamage", function(ply, hitgroup, dmginfo)
    local att = dmginfo:GetAttacker()

    if IsPlayer(att) and GetRoundState() >= ROUND_ACTIVE then
        if att:IsCannibal() then
            local penalty = cannibal_damage_penalty:GetFloat()
            dmginfo:ScaleDamage(1 - penalty)
        end
    end
end)

---------------------
-- MOVE ROLE STATE --
---------------------

ROLE_MOVE_ROLE_STATE[ROLE_CANNIBAL] = function(ply, target, keep_on_source)
    if keep_on_source then return end

    local oldSID64 = ply:SteamID64()
    local newSID64 = target:SteamID64()
    for _, v in PlayerIterator() do
        if v.TTTCannibalEaten and v.TTTCannibalEaten == oldSID64 then
            v:SetProperty("TTTCannibalEaten", newSID64)
            v:SpectateEntity(target)
        end
    end
end

----------------
-- WIN CHECKS --
----------------

AddHook("TTTCheckForWin", "Cannibal_TTTCheckForWin", function()
    local cannibal_alive = false
    local other_alive = false
    for _, v in PlayerIterator() do
        if v:IsActive() then
            if v:IsCannibal() then
                cannibal_alive = true
            elseif not v:ShouldActLikeJester() and not ROLE_HAS_PASSIVE_WIN[v:GetRole()] and not v.TTTCannibalEaten then
                other_alive = true
            end
        end
    end

    if cannibal_alive and not other_alive then
        return WIN_CANNIBAL
    elseif cannibal_alive then
        return WIN_NONE
    end
end)

AddHook("TTTPrintResultMessage", "Cannibal_TTTPrintResultMessage", function(type)
    if type == WIN_CANNIBAL then
        LANG.Msg("win_cannibal", {role = ROLE_STRINGS[ROLE_CANNIBAL]})
        ServerLog("Result: " .. ROLE_STRINGS[ROLE_CANNIBAL] .. " wins.\n")
        return true
    end
end)

-------------
-- CLEANUP --
-------------

AddHook("TTTPrepareRound", "Cannibal_TTTPrepareRound", function()
    for _, v in PlayerIterator() do
        v:ClearProperty("TTTCannibalEaten")
    end
end)

AddHook("TTTEndRound", "Cannibal_TTTEndRound", function()
    table.Empty(CANNIBAL.playerWeapons)
end)