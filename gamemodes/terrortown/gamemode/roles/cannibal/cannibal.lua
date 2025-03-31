AddCSLuaFile()

local hook
local player

local AddHook = hook.Add
local PlayerIterator = player.Iterator

util.AddNetworkString("TTT_CannibalEaten")

CANNIBAL = {
    playerWeapons = {},
    playerCollisionGroups = {}
}

--------------------
-- PLAYER RESPAWN --
--------------------

local function ReleaseEatenPlayers(ply)
    local cannibalSID64 = ply:SteamID64()
    for _, v in PlayerIterator() do
        if v.TTTCannibalEaten and v.TTTCannibalEaten == cannibalSID64 then
            v:ClearProperty("TTTCannibalEaten")
            v:UnSpectate()
            v:DrawViewModel(true)
            v:DrawWorldModel(true)

            local sID64 = v:SteamID64()

            for _, data in ipairs(CANNIBAL.playerWeapons[sID64]) do
                local wep = ply:Give(data.class)
                wep:SetClip1(data.clip1)
                wep:SetClip2(data.clip2)

                if TTTPAP and data.PAPUpgrade and IsValid(wep) then
                    TTTPAP:ApplyUpgrade(wep, data.PAPUpgrade)
                end
            end
            CANNIBAL.playerWeapons[sID64] = nil

            timer.Create("TTTCannibalNoCollide" .. sID64, 0.5, 0, function()
                local nearPlayer = false
                for _, v2 in PlayerIterator() do
                    if v ~= v2 and v:GetPos():DistToSqr(v2:GetPos()) <= 6400 then
                        nearPlayer = true
                        break
                    end
                end
                if not nearPlayer and not (v:GetPhysicsObject() and v:GetPhysicsObject():IsPenetrating()) then
                    v:SetCollisionGroup(CANNIBAL.playerCollisionGroups[sID64])
                    CANNIBAL.playerCollisionGroups[sID64] = nil
                    timer.Destroy("TTTCannibalNoCollide" .. sID64)
                end
            end)
        end
    end
end

AddHook("PlayerDeath", "Cannibal_PlayerDeath", function(victim, infl, attacker)
    if not IsPlayer(victim) then return end
    if not victim:IsCannibal() then return end

    ReleaseEatenPlayers(victim)
end)

AddHook("PlayerDisconnected", "Cannibal_PlayerDisconnected", function(ply)
    if not ply:IsCannibal() then return end

    ReleaseEatenPlayers(ply)
end)

AddHook("TTTPlayerRoleChanged", "Cannibal_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if not IsPlayer(ply) then return end
    if oldRole ~= ROLE_CANNIBAL or newRole == ROLE_CANNIBAL then return end

    ReleaseEatenPlayers(ply)
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

AddHook("PlayerCanSeePlayersChat", "Cannibal_PlayerCanSeePlayersChat_" .. self:EntIndex(), function(text, team_only, listener, speaker)
    if not IsPlayer(listener) or not IsPlayer(speaker) then return end

    if ShouldBlockCommunications(listener, speaker) then
        return false
    end
end)

AddHook("PlayerCanHearPlayersVoice", "Cannibal_PlayerCanHearPlayersVoice_" .. self:EntIndex(), function(listener, speaker)
    if not IsPlayer(listener) or not IsPlayer(speaker) then return end

    if ShouldBlockCommunications(listener, speaker) then
        return false, false
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
        LANG.Msg("win_cannibal", { role = ROLE_STRINGS[ROLE_CANNIBAL] })
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

    for _, v in pairs(CANNIBAL.playerCollisionGroups) do
        local ply = player.GetBySteamID64(v)
        if not IsPlayer(ply) then continue end

        ply:SetCollisionGroup(CANNIBAL.playerCollisionGroups[v])
        CANNIBAL.playerCollisionGroups[v] = nil
        timer.Destroy("TTTCannibalNoCollide" .. v)
    end
end)