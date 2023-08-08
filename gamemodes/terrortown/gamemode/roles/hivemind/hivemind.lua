AddCSLuaFile()

local hook = hook
local player = player
local timer = timer

local AddHook = hook.Add
local GetAllPlayers = player.GetAll

util.AddNetworkString("TTT_HiveMindChatDupe")

-------------
-- CONVARS --
-------------

local hivemind_vision_enable = GetConVar("ttt_hivemind_vision_enable")
local hivemind_friendly_fire = GetConVar("ttt_hivemind_friendly_fire")

----------------------
-- CHAT DUPLICATION --
----------------------

AddHook("PlayerSay", "HiveMind_PlayerSay", function(ply, text, team_only)
    if team_only then return end

    net.Start("TTT_HiveMindChatDupe")
    net.WriteEntity(ply)
    net.WriteString(text)
    net.Broadcast()
end)

-------------------------
-- ROLE CHANGE ON KILL --
-------------------------

-- Players killed by the hive mind join the hive mind
AddHook("PlayerDeath", "HiveMind_PlayerDeath", function(victim, infl, attacker)
    if not IsValid(victim) or victim:IsHiveMind() then return end
    if not IsValid(attacker) or not attacker:IsHiveMind() then return end

    timer.Create("HiveMindRespawn_" .. victim:SteamID64(), 0.25, 1, function()
        -- Double-check
        if not IsValid(victim) or victim:IsHiveMind() then return end
        if not IsValid(attacker) or not attacker:IsHiveMind() then return end

        local body = victim.server_ragdoll or victim:GetRagdollEntity()
        victim:SpawnForRound(true)
        victim:SetRole(ROLE_HIVEMIND)
        if IsValid(body) then
            victim:SetPos(FindRespawnLocation(body:GetPos()) or body:GetPos())
            victim:SetEyeAngles(Angle(0, body:GetAngles().y, 0))
            body:Remove()
        end
        victim:QueueMessage(MSG_PRINTCENTER, "You have become part of the " .. ROLE_STRINGS[ROLE_HIVEMIND] .. ".")

        SendFullStateUpdate()
    end)
end)

-------------------
-- SHARED HEALTH --
-------------------

local currentHealth = nil
local maxHealth = nil

AddHook("TTTPlayerRoleChanged", "HiveMind_HealthSync_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if not ply:Alive() or ply:IsSpec() then return end
    if oldRole == ROLE_HIVEMIND or newRole ~= ROLE_HIVEMIND then return end

    -- Everyone except the first member of the hive mind is assigned the existing health pool
    if currentHealth == nil then
        currentHealth = ply:Health()
    else
        ply:SetHealth(currentHealth)
    end

    -- Each additional member of the hive mind adds their max health to the pool
    if maxHealth == nil then
        maxHealth = ply:GetMaxHealth()
    else
        maxHealth = maxHealth + ply:GetMaxHealth()

        for _, p in ipairs(GetAllPlayers()) do
            if not p:IsHiveMind() then continue end
            p:SetMaxHealth(maxHealth)

            if p ~= ply then
                p:QueueMessage(MSG_PRINTCENTER, ply:Nick() .. " (" .. ROLE_STRINGS_EXT[oldRole] .. ") has joined the " .. ROLE_STRINGS[ROLE_HIVEMIND] .. ".")
            end
        end
    end
end)

local function HandleHealthSync(ply, newHealth)
    -- Don't bother running this if the health hasn't changed
    if newHealth == currentHealth then return end

    -- This amount is, by definition, the latest health value for the whole hive mind
    currentHealth = newHealth

    -- Sync it to every other member
    for _, p in ipairs(GetAllPlayers()) do
        if p == ply then continue end
        if not p:IsActiveHiveMind() then continue end

        p:SetHealth(currentHealth)
    end
end

AddHook("PostEntityTakeDamage", "HiveMind_PostEntityTakeDamage", function(ent, dmginfo, taken)
    if not taken then return end
    if not IsPlayer(ent) or not ent:IsActiveHiveMind() then return end
    HandleHealthSync(ent, ent:Health())
end)

AddHook("TTTPlayerHealthChanged", "HiveMind_TTTPlayerHealthChanged", function(ply, oldHealth, newHealth)
    if not IsPlayer(ply) or not ply:IsActiveHiveMind() then return end
    HandleHealthSync(ply, newHealth)
end)

AddHook("PostPlayerDeath", "HiveMind_PostPlayerDeath", function(ply)
    if not IsPlayer(ply) or not ply:IsHiveMind() then return end

    for _, p in ipairs(GetAllPlayers()) do
        if p == ply then continue end
        if not p:IsActiveHiveMind() then continue end

        p:QueueMessage(MSG_PRINTCENTER, "A member of the " .. ROLE_STRINGS[ROLE_HIVEMIND] .. " has been killed.")
        p:Kill()
    end
end)

-------------------
-- FRIENDLY FIRE --
-------------------

-- If friendly fire is not enabled, prevent damage between hive minds
AddHook("ScalePlayerDamage", "HiveMind_ScalePlayerDamage", function(ply, hitgroup, dmginfo)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not ply:IsActiveHiveMind() then return end
    if hivemind_friendly_fire:GetBool() then return end

    local att = dmginfo:GetAttacker()
    if not IsPlayer(att) or not att:IsActiveHiveMind() then return end

    dmginfo:ScaleDamage(0)
end)

-----------
-- KARMA --
-----------

-- Hive Mind only loses karma for hurting their own team
AddHook("TTTKarmaShouldGivePenalty", "HiveMind_TTTKarmaShouldGivePenalty", function(ply, reward, victim)
    if IsPlayer(victim) and victim:IsActiveHiveMind() and ply:IsActiveHiveMind() then
        return true
    end
end)

----------------
-- WIN CHECKS --
----------------

AddHook("TTTCheckForWin", "HiveMind_TTTCheckForWin", function()
    -- Only independent hive minds can win on their own
    if not INDEPENDENT_ROLES[ROLE_HIVEMIND] then return end

    local hivemind_alive = false
    local other_alive = false
    for _, v in ipairs(GetAllPlayers()) do
        if v:IsActive() then
            if v:IsHiveMind() then
                hivemind_alive = true
            elseif not v:ShouldActLikeJester() then
                other_alive = true
            end
        end
    end

    if hivemind_alive and not other_alive then
        return WIN_HIVEMIND
    elseif hivemind_alive then
        return WIN_NONE
    end
end)

AddHook("TTTPrintResultMessage", "HiveMind_TTTPrintResultMessage", function(type)
    if type == WIN_HIVEMIND then
        LANG.Msg("win_hivemind", { role = ROLE_STRINGS[ROLE_HIVEMIND] })
        ServerLog("Result: " .. ROLE_STRINGS[ROLE_HIVEMIND] .. " wins.\n")
        return true
    end
end)

-----------------------
-- PLAYER VISIBILITY --
-----------------------

-- Add all hive mind members to the PVS if vision is enabled
AddHook("SetupPlayerVisibility", "HiveMind_SetupPlayerVisibility", function(ply)
    if not ply:ShouldBypassCulling() then return end
    if not ply:IsActiveHiveMind() then return end
    if not hivemind_vision_enable:GetBool() then return end

    for _, v in ipairs(GetAllPlayers()) do
        if ply:TestPVS(v) then continue end
        if not v:IsActiveHiveMind() then continue end

        local pos = v:GetPos()
        if ply:IsOnScreen(pos) then
            AddOriginToPVS(pos)
        end
    end
end)

-------------
-- CLEANUP --
-------------

AddHook("TTTPrepareRound", "HiveMind_PrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        timer.Remove("HiveMindRespawn_" .. v:SteamID64())
    end
end)