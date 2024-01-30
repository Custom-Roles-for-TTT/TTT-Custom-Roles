-- Random stuff

if not util then return end

local cvars = cvars
local input = input
local ipairs = ipairs
local IsValid = IsValid
local math = math
local pairs = pairs
local scripted_ents = scripted_ents
local string = string
local table = table
local timer = timer
local weapons = weapons
local hook = hook

local GetAllPlayers = player.GetAll
local StringUpper = string.upper
local StringFormat = string.format
local StringSub = string.sub
local StringStartsWith = string.StartsWith
local StringTrim = string.Trim
local StringTrimLeft = string.TrimLeft
local HookCall = hook.Call

-- attempts to get the weapon used from a DamageInfo instance needed because the
-- GetAmmoType value is useless and inflictor isn't properly set (yet)
function util.WeaponFromDamage(dmg)
    local inf = dmg:GetInflictor()
    local wep = nil
    if IsValid(inf) then
        if inf:IsWeapon() or inf.Projectile then
            wep = inf
        elseif dmg:IsDamageType(DMG_DIRECT) or dmg:IsDamageType(DMG_CRUSH) then
            -- DMG_DIRECT is the player burning, no weapon involved
            -- DMG_CRUSH is physics or falling on someone
            wep = nil
        elseif inf:IsPlayer() then
            wep = inf:GetActiveWeapon()
            if not IsValid(wep) then
                -- this may have been a dying shot, in which case we need a
                -- workaround to find the weapon because it was dropped on death
                wep = IsValid(inf.dying_wep) and inf.dying_wep or nil
            end
        end
    end

    return wep
end

-- Gets the table for a SWEP or a weapon-SENT (throwing knife), so not
-- equivalent to weapons.Get. Do not modify the table returned by this, consider
-- as read-only.
function util.WeaponForClass(cls)
    local wep = weapons.GetStored(cls)

    if not wep then
        wep = scripted_ents.GetStored(cls)
        if wep then
            -- don't like to rely on this, but the alternative is
            -- scripted_ents.Get which does a full table copy, so only do
            -- that as last resort
            wep = wep.t or scripted_ents.Get(cls)
        end
    end

    return wep
end

function util.GetAlivePlayers()
    local alive = {}
    for _, p in ipairs(GetAllPlayers()) do
        if IsValid(p) and p:Alive() and p:IsTerror() then
            table.insert(alive, p)
        end
    end

    return alive
end

function util.GetNextAlivePlayer(ply)
    local alive = util.GetAlivePlayers()

    if #alive < 1 then return nil end

    local prev = nil
    local choice = nil

    if IsValid(ply) then
        for k, p in ipairs(alive) do
            if prev == ply then
                choice = p
            end

            prev = p
        end
    end

    if not IsValid(choice) then
        choice = alive[1]
    end

    return choice
end

-- Uppercases the first character only
function string.Capitalize(str)
    return StringUpper(StringSub(str, 1, 1)) .. StringSub(str, 2)
end
util.Capitalize = string.Capitalize

-- Color unpacking
function clr(color) return color.r, color.g, color.b, color.a; end

if CLIENT then
    -- Is screenpos on screen?
    function IsOffScreen(scrpos)
        return not scrpos.visible or scrpos.x < 0 or scrpos.y < 0 or scrpos.x > ScrW() or scrpos.y > ScrH()
    end
end

function AccessorFuncDT(tbl, varname, name)
    tbl["Get" .. name] = function(s) return s.dt and s.dt[varname] end
    tbl["Set" .. name] = function(s, v) if s.dt then s.dt[varname] = v end end
end

function util.PaintDown(start, effname, ignore)
    local btr = util.TraceLine({ start = start, endpos = start + Vector(0, 0, -256), filter = ignore, mask = MASK_SOLID })

    util.Decal(effname, btr.HitPos + btr.HitNormal, btr.HitPos - btr.HitNormal)
end

local function DoBleed(ent)
    if not IsValid(ent) or (ent:IsPlayer() and (not ent:Alive() or not ent:IsTerror())) then
        return
    end

    local jitter = VectorRand() * 30
    jitter.z = 20

    util.PaintDown(ent:GetPos() + jitter, "Blood", ent)
end

-- Something hurt us, start bleeding for a bit depending on the amount
function util.StartBleeding(ent, dmg, t)
    if dmg < 5 or not IsValid(ent) then
        return
    end

    if ent:IsPlayer() and (not ent:Alive() or not ent:IsTerror()) then
        return
    end

    local times = math.Clamp(math.Round(dmg / 15), 1, 20)

    local delay = math.Clamp(t / times, 0.1, 2)

    if ent:IsPlayer() then
        times = times * 2
        delay = delay / 2
    end

    timer.Create("bleed" .. ent:EntIndex(), delay, times,
            function() DoBleed(ent) end)
end

function util.StopBleeding(ent)
    timer.Remove("bleed" .. ent:EntIndex())
end

local zapsound = Sound("npc/assassin/ball_zap1.wav")
function util.EquipmentDestroyed(pos)
    local effect = EffectData()
    effect:SetOrigin(pos)
    util.Effect("cball_explode", effect)
    sound.Play(zapsound, pos)
end

-- Useful default behaviour for semi-modal DFrames
function util.BasicKeyHandler(pnl, kc)
    -- passthrough F5
    if kc == KEY_F5 then
        RunConsoleCommand("jpeg")
    else
        pnl:Close()
    end
end

function util.noop() end
function util.passthrough(x) return x end

-- Fisher-Yates shuffle
local rand = math.random
function table.Shuffle(t)
    local n = #t

    while n > 1 do
        -- n is now the last pertinent index
        local k = rand(n) -- 1 <= k <= n
        -- Quick swap
        t[n], t[k] = t[k], t[n]
        n = n - 1
    end

    return t
end

-- Override with nil check
function table.HasValue(tbl, val)
    if not tbl then return end

    for _, v in pairs(tbl) do
        if v == val then return true end
    end
    return false
end

function table.HasItemWithPropertyValue(tbl, key, val)
    if not tbl or not key then return end

    for _, v in pairs(tbl) do
        if v[key] and v[key] == val then return true end
    end
    return false
end

-- Value equality for tables
function table.EqualValues(a, b)
    if a == b then return true end

    for k, v in pairs(a) do
        if v ~= b[k] then
            return false
        end
    end

    return true
end

-- Basic table.HasValue pointer checks are insufficient when checking a table of
-- tables, so this uses table.EqualValues instead.
function table.HasTable(tbl, needle)
    if not tbl then return end

    for k, v in pairs(tbl) do
        if v == needle then
            return true
        elseif table.EqualValues(v, needle) then
            return true
        end
    end
    return false
end

-- Returns copy of table with only specific keys copied
function table.CopyKeys(tbl, keys)
    if not (tbl and keys) then return end

    local out = {}
    local val
    for _, k in pairs(keys) do
        val = tbl[k]
        if istable(val) then
            out[k] = table.Copy(val)
        else
            out[k] = val
        end
    end
    return out
end

-- Returns new table that contains the keys that are only present in both given tables,
-- excluding those which appear as values in the given exclude table (if it is given)
function table.IntersectedKeys(first_tbl, second_tbl, excludes)
    if not (first_tbl and second_tbl) then return end
    local intersect = {}
    for k, v in pairs(first_tbl) do
        if v and second_tbl[k] and (not excludes or not table.HasValue(excludes, k)) then
            table.insert(intersect, k)
        end
    end
    return intersect
end

-- Returns new table that contains a combination of the keys present in first table and the second table,
-- excluding those which appear as values in the given exclude table (if it is given)
function table.UnionedKeys(first_tbl, second_tbl, excludes)
    if not (first_tbl and second_tbl) then return end

    -- Clone the first table if there are no excludes
    local union
    if excludes then
        union = table.ExcludedKeys(first_tbl, excludes)
    else
        union = table.LookupKeys(first_tbl)
    end

    -- Add anything that is not already in the table and not excluded
    for k, v in pairs(second_tbl) do
        if v and not union[k] and (not excludes or not table.HasValue(excludes, k)) then
            table.insert(union, k)
        end
    end
    return union
end

-- Returns new table that contains the keys not present as values in in the given exclude table
function table.ExcludedKeys(tbl, excludes)
    if not (tbl and excludes) then return end
    local new_tbl = {}
    for k, v in pairs(tbl) do
        if v and not table.HasValue(excludes, k) then
            table.insert(new_tbl, k)
        end
    end
    return new_tbl
end

-- Returns new table that contains the keys that have a truth-y value in the given table
function table.LookupKeys(tbl)
    if not tbl then return end
    local new_tbl = {}
    for k, v in pairs(tbl) do
        if v then
            table.insert(new_tbl, k)
        end
    end
    return new_tbl
end

-- Returns a new table whose keys are the values of the given table and whose values are all the literal boolean "true"
-- Used for fast lookups by key
function table.ToLookup(tbl)
    if not tbl then return end
    local new_tbl = {}
    for _, v in pairs(tbl) do
        new_tbl[v] = true
    end
    return new_tbl
end

local gsub = string.gsub
-- Simple string interpolation:
-- string.Interp("{killer} killed {victim}", {killer = "Bob", victim = "Joe"})
-- returns "Bob killed Joe"
-- No spaces or special chars in parameter name, just alphanumerics.
function string.Interp(str, tbl)
    return gsub(str, "{(%w+)}", tbl)
end

-- Short helper for input.LookupBinding, returns capitalised key or a default
function Key(binding, default)
    local b = input.LookupBinding(binding)
    if not b then return default end

    return StringUpper(b)
end

local exp = math.exp
-- Equivalent to ExponentialDecay from Source's mathlib.
-- Convenient for falloff curves.
function math.ExponentialDecay(halflife, dt)
    -- ln(0.5) = -0.69..
    return exp((-0.69314718 / halflife) * dt)
end

function Dev(level, ...)
    if cvars and cvars.Number("developer", 0) >= level then
        Msg("[TTT dev]")
        -- table.concat does not tostring, derp

        local params = { ... }
        for i = 1, #params do
            Msg(" " .. tostring(params[i]))
        end

        Msg("\n")
    end
end

function IsPlayer(ent)
    return IsValid(ent) and ent:IsPlayer()
end

function IsRagdoll(ent)
    return IsValid(ent) and ent:GetClass() == "prop_ragdoll"
end

local band = bit.band
function util.BitSet(val, b)
    return band(val, b) == b
end

if CLIENT then
    local healthcolors = {
        healthy = Color(0, 255, 0, 255),
        hurt = Color(170, 230, 10, 255),
        wounded = Color(230, 215, 10, 255),
        badwound = Color(255, 140, 0, 255),
        death = Color(255, 0, 0, 255)
    };

    function util.HealthToString(health, maxhealth)
        maxhealth = maxhealth or 100

        if health > maxhealth * 0.9 then
            return "hp_healthy", healthcolors.healthy
        elseif health > maxhealth * 0.7 then
            return "hp_hurt", healthcolors.hurt
        elseif health > maxhealth * 0.45 then
            return "hp_wounded", healthcolors.wounded
        elseif health > maxhealth * 0.2 then
            return "hp_badwnd", healthcolors.badwound
        else
            return "hp_death", healthcolors.death
        end
    end

    local karmacolors = {
        max = COLOR_WHITE,
        high = Color(255, 240, 135, 255),
        med = Color(245, 220, 60, 255),
        low = Color(255, 180, 0, 255),
        min = Color(255, 130, 0, 255),
    };

    function util.KarmaToString(karma)
        if karma >= 1000 then
            return "karma_max", karmacolors.max
        elseif karma > 900 then
            return "karma_high", karmacolors.high
        elseif karma > 700 then
            return "karma_med", karmacolors.med
        elseif karma > 500 then
            return "karma_low", karmacolors.low
        else
            return "karma_min", karmacolors.min
        end
    end

    function util.IncludeClientFile(file)
        include(file)
    end
else
    function util.IncludeClientFile(file)
        AddCSLuaFile(file)
    end
end

-- Like string.FormatTime but simpler (and working), always a string, no hour
-- support
function util.SimpleTime(seconds, fmt)
    if not seconds then seconds = 0 end

    local ms = (seconds - math.floor(seconds)) * 100
    seconds = math.floor(seconds)
    local s = seconds % 60
    seconds = (seconds - s) / 60
    local m = seconds % 60

    return StringFormat(fmt, m, s, ms)
end

if SERVER then
    function util.ExecFile(filePath, errorIfMissing)
        if not file.Exists(filePath, "GAME") then
            if errorIfMissing then
                ErrorNoHalt(StringFormat("File not found when trying to execute: %s\n", filePath))
            end
            return
        end

        local fileContent = file.Read(filePath, "GAME")
        local lines = string.Explode("\n", fileContent)
        for _, line in ipairs(lines) do
            line = StringTrim(line)
            if #line == 0 then continue end

            if StringStartsWith(line, "exec ") then
                local subFile = StringTrimLeft(line, "exec ")
                util.ExecFile(subFile, errorIfMissing)
                continue
            end

            game.ConsoleCommand(StringFormat("%s\n", line))
        end
    end
end

function util.CanRoleSpawnArtificially(role)
    if HookCall("TTTRoleSpawnsArtificially", nil, role) then
        return true
    end
    return false
end

function util.CanRoleSpawnNaturally(role)
    if DEFAULT_ROLES[role] or ROLE_PACK_ROLES[role] or GetConVar("ttt_" .. ROLE_STRINGS_RAW[role] .. "_enabled"):GetBool() then
        return true
    end
    return false
end

function util.CanRoleSpawn(role)
    return util.CanRoleSpawnNaturally(role) or util.CanRoleSpawnArtificially(role)
end

----------------------------
-- ADAPTED FROM FLARE GUN --
----------------------------

if CLIENT then

    local function ReceiveScorches()
        local ent = net.ReadEntity()
        local num = net.ReadUInt(8)
        -- small scorches under the limbs
        for i=1, num do
            util.PaintDown(net.ReadVector(), "FadingScorch", ent)
        end

        -- big scorch in the center
        if IsValid(ent) then
            util.PaintDown(ent:LocalToWorld(ent:OBBCenter()), "Scorch", ent)
        end
    end
    net.Receive("TTT_RagdollScorch", ReceiveScorches)

elseif SERVER then

    util.AddNetworkString("TTT_RagdollScorch")

    local function SendScorches(ent, tbl)
        net.Start("TTT_RagdollScorch")
            net.WriteEntity(ent)
            net.WriteUInt(#tbl, 8)
            for _, p in ipairs(tbl) do
                net.WriteVector(p)
            end
        net.Broadcast()
    end

    local function RunIgniteTimer(ent, timer_name)
        if IsValid(ent) and ent:IsOnFire() then
            if ent:WaterLevel() > 0 then
                ent:Extinguish()
            elseif CurTime() > ent.burn_destroy then
                ent:SetNotSolid(true)
                ent:Remove()
            else
                -- keep on burning
                return
            end
        end

        timer.Remove(timer_name) -- stop running timer
    end

    local function ScorchUnderRagdoll(ent)
        local postbl = {}
        -- small scorches under limbs
        for i=0, ent:GetPhysicsObjectCount() - 1 do
            local subphys = ent:GetPhysicsObjectNum(i)
            if IsValid(subphys) then
                table.insert(postbl, subphys:GetPos())
            end
        end

        -- send to client manually because server decal painting tends to be unreliable
        SendScorches(ent, postbl)
    end

    -- Burns and destroys a ragdoll while also displaying scorches and allowing for extinguishing in water
    function util.BurnRagdoll(rag, burn_time, scorch)
        if not IsValid(rag) or rag:GetClass() ~= "prop_ragdoll" then return end

        rag:Ignite(burn_time)
        rag.burn_destroy = CurTime() + burn_time

        local tname = Format("burnrag_%d_%d", rag:EntIndex(), math.ceil(CurTime()))
        timer.Create(tname, 0.1, math.ceil(1 + burn_time / 0.1), function()
            RunIgniteTimer(rag, tname)
        end)

        -- Default to true
        if scorch ~= false then
            ScorchUnderRagdoll(rag)
        end
    end

end

------------------------
-- END FROM FLARE GUN --
------------------------