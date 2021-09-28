-- serverside extensions to player table

local plymeta = FindMetaTable("Player")
if not plymeta then
    Error("FAILED TO FIND PLAYER TABLE")
    return
end

local entmeta = FindMetaTable("Entity")
if not entmeta then
    Error("FAILED TO FIND ENTITY TABLE")
    return
end

function plymeta:SetRagdollSpec(s)
    if s then
        self.spec_ragdoll_start = CurTime()
    end
    self.spec_ragdoll = s
end
function plymeta:GetRagdollSpec() return self.spec_ragdoll end

AccessorFunc(plymeta, "force_spec", "ForceSpec", FORCE_BOOL)

--- Karma

-- The base/start karma is determined once per round and determines the player's
-- damage penalty. It is networked and shown on clients.
function plymeta:SetBaseKarma(k)
    self:SetNWFloat("karma", k)
end

-- The live karma starts equal to the base karma, but is updated "live" as the
-- player damages/kills others. When another player damages/kills this one, the
-- live karma is used to determine his karma penalty.
AccessorFunc(plymeta, "live_karma", "LiveKarma", FORCE_NUMBER)

-- The damage factor scales how much damage the player deals, so if it is .9
-- then the player only deals 90% of his original damage.
AccessorFunc(plymeta, "dmg_factor", "DamageFactor", FORCE_NUMBER)

-- If a player does not damage team members in a round, he has a "clean" round
-- and gets a bonus for it.
AccessorFunc(plymeta, "clean_round", "CleanRound", FORCE_BOOL)

-- How many clean rounds in a row the player has gone
AccessorFunc(plymeta, "clean_rounds", "CleanRounds", FORCE_NUMBER)

function plymeta:SetZombiePrime(p) self:SetNWBool("zombie_prime", p) end

function plymeta:SetVampirePrime(p) self:SetNWBool("vampire_prime", p) end

function plymeta:SetVampirePreviousRole(r) self:SetNWInt("vampire_previous_role", r) end

function plymeta:InitKarma()
    KARMA.InitPlayer(self)
end

--- Equipment credits
function plymeta:SetCredits(amt)
    self.equipment_credits = amt
    self:SendCredits()
end

function plymeta:AddCredits(amt)
    self:SetCredits(self:GetCredits() + amt)
end
function plymeta:SubtractCredits(amt) self:AddCredits(-amt) end

function plymeta:SetDefaultCredits()
    if self:IsSpec() or self:GetRole() == ROLE_NONE then return end

    local c = 0
    local cvar = nil
    if self:IsTraitor() then
        cvar = "ttt_credits_starting"
    elseif self:IsDetective() then
        cvar = "ttt_det_credits_starting"
    else
        cvar = "ttt_" .. ROLE_STRINGS_RAW[self:GetRole()] .. "_credits_starting"
    end
    if ConVarExists(cvar) then
        c = GetConVar(cvar):GetInt()
    end

    if self:IsTraitorTeam() then
        if CountTraitors() == 1 then
            c = c + GetConVar("ttt_credits_alonebonus"):GetInt()
        end
    end

    self:SetCredits(c)
end

function plymeta:SendCredits()
    net.Start("TTT_Credits")
    net.WriteUInt(self:GetCredits(), 8)
    net.Send(self)
end

--- Equipment items
function plymeta:AddEquipmentItem(id)
    id = tonumber(id)
    if id then
        self.equipment_items = bit.bor(self.equipment_items, id)
        self:SendEquipment()
    end
end

-- We do this instead of an NW var in order to limit the info to just this ply
function plymeta:SendEquipment()
    net.Start("TTT_Equipment")
    net.WriteUInt(self.equipment_items, 32)
    net.Send(self)
end

function plymeta:ResetEquipment()
    self.equipment_items = EQUIP_NONE
    self:SendEquipment()
end

function plymeta:SendBought()
    -- Send all as string, even though equipment are numbers, for simplicity
    net.Start("TTT_Bought")
    net.WriteUInt(#self.bought, 8)
    for _, v in pairs(self.bought) do
        net.WriteString(v)
    end
    net.Send(self)
end

local function ResendBought(ply)
    if IsValid(ply) then ply:SendBought() end
end
concommand.Add("ttt_resend_bought", ResendBought)

function plymeta:ResetBought()
    self.bought = {}
    self:SendBought()
end

function plymeta:AddBought(id)
    if not self.bought then self.bought = {} end

    table.insert(self.bought, tostring(id))

    self:SendBought()
end

-- Strips player of all equipment
function plymeta:StripAll()
    -- standard stuff
    self:StripAmmo()
    self:StripWeapons()

    -- our stuff
    self:ResetEquipment()
    self:SetCredits(0)
end

-- Sets all flags (force_spec, etc) to their default
function plymeta:ResetStatus()
    self:SetRole(ROLE_INNOCENT)
    self:SetRagdollSpec(false)
    self:SetForceSpec(false)

    self:ResetRoundFlags()
end

-- Sets round-based misc flags to default position. Called at PlayerSpawn.
function plymeta:ResetRoundFlags()
    -- equipment
    self:ResetEquipment()
    self:SetCredits(0)

    self:ResetBought()

    -- equipment stuff
    self.bomb_wire = nil
    self.radar_charge = 0
    self.decoy = nil

    -- corpse
    self:SetNWBool("det_called", false)
    self:SetNWBool("body_found", false)
    self:SetNWBool("body_searched", false)

    self.kills = {}

    self.dying_wep = nil
    self.was_headshot = false

    -- communication
    self.mute_team = -1
    self.traitor_gvoice = false

    self:SetNWBool("disguised", false)
    -- If they had an "old model" that means they were disguised
    -- Reset their model back to what they used before they put the disguise on
    if self.oldmodel then
        entmeta.SetModel(self, self.oldmodel)
        self.oldmodel = nil
    end

    -- karma
    self:SetCleanRound(true)

    if not self:GetCleanRounds() then
        self:SetCleanRounds(1)
    end

    self:Freeze(false)
end

function plymeta:GiveEquipmentItem(id)
    if self:HasEquipmentItem(id) then
        return false
    elseif id and id > EQUIP_NONE then
        self:AddEquipmentItem(id)
        return true
    end
end

-- Forced specs and latejoin specs should not get points
function plymeta:ShouldScore()
    if self:GetForceSpec() then
        return false
    elseif self:IsSpec() and self:Alive() then
        return false
    else
        return true
    end
end

function plymeta:RecordKill(victim)
    if not IsValid(victim) then return end

    if not self.kills then
        self.kills = {}
    end

    table.insert(self.kills, victim:SteamID64())
end

function plymeta:SetSpeed(slowed)
    -- For player movement prediction to work properly, ply:SetSpeed turned out
    -- to be a bad idea. It now uses GM:SetupMove, and the TTTPlayerSpeedModifier
    -- hook is provided to let you change player speed without messing up
    -- prediction. It needs to be hooked on both client and server and return the
    -- same results (ie. same implementation).
    error "Player:SetSpeed has been removed - please remove this call and use the TTTPlayerSpeedModifier hook in both CLIENT and SERVER environments"
end

function plymeta:ResetLastWords()
    if not IsValid(self) then return end -- timers are dangerous things
    self.last_words_id = nil
end

function plymeta:SendLastWords(dmginfo)
    -- Use a pseudo unique id to prevent people from abusing the concmd
    self.last_words_id = math.floor(CurTime() + math.random(500))

    -- See if the damage was interesting
    local dtype = KILL_NORMAL
    if dmginfo:GetAttacker() == self or dmginfo:GetInflictor() == self then
        dtype = KILL_SUICIDE
    elseif dmginfo:IsDamageType(DMG_BURN) then
        dtype = KILL_BURN
    elseif dmginfo:IsFallDamage() then
        dtype = KILL_FALL
    end

    self.death_type = dtype

    net.Start("TTT_InterruptChat")
    net.WriteUInt(self.last_words_id, 32)
    net.Send(self)

    -- any longer than this and you're out of luck
    local ply = self
    timer.Simple(2, function() ply:ResetLastWords() end)
end

function plymeta:ResetViewRoll()
    local ang = self:EyeAngles()
    if ang.r ~= 0 then
        ang.r = 0
        self:SetEyeAngles(ang)
    end
end

function plymeta:ShouldSpawn()
    -- do not spawn players who have not been through initspawn
    if (not self:IsSpec()) and (not self:IsTerror()) then return false end
    -- do not spawn forced specs
    if self:IsSpec() and self:GetForceSpec() then return false end

    return true
end

-- Preps a player for a new round, spawning them if they should. If dead_only is
-- true, only spawns if player is dead, else just makes sure he is healed.
function plymeta:SpawnForRound(dead_only)
    hook.Call("PlayerSetModel", GAMEMODE, self)
    hook.Call("TTTPlayerSetColor", GAMEMODE, self)
    hook.Call("TTTPlayerSpawnForRound", GAMEMODE, self, dead_only)

    -- Workaround to prevent GMod sprint from working
    self:SetRunSpeed(self:GetWalkSpeed())

    -- wrong alive status and not a willing spec who unforced after prep started
    -- (and will therefore be "alive")
    if dead_only and self:Alive() and (not self:IsSpec()) then
        -- if the player does not need respawn, make sure he has full health
        self:SetHealth(self:GetMaxHealth())
        return false
    end

    if not self:ShouldSpawn() then return false end

    -- reset propspec state that they may have gotten during prep
    PROPSPEC.Clear(self)

    -- respawn anyone else
    if self:Team() == TEAM_SPEC then
        self:UnSpectate()
    end

    self:StripAll()
    self:SetTeam(TEAM_TERROR)
    -- Disable Phantom haunting
    self:SetNWBool("Haunting", false)
    self:SetNWString("HauntingTarget", nil)
    self:SetNWInt("HauntingPower", 0)
    timer.Remove(self:Nick() .. "HauntingPower")
    timer.Remove(self:Nick() .. "HauntingSpectate")
    -- Disable Killer smoke
    self:SetNWBool("KillerSmoke", false)
    -- Disable Parasite infection
    self:SetNWBool("Infecting", false)
    self:SetNWString("InfectingTarget", nil)
    self:SetNWInt("InfectionProgress", 0)
    timer.Remove(self:Nick() .. "InfectionProgress")
    timer.Remove(self:Nick() .. "InfectingSpectate")

    -- If this player was dead, mark them as being in the process of being resurrected
    if dead_only then
        self.Resurrecting = true
    end

    self:Spawn()

    -- If a dead player was spawned outside of the round start, broadcast the defib event
    if dead_only then
        net.Start("TTT_Defibrillated")
        net.WriteString(self:Nick())
        net.Broadcast()

        SetRoleHealth(self)
    end

    -- Make sure players who are respawning get their default weapons
    timer.Simple(1, function()
        if not self:HasWeapon("weapon_ttt_unarmed") then
            self:Give("weapon_ttt_unarmed")
        end
        if not self:HasWeapon("weapon_zm_carry") then
            self:Give("weapon_zm_carry")
        end
        if not self:HasWeapon("weapon_zm_improvised") then
            self:Give("weapon_zm_improvised")
        end
    end)

    -- tell caller that we spawned
    return true
end

function plymeta:InitialSpawn()
    self.has_spawned = false

    -- The team the player spawns on depends on the round state
    self:SetTeam(GetRoundState() == ROUND_PREP and TEAM_TERROR or TEAM_SPEC)

    -- Change some gmod defaults
    self:SetCanZoom(false)
    self:SetJumpPower(160)
    self:SetCrouchedWalkSpeed(0.3)
    self:SetRunSpeed(220)
    self:SetWalkSpeed(220)
    self:SetMaxSpeed(220)

    -- Always spawn innocent initially, traitor will be selected later
    self:ResetStatus()

    -- Start off with clean, full karma (unless it can and should be loaded)
    self:InitKarma()

    -- We never have weapons here, but this inits our equipment state
    self:StripAll()
end

function plymeta:KickBan(length, reason)
    -- see admin.lua
    PerformKickBan(self, length, reason)
end

local function GetInnocentTeamDrunkExcludes()
    -- Exclude detectives from the innocent list
    local excludes = table.Copy(DETECTIVE_ROLES)
    -- Also exclude the trickster if there are no traitor buttons
    if #ents.FindByClass("ttt_traitor_button") == 0 then
        excludes[ROLE_TRICKSTER] = true
    end

    -- Always exclude the glitch because a glitch suddenly appearing
    -- in the middle of a round makes it obvious who is not a real traitor
    excludes[ROLE_GLITCH] = true

    return excludes
end

local function GetIndependentTeamDrunkExcludes()
    -- Exclude the drunk since they already are one
    local excludes = {}
    excludes[ROLE_DRUNK] = true
    -- Also exclude the mad scientist if zombies aren't independent (same as spawning logic)
    if not INDEPENDENT_ROLES[ROLE_ZOMBIE] then
        excludes[ROLE_MADSCIENTIST] = true
    end
    return excludes
end

function plymeta:SoberDrunk(team)
    if not self:IsActiveDrunk() then return false end

    local role = nil
    -- If any role is allowed
    if GetConVar("ttt_drunk_any_role"):GetBool() then
        local role_options = {}
        -- Get the role options by team, if one was given
        if team then
            if team == ROLE_TEAM_TRAITOR then
                role_options = GetTeamRoles(TRAITOR_ROLES)
            elseif team == ROLE_TEAM_INNOCENT then
                role_options = GetTeamRoles(INNOCENT_ROLES, GetInnocentTeamDrunkExcludes())
            elseif team == ROLE_TEAM_JESTER then
                role_options = GetTeamRoles(JESTER_ROLES)
            elseif team == ROLE_TEAM_INDEPENDENT then
                role_options = GetTeamRoles(INDEPENDENT_ROLES, GetIndependentTeamDrunkExcludes())
            elseif team == ROLE_TEAM_MONSTER then
                role_options = GetTeamRoles(MONSTER_ROLES)
            elseif team == ROLE_TEAM_DETECTIVE then
                role_options = GetTeamRoles(DETECTIVE_ROLES)
            end
        -- Or build a list of the options based on what team is randomly chosen (innocent vs. everything else)
        else
            if math.random() <= GetConVar("ttt_drunk_innocent_chance"):GetFloat() then
                role_options = GetTeamRoles(INNOCENT_ROLES, GetInnocentTeamDrunkExcludes())
            else
                local excludes = GetIndependentTeamDrunkExcludes()
                -- Add every non-innocent role (except those that are excluded)
                for r = 0, ROLE_MAX do
                    if not INNOCENT_ROLES[r] and not excludes[r] then
                        table.insert(role_options, r)
                    end
                end
            end
        end

        -- If there are role options, remove any that shouldn't be used
        if #role_options > 0 then
            -- Remove any used roles
            for _, p in ipairs(player.GetAll()) do
                if p:IsCustom() then
                    table.RemoveByValue(role_options, p:GetRole())
                end
            end

            -- Keep track of which ones are explicitly allowed because removing from tables that you are iterating over causes the iteration to skip elements
            local allowed_options = {}

            -- Remove any roles that are not enabled or allowed
            for _, r in ipairs(role_options) do
                local rolestring = ROLE_STRINGS_RAW[r]
                if GetConVar("ttt_drunk_can_be_" .. rolestring):GetBool() and (DEFAULT_ROLES[r] or GetConVar("ttt_" .. rolestring .. "_enabled"):GetBool()) then
                    table.insert(allowed_options, r)
                end
            end

            role_options = allowed_options
        end

        -- Choose one of the roles, if there are any
        if #role_options > 0 then
            role = role_options[math.random(1, #role_options)]
        end
    end

    -- If a role hasn't already been chosen, fall back to the either-or logic
    if not role then
        -- If a team is given, use it to choose one of the basic options
        if team then
            role = team == ROLE_TEAM_TRAITOR and ROLE_TRAITOR or ROLE_INNOCENT
        -- If not, use randomization
        elseif math.random() <= GetConVar("ttt_drunk_innocent_chance"):GetFloat() then
            role = ROLE_INNOCENT
        else
            role = ROLE_TRAITOR
        end
    end

    self:DrunkRememberRole(role)
    return true
end

function plymeta:DrunkRememberRole(role, hidecenter)
    if not self:IsActiveDrunk() then return false end

    self:SetNWBool("WasDrunk", true)
    self:SetRole(role)
    self:PrintMessage(HUD_PRINTTALK, "You have remembered that you are " .. ROLE_STRINGS_EXT[role] .. ".")
    if not hidecenter then self:PrintMessage(HUD_PRINTCENTER, "You have remembered that you are " .. ROLE_STRINGS_EXT[role] .. ".") end
    self:SetDefaultCredits()

    local mode = GetConVar("ttt_drunk_notify_mode"):GetInt()
    if mode > 0 then
        for _, v in pairs(player.GetAll()) do
            if self ~= v then
                if (v:IsTraitorTeam() and (mode == JESTER_NOTIFY_DETECTIVE_AND_TRAITOR or mode == JESTER_NOTIFY_TRAITOR)) or -- the enums here are the same as for the jester notifications so we can just use those
                        (v:IsDetectiveLike() and (mode == JESTER_NOTIFY_DETECTIVE_AND_TRAITOR or mode == JESTER_NOTIFY_DETECTIVE)) or
                        mode == JESTER_NOTIFY_EVERYONE then
                    v:PrintMessage(HUD_PRINTTALK, ROLE_STRINGS_EXT[ROLE_DRUNK] .. " has remembered their role.")
                end
            end
        end
    end

    -- Update role health
    SetRoleMaxHealth(self)
    if self:Health() > self:GetMaxHealth() then
        self:SetHealth(self:GetMaxHealth())
    end

    -- Start role special logic checks
    self:BeginRoleChecks()

    -- Give loadout weapons
    hook.Run("PlayerLoadout", self)

    net.Start("TTT_DrunkSober")
    net.WriteString(self:Nick())
    net.WriteString(ROLE_STRINGS_EXT[role])
    net.Broadcast()

    SendFullStateUpdate()
    return true
end

function plymeta:BeginRoleChecks()
    -- Revenger logic
    if self:IsRevenger() then
        local potentialSoulmates = {}
        for _, p in pairs(player.GetAll()) do
            if p:Alive() and not p:IsSpec() and p ~= self then
                table.insert(potentialSoulmates, p)
            end
        end
        if #potentialSoulmates > 0 then
            local revenger_lover = potentialSoulmates[math.random(#potentialSoulmates)]
            self:SetNWString("RevengerLover", revenger_lover:SteamID64() or "")
            self:PrintMessage(HUD_PRINTTALK, "You are in love with " .. revenger_lover:Nick() .. ".")
            self:PrintMessage(HUD_PRINTCENTER, "You are in love with " .. revenger_lover:Nick() .. ".")
        end

        local drain_health = GetConVar("ttt_revenger_drain_health_to"):GetInt()
        if drain_health >= 0 then
            timer.Create("revengerhealthdrain", 3, 0, function()
                for _, p in pairs(player.GetAll()) do
                    local lover_sid = p:GetNWString("RevengerLover", "")
                    if p:IsActiveRevenger() and lover_sid ~= "" then
                        local lover = player.GetBySteamID64(lover_sid)
                        if IsValid(lover) and (not lover:Alive() or lover:IsSpec()) then
                            local hp = p:Health()
                            if hp > drain_health then
                                -- We were going to set them to 0, so just kill them instead
                                if hp == 1 then
                                    p:PrintMessage(HUD_PRINTTALK, "You have succumbed to the heartache of losing your lover.")
                                    p:PrintMessage(HUD_PRINTCENTER, "You have succumbed to the heartache of losing your lover.")
                                    p:Kill()
                                else
                                    p:SetHealth(hp - 1)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end

    -- Drunk logic
    if self:IsDrunk() then
        SetGlobalFloat("ttt_drunk_remember", CurTime() + GetConVar("ttt_drunk_sober_time"):GetInt())
        timer.Create("drunkremember", GetConVar("ttt_drunk_sober_time"):GetInt(), 1, function()
            for _, p in pairs(player.GetAll()) do
                if p:IsActiveDrunk() then
                    p:SoberDrunk()
                elseif p:IsDrunk() and not p:Alive() and not timer.Exists("waitfordrunkrespawn") then
                    timer.Create("waitfordrunkrespawn", 0.1, 0, function()
                        local dead_drunk = false
                        for _, p2 in pairs(player.GetAll()) do
                            if p2:IsActiveDrunk() then
                                p2:SoberDrunk()
                            elseif p2:IsDrunk() and not p2:Alive() then
                                dead_drunk = true
                            end
                        end
                        if timer.Exists("waitfordrunkrespawn") and not dead_drunk then timer.Remove("waitfordrunkrespawn") end
                    end)
                end
            end
        end)
    end

    -- Old Man logic
    local oldman_drain_health = GetConVar("ttt_oldman_drain_health_to"):GetInt()
    if self:IsOldMan() and oldman_drain_health > 0 then
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

    -- Assassin logic
    if self:IsAssassin() then
        AssignAssassinTarget(self, true, false)
    end

    -- Killer logic
    if self:IsKiller() then
        if GetConVar("ttt_killer_knife_enabled"):GetBool() then
            self:Give("weapon_kil_knife")
        end
        if GetConVar("ttt_killer_crowbar_enabled"):GetBool() then
            self:StripWeapon("weapon_zm_improvised")
            self:Give("weapon_kil_crowbar")
            self:SelectWeapon("weapon_kil_crowbar")
        end
    end

    -- Glitch logic
    if self:IsGlitch() then
        SetGlobalBool("ttt_glitch_round", true)
    end

    -- Deputy/Impersonator logic
    -- If this is a promotable role and they should be promoted, promote them immediately
    -- The logic which handles a detective dying is in the PlayerDeath hook
    if self:IsDetectiveLikePromotable() and ShouldPromoteDetectiveLike() then
        self:HandleDetectiveLikePromotion()
    end
end

function plymeta:GiveDelayedShopItems()
    for _, item_id in ipairs(self.bought) do
        local id_num = tonumber(item_id)
        local isequip = id_num and 1 or 0

        -- Give the item to the player
        if id_num then
            self:GiveEquipmentItem(id_num)
        else
            self:Give(item_id)
            local wep = weapons.GetStored(item_id)
            if wep and wep.WasBought then
                wep:WasBought(self)
            end
        end

        -- Also let them know they bought this item "again" so hooks are called
        -- NOTE: The net event and the give action cannot be done at the same time because GiveEquipmentItem calls its own net event which causes an error
        net.Start("TTT_BoughtItem")
        net.WriteBit(isequip)
        if id_num then
            net.WriteInt(id_num, 32)
        else
            net.WriteString(item_id)
        end
        net.Send(self)
    end
end

local oldSpectate = plymeta.Spectate
function plymeta:Spectate(type)
    oldSpectate(self, type)

    -- NPCs should never see spectators. A workaround for the fact that gmod NPCs
    -- do not ignore them by default.
    self:SetNoTarget(true)

    if type == OBS_MODE_ROAMING then
        self:SetMoveType(MOVETYPE_NOCLIP)
    end
end

local oldSpectateEntity = plymeta.SpectateEntity
function plymeta:SpectateEntity(ent)
    oldSpectateEntity(self, ent)

    if IsPlayer(ent) then
        self:SetupHands(ent)
    end
end

local oldUnSpectate = plymeta.UnSpectate
function plymeta:UnSpectate()
    oldUnSpectate(self)
    self:SetNoTarget(false)
end

local oldSetTeam = plymeta.SetTeam
function plymeta:SetTeam(team)
    oldSetTeam(self, team)

    -- If this player is a Spectator then strip all the weapons after a delay to work around some addons that force spectator but leave the magneto stick somehow
    if team == TEAM_SPEC then
        timer.Simple(0.5, function()
            if not IsValid(self) or self:Team() ~= TEAM_SPEC then return end
            self:StripAll()
        end)
    end
end

function plymeta:GetAvoidDetective()
    return self:GetInfoNum("ttt_avoid_detective", 0) > 0
end

function plymeta:Ignite(dur, radius)
    -- Keep track of extended ignition information so when multiple things are causing burning the later ones don't lose their data. See PlayerTakeDamage in player.lua
    self.ignite_info_ext = {dur = dur, end_time = CurTime() + dur}
    entmeta.Ignite(self, dur, radius)
end

-- Run these overrides when the round is preparing the first time to ensure their addons have been loaded
hook.Add("TTTPrepareRound", "PostLoadOverride", function()
    -- Compatibility with Dead Ringer (810154456)
    if plymeta.DRuncloak then
        local oldDRuncloak = plymeta.DRuncloak
        -- Handle clearing search and corpse data when a Dead Ringer'd player uncloaks
        function plymeta:DRuncloak()
            self:SetNWBool("body_searched", false)
            self:SetNWBool("det_called", false)
            oldDRuncloak(self)

            net.Start("TTT_RemoveCorpseCall")
            -- Must be SteamID for Dead Ringer compatibility
            net.WriteString(self:SteamID())
            net.Broadcast()
        end
    end

    -- These overrides are set, no reason to check every round
    hook.Remove("TTTPrepareRound", "PostLoadOverride")
end)
