AddCSLuaFile()

local hook = hook
local ipairs = ipairs
local player = player

local GetAllPlayers = player.GetAll
local MathRandom = math.random

-------------
-- CONVARS --
-------------

local arsonist_douse_time = CreateConVar("ttt_arsonist_douse_time", "8", FCVAR_NONE, "The amount of time (in seconds) the arsonist takes to douse someone", 0, 60)
local arsonist_douse_distance = CreateConVar("ttt_arsonist_douse_distance", "250", FCVAR_NONE, "The maximum distance away the dousing target can be", 50, 1000)
local arsonist_douse_notify_delay_min = CreateConVar("ttt_arsonist_douse_notify_delay_min", "10", FCVAR_NONE, "The minimum delay before a player is notified they've been doused", 0, 30)
local arsonist_douse_notify_delay_max = CreateConVar("ttt_arsonist_douse_notify_delay_max", "30", FCVAR_NONE, "The delay delay before a player is notified they've been doused", 3, 60)
local arsonist_damage_penalty = CreateConVar("ttt_arsonist_damage_penalty", "0.2", FCVAR_NONE, "Damage penalty that the arsonist has when attacking before igniting everyone (e.g. 0.2 = 20% less damage)", 0, 1)
local arsonist_burn_damage = CreateConVar("ttt_arsonist_burn_damage", "2", FCVAR_NONE, "Damage done per fire tick to players ignited by the arsonist", 1, 10)

hook.Add("TTTSyncGlobals", "Informant_TTTSyncGlobals", function()
    SetGlobalInt("ttt_arsonist_douse_time", arsonist_douse_time:GetInt())
    SetGlobalInt("ttt_arsonist_douse_notify_delay_min", arsonist_douse_notify_delay_min:GetInt())
    SetGlobalInt("ttt_arsonist_douse_notify_delay_max", arsonist_douse_notify_delay_max:GetInt())
end)

--------------------
-- PLAYER DOUSING --
--------------------

local function FindArsonistTarget(arsonist, douse_distance)
    local closest_ply
    local closest_ply_dist = -1
    local doused_count = 0
    local alive_count = 0
    for _, p in ipairs(GetAllPlayers()) do
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
            closest_ply_dist = distance
            closest_ply = p
        end
    end

    if IsPlayer(closest_ply) then
        arsonist:SetNWString("TTTArsonistDouseTarget", closest_ply:SteamID64())
    end

    -- Return whether we've doused all living players (except ourselves)
    return alive_count == doused_count
end

hook.Add("Think", "Arsonist_Douse_Think", function()
    local douse_time = arsonist_douse_time:GetInt()
    local douse_distance = arsonist_douse_distance:GetFloat()
    local douse_notify_delay_min = arsonist_douse_notify_delay_min:GetInt()
    local douse_notify_delay_max = arsonist_douse_notify_delay_max:GetInt()
    if douse_notify_delay_min > douse_notify_delay_max then
        douse_notify_delay_min = douse_notify_delay_max
    end

    -- If the target's distance is 75% of the max distance they should be in the "LOSING" stage
    local losing_distance = douse_distance * 0.75
    for _, p in ipairs(GetAllPlayers()) do
        if not p:IsActiveArsonist() then continue end
        if p:GetNWBool("TTTArsonistDouseComplete", false) then continue end

        local target_sid64 = p:GetNWString("TTTArsonistDouseTarget", "")
        local target = player.GetBySteamID64(target_sid64)
        if not target_sid64 or #target_sid64 == 0 or not IsPlayer(target) then
            local complete = FindArsonistTarget(p, douse_distance)
            if complete then
                p:SetNWBool("TTTArsonistDouseComplete", true)

                local message = "You've doused everyone alive in gasoline. Your igniter is now active!"
                p:PrintMessage(HUD_PRINTCENTER, message)
                p:PrintMessage(HUD_PRINTTALK, message)
            end
            continue
        end

        local distance = target:GetPos():Distance(p:GetPos())
        local stage = target:GetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED)
        local start_time = p:GetNWFloat("TTTArsonistDouseStartTime", -1)
        if distance > douse_distance then
            if stage ~= ARSONIST_DOUSING_LOST then
                target:SetNWInt("TTTArsonistDouseStage", ARSONIST_DOUSING_LOST)
                -- Wait for 1 second after losing before resetting
                p:SetNWFloat("TTTArsonistDouseStartTime", CurTime() + 1)
            else
                -- After the buffer time has passed, reset the variables for both the target and the arsonist
                if CurTime() > start_time then
                    p:SetNWString("TTTArsonistDouseTarget", "")
                    p:SetNWFloat("TTTArsonistDouseStartTime", -1)
                    target:SetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED)
                end
            end
        elseif stage == ARSONIST_DOUSING or stage == ARSONIST_DOUSING_LOSING then
            -- If they are getting too far away, change to "LOSING" stage
            if distance > losing_distance then
                if stage ~= ARSONIST_DOUSING_LOSING then
                    target:SetNWInt("TTTArsonistDouseStage", ARSONIST_DOUSING_LOSING)
                end
            -- Otherwise change them back to "DOUSING"
            elseif stage ~= ARSONIST_DOUSING then
                target:SetNWInt("TTTArsonistDouseStage", ARSONIST_DOUSING)
            end

            -- If we're done dousing, mark the target and reset the arsonist state
            if CurTime() - start_time > douse_time then
                target:SetNWInt("TTTArsonistDouseStage", ARSONIST_DOUSED)
                p:SetNWFloat("TTTArsonistDouseStartTime", -1)
                p:SetNWString("TTTArsonistDouseTarget", "")

                -- Send message (after a random delay) that this player has been doused, but only if it's enabled
                if douse_notify_delay_min > 0 then
                    local delay = MathRandom(douse_notify_delay_min, douse_notify_delay_max)
                    timer.Create("TTTArsonistNotifyDelay_" .. target_sid64, delay, 1, function()
                        if not IsPlayer(target) then return end
                        if not target:Alive() or target:IsSpec() then return end

                        local message = "You have been doused in gasoline by the " .. ROLE_STRINGS[ROLE_ARSONIST] .. "!"
                        target:PrintMessage(HUD_PRINTCENTER, message)
                        target:PrintMessage(HUD_PRINTTALK, message)
                    end)
                end
            end
        -- Otherwise mark them as "dousing" and the start time so the progress bar can show
        elseif stage ~= ARSONIST_DOUSING then
            p:SetNWFloat("TTTArsonistDouseStartTime", CurTime())
            target:SetNWInt("TTTArsonistDouseStage", ARSONIST_DOUSING)
        end
    end
end)

hook.Add("PostPlayerDeath", "Arsonist_PostPlayerDeath", function(ply)
    -- Remove the notification delay timer since the player is already dead
    timer.Remove("TTTArsonistNotifyDelay_" .. ply:SteamID64())
end)

hook.Add("TTTPrepareRound", "Arsonist_TTTPrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        v:SetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED)
        v:SetNWString("TTTArsonistDouseTarget", "")
        v:SetNWFloat("TTTArsonistDouseStartTime", -1)
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
        for _, p in ipairs(GetAllPlayers()) do
            if not p:IsArsonist() then continue end
            -- Don't reset hte flag on a player that already used their igniter
            if not p:HasWeapon("weapon_ars_igniter") then continue end

            if p:GetNWBool("TTTArsonistDouseComplete", false) then
                p:SetNWBool("TTTArsonistDouseComplete", false)

                -- Let the arsonist know they have more work to do
                if p:Alive() and not p:IsSpec() then
                    p:PrintMessage(HUD_PRINTCENTER, message)
                    p:PrintMessage(HUD_PRINTTALK, message)
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
    for _, v in ipairs(GetAllPlayers()) do
        if v:Alive() and v:IsTerror() then
            if v:IsArsonist() then
                arsonist_alive = true
            elseif not v:ShouldActLikeJester() then
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