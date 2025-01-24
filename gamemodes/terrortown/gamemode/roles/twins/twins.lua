-------------
-- CONVARS --
-------------

local twins_spawn_chance = CreateConVar("ttt_twins_spawn_chance", "0.1", FCVAR_REPLICATED)
local twins_min_players = CreateConVar("ttt_twins_min_players", "0", FCVAR_REPLICATED)

local twins_enabled = GetConVar("ttt_twins_enabled")
local twins_invulnerability_timer = GetConVar("ttt_twins_invulnerability_timer")

-------------------
-- ROLE SPAWNING --
-------------------

hook.Add("TTTSelectRoles", "Twins_TTTSelectRoles", function()
    local players = {}
    local choices = {}
    local innocents = {}
    local traitors = {}
    local specialInnocents = {}
    local specialTraitors = {}

    for _, p in player.Iterator() do
        if IsValid(p) and not p:IsSpec() then
            table.insert(players, p)
            if p:GetRole() == ROLE_NONE then
                table.insert(choices, p)
            elseif p:IsInnocent() then
                table.insert(innocents, p)
            elseif p:IsTraitor() then
                table.insert(traitors, p)
            elseif p:IsInnocentTeam() and not p:IsDetectiveTeam() then
                table.insert(specialInnocents, p)
            elseif p:IsTraitorTeam() then
                table.insert(specialTraitors, p)
            end
        end
    end

    local forcedGoodTwin = false
    local forcedEvilTwin = false

    for _, p in player.Iterator() do
        local forcedRole = p:GetForcedRole()
        if forcedRole and table.HasValue(choices, p) then
            table.RemoveByValue(choices, p)
        end

        if forcedRole == ROLE_GOODTWIN or p:IsGoodTwin() then
            forcedGoodTwin = true
        elseif forcedRole == ROLE_EVILTWIN or p:IsEvilTwin() then
            forcedEvilTwin = true
        end
    end

    -- If both twins have been forced we can stop here
    if forcedGoodTwin and forcedEvilTwin then return
    -- If neither twin has been forced then we spawn them as normal
    elseif not forcedGoodTwin and not forcedEvilTwin then
        if not twins_enabled:GetBool() then return end
        if math.random() > twins_spawn_chance:GetFloat() then return end
        if twins_min_players:GetInt() ~= 0 and #players < twins_min_players:GetInt() then return end
        if #choices < 2 then return end

        table.Shuffle(choices)
        choices[1]:SetRole(ROLE_GOODTWIN)
        choices[2]:SetRole(ROLE_EVILTWIN)
    -- If only one twin has been forced then we should try to spawn the other prioritizing unassigned players, then vanilla roles, then special roles
    else
        if forcedGoodTwin then
            if #choices > 0 then
                table.Shuffle(choices)
                choices[1]:SetRole(ROLE_EVILTWIN)
            elseif #traitors > 0 then
                table.Shuffle(traitors)
                traitors[1]:SetRole(ROLE_EVILTWIN)
            elseif #specialTraitors > 0 then
                table.Shuffle(specialTraitors)
                specialTraitors[1]:SetRole(ROLE_EVILTWIN)
            end
        else
            if #choices > 0 then
                table.Shuffle(choices)
                choices[1]:SetRole(ROLE_GOODTWIN)
            elseif #innocents > 0 then
                table.Shuffle(innocents)
                innocents[1]:SetRole(ROLE_GOODTWIN)
            elseif #specialInnocents > 0 then
                table.Shuffle(specialInnocents)
                specialInnocents[1]:SetRole(ROLE_GOODTWIN)
            end
        end
    end
end)

hook.Add("TTTBeginRound", "Twins_TTTBeginRound", function()
    local goodTwins = {}
    local evilTwins = {}
    for _, p in player.Iterator() do
        if p:IsGoodTwin() then
            table.insert(goodTwins, p)
        elseif p:IsEvilTwin() then
            table.insert(evilTwins, p)
        end
    end

    -- If we don't have at least one of each twin at the start of the round, change them to regular innocents and traitors
    if #goodTwins == 0 or #evilTwins == 0 then
        for _, p in ipairs(goodTwins) do
            p:SetRole(ROLE_INNOCENT)
        end
        for _, p in ipairs(evilTwins) do
            p:SetRole(ROLE_TRAITOR)
        end
        return
    end

    local message

    if #goodTwins == 1 then
        message = goodTwins[1]:Nick() .. " is your " .. ROLE_STRINGS[ROLE_GOODTWIN] .. "."
    else
        message = "You have multiple " .. ROLE_STRINGS_PLURAL[ROLE_GOODTWIN] .. "! They are " .. util.FormattedList(goodTwins, function(ply) return ply:Nick() end) .. "."
    end
    for _, p in ipairs(evilTwins) do
        p:QueueMessage(MSG_PRINTBOTH, message)
        if #evilTwins >= 2 then
            local fellowEvilTwins = table.Copy(evilTwins)
            table.RemoveByValue(fellowEvilTwins, p)
            if #fellowEvilTwins == 1 then
                message = fellowEvilTwins[1]:Nick() .. " is a fellow " .. ROLE_STRINGS[ROLE_EVILTWIN] .. "!"
            else
                message = util.FormattedList(fellowEvilTwins, function(ply) return ply:Nick() end) .. " are fellow " .. ROLE_STRINGS_PLURAL[ROLE_EVILTWIN] .. "!"
            end
            p:QueueMessage(MSG_PRINTBOTH, message)
        end
    end

    if #evilTwins == 1 then
        message = evilTwins[1]:Nick() .. " is your " .. ROLE_STRINGS[ROLE_EVILTWIN] .. "."
    else
        message = "You have multiple " .. ROLE_STRINGS_PLURAL[ROLE_EVILTWIN] .. "! They are " .. util.FormattedList(evilTwins, function(ply) return ply:Nick() end) .. "."
    end
    for _, p in ipairs(goodTwins) do
        p:QueueMessage(MSG_PRINTBOTH, message)
        if #goodTwins >= 2 then
            local fellowGoodTwins = table.Copy(goodTwins)
            table.RemoveByValue(fellowGoodTwins, p)
            if #fellowGoodTwins == 1 then
                message = fellowGoodTwins[1]:Nick() .. " is a fellow " .. ROLE_STRINGS[ROLE_GOODTWIN] .. "!"
            else
                message = util.FormattedList(fellowGoodTwins, function(ply) return ply:Nick() end) .. " are fellow " .. ROLE_STRINGS_PLURAL[ROLE_GOODTWIN] .. "!"
            end
            p:QueueMessage(MSG_PRINTBOTH, message)
        end
    end
end)

------------------
-- DEATH CHECKS --
------------------

local invulnerabilityTriggered = false
local twinsCanDamageEachOther = false

local function CheckTwinsInvulnerability(ply, oldRole)
    if twinsCanDamageEachOther then return end
    if GetRoundState() ~= ROUND_ACTIVE then return end

    if (ply:IsTwin() or oldRole == ROLE_GOODTWIN or oldRole == ROLE_EVILTWIN) and not invulnerabilityTriggered then
        local invulnerability_timer = twins_invulnerability_timer:GetInt()
        if invulnerability_timer == 0 then return end

        local livingGoodTwins = {}
        local livingEvilTwins = {}
        for _, p in player.Iterator() do
            if p:IsActiveGoodTwin() then
                table.insert(livingGoodTwins, p)
                if #livingEvilTwins > 0 then return end
            elseif p:IsActiveEvilTwin() then
                table.insert(livingEvilTwins, p)
                if #livingGoodTwins > 0 then return end
            end
        end

        invulnerabilityTriggered = true
        if #livingGoodTwins > 0 then
            for _, p in ipairs(livingGoodTwins) do
                p:QueueMessage(MSG_PRINTBOTH, "The " .. ROLE_STRINGS[ROLE_EVILTWIN] .. " has died! You have been granted " .. invulnerability_timer .. " seconds of invulnerability.")
                p:SetInvulnerable(true, true)
                p:SetNWFloat("TTTTwinsInvulnerabilityEnd", CurTime() + invulnerability_timer)
                timer.Create("TwinInvulnerabilityEnd_" .. p:SteamID64(), invulnerability_timer, 1, function()
                    p:QueueMessage(MSG_PRINTTALK, "Your invulnerability period has ended.")
                    p:SetInvulnerable(false, true)
                    p:SetNWFloat("TTTTwinsInvulnerabilityEnd", 0)
                end)
            end
        elseif #livingEvilTwins > 0 then
            for _, p in ipairs(livingEvilTwins) do
                if not p:IsRoleAbilityDisabled() then
                    p:QueueMessage(MSG_PRINTBOTH, "The " .. ROLE_STRINGS[ROLE_GOODTWIN] .. " has died! You have been granted " .. invulnerability_timer .. " seconds of invulnerability.")
                    p:SetInvulnerable(true, true)
                    p:SetNWFloat("TTTTwinsInvulnerabilityEnd", CurTime() + invulnerability_timer)
                    timer.Create("TwinInvulnerabilityEnd_" .. p:SteamID64(), invulnerability_timer, 1, function()
                        p:QueueMessage(MSG_PRINTTALK, "Your invulnerability period has ended.")
                        p:SetInvulnerable(false, true)
                        p:SetNWFloat("TTTTwinsInvulnerabilityEnd", 0)
                    end)
                end
            end
        end
    else
        local twins = {}
        local hasGoodTwin = false
        local hasEvilTwin = false
        for _, p in player.Iterator() do
            if p:IsActive() then
                if p:IsGoodTwin() then
                    table.insert(twins, p)
                    hasGoodTwin = true
                elseif p:IsEvilTwin() then
                    table.insert(twins, p)
                    hasEvilTwin = true
                elseif not p:ShouldActLikeJester() then
                    return
                end
            end
        end

        twinsCanDamageEachOther = true
        if hasGoodTwin and hasEvilTwin then
            for _, p in ipairs(twins) do
                p:QueueMessage(MSG_PRINTBOTH, "Only twins remain! You can now damage each other freely.")
            end
        end
    end
end

hook.Add("PlayerDeath", "Twins_PlayerDeath", function(victim, infl, attacker)
    CheckTwinsInvulnerability(victim)
end)

hook.Add("TTTPlayerRoleChanged", "Twins_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    CheckTwinsInvulnerability(ply, oldRole)
    if (oldRole == ROLE_GOODTWIN or oldRole == ROLE_EVILTWIN) and newRole ~= ROLE_GOODTWIN and newRole ~= ROLE_EVILTWIN then
        if timer.Exists("TwinInvulnerabilityEnd_" .. ply:SteamID64()) then
            timer.Remove("TwinInvulnerabilityEnd_" .. ply:SteamID64())
            ply:SetInvulnerable(false, true)
            ply:SetNWFloat("TTTTwinsInvulnerabilityEnd", 0)
        end
    end
end)

---------------------
-- DAMAGE BLOCKING --
---------------------

hook.Add("EntityTakeDamage", "Twins_EntityTakeDamage", function(target, dmginfo)
    if not IsPlayer(target) then return end
    if not target:IsTwin() then return end

    local att = dmginfo:GetAttacker()
    if not IsPlayer(att) then return end

    if not twinsCanDamageEachOther and att:IsTwin() then
        dmginfo:ScaleDamage(0)
        dmginfo:SetDamage(0)
        return
    end
end)

----------------
-- HITMARKERS --
----------------

hook.Add("TTTDrawHitMarker", "Twins_TTTDrawHitMarker", function(victim, dmginfo)
    local att = dmginfo:GetAttacker()
    if not IsPlayer(att) or not IsPlayer(victim) then return end

    if not twinsCanDamageEachOther and att:IsTwin() and victim:IsTwin() then
        return true, false, true, false
    end
end)

-------------
-- CLEANUP --
-------------

hook.Add("TTTPrepareRound", "Twins_TTTPrepareRound", function()
    invulnerabilityTriggered = false
    twinsCanDamageEachOther = false

    for _, p in player.Iterator() do
        timer.Remove("TwinInvulnerabilityEnd_" .. p:SteamID64())
        p:SetNWFloat("TTTTwinsInvulnerabilityEnd", 0)
    end
end)