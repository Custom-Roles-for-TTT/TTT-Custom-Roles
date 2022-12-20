AddCSLuaFile()

local hook = hook
local ipairs = ipairs
local math = math
local net = net
local pairs = pairs
local player = player
local resource = resource
local table = table
local timer = timer
local util = util
local weapons = weapons

local GetAllPlayers = player.GetAll
local CreateEntity = ents.Create
local MathRandom = math.random
local TableInsert = table.insert
local TableRemove = table.remove

util.AddNetworkString("TTT_UpdateLootGoblinWins")
util.AddNetworkString("TTT_LootGoblinRadar")

resource.AddSingleFile("lootgoblin/cackle1.wav")
resource.AddSingleFile("lootgoblin/cackle2.wav")
resource.AddSingleFile("lootgoblin/cackle3.wav")
resource.AddSingleFile("lootgoblin/jingle1.wav")
resource.AddSingleFile("lootgoblin/jingle2.wav")
resource.AddSingleFile("lootgoblin/jingle3.wav")
resource.AddSingleFile("lootgoblin/jingle4.wav")
resource.AddSingleFile("lootgoblin/jingle5.wav")
resource.AddSingleFile("lootgoblin/jingle6.wav")
resource.AddSingleFile("lootgoblin/jingle7.wav")
resource.AddSingleFile("lootgoblin/jingle8.wav")

-------------
-- CONVARS --
-------------

CreateConVar("ttt_lootgoblin_notify_mode", "4", FCVAR_NONE, "The logic to use when notifying players that the lootgoblin is killed", 0, 4)
CreateConVar("ttt_lootgoblin_notify_sound", "1")
CreateConVar("ttt_lootgoblin_notify_confetti", "1")
local lootgoblin_activation_timer = CreateConVar("ttt_lootgoblin_activation_timer", "30", FCVAR_NONE, "Minimum time in seconds before the loot goblin is revealed", 0, 120)
local lootgoblin_activation_timer_max = CreateConVar("ttt_lootgoblin_activation_timer_max", "60", FCVAR_NONE, "Maximum time in seconds before the loot goblin is revealed", 0, 120)
local lootgoblin_announce = CreateConVar("ttt_lootgoblin_announce", "4", FCVAR_NONE, "The logic to use when notifying players that a loot goblin has been revealed. 0 - Don't notify anyone. 1 - Only notify traitors and detective. 2 - Only notify traitors. 3 - Only notify detective. 4 - Notify everyone", 0, 4)
local lootgoblin_size = CreateConVar("ttt_lootgoblin_size", "0.5", FCVAR_NONE, "The size multiplier for the loot goblin to use when they are revealed (e.g. 0.5 = 50% size)", 0, 1)
local lootgoblin_cackle_timer_min = CreateConVar("ttt_lootgoblin_cackle_timer_min", "4", FCVAR_NONE, "The minimum time between loot goblin cackles", 0, 30)
local lootgoblin_cackle_timer_max = CreateConVar("ttt_lootgoblin_cackle_timer_max", "12", FCVAR_NONE, "The maximum time between loot goblin cackles", 0, 30)
local lootgoblin_cackle_enabled = CreateConVar("ttt_lootgoblin_cackle_enabled", "1")
local lootgoblin_weapons_dropped = CreateConVar("ttt_lootgoblin_weapons_dropped", "8", FCVAR_NONE, "How many weapons the loot goblin drops when they are killed", 0, 10)
local lootgoblin_jingle_enabled = CreateConVar("ttt_lootgoblin_jingle_enabled", "1")
local lootgoblin_speed_mult = CreateConVar("ttt_lootgoblin_speed_mult", "1.2", FCVAR_NONE, "The multiplier to use on the loot goblin's movement speed when they are activated (e.g. 1.2 = 120% normal speed)", 1, 2)
local lootgoblin_sprint_recovery = CreateConVar("ttt_lootgoblin_sprint_recovery", "0.12", FCVAR_NONE, "The amount of stamina to recover per tick when the loot goblin is activated", 0, 1)
local lootgoblin_regen_mode = CreateConVar("ttt_lootgoblin_regen_mode", "2", FCVAR_NONE, "Whether the loot goblin should regenerate health and using what logic. 0 - No regeneration. 1 - Constant regen while active. 2 - Regen while standing still. 3 - Regen after taking damage", 0, 3)
local lootgoblin_regen_rate = CreateConVar("ttt_lootgoblin_regen_rate", "3", FCVAR_NONE, "How often (in seconds) a loot goblin should regain health while regenerating", 1, 60)
local lootgoblin_regen_delay = CreateConVar("ttt_lootgoblin_regen_delay", "0", FCVAR_NONE, "The length of the delay (in seconds) before the loot goblin's health will start to regenerate", 0, 60)
local lootgoblin_radar_enabled = CreateConVar("ttt_lootgoblin_radar_enabled", "0", FCVAR_NONE, "Whether the radar ping for the loot goblin should be enabled or not", 0, 1)
local lootgoblin_radar_timer = CreateConVar("ttt_lootgoblin_radar_timer", "15", FCVAR_NONE, "How often (in seconds) the radar ping for the loot goblin should update", 1, 60)
local lootgoblin_radar_delay = CreateConVar("ttt_lootgoblin_radar_delay", "15", FCVAR_NONE, "How dealyed (in seconds) the radar ping for the loot goblin should be", 1, 60)

hook.Add("TTTSyncGlobals", "LootGoblin_TTTSyncGlobals", function()
    SetGlobalFloat("ttt_lootgoblin_speed_mult", lootgoblin_speed_mult:GetFloat())
    SetGlobalFloat("ttt_lootgoblin_sprint_recovery", lootgoblin_sprint_recovery:GetFloat())
    SetGlobalInt("ttt_lootgoblin_regen_mode", lootgoblin_regen_mode:GetInt())
    SetGlobalInt("ttt_lootgoblin_regen_delay", lootgoblin_regen_delay:GetInt())
    SetGlobalInt("ttt_revenger_radar_timer", lootgoblin_radar_timer:GetInt())
end)

-----------
-- KARMA --
-----------

-- The loot goblin has no karma, positive or negative
hook.Add("TTTKarmaGivePenalty", "LootGoblin_TTTKarmaGivePenalty", function(ply, penalty, victim)
    if IsPlayer(victim) and (ply:IsLootGoblin() or victim:IsLootGoblin())  then
        return true
    end
end)
hook.Add("TTTKarmaGiveReward", "LootGoblin_TTTKarmaGiveReward", function(ply, reward, victim)
    if IsPlayer(victim) and (ply:IsLootGoblin() or victim:IsLootGoblin()) then
        return true
    end
end)

-----------
-- REGEN --
-----------

local function StartRegen(ply)
    local rate = lootgoblin_regen_rate:GetInt()
    timer.Create("LootGoblinRegen_" .. ply:SteamID64(), rate, 0, function()
        if ply:Alive() and not ply:IsSpec() and ply:IsLootGoblin() then
            local hp = ply:Health()
            if hp < ply:GetMaxHealth() then
                ply:SetHealth(hp + 1)
            end
        end
    end)
end

local function StopRegen(ply)
    timer.Remove("LootGoblinRegen_" .. ply:SteamID64())
    timer.Remove("LootGoblinRegenDelay_" .. ply:SteamID64())
end

local function HandleRegen(ply, delay_override)
    local delay = delay_override or lootgoblin_regen_delay:GetInt()
    if delay > 0 then
        timer.Create("LootGoblinRegenDelay_" .. ply:SteamID64(), delay, 0, function()
            StartRegen(ply)
        end)
    else
        StartRegen(ply)
    end
end

local playermoveloc = {}
hook.Add("FinishMove", "LootGoblin_FinishMove", function(ply, mv)
    local mode = lootgoblin_regen_mode:GetInt()
    if mode ~= LOOTGOBLIN_REGEN_MODE_STILL then return end

    if ply:IsActiveLootGoblin() and ply:IsRoleActive() then
        local loc = ply:GetPos()
        local sid64 = ply:SteamID64()
        -- Keep track of when a player moves and stop regeneration when they do
        if playermoveloc[sid64] == nil or math.abs(playermoveloc[sid64]:Distance(loc)) > 0 then
            StopRegen(ply)
            playermoveloc[sid64] = loc
        -- If regen stuff hasn't started yet, do it
        elseif not timer.Exists("LootGoblinRegen_" .. sid64) and not timer.Exists("LootGoblinRegenDelay_" .. sid64) then
            HandleRegen(ply)
        end
    end
end)

hook.Add("PostEntityTakeDamage", "LootGoblin_PostEntityTakeDamage", function(ent, dmginfo, taken)
    if not taken then return end
    if not IsPlayer(ent) then return end

    local dmg = dmginfo:GetDamage()
    if dmg <= 0 then return end

    if not ent:IsActiveLootGoblin() or not ent:IsRoleActive() then return end

    local mode = lootgoblin_regen_mode:GetInt()
    if mode ~= LOOTGOBLIN_REGEN_MODE_AFTER_DAMAGE then return end

    StopRegen(ent)
    HandleRegen(ent)
end)

----------------------
-- HELPER FUNCTIONS --
----------------------

local cackles = {
    Sound("lootgoblin/cackle1.wav"),
    Sound("lootgoblin/cackle2.wav"),
    Sound("lootgoblin/cackle3.wav")
}
local defaultJumpPower = 160
local lootGoblinActive = false

local function ActivateLootGoblin(ply)
    ply:SetNWBool("LootGoblinActive", true)
    ply:PrintMessage(HUD_PRINTTALK, "You have transformed into a goblin!")

    local mode = lootgoblin_regen_mode:GetInt()
    if mode == LOOTGOBLIN_REGEN_MODE_ALWAYS then
        HandleRegen(ply)
    end

    local scale = lootgoblin_size:GetFloat()
    ply:SetPlayerScale(scale)
    local jumpPower = defaultJumpPower
    -- Compensate the jump power of smaller players so they have roughly the same jump height as normal
    -- In testing, scales >= 1 all seem to work fine with the default jump power and that's not the intent of this role anyway
    if scale < 1 then
        -- Derived formula is y = -120x + 280
        -- We take the base jump power out of this as a known constant and then
        -- give a small jump boost of 5 extra power to "round up" the jump estimates
        -- so that smaller sizes can still clear jump+crouch blocks
        jumpPower = jumpPower + (-(120 * scale) + 125)
    end
    ply:SetJumpPower(jumpPower)

    if lootgoblin_radar_enabled:GetBool() then
        net.Start("TTT_LootGoblinRadar")
        net.WriteBool(true)
        net.Broadcast()
    end
end

local function StartGoblinTimers()
    local goblinTimeMin = lootgoblin_activation_timer:GetInt()
    local goblinTimeMax = lootgoblin_activation_timer_max:GetInt()
    if goblinTimeMax < goblinTimeMin then
        goblinTimeMax = goblinTimeMin
    end
    local goblinTime = MathRandom(goblinTimeMin, goblinTimeMax)
    SetGlobalFloat("ttt_lootgoblin_activate", CurTime() + goblinTime)
    for _, v in ipairs(GetAllPlayers()) do
        if v:IsActiveLootGoblin() then
            v:PrintMessage(HUD_PRINTTALK, "You will transform into a goblin in " .. tostring(goblinTime) .. " seconds!")
        end
    end
    timer.Create("LootGoblinActivate", goblinTime, 1, function()
        lootGoblinActive = true
        local revealMode = lootgoblin_announce:GetInt()
        for _, v in ipairs(GetAllPlayers()) do
            if v:IsActiveLootGoblin() then
                ActivateLootGoblin(v)
            elseif revealMode == JESTER_NOTIFY_EVERYONE or
                    (v:IsActiveTraitorTeam() and (revealMode == JESTER_NOTIFY_TRAITOR or JESTER_NOTIFY_DETECTIVE_AND_TRAITOR)) or
                    (not v:IsActiveDetectiveLike() and (revealMode == JESTER_NOTIFY_DETECTIVE or JESTER_NOTIFY_DETECTIVE_AND_TRAITOR)) then
                local message = string.Capitalize(ROLE_STRINGS_EXT[ROLE_LOOTGOBLIN]) .. " has been spotted!"
                v:PrintMessage(HUD_PRINTTALK, message)
                v:PrintMessage(HUD_PRINTCENTER, message)
            end
        end

        if lootgoblin_cackle_enabled:GetBool() then
            local min = lootgoblin_cackle_timer_min:GetInt()
            local max = lootgoblin_cackle_timer_max:GetInt()
            if max < min then
                max = min
            end
            timer.Create("LootGoblinCackle", MathRandom(min, max), 0, function()
                for _, v in ipairs(GetAllPlayers()) do
                    if v:IsActiveLootGoblin() and not v:GetNWBool("LootGoblinKilled", false) then
                        local idx = MathRandom(1, #cackles)
                        local chosen_sound = cackles[idx]
                        sound.Play(chosen_sound, v:GetPos())
                    end
                end
                timer.Adjust("LootGoblinCackle", MathRandom(min, max), 0, nil)
            end)
        end
    end)
end

----------------
-- WIN CHECKS --
----------------

local function HandleLootGoblinWinChecks(win_type)
    if win_type == WIN_NONE then return end

    local hasLootGoblin = false
    for _, v in ipairs(GetAllPlayers()) do
        if v:IsActiveLootGoblin() and not v:GetNWBool("LootGoblinKilled", false) then
            hasLootGoblin = true
        end
    end
    if not hasLootGoblin then return end

    net.Start("TTT_UpdateLootGoblinWins")
    net.WriteBool(true)
    net.Broadcast()
end
hook.Add("TTTWinCheckComplete", "LootGoblin_TTTWinCheckComplete", HandleLootGoblinWinChecks)

------------
-- TIMERS --
------------

hook.Add("TTTBeginRound", "LootGoblin_TTTBeginRound", function()
    if player.IsRoleLiving(ROLE_LOOTGOBLIN) then
        StartGoblinTimers()
    end
end)

---------------
-- FOOTSTEPS --
---------------

-- Play a jingling sound whenever an activated loot goblin takes a step
local footsteps = {
    Sound("lootgoblin/jingle1.wav"),
    Sound("lootgoblin/jingle2.wav"),
    Sound("lootgoblin/jingle3.wav"),
    Sound("lootgoblin/jingle4.wav"),
    Sound("lootgoblin/jingle5.wav"),
    Sound("lootgoblin/jingle6.wav"),
    Sound("lootgoblin/jingle7.wav"),
    Sound("lootgoblin/jingle8.wav")
}
hook.Add("PlayerFootstep", "LootGoblin_PlayerFootstep", function(ply, pos, foot, snd, volume, rf)
    if ply:IsActiveLootGoblin() and ply:IsRoleActive() and not ply:GetNWBool("LootGoblinKilled", false) and lootgoblin_jingle_enabled:GetBool() then
        local idx = MathRandom(1, #footsteps)
        local chosen_sound = footsteps[idx]
        sound.Play(chosen_sound, pos, volume, 100, 1)
    end
end)

-----------
-- DEATH --
-----------

local function PauseIfSingleGoblin()
    if not timer.Exists("LootGoblinActivate") then return end
    if GetRoundState() ~= ROUND_ACTIVE then return end

    if not player.IsRoleLiving(ROLE_LOOTGOBLIN) then
        timer.Pause("LootGoblinActivate")
    end
end

hook.Add("PlayerDeath", "LootGoblin_PlayerDeath", function(victim, infl, attacker)
    if victim:IsLootGoblin() then
        if victim:IsRoleActive() and not victim:GetNWBool("LootGoblinKilled", false) then
            JesterTeamKilledNotification(attacker, victim,
            -- getkillstring
                    function()
                        return "The " .. ROLE_STRINGS[ROLE_LOOTGOBLIN] .. " has been killed!"
                    end)
            local lootTable = {}
            timer.Create("LootGoblinWeaponDrop", 0.05, lootgoblin_weapons_dropped:GetInt(), function()
                if #lootTable == 0 then -- Rebuild the loot table if we run out
                    for _, v in ipairs(weapons.GetList()) do
                        if v and not v.AutoSpawnable and v.CanBuy and v.AllowDrop then
                            table.insert(lootTable, WEPS.GetClass(v))
                        end
                    end
                end

                local ragdoll = victim.server_ragdoll or victim:GetRagdollEntity()
                local pos = ragdoll:GetPos() + Vector(0, 0, 25)

                local idx = MathRandom(1, #lootTable)
                local wep = lootTable[idx]
                table.remove(lootTable, idx)
                local ent = CreateEntity(wep)
                ent:SetPos(pos)
                ent:Spawn()

                local phys = ent:GetPhysicsObject()
                if phys:IsValid() then phys:ApplyForceCenter(Vector(math.Rand(-100, 100), math.Rand(-100, 100), 300) * phys:GetMass()) end
            end)
        end

        StopRegen(victim)
        PauseIfSingleGoblin()
    end
end)

-----------
-- RADAR --
-----------

local goblins = {}
hook.Add("TTTBeginRound", "LootGoblin_Radar_TTTBeginRound", function()
    for _, v in ipairs(GetAllPlayers()) do
        v:SetNWVector("TTTLootGoblinRadar", v:LocalToWorld(v:OBBCenter())) -- Fallback just in case
    end

    timer.Create("LootGoblinRadarDelay", 1, 0, function()
        for _, v in ipairs(GetAllPlayers()) do
            if v:IsActiveLootGoblin() then
                local locations = goblins[v:SteamID64()]
                if locations == nil then
                    locations = {}
                end
                TableInsert(locations, v:LocalToWorld(v:OBBCenter()))
                if #locations > lootgoblin_radar_delay:GetInt() then
                    v:SetNWVector("TTTLootGoblinRadar", locations[1])
                    TableRemove(locations, 1)
                end
                goblins[v:SteamID64()] = locations
            end
        end
    end)
end)

-------------
-- CLEANUP --
-------------

local function ResetPlayer(ply)
    ply:SetNWBool("LootGoblinActive", false)
    ply:ResetPlayerScale()
    ply:SetJumpPower(defaultJumpPower)
    StopRegen(ply)
    PauseIfSingleGoblin()
end

hook.Add("TTTPrepareRound", "LootGoblin_PrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        v:SetNWBool("LootGoblinKilled", false)
        v:SetNWVector("TTTLootGoblinRadar", Vector(0, 0, 0))
        ResetPlayer(v)
    end
    net.Start("TTT_LootGoblinRadar")
    net.WriteBool(false)
    net.Broadcast()
end)

hook.Add("TTTPlayerSpawnForRound", "LootGoblin_TTTPlayerSpawnForRound", function(ply, deadOnly)
    if ply:IsLootGoblin() then
        if lootGoblinActive then
            if ply:IsRoleActive() then
                ply:SetNWBool("LootGoblinKilled", true)
            else
                ActivateLootGoblin(ply)
            end
        elseif timer.Exists("LootGoblinActivate") then
            timer.UnPause("LootGoblinActivate")
            local remaining = timer.TimeLeft("LootGoblinActivate")
            SetGlobalFloat("ttt_lootgoblin_activate", CurTime() + remaining)
        end
    end
end)

hook.Add("TTTPlayerRoleChanged", "LootGoblin_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if oldRole == ROLE_LOOTGOBLIN then
        ResetPlayer(ply)
    elseif newRole == ROLE_LOOTGOBLIN then
        if lootGoblinActive then
            ActivateLootGoblin(ply)
        elseif not timer.Exists("LootGoblinActivate") then
            StartGoblinTimers()
        else
            timer.UnPause("LootGoblinActivate")
            local remaining = timer.TimeLeft("LootGoblinActivate")
            SetGlobalFloat("ttt_lootgoblin_activate", CurTime() + remaining)
        end
    end
end)

hook.Add("TTTEndRound", "LootGoblin_TTTEndRound", function()
    timer.Remove("LootGoblinActivate")
    timer.Remove("LootGoblinCackle")
    timer.Remove("LootGoblinRadarDelay")
    lootGoblinActive = false
end)