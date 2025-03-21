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

local concommand = concommand
local hook = hook
local ipairs = ipairs
local IsValid = IsValid
local math = math
local net = net
local pairs = pairs
local table = table
local timer = timer
local weapons = weapons

local CallHook = hook.Call

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
-- live karma is used to determine their karma penalty.
AccessorFunc(plymeta, "live_karma", "LiveKarma", FORCE_NUMBER)

-- The damage factor scales how much damage the player deals, so if it is .9
-- then the player only deals 90% of their original damage.
AccessorFunc(plymeta, "dmg_factor", "DamageFactor", FORCE_NUMBER)

-- If a player does not damage team members in a round, they have a "clean" round
-- and gets a bonus for it.
AccessorFunc(plymeta, "clean_round", "CleanRound", FORCE_BOOL)

-- How many clean rounds in a row the player has gone
AccessorFunc(plymeta, "clean_rounds", "CleanRounds", FORCE_NUMBER)

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
    CallHook("TTTPlayerCreditsChanged", nil, self, amt)
end
function plymeta:SubtractCredits(amt) self:AddCredits(-amt) end

function plymeta:SetDefaultCredits(keep_existing)
    if self:IsSpec() or self:GetRole() == ROLE_NONE then return end

    local cvar
    if self:IsTraitor() then
        cvar = "ttt_credits_starting"
    elseif self:IsDetective() then
        cvar = "ttt_det_credits_starting"
    else
        cvar = "ttt_" .. ROLE_STRINGS_RAW[self:GetRole()] .. "_credits_starting"
    end

    local c = cvars.Number(cvar, 0)
    if self:IsTraitorTeam() and CountTraitors() == 1 then
        c = c + GetConVar("ttt_credits_alonebonus"):GetInt()
    end

    if not keep_existing then
        self:SetCredits(c)
    else
        self:AddCredits(c)
    end
end

function plymeta:SendCredits()
    net.Start("TTT_Credits")
    net.WriteUInt(self:GetCredits(), 8)
    net.Send(self)
end

--- Equipment items
function plymeta:AddEquipmentItem(id)
    id = tonumber(id)
    if id and not table.HasValue(self.equipment_items, id) then
        table.insert(self.equipment_items, id)
        self:SendEquipment()
    end
end

function plymeta:RemoveEquipmentItem(id)
    id = tonumber(id)
    if id and table.RemoveByValue(self.equipment_items, id) then
        -- Reset the indexes of the table
        self.equipment_items = table.ClearKeys(self.equipment_items)
        self:SendEquipment()
    end
end

-- We do this instead of an NW var in order to limit the info to just this ply
function plymeta:SendEquipment()
    net.Start("TTT_Equipment")
    net.WriteUInt(#self.equipment_items, 8)
    for _, v in ipairs(self.equipment_items) do
        net.WriteUInt(v, 8)
    end
    net.Send(self)
end

function plymeta:ResetEquipment()
    self.equipment_items = {}
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

    -- Change some gmod defaults
    self:SetCanZoom(false)
    self:SetJumpPower(160)
    self:SetCrouchedWalkSpeed(0.3)
    self:SetRunSpeed(220)
    self:SetWalkSpeed(220)
    self:SetMaxSpeed(220)

    -- equipment stuff
    self.bomb_wire = nil
    self.radar_charge = 0
    self.decoy = nil

    -- corpse
    self:SetNWBool("det_called", false)
    self:SetNWBool("body_found", false)
    self:SetNWBool("body_searched", false)
    self:ClearProperty("body_found_role")
    self:SetNWBool("body_searched_det", false)

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
    -- Backwards compatibility for addons that call GetEquipmentItems and pass the result in here
    if id and istable(id) then
        local result = true
        for _, e in pairs(id) do
            result = result and self:GiveEquipmentItem(e)
        end
        return result
    end

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
-- true, only spawns if player is dead, else just makes sure they are healed.
function plymeta:SpawnForRound(dead_only)
    CallHook("PlayerSetModel", GAMEMODE, self)
    CallHook("TTTPlayerSetColor", GAMEMODE, self)
    CallHook("TTTPlayerSpawnForRound", GAMEMODE, self, dead_only)

    -- Workaround to prevent GMod sprint from working
    self:SetRunSpeed(self:GetWalkSpeed())

    -- wrong alive status and not a willing spec who unforced after prep started
    -- (and will therefore be "alive")
    if dead_only and self:Alive() and (not self:IsSpec()) then
        -- if the player does not need respawn, make sure they have full health
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

        -- Clear all search information for this resurrected player
        self:SetNWBool("det_called", false)
        self:SetNWBool("body_found", false)
        self:ClearProperty("body_found_role")
        self:SetNWBool("body_searched", false)
        self:SetNWBool("body_searched_det", false)

        net.Start("TTT_ClearSearchResult")
        net.WritePlayer(self)
        net.Broadcast()

        SetRoleHealth(self)
    end

    -- Make sure players who are respawning get their default weapons
    timer.Simple(1, function()
        if not IsPlayer(self) then return end

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

    -- Always spawn innocent initially, traitor will be selected later
    self:ResetStatus()

    -- Start off with clean, full karma (unless it can and should be loaded)
    self:InitKarma()

    -- We never have weapons here, but this inits our equipment state
    self:StripAll()

    -- If round prep has started, call SpawnForRound on the player so all the same logic
    -- that has been ran against the other players is run against this new player as well
    if GetRoundState() == ROUND_PREP then
        self:SpawnForRound(false)
    end
end

function plymeta:KickBan(length, reason)
    -- see admin.lua
    PerformKickBan(self, length, reason)
end

function plymeta:BeginRoleChecks()
    -- Run role-specific logic
    if ROLE_ON_ROLE_ASSIGNED[self:GetRole()] then
        ROLE_ON_ROLE_ASSIGNED[self:GetRole()](self)
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
            net.WriteUInt(id_num, 32)
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
    self:SetRagdollSpec(false)
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
plymeta.ShouldAvoidDetective = plymeta.GetAvoidDetective

function plymeta:GetBypassCulling()
    return self:GetInfoNum("ttt_bypass_culling", 1) > 0
end
plymeta.ShouldBypassCulling = plymeta.GetBypassCulling

function plymeta:Ignite(dur, radius)
    -- Keep track of extended ignition information so when multiple things are causing burning the later ones don't lose their data. See PlayerTakeDamage in player.lua
    self.ignite_info_ext = {dur = dur, end_time = CurTime() + dur}
    entmeta.Ignite(self, dur, radius)
end

local player_view_offsets = {}
local player_view_offsets_ducked = {}
function plymeta:SetPlayerScale(scale)
    self:SetStepSize(self:GetStepSize() * scale)
    self:SetModelScale(self:GetModelScale() * scale, 1)

    -- Save the original values
    local sid = self:SteamID64()
    if not player_view_offsets[sid] then
        player_view_offsets[sid] = self:GetViewOffset()
    end
    if not player_view_offsets_ducked[sid] then
        player_view_offsets_ducked[sid] = self:GetViewOffsetDucked()
    end

    -- Use the current, not the saved, values so that this can run multiple times (in theory)
    self:SetViewOffset(self:GetViewOffset()*scale)
    self:SetViewOffsetDucked(self:GetViewOffsetDucked()*scale)

    local a, b = self:GetHull()
    self:SetHull(a * scale, b * scale)

    a, b = self:GetHullDuck()
    self:SetHullDuck(a * scale, b * scale)
end

function plymeta:ResetPlayerScale()
    self:SetModelScale(1, 1)

    -- Retrieve the saved offsets
    local offset = nil
    local sid = self:SteamID64()
    if player_view_offsets[sid] then
        offset = player_view_offsets[sid]
        player_view_offsets[sid] = nil
    end
    -- Reset the view offset to the saved value or the default (if the ec_ViewChanged is not set)
    -- The "ec_ViewChanged" property is from the "Enhanced Camera" mod which use ViewOffset to make the camera more "realistic"
    if offset or not self.ec_ViewChanged then
        self:SetViewOffset(offset or Vector(0, 0, 64))
    end

    -- Retrieve the saved ducked offsets
    local offset_ducked = nil
    if player_view_offsets_ducked[sid] then
        offset_ducked = player_view_offsets_ducked[sid]
        player_view_offsets_ducked[sid] = nil
    end
    -- Reset the view offset to the saved value or the default (if the ec_ViewChanged is not set)
    -- The "ec_ViewChanged" property is from the "Enhanced Camera" mod which use ViewOffset to make the camera more "realistic"
    if offset_ducked or not self.ec_ViewChanged then
        self:SetViewOffsetDucked(offset_ducked or Vector(0, 0, 28))
    end
    self:ResetHull()
    self:SetStepSize(18)
end

local messageQueue = {}

function plymeta:PrintMessageQueue()
    local sid = self:SteamID64()

    if not messageQueue[sid] or #messageQueue[sid] == 0 then
        self:PrintMessage(HUD_PRINTCENTER, "")
        return
    end

    local message = messageQueue[sid][1]
    -- Send this message as long as there is no predicate or it says this player is valid
    if not message.predicate or message.predicate(self) then
        self:PrintMessage(HUD_PRINTCENTER, message.message)
    else
        table.remove(messageQueue[sid], 1)
        self:PrintMessageQueue()
        return
    end
    if message.time <= 5 then
        timer.Create("MessageQueue" .. sid, message.time, 1, function()
            table.remove(messageQueue[sid], 1)
            self:PrintMessageQueue()
        end)
    else
        timer.Create("MessageQueue" .. sid, 5, 1, function()
            messageQueue[sid][1].time = messageQueue[sid][1].time - 5
            self:PrintMessageQueue()
        end)
    end
end

function plymeta:ResetMessageQueue()
    local sid = self:SteamID64()
    messageQueue[sid] = {}
    timer.Remove("MessageQueue" .. sid)
    self:PrintMessage(HUD_PRINTCENTER, "")
end

function plymeta:QueueMessage(message_type, message, time, id, predicate)
    time = time or 5
    if type(id) == "function" and predicate == nil then
        predicate = id
        id = nil
    end

    local sid = self:SteamID64()
    if not messageQueue[sid] then
        messageQueue[sid] = {}
    end
    -- Send this message as long as its a chat-based message and there is no predicate or it says this player is valid
    if (message_type == MSG_PRINTBOTH or message_type == MSG_PRINTTALK) and (not predicate or predicate(self)) then
        self:PrintMessage(HUD_PRINTTALK, message)
    end
    if message_type == MSG_PRINTBOTH or message_type == MSG_PRINTCENTER then
        table.insert(messageQueue[sid], {message=message, time=time, predicate=predicate, id=id})
        if #messageQueue[sid] == 1 and not timer.Exists("MessageQueue" .. sid) then
            self:PrintMessageQueue()
        end
    end
end

net.Receive("TTT_QueueMessage", function(len, ply)
    local message_type = net.ReadUInt(3)
    local message = net.ReadString()
    local time = net.ReadFloat()
    local id = net.ReadString()
    if #id == 0 then
        id = nil
    end
    ply:QueueMessage(message_type, message, time, id)
end)

function plymeta:ClearQueuedMessage(id)
    local sid = self:SteamID64()

    local skipCurrent = false
    if messageQueue[sid] then
        if messageQueue[sid][1] and messageQueue[sid][1].id == id then
            skipCurrent = true
        end

        local i = 1
        while i <= #messageQueue[sid] do
            if messageQueue[sid][i].id == id then
                table.remove(messageQueue[sid], i)
            else
                i = i + 1
            end
        end
    end

    if skipCurrent then
        timer.Remove("MessageQueue" .. sid)
        self:PrintMessageQueue()
    end
end

net.Receive("TTT_ClearQueuedMessage", function(len, ply)
    local id = net.ReadString()
    ply:ClearQueuedMessage(id)
end)

function plymeta:ForceRoleNextRound(role)
    if self.forcedRole and self.forcedRole ~= ROLE_NONE then
        return false
    end
    self.forcedRole = role
    return true
end

function plymeta:GetForcedRole()
    if self.forcedRole and self.forcedRole ~= ROLE_NONE then
        return self.forcedRole
    end
    return false
end

function plymeta:ClearForcedRole()
    self.forcedRole = ROLE_NONE
end

function plymeta:SetInvulnerable(invulnerable, play_sound)
    self:SetNWBool("CRTTT_Invulnerable", invulnerable)
    if play_sound then
        self:EmitSound(invulnerable and "invulnerablestart.wav" or "invulnerableend.wav")
    end
end

function plymeta:SetProperty(name, value, targets)
    SYNC:SetPlayerProperty(self, name, value, targets)
end

function plymeta:ClearProperty(name, targets)
    SYNC:ClearPlayerProperty(self, name, targets)
end

-- Run these overrides when the round is preparing the first time to ensure their addons have been loaded
hook.Add("TTTPrepareRound", "PostLoadOverride", function()
    -- Compatibility with Dead Ringer (810154456)
    if plymeta.DRuncloak then
        local oldDRuncloak = plymeta.DRuncloak
        -- Handle clearing search and corpse data when a Dead Ringer'd player uncloaks
        function plymeta:DRuncloak()
            self:SetNWBool("det_called", false)
            self:SetNWBool("body_found", false)
            self:SetNWBool("body_searched", false)
            self:ClearProperty("body_found_role")
            self:SetNWBool("body_searched_det", false)
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
