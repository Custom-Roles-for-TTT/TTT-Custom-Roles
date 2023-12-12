---- Corpse functions

-- namespaced because we have no ragdoll metatable
CORPSE = {}

include("corpse_shd.lua")

local concommand = concommand
local hook = hook
local math = math
local net = net
local pairs = pairs
local player = player
local table = table
local timer = timer
local util = util

local CreateEntity = ents.Create

--- networked data abstraction layer
local dti = CORPSE.dti

function CORPSE.SetFound(rag, state)
    --rag:SetNWBool("found", state)
    rag:SetDTBool(dti.BOOL_FOUND, state)
end

function CORPSE.SetPlayerNick(rag, ply_or_name)
    -- don't have datatable strings, so use a dt entity for common case of
    -- still-connected player, and if the player is gone, fall back to nw string
    local name = ply_or_name
    if IsValid(ply_or_name) then
        name = ply_or_name:Nick()
        rag:SetDTEntity(dti.ENT_PLAYER, ply_or_name)
    end

    rag:SetNWString("nick", name)
end

function CORPSE.SetCredits(rag, credits)
    --rag:SetNWInt("credits", credits)
    rag:SetDTInt(dti.INT_CREDITS, credits)
end


--- ragdoll creation and search

-- If detective mode, announce when someone's body is found
local bodyfound = CreateConVar("ttt_announce_body_found", "1")

local function AnnounceBodyName(p, round_state)
    if round_state ~= ROUND_ACTIVE then return true end

    -- If only detectives can search, only announce if this player is a detective
    if GetConVar("ttt_detectives_search_only"):GetBool() then return p:IsDetectiveLike() end
    -- If only detectives can see the name, only announce if this player is a detective
    if GetConVar("ttt_detectives_search_only_nick"):GetBool() then return p:IsDetectiveLike() end
    -- Otherwise everyone can see it
    return true
end

local function AnnounceBodyRole(p, round_state)
    if round_state ~= ROUND_ACTIVE then return true end

    -- If only detectives can search, only announce if this player is a detective
    if GetConVar("ttt_detectives_search_only"):GetBool() then return p:IsDetectiveLike() end
    -- If only detectives can see the role, only announce if this player is a detective
    if GetConVar("ttt_detectives_search_only_role"):GetBool() then return p:IsDetectiveLike() end
    -- Otherwise everyone can see it
    return true
end

local function AnnounceBodyTeam(p, round_state)
    if round_state ~= ROUND_ACTIVE then return true end

    -- If only detectives can search, only announce if this player is a detective
    if GetConVar("ttt_detectives_search_only"):GetBool() then return p:IsDetectiveLike() end
    -- If only detectives can see the team, only announce if this player is a detective
    if GetConVar("ttt_detectives_search_only_team"):GetBool() then return p:IsDetectiveLike() end
    -- Otherwise everyone can see it
    return true
end

function GM:TTTCanIdentifyCorpse(ply, corpse, was_traitor)
    -- return true to allow corpse identification, false to disallow
    return true
end

local function IdentifyBody(ply, rag)
    if not ply:IsTerror() then return end

    -- simplified case for those who die and get found during prep
    local round_state = GetRoundState()
    if round_state == ROUND_PREP then
        CORPSE.SetFound(rag, true)
        return
    end

    if not hook.Run("TTTCanIdentifyCorpse", ply, rag, TRAITOR_ROLES[rag.was_role]) then
        return
    end

    -- do this after the hook in case it wants to change some of that data
    local role = rag.was_role
    local finder = ply:Nick()
    local nick = CORPSE.GetPlayerNick(rag, "")

    -- will return either false or a valid ply
    local deadply = player.GetBySteamID64(rag.sid64) or player.GetBySteamID(rag.sid)

    -- Announce body
    local announceName = AnnounceBodyName(ply, round_state)
    if bodyfound:GetBool() and not CORPSE.GetFound(rag, false) and (not IsValid(deadply) or announceName or not deadply:GetNWBool("body_found", false)) then
        local name = "someone"
        if announceName then
            name = nick
        end
        local role_string = "an unknown role"
        if AnnounceBodyRole(ply, round_state) then
            role_string = ROLE_STRINGS_EXT[role]
        elseif AnnounceBodyTeam(ply, round_state) then
            local roleTeam = player.GetRoleTeam(role)
            local teamName = GetRoleTeamName(roleTeam)
            role_string = "on the " .. teamName .. " team"
        end

        LANG.Msg("body_found", {
            finder = finder,
            victim = name,
            role = role_string
        })
    end

    -- Register find
    if not CORPSE.GetFound(rag, false) then
        if IsValid(deadply) then
            -- Only reveal that this body was searched and found if they were searched by someone who can know its name
            -- Otherwise the scoreboard gets updated which reveals their name anyway
            if announceName then
                deadply:SetNWBool("body_found", true)
                deadply:SetNWBool("body_searched", true)
            end
            -- Keep track if this body was searched specifically by a detective
            if ply:IsDetectiveLike() then
                deadply:SetNWBool("body_searched_det", true)
            end

            -- Don't cache this in case the hook wants to change the corpse's role
            if TRAITOR_ROLES[role] then
                -- update innocent team's list of whichever traitor role this corpse was
                SendRoleList(role, GetInnocentTeamFilter(false))
            end
            SCORE:HandleBodyFound(ply, deadply)
        end
        hook.Call("TTTBodyFound", GAMEMODE, ply, deadply, rag)
        CORPSE.SetFound(rag, announceName)
    -- Keep track if this body was searched specifically by a detective
    -- Also force the scoreboard to update
    elseif IsValid(deadply) and ply:IsDetectiveLike() and not deadply:GetNWBool("body_searched_det", false) then
        deadply:SetNWBool("body_found", true)
        deadply:SetNWBool("body_searched", true)
        deadply:SetNWBool("body_searched_det", true)
        net.Start("TTT_ScoreboardUpdate")
        net.WriteBool(true)
        net.Broadcast()
    end

    if not announceName then return end

    -- Handle kill list
    for _, vicsid in pairs(rag.kills) do
        -- filter out disconnected
        local vic = player.GetBySteamID64(vicsid) or player.GetBySteamID(vicsid)

        -- is this an unconfirmed dead?
        if IsValid(vic) and (not vic:GetNWBool("body_searched", false)) and (not vic:GetNWBool("body_found", false)) then
            LANG.Msg("body_confirm", {
                finder = finder,
                victim = vic:Nick()
            })

            -- update scoreboard status
            vic:SetNWBool("body_found", true)
        end
    end
end

-- Covert identify concommand for traitors
local function IdentifyCommand(ply, cmd, args)
    if not IsValid(ply) then return end
    if #args ~= 2 then return end

    local eidx = tonumber(args[1])
    local id = tonumber(args[2])
    if (not eidx) or (not id) then return end

    if (not ply.search_id) or ply.search_id.id ~= id or ply.search_id.eidx ~= eidx then
        ply.search_id = nil
        return
    end

    ply.search_id = nil

    local rag = Entity(eidx)
    if IsValid(rag) and rag.player_ragdoll and rag:GetPos():Distance(ply:GetPos()) < 128 then
        if not CORPSE.GetFound(rag, false) then
            IdentifyBody(ply, rag)
        end
    end
end
concommand.Add("ttt_confirm_death", IdentifyCommand)

local function GetExtendedDetectiveFilter(alive_only)
    return GetPlayerFilter(function(p) return p:IsDetectiveLike() and (not alive_only or p:IsTerror()) end)
end

-- Call detectives to a corpse
local function CallDetective(ply, cmd, args)
    if not IsValid(ply) then return end
    if #args ~= 2 then return end
    if not ply:IsActive() then return end

    local eidx = tonumber(args[1])
    if not eidx then return end

    local sid = args[2]
    local rag = Entity(eidx)
    if not (IsValid(rag) and rag.player_ragdoll) then return end

    if ((rag.last_detective_call or 0) < (CurTime() - 5)) and (rag:GetPos():Distance(ply:GetPos()) < 128) then
        rag.last_detective_call = CurTime()

        if CORPSE.GetFound(rag, false) then
            -- show indicator to detectives
            net.Start("TTT_CorpseCall")
            net.WriteVector(rag:GetPos())
            net.WriteString(sid)
            net.Send(GetExtendedDetectiveFilter(true))

            LANG.Msg("body_call", {
                player = ply:Nick(),
                role = ROLE_STRINGS_EXT[ROLE_DETECTIVE],
                victim = CORPSE.GetPlayerNick(rag, "someone")
            })
        else
            LANG.Msg(ply, "body_call_error", { role = ROLE_STRINGS_EXT[ROLE_DETECTIVE] })
        end
    end
end
concommand.Add("ttt_call_detective", CallDetective)

local function bitsRequired(num)
    local bits, max = 0, 1
    while max <= num do
        bits = bits + 1
        max = max + max
    end
    return bits
end

function GM:TTTCanSearchCorpse(ply, corpse, is_covert, is_long_range, was_traitor)
    -- return true to allow corpse search, false to disallow.
    return true
end

-- Send a usermessage to client containing search results
function CORPSE.ShowSearch(ply, rag, covert, long_range)
    if not IsValid(ply) or not IsValid(rag) then return end

    if rag:IsOnFire() then
        LANG.Msg(ply, "body_burning")
        return
    end

    if not hook.Run("TTTCanSearchCorpse", ply, rag, covert, long_range, TRAITOR_ROLES[rag.was_role]) then
        return
    end

    -- init a heap of data we'll be sending
    -- do this after the hook in case it wants to change some of that data
    local role = rag.was_role
    local nick = CORPSE.GetPlayerNick(rag)
    local eq = rag.equipment or EQUIP_NONE
    local c4 = rag.bomb_wire or -1
    local dmg = rag.dmgtype or DMG_GENERIC
    local wep = rag.dmgwep or ""
    local words = rag.last_words or ""
    local hshot = rag.was_headshot or false
    local dtime = rag.time or 0

    local ownerEnt = player.GetBySteamID64(rag.sid64) or player.GetBySteamID(rag.sid)
    local owner = IsValid(ownerEnt) and ownerEnt:EntIndex() or -1

    -- basic sanity check
    if nick == nil or eq == nil or role == nil then return end

    local credits = CORPSE.GetCredits(rag, 0)
    if ply:CanLootCredits(true) and credits > 0 and (not long_range) then
        LANG.Msg(ply, "body_credits", { num = credits })
        ply:AddCredits(credits)
        CORPSE.SetCredits(rag, 0)
        ServerLog(ply:Nick() .. " took " .. credits .. " credits from the body of " .. nick .. "\n")
        SCORE:HandleCreditFound(ply, nick, credits)
        return
    elseif DetectiveMode() then
        if CORPSE.CanBeSearched(ply, rag) then
            if not covert then
                IdentifyBody(ply, rag)
            end
        elseif IsValid(ownerEnt) and not ply:IsSpec() and not ownerEnt:GetNWBool("det_called", false) and not ownerEnt:GetNWBool("body_searched", false) then
            if IsValid(rag) and rag:GetPos():Distance(ply:GetPos()) < 128 then
                hook.Call("TTTBodyFound", GAMEMODE, ply, ownerEnt, rag)
                net.Start("TTT_CorpseCall")
                net.WriteVector(rag:GetPos())
                net.WriteString(rag.sid)
                net.Send(GetExtendedDetectiveFilter(true))
                ownerEnt:SetNWBool("det_called", true)
                ownerEnt:SetNWBool("body_found", true)
                LANG.Msg("body_confirm", { finder = ply:Nick(), victim = CORPSE.GetPlayerNick(rag, "someone") })
                LANG.Msg("body_call", { player = ply:Nick(), role = ROLE_STRINGS_EXT[ROLE_DETECTIVE], victim = CORPSE.GetPlayerNick(rag, "someone") })
            end
            return
        else
            return
        end
    end

    -- time of death relative to current time (saves bits)
    if dtime ~= 0 then
        dtime = math.Round(CurTime() - dtime)
    end

    -- identifier so we know whether a ttt_confirm_death was legit
    ply.search_id = { eidx = rag:EntIndex(), id = rag:EntIndex() + dtime }

    -- time of dna sample decay relative to current time
    local stime = 0
    if rag.killer_sample then
        stime = math.max(0, rag.killer_sample.t - CurTime())
    end

    -- build list of people this traitor killed
    local kill_entids = {}
    for _, vicsid in pairs(rag.kills) do
        -- also send disconnected players as a marker
        local vic = player.GetBySteamID64(vicsid) or player.GetBySteamID(vicsid)
        table.insert(kill_entids, IsValid(vic) and vic:EntIndex() or -1)
    end

    local lastid = -1
    if rag.lastid and ply:IsActiveDetectiveLike() then
        -- if the person this victim last id'd has since disconnected, send -1 to
        -- indicate this
        lastid = IsValid(rag.lastid.ent) and rag.lastid.ent:EntIndex() or -1
    end

    local round_state = GetRoundState()
    local sendName = AnnounceBodyName(ply, round_state)
    local sendRole = AnnounceBodyRole(ply, round_state)

    -- Send a message with basic info
    net.Start("TTT_RagdollSearch")
    net.WriteUInt(rag:EntIndex(), 16) -- 16 bits
    net.WriteUInt(owner, 8) -- 128 max players. ( 8 bits )
    net.WriteString(sendName and nick or "<Unknown>")
    net.WriteUInt(eq, 32) -- Equipment ( 32 = max. )
    net.WriteInt(sendRole and role or -1, 8) -- ( 8 bits )
    net.WriteInt(c4, bitsRequired(C4_WIRE_COUNT) + 1) -- -1 -> 2^bits ( default c4: 4 bits )
    net.WriteUInt(dmg, 30) -- DMG_BUCKSHOT is the highest. ( 30 bits )
    net.WriteString(wep)
    net.WriteBit(hshot) -- ( 1 bit )
    net.WriteInt(dtime, 16)
    net.WriteInt(stime, 16)

    net.WriteUInt(#kill_entids, 8)
    for _, idx in pairs(kill_entids) do
        net.WriteUInt(idx, 8) -- first game.MaxPlayers() of entities are for players.
    end

    net.WriteUInt(lastid, 8)

    -- Who found this, so if we get this from a detective we can decide not to
    -- show a window
    net.WriteUInt(ply:EntIndex(), 8)

    net.WriteString(words)

    -- 133 + string data + #kill_entids * 8
    -- 200

    if ply:IsActive() and not covert then
        net.Broadcast()

        -- Let detctives know that this body has already been searched
        net.Start("TTT_RemoveCorpseCall")
        net.WriteString(rag.sid)
        net.Send(GetExtendedDetectiveFilter(true))
    else
        net.Send(ply)
    end
end


-- Returns a sample for use in dna scanner if the kill fits certain constraints,
-- else returns nil
local function GetKillerSample(victim, attacker, dmg)
    -- only guns and melee damage, not explosions
    if not (dmg:IsBulletDamage() or dmg:IsDamageType(DMG_SLASH) or dmg:IsDamageType(DMG_CLUB)) then
        return nil
    end

    if not (IsValid(victim) and IsPlayer(attacker)) then return end

    -- NPCs for which a player is damage owner (meaning despite the NPC dealing
    -- the damage, the attacker is a player) should not cause the player's DNA to
    -- end up on the corpse.
    local infl = dmg:GetInflictor()
    if IsValid(infl) and infl:IsNPC() then return end

    local dist = victim:GetPos():Distance(attacker:GetPos())
    if dist > GetConVar("ttt_killer_dna_range"):GetInt() then return nil end

    local sample = {}
    sample.killer = attacker
    sample.killer_sid = attacker:SteamID() -- backwards compatibility; use sample.killer_sid64 instead
    sample.killer_sid64 = attacker:SteamID64()
    sample.victim = victim
    sample.t = CurTime() + (-1 * (0.019 * dist) ^ 2 + GetConVar("ttt_killer_dna_basetime"):GetInt())

    return sample
end

local crimescene_keys = { "Fraction", "HitBox", "Normal", "HitPos", "StartPos" }
local poseparams = {
    "aim_yaw", "move_yaw", "aim_pitch",
    --   "spine_yaw", "head_yaw", "head_pitch"
};

local function GetSceneDataFromPlayer(ply)
    local data = {
        pos = ply:GetPos(),
        ang = ply:GetAngles(),
        sequence = ply:GetSequence(),
        cycle = ply:GetCycle()
    };

    for _, param in pairs(poseparams) do
        data[param] = ply:GetPoseParameter(param)
    end

    return data
end

local function GetSceneData(victim, attacker, dmginfo)
    -- only for guns for now, hull traces don't work well etc
    if not dmginfo:IsBulletDamage() then return end

    local scene = {}

    if victim.hit_trace then
        scene.hit_trace = table.CopyKeys(victim.hit_trace, crimescene_keys)
    else
        return scene
    end

    scene.victim = GetSceneDataFromPlayer(victim)

    if IsPlayer(attacker) then
        scene.killer = GetSceneDataFromPlayer(attacker)

        local att = attacker:LookupAttachment("anim_attachment_RH")
        local angpos = attacker:GetAttachment(att)
        if not angpos then
            scene.hit_trace.StartPos = attacker:GetShootPos()
        else
            scene.hit_trace.StartPos = angpos.Pos
        end
    end

    return scene
end

local rag_collide = CreateConVar("ttt_ragdoll_collide", "0")

-- Creates client or server ragdoll depending on settings
function CORPSE.Create(ply, attacker, dmginfo)
    if not IsValid(ply) then return end

    local efn = ply.effect_fn
    ply.effect_fn = nil

    local rag = CreateEntity("prop_ragdoll")
    if not IsValid(rag) then return nil end

    rag:SetPos(ply:GetPos())
    rag:SetModel(ply:GetModel())
    rag:SetSkin(ply:GetSkin())
    for _, value in pairs(ply:GetBodyGroups()) do
        rag:SetBodygroup(value.id, ply:GetBodygroup(value.id))
    end
    rag:SetAngles(ply:GetAngles())
    rag:SetColor(ply:GetColor())

    rag:Spawn()
    rag:Activate()

    -- nonsolid to players, but can be picked up and shot
    rag:SetCollisionGroup(rag_collide:GetBool() and COLLISION_GROUP_WEAPON or COLLISION_GROUP_DEBRIS_TRIGGER)

    -- flag this ragdoll as being a player's
    rag.player_ragdoll = true
    rag.sid64 = ply:SteamID64()

    rag.sid = ply:SteamID() -- backwards compatibility; use rag.sid64 instead
    rag.uqid = ply:UniqueID() -- backwards compatibility; use rag.sid64 instead

    -- network data
    CORPSE.SetPlayerNick(rag, ply)
    CORPSE.SetFound(rag, false)
    CORPSE.SetCredits(rag, ply:GetCredits())

    -- if someone searches this body they can find info on the victim and the
    -- death circumstances
    rag.equipment = ply:GetEquipmentItems()
    rag.was_role = ply:GetRole()
    rag.bomb_wire = ply.bomb_wire
    rag.dmgtype = dmginfo:GetDamageType()

    local wep = util.WeaponFromDamage(dmginfo)
    rag.dmgwep = IsValid(wep) and wep:GetClass() or ""

    rag.was_headshot = (ply.was_headshot and dmginfo:IsBulletDamage())
    rag.time = CurTime()
    rag.kills = table.Copy(ply.kills)

    rag.killer_sample = GetKillerSample(ply, attacker, dmginfo)

    -- crime scene data
    rag.scene = GetSceneData(ply, attacker, dmginfo)

    -- position the bones
    local num = rag:GetPhysicsObjectCount() - 1
    local v = ply:GetVelocity()

    -- bullets have a lot of force, which feels better when shooting props,
    -- but makes bodies fly, so dampen that here
    if dmginfo:IsDamageType(DMG_BULLET) or dmginfo:IsDamageType(DMG_SLASH) then
        v = v / 5
    end

    for i = 0, num do
        local bone = rag:GetPhysicsObjectNum(i)
        if IsValid(bone) then
            local bp, ba = ply:GetBonePosition(rag:TranslatePhysBoneToBone(i))
            if bp and ba then
                bone:SetPos(bp)
                bone:SetAngles(ba)
            end

            -- not sure if this will work:
            bone:SetVelocity(v)
        end
    end

    -- create advanced death effects (knives)
    if efn then
        -- next frame, after physics is happy for this ragdoll
        timer.Simple(0, function() if IsValid(rag) then efn(rag) end end)
    end

    hook.Run("TTTOnCorpseCreated", rag, ply)

    return rag -- we'll be speccing this
end
