AddCSLuaFile()

util.AddNetworkString("TTT_UpdateOldManWins")

resource.AddSingleFile("sound/oldmanramble.wav")

-------------
-- CONVARS --
-------------

local oldman_drain_health_to = CreateConVar("ttt_oldman_drain_health_to", "0")
local oldman_adrenaline_rush = CreateConVar("ttt_oldman_adrenaline_rush", "5")
local oldman_adrenaline_shotgun = CreateConVar("ttt_oldman_adrenaline_shotgun", "1")
local oldman_adrenaline_ramble = CreateConVar("ttt_oldman_adrenaline_ramble", "1")
local oldman_hide_when_active = CreateConVar("ttt_oldman_hide_when_active", "0")

hook.Add("TTTSyncGlobals", "OldMan_TTTSyncGlobals", function()
    SetGlobalInt("ttt_oldman_drain_health_to", oldman_drain_health_to:GetInt())
    SetGlobalInt("ttt_oldman_adrenaline_rush", oldman_adrenaline_rush:GetInt())
    SetGlobalBool("ttt_oldman_adrenaline_shotgun", oldman_adrenaline_shotgun:GetBool())
    SetGlobalBool("ttt_oldman_hide_when_active", oldman_hide_when_active:GetBool())
end)

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
            for _, p in pairs(player.GetAll()) do
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

hook.Add("EntityTakeDamage", "OldMan_EntityTakeDamage", function(ent, dmginfo)
    if GetRoundState() ~= ROUND_ACTIVE then return end
    if not IsPlayer(ent) or not ent:IsOldMan() then return end

    local adrenalineTime = oldman_adrenaline_rush:GetInt()
    -- Don't run this if adrenaline rush is disabled
    if adrenalineTime <= 0 then return end

    -- Only give the Old Man an adrenaline rush once
    if ent:GetNWBool("AdrenalineRushed", false) then return end

    local att = dmginfo:GetAttacker()
    local damage = dmginfo:GetDamage()
    local health = ent:Health()
    if ent:IsRoleActive() then -- If they are mid adrenaline rush then they take no damage
        dmginfo:ScaleDamage(0)
        dmginfo:SetDamage(0)
    elseif IsPlayer(att) and damage >= health then -- If they are attacked by a player that would have killed them they enter an adrenaline rush
        dmginfo:SetDamage(health - 1)
        ent:SetNWBool("AdrenalineRush", true)
        if oldman_adrenaline_ramble:GetBool() then
            ent:EmitSound("oldmanramble.wav")
        end
        local message = "You are having an adrenaline rush! You will die in " .. tostring(adrenalineTime) .. " seconds."
        ent:PrintMessage(HUD_PRINTTALK, message)
        ent:PrintMessage(HUD_PRINTCENTER, message)

        if oldman_adrenaline_shotgun:GetBool() then
            for _, wep in ipairs(ent:GetWeapons()) do
                if wep.Kind == WEAPON_HEAVY then
                    ent:StripWeapon(wep:GetClass())
                end
            end
            ent:Give("weapon_old_dbshotgun")
            ent:SelectWeapon("weapon_old_dbshotgun")
        end

        timer.Create(ent:Nick() .. "AdrenalineRush", adrenalineTime, 1, function()
            ent:SetNWBool("AdrenalineRush", false)
            ent:SetNWBool("AdrenalineRushed", true)
            -- Only kill them if they are still the old man
            if ent:IsActiveOldMan() then
                local inflictor = dmginfo:GetInflictor()
                if not IsValid(inflictor) then
                    inflictor = att
                end

                -- Use TakeDamage instead of Kill so it properly applies karma
                local dmg = DamageInfo()
                dmg:SetDamageType(dmginfo:GetDamageType())
                dmg:SetAttacker(att)
                dmg:SetInflictor(inflictor)
                -- Use 10 so damage scaling doesn't mess with it. The worse damage factor (0.1) will still deal 1 damage after scaling a 10 down
                -- Karma ignores excess damage anyway
                dmg:SetDamage(10)
                dmg:SetDamageForce(Vector(0, 0, 1))

                ent:TakeDamageInfo(dmg)
            end
        end)
    end
end)

hook.Add("TTTPrepareRound", "OldMan_Adrenaline_TTTPrepareRound", function()
    for _, v in pairs(player.GetAll()) do
        v:SetNWBool("AdrenalineRush", false)
        v:SetNWBool("AdrenalineRushed", false)
        timer.Remove(v:Nick() .. "AdrenalineRush")
    end
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