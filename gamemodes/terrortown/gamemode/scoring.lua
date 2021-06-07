---- Customized scoring

local math = math
local string = string
local table = table
local pairs = pairs

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
    if not (IsValid(victim) and victim:IsPlayer()) then return end

    local e = {
        id = EVENT_KILL,
        att = { ni = "", sid = -1, sid64 = -1, tr = false, inno = false, jes = false },
        vic = { ni = victim:Nick(), sid = victim:SteamID(), sid64 = victim:SteamID64(), tr = false, inno = false, jes = false },
        dmg = CopyDmg(dmginfo),
        tk = false
    };

    e.dmg.h = victim.was_headshot

    e.vic.role = victim:GetRole()
    e.vic.inno = victim:IsInnocentTeam()
    e.vic.tr = victim:GetTraitor()
    e.vic.jes = victim:IsJesterTeam()

    if IsValid(attacker) and attacker:IsPlayer() then
        e.att.ni = attacker:Nick()
        e.att.sid = attacker:SteamID()
        e.att.sid64 = attacker:SteamID64()
        e.att.role = attacker:GetRole()
        e.att.tr = attacker:GetTraitor()
        e.att.inno = attacker:IsInnocentTeam()
        e.att.jes = attacker:IsJesterTeam()
        e.tk = (e.att.tr and e.vic.tr) or (e.att.inno and e.vic.inno) or (e.att.jes and e.vic.jes)

        -- If a traitor gets himself killed by another traitor's C4, it's his own
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
    local innocents = {}
    local traitors = {}
    local detectives = {}
    local jesters = {}
    local swappers = {}
    local glitches = {}
    local phantoms = {}
    local hypnotists = {}
    local revengers = {}
    local drunks = {}
    local clowns = {}
    local deputies = {}
    local impersonators = {}
    local beggars = {}
    local oldmen = {}

    for _, ply in ipairs(player.GetAll()) do
        if ply:GetInnocent() then
            table.insert(innocents, ply:SteamID64())
        elseif ply:GetTraitor() then
            table.insert(traitors, ply:SteamID64())
        elseif ply:GetDetective() then
            table.insert(detectives, ply:SteamID64())
        elseif ply:GetJester() then
            table.insert(jesters, ply:SteamID64())
        elseif ply:GetSwapper() then
            table.insert(swappers, ply:SteamID64())
        elseif ply:GetGlitch() then
            table.insert(glitches, ply:SteamID64())
        elseif ply:GetPhantom() then
            table.insert(phantoms, ply:SteamID64())
        elseif ply:GetHypnotist() then
            table.insert(hypnotists, ply:SteamID64())
        elseif ply:GetRevenger() then
            table.insert(revengers, ply:SteamID64())
        elseif ply:GetDrunk() then
            table.insert(drunks, ply:SteamID64())
        elseif ply:GetClown() then
            table.insert(clowns, ply:SteamID64())
        elseif ply:GetDeputy() then
            table.insert(deputies, ply:SteamID64())
        elseif ply:GetImpersonator() then
            table.insert(impersonators, ply:SteamID64())
        elseif ply:GetBeggar() then
            table.insert(beggars, ply:SteamID64())
        elseif ply:GetOldMan() then
            table.insert(oldmen, ply:SteamID64())
        end
    end

    self:AddEvent({ id = EVENT_SELECTED,
                    innocent_ids = innocents,
                    traitor_ids = traitors,
                    detective_ids = detectives,
                    jester_ids = jesters,
                    swapper_ids = swappers,
                    glitch_ids = glitches,
                    phantom_ids = phantoms,
                    hypnotist_ids = hypnotists,
                    revenger_ids = revengers,
                    drunk_ids = drunks,
                    clown_ids = clowns,
                    deputy_ids = deputies,
                    impersonator_ids = impersonators,
                    beggar_ids = beggars,
                    old_man_ids = oldmen })
end

function SCORE:HandleBodyFound(finder, found)
    self:AddEvent({ id = EVENT_BODYFOUND, ni = finder:Nick(), sid = finder:SteamID(), sid64 = finder:SteamID64(), b = found:Nick() })
end

function SCORE:HandleC4Explosion(planter, arm_time, exp_time)
    local nick = "Someone"
    if IsValid(planter) and planter:IsPlayer() then
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
    local innocents = {}
    local traitors = {}
    local detectives = {}
    local jesters = {}
    local swappers = {}
    local glitches = {}
    local phantoms = {}
    local hypnotists = {}
    local revengers = {}
    local drunks = {}
    local clowns = {}
    local deputies = {}
    local impersonators = {}
    local beggars = {}
    local oldmen = {}

    for _, ply in ipairs(player.GetAll()) do
        scores[ply:SteamID64()] = {}

        if ply:GetInnocent() then
            table.insert(innocents, ply:SteamID64())
        elseif ply:GetTraitor() then
            table.insert(traitors, ply:SteamID64())
        elseif ply:GetDetective() then
            table.insert(detectives, ply:SteamID64())
        elseif ply:GetJester() then
            table.insert(jesters, ply:SteamID64())
        elseif ply:GetSwapper() then
            table.insert(swappers, ply:SteamID64())
        elseif ply:GetGlitch() then
            table.insert(glitches, ply:SteamID64())
        elseif ply:GetPhantom() then
            table.insert(phantoms, ply:SteamID64())
        elseif ply:GetHypnotist() then
            table.insert(hypnotists, ply:SteamID64())
        elseif ply:GetRevenger() then
            table.insert(revengers, ply:SteamID64())
        elseif ply:GetDrunk() then
            table.insert(drunks, ply:SteamID64())
        elseif ply:GetClown() then
            table.insert(clowns, ply:SteamID64())
        elseif ply:GetDeputy() then
            table.insert(deputies, ply:SteamID64())
        elseif ply:GetImpersonator() then
            table.insert(impersonators, ply:SteamID64())
        elseif ply:GetBeggar() then
            table.insert(beggars, ply:SteamID64())
        elseif ply:GetOldMan() then
            table.insert(oldmen, ply:SteamID64())
        end
    end

    -- individual scores, and count those left alive
    local scored_log = ScoreEventLog(self.Events, scores, innocents, traitors, detectives, jesters, swappers, glitches, phantoms, hypnotists, revengers, drunks, clowns, deputies, impersonators, beggars, oldmen)
    local ply = nil
    for sid, s in pairs(scored_log) do
        ply = player.GetBySteamID64(sid)
        if IsValid(ply) and ply:ShouldScore() then
            ply:AddFrags(KillsToPoints(s, ply:IsTraitorTeam(), ply:IsInnocentTeam()))
        end
    end

    -- team scores
    local bonus = ScoreTeamBonus(scored_log, wintype)

    for sid64, _ in pairs(scored_log) do
        ply = player.GetBySteamID64(sid64)
        if IsValid(ply) and ply:ShouldScore() then
            local points_team = bonus.innos
            if ply:IsTraitorTeam() then
                points_team = bonus.traitors
            elseif ply:IsJesterTeam() then
                points_team = bonus.jesters
            end

            ply:AddFrags(points_team)
        end
    end

    -- count deaths
    for _, e in pairs(self.Events) do
        if e.id == EVENT_KILL then
            local victim = player.GetBySteamID64(e.vic.sid64) or player.GetBySteamID(e.vic.sid)
            if IsValid(victim) and victim:ShouldScore() then
                victim:AddDeaths(1)
            end
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
            net.WriteData(string.sub(events, curpos + 1, curpos + MaxStreamLength + 1), MaxStreamLength)
            net.Broadcast()

            curpos = curpos + MaxStreamLength + 1
        until (len - curpos <= MaxStreamLength)

        net.Start("TTT_ReportStream")
        net.WriteUInt(len, 16)
        net.WriteData(string.sub(events, curpos + 1, len), len - curpos)
        net.Broadcast()
    end
end
