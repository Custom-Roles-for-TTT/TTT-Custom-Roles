AddCSLuaFile()

local hook = hook
local player = player
local timer = timer

local AddHook = hook.Add
local CallHook = hook.Call
local PlayerIterator = player.Iterator

util.AddNetworkString("TTT_HiveMindChatDupe")

local CHAT_MODE_NONE = 0
local CHAT_DUPE_ALL = 1
local CHAT_DUPE_PRIME = 2

-------------
-- CONVARS --
-------------

local hivemind_chat_mode = CreateConVar("ttt_hivemind_chat_mode", CHAT_DUPE_ALL, FCVAR_NONE, "How to handle chat by the hive mind. 0 - Do nothing. 1 - Force all members to duplicate when any member chats. 2 - Force all members to duplicate when only the first member chats.", CHAT_MODE_NONE, CHAT_DUPE_PRIME)
local hivemind_block_environmental = CreateConVar("ttt_hivemind_block_environmental", "0", FCVAR_NONE, "Whether to block environmental damage to the hive mind", 0, 1)

local hivemind_vision_enabled = GetConVar("ttt_hivemind_vision_enabled")
local hivemind_friendly_fire = GetConVar("ttt_hivemind_friendly_fire")
local hivemind_join_heal_pct = GetConVar("ttt_hivemind_join_heal_pct")
local hivemind_join_max_hp_pct = GetConVar("ttt_hivemind_join_max_hp_pct")
local hivemind_regen_timer = GetConVar("ttt_hivemind_regen_timer")
local hivemind_regen_per_member_amt = GetConVar("ttt_hivemind_regen_per_member_amt")
local hivemind_regen_max_pct = GetConVar("ttt_hivemind_regen_max_pct")

----------------------
-- CHAT DUPLICATION --
----------------------

AddHook("PlayerSay", "HiveMind_PlayerSay", function(ply, text, team_only)
    local chat_mode = hivemind_chat_mode:GetInt()
    if chat_mode <= CHAT_MODE_NONE then return end
    if not IsPlayer(ply) then return end
    if not ply:IsHiveMind() then return end
    if chat_mode == CHAT_DUPE_PRIME and not ply.HiveMindPrime then return end
    if team_only then return end

    net.Start("TTT_HiveMindChatDupe")
        net.WritePlayer(ply)
        net.WriteString(text)
    net.Broadcast()
end)

-------------------------
-- ROLE CHANGE ON KILL --
-------------------------

-- Players killed by the hive mind join the hive mind
AddHook("PlayerDeath", "HiveMind_Assimilate_PlayerDeath", function(victim, infl, attacker)
    if not IsPlayer(victim) or victim:IsHiveMind() then return end
    if not IsPlayer(attacker) or not attacker:IsHiveMind() or attacker:IsRoleAbilityDisabled() then return end

    -- Let other roles or addons prevent hive mind respawn
    if CallHook("TTTCanRespawnAsRole", nil, victim, ROLE_HIVEMIND) == false then return end

    -- Hive Mind bypasses whatever respawn feature the victim's old role had
    if victim:IsRespawning() then
        victim:StopRespawning()
    end

    victim:SetNWBool("HiveMindRespawning", true)
    timer.Create("HiveMindRespawn_" .. victim:SteamID64(), 0.25, 1, function()
        -- Double-check
        if not IsPlayer(victim) or victim:IsHiveMind() then return end
        if not IsPlayer(attacker) or not attacker:IsHiveMind() then return end

        victim:SetNWBool("HiveMindRespawning", false)

        local body = victim.server_ragdoll or victim:GetRagdollEntity()
        victim.HiveMindPreviousMaxHealth = victim:GetMaxHealth()
        victim:SpawnForRound(true)
        victim:SetRole(ROLE_HIVEMIND)
        victim:StripRoleWeapons()
        if IsValid(body) then
            local credits = CORPSE.GetCredits(body, 0)
            victim:AddCredits(credits)
            victim:SetPos(FindRespawnLocation(body:GetPos()) or body:GetPos())
            victim:SetEyeAngles(Angle(0, body:GetAngles().y, 0))
            body:Remove()
        end
        victim:QueueMessage(MSG_PRINTCENTER, "You have become part of the " .. ROLE_STRINGS[ROLE_HIVEMIND] .. ".")

        SendFullStateUpdate()
    end)
end)

hook.Add("TTTStopPlayerRespawning", "HiveMind_TTTStopPlayerRespawning", function(ply)
    if not IsPlayer(ply) then return end
    if ply:Alive() then return end

    if ply:GetNWBool("HiveMindRespawning", false) then
        timer.Remove("HiveMindRespawn_" .. ply:SteamID64())
        ply:SetNWBool("HiveMindRespawning", false)
    end
end)

--------------------
-- SHARED CREDITS --
--------------------

local currentCredits = 0

local function HandleCreditsSync(amt)
    currentCredits = currentCredits + amt
    for _, p in PlayerIterator() do
        if not p:IsHiveMind() then continue end
        if p:GetCredits() ~= currentCredits then
            p:SetCredits(currentCredits)
        end
    end
end

AddHook("TTTPlayerCreditsChanged", "HiveMind_CreditsSync_TTTPlayerCreditsChanged", function(ply, amt)
    if not IsPlayer(ply) or not ply:IsActiveHiveMind() then return end
    HandleCreditsSync(amt)
end)

AddHook("TTTPlayerRoleChanged", "HiveMind_CreditsSync_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if not ply:Alive() or ply:IsSpec() then return end
    if oldRole == ROLE_HIVEMIND or newRole ~= ROLE_HIVEMIND then return end
    HandleCreditsSync(ply:GetCredits())
end)

AddHook("TTTBodyCreditsLooted", "HiveMind_CreditsSync_TTTBodyCreditsLooted", function(ply, deadPly, rag, credits)
    if not IsPlayer(deadPly) or not deadPly:IsHiveMind() then return end

    -- Find all corpses that belong to hive minds and remove their credits
    for _, p in PlayerIterator() do
        if not p:IsHiveMind() then continue end
        if p:Alive() or not p:IsSpec() then continue end

        p:SetCredits(0)
        local p_rag = p.server_ragdoll or p:GetRagdollEntity()
        if IsValid(p_rag) then
            CORPSE.SetCredits(p_rag, 0)
        end
    end
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
        local roleMaxHealth = 100
        -- This player should have their previous max health saved in the death hook above, but just make sure
        if ply.HiveMindPreviousMaxHealth then
            roleMaxHealth = ply.HiveMindPreviousMaxHealth
            ply.HiveMindPreviousMaxHealth = nil
        -- If it's not there, for whatever reason, use the old role's configured max health instead
        elseif oldRole > ROLE_NONE and oldRole <= ROLE_MAX then
            roleMaxHealth = cvars.Number("ttt_" .. ROLE_STRINGS_RAW[oldRole] .. "_max_health", 100)
        end
        maxHealth = maxHealth + (roleMaxHealth * hivemind_join_max_hp_pct:GetFloat())

        local heal_pct = hivemind_join_heal_pct:GetFloat()
        if heal_pct > 0 then
            local healAmt = math.ceil(roleMaxHealth * heal_pct)
            currentHealth = currentHealth + healAmt
        end

        for _, p in PlayerIterator() do
            if not p:IsHiveMind() then continue end
            p:SetMaxHealth(maxHealth)
            -- If we're being healed, update everyone's health too
            if heal_pct > 0 then
                p:SetHealth(currentHealth)
            end

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
    for _, p in PlayerIterator() do
        if p == ply then continue end
        if not p:IsActiveHiveMind() then continue end

        p:SetHealth(currentHealth)
    end
end

AddHook("EntityTakeDamage", "HiveMind_EntityTakeDamage", function(ent, dmginfo)
    if GetRoundState() ~= ROUND_ACTIVE then return end
    if not hivemind_block_environmental:GetBool() then return end
    if not IsPlayer(ent) then return end
    if not ent:IsActiveHiveMind() then return end

    -- Block environmental damage to this hive mind as long as it isn't a map trigger doing it
    -- Damage type DMG_GENERIC is "0" which doesn't seem to work with IsDamageType
    local att = dmginfo:GetAttacker()
    if (not IsValid(att) or att:GetClass() ~= "trigger_hurt") and
        (dmginfo:IsExplosionDamage() or dmginfo:IsDamageType(DMG_BURN) or dmginfo:IsDamageType(DMG_CRUSH) or
         dmginfo:IsDamageType(DMG_DROWN) or dmginfo:GetDamageType() == 0 or dmginfo:IsDamageType(DMG_DISSOLVE)) then
        dmginfo:ScaleDamage(0)
        dmginfo:SetDamage(0)
    end
end)

AddHook("PostEntityTakeDamage", "HiveMind_PostEntityTakeDamage", function(ent, dmginfo, taken)
    if not taken then return end
    if not IsPlayer(ent) or not ent:IsActiveHiveMind() then return end
    HandleHealthSync(ent, ent:Health())
end)

AddHook("TTTPlayerHealthChanged", "HiveMind_TTTPlayerHealthChanged", function(ply, oldHealth, newHealth)
    if not IsPlayer(ply) or not ply:IsActiveHiveMind() then return end
    HandleHealthSync(ply, newHealth)
end)

-- Kill all the members of the hive mind if a single hive mind is killed
AddHook("PlayerDeath", "HiveMind_GroupDeath_PlayerDeath", function(victim, infl, attacker)
    if not IsPlayer(victim) or not victim:IsHiveMind() then return end
    -- If the victim and the inflictor and the attacker are all the same thing then they probably used the "kill" console command
    if victim == attacker and IsValid(infl) and victim == infl then return end

    for _, p in PlayerIterator() do
        if p == victim then continue end
        if not p:IsActiveHiveMind() then continue end

        p:QueueMessage(MSG_PRINTCENTER, "A member of the " .. ROLE_STRINGS[ROLE_HIVEMIND] .. " has been killed.")
        p:Kill()
    end

    -- Reset the current health in case a member of the hive mind comes back somehow
    -- Let them keep their max health and weapons though because the other players are still part of the hive mind, even if dead
    currentHealth = nil
end)

------------------
-- HEALTH REGEN --
------------------

local primeAssigned = false
ROLE_ON_ROLE_ASSIGNED[ROLE_HIVEMIND] = function(ply)
    if not primeAssigned then
        ply.HiveMindPrime = true
        primeAssigned = true
    end
    if timer.Exists("HiveMindHealthRegen") then return end

    local regen_timer = hivemind_regen_timer:GetInt()
    if regen_timer <= 0 then return end

    local per_member_amt = hivemind_regen_per_member_amt:GetInt()
    local regen_max = hivemind_regen_max_pct:GetFloat()

    timer.Create("HiveMindHealthRegen", regen_timer, 0, function()
        local hivemind_count = 0
        for _, p in PlayerIterator() do
            if p:IsHiveMind() then
                hivemind_count = hivemind_count + 1
            end
        end

        -- Only heal for each additional member
        if hivemind_count <= 1 then return end

        -- If we're healing past their max regen, scale the amount down to match instead
        local heal_amount = per_member_amt * (hivemind_count - 1)
        if (currentHealth + heal_amount) / maxHealth > regen_max then
            heal_amount = math.floor(regen_max * maxHealth) - currentHealth
        end

        -- Don't bother syncing if we're not healing anything
        if heal_amount <= 0 then return end

        HandleHealthSync(nil, currentHealth + heal_amount)
    end)
end

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
    for _, v in PlayerIterator() do
        if v:IsActive() then
            if v:IsHiveMind() then
                hivemind_alive = true
            elseif not v:ShouldActLikeJester() and not ROLE_HAS_PASSIVE_WIN[v:GetRole()] then
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
    if not hivemind_vision_enabled:GetBool() then return end

    for _, v in PlayerIterator() do
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
    primeAssigned = false
    for _, v in PlayerIterator() do
        timer.Remove("HiveMindRespawn_" .. v:SteamID64())
        v:SetNWBool("HiveMindRespawning", false)
        v.HiveMindPreviousMaxHealth = nil
        v.HiveMindPrime = nil
    end
    timer.Remove("HiveMindHealthRegen")
end)