AddCSLuaFile()

local plymeta = FindMetaTable("Player")

local hook = hook
local IsValid = IsValid
local math = math
local net = net
local pairs = pairs
local player = player
local table = table
local util = util

local AddHook = hook.Add
local RemoveHook = hook.Remove
local PlayerIterator = player.Iterator
local MathRandom = math.random
local TableInsert = table.insert

util.AddNetworkString("TTT_Zombified")

-------------
-- CONVARS --
-------------

CreateConVar("ttt_zombie_round_chance", 0.1, FCVAR_NONE, "The chance that a \"zombie round\" will occur where all players who would have been traitors are made zombies instead. Only usable when \"ttt_zombie_is_traitor\" is set to \"1\"", 0, 1)
local zombie_prime_only_weapons = CreateConVar("ttt_zombie_prime_only_weapons", "1")
local zombie_respawn_health = CreateConVar("ttt_zombie_respawn_health", "100", FCVAR_NONE, "The amount of health a player should respawn with when they are converted to a zombie thrall", 1, 200)
local zombie_friendly_fire = CreateConVar("ttt_zombie_friendly_fire", "2", FCVAR_NONE, "How to handle friendly fire damage between zombies. 0 - Do nothing. 1 - Reflect the damage back to the attacker. 2 - Negate the damage.", 0, 2)
local zombie_respawn_block_win = CreateConVar("ttt_zombie_respawn_block_win", "0")
local zombie_prime_convert_chance = CreateConVar("ttt_zombie_prime_convert_chance", "1", FCVAR_NONE, "The chance that a prime zombie (e.g. player who spawned as a zombie originally) will convert other players who are killed by their claws to be zombies as well. Set to 0 to disable", 0, 1)
local zombie_thrall_convert_chance = CreateConVar("ttt_zombie_thrall_convert_chance", "1", FCVAR_NONE, "The chance that a zombie thrall (e.g. non-prime zombie) will convert other players who are killed by their claws to be zombies as well. Set to 0 to disable", 0, 1)

local zombie_show_target_icon = GetConVar("ttt_zombie_show_target_icon")
local zombie_vision_enabled = GetConVar("ttt_zombie_vision_enabled")
local zombie_damage_penalty = GetConVar("ttt_zombie_damage_penalty")
local zombie_damage_reduction = GetConVar("ttt_zombie_damage_reduction")
local zombie_spit_convert = GetConVar("ttt_zombie_spit_convert")

-----------
-- PRIME --
-----------

-- If the last zombie prime leaves, randomly choose a new one
local function Zombie_Prime_PlayerDisconnected(ply)
    if not ply:IsZombie() then return end
    if not ply:IsZombiePrime() then return end

    local zombies = {}
    for _, v in PlayerIterator() do
        if v:IsActiveZombie() and v ~= ply then
            -- If we already have another prime, we're all set
            if v:IsZombiePrime() then
                return
            end

            TableInsert(zombies, v)
        end
    end

    if #zombies == 0 then return end

    local idx = MathRandom(1, #zombies)
    local new_prime = zombies[idx]
    new_prime:SetZombiePrime(true)

    new_prime:QueueMessage(MSG_PRINTBOTH, "The prime " .. ROLE_STRINGS[ROLE_ZOMBIE] .. " has been lost and you've seized power in their absence!")
end

-- Keep previous naming scheme for backwards compatibility
function plymeta:SetZombiePrime(p) self:SetNWBool("zombie_prime", p) end

-----------------
-- ROLE STATUS --
-----------------

AddHook("TTTPlayerRoleChanged", "Zombie_RoleFeatures_TTTPlayerRoleChanged", function(ply, oldRole, role)
    if role ~= ROLE_ZOMBIE then return end
    if oldRole ~= ROLE_NONE then return end

    ply:SetZombiePrime(true)
end)

AddHook("TTTPrepareRound", "Zombie_RoleFeatures_PrepareRound", function()
    for _, v in PlayerIterator() do
        v.WasZombieColored = false
        v:SetNWBool("IsZombifying", false)
        v:SetZombiePrime(false)
        timer.Remove("Zombify_" .. v:SteamID64())
    end
end)

ROLE_MOVE_ROLE_STATE[ROLE_ZOMBIE] = function(ply, target, keep_on_source)
    if ply:IsZombiePrime() then
        if not keep_on_source then ply:SetZombiePrime(false) end
        target:SetZombiePrime(true)
    end
end

----------------
-- WIN CHECKS --
----------------

local function Zombie_TTTWinCheckBlocks(win_blocks)
    if not zombie_respawn_block_win:GetBool() then return end

    TableInsert(win_blocks, function(win)
        for _, v in PlayerIterator() do
            if v:IsZombifying() then
                return WIN_NONE
            end
        end
    end)
end

local function Zombie_TTTCheckForWin()
    -- Only run the win check if the zombies win by themselves (or with the Mad Scientist)
    if not INDEPENDENT_ROLES[ROLE_ZOMBIE] then return end

    local zombie_alive = false
    local other_alive = false
    for _, v in PlayerIterator() do
        if v:IsActive() then
            if v:IsZombie() or v:IsMadScientist() then
                zombie_alive = true
            elseif not v:ShouldActLikeJester() and not ROLE_HAS_PASSIVE_WIN[v:GetRole()] then
                other_alive = true
            end
        end
    end

    if zombie_alive and not other_alive then
        return WIN_ZOMBIE
    elseif zombie_alive then
        return WIN_NONE
    end
end

local function Zombie_TTTPrintResultMessage(type)
    if type == WIN_ZOMBIE then
        local plural = ROLE_STRINGS_PLURAL[ROLE_ZOMBIE]
        LANG.Msg("win_zombies", { role = plural })
        ServerLog("Result: " .. plural .. " win.\n")
        return true
    end
end

-----------
-- KARMA --
-----------

-- Reduce karma if a zombie hurts or kills an ally
local function Zombie_TTTKarmaShouldGivePenalty(attacker, victim)
    if attacker:IsZombie() then
        return victim:IsZombieAlly()
    end
end

------------
-- DAMAGE --
------------

local function Zombie_ScalePlayerDamage(ply, hitgroup, dmginfo)
    local att = dmginfo:GetAttacker()
    -- Only apply damage scaling after the round starts
    if IsPlayer(att) and GetRoundState() >= ROUND_ACTIVE then
        -- Monsters take less bullet damage
        if dmginfo:IsBulletDamage() and ply:IsZombie() then
            local reduction = zombie_damage_reduction:GetFloat()
            dmginfo:ScaleDamage(1 - reduction)
        end

        -- Zombies do less damage when using non-claw weapons
        if att:IsZombie() and att:GetActiveWeapon():GetClass() ~= "weapon_zom_claws" then
            local penalty = zombie_damage_penalty:GetFloat()
            dmginfo:ScaleDamage(1 - penalty)
        end
    end
end

-- Handle zombie team killing - this can be funny, but it can also be used by frustrated players who didn't appreciate being zombified
local function Zombie_EntityTakeDamage(ent, dmginfo)
    if GetRoundState() ~= ROUND_ACTIVE then return end
    if not IsPlayer(ent) or not ent:IsZombie() then return end

    local zombie_friendly_fire_mode = zombie_friendly_fire:GetInt()
    if zombie_friendly_fire_mode <= ZOMBIE_FF_MODE_NONE then return end

    local custom_damage = dmginfo:GetDamageCustom()
    -- If this is set, assume that we're the ones that set it and don't check this damage info
    if custom_damage == DMG_AIRBOAT then return end

    local att = dmginfo:GetAttacker()
    if not IsPlayer(att) or not att:IsZombieAlly() then return end

    -- Copy the original damage info and send it back on the attacker
    if zombie_friendly_fire_mode == ZOMBIE_FF_MODE_REFLECT then
        local infl = dmginfo:GetInflictor()
        if not IsValid(infl) then
            infl = game.GetWorld()
        end

        local newinfo = DamageInfo()
        -- Set this so that we can check for it since it is not normally used in GMod
        newinfo:SetDamageCustom(DMG_AIRBOAT)
        newinfo:SetDamage(dmginfo:GetDamage())
        newinfo:SetDamageType(dmginfo:GetDamageType())
        newinfo:SetAttacker(att)
        newinfo:SetInflictor(infl)
        newinfo:SetDamageForce(dmginfo:GetDamageForce())
        newinfo:SetDamagePosition(dmginfo:GetDamagePosition())
        newinfo:SetReportedPosition(dmginfo:GetReportedPosition())
        att:TakeDamageInfo(newinfo)
    end

    -- In either case, remove the damage
    -- This is used by both ZOMBIE_FF_MODE_REFLECT and ZOMBIE_FF_MODE_IMMUNE
    dmginfo:ScaleDamage(0)
    dmginfo:SetDamage(0)
end

-- Zombies don't take fall damage
local function Zombie_OnPlayerHitGround(ply, in_water, on_floater, speed)
    if ply:IsZombie() and GetRoundState() >= ROUND_ACTIVE then
        return true
    end
end

------------------
-- ROLE WEAPONS --
------------------

local zombie_color = Color(70, 100, 25, 255)

-- Make sure the zombie keeps their appropriate weapons and coloring
local function Zombie_TTTPlayerAliveThink(ply)
    if not IsValid(ply) or ply:IsSpec() or GetRoundState() ~= ROUND_ACTIVE then return end

    if ply:IsZombie() then
        if ply.GetActiveWeapon and IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "weapon_zom_claws" then
            ply.WasZombieColored = true
            ply:SetColor(zombie_color)
        elseif ply.WasZombieColored then
            ply.WasZombieColored = false
            ply:SetColor(COLOR_WHITE)
        end

        -- Strip all non-claw weapons for non-prime zombies if that feature is enabled
        -- Strip individual weapons instead of all because otherwise the player will have their claws added and removed constantly
        if zombie_prime_only_weapons:GetBool() and not ply:GetZombiePrime() then
            local weapons = ply:GetWeapons()
            for _, v in pairs(weapons) do
                local weapclass = WEPS.GetClass(v)
                if weapclass ~= "weapon_zom_claws" then
                    ply:StripWeapon(weapclass)
                end
            end
            ply:SetFOV(0, 0)
        end

        -- If this zombie doesn't have claws, give them claws
        if not ply:HasWeapon("weapon_zom_claws") then
            ply:Give("weapon_zom_claws")
        end
    elseif ply.WasZombieColored then
        ply.WasZombieColored = false
        ply:SetColor(COLOR_WHITE)
    end
end

-- Handle role weapon assignment
local function Zombie_PlayerLoadout(ply)
    if not IsPlayer(ply) or not ply:Alive() or ply:IsSpec() or not ply:IsZombie() or GetRoundState() ~= ROUND_ACTIVE then return end

    if not ply:HasWeapon("weapon_zom_claws") then
        ply:Give("weapon_zom_claws")
    end
end

-- Only allow the zombie to pick up zombie-specific weapons
local function Zombie_Weapons_PlayerCanPickupWeapon(ply, wep)
    if not IsValid(wep) or not IsValid(ply) then return end
    if ply:IsSpec() then return end

    if wep:GetClass() == "weapon_zom_claws" then
        return ply:IsZombie()
    end

    if zombie_prime_only_weapons:GetBool() and ply:IsZombie() and not ply:IsZombiePrime() and GetRoundState() == ROUND_ACTIVE then
        return false
    end
end

----------------
-- RESPAWNING --
----------------

function plymeta:RespawnAsZombie(prime)
    -- Let other roles or addons prevent zombie respawn
    if hook.Call("TTTCanRespawnAsRole", nil, self, ROLE_ZOMBIE) == false then return end

    self:QueueMessage(MSG_PRINTCENTER, "You will respawn as " .. ROLE_STRINGS_EXT[ROLE_ZOMBIE] .. " in 3 seconds.")
    self:SetNWBool("IsZombifying", true)

    net.Start("TTT_Zombified")
    net.WriteString(self:Nick())
    net.Broadcast()

    timer.Create("Zombify_" .. self:SteamID64(), 3, 1, function()
        -- Sanity check
        if not IsPlayer(self) then return end

        -- Don't respawn the player if they were already zombified by something else
        if not self:IsZombie() then
            local body = self.server_ragdoll or self:GetRagdollEntity()
            self:SetRole(ROLE_ZOMBIE)
            if type(prime) ~= "boolean" then
                prime = false
            end
            self:SetZombiePrime(prime)
            self:SpawnForRound(true)

            local health = zombie_respawn_health:GetInt()
            self:SetMaxHealth(health)
            self:SetHealth(health)

            -- Don't strip weapons if this player is allowed to keep them
            if not prime or not zombie_prime_only_weapons:GetBool() then
                self:StripAll()
            end
            self:Give("weapon_zom_claws")
            if IsValid(body) then
                self:SetPos(FindRespawnLocation(body:GetPos()) or body:GetPos())
                self:SetEyeAngles(Angle(0, body:GetAngles().y, 0))
                body:Remove()
            end
        end
        self:SetNWBool("IsZombifying", false)
        SendFullStateUpdate()
    end)
end

local function Zombie_TTTStopPlayerRespawning(ply)
    if not IsPlayer(ply) then return end
    if ply:Alive() then return end

    if ply:IsZombifying() then
        timer.Remove("Zombify_" .. ply:SteamID64())
        ply:SetNWBool("IsZombifying", false)
    end
end

local function Zombie_TTTCupidShouldLoverSurvive(ply, lover)
    if ply:IsZombifying() or lover:IsZombifying() then
        return true
    end
end

local function ShouldConvert(ply)
    local chance = ply:IsZombiePrime() and zombie_prime_convert_chance:GetFloat() or zombie_thrall_convert_chance:GetFloat()
    -- Use "less-than" so a chance of 0 really means never
    return math.random() < chance
end

local function Zombie_DoPlayerDeath(victim, attacker, dmginfo)
    if not IsPlayer(attacker) or not attacker:IsZombie() then return end
    if not ShouldConvert(attacker) then return end

    local inflictor = dmginfo:GetInflictor()
    if not IsValid(inflictor) or WEPS.GetClass(inflictor) ~= "weapon_zom_claws" then return end

    -- If they were killed by a normal slash attack or spit conversion is enabled and they were killed by spitting, convert them
    if (dmginfo:IsDamageType(DMG_SLASH) or (zombie_spit_convert:GetBool() and dmginfo:IsDamageType(DMG_BULLET))) and not attacker:IsRoleAbilityDisabled() then
        attacker:AddCredits(1)
        LANG.Msg(attacker, "credit_all", { role = ROLE_STRINGS[ROLE_ZOMBIE], num = 1 })
        hook.Call("TTTPlayerRoleChangedByItem", nil, attacker, victim, inflictor)
        victim:RespawnAsZombie()
    end
end

-----------------------
-- PLAYER VISIBILITY --
-----------------------

-- Add all players to the PVS for the zombie if highlighting or Kill icon are enabled
local function Zombie_SetupPlayerVisibility(ply)
    if not ply:ShouldBypassCulling() then return end
    if not ply:IsActiveZombie() then return end
    if not zombie_vision_enabled:GetBool() and not zombie_show_target_icon:GetBool() then return end

    -- Only use this when the zombie would see the highlighting and icons (when they have their claws out)
    local hasClaws = ply.GetActiveWeapon and IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "weapon_zom_claws"
    if not hasClaws then return end

    for _, v in PlayerIterator() do
        if ply:TestPVS(v) then continue end

        local pos = v:GetPos()
        if ply:IsOnScreen(pos) then
            AddOriginToPVS(pos)
        end
    end
end

------------------
-- REGISTRATION --
------------------

ROLE_REGISTER_HOOKS[ROLE_ZOMBIE] = function()
    AddHook("DoPlayerDeath", "Zombie_DoPlayerDeath", Zombie_DoPlayerDeath)
    AddHook("EntityTakeDamage", "Zombie_EntityTakeDamage", Zombie_EntityTakeDamage)
    AddHook("OnPlayerHitGround", "Zombie_OnPlayerHitGround", Zombie_OnPlayerHitGround)
    AddHook("PlayerCanPickupWeapon", "Zombie_Weapons_PlayerCanPickupWeapon", Zombie_Weapons_PlayerCanPickupWeapon)
    AddHook("PlayerDisconnected", "Zombie_Prime_PlayerDisconnected", Zombie_Prime_PlayerDisconnected)
    AddHook("PlayerLoadout", "Zombie_PlayerLoadout", Zombie_PlayerLoadout)
    AddHook("ScalePlayerDamage", "Zombie_ScalePlayerDamage", Zombie_ScalePlayerDamage)
    AddHook("SetupPlayerVisibility", "Zombie_SetupPlayerVisibility", Zombie_SetupPlayerVisibility)
    AddHook("TTTCheckForWin", "Zombie_TTTCheckForWin", Zombie_TTTCheckForWin)
    AddHook("TTTCupidShouldLoverSurvive", "Zombie_TTTCupidShouldLoverSurvive", Zombie_TTTCupidShouldLoverSurvive)
    AddHook("TTTKarmaShouldGivePenalty", "Zombie_TTTKarmaShouldGivePenalty", Zombie_TTTKarmaShouldGivePenalty)
    AddHook("TTTPlayerAliveThink", "Zombie_TTTPlayerAliveThink", Zombie_TTTPlayerAliveThink)
    AddHook("TTTPrintResultMessage", "Zombie_TTTPrintResultMessage", Zombie_TTTPrintResultMessage)
    AddHook("TTTStopPlayerRespawning", "Zombie_TTTStopPlayerRespawning", Zombie_TTTStopPlayerRespawning)
    AddHook("TTTWinCheckBlocks", "Zombie_TTTWinCheckBlocks", Zombie_TTTWinCheckBlocks)
end

ROLE_UNREGISTER_HOOKS[ROLE_ZOMBIE] = function()
    RemoveHook("DoPlayerDeath", "Zombie_DoPlayerDeath")
    RemoveHook("EntityTakeDamage", "Zombie_EntityTakeDamage")
    RemoveHook("OnPlayerHitGround", "Zombie_OnPlayerHitGround")
    RemoveHook("PlayerCanPickupWeapon", "Zombie_Weapons_PlayerCanPickupWeapon")
    RemoveHook("PlayerDisconnected", "Zombie_Prime_PlayerDisconnected")
    RemoveHook("PlayerLoadout", "Zombie_PlayerLoadout")
    RemoveHook("ScalePlayerDamage", "Zombie_ScalePlayerDamage")
    RemoveHook("SetupPlayerVisibility", "Zombie_SetupPlayerVisibility")
    RemoveHook("TTTCheckForWin", "Zombie_TTTCheckForWin")
    RemoveHook("TTTCupidShouldLoverSurvive", "Zombie_TTTCupidShouldLoverSurvive")
    RemoveHook("TTTKarmaShouldGivePenalty", "Zombie_TTTKarmaShouldGivePenalty")
    RemoveHook("TTTPlayerAliveThink", "Zombie_TTTPlayerAliveThink")
    RemoveHook("TTTPrintResultMessage", "Zombie_TTTPrintResultMessage")
    RemoveHook("TTTStopPlayerRespawning", "Zombie_TTTStopPlayerRespawning")
    RemoveHook("TTTWinCheckBlocks", "Zombie_TTTWinCheckBlocks")
end