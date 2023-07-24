AddCSLuaFile()

local hook = hook
local IsValid = IsValid
local pairs = pairs

local GetAllPlayers = player.GetAll

-------------
-- CONVARS --
-------------

local informant_share_scans = CreateConVar("ttt_informant_share_scans", "1")
local informant_can_scan_jesters = CreateConVar("ttt_informant_can_scan_jesters", "0")
local informant_can_scan_glitches = CreateConVar("ttt_informant_can_scan_glitches", "0")
local informant_requires_scanner = CreateConVar("ttt_informant_requires_scanner", "0")
local informant_scanner_time = CreateConVar("ttt_informant_scanner_time", "8", FCVAR_NONE, "The amount of time (in seconds) the informant's scanner takes to use", 0, 60)
local informant_scanner_float_time = CreateConVar("ttt_informant_scanner_float_time", "1", FCVAR_NONE, "The amount of time (in seconds) it takes for the informant's scanner to lose it's target without line of sight", 0, 60)
local informant_scanner_cooldown = CreateConVar("ttt_informant_scanner_cooldown", "3", FCVAR_NONE, "The amount of time (in seconds) the informant's tracker goes on cooldown for after losing it's target", 0, 60)
local informant_scanner_distance = CreateConVar("ttt_informant_scanner_distance", "2500", FCVAR_NONE, "The maximum distance away the scanner target can be", 1000, 10000)

hook.Add("TTTSyncGlobals", "Informant_TTTSyncGlobals", function()
    SetGlobalBool("ttt_informant_share_scans", informant_share_scans:GetBool())
    SetGlobalBool("ttt_informant_can_scan_jesters", informant_can_scan_jesters:GetBool())
    SetGlobalBool("ttt_informant_can_scan_glitches", informant_can_scan_glitches:GetBool())
    SetGlobalBool("ttt_informant_requires_scanner", informant_requires_scanner:GetBool())
    SetGlobalInt("ttt_informant_scanner_time", informant_scanner_time:GetInt())
end)

------------------
-- ROLE WEAPONS --
------------------

-- Only allow the informant to pick up informant-specific weapons
hook.Add("PlayerCanPickupWeapon", "Informant_Weapons_PlayerCanPickupWeapon", function(ply, wep)
    if not IsValid(wep) or not IsValid(ply) then return end
    if ply:IsSpec() then return false end

    if wep:GetClass() == "weapon_inf_scanner" then
        return ply:IsInformant()
    end
end)

----------------
-- ROLE STATE --
----------------

local function HasInformant()
    for _, v in ipairs(GetAllPlayers()) do
        if v:IsInformant() then
            return true
        end
    end
    return false
end

local function ShouldHideRoleForTraitors(ply, oldRole, newRole)
    -- If this was a beggar or bodysnatcher and we're not revealing it to traitors, hide their role
    if (oldRole == ROLE_BEGGAR and ply:GetNWBool("WasBeggar")) or (oldRole == ROLE_BODYSNATCHER and ply:GetNWBool("WasBodysnatcher")) then
        local role_team = player.GetRoleTeam(newRole, true)
        local convar_team = GetRawRoleTeamName(role_team)
        local reveal_traitor = GetGlobalInt("ttt_" .. ROLE_STRINGS_RAW[oldRole] .. "_reveal_" .. convar_team, ANNOUNCE_REVEAL_ALL)
        return reveal_traitor ~= ANNOUNCE_REVEAL_ALL and reveal_traitor ~= ANNOUNCE_REVEAL_TRAITORS
    end
    return false
end

local function SetDefaultScanState(ply, oldRole, newRole)
    -- Players that change roles and should remain hidden only skip the team scan
    if ShouldHideRoleForTraitors(ply, oldRole, newRole) then
        ply:SetNWInt("TTTInformantScanStage", INFORMANT_SCANNED_TEAM)
    elseif ply:IsDetectiveTeam() then
        -- If the detective's role is not known, only skip the team scan
        if GetConVar("ttt_detectives_hide_special_mode"):GetInt() >= SPECIAL_DETECTIVE_HIDE_FOR_ALL then
            ply:SetNWInt("TTTInformantScanStage", INFORMANT_SCANNED_TEAM)
        -- Otherwise skip the team and role scan
        else
            ply:SetNWInt("TTTInformantScanStage", INFORMANT_SCANNED_ROLE)
        end
    -- Handle traitor logic specially so we don't expose roles when there is a glitch
    elseif (ply:IsTraitorTeam() and not ply:IsInformant()) or ply:IsGlitch() then
        -- Hide specific team roles if there is a glitch
        if GetGlobalBool("ttt_glitch_round", false) then
            ply:SetNWInt("TTTInformantScanStage", INFORMANT_SCANNED_TEAM)
        else
            ply:SetNWInt("TTTInformantScanStage", INFORMANT_SCANNED_ROLE)
        end
    -- Skip the team scanning stage for any role whose team is already known by a traitor
    elseif ply:IsJesterTeam() then
        ply:SetNWInt("TTTInformantScanStage", INFORMANT_SCANNED_TEAM)
    else
        ply:SetNWInt("TTTInformantScanStage", INFORMANT_UNSCANNED)
    end
end

hook.Add("TTTPrepareRound", "Informant_TTTPrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        v:SetNWInt("TTTInformantScanStage", INFORMANT_UNSCANNED)
        v:SetNWInt("TTTInformantScannerState", INFORMANT_SCANNER_IDLE)
        v:SetNWString("TTTInformantScannerTarget", "")
        v:SetNWString("TTTInformantScannerMessage", "")
        v:SetNWFloat("TTTInformantScannerStartTime", -1)
        v:SetNWFloat("TTTInformantScannerTargetLostTime", -1)
        v:SetNWFloat("TTTInformantScannerCooldown", -1)
    end
end)

hook.Add("TTTBeginRound", "Informant_TTTBeginRound", function()
    if not HasInformant() then return end

    for _, v in pairs(GetAllPlayers()) do
        SetDefaultScanState(v)
    end
end)

------------------
-- ROLE CHANGES --
------------------

hook.Add("TTTPlayerRoleChanged", "Informant_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if oldRole == newRole then return end
    if GetRoundState() ~= ROUND_ACTIVE then return end

    if oldRole == ROLE_INFORMANT then
        ply:SetNWInt("TTTInformantScannerState", INFORMANT_SCANNER_IDLE)
        ply:SetNWString("TTTInformantScannerTarget", "")
        ply:SetNWString("TTTInformantScannerMessage", "")
        ply:SetNWFloat("TTTInformantScannerStartTime", -1)
        ply:SetNWFloat("TTTInformantScannerTargetLostTime", -1)
        ply:SetNWFloat("TTTInformantScannerCooldown", -1)
    end

    -- Set the default role state if there is an informant
    local scanStage = ply:GetNWInt("TTTInformantScanStage", INFORMANT_UNSCANNED)
    if HasInformant() then
        -- Only notify if there is an informant and the player had some info being reset
        if scanStage > INFORMANT_UNSCANNED then
            local share = GetGlobalBool("ttt_informant_share_scans", true)
            local hideRole = ShouldHideRoleForTraitors(ply, oldRole, newRole)
            for _, v in pairs(GetAllPlayers()) do
                -- Don't tell people about this role change if we're not revealing them
                if hideRole then continue end

                if v:IsActiveInformant() then
                    v:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " has changed roles. You will need to rescan them.")
                elseif v:IsActiveTraitorTeam() and share then
                    v:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " has changed roles. The " .. ROLE_STRINGS[ROLE_INFORMANT] .. " will need to rescan them.")
                end
            end
        end

        SetDefaultScanState(ply, oldRole, newRole)
    -- If there is not, make sure this role is set to "unscanned"
    elseif scanStage > INFORMANT_UNSCANNED then
        ply:SetNWInt("TTTInformantScanStage", INFORMANT_UNSCANNED)
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

    ply:SetNWInt("TTTInformantScannerState", INFORMANT_SCANNER_LOST)
    ply:SetNWString("TTTInformantScannerTarget", "")
    ply:SetNWString("TTTInformantScannerMessage", "TARGET LOST")
    ply:SetNWFloat("TTTInformantScannerStartTime", -1)
    ply:SetNWFloat("TTTInformantScannerCooldown", CurTime())
end

local function Announce(ply, message)
    if not IsValid(ply) then return end

    ply:PrintMessage(HUD_PRINTTALK, "You have " .. message)
    if not GetGlobalBool("ttt_informant_share_scans", true) then return end

    for _, p in pairs(GetAllPlayers()) do
        if p:IsActiveTraitorTeam() and p ~= ply then
            p:PrintMessage(HUD_PRINTTALK, "The informant has " .. message)
        end
    end
end

local function InRange(ply, target)
    if not IsValid(ply) or not IsValid(target) then return false end

    if not ply:IsLineOfSightClear(target) then return false end

    local plyPos = ply:GetPos()
    local targetPos = target:GetPos()
    if plyPos:Distance(targetPos) > informant_scanner_distance:GetInt() then return false end

    return ply:IsOnScreen(target, 0.35)
end

local function ScanAllowed(ply, target)
    if not IsValid(ply) or not IsValid(target) then return false end
    if not IsPlayer(target) then return false end
    if not target:IsActive() then return false end
    if not InRange(ply, target) then return false end

    if target:IsJesterTeam() and not informant_can_scan_jesters:GetBool() then return false end

    -- Pretend that beggars and bodysnatchers that aren't revealed to this player are still on the jester team
    if target:GetNWBool("WasBeggar", false) and not ply:ShouldRevealBeggar(target) then return informant_can_scan_jesters:GetBool() end
    if target:GetNWBool("WasBodysnatcher", false) and not ply:ShouldRevealBodysnatcher(target) then return informant_can_scan_jesters:GetBool() end

    if (target:IsGlitch() or target:IsTraitorTeam()) then
        if not informant_can_scan_glitches:GetBool() then return false end
        if target:IsGlitch() then return true end
        local glitchMode = GetConVar("ttt_glitch_mode"):GetInt()
        if GetGlobalBool("ttt_glitch_round", false) and ((glitchMode == GLITCH_SHOW_AS_TRAITOR and target:IsTraitor()) or glitchMode >= GLITCH_SHOW_AS_SPECIAL_TRAITOR) then
            return true
        else
            return false
        end
    end
    return true
end

local function Scan(ply, target)
    if not IsValid(ply) or not IsValid(target) then return end

    if target:IsActive() then
        local stage = target:GetNWInt("TTTInformantScanStage", INFORMANT_UNSCANNED)
        if CurTime() - ply:GetNWFloat("TTTInformantScannerStartTime", -1) >= informant_scanner_time:GetInt() then
            stage = stage + 1
            if stage == INFORMANT_SCANNED_TEAM then
                local message = "discovered that " .. target:Nick() .. " is "
                if target:IsInnocentTeam() then
                    message = message .. "an innocent role."
                elseif target:IsIndependentTeam() then
                    message = message .. "an independent role."
                elseif target:IsMonsterTeam() then
                    message = message .. "a monster role."
                end

                Announce(ply, message)
                ply:SetNWFloat("TTTInformantScannerStartTime", CurTime())
            elseif stage == INFORMANT_SCANNED_ROLE then
                Announce(ply, "discovered that " .. target:Nick() .. " is " .. ROLE_STRINGS_EXT[target:GetRole()] .. ".")
                ply:SetNWFloat("TTTInformantScannerStartTime", CurTime())
            elseif stage == INFORMANT_SCANNED_TRACKED then
                Announce(ply, "tracked the movements of " .. target:Nick() .. " (" .. ROLE_STRINGS[target:GetRole()] .. ").")
                ply:SetNWInt("TTTInformantScannerState", INFORMANT_SCANNER_IDLE)
                ply:SetNWString("TTTInformantScannerTarget", "")
                ply:SetNWString("TTTInformantScannerMessage", "")
                ply:SetNWFloat("TTTInformantScannerStartTime", -1)
            end
            target:SetNWInt("TTTInformantScanStage", stage)
            hook.Call("TTTInformantScanStageChanged", nil, ply, target, stage)
        end
    else
        TargetLost(ply)
    end
end

hook.Add("TTTPlayerAliveThink", "Informant_TTTPlayerAliveThink", function(ply)
    if not IsValid(ply) or ply:IsSpec() or GetRoundState() ~= ROUND_ACTIVE then return end

    if ply:IsInformant() then
        local state = ply:GetNWInt("TTTInformantScannerState", INFORMANT_SCANNER_IDLE)
        if state == INFORMANT_SCANNER_IDLE then
            local target = IsTargetingPlayer(ply)
            if target and (not GetGlobalBool("ttt_informant_requires_scanner", false) or (ply.GetActiveWeapon and IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "weapon_inf_scanner")) then
                if target:GetNWInt("TTTInformantScanStage", INFORMANT_UNSCANNED) < INFORMANT_SCANNED_TRACKED and ScanAllowed(ply, target) then
                    ply:SetNWInt("TTTInformantScannerState", INFORMANT_SCANNER_LOCKED)
                    ply:SetNWString("TTTInformantScannerTarget", target:SteamID64())
                    ply:SetNWString("TTTInformantScannerMessage", "SCANNING " .. string.upper(target:Nick()))
                    ply:SetNWFloat("TTTInformantScannerStartTime", CurTime())
                end
            end
        elseif state == INFORMANT_SCANNER_LOCKED then
            local target = player.GetBySteamID64(ply:GetNWString("TTTInformantScannerTarget", ""))
            if target:IsActive() then
                if not InRange(ply, target) then
                    ply:SetNWInt("TTTInformantScannerState", INFORMANT_SCANNER_SEARCHING)
                    ply:SetNWString("TTTInformantScannerMessage", "SCANNING " .. string.upper(target:Nick()) .. " (LOSING TARGET)")
                    ply:SetNWFloat("TTTInformantScannerTargetLostTime", CurTime())
                end
                Scan(ply, target)
            else
                TargetLost(ply)
            end
        elseif state == INFORMANT_SCANNER_SEARCHING then
            local target = player.GetBySteamID64(ply:GetNWString("TTTInformantScannerTarget", ""))
            if target:IsActive() then
                if (CurTime() - ply:GetNWInt("TTTInformantScannerTargetLostTime", -1)) >= informant_scanner_float_time:GetInt() then
                    TargetLost(ply)
                else
                    if InRange(ply, target) then
                        ply:SetNWInt("TTTInformantScannerState", INFORMANT_SCANNER_LOCKED)
                        ply:SetNWString("TTTInformantScannerMessage", "SCANNING " .. string.upper(target:Nick()))
                        ply:SetNWFloat("TTTInformantScannerTargetLostTime", -1)
                    end
                    Scan(ply, target)
                end
            else
                TargetLost(ply)
            end
        elseif state == INFORMANT_SCANNER_LOST then
            if (CurTime() - ply:GetNWFloat("TTTInformantScannerCooldown", -1)) >= informant_scanner_cooldown:GetInt() then
                ply:SetNWInt("TTTInformantScannerState", INFORMANT_SCANNER_IDLE)
                ply:SetNWString("TTTInformantScannerMessage", "")
                ply:SetNWFloat("TTTInformantScannerCooldown", -1)
            end
        end
    end
end)