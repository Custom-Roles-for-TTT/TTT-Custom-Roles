AddCSLuaFile()

local hook = hook
local ipairs = ipairs
local IsValid = IsValid
local net = net
local pairs = pairs
local player = player
local resource = resource
local timer = timer
local util = util

local GetAllPlayers = player.GetAll

util.AddNetworkString("TTT_UpdateOldManWins")
util.AddNetworkString("TTT_ResetOldManWins")

resource.AddSingleFile("sound/oldmanramble.wav")

-------------
-- CONVARS --
-------------

local oldman_drain_health_to = GetConVar("ttt_oldman_drain_health_to")
local oldman_adrenaline_rush = GetConVar("ttt_oldman_adrenaline_rush")
local oldman_adrenaline_shotgun = GetConVar("ttt_oldman_adrenaline_shotgun")
local oldman_adrenaline_ramble = GetConVar("ttt_oldman_adrenaline_ramble")

----------------
-- WIN CHECKS --
----------------

local function HandleOldManWinChecks(win_type)
    if win_type == WIN_NONE then return end
    if not player.IsRoleLiving(ROLE_OLDMAN) then return end

    net.Start("TTT_UpdateOldManWins")
    net.WriteBool(true)
    net.Broadcast()
end
hook.Add("TTTWinCheckComplete", "OldMan_TTTWinCheckComplete", HandleOldManWinChecks)

-------------------
-- ROLE FEATURES --
-------------------

-- Manage health drain
hook.Add("TTTEndRound", "OldMan_RoleFeatures_TTTEndRound", function()
    if timer.Exists("oldmanhealthdrain") then timer.Remove("oldmanhealthdrain") end
end)

ROLE_ON_ROLE_ASSIGNED[ROLE_OLDMAN] = function(ply)
    local oldman_drain_health = oldman_drain_health_to:GetInt()
    if oldman_drain_health > 0 then
        timer.Create("oldmanhealthdrain", 3, 0, function()
            for _, p in pairs(GetAllPlayers()) do
                if p:IsActiveOldMan() then
                    local hp = p:Health()
                    if hp > oldman_drain_health then
                        p:SetHealth(hp - 1)
                    end

                    local max = p:GetMaxHealth()
                    if max > oldman_drain_health then
                        p:SetMaxHealth(max - 1)
                    end
                end
            end
        end)
    end
end

local tempHealth = 10000
hook.Add("EntityTakeDamage", "OldMan_EntityTakeDamage", function(ent, dmginfo)
    -- Don't run this if adrenaline rush is disabled
    local adrenalineTime = oldman_adrenaline_rush:GetInt()
    if adrenalineTime <= 0 then return end

    if GetRoundState() ~= ROUND_ACTIVE then return end
    if not IsPlayer(ent) or not ent:IsOldMan() then return end

    -- If they are mid adrenaline rush then they take no damage
    if ent:IsRoleActive() then
        dmginfo:ScaleDamage(0)
        dmginfo:SetDamage(0)
        return
    end

    -- Only give the Old Man an adrenaline rush once
    if ent:GetNWBool("AdrenalineRushed", false) then return end

    -- If we're not already processing one of these events
    if not ent.damageHealth then
        -- Save their real health
        ent.damageHealth = ent:Health()
        -- Set their health to a high number so we can detect if they take damage
        ent:SetHealth(tempHealth)
    end
end)

hook.Add("TTTDrawHitMarker", "OldMan_TTTDrawHitMarker", function(victim, dmginfo)
    local adrenalineTime = oldman_adrenaline_rush:GetInt()
    if adrenalineTime <= 0 then return end

    if GetRoundState() ~= ROUND_ACTIVE then return end

    if not IsPlayer(victim) then return end
    if victim:IsOldMan() and victim:IsRoleActive() then
        return true, false, true, false
    end
end)

hook.Add("PostEntityTakeDamage", "OldMan_PostEntityTakeDamage", function(ent, dmginfo, took)
    -- Don't run this if adrenaline rush is disabled
    local adrenalineTime = oldman_adrenaline_rush:GetInt()
    if adrenalineTime <= 0 then return end

    if GetRoundState() ~= ROUND_ACTIVE then return end
    if not IsPlayer(ent) or not ent:IsOldMan() then return end

    -- Retrieve their original health
    local health = ent.damageHealth
    ent.damageHealth = nil
    if not health then return end

    -- And check if they took damage
    local damage = dmginfo:GetDamage()

    -- If they didn't take damage then we don't care
    -- but be sure to set their health back to the original
    if not took or damage <= 0 then
        ent:SetHealth(health)
        return
    end

    -- Only give the Old Man an adrenaline rush once
    if ent:IsRoleActive() then return end
    if ent:GetNWBool("AdrenalineRushed", false) then return end

    -- If the damage would have killed them then...
    if damage >= health then
        local att = dmginfo:GetAttacker()
        -- If they are attacked by a player, enter an adrenaline rush
        if IsPlayer(att) then
            ent:SetNWBool("AdrenalineRush", true)
            -- Delay the health change here slightly so that any other damage events can fully clear first
            -- Without this delay, double damage events (from, e.g. a Holy Hand Grenade explosion) will cause the player to die
            timer.Simple(0, function()
                ent:SetHealth(1)
            end)
            if oldman_adrenaline_ramble:GetBool() then
                ent:EmitSound("oldmanramble.wav")
            end
            ent:QueueMessage(MSG_PRINTBOTH, "You are having an adrenaline rush! You will die in " .. tostring(adrenalineTime) .. " seconds.")

            if oldman_adrenaline_shotgun:GetBool() then
                for _, wep in ipairs(ent:GetWeapons()) do
                    if wep.Kind == WEAPON_HEAVY then
                        ent:StripWeapon(wep:GetClass())
                    end
                end
                ent:SetFOV(0, 0)
                ent:Give("weapon_old_dbshotgun")
                ent:SelectWeapon("weapon_old_dbshotgun")
            end

            local inflictor = dmginfo:GetInflictor()
            local damagetype = dmginfo:GetDamageType()
            timer.Create(ent:Nick() .. "AdrenalineRush", adrenalineTime, 1, function()
                ent:SetNWBool("AdrenalineRush", false)
                ent:SetNWBool("AdrenalineRushed", true)
                -- Only kill them if they are still the old man
                if ent:IsActiveOldMan() then
                    if not IsValid(inflictor) then
                        inflictor = att
                    end

                    -- Use TakeDamage instead of Kill so it properly applies karma
                    local dmg = DamageInfo()
                    dmg:SetDamageType(damagetype)
                    dmg:SetAttacker(att)
                    dmg:SetInflictor(inflictor)
                    -- Use 10 so damage scaling doesn't mess with it. The worse damage factor (0.1) will still deal 1 damage after scaling a 10 down
                    -- Karma ignores excess damage anyway
                    dmg:SetDamage(10)
                    dmg:SetDamageForce(Vector(0, 0, 1))

                    ent:TakeDamageInfo(dmg)
                end
            end)
        -- Otherwise just let them die
        else
            ent:Kill()
        end
    -- If this wasn't enough to kill the player, reduce their health by the damage amount
    else
        ent:SetHealth(health - damage)
    end
end)

hook.Add("TTTPrepareRound", "OldMan_TTTPrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        v.damageHealth = nil
        v:SetNWBool("AdrenalineRush", false)
        v:SetNWBool("AdrenalineRushed", false)
        timer.Remove(v:Nick() .. "AdrenalineRush")
    end

    net.Start("TTT_ResetOldManWins")
    net.Broadcast()
end)

hook.Add("TTTBeginRound", "OldMan_TTTBeginRound", function()
    net.Start("TTT_ResetOldManWins")
    net.Broadcast()
end)

-----------
-- KARMA --
-----------

hook.Add("TTTKarmaShouldGivePenalty", "OldMan_TTTKarmaShouldGivePenalty", function(attacker, victim)
    -- Innocents will lose karma for killing an Old Man
    if attacker:IsInnocentTeam() and victim:IsOldMan() then
        return true
    end
    -- Old Man has no karma, positive or negative, while their adrenaline rush is active
    if attacker:IsOldMan() then
        return not attacker:GetNWBool("AdrenalineRush", false)
    end
end)

-------------
-- CREDITS --
-------------

local function OldManCreditLogic(victim, attacker, amt)
    if victim:IsOldMan() then
        return 0
    end
end

-- Nobody should be rewarded for killing the old man
hook.Add("TTTRewardDetectiveTraitorDeathAmount", "OldMan_TTTRewardDetectiveTraitorDeathAmount", OldManCreditLogic)
hook.Add("TTTRewardTraitorInnocentDeathAmount", "OldMan_TTTRewardTraitorInnocentDeathAmount", OldManCreditLogic)