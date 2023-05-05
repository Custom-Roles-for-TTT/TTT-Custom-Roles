AddCSLuaFile()

local hook = hook
local ipairs = ipairs
local IsValid = IsValid
local net = net
local pairs = pairs
local timer = timer
local util = util

local GetAllPlayers = player.GetAll

util.AddNetworkString("TTT_BeggarConverted")
util.AddNetworkString("TTT_BeggarKilled")

-------------
-- CONVARS --
-------------

CreateConVar("ttt_beggar_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that the beggar is killed", 0, 4)
CreateConVar("ttt_beggar_notify_sound", "0", FCVAR_NONE, "Whether to play a cheering sound when a beggar is killed", 0, 1)
CreateConVar("ttt_beggar_notify_confetti", "0", FCVAR_NONE, "Whether to throw confetti when a beggar is a killed", 0, 1)
local beggars_are_independent = CreateConVar("ttt_beggars_are_independent", "0", FCVAR_NONE, "Whether beggars should be treated as members of the independent team", 0, 1)
local beggar_reveal_traitor = CreateConVar("ttt_beggar_reveal_traitor", "1", FCVAR_NONE, "Who the beggar is revealed to when they join the traitor team", 0, 3)
local beggar_reveal_innocent = CreateConVar("ttt_beggar_reveal_innocent", "2", FCVAR_NONE, "Who the beggar is revealed to when they join the innocent team", 0, 3)
local beggar_respawn = CreateConVar("ttt_beggar_respawn", "0", FCVAR_NONE, "Whether the beggar respawns when they are killed before joining another team", 0, 1)
local beggar_respawn_limit = CreateConVar("ttt_beggar_respawn_limit", "0", FCVAR_NONE, "The maximum number of times the beggar can respawn (if \"ttt_beggar_respawn\" is enabled). Set to 0 to allow infinite", 0, 30)
local beggar_respawn_delay = CreateConVar("ttt_beggar_respawn_delay", "3", FCVAR_NONE, "The delay to use when respawning the beggar (if \"ttt_beggar_respawn\" is enabled)", 0, 60)
local beggar_respawn_change_role = CreateConVar("ttt_beggar_respawn_change_role", "0", FCVAR_NONE, "Whether to change the role of the respawning the beggar (if \"ttt_beggar_respawn\" is enabled)", 0, 1)
local beggar_traitor_scan = CreateConVar("ttt_beggar_traitor_scan", "0", FCVAR_NONE, "Whether the beggar can scan players to see if they are traitors", 0, 1)
local beggar_traitor_scan_time = CreateConVar("ttt_beggar_traitor_scan_time", "15", FCVAR_NONE, "The amount of time (in seconds) the beggar's scanner takes to use", 0, 60)
local beggar_traitor_scan_float_time = CreateConVar("ttt_beggar_traitor_scan_float_time", "1", FCVAR_NONE, "The amount of time (in seconds) it takes for the beggar's scanner to lose it's target without line of sight", 0, 60)
local beggar_traitor_scan_cooldown = CreateConVar("ttt_beggar_traitor_scan_cooldown", "3", FCVAR_NONE, "The amount of time (in seconds) the beggar's tracker goes on cooldown for after losing it's target", 0, 60)
local beggar_traitor_scan_distance = CreateConVar("ttt_beggar_traitor_scan_distance", "2500", FCVAR_NONE, "The maximum distance away the scanner target can be", 1000, 10000)

hook.Add("TTTSyncGlobals", "Beggar_TTTSyncGlobals", function()
    SetGlobalBool("ttt_beggars_are_independent", beggars_are_independent:GetBool())
    SetGlobalBool("ttt_beggar_respawn", beggar_respawn:GetBool())
    SetGlobalBool("ttt_beggar_traitor_scan", beggar_traitor_scan:GetBool())
    SetGlobalInt("ttt_beggar_respawn_limit", beggar_respawn_limit:GetInt())
    SetGlobalInt("ttt_beggar_respawn_delay", beggar_respawn_delay:GetInt())
    SetGlobalBool("ttt_beggar_respawn_change_role", beggar_respawn_change_role:GetBool())
    SetGlobalInt("ttt_beggar_reveal_traitor", beggar_reveal_traitor:GetInt())
    SetGlobalInt("ttt_beggar_reveal_innocent", beggar_reveal_innocent:GetInt())
    SetGlobalInt("ttt_beggar_traitor_scan_time", beggar_traitor_scan_time:GetInt())
end)

-------------------
-- ROLE TRACKING --
-------------------

hook.Add("WeaponEquip", "Beggar_WeaponEquip", function(wep, ply)
    if not IsValid(wep) or not IsPlayer(ply) then return end
    if not wep.CanBuy or wep.AutoSpawnable then return end

    if not wep.BoughtBy then
        wep.BoughtBy = ply
    elseif ply:IsBeggar() and (wep.BoughtBy:IsTraitorTeam() or wep.BoughtBy:IsInnocentTeam()) then
        local role
        local beggarMode
        if wep.BoughtBy:IsTraitorTeam() then
            role = ROLE_TRAITOR
            beggarMode = beggar_reveal_traitor:GetInt()
        else
            role = ROLE_INNOCENT
            beggarMode = beggar_reveal_innocent:GetInt()
        end

        ply:SetRole(role)
        ply:SetNWBool("WasBeggar", true)
        ply:PrintMessage(HUD_PRINTTALK, "You have joined the " .. ROLE_STRINGS[role] .. " team")
        ply:PrintMessage(HUD_PRINTCENTER, "You have joined the " .. ROLE_STRINGS[role] .. " team")
        timer.Simple(0.5, function() SendFullStateUpdate() end) -- Slight delay to avoid flickering from beggar to the new role and back to beggar

        for _, v in ipairs(GetAllPlayers()) do
            if v ~= ply and (beggarMode == ANNOUNCE_REVEAL_ALL or (v:IsActiveTraitorTeam() and beggarMode == ANNOUNCE_REVEAL_TRAITORS) or (not v:IsActiveTraitorTeam() and beggarMode == ANNOUNCE_REVEAL_INNOCENTS)) then
                v:PrintMessage(HUD_PRINTTALK, "The beggar has joined the " .. ROLE_STRINGS[role] .. " team")
                v:PrintMessage(HUD_PRINTCENTER, "The beggar has joined the " .. ROLE_STRINGS[role] .. " team")
            end
        end

        net.Start("TTT_BeggarConverted")
        net.WriteString(ply:Nick())
        net.WriteString(wep.BoughtBy:Nick())
        net.WriteString(ROLE_STRINGS_EXT[role])
        net.WriteString(ply:SteamID64())
        net.Broadcast()
    end
end)

-- Disable tracking that this player was a beggar at the start of a new round or if their role changes again (e.g. if they go beggar -> innocent -> dead -> hypnotist res to traitor)
hook.Add("TTTPrepareRound", "Beggar_PrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        v:SetNWBool("WasBeggar", false)
        v:SetNWBool("BeggarIsRespawning", false)
        timer.Remove(v:Nick() .. "BeggarRespawn")
    end
end)

hook.Add("TTTPlayerRoleChanged", "Beggar_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if oldRole ~= ROLE_BEGGAR then
        ply:SetNWBool("WasBeggar", false)

        -- Keep track of how many times they have respawned
        if newRole == ROLE_BEGGAR then
            ply.BeggarRespawn = 0
        end
    end
end)

-----------------
-- KILL CHECKS --
-----------------

local function BeggarKilledNotification(attacker, victim)
    JesterTeamKilledNotification(attacker, victim,
        -- getkillstring
        function()
            return attacker:Nick() .. " cruelly killed the lowly " .. ROLE_STRINGS[ROLE_BEGGAR] .. "!"
        end)
end

hook.Add("PlayerDeath", "Beggar_KillCheck_PlayerDeath", function(victim, infl, attacker)
    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    if not valid_kill then return end
    if not victim:IsBeggar() then return end

    BeggarKilledNotification(attacker, victim)

    local respawnLimit = beggar_respawn_limit:GetInt()
    if beggar_respawn:GetBool() and (respawnLimit == 0 or victim.BeggarRespawn < respawnLimit) then
        victim.BeggarRespawn = victim.BeggarRespawn + 1

        local change_role = beggar_respawn_change_role:GetBool()
        local message_extra = ""
        if change_role then
            message_extra = " with a new role"
        end

        local delay = beggar_respawn_delay:GetInt()
        if delay > 0 then
            victim:PrintMessage(HUD_PRINTTALK, "You were killed but will respawn" .. message_extra .. " in " .. delay .. " seconds.")
            victim:PrintMessage(HUD_PRINTCENTER, "You were killed but will respawn" .. message_extra .. " in " .. delay .. " seconds.")
        else
            victim:PrintMessage(HUD_PRINTTALK, "You were killed but are about to respawn" .. message_extra .. ".")
            victim:PrintMessage(HUD_PRINTCENTER, "You were killed but are about to respawn" .. message_extra .. ".")
            -- Introduce a slight delay to prevent player getting stuck as a spectator
            delay = 0.1
        end

        victim:SetNWBool("BeggarIsRespawning", true)

        timer.Create(victim:Nick() .. "BeggarRespawn", delay, 1, function()
            local body = victim.server_ragdoll or victim:GetRagdollEntity()

            if change_role then
                -- Use the opposite role of the person that killed them
                local role = ROLE_INNOCENT
                if attacker:IsInnocentTeam() then
                    role = ROLE_TRAITOR
                end

                victim:SetRoleAndBroadcast(role)
                SendFullStateUpdate()
                SetRoleHealth(victim)
                timer.Simple(0.25, function()
                    victim:SetDefaultCredits()
                end)
            end

            victim:SpawnForRound(true)
            victim:SetHealth(victim:GetMaxHealth())
            SafeRemoveEntity(body)
            victim:SetNWBool("BeggarIsRespawning", false)
        end)

        net.Start("TTT_BeggarKilled")
        net.WriteString(victim:Nick())
        net.WriteString(attacker:Nick())
        net.WriteUInt(delay, 8)
        net.Broadcast()
    end
end)

------------------
-- CUPID LOVERS --
------------------

hook.Add("TTTCupidShouldLoverSurvive", "Beggar_TTTCupidShouldLoverSurvive", function(ply, lover)
    if ply:GetNWBool("BeggarIsRespawning", false) or lover:GetNWBool("BeggarIsRespawning", false) then
        return true
    end
end)

----------------
-- ROLE STATE --
----------------

local function HasBeggar()
    for _, v in ipairs(GetAllPlayers()) do
        if v:IsBeggar() then
            return true
        end
    end
    return false
end

hook.Add("TTTPrepareRound", "Beggar_TTTPrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        v:SetNWInt("TTTBeggarScanStage", BEGGAR_UNSCANNED)
        v:SetNWInt("TTTBeggarScannerState", BEGGAR_SCANNER_IDLE)
        v:SetNWString("TTTBeggarScannerTarget", "")
        v:SetNWString("TTTBeggarScannerMessage", "")
        v:SetNWFloat("TTTBeggarScannerStartTime", -1)
        v:SetNWFloat("TTTBeggarScannerTargetLostTime", -1)
        v:SetNWFloat("TTTBeggarScannerCooldown", -1)
    end
end)

------------------
-- ROLE CHANGES --
------------------

hook.Add("TTTPlayerRoleChanged", "Beggar_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if not beggar_traitor_scan:GetBool() then return end
    if oldRole == newRole then return end
    if GetRoundState() ~= ROUND_ACTIVE then return end

    if oldRole == ROLE_BEGGAR then
        ply:SetNWInt("TTTBeggarScannerState", BEGGAR_SCANNER_IDLE)
        ply:SetNWString("TTTBeggarScannerTarget", "")
        ply:SetNWString("TTTBeggarScannerMessage", "")
        ply:SetNWFloat("TTTBeggarScannerStartTime", -1)
        ply:SetNWFloat("TTTBeggarScannerTargetLostTime", -1)
        ply:SetNWFloat("TTTBeggarScannerCooldown", -1)
    end

    -- Set the default role state if there is an beggar
    local scanStage = ply:GetNWInt("TTTBeggarScanStage", BEGGAR_UNSCANNED)
    if HasBeggar() then
        -- Only notify if there is an beggar and the player had some info being reset
        if scanStage > BEGGAR_UNSCANNED then
            for _, v in pairs(GetAllPlayers()) do
                if v:IsActiveBeggar() then
                    v:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " has changed roles. You will need to rescan them.")
                end
            end
        end
    -- If there is not, make sure this role is set to "unscanned"
    elseif scanStage > BEGGAR_UNSCANNED then
        ply:SetNWInt("TTTBeggarScanStage", BEGGAR_UNSCANNED)
    end
end)

-------------
-- SCANNER --
-------------

local function IsTargetingPlayer(ply)
    if not IsValid(ply) then return false end

    local tr = ply:GetEyeTrace(MASK_SHOT)
    local ent = tr.Entity

    return (IsPlayer(ent) and ent:IsActive()) and ent or false
end

local function TargetLost(ply)
    if not IsValid(ply) then return end

    ply:SetNWInt("TTTBeggarScannerState", BEGGAR_SCANNER_LOST)
    ply:SetNWString("TTTBeggarScannerTarget", "")
    ply:SetNWString("TTTBeggarScannerMessage", "TARGET LOST")
    ply:SetNWFloat("TTTBeggarScannerStartTime", -1)
    ply:SetNWFloat("TTTBeggarScannerCooldown", CurTime())
end

local function InRange(ply, target)
    if not IsValid(ply) or not IsValid(target) then return false end

    if not ply:IsLineOfSightClear(target) then return false end

    local plyPos = ply:GetPos()
    local targetPos = target:GetPos()
    if plyPos:Distance(targetPos) > beggar_traitor_scan_distance:GetInt() then return false end

    return ply:IsOnScreen(target, 0.35)
end

local function ScanAllowed(ply, target)
    if not beggar_traitor_scan:GetBool() then return false end
    if not IsValid(ply) or not IsValid(target) then return false end
    if not IsPlayer(target) then return false end
    if not target:IsActive() then return false end
    return InRange(ply, target)
end

local function Scan(ply, target)
    if not IsValid(ply) or not IsValid(target) then return end

    if target:IsActive() then
        local stage = target:GetNWInt("TTTBeggarScanStage", BEGGAR_UNSCANNED)
        if CurTime() - ply:GetNWFloat("TTTBeggarScannerStartTime", -1) >= beggar_traitor_scan_time:GetInt() then
            stage = BEGGAR_SCANNED_TEAM
            local message = "You have discovered that " .. target:Nick() .. " is "
            if not target:IsTraitorTeam() then
                message = message .. "not "
                stage = BEGGAR_SCANNED_HIDDEN
            end
            message = message .. "a traitor role."

            ply:PrintMessage(HUD_PRINTTALK, message)
            ply:SetNWInt("TTTBeggarScannerState", BEGGAR_SCANNER_IDLE)
            ply:SetNWString("TTTBeggarScannerTarget", "")
            ply:SetNWString("TTTBeggarScannerMessage", "")
            ply:SetNWFloat("TTTBeggarScannerStartTime", -1)
            target:SetNWInt("TTTBeggarScanStage", stage)
            hook.Call("TTTBeggarScanStageChanged", nil, ply, target, stage)
        end
    else
        TargetLost(ply)
    end
end

hook.Add("TTTPlayerAliveThink", "Beggar_TTTPlayerAliveThink", function(ply)
    if not IsValid(ply) or ply:IsSpec() or GetRoundState() ~= ROUND_ACTIVE then return end

    if ply:IsBeggar() then
        local state = ply:GetNWInt("TTTBeggarScannerState", BEGGAR_SCANNER_IDLE)
        if state == BEGGAR_SCANNER_IDLE then
            local target = IsTargetingPlayer(ply)
            if target and target:GetNWInt("TTTBeggarScanStage", BEGGAR_UNSCANNED) < BEGGAR_SCANNED_HIDDEN and ScanAllowed(ply, target) then
                ply:SetNWInt("TTTBeggarScannerState", BEGGAR_SCANNER_LOCKED)
                ply:SetNWString("TTTBeggarScannerTarget", target:SteamID64())
                ply:SetNWString("TTTBeggarScannerMessage", "SCANNING " .. string.upper(target:Nick()))
                ply:SetNWFloat("TTTBeggarScannerStartTime", CurTime())
            end
        elseif state == BEGGAR_SCANNER_LOCKED then
            local target = player.GetBySteamID64(ply:GetNWString("TTTBeggarScannerTarget", ""))
            if target:IsActive() then
                if not InRange(ply, target) then
                    ply:SetNWInt("TTTBeggarScannerState", BEGGAR_SCANNER_SEARCHING)
                    ply:SetNWString("TTTBeggarScannerMessage", "SCANNING " .. string.upper(target:Nick()) .. " (LOSING TARGET)")
                    ply:SetNWFloat("TTTBeggarScannerTargetLostTime", CurTime())
                end
                Scan(ply, target)
            else
                TargetLost(ply)
            end
        elseif state == BEGGAR_SCANNER_SEARCHING then
            local target = player.GetBySteamID64(ply:GetNWString("TTTBeggarScannerTarget", ""))
            if target:IsActive() then
                if (CurTime() - ply:GetNWInt("TTTBeggarScannerTargetLostTime", -1)) >= beggar_traitor_scan_float_time:GetInt() then
                    TargetLost(ply)
                else
                    if InRange(ply, target) then
                        ply:SetNWInt("TTTBeggarScannerState", BEGGAR_SCANNER_LOCKED)
                        ply:SetNWString("TTTBeggarScannerMessage", "SCANNING " .. string.upper(target:Nick()))
                        ply:SetNWFloat("TTTBeggarScannerTargetLostTime", -1)
                    end
                    Scan(ply, target)
                end
            else
                TargetLost(ply)
            end
        elseif state == BEGGAR_SCANNER_LOST then
            if (CurTime() - ply:GetNWFloat("TTTBeggarScannerCooldown", -1)) >= beggar_traitor_scan_cooldown:GetInt() then
                ply:SetNWInt("TTTBeggarScannerState", BEGGAR_SCANNER_IDLE)
                ply:SetNWString("TTTBeggarScannerMessage", "")
                ply:SetNWFloat("TTTBeggarScannerCooldown", -1)
            end
        end
    end
end)