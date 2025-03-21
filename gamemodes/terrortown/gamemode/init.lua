---- Trouble in Terrorist Town

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("init_shd.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_msgstack.lua")
AddCSLuaFile("cl_hudpickup.lua")
AddCSLuaFile("cl_keys.lua")
AddCSLuaFile("cl_wepswitch.lua")
AddCSLuaFile("cl_awards.lua")
AddCSLuaFile("cl_scoring_events.lua")
AddCSLuaFile("cl_scoring.lua")
AddCSLuaFile("cl_popups.lua")
AddCSLuaFile("cl_equip.lua")
AddCSLuaFile("equip_items_shd.lua")
AddCSLuaFile("cl_help.lua")
AddCSLuaFile("cl_scoreboard.lua")
AddCSLuaFile("cl_tips.lua")
AddCSLuaFile("cl_voice.lua")
AddCSLuaFile("scoring_shd.lua")
AddCSLuaFile("util.lua")
AddCSLuaFile("lang_shd.lua")
AddCSLuaFile("corpse_shd.lua")
AddCSLuaFile("player_ext_shd.lua")
AddCSLuaFile("weaponry_shd.lua")
AddCSLuaFile("cl_radio.lua")
AddCSLuaFile("cl_radar.lua")
AddCSLuaFile("cl_tbuttons.lua")
AddCSLuaFile("cl_disguise.lua")
AddCSLuaFile("cl_transfer.lua")
AddCSLuaFile("cl_search.lua")
AddCSLuaFile("cl_targetid.lua")
AddCSLuaFile("cl_rolepacks.lua")
AddCSLuaFile("cl_roleblocks.lua")
AddCSLuaFile("cl_roleweapons.lua")
AddCSLuaFile("vgui/ColoredBox.lua")
AddCSLuaFile("vgui/SimpleIcon.lua")
AddCSLuaFile("vgui/ProgressBar.lua")
AddCSLuaFile("vgui/ScrollLabel.lua")
AddCSLuaFile("vgui/sb_main.lua")
AddCSLuaFile("vgui/sb_row.lua")
AddCSLuaFile("vgui/sb_team.lua")
AddCSLuaFile("vgui/sb_info.lua")
AddCSLuaFile("cl_hitmarkers.lua")
AddCSLuaFile("cl_deathnotify.lua")
AddCSLuaFile("cl_sprint.lua")
AddCSLuaFile("sprint_shd.lua")
AddCSLuaFile("cl_cheatsheet.lua")
AddCSLuaFile("cl_sync.lua")

include("shared.lua")
include("init_shd.lua")

include("incompatible_addons.lua")
include("karma.lua")
include("entity.lua")
include("radar.lua")
include("admin.lua")
include("traitor_state.lua")
include("propspec.lua")
include("weaponry.lua")
include("gamemsg.lua")
include("ent_replace.lua")
include("scoring.lua")
include("corpse.lua")
include("player_ext_shd.lua")
include("player_ext.lua")
include("player.lua")
include("hitmarkers.lua")
include("deathnotify.lua")
include("roleweapons.lua")
include("sprint_shd.lua")
include("rolepacks.lua")
include("roleblocks.lua")
include("sync.lua")

-- Localise stuff we use often. It's like Lua go-faster stripes.
local concommand = concommand
local cvars = cvars
local ents = ents
local file = file
local hook = hook
local ipairs = ipairs
local IsValid = IsValid
local math = math
local net = net
local pairs = pairs
local player = player
local string = string
local table = table
local timer = timer
local util = util

local CallHook = hook.Call
local RunHook = hook.Run
local GetAllPlayers = player.GetAll
local PlayerIterator = player.Iterator
local MathRand = math.Rand
local StringFormat = string.format
local StringLower = string.lower
local StringUpper = string.upper

-- Round times
CreateConVar("ttt_roundtime_minutes", "10", FCVAR_NOTIFY)
CreateConVar("ttt_preptime_seconds", "30", FCVAR_NOTIFY)
CreateConVar("ttt_posttime_seconds", "30", FCVAR_NOTIFY)
CreateConVar("ttt_firstpreptime", "60")

-- Haste mode
local ttt_haste = CreateConVar("ttt_haste", "1", FCVAR_NOTIFY)
CreateConVar("ttt_haste_starting_minutes", "5", FCVAR_NOTIFY)
CreateConVar("ttt_haste_minutes_per_death", "0.5", FCVAR_NOTIFY)

-- Player Spawning
CreateConVar("ttt_spawn_wave_interval", "0")

CreateConVar("ttt_traitor_pct", "0.25")
CreateConVar("ttt_traitor_max", "32")

CreateConVar("ttt_detective_pct", "0.13", FCVAR_NOTIFY)
CreateConVar("ttt_detective_max", "32")
CreateConVar("ttt_detective_min_players", "8")
local detective_karma_min = CreateConVar("ttt_detective_karma_min", "600")

-- Role spawn parameters
CreateConVar("ttt_independent_chance", 0.5)
CreateConVar("ttt_jester_chance", 0.5)

CreateConVar("ttt_monster_max", "1")
CreateConVar("ttt_monster_pct", 0.33)
CreateConVar("ttt_monster_chance", 0.5)

for role = 0, ROLE_MAX do
    local rolestring = ROLE_STRINGS_RAW[role]
    if not DEFAULT_ROLES[role] and not ROLE_BLOCK_SPAWN_CONVARS[role] then
        CreateConVar("ttt_" .. rolestring .. "_spawn_weight", "1")
        CreateConVar("ttt_" .. rolestring .. "_min_players", "0")
    end

    if not ROLE_BLOCK_HEALTH_CONVARS[role] then
        local starting_health = "100"
        if ROLE_STARTING_HEALTH[role] then starting_health = ROLE_STARTING_HEALTH[role] end

        local max_health = nil
        if ROLE_MAX_HEALTH[role] then max_health = ROLE_MAX_HEALTH[role] end

        CreateConVar("ttt_" .. rolestring .. "_starting_health", starting_health)
        CreateConVar("ttt_" .. rolestring .. "_max_health", max_health or starting_health)
    end
end

-- Jester role properties
CreateConVar("ttt_jesters_trigger_traitor_testers", "1")

-- Independent role properties
CreateConVar("ttt_independents_trigger_traitor_testers", "0")

-- Do this here so the convars are created early enough to be used by ULX
for role = 0, ROLE_MAX do
    if role ~= ROLE_DRUNK and role ~= ROLE_GLITCH then
        CreateConVar("ttt_drunk_can_be_" .. ROLE_STRINGS_RAW[role], "1")
    end
end

-- Other custom role properties
CreateConVar("ttt_multiple_jesters_independents", "0")
CreateConVar("ttt_jester_independent_pct", "0.13")
CreateConVar("ttt_jester_independent_max", "2")
CreateConVar("ttt_jester_independent_chance", "0.5")
CreateConVar("ttt_deputy_impersonator_promote_any_death", "0")
CreateConVar("ttt_deputy_impersonator_start_promoted", "0")
CreateConVar("ttt_single_jester_independent", "1")
CreateConVar("ttt_single_jester_independent_max_players", "0")

-- Traitor credits
CreateConVar("ttt_credits_starting", "2")
CreateConVar("ttt_credits_award_pct", "0.35")
CreateConVar("ttt_credits_award_size", "1")
CreateConVar("ttt_credits_award_repeat", "1")
CreateConVar("ttt_credits_detectivekill", "1")
CreateConVar("ttt_credits_alonebonus", "1")

-- Detective credits
CreateConVar("ttt_det_credits_starting", "1")
CreateConVar("ttt_det_credits_traitorkill", "0")
CreateConVar("ttt_det_credits_traitordead", "1")

-- Other
CreateConVar("ttt_use_weapon_spawn_scripts", "1")
CreateConVar("ttt_weapon_spawn_count", "0")

CreateConVar("ttt_round_limit", "6", FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED)
CreateConVar("ttt_time_limit_minutes", "75", FCVAR_NOTIFY + FCVAR_REPLICATED)

CreateConVar("ttt_idle_limit", "180", FCVAR_NOTIFY)

CreateConVar("ttt_voice_drain", "0", FCVAR_NOTIFY)
CreateConVar("ttt_voice_drain_normal", "0.2", FCVAR_NOTIFY)
CreateConVar("ttt_voice_drain_admin", "0.05", FCVAR_NOTIFY)
CreateConVar("ttt_voice_drain_recharge", "0.05", FCVAR_NOTIFY)

CreateConVar("ttt_namechange_kick", "1", FCVAR_NOTIFY)
CreateConVar("ttt_namechange_bantime", "10")

CreateConVar("ttt_disable_headshots", "0")
CreateConVar("ttt_disable_mapwin", "0")

-- bem server convars
CreateConVar("ttt_bem_allow_change", 1, { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE }, "Allow clients to change the look of the shop menu")
CreateConVar("ttt_bem_sv_cols", 4, { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE }, "Sets the number of columns in the shop menu's item list (serverside)")
CreateConVar("ttt_bem_sv_rows", 5, { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE }, "Sets the number of rows in the shop menu's item list (serverside)")
CreateConVar("ttt_bem_sv_size", 64, { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE }, "Sets the item size in the shop menu's item list (serverside)")

local ttt_detective = CreateConVar("ttt_sherlock_mode", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY)
local ttt_minply = CreateConVar("ttt_minimum_players", "2", FCVAR_ARCHIVE + FCVAR_NOTIFY)

-- debuggery
local ttt_dbgwin = CreateConVar("ttt_debug_preventwin", "0")
CreateConVar("ttt_debug_logkills", "1")
local ttt_dbgroles = CreateConVar("ttt_debug_logroles", "1")

-- Pool some network names.
util.AddNetworkString("TTT_RoundState")
util.AddNetworkString("TTT_RagdollSearch")
util.AddNetworkString("TTT_GameMsg")
util.AddNetworkString("TTT_GameMsgColor")
util.AddNetworkString("TTT_RoleChat")
util.AddNetworkString("TTT_TraitorVoiceState")
util.AddNetworkString("TTT_LastWordsMsg")
util.AddNetworkString("TTT_RadioMsg")
util.AddNetworkString("TTT_ReportStream")
util.AddNetworkString("TTT_ReportStream_Part")
util.AddNetworkString("TTT_LangMsg")
util.AddNetworkString("TTT_ServerLang")
util.AddNetworkString("TTT_Equipment")
util.AddNetworkString("TTT_Credits")
util.AddNetworkString("TTT_Bought")
util.AddNetworkString("TTT_BoughtItem")
util.AddNetworkString("TTT_InterruptChat")
util.AddNetworkString("TTT_PlayerSpawned")
util.AddNetworkString("TTT_PlayerDied")
util.AddNetworkString("TTT_PlayerDisconnected")
util.AddNetworkString("TTT_CorpseCall")
util.AddNetworkString("TTT_RemoveCorpseCall")
util.AddNetworkString("TTT_ClearClientState")
util.AddNetworkString("TTT_ClearSearchResult")
util.AddNetworkString("TTT_PerformGesture")
util.AddNetworkString("TTT_Role")
util.AddNetworkString("TTT_RoleList")
util.AddNetworkString("TTT_ConfirmUseTButton")
util.AddNetworkString("TTT_C4Config")
util.AddNetworkString("TTT_C4DisarmResult")
util.AddNetworkString("TTT_C4Warn")
util.AddNetworkString("TTT_SendSamples")
util.AddNetworkString("TTT_ShowPrints")
util.AddNetworkString("TTT_TakeSample")
util.AddNetworkString("TTT_ScanResult")
util.AddNetworkString("TTT_FlareScorch")
util.AddNetworkString("TTT_Radar")
util.AddNetworkString("TTT_Spectate")
util.AddNetworkString("TTT_TeleportMark")
util.AddNetworkString("TTT_ClearRadarExtras")
util.AddNetworkString("TTT_Defibrillated")
util.AddNetworkString("TTT_RoleChanged")
util.AddNetworkString("TTT_LogInfo")
util.AddNetworkString("TTT_BuyableWeapons")
util.AddNetworkString("TTT_UpdateBuyableWeapons")
util.AddNetworkString("TTT_ResetBuyableWeaponsCache")
util.AddNetworkString("TTT_ConfigureRoleWeapons")
util.AddNetworkString("TTT_RoleWeaponsLoaded")
util.AddNetworkString("TTT_ClearRoleWeapons")
util.AddNetworkString("TTT_PlayerFootstep")
util.AddNetworkString("TTT_ClearPlayerFootsteps")
util.AddNetworkString("TTT_JesterDeathCelebration")
util.AddNetworkString("TTT_LoadMonsterEquipment")
util.AddNetworkString("TTT_UpdateRoleNames")
util.AddNetworkString("TTT_ScoreboardUpdate")
util.AddNetworkString("TTT_QueueMessage")
util.AddNetworkString("TTT_ClearQueuedMessage")

local function ClearAllFootsteps()
    net.Start("TTT_ClearPlayerFootsteps")
    net.Broadcast()
end

---- Round mechanics
function GM:Initialize()
    MsgN("Trouble In Terrorist Town gamemode initializing...")

    -- Force friendly fire to be enabled. If it is off, we do not get lag compensation.
    RunConsoleCommand("mp_friendlyfire", "1")

    -- Default crowbar unlocking settings, may be overridden by config entity
    GAMEMODE.crowbar_unlocks = {
        [OPEN_DOOR] = true,
        [OPEN_ROT] = true,
        [OPEN_BUT] = true,
        [OPEN_NOTOGGLE] = true
    };

    -- More map config ent defaults
    GAMEMODE.force_plymodel = ""
    GAMEMODE.propspec_allow_named = false

    GAMEMODE.MapWin = WIN_NONE
    GAMEMODE.AwardedCredits = false
    GAMEMODE.AwardedCreditsDead = 0

    GAMEMODE.round_state = ROUND_WAIT
    GAMEMODE.FirstRound = true
    GAMEMODE.RoundStartTime = 0

    GAMEMODE.DamageLog = {}
    GAMEMODE.LastRole = {}
    GAMEMODE.playermodel = GetRandomPlayerModel()
    GAMEMODE.playercolor = COLOR_WHITE

    -- Delay reading of cvars until config has definitely loaded
    GAMEMODE.cvar_init = false

    SetGlobalFloat("ttt_round_end", -1)
    SetGlobalFloat("ttt_haste_end", -1)

    -- For the paranoid
    math.randomseed(os.time())

    WaitForPlayers()
    WEPS.HandleRoleEquipment()

    if cvars.Number("sv_alltalk", 0) > 0 then
        ErrorNoHalt("TTT WARNING: sv_alltalk is enabled. Dead players will be able to talk to living players. TTT will now attempt to set sv_alltalk 0.\n")
        RunConsoleCommand("sv_alltalk", "0")
    end

    if not IsMounted("cstrike") then
        ErrorNoHalt("TTT WARNING: CS:S does not appear to be mounted by GMod. Things may break in strange ways. Server admin? Check the TTT readme for help.\n")
    end
end

-- Used to do this in Initialize, but server cfg has not always run yet by that
-- point.
function GM:InitCvars()
    MsgN("TTT initializing convar settings...")

    local map_config = StringFormat("cfg/%s.cfg", game.GetMap())
    if file.Exists(map_config, "GAME") then
        MsgN("Loading map-specific config from " .. map_config)
        util.ExecFile(map_config, true)
    end

    -- Initialize game state that is synced with client
    SetGlobalInt("ttt_rounds_left", GetConVar("ttt_round_limit"):GetInt())
    GAMEMODE:SyncGlobals()
    KARMA.InitState()

    UpdateRoleStrings()

    self.cvar_init = true
end

function GM:InitPostEntity()
    WEPS.ForcePrecache()
end

-- Convar replication is broken in gmod, so we do this.
-- I don't like it any more than you do, dear reader.
function GM:SyncGlobals()
    -- For some reason hooking "SyncGlobals" directly is unreliable so... here we go
    CallHook("TTTSyncGlobals", nil)

    SetGlobalBool("ttt_detective", ttt_detective:GetBool())
    SetGlobalBool("ttt_haste", ttt_haste:GetBool())
    SetGlobalInt("ttt_time_limit_minutes", GetConVar("ttt_time_limit_minutes"):GetInt())
    SetGlobalBool("ttt_highlight_admins", GetConVar("ttt_highlight_admins"):GetBool())
    SetGlobalBool("ttt_locational_voice", GetConVar("ttt_locational_voice"):GetBool())
    SetGlobalInt("ttt_idle_limit", GetConVar("ttt_idle_limit"):GetInt())

    SetGlobalBool("ttt_voice_drain", GetConVar("ttt_voice_drain"):GetBool())
    SetGlobalFloat("ttt_voice_drain_normal", GetConVar("ttt_voice_drain_normal"):GetFloat())
    SetGlobalFloat("ttt_voice_drain_admin", GetConVar("ttt_voice_drain_admin"):GetFloat())
    SetGlobalFloat("ttt_voice_drain_recharge", GetConVar("ttt_voice_drain_recharge"):GetFloat())

    SetGlobalFloat("ttt_karma_strict", GetConVar("ttt_karma_strict"):GetBool())
    SetGlobalFloat("ttt_karma_lenient", GetConVar("ttt_karma_lenient"):GetBool())

    SetGlobalBool("ttt_bem_allow_change", GetConVar("ttt_bem_allow_change"):GetBool())
    SetGlobalInt("ttt_bem_sv_cols", GetConVar("ttt_bem_sv_cols"):GetInt())
    SetGlobalInt("ttt_bem_sv_rows", GetConVar("ttt_bem_sv_rows"):GetInt())
    SetGlobalInt("ttt_bem_sv_size", GetConVar("ttt_bem_sv_size"):GetInt())

    SetGlobalBool("sv_voiceenable", GetConVar("sv_voiceenable"):GetBool())

    UpdateRoleState()
end

function SendRoundState(state, ply)
    net.Start("TTT_RoundState")
    net.WriteUInt(state, 3)
    return ply and net.Send(ply) or net.Broadcast()
end

-- Round state is encapsulated by set/get so that it can easily be changed to
-- eg. a networked var if this proves more convenient
function SetRoundState(state)
    GAMEMODE.round_state = state

    SCORE:RoundStateChange(state)

    SendRoundState(state)
end

function GetRoundState()
    return GAMEMODE.round_state
end

local function EnoughPlayers()
    local ready = 0
    -- only count truly available players, ie. no forced specs
    for _, ply in PlayerIterator() do
        if IsValid(ply) and ply:ShouldSpawn() then
            ready = ready + 1
        end
    end
    return ready >= ttt_minply:GetInt()
end

-- Used to be in Think/Tick, now in a timer
function WaitingForPlayersChecker()
    if GetRoundState() == ROUND_WAIT then
        if EnoughPlayers() then
            timer.Create("wait2prep", 1, 1, PrepareRound)

            timer.Stop("waitingforply")
        end
    end
end

-- Start waiting for players
function WaitForPlayers()
    SetRoundState(ROUND_WAIT)

    if not timer.Start("waitingforply") then
        timer.Create("waitingforply", 2, 0, WaitingForPlayersChecker)
    end
end

-- When a player initially spawns after mapload, everything is a bit strange;
-- just making them spectator for some reason does not work right. Therefore,
-- we regularly check for these broken spectators while we wait for players
-- and immediately fix them.
function FixSpectators()
    for k, ply in PlayerIterator() do
        if ply:IsSpec() and not ply:GetRagdollSpec() and ply:GetMoveType() < MOVETYPE_NOCLIP then
            ply:Spectate(OBS_MODE_ROAMING)
        end
    end
end

local function GetPlayerName(ply)
    local name = ply:GetNWString("PlayerName", "")
    if not name or #name == 0 then
        name = ply:Nick()
    end
    return name
end

local function NameChangeKick()
    if not GetConVar("ttt_namechange_kick"):GetBool() then
        timer.Remove("namecheck")
        return
    end

    if GetRoundState() == ROUND_ACTIVE then
        for _, ply in ipairs(player.GetHumans()) do
            if ply.spawn_nick then
                if ply.has_spawned and ply.spawn_nick ~= GetPlayerName(ply) and not RunHook("TTTNameChangeKick", ply) then
                    local t = GetConVar("ttt_namechange_bantime"):GetInt()
                    local msg = "Changed name during a round"
                    if t > 0 then
                        ply:KickBan(t, msg)
                    else
                        ply:Kick(msg)
                    end
                end
            else
                ply.spawn_nick = GetPlayerName(ply)
            end
        end
    end
end

function StartNameChangeChecks()
    if not GetConVar("ttt_namechange_kick"):GetBool() then return end

    -- bring nicks up to date, may have been changed during prep/post
    for _, ply in PlayerIterator() do
        ply.spawn_nick = GetPlayerName(ply)
    end

    if not timer.Exists("namecheck") then
        timer.Create("namecheck", 3, 0, NameChangeKick)
    end
end

local function CleanUp()
    local et = ents.TTT
    -- if we are going to import entities, it's no use replacing HL2DM ones as
    -- soon as they spawn, because they'll be removed anyway
    et.SetReplaceChecking(not et.CanImportEntities(game.GetMap()))

    et.FixParentedPreCleanup()

    game.CleanUpMap(false, nil, function() et.FixParentedPostCleanup() end)

    -- Strip players now, so that their weapons are not seen by ReplaceEntities
    for k, v in PlayerIterator() do
        if IsValid(v) then
            v:StripWeapons()
        end
    end

    -- a different kind of cleanup
    hook.Remove("PlayerSay", "ULXMeCheck")
end

local function SpawnEntities()
    local et = ents.TTT
    -- Spawn weapons from script if there is one
    local import = et.CanImportEntities(game.GetMap())

    if import then
        et.ProcessImportScript(game.GetMap())
    else
        -- Replace HL2DM/ZM ammo/weps with our own
        et.ReplaceEntities()

        -- Populate CS:S/TF2 maps with extra guns
        et.PlaceExtraWeapons()
    end

    -- Replace weapons with similar types
    if et.ReplaceWeaponsFromPools then
        et.ReplaceWeaponsFromPools()
    end

    -- We're done resetting the map, unlock weapon pickups for the players about to respawn
    GAMEMODE.RespawningWeapons = false

    -- Finally, get players in there
    SpawnWillingPlayers()
end

local function StopRoundTimers()
    -- remove all timers
    timer.Stop("wait2prep")
    timer.Stop("prep2begin")
    timer.Stop("end2prep")
    timer.Stop("winchecker")
end

-- Make sure we have the players to do a round, people can leave during our
-- preparations so we'll call this numerous times
local function CheckForAbort()
    if not EnoughPlayers() then
        LANG.Msg("round_minplayers")
        StopRoundTimers()

        WaitForPlayers()
        return true
    end

    return false
end

function GM:TTTDelayRoundStartForVote()
    -- Can be used for custom voting systems
    --return true, 30
    return false
end

function PrepareRound()
    for _, v in PlayerIterator() do
        v:SetInvulnerable(false, false)
        v:SetNWVector("PlayerColor", Vector(1, 1, 1))
        -- Workaround to prevent GMod sprint from working
        v:SetRunSpeed(v:GetWalkSpeed())
        -- Clear out the resurrection checking data so roles don't get their old weapons back next round in specific circumstances
        v.Resurrecting = false
        v.DeathRoleWeapons = nil
        -- Clear out old ignition info so we don't misattribute stuff in the new round
        v.ignite_info = nil
        -- Clear the message queue so any messages from the previous round don't show update
        v:ResetMessageQueue()
    end

    -- Check playercount
    if CheckForAbort() then return end

    local delay_round, delay_length = RunHook("TTTDelayRoundStartForVote")

    if delay_round then
        delay_length = delay_length or 30

        LANG.Msg("round_voting", { num = delay_length })

        timer.Create("delayedprep", delay_length, 1, PrepareRound)
        return
    end

    -- Reset the map entities
    GAMEMODE.RespawningWeapons = true
    CleanUp()

    GAMEMODE.MapWin = WIN_NONE
    GAMEMODE.AwardedCredits = false
    GAMEMODE.AwardedCreditsDead = 0

    SCORE:Reset()

    -- Update damage scaling
    KARMA.RoundBegin()

    WEPS.ResetWeaponsCache()
    WEPS.ResetRoleWeaponCache()
    WEPS.ClearRetryTimers()

    -- New look. Random if no forced model set.
    GAMEMODE.playermodel = #GAMEMODE.force_plymodel == 0 and GetRandomPlayerModel() or GAMEMODE.force_plymodel
    GAMEMODE.playercolor = RunHook("TTTPlayerColor", GAMEMODE.playermodel)

    if CheckForAbort() then return end

    -- Schedule round start
    local ptime = GetConVar("ttt_preptime_seconds"):GetInt()
    if GAMEMODE.FirstRound then
        ptime = GetConVar("ttt_firstpreptime"):GetInt()
        GAMEMODE.FirstRound = false
    end

    -- Piggyback on "round end" time global var to show end of phase timer
    SetRoundEnd(CurTime() + ptime)

    timer.Create("prep2begin", ptime, 1, BeginRound)

    -- Mute for a second around traitor selection, to counter a dumb exploit
    -- related to traitor's mics cutting off for a second when they're selected.
    timer.Create("selectmute", ptime - 1, 1, function() MuteForRestart(true) end)

    LANG.Msg("round_begintime", { num = ptime })
    SetRoundState(ROUND_PREP)

    -- Delay spawning until next frame to avoid ent overload
    timer.Simple(0.01, SpawnEntities)

    -- Undo the roundrestart mute, though they will once again be muted for the
    -- selectmute timer.
    timer.Create("restartmute", 1, 1, function() MuteForRestart(false) end)

    net.Start("TTT_ClearClientState")
    net.Broadcast()
    net.Start("TTT_ClearRadarExtras")
    net.Broadcast()

    -- In case client's cleanup fails, make client set all players to innocent role
    timer.Simple(1, SendRoleReset)

    -- Tell hooks and map we started prep
    RunHook("TTTPrepareRound")
    for role = 0, ROLE_MAX do
        ROLE_STARTING_TEAM[role] = player.GetRoleTeam(role, false)
    end
    ClearAllFootsteps()
    ents.TTT.TriggerRoundStateOutputs(ROUND_PREP)
end

function SetRoundEnd(endtime)
    SetGlobalFloat("ttt_round_end", endtime)
end

function IncRoundEnd(incr)
    SetRoundEnd(GetGlobalFloat("ttt_round_end", 0) + incr)
end

function TellTraitorsAboutTraitors()
    local traitornicks = {}
    local hasGlitch = false
    for _, v in PlayerIterator() do
        if v:IsTraitorTeam() then
            table.insert(traitornicks, v:Nick())
        elseif v:IsGlitch() then
            table.insert(traitornicks, v:Nick())
            hasGlitch = true
        end
    end

    -- This is ugly as hell, but it's kinda nice to filter out the names of the
    -- traitors themselves in the messages to them
    for _, v in PlayerIterator() do
        if v:IsTraitorTeam() then
            if hasGlitch then
                v:QueueMessage(MSG_PRINTBOTH, "There is " .. ROLE_STRINGS_EXT[ROLE_GLITCH] .. ".")
            end

            if #traitornicks < 2 then
                LANG.Msg(v, "round_traitors_one", { role = ROLE_STRINGS[ROLE_TRAITOR] })
                return
            else
                local names = ""
                for _, name in ipairs(traitornicks) do
                    if name ~= v:Nick() then
                        names = names .. name .. ", "
                    end
                end
                names = utf8.sub(names, 1, -3)
                LANG.Msg(v, "round_traitors_more", { role = ROLE_STRINGS[ROLE_TRAITOR], names = names })
            end
        end
    end
end

function SpawnWillingPlayers(dead_only)
    local wave_delay = GetConVar("ttt_spawn_wave_interval"):GetFloat()

    -- simple method, should make this a case of the other method once that has
    -- been tested.
    if wave_delay <= 0 or dead_only then
        for k, ply in PlayerIterator() do
            if IsValid(ply) then
                ply:SpawnForRound(dead_only)
            end
        end
    else
        -- wave method
        local num_spawns = #GetSpawnEnts()

        local to_spawn = {}
        for _, ply in RandomPairs(GetAllPlayers()) do
            if IsValid(ply) and ply:ShouldSpawn() then
                table.insert(to_spawn, ply)
                GAMEMODE:PlayerSpawnAsSpectator(ply)
            end
        end

        local sfn = function()
            local c = 0
            -- fill the available spawnpoints with players that need
            -- spawning
            while c < num_spawns and #to_spawn > 0 do
                for k, ply in ipairs(to_spawn) do
                    if IsValid(ply) and ply:SpawnForRound() then
                        -- a spawn ent is now occupied
                        c = c + 1
                    end
                    -- Few possible cases:
                    -- 1) player has now been spawned
                    -- 2) player should remain spectator after all
                    -- 3) player has disconnected
                    -- In all cases we don't need to spawn them again.
                    table.remove(to_spawn, k)

                    -- all spawn ents are occupied, so the rest will have
                    -- to wait for next wave
                    if c >= num_spawns then
                        break
                    end
                end
            end

            MsgN("Spawned " .. c .. " players in spawn wave.")

            if #to_spawn == 0 then
                timer.Remove("spawnwave")
                MsgN("Spawn waves ending, all players spawned.")
            end
        end

        MsgN("Spawn waves starting.")
        timer.Create("spawnwave", wave_delay, 0, sfn)

        -- already run one wave, which may stop the timer if everyone is spawned
        -- in one go
        sfn()
    end
end

local function InitRoundEndTime()
    -- Init round values
    local endtime = CurTime() + (GetConVar("ttt_roundtime_minutes"):GetInt() * 60)
    if HasteMode() then
        endtime = CurTime() + (GetConVar("ttt_haste_starting_minutes"):GetInt() * 60)
        -- this is a "fake" time shown to innocents, showing the end time if no
        -- one would have been killed, it has no gameplay effect
        SetGlobalFloat("ttt_haste_end", endtime)
    end

    SetRoundEnd(endtime)
end

local colorGenerationHue = MathRand(0, 360)
function BeginRound()
    GAMEMODE:SyncGlobals()

    if CheckForAbort() then return end

    WEPS.HandleRoleEquipment()
    InitRoundEndTime()

    if CheckForAbort() then return end

    -- Respawn dumb people who died during prep
    SpawnWillingPlayers(true)

    -- Remove their ragdolls
    ents.TTT.RemoveRagdolls(true)

    -- Check for low-karma players that weren't banned on round end
    if KARMA.cv.autokick:GetBool() then KARMA.CheckAutoKickAll() end

    if CheckForAbort() then return end

    -- Select traitors & co. This is where things really start so we can't abort
    -- anymore.
    SelectRoles()
    LANG.Msg("round_selected", { role = ROLE_STRINGS_PLURAL[ROLE_TRAITOR] })
    SendFullStateUpdate()

    -- Edge case where a player joins just as the round starts and is picked as
    -- traitor, but for whatever reason does not get the traitor state msg. So
    -- re-send after a second just to make sure everyone is getting it.
    timer.Simple(1, SendFullStateUpdate)
    timer.Simple(10, SendFullStateUpdate)

    SCORE:HandleSelection() -- log traitors and detectives

    for _, v in PlayerIterator() do
        v:SetInvulnerable(false, false)
        -- Player color
        -- Generate a new color, but make sure it's not too bright or too dark
        local col = HSLToColor(colorGenerationHue, MathRand(0.5, 1), MathRand(0.25, 0.75))
        -- Add the golden ratio conjugate (multiplied by 360) to the previous hue to get the next one
        colorGenerationHue = colorGenerationHue + (0.61803 * 360)
        colorGenerationHue = colorGenerationHue % 360
        local vec = Vector(col.r / 255, col.g / 255, col.b / 255)
        v:SetNWVector("PlayerColor", vec)

        v:BeginRoleChecks()

        SetRoleHealth(v)
    end

    -- Give the StateUpdate messages ample time to arrive
    timer.Simple(1.5, TellTraitorsAboutTraitors)
    timer.Simple(2.5, ShowRoundStartPopup)

    -- EQUIP_REGEN health regeneration tick
    timer.Create("RegenEquipmentTick", 0.66, 0, function()
        for _, v in PlayerIterator() do
            if v:Alive() and not v:IsSpec() and v:HasEquipmentItem(EQUIP_REGEN) then
                local hp = v:Health()
                if hp < v:GetMaxHealth() then
                    v:SetHealth(hp + 1)
                end
            end
        end
    end)

    -- Start the win condition check timer
    StartWinChecks()
    StartNameChangeChecks()
    timer.Create("selectmute", 1, 1, function() MuteForRestart(false) end)

    GAMEMODE.DamageLog = {}
    GAMEMODE.RoundStartTime = CurTime()

    local zombie_is_traitor = TRAITOR_ROLES[ROLE_ZOMBIE]
    local vampire_is_traitor = TRAITOR_ROLES[ROLE_VAMPIRE]
    LoadMonsterEquipment(zombie_is_traitor, vampire_is_traitor)
    -- Send the status to the client because at this point the globals haven't synced
    net.Start("TTT_LoadMonsterEquipment")
    net.WriteBool(zombie_is_traitor)
    net.WriteBool(vampire_is_traitor)
    net.Broadcast()

    -- Sound start alarm
    SetRoundState(ROUND_ACTIVE)
    LANG.Msg("round_started")
    ServerLog("Round proper has begun...\n")
    ClearAllFootsteps()
    GAMEMODE:UpdatePlayerLoadouts() -- needs to happen when round_active

    RunHook("TTTBeginRound")

    ents.TTT.TriggerRoundStateOutputs(ROUND_BEGIN)
end

function PrintResultMessage(type)
    ServerLog("Round ended.\n")

    local overridden = CallHook("TTTPrintResultMessage", nil, type)
    if overridden then return end

    if type == WIN_TIMELIMIT then
        if GetConVar("ttt_roundtime_win_draw"):GetBool() then
            LANG.Msg("win_draw")
            ServerLog("Result: timelimit reached, draw.\n")
        else
            LANG.Msg("win_time", { role = ROLE_STRINGS_PLURAL[ROLE_INNOCENT] })
            ServerLog("Result: timelimit reached, " .. ROLE_STRINGS_PLURAL[ROLE_TRAITOR] .. " lose.\n")
        end
    elseif type == WIN_TRAITOR then
        LANG.Msg("win_traitor", { role = ROLE_STRINGS_PLURAL[ROLE_TRAITOR] })
        ServerLog("Result: " .. ROLE_STRINGS_PLURAL[ROLE_TRAITOR] .. " win.\n")
    elseif type == WIN_INNOCENT then
        LANG.Msg("win_innocent", { role = ROLE_STRINGS_PLURAL[ROLE_TRAITOR] })
        ServerLog("Result: " .. ROLE_STRINGS_PLURAL[ROLE_INNOCENT] .. " win.\n")
    elseif type == WIN_MONSTER then
        local monster_role = GetWinningMonsterRole()
        -- If it wasn't a special kind of monster that won (zombie or vampire) use the "Monsters Win" label
        if not monster_role then
            LANG.Msg("win_monster")
            ServerLog("Result: Monsters win.\n")
        else
            local plural = ROLE_STRINGS_PLURAL[monster_role]
            LANG.Msg("win_" .. StringLower(plural), { role = plural })
            ServerLog("Result: " .. plural .. " win.\n")
        end
    else
        ServerLog("Result: unknown victory condition (" .. tostring(type) .. ")!\n")
    end
end

function CheckForMapSwitch()
    -- Check for mapswitch
    local rounds_left = math.max(0, GetGlobalInt("ttt_rounds_left", 6) - 1)
    SetGlobalInt("ttt_rounds_left", rounds_left)

    local time_left = math.max(0, (GetConVar("ttt_time_limit_minutes"):GetInt() * 60) - CurTime())
    local switchmap = false
    local nextmap = StringUpper(game.GetMapNext())

    if rounds_left <= 0 then
        LANG.Msg("limit_round", { mapname = nextmap })
        switchmap = true
    elseif time_left <= 0 then
        LANG.Msg("limit_time", { mapname = nextmap })
        switchmap = true
    end

    if switchmap then
        timer.Stop("end2prep")
        timer.Simple(15, game.LoadNextMap)
    else
        LANG.Msg("limit_left", {
            num = rounds_left,
            time = math.ceil(time_left / 60),
            mapname = nextmap })
    end
end

function EndRound(type)
    PrintResultMessage(type)

    -- first handle round end
    SetRoundState(ROUND_POST)

    local ptime = math.max(5, GetConVar("ttt_posttime_seconds"):GetInt())
    LANG.Msg("win_showreport", { num = ptime })
    timer.Create("end2prep", ptime, 1, PrepareRound)

    -- Piggyback on "round end" time global var to show end of phase timer
    SetRoundEnd(CurTime() + ptime)

    timer.Create("restartmute", ptime - 1, 1, function() MuteForRestart(true) end)

    -- Stop checking for wins
    StopWinChecks()

    -- We may need to start a timer for a mapswitch, or start a vote
    CheckForMapSwitch()

    KARMA.RoundEnd()

    -- now handle potentially error prone scoring stuff

    -- register an end of round event
    SCORE:RoundComplete(type)

    -- update player scores
    SCORE:ApplyEventLogScores(type)

    -- send the clients the round log, players will be shown the report
    SCORE:StreamToClients()

    -- server plugins might want to start a map vote here or something
    -- these hooks are not used by TTT internally
    RunHook("TTTEndRound", type)

    ents.TTT.TriggerRoundStateOutputs(ROUND_POST, type)
end

function GM:MapTriggeredEnd(wintype)
    if GetConVar("ttt_disable_mapwin"):GetBool() then
        LANG.Msg("win_prevented")
        ServerLog("Map attempted to end the round with win type: " .. wintype .. ".\n")
    else
        self.MapWin = wintype
    end
end

local function HandleWinCondition(win)
    -- Allow addons to block win conditions other than time limit
    if win ~= WIN_TIMELIMIT then
        -- Handle role-specific checks
        local win_blocks = {}
        xpcall(function()
            CallHook("TTTWinCheckBlocks", nil, win_blocks)
        end, function(err)
            ErrorNoHalt("ERROR: Error occurred when running the 'TTTWinCheckBlocks' hook. Report this to the developers! Win Type: " .. win .. ", Error:\n", err, "\n")
        end)

        for _, win_block in ipairs(win_blocks) do
            local new_win
            xpcall(function()
                new_win = win_block(win)
            end, function(err)
                ErrorNoHalt("ERROR: Error occurred when running a win check block function from the 'TTTWinCheckBlocks' hook. Report this to the developers! Win Type: " .. win .. ", Error:\n", err, "\n")
            end)
            -- Protect against blocking functions which don't always return
            if new_win then
                win = new_win
            end
        end
    end

    -- If, after all that, we have a win condition then end the round
    if win ~= WIN_NONE then
        xpcall(function()
            CallHook("TTTWinCheckComplete", nil, win)
        end, function(err)
            ErrorNoHalt("ERROR: Error occurred when running the 'TTTWinCheckComplete' hook. Report this to the developers! Win Type: " .. win .. ", Error:\n", err, "\n")
        end)

        timer.Simple(0.5, function() EndRound(win) end) -- Slight delay to make sure alternate winners go through before scoring
    end
end

-- Used to be in think, now a timer
local function WinChecker()
    -- If prevent-win is enabled then don't even check the win conditions
    if ttt_dbgwin:GetBool() then return end

    if GetRoundState() == ROUND_ACTIVE then
        local win = WIN_NONE
        if CurTime() > GetGlobalFloat("ttt_round_end", 0) then
            win = WIN_TIMELIMIT
        else
            -- Check the map win first
            if GAMEMODE.MapWin ~= WIN_NONE then
                local mw = GAMEMODE.MapWin
                GAMEMODE.MapWin = WIN_NONE
                win = mw
            end

            -- If this isn't a map win, call the hook
            if win == WIN_NONE then
                xpcall(function()
                    win = RunHook("TTTCheckForWin")
                end, function(err)
                    ErrorNoHalt("ERROR: Error occurred when running the 'TTTCheckForWin' hook. Report this to the developers! Win Type: " .. win .. ", Error:\n", err, "\n")
                end)
                if win > WIN_MAX then
                    ErrorNoHalt("WARNING: 'TTTCheckForWin' hook returned win ID '" .. win .. "' that exceeds the expected maximum of " .. WIN_MAX .. ". Please use GenerateNewWinID() instead to get a unique win ID.\n")
                end
            end
        end

        HandleWinCondition(win)
    end
end

function StartWinChecks()
    if not timer.Start("winchecker") then
        timer.Create("winchecker", 1, 0, WinChecker)
    end
end

function StopWinChecks()
    timer.Stop("winchecker")
end

-- The most basic win check is whether both sides have one dude alive
function GM:TTTCheckForWin()
    local traitor_alive = false
    local innocent_alive = false
    local monster_alive = false

    for _, v in PlayerIterator() do
        if v:IsActive() then
            if v:IsTraitorTeam() then
                traitor_alive = true
            elseif v:IsMonsterTeam() then
                monster_alive = true
            elseif v:IsInnocentTeam() then
                innocent_alive = true
            end
        end
    end

    if traitor_alive and innocent_alive then
        return WIN_NONE --early out
    end

    -- If everyone is dead the traitors win
    if not innocent_alive and not monster_alive then
        return WIN_TRAITOR
    -- If all the "bad" people are dead, innocents win
    elseif not traitor_alive and not monster_alive then
        return WIN_INNOCENT
    -- If the monsters are the only ones left, they win
    elseif not innocent_alive and not traitor_alive then
        return WIN_MONSTER
    end

    return WIN_NONE
end

local function GetTraitorCount(ply_count)
    -- get number of traitors: pct of players rounded up
    local traitor_count = math.ceil(ply_count * math.Round(GetConVar("ttt_traitor_pct"):GetFloat(), 3))
    -- make sure there is at least 1 traitor
    return math.Clamp(traitor_count, 1, GetConVar("ttt_traitor_max"):GetInt())
end

local function GetDetectiveCount(ply_count)
    local detective_count = math.ceil(ply_count * math.Round(GetConVar("ttt_detective_pct"):GetFloat(), 3))

    return math.Clamp(detective_count, 1, GetConVar("ttt_detective_max"):GetInt())
end

local function GetSpecialTraitorCount(ply_count)
    -- get number of special traitors: pct of traitors rounded up
    return math.ceil(ply_count * math.Round(GetConVar("ttt_special_traitor_pct"):GetFloat(), 3))
end

local function GetSpecialInnocentCount(ply_count)
    -- get number of special innocents: pct of innocents rounded up
    return math.ceil(ply_count * math.Round(GetConVar("ttt_special_innocent_pct"):GetFloat(), 3))
end

local function GetSpecialDetectiveCount(ply_count)
    -- get number of special detectives: pct of detectives rounded up
    return math.ceil(ply_count * math.Round(GetConVar("ttt_special_detective_pct"):GetFloat(), 3))
end

local function GetJesterIndependentCount(ply_count)
    -- get number of jesters and independents: pct of players rounded up
    local jester_independent_count =  math.ceil(ply_count * math.Round(GetConVar("ttt_jester_independent_pct"):GetFloat(), 3))
    return math.Clamp(jester_independent_count, 1, GetConVar("ttt_jester_independent_max"):GetInt())
end

local function GetMonsterCount(ply_count)
    if #GetTeamRoles(MONSTER_ROLES) == 0 then
        return 0
    end

    local monster_count = math.ceil(ply_count * math.Round(GetConVar("ttt_monster_pct"):GetFloat(), 3))
    return math.Clamp(monster_count, 0, GetConVar("ttt_monster_max"):GetInt())
end

local function PrintRoleText(text)
    if not ttt_dbgroles:GetBool() then return end
    print(text)
end

local function PrintRole(ply, role)
    PrintRoleText(ply:Nick() .. " (" .. ply:SteamID() .. " | " .. ply:SteamID64() .. ") - " .. ROLE_STRINGS[role])
end

function SelectRoles()
    local choices = {}
    local prev_roles = {}
    -- Initialize the table for every role
    for wrole = ROLE_NONE, ROLE_MAX do
        prev_roles[wrole] = {}
    end

    if not GAMEMODE.LastRole then GAMEMODE.LastRole = {} end

    for _, v in PlayerIterator() do
        if IsValid(v) then
            -- everyone on the spec team is in specmode
            if not v:IsSpec() then
                -- save previous role and sign up as a possible role
                local r = GAMEMODE.LastRole[v:SteamID64()] or v:GetRole() or ROLE_NONE

                table.insert(prev_roles[r], v)
                table.insert(choices, v)
            end

            v:SetRole(ROLE_NONE)
        end
    end

    table.Shuffle(choices)
    local choice_count = #choices

    -- special spawning cvars
    local blocked_roles = {}

    local roleblocks = ROLEBLOCKS.GetBlockedRoles()

    if choice_count == 0 then return end

    ROLEPACKS.AssignRoles(choices)

    local choices_copy = table.Copy(choices)
    local prev_roles_copy = table.Copy(prev_roles)

    CallHook("TTTSelectRoles", nil, choices_copy, prev_roles_copy)

    for _, v in ipairs(choices) do
        if v.forcedRole and v.forcedRole ~= ROLE_NONE then
            v:SetRole(v.forcedRole)
            v:ClearForcedRole()
        end
    end

    local forcedTraitorCount = 0
    local forcedSpecialTraitorCount = 0
    local forcedDetectiveCount = 0
    local forcedSpecialDetectiveCount = 0
    local forcedSpecialInnocentCount = 0
    local forcedIndependentCount = 0
    local forcedJesterCount = 0
    local forcedMonsterCount = 0

    local hasRole = {}

    local multipleJesterIndependent = GetConVar("ttt_multiple_jesters_independents"):GetBool()
    local singleJesterIndependent = GetConVar("ttt_single_jester_independent"):GetBool()

    -- If we have more players than the maximum for a single jester OR independent, force allowing both
    local singleJesterIndependentMaxPlayers = GetConVar("ttt_single_jester_independent_max_players"):GetInt()
    if singleJesterIndependent and singleJesterIndependentMaxPlayers > 0 and #choices > singleJesterIndependentMaxPlayers then
        singleJesterIndependent = false
    end

    PrintRoleText("-----CHECKING EXTERNALLY CHOSEN ROLES-----")
    for _, v in PlayerIterator() do
        if IsValid(v) and (not v:IsSpec()) then
            local role = v:GetRole()
            if role > ROLE_NONE and role <= ROLE_MAX then
                local index = 0
                for i, j in pairs(choices) do
                    if v == j then
                        index = i
                        break
                    end
                end

                table.remove(choices, index)
                hasRole[role] = true

                -- TRAITOR ROLES
                if role == ROLE_TRAITOR then
                    forcedTraitorCount = forcedTraitorCount + 1
                elseif TRAITOR_ROLES[role] then
                    forcedSpecialTraitorCount = forcedSpecialTraitorCount + 1
                elseif role == ROLE_DETECTIVE then
                    forcedDetectiveCount = forcedDetectiveCount + 1
                elseif DETECTIVE_ROLES[role] then
                    forcedSpecialDetectiveCount = forcedSpecialDetectiveCount + 1
                elseif INNOCENT_ROLES[role] and role ~= ROLE_INNOCENT then
                    forcedSpecialInnocentCount = forcedSpecialInnocentCount + 1
                elseif JESTER_ROLES[role] then
                    if singleJesterIndependent then
                        forcedIndependentCount = forcedIndependentCount + 1
                    else
                        forcedJesterCount = forcedJesterCount + 1
                    end
                elseif INDEPENDENT_ROLES[role] then
                    forcedIndependentCount = forcedIndependentCount + 1
                elseif MONSTER_ROLES[role] then
                    forcedMonsterCount = forcedMonsterCount + 1
                end

                if roleblocks and #roleblocks > 0 then
                    for _, group in ipairs(roleblocks) do
                        for _, groupRole in ipairs(group) do
                            if groupRole.role == ROLE_STRINGS_RAW[role] then
                                for _, blockRole in ipairs(group) do
                                    if blockRole.role ~= ROLE_STRINGS_RAW[role] then
                                        local toBlock = ROLE_NONE
                                        for r = ROLE_INNOCENT, ROLE_MAX do
                                            if ROLE_STRINGS_RAW[r] == blockRole.role then
                                                toBlock = r
                                                break
                                            end
                                        end
                                        blocked_roles[toBlock] = true
                                    end
                                end
                                break
                            end
                        end
                    end
                end

                PrintRole(v, role)
            end
        end
    end

    if roleblocks and #roleblocks > 0 then
        for _, group in ipairs(roleblocks) do
            local groupRoles = {}
            for _, groupRole in ipairs(group) do
                local role = ROLE_NONE
                for r = ROLE_INNOCENT, ROLE_MAX do
                    if ROLE_STRINGS_RAW[r] == groupRole.role then
                        role = r
                        break
                    end
                end
                if role ~= ROLE_NONE and not blocked_roles[role] then
                    for _ = 1, groupRole.weight do
                        table.insert(groupRoles, role)
                    end
                end
            end
            table.Shuffle(groupRoles)
            local chosenRole = groupRoles[1]
            for _, role in ipairs(groupRoles) do
                if role ~= chosenRole then
                    blocked_roles[role] = true
                end
            end
        end
    end

    PrintRoleText("-----RANDOMLY PICKING REMAINING ROLES-----")

    -- determine how many of each role we want
    local unmodified_detective_count = GetDetectiveCount(choice_count)
    local detective_count = unmodified_detective_count - forcedDetectiveCount - forcedSpecialDetectiveCount
    local max_special_detective_count = math.min(GetSpecialDetectiveCount(unmodified_detective_count) - forcedSpecialDetectiveCount, detective_count)
    local unmodified_traitor_count = GetTraitorCount(choice_count)
    local traitor_count = unmodified_traitor_count - forcedTraitorCount - forcedSpecialTraitorCount
    local max_special_traitor_count = math.min(GetSpecialTraitorCount(unmodified_traitor_count) - forcedSpecialTraitorCount, traitor_count)
    local independent_count = ((math.random() <= GetConVar("ttt_independent_chance"):GetFloat()) and 1 or 0) - forcedIndependentCount
    local jester_count = ((math.random() <= GetConVar("ttt_jester_chance"):GetFloat()) and 1 or 0) - forcedJesterCount
    local jester_independent_count = GetJesterIndependentCount(choice_count) - forcedIndependentCount - forcedJesterCount
    local monster_count = GetMonsterCount(choice_count) - forcedMonsterCount

    local specialTraitorRoles = {}
    local specialInnocentRoles = {}
    local specialDetectiveRoles = {}
    local independentRoles = {}
    local jesterRoles = {}
    local monsterRoles = {}
    local detectives = {}
    local traitors = {}
    local glitch_mode = GetConVar("ttt_glitch_mode"):GetInt()

    -- Special rules for role spawning
    -- Role exclusion logic also needs to be copied into the drunk role selection logic in drunk.lua -> plymeta:SoberDrunk
    local rolePredicates = {
        -- Innocents
        [ROLE_DEPUTY] = function() return detective_count > 0 or GetConVar("ttt_deputy_without_detective"):GetBool() end,
        [ROLE_REVENGER] = function() return choice_count > 1 end,
        [ROLE_GLITCH] = function()
            return (glitch_mode == GLITCH_SHOW_AS_TRAITOR and #traitors > 1) or
                    ((glitch_mode == GLITCH_SHOW_AS_SPECIAL_TRAITOR or glitch_mode == GLITCH_HIDE_SPECIAL_TRAITOR_ROLES) and traitor_count > 1)
        end,

        -- Traitors
        [ROLE_IMPERSONATOR] = function() return detective_count > 0 or GetConVar("ttt_impersonator_without_detective"):GetBool() end,
    }

    local function DoesRolePassPredicate(role)
        -- If the default predicate exists for this role but returns false then this role shouldn't be chosen
        if rolePredicates[role] and not rolePredicates[role]() then return false end
        -- If the override predicate exists for this role but returns false then this role shouldn't be chosen
        if ROLE_SELECTION_PREDICATE[role] and not ROLE_SELECTION_PREDICATE[role]() then return false end
        -- If the role has been blocked by a single_role1_role2 convar then this role shouldn't be chosen
        if blocked_roles[role] then return false end
        -- Otherwise let the role be chosen
        return true
    end

    local function IsRoleAvailable(role)
        return not hasRole[role] and cvars.Bool("ttt_" .. ROLE_STRINGS_RAW[role] .. "_enabled", false) and choice_count >= cvars.Number("ttt_" .. ROLE_STRINGS_RAW[role] .. "_min_players", 0) and DoesRolePassPredicate(role)
    end

    local function HandleDelayedRole(role, tbl, pred)
        if not IsRoleAvailable(role) then return end
        if pred and not pred() then return end

        for _ = 1, cvars.Number("ttt_" .. ROLE_STRINGS_RAW[role] .. "_spawn_weight", 1) do
            table.insert(tbl, role)
        end
    end

    -- Roles that required their checks to be delayed because they rely on other role selection information
    local delayedCheckRoles = {
        -- Glitch requires the number of traitors that have been selected
        [ROLE_GLITCH] = true,
        -- Deputy, Impersonator, and Marshal all need to know whether a player with the other roles exist before spawning
        [ROLE_DEPUTY] = true,
        [ROLE_IMPERSONATOR] = true,
        [ROLE_MARSHAL] = true
    }

    -- Build the weighted lists for all non-default roles
    for r = ROLE_DETECTIVE + 1, ROLE_MAX do
        if not delayedCheckRoles[r] and IsRoleAvailable(r) then
            for _ = 1, cvars.Number("ttt_" .. ROLE_STRINGS_RAW[r] .. "_spawn_weight", 1) do
                -- Don't include zombies in the traitor list since they will spawn as a special "zombie round" sometimes if they are traitors
                if TRAITOR_ROLES[r] and r ~= ROLE_ZOMBIE then
                    table.insert(specialTraitorRoles, r)
                elseif DETECTIVE_ROLES[r] then
                    table.insert(specialDetectiveRoles, r)
                elseif INNOCENT_ROLES[r] then
                    table.insert(specialInnocentRoles, r)
                elseif JESTER_ROLES[r] then
                    if singleJesterIndependent or multipleJesterIndependent then
                        table.insert(independentRoles, r)
                    else
                        table.insert(jesterRoles, r)
                    end
                elseif INDEPENDENT_ROLES[r] then
                    table.insert(independentRoles, r)
                elseif MONSTER_ROLES[r] then
                    table.insert(monsterRoles, r)
                end
            end
        end
    end

    -- pick detectives
    if choice_count >= GetConVar("ttt_detective_min_players"):GetInt() then
        local min_karma = detective_karma_min:GetInt()
        local options = {}
        local secondary_options = {}
        local tertiary_options = {}
        for _, p in ipairs(choices) do
            if not KARMA.IsEnabled() or p:GetBaseKarma() >= min_karma then
                if not p:ShouldAvoidDetective() then
                    table.insert(options, p)
                end
                table.insert(secondary_options, p)
            end
            table.insert(tertiary_options, p)
        end

        -- Fall back to the other Detective options if there aren't any players with good karma and who aren't avoiding the role
        if #options == 0 then
            -- Prefer people with good karma
            if #secondary_options > 0 then
                options = secondary_options
            -- Or just anyone
            else
                options = tertiary_options
            end
        end

        for _ = 1, detective_count do
            if #options > 0 then
                local plyPick = math.random(1, #options)
                local ply = table.remove(options, plyPick)
                table.insert(detectives, ply)
                table.RemoveByValue(choices, ply)
            end
        end
    end

    -- pick traitors
    for _ = 1, traitor_count do
        if #choices > 0 then
            local plyPick = math.random(1, #choices)
            local ply = table.remove(choices, plyPick)
            table.insert(traitors, ply)
        end
    end

    -- Copy these tables before they are modified so the hooks can know who the available team members are
    choices_copy = table.Copy(choices)
    local traitors_copy = table.Copy(traitors)
    local detectives_copy = table.Copy(detectives)

    -- pick special detectives
    if max_special_detective_count > 0 then
        for r, delayed in pairs(delayedCheckRoles) do
            if not delayed or not DETECTIVE_ROLES[r] then continue end
            HandleDelayedRole(r, specialDetectiveRoles)
        end

        -- Allow external addons to modify available roles and their weights
        CallHook("TTTSelectRolesDetectiveOptions", nil, specialDetectiveRoles, choices_copy, choice_count, traitors_copy, traitor_count, detectives_copy, detective_count)

        for _ = 1, max_special_detective_count do
            if #specialDetectiveRoles ~= 0 and math.random() <= GetConVar("ttt_special_detective_chance"):GetFloat() and #detectives > 0 then
                local plyPick = math.random(1, #detectives)
                local ply = table.remove(detectives, plyPick)
                local rolePick = math.random(1, #specialDetectiveRoles)
                local role = specialDetectiveRoles[rolePick]
                ply:SetRole(role)
                PrintRole(ply, role)
                for i = #specialDetectiveRoles, 1, -1 do
                    if specialDetectiveRoles[i] == role then
                        table.remove(specialDetectiveRoles, i)
                    end
                end
            end
        end
    end

    local can_have_impersonator = IsRoleAvailable(ROLE_IMPERSONATOR)
    local impersonator_chance = GetConVar("ttt_impersonator_detective_chance"):GetFloat()
    -- Any of these left are vanilla detectives
    for _, v in pairs(detectives) do
        -- By chance have this detective actually be a promoted impersonator
        if can_have_impersonator and #traitors > 0 and math.random() < impersonator_chance then
            v:SetRole(ROLE_IMPERSONATOR)
            PrintRole(v, ROLE_IMPERSONATOR)
            v:HandleDetectiveLikePromotion()

            -- Move a player from "traitors" to "choices" and update the table copies to keep the team counts the same
            local plyPick = math.random(1, #traitors)
            local ply = table.remove(traitors, plyPick)
            table.insert(choices, ply)
            traitors_copy = table.Copy(traitors)
            choices_copy = table.Copy(choices)

            -- Mark this role as taken so we don't have 2 impersonators
            hasRole[ROLE_IMPERSONATOR] = true

            -- Only allow one to be an impersonator
            can_have_impersonator = false
        else
            v:SetRole(ROLE_DETECTIVE)
            PrintRole(v, ROLE_DETECTIVE)
        end
    end

    if ((GetConVar("ttt_zombie_enabled"):GetBool() and math.random() <= GetConVar("ttt_zombie_round_chance"):GetFloat() and choice_count >= cvars.Number("ttt_zombie_min_players", 0) and (forcedTraitorCount <= 0) and (forcedSpecialTraitorCount <= 0)) or hasRole[ROLE_ZOMBIE]) and TRAITOR_ROLES[ROLE_ZOMBIE] then
        -- This is a zombie round so all traitors become zombies
        for _, v in pairs(traitors) do
            v:SetRole(ROLE_ZOMBIE)
            PrintRole(v, ROLE_ZOMBIE)
        end

        SetGlobalBool("ttt_zombie_round", true)
    else
        -- pick special traitors
        if max_special_traitor_count > 0 then
            for r, delayed in pairs(delayedCheckRoles) do
                if not delayed or not TRAITOR_ROLES[r] then continue end
                HandleDelayedRole(r, specialTraitorRoles)
            end

            -- Allow external addons to modify available roles and their weights
            CallHook("TTTSelectRolesTraitorOptions", nil, specialTraitorRoles, choices_copy, choice_count, traitors_copy, traitor_count, detectives_copy, detective_count)

            for _ = 1, max_special_traitor_count do
                if #specialTraitorRoles ~= 0 and math.random() <= GetConVar("ttt_special_traitor_chance"):GetFloat() and #traitors > 0 then
                    local plyPick = math.random(1, #traitors)
                    local ply = table.remove(traitors, plyPick)
                    local rolePick = math.random(1, #specialTraitorRoles)
                    local role = specialTraitorRoles[rolePick]
                    ply:SetRole(role)
                    PrintRole(ply, role)
                    for i = #specialTraitorRoles, 1, -1 do
                        if specialTraitorRoles[i] == role then
                            table.remove(specialTraitorRoles, i)
                        end
                    end
                end
            end
        end

        -- Any of these left are vanilla traitors
        for _, v in pairs(traitors) do
            v:SetRole(ROLE_TRAITOR)
            PrintRole(v, ROLE_TRAITOR)
        end

        SetGlobalBool("ttt_zombie_round", false)
    end

    if multipleJesterIndependent then
        if jester_independent_count > 0 and #choices > 0 then
            for r, delayed in pairs(delayedCheckRoles) do
                if not delayed or not INDEPENDENT_ROLES[r] then continue end
                HandleDelayedRole(r, independentRoles)
            end
            -- Allow external addons to modify available roles and their weights
            CallHook("TTTSelectRolesIndependentOptions", nil, independentRoles, choices_copy, choice_count, traitors_copy, traitor_count, detectives_copy, detective_count)

            for r, delayed in pairs(delayedCheckRoles) do
                if not delayed or not JESTER_ROLES[r] then continue end
                HandleDelayedRole(r, independentRoles)
            end
            -- Allow external addons to modify available roles and their weights
            CallHook("TTTSelectRolesJesterOptions", nil, independentRoles, choices_copy, choice_count, traitors_copy, traitor_count, detectives_copy, detective_count)
        end

        for _ = 1, jester_independent_count do
            if #independentRoles ~= 0 and math.random() <= GetConVar("ttt_jester_independent_chance"):GetFloat() and #choices > 0 then
                local plyPick = math.random(1, #choices)
                local ply = table.remove(choices, plyPick)
                local rolePick = math.random(1, #independentRoles)
                local role = independentRoles[rolePick]
                ply:SetRole(role)
                PrintRole(ply, role)
                for i = #independentRoles, 1, -1 do
                    if independentRoles[i] == role then
                        table.remove(independentRoles, i)
                    end
                end
            end
        end
    else
        -- pick independent
        if forcedIndependentCount == 0 and independent_count > 0 and #choices > 0 then
            for r, delayed in pairs(delayedCheckRoles) do
                if not delayed or not INDEPENDENT_ROLES[r] then continue end
                HandleDelayedRole(r, independentRoles)
            end

            -- Allow external addons to modify available roles and their weights
            CallHook("TTTSelectRolesIndependentOptions", nil, independentRoles, choices_copy, choice_count, traitors_copy, traitor_count, detectives_copy, detective_count)
            if singleJesterIndependent then
                for r, delayed in pairs(delayedCheckRoles) do
                    if not delayed or not JESTER_ROLES[r] then continue end
                    HandleDelayedRole(r, independentRoles)
                end
                -- Allow external addons to modify available roles and their weights
                CallHook("TTTSelectRolesJesterOptions", nil, independentRoles, choices_copy, choice_count, traitors_copy, traitor_count, detectives_copy, detective_count)
            end

            if #independentRoles ~= 0 then
                local plyPick = math.random(1, #choices)
                local ply = table.remove(choices, plyPick)
                local rolePick = math.random(1, #independentRoles)
                local role = independentRoles[rolePick]
                ply:SetRole(role)
                PrintRole(ply, role)
                for i = #independentRoles, 1, -1 do
                    if independentRoles[i] == role then
                        table.remove(independentRoles, i)
                    end
                end
            end
        end

        -- pick jester
        if not singleJesterIndependent and forcedJesterCount == 0 and jester_count > 0 and #choices > 0 then
            for r, delayed in pairs(delayedCheckRoles) do
                if not delayed or not JESTER_ROLES[r] then continue end
                HandleDelayedRole(r, jesterRoles)
            end
            -- Allow external addons to modify available roles and their weights
            CallHook("TTTSelectRolesJesterOptions", nil, jesterRoles, choices_copy, choice_count, traitors_copy, traitor_count, detectives_copy, detective_count)

            if #jesterRoles ~= 0 then
                local plyPick = math.random(1, #choices)
                local ply = table.remove(choices, plyPick)
                local rolePick = math.random(1, #jesterRoles)
                local role = jesterRoles[rolePick]
                ply:SetRole(role)
                PrintRole(ply, role)
                for i = #jesterRoles, 1, -1 do
                    if jesterRoles[i] == role then
                        table.remove(jesterRoles, i)
                    end
                end
            end
        end
    end

    if monster_count > 0 and #choices > 0 then
        for r, delayed in pairs(delayedCheckRoles) do
            if not delayed or not MONSTER_ROLES[r] then continue end
            HandleDelayedRole(r, monsterRoles)
        end

        -- Allow external addons to modify available roles and their weights
        CallHook("TTTSelectRolesMonsterOptions", nil, monsterRoles, choices_copy, choice_count, traitors_copy, traitor_count, detectives_copy, detective_count)

        for _ = 1, monster_count do
            if #monsterRoles ~= 0 and math.random() <= GetConVar("ttt_monster_chance"):GetFloat() and #choices > 0 then
                local plyPick = math.random(1, #choices)
                local ply = table.remove(choices, plyPick)
                local rolePick = math.random(1, #monsterRoles)
                local role = monsterRoles[rolePick]
                ply:SetRole(role)
                PrintRole(ply, role)
                for i = #monsterRoles, 1, -1 do
                    if monsterRoles[i] == role then
                        table.remove(monsterRoles, i)
                    end
                end
            end
        end
    end

    -- pick special innocents
    local max_special_innocent_count = GetSpecialInnocentCount(#choices) - forcedSpecialInnocentCount
    if max_special_innocent_count > 0 then
        for r, delayed in pairs(delayedCheckRoles) do
            -- Skip detective roles even though they are innocent because they are handled above
            if not delayed or not INNOCENT_ROLES[r] or DETECTIVE_ROLES[r] then continue end
            HandleDelayedRole(r, specialInnocentRoles)
        end

        -- Allow external addons to modify available roles and their weights
        CallHook("TTTSelectRolesInnocentOptions", nil, specialInnocentRoles, choices_copy, choice_count, traitors_copy, traitor_count, detectives_copy, detective_count)

        for _ = 1, max_special_innocent_count do
            if #specialInnocentRoles ~= 0 and math.random() <= GetConVar("ttt_special_innocent_chance"):GetFloat() and #choices > 0 then
                local plyPick = math.random(1, #choices)
                local ply = table.remove(choices, plyPick)
                local rolePick = math.random(1, #specialInnocentRoles)
                local role = specialInnocentRoles[rolePick]
                if role == ROLE_GLITCH and glitch_mode == GLITCH_SHOW_AS_SPECIAL_TRAITOR then
                    local bluff = ROLE_TRAITOR
                    if #specialTraitorRoles > 0 and not (#traitors > 0 and math.random() > 0.5) then -- If there are normal traitors in a round the glitch has a 50% chance to be a special traitor or regular traitor
                        local bluffPick = math.random(1, #specialTraitorRoles)
                        bluff = specialTraitorRoles[bluffPick]
                    end
                    ply:SetNWInt("GlitchBluff", bluff)
                end
                ply:SetRole(role)
                PrintRole(ply, role)
                for i = #specialInnocentRoles, 1, -1 do
                    if specialInnocentRoles[i] == role then
                        table.remove(specialInnocentRoles, i)
                    end
                end
            end
        end
    end

    -- Anyone left is innocent
    for _, v in pairs(choices) do
        v:SetRole(ROLE_INNOCENT)
        PrintRole(v, ROLE_INNOCENT)
    end
    PrintRoleText("------------DONE PICKING ROLES------------")

    GAMEMODE.LastRole = {}

    for _, ply in PlayerIterator() do
        -- initialize credit count for everyone based on their role
        if IsValid(ply) and not ply:IsSpec() then
            if ply:GetRole() == ROLE_NONE then
                ErrorNoHalt("WARNING: " .. ply:Nick() .. " was not assigned a role! Forcing them to be " .. ROLE_STRINGS[ROLE_INNOCENT] .. "...\n")
                ply:SetRole(ROLE_INNOCENT)
            end

            -- Keep existing credits so pre-promoted roles have their bonuses
            ply:SetDefaultCredits(true)
        end

        -- store a steamid64 -> role map
        GAMEMODE.LastRole[ply:SteamID64()] = ply:GetRole()
    end
end

local function ForceRoundRestart(ply, command, args)
    -- ply is nil on dedicated server console
    if (not IsValid(ply)) or ply:IsAdmin() or ply:IsSuperAdmin() or cvars.Bool("sv_cheats", 0) then
        LANG.Msg("round_restart")

        StopRoundTimers()

        -- Let addons know that a round ended
        RunHook("TTTEndRound", WIN_NONE)

        -- do prep
        PrepareRound()
    else
        ply:PrintMessage(HUD_PRINTCONSOLE, "You must be a GMod Admin or SuperAdmin on the server to use this command, or sv_cheats must be enabled.")
    end
end
concommand.Add("ttt_roundrestart", ForceRoundRestart)

function ShowVersion(ply)
    local text = Format("This is TTT version %s\n", GAMEMODE.Version)
    if IsValid(ply) then
        ply:PrintMessage(HUD_PRINTNOTIFY, text)
    else
        Msg(text)
    end
end
concommand.Add("ttt_version", ShowVersion)