---- Customized scoring

local ipairs = ipairs
local IsValid = IsValid
local net = net
local pairs = pairs
local player = player
local string = string
local table = table
local util = util

local GetAllPlayers = player.GetAll
local StringSub = string.sub

SCORE = SCORE or {}
SCORE.Events = SCORE.Events or {}

include("scoring_shd.lua")

-- One might wonder why all the key names in the event tables are so annoyingly
-- short. Well, the serialisation module in gmod (glon) does not do any
-- compression. At all. This means the difference between all events having a
-- "time_added" key versus a "t" key is very significant for the amount of data
-- we need to send. It's a pain, but I'm not going to code my own compression,
-- so doing it manually is the only way.

-- One decent way to reduce data sent turned out to be rounding the time floats.
-- We don't actually need to know about 10000ths of seconds after all.

function SCORE:AddEvent(entry, t_override)
    entry.t = t_override or CurTime()
    table.insert(self.Events, entry)
end

local function CopyDmg(dmg)
    local wep = util.WeaponFromDamage(dmg)
    local g, n

    if wep then
        g = wep:GetClass()
    else
        local infl = dmg:GetInflictor()
        if IsValid(infl) and infl.ScoreName then
            n = infl.ScoreName
        end
    end

    -- t = type, a = amount, g = gun, h = headshot, n = name
    return {
        t = dmg:GetDamageType(),
        a = dmg:GetDamage(),
        h = false,
        g = g,
        n = n
    }
end

function SCORE:HandleKill(victim, attacker, dmginfo)
    if not IsPlayer(victim) then return end

    local e = {
        id = EVENT_KILL,
        att = { ni = "", sid = -1, sid64 = -1, role = -1, tr = false, inno = false, jes = false, ind = false, mon = false },
        vic = { ni = victim:Nick(), sid = victim:SteamID(), sid64 = victim:SteamID64(), role = -1, tr = false, inno = false, jes = false, ind = false, mon = false },
        dmg = CopyDmg(dmginfo),
        tk = false
    };

    e.dmg.h = victim.was_headshot

    e.vic.role = victim:GetRole()
    e.vic.inno = victim:IsInnocentTeam()
    e.vic.tr = victim:IsTraitorTeam()
    e.vic.jes = victim:IsJesterTeam()
    e.vic.ind = victim:IsIndependentTeam()
    e.vic.mon = victim:IsMonsterTeam()

    if IsPlayer(attacker) then
        e.att.ni = attacker:Nick()
        e.att.sid = attacker:SteamID()
        e.att.sid64 = attacker:SteamID64()
        e.att.role = attacker:GetRole()
        e.att.tr = attacker:IsTraitorTeam()
        e.att.inno = attacker:IsInnocentTeam()
        e.att.jes = attacker:IsJesterTeam()
        e.att.ind = attacker:IsIndependentTeam()
        e.att.mon = attacker:IsMonsterTeam()
        e.tk = (e.att.tr and e.vic.tr) or (e.att.inno and e.vic.inno) or (e.att.mon and e.vic.mon)

        -- If a traitor gets himself killed by another traitor's C4, it's their own
        -- damn fault for ignoring the indicator.
        if dmginfo:IsExplosionDamage() and e.att.tr and e.vic.tr then
            local infl = dmginfo:GetInflictor()
            if IsValid(infl) and infl:GetClass() == "ttt_c4" then
                e.att = table.Copy(e.vic)
            end
        end
    end

    self:AddEvent(e)
end

function SCORE:HandleSpawn(ply)
    if ply:Team() == TEAM_TERROR then
        self:AddEvent({ id = EVENT_SPAWN, ni = ply:Nick(), sid = ply:SteamID(), sid64 = ply:SteamID64() })
    end
end

function SCORE:HandleSelection()
    local roles = {}
    for _, ply in ipairs(GetAllPlayers()) do
        -- Prefix the ID value with a string to force the key to stay as a string when it gets transferred
        -- Without this, the key gets converted to a floating-point number which loses precision and causes errors during data lookup
        roles[GetRoleId(ply:SteamID64())] = ply:GetRole()
    end

    self:AddEvent({ id = EVENT_SELECTED, roles = roles })
end

function SCORE:HandleBodyFound(finder, found)
    self:AddEvent({ id = EVENT_BODYFOUND, ni = finder:Nick(), sid = finder:SteamID(), sid64 = finder:SteamID64(), b = found:Nick(), isd = finder:IsDetectiveLike() })
end

function SCORE:HandleC4Explosion(planter, arm_time, exp_time)
    local nick = "Someone"
    if IsPlayer(planter) then
        nick = planter:Nick()
    end

    self:AddEvent({ id = EVENT_C4PLANT, ni = nick }, arm_time)
    self:AddEvent({ id = EVENT_C4EXPLODE, ni = nick }, exp_time)
end

function SCORE:HandleC4Disarm(disarmer, owner, success)
    if disarmer == owner then return end
    if not IsValid(disarmer) then return end

    local ev = {
        id = EVENT_C4DISARM,
        ni = disarmer:Nick(),
        s = success
    };

    if IsValid(owner) then
        ev.own = owner:Nick()
    end

    self:AddEvent(ev)
end

function SCORE:HandleCreditFound(finder, found_nick, credits)
    self:AddEvent({ id = EVENT_CREDITFOUND, ni = finder:Nick(), sid = finder:SteamID(), sid64 = finder:SteamID64(), b = found_nick, cr = credits })
end

function SCORE:ApplyEventLogScores(wintype)
    local scores = {}
    local roles = {}
    local bonus = {}

    for _, ply in ipairs(GetAllPlayers()) do
        local sid64 = ply:SteamID64()
        scores[sid64] = {}
        roles[sid64] = ply:GetRole()
        bonus[sid64] = 0
    end

    -- count deaths
    for _, e in pairs(self.Events) do
        if e.id == EVENT_KILL then
            local victim = player.GetBySteamID64(e.vic.sid64) or player.GetBySteamID(e.vic.sid)
            if IsValid(victim) and victim:ShouldScore() then
                victim:AddDeaths(1)
            end
        end

        -- Allow any event to provide bonus points
        if e.sid64 and e.bonus then
            local sid = e.sid64
            bonus[sid] = bonus[sid] + e.bonus
        end
    end

    -- individual scores, and count those left alive
    local scored_log = ScoreEventLog(self.Events, scores, roles, bonus)
    local ply
    for sid, s in pairs(scored_log) do
        ply = player.GetBySteamID64(sid)
        if IsValid(ply) and ply:ShouldScore() then
            ply:AddFrags(KillsToPoints(s, ply:IsTraitorTeam(), ply:IsInnocentTeam()))
        end
    end

    -- team scores
    bonus = ScoreTeamBonus(scored_log, wintype)

    for sid64, _ in pairs(scored_log) do
        ply = player.GetBySteamID64(sid64)
        if IsValid(ply) and ply:ShouldScore() then
            local points_team = bonus.innos
            if ply:IsTraitorTeam() then
                points_team = bonus.traitors
            elseif ply:IsJesterTeam() then
                points_team = bonus.jesters
            elseif ply:IsIndependentTeam() then
                points_team = bonus.indeps
            elseif ply:IsMonsterTeam() then
                points_team = bonus.monsters
            end

            ply:AddFrags(points_team)
        end
    end
end

function SCORE:RoundStateChange(newstate)
    self:AddEvent({ id = EVENT_GAME, state = newstate })
end

function SCORE:RoundComplete(wintype)
    self:AddEvent({ id = EVENT_FINISH, win = wintype })
end

function SCORE:Reset()
    self.Events = {}
end

function SCORE:StreamToClients()
    local events = util.TableToJSON(self.Events)
    if events == nil then
        ErrorNoHalt("Round report event encoding failed!\n")
        return
    end

    events = util.Compress(events)
    if events == "" then
        ErrorNoHalt("Round report event compression failed!\n")
        return
    end

    -- divide into happy lil bits.
    -- this was necessary with user messages, now it's
    -- a just-in-case thing if a round somehow manages to be > 64K
    local len = #events
    local MaxStreamLength = SCORE.MaxStreamLength

    if len <= MaxStreamLength then
        net.Start("TTT_ReportStream")
        net.WriteUInt(len, 16)
        net.WriteData(events, len)
        net.Broadcast()
    else
        local curpos = 0

        repeat
            net.Start("TTT_ReportStream_Part")
            net.WriteData(StringSub(events, curpos + 1, curpos + MaxStreamLength + 1), MaxStreamLength)
            net.Broadcast()

            curpos = curpos + MaxStreamLength + 1
        until (len - curpos <= MaxStreamLength)

        net.Start("TTT_ReportStream")
        net.WriteUInt(len, 16)
        net.WriteData(StringSub(events, curpos + 1, len), len - curpos)
        net.Broadcast()
    end
end
