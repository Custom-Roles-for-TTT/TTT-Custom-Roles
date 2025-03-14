AddCSLuaFile()

local hook = hook
local IsValid = IsValid
local pairs = pairs
local player = player
local table = table
local ents = ents

local PlayerIterator = player.Iterator
local CreateEntity = ents.Create
local FindEntsByClass = ents.FindByClass

-------------
-- CONVARS --
-------------

local medium_seance_float_time = CreateConVar("ttt_medium_seance_float_time", "1", FCVAR_NONE, "The amount of time (in seconds) it takes for the Medium's seance to lose it's target after getting out of range", 0, 60)
local medium_seance_cooldown = CreateConVar("ttt_medium_seance_cooldown", "3", FCVAR_NONE, "The amount of time (in seconds) the Medium's seance goes on cooldown for after losing it's target", 0, 60)
local medium_seance_distance = CreateConVar("ttt_medium_seance_distance", "250", FCVAR_NONE, "The maximum distance away the seance target can be", 50, 1000)

local medium_spirit_color = GetConVar("ttt_medium_spirit_color")
local medium_dead_notify = GetConVar("ttt_medium_dead_notify")
local medium_seance_time = GetConVar("ttt_medium_seance_time")
local medium_seance_max_info = GetConVar("ttt_medium_seance_max_info")
local medium_hide_killer_role = GetConVar("ttt_medium_hide_killer_role")

-------------------
-- ROLE FEATURES --
-------------------

local spirits = {}
hook.Add("TTTPrepareRound", "Medium_Spirits_TTTPrepareRound", function()
    for _, ent in pairs(spirits) do
        SafeRemoveEntity(ent)
    end
    table.Empty(spirits)
end)

hook.Add("PlayerSpawn", "Medium_Spirits_PlayerSpawn", function(ply)
    local sid = ply:SteamID64()
    SafeRemoveEntity(spirits[sid])
    spirits[sid] = nil
end)

hook.Add("PlayerDisconnected", "Medium_Spirits_PlayerDisconnected", function(ply)
    local sid = ply:SteamID64()
    SafeRemoveEntity(spirits[sid])
    spirits[sid] = nil
end)

hook.Add("FinishMove", "Medium_Spirits_FinishMove", function(ply, mv)
    if not IsValid(ply) or not ply:IsSpec() then return end

    local spirit = spirits[ply:SteamID64()]
    if not IsValid(spirit) then return end

    spirit:SetPos(ply:GetPos())

    local show = ply:GetObserverMode() == OBS_MODE_ROAMING
    spirit:SetNWBool("MediumSpirit", show)
end)

hook.Add("PlayerDeath", "Medium_Spirits_PlayerDeath", function(victim, infl, attacker)
    -- Create spirit for the medium
    local mediumCount = 0
    for _, v in PlayerIterator() do
        if v:IsMedium() then
            mediumCount = mediumCount + 1
        end
    end

    -- If there is a medium or a medium can spawn we want to create the spirits
    if mediumCount > 0 or util.CanRoleSpawn(ROLE_MEDIUM) then
        local spirit = CreateEntity("npc_kleiner")
        spirit:SetPos(victim:GetPos())
        spirit:SetRenderMode(RENDERMODE_NONE)
        spirit:SetNotSolid(true)
        spirit:DrawShadow(false)
        spirit:SetNWBool("MediumSpirit", false)
        spirit:AddFlags(FL_NOTARGET)
        local col = Vector(1, 1, 1)
        if medium_spirit_color:GetBool() then
            col = victim:GetNWVector("PlayerColor", Vector(1, 1, 1))
        end
        spirit:SetNWVector("SpiritColor", col)
        spirit:SetNWString("SpiritOwner", victim:SteamID64())
        spirit:Spawn()
        spirits[victim:SteamID64()] = spirit

        -- If there is a medium in the round, let the player who died know there is a medium as long as this player isn't the only medium and they are not respawning
        if medium_dead_notify:GetBool() and mediumCount > 0 and (mediumCount > 1 or not victim:IsMedium()) and not victim:IsRespawning() then
            victim:QueueMessage(MSG_PRINTBOTH, "The " .. ROLE_STRINGS[ROLE_MEDIUM] .. " senses your spirit.")
        end

        -- Reset the Medium's scans on this player if they were killed then revived and killed again
        victim:SetNWInt("TTTMediumSeanceStage", MEDIUM_SCANNED_NONE)
    end
end)

-- Hide the role of the player that killed the victim if there is a medium in the round and that feature is enabled
hook.Add("TTTDeathNotifyOverride", "Medium_TTTDeathNotifyOverride", function(victim, inflictor, attacker, reason, killerName, role)
    if GetRoundState() ~= ROUND_ACTIVE then return end
    if not IsPlayer(attacker) then return end
    if victim == attacker then return end
    if not medium_hide_killer_role:GetBool() then return end

    local medium = false
    for _, p in PlayerIterator() do
        if p:IsMedium() then
            medium = true
            break
        end
    end

    if not medium then return end

    return reason, killerName, ROLE_NONE
end)

-------------
-- SCANNER --
-------------

hook.Add("TTTPrepareRound", "Medium_TTTPrepareRound", function()
    for _, v in PlayerIterator() do
        v:SetNWInt("TTTMediumSeanceStage", MEDIUM_SCANNED_NONE)
        v:SetNWInt("TTTMediumSeanceState", MEDIUM_SEANCE_IDLE)
        v:SetNWString("TTTMediumSeanceTarget", "")
        v:SetNWString("TTTMediumSeanceMessage", "")
        v:SetNWFloat("TTTMediumSeanceStartTime", -1)
        v:SetNWFloat("TTTMediumSeanceTargetLostTime", -1)
        v:SetNWFloat("TTTMediumSeanceCooldown", -1)
    end
end)

local function FindSeanceTarget(medium)
    local closest_player
    local closest_dist = -1
    for _, ent in ipairs(FindEntsByClass("npc_kleiner")) do
        if not ent:GetNWBool("MediumSpirit", false) then continue end

        local sid64 = ent:GetNWString("SpiritOwner", "")
        local ply = player.GetBySteamID64(sid64)
        if not IsPlayer(ply) then continue end

        if ply:IsActive() then continue end

        if ply:GetNWInt("TTTMediumSeanceStage") >= medium_seance_max_info:GetInt() then continue end

        local distance = ent:GetPos():Distance(medium:GetPos())
        if distance < medium_seance_distance:GetInt() and (closest_dist == -1 or distance < closest_dist) then
            closest_dist = distance
            closest_player = ply
        end
    end

    return closest_player
end

local function TargetLost(ply)
    if not IsValid(ply) then return end

    ply:SetNWInt("TTTMediumSeanceState", MEDIUM_SEANCE_LOST)
    ply:SetNWString("TTTMediumSeanceTarget", "")
    ply:SetNWString("TTTMediumSeanceMessage", "TARGET LOST")
    ply:SetNWFloat("TTTMediumSeanceStartTime", -1)
    ply:SetNWFloat("TTTMediumSeanceCooldown", CurTime())
end

local function InRange(ply, target)
    if not IsValid(ply) or not IsValid(target) then return false end

    if not target:GetNWBool("MediumSpirit", false) then return false end

    local plyPos = ply:GetPos()
    local targetPos = target:GetPos()
    if plyPos:Distance(targetPos) > medium_seance_distance:GetInt() then return false end

    return true
end

local function RoleKnown(target)
    if target:GetNWBool("body_searched_det", false) then return true end
    if target:GetNWBool("body_searched", false) then
        if not GetConVar("ttt_detectives_search_only"):GetBool() then return true end
        if not GetConVar("ttt_detectives_search_only_role"):GetBool() and not GetConVar("ttt_detectives_search_only_nick"):GetBool() then return true end
    end
    return false
end

local function TeamKnown(target)
    if target:GetNWBool("body_searched_det", false) then return true end
    if target:GetNWBool("body_searched", false) then
        if not GetConVar("ttt_detectives_search_only"):GetBool() then return true end
        if not GetConVar("ttt_detectives_search_only_team"):GetBool() and not GetConVar("ttt_detectives_search_only_nick"):GetBool() then return true end
    end
    return false
end

local function Scan(ply, target)
    if not IsPlayer(ply) or not IsPlayer(target) then return end

    local stage = target:GetNWInt("TTTMediumSeanceStage", MEDIUM_SCANNED_NONE)
    local seance_max_info = medium_seance_max_info:GetInt()
    if target:IsActive() or stage >= seance_max_info then
        TargetLost(ply)
    else
        if CurTime() - ply:GetNWFloat("TTTMediumSeanceStartTime", -1) >= medium_seance_time:GetInt() then
            stage = stage + 1
            if stage == MEDIUM_SCANNED_NAME then
                if seance_max_info > MEDIUM_SCANNED_NAME then
                    local state = ply:GetNWInt("TTTMediumSeanceState", MEDIUM_SEANCE_IDLE)
                    if state == MEDIUM_SEANCE_LOCKED then
                        ply:SetNWString("TTTMediumSeanceMessage", "SCANNING " .. string.upper(target:Nick()))
                    elseif state == MEDIUM_SEANCE_SEARCHING then
                        ply:SetNWString("TTTMediumSeanceMessage", "SCANNING " .. string.upper(target:Nick()) .. " (LOSING TARGET)")
                    end
                end
                ply:QueueMessage(MSG_PRINTBOTH, "You have learned that this spirit belongs to " .. target:Nick())
                if RoleKnown(target) then
                    stage = MEDIUM_SCANNED_ROLE
                    ply:QueueMessage(MSG_PRINTBOTH, "Their body has already been searched so you know their role.")
                elseif TeamKnown(target) then
                    stage = MEDIUM_SCANNED_TEAM
                    ply:QueueMessage(MSG_PRINTBOTH, "Their body has already been searched by someone else so you know their team.")
                else
                    -- This message is only relevant if they haven't already been searched
                    LANG.Msg("medium_reveal_name", {
                        medium = ply:Nick(),
                        spirit = target:Nick()
                    })
                end
            elseif stage == MEDIUM_SCANNED_TEAM then
                local teamMsg = ""
                if target:IsTraitorTeam() then teamMsg = "a traitor"
                elseif target:IsDetectiveTeam() then teamMsg = "a detective"
                elseif target:IsInnocentTeam() then teamMsg = "an innocent"
                elseif target:IsIndependentTeam() then teamMsg = "an independent"
                elseif target:IsJesterTeam() then teamMsg = "a jester"
                elseif target:IsMonsterTeam() then teamMsg = "a monster" end
                ply:QueueMessage(MSG_PRINTBOTH, "You have learned that " .. target:Nick() .. " was " .. teamMsg .. " role.")
                LANG.Msg("medium_reveal_role", {
                    medium = ply:Nick(),
                    spirit = target:Nick(),
                    role = teamMsg .. " role"
                })
            elseif stage == MEDIUM_SCANNED_ROLE then
                ply:QueueMessage(MSG_PRINTBOTH, "You have learned that " .. target:Nick() .. " was " .. ROLE_STRINGS_EXT[target:GetRole()] .. ".")
                LANG.Msg("medium_reveal_role", {
                    medium = ply:Nick(),
                    spirit = target:Nick(),
                    role = ROLE_STRINGS_EXT[target:GetRole()]
                })
            end

            if stage >= seance_max_info then
                ply:SetNWInt("TTTMediumSeanceState", MEDIUM_SEANCE_IDLE)
                ply:SetNWString("TTTMediumSeanceTarget", "")
                ply:SetNWString("TTTMediumSeanceMessage", "")
                ply:SetNWFloat("TTTMediumSeanceStartTime", -1)
            else
                ply:SetNWFloat("TTTMediumSeanceStartTime", CurTime())
            end
            target:SetNWInt("TTTMediumSeanceStage", stage)
            hook.Call("TTTMediumScanStageChanged", nil, ply, target, stage)
        end
    end
end

hook.Add("TTTPlayerAliveThink", "Medium_TTTPlayerAliveThink", function(ply)
    if not ply:IsActiveMedium() then return end

    local seance_max_info = medium_seance_max_info:GetInt()
    if seance_max_info == MEDIUM_SCANNED_NONE then return end

    local state = ply:GetNWInt("TTTMediumSeanceState", MEDIUM_SEANCE_IDLE)
    if state == MEDIUM_SEANCE_IDLE then
        local target = FindSeanceTarget(ply)
        if target then
            local stage = target:GetNWInt("TTTMediumSeanceStage", MEDIUM_SCANNED_NONE)

            if stage < seance_max_info then
                ply:SetNWInt("TTTMediumSeanceState", MEDIUM_SEANCE_LOCKED)
                ply:SetNWString("TTTMediumSeanceTarget", target:SteamID64())
                ply:SetNWFloat("TTTMediumSeanceStartTime", CurTime())
                if stage >= MEDIUM_SCANNED_NAME then
                    ply:SetNWString("TTTMediumSeanceMessage", "SCANNING " .. string.upper(target:Nick()))
                else
                    ply:SetNWString("TTTMediumSeanceMessage", "SCANNING UNKNOWN SPIRIT")
                end
            end
        end
    elseif state == MEDIUM_SEANCE_LOCKED then
        local sid64 = ply:GetNWString("TTTMediumSeanceTarget", "")
        local targetPlayer = player.GetBySteamID64(sid64)
        local targetSpirit = spirits[sid64]
        if not targetPlayer:IsActive() then
            if not InRange(ply, targetSpirit) then
                ply:SetNWInt("TTTMediumSeanceState", MEDIUM_SEANCE_SEARCHING)
                ply:SetNWFloat("TTTMediumSeanceTargetLostTime", CurTime())
                if targetPlayer:GetNWInt("TTTMediumSeanceStage", MEDIUM_SCANNED_NONE) >= MEDIUM_SCANNED_NAME then
                    ply:SetNWString("TTTMediumSeanceMessage", "SCANNING " .. string.upper(targetPlayer:Nick()) .. " (LOSING TARGET)")
                else
                    ply:SetNWString("TTTMediumSeanceMessage", "SCANNING UNKNOWN SPIRIT (LOSING TARGET)")
                end
            end
            Scan(ply, targetPlayer)
        else
            TargetLost(ply)
        end
    elseif state == MEDIUM_SEANCE_SEARCHING then
        local sid64 = ply:GetNWString("TTTMediumSeanceTarget", "")
        local targetPlayer = player.GetBySteamID64(sid64)
        local targetSpirit = spirits[sid64]
        if not targetPlayer:IsActive() then
            if (CurTime() - ply:GetNWInt("TTTMediumSeanceTargetLostTime", -1)) >= medium_seance_float_time:GetInt() then
                TargetLost(ply)
            else
                if InRange(ply, targetSpirit) then
                    ply:SetNWInt("TTTMediumSeanceState", MEDIUM_SEANCE_LOCKED)
                    ply:SetNWFloat("TTTMediumSeanceTargetLostTime", -1)
                    if targetPlayer:GetNWInt("TTTMediumSeanceStage", MEDIUM_SCANNED_NONE) >= MEDIUM_SCANNED_NAME then
                        ply:SetNWString("TTTMediumSeanceMessage", "SCANNING " .. string.upper(targetPlayer:Nick()))
                    else
                        ply:SetNWString("TTTMediumSeanceMessage", "SCANNING UNKNOWN SPIRIT")
                    end
                end
                Scan(ply, targetPlayer)
            end
        else
            TargetLost(ply)
        end
    elseif state == MEDIUM_SEANCE_LOST then
        if (CurTime() - ply:GetNWFloat("TTTMediumSeanceCooldown", -1)) >= medium_seance_cooldown:GetInt() then
            ply:SetNWInt("TTTMediumSeanceState", MEDIUM_SEANCE_IDLE)
            ply:SetNWString("TTTMediumSeanceMessage", "")
            ply:SetNWFloat("TTTMediumSeanceCooldown", -1)
        end
    end
end)

hook.Add("TTTBodyFound", "Medium_TTTBodyFound", function(_, deadply, _)
    if not IsPlayer(deadply) then return end
    local stage = deadply:GetNWInt("TTTMediumSeanceStage", MEDIUM_SCANNED_NONE)
    if stage >= MEDIUM_SCANNED_NAME then
        timer.Simple(0, function() -- Delay until the next frame so the body search logic can fully run before checking this
            if RoleKnown(deadply) and stage < MEDIUM_SCANNED_ROLE then
                deadply:SetNWInt("TTTMediumSeanceStage", MEDIUM_SCANNED_ROLE)
            elseif TeamKnown(deadply) and stage < MEDIUM_SCANNED_TEAM then
                deadply:SetNWInt("TTTMediumSeanceStage", MEDIUM_SCANNED_TEAM)
            end
        end)
    end
end)