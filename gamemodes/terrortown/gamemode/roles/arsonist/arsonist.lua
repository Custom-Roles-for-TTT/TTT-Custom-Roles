AddCSLuaFile()

local ents = ents
local hook = hook
local ipairs = ipairs
local math = math
local player = player

local FindEntsByClass = ents.FindByClass
local PlayerIterator = player.Iterator
local MathRandom = math.random

-------------
-- CONVARS --
-------------

local arsonist_douse_float_time = CreateConVar("ttt_arsonist_douse_float_time", "3", FCVAR_NONE, "The amount of time (in seconds) it takes for the arsonist to lose their target after getting out of range", 0, 60)
local arsonist_douse_cooldown = CreateConVar("ttt_arsonist_douse_cooldown", "3", FCVAR_NONE, "The amount of time (in seconds) the arsonist's douse goes on cooldown for after they lose their target", 0, 60)
local arsonist_douse_require_los = CreateConVar("ttt_arsonist_douse_require_los", "1")
local arsonist_douse_distance = CreateConVar("ttt_arsonist_douse_distance", "250", FCVAR_NONE, "The maximum distance away the dousing target can be", 50, 1000)
local arsonist_damage_penalty = CreateConVar("ttt_arsonist_damage_penalty", "0.2", FCVAR_NONE, "Damage penalty that the arsonist has when attacking before igniting everyone (e.g. 0.2 = 20% less damage)", 0, 1)
local arsonist_burn_damage = CreateConVar("ttt_arsonist_burn_damage", "2", FCVAR_NONE, "Damage done per fire tick to players ignited by the arsonist", 1, 10)

local arsonist_douse_time = GetConVar("ttt_arsonist_douse_time")
local arsonist_douse_notify_delay_min = GetConVar("ttt_arsonist_douse_notify_delay_min")
local arsonist_douse_notify_delay_max = GetConVar("ttt_arsonist_douse_notify_delay_max")
local arsonist_douse_corpses = GetConVar("ttt_arsonist_douse_corpses")

--------------------
-- PLAYER DOUSING --
--------------------

local function FindArsonistTarget(arsonist, douse_distance)
    local closest_ply
    local closest_ply_dist = -1
    local doused_count = 0
    local alive_count = 0
    local douse_require_los = arsonist_douse_require_los:GetBool()
    for _, p in PlayerIterator() do
        if p == arsonist then continue end
        if not p:Alive() or p:IsSpec() then continue end

        alive_count = alive_count + 1
        local douse_stage = p:GetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED)
        if douse_stage == ARSONIST_DOUSED then
            doused_count = doused_count + 1
        end
        if douse_stage ~= ARSONIST_UNDOUSED then continue end

        local distance = p:GetPos():Distance(arsonist:GetPos())
        if distance < douse_distance and (closest_ply_dist == -1 or distance < closest_ply_dist) then
            if douse_require_los and not arsonist:IsLineOfSightClear(p) then continue end
            closest_ply_dist = distance
            closest_ply = p
        end
    end

    -- If we didn't find a player, find the closest ragdoll belonging to a dead player instead
    if not IsPlayer(closest_ply) and arsonist_douse_corpses:GetBool() then
        for _, rag in ipairs(FindEntsByClass("prop_ragdoll")) do
            if rag:GetNWBool("TTTArsonistDoused", false) then continue end

            local p = CORPSE.GetPlayer(rag)
            if p == arsonist then continue end
            if not IsPlayer(p) or p:Alive() or not p:IsSpec() then continue end

            local douse_stage = p:GetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED)
            if douse_stage ~= ARSONIST_UNDOUSED then continue end

            local distance = rag:GetPos():Distance(arsonist:GetPos())
            if distance < douse_distance and (closest_ply_dist == -1 or distance < closest_ply_dist) then
                if douse_require_los and not arsonist:IsLineOfSightClear(rag) then continue end
                closest_ply_dist = distance
                closest_ply = p
            end
        end
    end

    if IsPlayer(closest_ply) then
        arsonist:SetNWString("TTTArsonistDouseTarget", closest_ply:SteamID64())
    end

    -- Return whether we've doused all living players (except ourselves)
    return alive_count == doused_count
end

local arsonist_early_ignite
hook.Add("Think", "Arsonist_Douse_Think", function()
    -- Make sure we have this cached when it's available
    if not arsonist_early_ignite then
        arsonist_early_ignite = GetConVar("ttt_arsonist_early_ignite")
    end
    local early_ignite = arsonist_early_ignite and arsonist_early_ignite:GetBool() or false
    local douse_time = arsonist_douse_time:GetInt()
    local douse_distance = arsonist_douse_distance:GetFloat()
    local douse_notify_delay_min = arsonist_douse_notify_delay_min:GetInt()
    local douse_notify_delay_max = arsonist_douse_notify_delay_max:GetInt()
    local douse_float_time = arsonist_douse_float_time:GetInt()
    local douse_cooldown = arsonist_douse_cooldown:GetInt()
    local douse_require_los = arsonist_douse_require_los:GetBool()
    if douse_notify_delay_min > douse_notify_delay_max then
        douse_notify_delay_min = douse_notify_delay_max
    end

    for _, p in PlayerIterator() do
        if not p:IsActiveArsonist() then continue end
        if p:GetNWBool("TTTArsonistDouseComplete", false) then continue end

        local target_sid64 = p:GetNWString("TTTArsonistDouseTarget", "")
        local target = player.GetBySteamID64(target_sid64)
        if not target_sid64 or #target_sid64 == 0 or not IsPlayer(target) then
            local complete = FindArsonistTarget(p, douse_distance)
            if complete then
                p:SetNWBool("TTTArsonistDouseComplete", true)

                local message = "You've doused everyone alive in gasoline."
                if not early_ignite then
                    message = message .. " Your igniter is now active!"
                end
                p:QueueMessage(MSG_PRINTBOTH, message)
            end
            continue
        end

        local stage = target:GetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED)
        local start_time = p:GetNWFloat("TTTArsonistDouseStartTime", -1)

        local target_pos = target:GetPos()
        local target_dead = not target:Alive() or target:IsSpec()
        local target_rag = nil
        local los_ent = target
        -- If the target is dead, use their ragdoll instead
        if target_dead then
            if arsonist_douse_corpses:GetBool() then
                target_rag = target.server_ragdoll or target:GetRagdollEntity()
                if not IsValid(target_rag) then continue end

                target_pos = target_rag:GetPos()
                los_ent = target_rag
            else
                if stage ~= ARSONIST_DOUSING_LOST and douse_cooldown > 0 then
                    target:SetNWInt("TTTArsonistDouseStage", ARSONIST_DOUSING_LOST)
                    -- Wait for the cooldown after losing before resetting
                    p:SetNWFloat("TTTArsonistDouseStartTime", CurTime() + douse_cooldown)
                elseif CurTime() > start_time or douse_cooldown == 0 then
                    -- After the buffer time has passed, reset the variables for both the target and the arsonist
                    p:SetNWString("TTTArsonistDouseTarget", "")
                    p:SetNWFloat("TTTArsonistDouseStartTime", -1)
                    target:SetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED)
                end
                continue
            end
        end

        local distance = target_pos:Distance(p:GetPos())
        if stage == ARSONIST_UNDOUSED then
            p:SetNWFloat("TTTArsonistDouseStartTime", CurTime())
            target:SetNWInt("TTTArsonistDouseStage", ARSONIST_DOUSING)
        elseif stage == ARSONIST_DOUSING then
            if distance > douse_distance or (douse_require_los and not p:IsLineOfSightClear(los_ent)) then
                target:SetNWInt("TTTArsonistDouseStage", ARSONIST_DOUSING_LOSING)
                p:SetNWFloat("TTTArsonistDouseLostTime", CurTime() + douse_float_time)
            end
        elseif stage == ARSONIST_DOUSING_LOSING then
            if CurTime() > p:GetNWFloat("TTTArsonistDouseLostTime", -1) then
                if douse_cooldown > 0 then
                    target:SetNWInt("TTTArsonistDouseStage", ARSONIST_DOUSING_LOST)
                    -- Wait for the cooldown after losing before resetting
                    p:SetNWFloat("TTTArsonistDouseStartTime", CurTime() + douse_cooldown)
                else
                    p:SetNWString("TTTArsonistDouseTarget", "")
                    p:SetNWFloat("TTTArsonistDouseStartTime", -1)
                    target:SetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED)
                end
            else
                if distance <= douse_distance and (not douse_require_los or p:IsLineOfSightClear(los_ent)) then
                    target:SetNWInt("TTTArsonistDouseStage", ARSONIST_DOUSING)
                    p:SetNWFloat("TTTArsonistDouseLostTime", -1)
                end
            end
        elseif stage == ARSONIST_DOUSING_LOST then
            if CurTime() > start_time then
                p:SetNWString("TTTArsonistDouseTarget", "")
                p:SetNWFloat("TTTArsonistDouseStartTime", -1)
                target:SetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED)
            end
        end

        if stage == ARSONIST_DOUSING or stage == ARSONIST_DOUSING_LOSING then
            -- If we're done dousing, mark the target and reset the arsonist state
            if CurTime() - start_time > douse_time then
                target:SetNWInt("TTTArsonistDouseStage", ARSONIST_DOUSED)
                target:SetNWInt("TTTArsonistDouseTime", CurTime())
                if IsValid(target_rag) then
                    target_rag:SetNWBool("TTTArsonistDoused", true)
                end
                p:SetNWFloat("TTTArsonistDouseStartTime", -1)
                p:SetNWString("TTTArsonistDouseTarget", "")

                -- Send message (after a random delay) that this player has been doused, but only if it's enabled
                if douse_notify_delay_min > 0 then
                    local delay = MathRandom(douse_notify_delay_min, douse_notify_delay_max)
                    timer.Create("TTTArsonistNotifyDelay_" .. target_sid64, delay, 1, function()
                        if not IsPlayer(target) then return end
                        if not target:Alive() or target:IsSpec() then return end

                        local message = ""
                        if target_dead then
                            message = message .. "Your corpse has "
                        else
                            message = message .. "You have "
                        end
                        message = message .. "been doused in gasoline by the " .. ROLE_STRINGS[ROLE_ARSONIST] .. "!"
                        target:QueueMessage(MSG_PRINTBOTH, message)
                    end)
                end
            end
        end
    end
end)

hook.Add("PostPlayerDeath", "Arsonist_PostPlayerDeath", function(ply)
    -- Remove the notification delay timer since the player is already dead
    timer.Remove("TTTArsonistNotifyDelay_" .. ply:SteamID64())

    -- Clear any ignite info the igniter may have left around
    if not ply.ignite_info then return end
    if not IsPlayer(ply.ignite_info.att) then return end
    if not ply.ignite_info.att:IsArsonist() then return end

    ply.ignite_info = nil
end)

hook.Add("TTTPrepareRound", "Arsonist_TTTPrepareRound", function()
    for _, v in PlayerIterator() do
        v:SetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED)
        v:SetNWInt("TTTArsonistDouseTime", -1)
        v:SetNWString("TTTArsonistDouseTarget", "")
        v:SetNWFloat("TTTArsonistDouseStartTime", -1)
        v:SetNWFloat("TTTArsonistDouseLostTime", -1)
        v:SetNWBool("TTTArsonistDouseComplete", false)
        timer.Remove("TTTArsonistNotifyDelay_" .. v:SteamID64())
    end
end)

hook.Add("TTTPlayerSpawnForRound", "Arsonist_TTTPlayerSpawnForRound", function(ply, dead_only)
    if dead_only and ply:Alive() and not ply:IsSpec() then return end

    -- Player is respawning that has not been doused
    if ply:GetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED) == ARSONIST_UNDOUSED then
        local message = "You've detected a new target player! Douse them in gasoline!"
        -- Reset any arsonist who has been flagged as "complete"
        for _, p in PlayerIterator() do
            if not p:IsArsonist() then continue end
            -- Don't reset the flag on a player that already used their igniter
            if not p:HasWeapon("weapon_ars_igniter") then continue end

            if p:GetNWBool("TTTArsonistDouseComplete", false) then
                p:SetNWBool("TTTArsonistDouseComplete", false)

                -- Let the arsonist know they have more work to do
                if p:IsActive() then
                    p:QueueMessage(MSG_PRINTBOTH, message)
                end
            end
        end
    end
end)

hook.Add("ScalePlayerDamage", "Arsonist_ScalePlayerDamage", function(ply, hitgroup, dmginfo)
    -- Only apply damage scaling after the round starts
    if GetRoundState() < ROUND_ACTIVE then return end

    local att = dmginfo:GetAttacker()
    if not IsPlayer(att) or not att:IsArsonist() then return end

    -- Scale the player's damage down if they haven't ignited everyone
    if not att:GetNWBool("TTTArsonistDouseComplete", false) then
        dmginfo:ScaleDamage(1 - arsonist_damage_penalty:GetFloat())
    end
end)

hook.Add("EntityTakeDamage", "Arsonist_EntityTakeDamage", function(ent, dmginfo)
    if not IsPlayer(ent) then return end

    -- Make sure the player is on fire and being damaged by fire
    if not ent:IsOnFire() then return end
    if not dmginfo:IsDamageType(DMG_BURN) then return end
    local att = dmginfo:GetAttacker()
    if not IsValid(att) then return end
    if att:GetClass() ~= "entityflame" then return end

    -- Make sure the person responsible for the damage is an arsonist
    if not ent.ignite_info then return end
    if not IsPlayer(ent.ignite_info.att) then return end
    if not ent.ignite_info.att:IsArsonist() then return end

    -- If this player was doused, set the person responsible and set the damage
    if ent:GetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED) == ARSONIST_DOUSED then
        dmginfo:SetAttacker(ent.ignite_info.att)
        dmginfo:SetInflictor(ent.ignite_info.infl)
        dmginfo:SetDamage(arsonist_burn_damage:GetInt())
    end
end)

----------------
-- WIN CHECKS --
----------------

hook.Add("TTTCheckForWin", "Arsonist_TTTCheckForWin", function()
    local arsonist_alive = false
    local other_alive = false
    for _, v in PlayerIterator() do
        if v:IsActive() then
            if v:IsArsonist() then
                arsonist_alive = true
            elseif not v:ShouldActLikeJester() and not ROLE_HAS_PASSIVE_WIN[v:GetRole()] then
                other_alive = true
            end
        end
    end

    if arsonist_alive and not other_alive then
        return WIN_ARSONIST
    elseif arsonist_alive then
        return WIN_NONE
    end
end)

hook.Add("TTTPrintResultMessage", "Arsonist_TTTPrintResultMessage", function(type)
    if type == WIN_ARSONIST then
        LANG.Msg("win_arsonist", { role = ROLE_STRINGS[ROLE_ARSONIST] })
        ServerLog("Result: " .. ROLE_STRINGS[ROLE_ARSONIST] .. " wins.\n")
        return true
    end
end)