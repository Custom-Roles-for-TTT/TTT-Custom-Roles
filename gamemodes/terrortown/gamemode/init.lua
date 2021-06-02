---- Trouble in Terrorist Town

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
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
AddCSLuaFile("vgui/ColoredBox.lua")
AddCSLuaFile("vgui/SimpleIcon.lua")
AddCSLuaFile("vgui/ProgressBar.lua")
AddCSLuaFile("vgui/ScrollLabel.lua")
AddCSLuaFile("vgui/sb_main.lua")
AddCSLuaFile("vgui/sb_row.lua")
AddCSLuaFile("vgui/sb_team.lua")
AddCSLuaFile("vgui/sb_info.lua")

include("shared.lua")

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
CreateConVar("ttt_detective_karma_min", "600")

-- Special innocent spawn probabilities
CreateConVar("ttt_special_innocent_pct", 0.33)
CreateConVar("ttt_special_innocent_chance", 0.5)
CreateConVar("ttt_glitch_enabled", 0)
CreateConVar("ttt_glitch_spawn_weight", "1")
CreateConVar("ttt_glitch_min_players", "0")
CreateConVar("ttt_phantom_enabled", 0)
CreateConVar("ttt_phantom_spawn_weight", "1")
CreateConVar("ttt_phantom_min_players", "0")
CreateConVar("ttt_revenger_enabled", 0)
CreateConVar("ttt_revenger_spawn_weight", "1")
CreateConVar("ttt_revenger_min_players", "0")
CreateConVar("ttt_deputy_enabled", 0)
CreateConVar("ttt_deputy_spawn_weight", "1")
CreateConVar("ttt_deputy_min_players", "0")

-- Special traitor spawn probabilities
CreateConVar("ttt_special_traitor_pct", 0.33)
CreateConVar("ttt_special_traitor_chance", 0.5)
CreateConVar("ttt_hypnotist_enabled", 0)
CreateConVar("ttt_hypnotist_spawn_weight", "1")
CreateConVar("ttt_hypnotist_min_players", "0")
CreateConVar("ttt_impersonator_enabled", 0)
CreateConVar("ttt_impersonator_spawn_weight", "1")
CreateConVar("ttt_impersonator_min_players", "0")

-- Independent spawn probabilities
CreateConVar("ttt_independent_chance", 0.5)
CreateConVar("ttt_jester_enabled", 0)
CreateConVar("ttt_jester_spawn_weight", "1")
CreateConVar("ttt_jester_min_players", "0")
CreateConVar("ttt_swapper_enabled", 0)
CreateConVar("ttt_swapper_spawn_weight", "1")
CreateConVar("ttt_swapper_min_players", "0")
CreateConVar("ttt_drunk_enabled", 0)
CreateConVar("ttt_drunk_spawn_weight", "1")
CreateConVar("ttt_drunk_min_players", "0")
CreateConVar("ttt_clown_enabled", 0)
CreateConVar("ttt_clown_spawn_weight", "1")
CreateConVar("ttt_clown_min_players", "0")
CreateConVar("ttt_beggar_enabled", 0)
CreateConVar("ttt_beggar_spawn_weight", "1")
CreateConVar("ttt_beggar_min_players", "0")
CreateConVar("ttt_old_man_enabled", 0)
CreateConVar("ttt_old_man_spawn_weight", "1")
CreateConVar("ttt_old_man_min_players", "0")

-- Custom role properties
CreateConVar("ttt_detective_starting_health", "100")
CreateConVar("ttt_swapper_killer_health", "100")
CreateConVar("ttt_phantom_respawn_health", "50")
CreateConVar("ttt_drunk_sober_time", "180")
CreateConVar("ttt_drunk_innocent_chance", "0.7")
CreateConVar("ttt_clown_damage_bonus", "0")
CreateConVar("ttt_deputy_damage_penalty", "0")
CreateConVar("ttt_impersonator_damage_penalty", "0")
CreateConVar("ttt_reveal_beggar_change", "1")
CreateConVar("ttt_single_deputy_impersonator", "0")
CreateConVar("ttt_old_man_starting_health", "1")
CreateConVar("ttt_jesters_trigger_traitor_testers", "1")
CreateConVar("ttt_independents_trigger_traitor_testers", "0")

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

-- Other credits
CreateConVar("ttt_hyp_credits_starting", "1")

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

CreateConVar("ttt_detective_search_only", "1", FCVAR_REPLICATED)

-- bem server convars
CreateConVar("ttt_bem_allow_change", 1, { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE }, "Allow clients to change the look of the Traitor/Detective menu")
CreateConVar("ttt_bem_sv_cols", 4, { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE }, "Sets the number of columns in the Traitor/Detective menu's item list (serverside)")
CreateConVar("ttt_bem_sv_rows", 5, { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE }, "Sets the number of rows in the Traitor/Detective menu's item list (serverside)")
CreateConVar("ttt_bem_sv_size", 64, { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE }, "Sets the item size in the Traitor/Detective menu's item list (serverside)")

-- sprint convars
local speedMultiplier = CreateConVar("ttt_sprint_bonus_rel", "0.4", FCVAR_SERVER_CAN_EXECUTE, "The relative speed bonus given while sprinting. Def: 0.4")
local recovery = CreateConVar("ttt_sprint_regenerate_innocent", "0.08", FCVAR_SERVER_CAN_EXECUTE, "Sets stamina regeneration for innocents. Def: 0.08")
local traitorRecovery = CreateConVar("ttt_sprint_regenerate_traitor", "0.12", FCVAR_SERVER_CAN_EXECUTE, "Sets stamina regeneration speed for traitors. Def: 0.12")
local consumption = CreateConVar("ttt_sprint_consume", "0.2", FCVAR_SERVER_CAN_EXECUTE, "Sets stamina consumption speed. Def: 0.2")

local ttt_detective = CreateConVar("ttt_sherlock_mode", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY)
local ttt_minply = CreateConVar("ttt_minimum_players", "2", FCVAR_ARCHIVE + FCVAR_NOTIFY)

-- debuggery
local ttt_dbgwin = CreateConVar("ttt_debug_preventwin", "0")

-- Localise stuff we use often. It's like Lua go-faster stripes.
local math = math
local table = table
local net = net
local player = player
local timer = timer
local util = util

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
util.AddNetworkString("TTT_CorpseCall")
util.AddNetworkString("TTT_RemoveCorpseCall")
util.AddNetworkString("TTT_ClearClientState")
util.AddNetworkString("TTT_PerformGesture")
util.AddNetworkString("TTT_Role")
util.AddNetworkString("TTT_RoleList")
util.AddNetworkString("TTT_ConfirmUseTButton")
util.AddNetworkString("TTT_C4Config")
util.AddNetworkString("TTT_C4DisarmResult")
util.AddNetworkString("TTT_C4Warn")
util.AddNetworkString("TTT_ShowPrints")
util.AddNetworkString("TTT_ScanResult")
util.AddNetworkString("TTT_FlareScorch")
util.AddNetworkString("TTT_Radar")
util.AddNetworkString("TTT_Spectate")
util.AddNetworkString("TTT_TeleportMark")
util.AddNetworkString("TTT_ClearRadarExtras")
util.AddNetworkString("TTT_ClownActivate")
util.AddNetworkString("TTT_DrawHitMarker")
util.AddNetworkString("TTT_ClientDeathNotify")
util.AddNetworkString("TTT_SprintSpeedSet")
util.AddNetworkString("TTT_SprintGetConVars")
util.AddNetworkString("TTT_SpawnedPlayers")
util.AddNetworkString("TTT_ResetScoreboard")
util.AddNetworkString("TTT_UpdateRevengerLoverKiller")
util.AddNetworkString("TTT_UpdateOldManWins")

local jester_killed = false
local revenger_lover = nil

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
    GAMEMODE.propspec_allow_named = true

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

    SetGlobalFloat("ttt_drunk_remember", -1)

    -- For the paranoid
    math.randomseed(os.time())

    WaitForPlayers()

    if cvars.Number("sv_alltalk", 0) > 0 then
        ErrorNoHalt("TTT WARNING: sv_alltalk is enabled. Dead players will be able to talk to living players. TTT will now attempt to set sv_alltalk 0.\n")
        RunConsoleCommand("sv_alltalk", "0")
    end

    local cstrike = false
    for _, g in ipairs(engine.GetGames()) do
        if g.folder == 'cstrike' then cstrike = true end
    end
    if not cstrike then
        ErrorNoHalt("TTT WARNING: CS:S does not appear to be mounted by GMod. Things may break in strange ways. Server admin? Check the TTT readme for help.\n")
    end
end

-- Used to do this in Initialize, but server cfg has not always run yet by that
-- point.
function GM:InitCvars()
    MsgN("TTT initializing convar settings...")

    -- Initialize game state that is synced with client
    SetGlobalInt("ttt_rounds_left", GetConVar("ttt_round_limit"):GetInt())
    GAMEMODE:SyncGlobals()
    KARMA.InitState()

    self.cvar_init = true
end

function GM:InitPostEntity()
    WEPS.ForcePrecache()
end

-- Convar replication is broken in gmod, so we do this.
-- I don't like it any more than you do, dear reader.
function GM:SyncGlobals()
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

    SetGlobalBool("ttt_detective_search_only", GetConVar("ttt_detective_search_only"):GetBool())
    SetGlobalBool("ttt_reveal_beggar_change", GetConVar("ttt_reveal_beggar_change"):GetBool())

    SetGlobalBool("sv_voiceenable", GetConVar("sv_voiceenable"):GetBool())
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
    for _, ply in ipairs(player.GetAll()) do
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
-- just making him spectator for some reason does not work right. Therefore,
-- we regularly check for these broken spectators while we wait for players
-- and immediately fix them.
function FixSpectators()
    for k, ply in ipairs(player.GetAll()) do
        if ply:IsSpec() and not ply:GetRagdollSpec() and ply:GetMoveType() < MOVETYPE_NOCLIP then
            ply:Spectate(OBS_MODE_ROAMING)
        end
    end
end

-- Used to be in think, now a timer
local function WinChecker()
    if GetRoundState() == ROUND_ACTIVE then
        if CurTime() > GetGlobalFloat("ttt_round_end", 0) then
            EndRound(WIN_TIMELIMIT)
        else
            local win = hook.Call("TTTCheckForWin", GAMEMODE)
            if win ~= WIN_NONE then
                timer.Simple(0.5, function() EndRound(win) end) -- Slight delay to make sure alternate winners go through before scoring
            end
        end
    end
end

local function NameChangeKick()
    if not GetConVar("ttt_namechange_kick"):GetBool() then
        timer.Remove("namecheck")
        return
    end

    if GetRoundState() == ROUND_ACTIVE then
        for _, ply in ipairs(player.GetHumans()) do
            if ply.spawn_nick then
                if ply.has_spawned and ply.spawn_nick ~= ply:Nick() and not hook.Call("TTTNameChangeKick", GAMEMODE, ply) then
                    local t = GetConVar("ttt_namechange_bantime"):GetInt()
                    local msg = "Changed name during a round"
                    if t > 0 then
                        ply:KickBan(t, msg)
                    else
                        ply:Kick(msg)
                    end
                end
            else
                ply.spawn_nick = ply:Nick()
            end
        end
    end
end

function StartNameChangeChecks()
    if not GetConVar("ttt_namechange_kick"):GetBool() then return end

    -- bring nicks up to date, may have been changed during prep/post
    for _, ply in ipairs(player.GetAll()) do
        ply.spawn_nick = ply:Nick()
    end

    if not timer.Exists("namecheck") then
        timer.Create("namecheck", 3, 0, NameChangeKick)
    end
end

function StartWinChecks()
    hook.Add("PlayerDeath", "CheckJesterDeath", function(victim, infl, attacker)
        if victim:GetJester() and attacker:IsPlayer() and (not attacker:GetJester()) and GetRoundState() == ROUND_ACTIVE then
            jester_killed = true
        end
    end)

    if not timer.Start("winchecker") then
        timer.Create("winchecker", 1, 0, WinChecker)
    end
end

function StopWinChecks()
    hook.Remove("PlayerDeath", "CheckJesterDeath")
    timer.Stop("winchecker")
end

local function CleanUp()
    local et = ents.TTT
    -- if we are going to import entities, it's no use replacing HL2DM ones as
    -- soon as they spawn, because they'll be removed anyway
    et.SetReplaceChecking(not et.CanImportEntities(game.GetMap()))

    et.FixParentedPreCleanup()

    game.CleanUpMap()

    et.FixParentedPostCleanup()

    -- Strip players now, so that their weapons are not seen by ReplaceEntities
    for k, v in ipairs(player.GetAll()) do
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
    for _, v in pairs(player.GetAll()) do
        v:SetNWBool("HauntedSmoke", false)
        v:SetNWString("RevengerLover", "")
        v:SetNWString("JesterKiller", "")
        v:SetNWString("SwappedWith", "")
        v:SetNWBool("WasDrunk", false)
        v:SetNWString("WasHypnotised", "")
        v:SetNWBool("KillerClownActive", false)
        v:SetNWBool("HasPromotion", false)
        v:SetNWBool("WasBeggar", false)
        -- Workaround to prevent GMod sprint from working
        v:SetRunSpeed(v:GetWalkSpeed())
    end

    net.Start("TTT_UpdateOldManWins")
    net.WriteBool(false)
    net.Broadcast()

    jester_killed = false

    revenger_lover = nil

    -- Check playercount
    if CheckForAbort() then return end

    local delay_round, delay_length = hook.Call("TTTDelayRoundStartForVote", GAMEMODE)

    if delay_round then
        delay_length = delay_length or 30

        LANG.Msg("round_voting", { num = delay_length })

        timer.Create("delayedprep", delay_length, 1, PrepareRound)
        return
    end

    -- Cleanup
    CleanUp()

    GAMEMODE.MapWin = WIN_NONE
    GAMEMODE.AwardedCredits = false
    GAMEMODE.AwardedCreditsDead = 0

    SCORE:Reset()

    -- Update damage scaling
    KARMA.RoundBegin()

    -- New look. Random if no forced model set.
    GAMEMODE.playermodel = GAMEMODE.force_plymodel == "" and GetRandomPlayerModel() or GAMEMODE.force_plymodel
    GAMEMODE.playercolor = hook.Call("TTTPlayerColor", GAMEMODE, GAMEMODE.playermodel)

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
    hook.Call("TTTPrepareRound")

    ents.TTT.TriggerRoundStateOutputs(ROUND_PREP)
end

function SetRoundEnd(endtime)
    SetGlobalFloat("ttt_round_end", endtime)
end

function IncRoundEnd(incr)
    SetRoundEnd(GetGlobalFloat("ttt_round_end", 0) + incr)
end

function TellTraitorsAboutTraitors()
    local plys = player.GetAll()

    local traitornicks = {}
    local hasGlitch = false

    for k, v in ipairs(plys) do
        if v:IsTraitorTeam() then
            table.insert(traitornicks, v:Nick())
        elseif v:IsGlitch() then
            table.insert(traitornicks, v:Nick())
            hasGlitch = true
        end
    end

    -- This is ugly as hell, but it's kinda nice to filter out the names of the
    -- traitors themselves in the messages to them
    for k, v in ipairs(plys) do
        if v:IsTraitorTeam() then
            if hasGlitch then
                v:PrintMessage(HUD_PRINTTALK, "There is a Glitch.")
                v:PrintMessage(HUD_PRINTCENTER, "There is a Glitch.")
            end

            if #traitornicks < 2 then
                LANG.Msg(v, "round_traitors_one")
                return
            else
                local names = ""
                for i, name in ipairs(traitornicks) do
                    if name ~= v:Nick() then
                        names = names .. name .. ", "
                    end
                end
                names = string.sub(names, 1, -3)
                LANG.Msg(v, "round_traitors_more", { names = names })
            end
        end
    end
end

function SpawnWillingPlayers(dead_only)
    local plys = player.GetAll()
    local wave_delay = GetConVar("ttt_spawn_wave_interval"):GetFloat()

    -- simple method, should make this a case of the other method once that has
    -- been tested.
    if wave_delay <= 0 or dead_only then
        for k, ply in ipairs(plys) do
            if IsValid(ply) then
                ply:SpawnForRound(dead_only)
            end
        end
    else
        -- wave method
        local num_spawns = #GetSpawnEnts()

        local to_spawn = {}
        for _, ply in RandomPairs(plys) do
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

function BeginRound()
    GAMEMODE:SyncGlobals()

    if CheckForAbort() then return end

    InitRoundEndTime()

    if CheckForAbort() then return end

    -- Respawn dumb people who died during prep
    SpawnWillingPlayers(true)

    -- Remove their ragdolls
    ents.TTT.RemoveRagdolls(true)

    if CheckForAbort() then return end

    -- Select traitors & co. This is where things really start so we can't abort
    -- anymore.
    SelectRoles()
    LANG.Msg("round_selected")
    SendFullStateUpdate()

    -- Edge case where a player joins just as the round starts and is picked as
    -- traitor, but for whatever reason does not get the traitor state msg. So
    -- re-send after a second just to make sure everyone is getting it.
    timer.Simple(1, SendFullStateUpdate)
    timer.Simple(10, SendFullStateUpdate)

    SCORE:HandleSelection() -- log traitors and detectives

    for _, v in pairs(player.GetAll()) do
        -- Hypnotist logic
        if v:GetRole() == ROLE_HYPNOTIST then
            v:Give("weapon_ttt_brainwash")
        end

        -- Revenger logic
        if v:GetRole() == ROLE_REVENGER then
            if not revenger_lover then
                local potentialSoulmates = {}
                for i, p in pairs(player.GetAll()) do
                    if p:Alive() and not p:IsSpec() and not p:IsRevenger() then
                        table.insert(potentialSoulmates, p)
                    end
                end
                if #potentialSoulmates > 0 then
                    revenger_lover = potentialSoulmates[math.random(#potentialSoulmates)]
                    hook.Add("PlayerDeath", "CheckRevengerLoverDeath", function(victim, infl, attacker)
                        if victim == revenger_lover and GetRoundState() == ROUND_ACTIVE then
                            if attacker:IsPlayer() and infl:GetClass() ~= env_fire then
                                v:PrintMessage(HUD_PRINTTALK, "Your love has died. Track down their killer.")
                                v:PrintMessage(HUD_PRINTCENTER, "Your love has died. Track down their killer.")
                                if attacker:IsValid() and attacker:IsActive() then
                                    net.Start("TTT_UpdateRevengerLoverKiller", v)
                                    net.WriteVector(attacker:LocalToWorld(attacker:OBBCenter()))
                                    net.Send(v)
                                end
                                timer.Create("revengerloverkiller", 15, 0, function()
                                    if attacker:IsValid() and attacker:IsActive() then
                                        net.Start("TTT_UpdateRevengerLoverKiller", v)
                                        net.WriteVector(attacker:LocalToWorld(attacker:OBBCenter()))
                                        net.Send(v)
                                    end
                                end)
                            else
                                v:PrintMessage(HUD_PRINTTALK, "Your love has died, but you cannot determine the cause.")
                                v:PrintMessage(HUD_PRINTCENTER, "Your love has died, but you cannot determine the cause.")
                            end
                        end
                    end)
                end
            end

            v:PrintMessage(HUD_PRINTTALK, "You are in love with " .. revenger_lover:Nick() .. ".")
            v:PrintMessage(HUD_PRINTCENTER, "You are in love with " .. revenger_lover:Nick() .. ".")
        end

        -- Drunk logic
        SetGlobalFloat("ttt_drunk_remember", CurTime() + GetConVar("ttt_drunk_sober_time"):GetInt())
        if v:GetRole() == ROLE_DRUNK then
            timer.Create("drunkremember", GetConVar("ttt_drunk_sober_time"):GetInt(), 1, function()
                for _, p in pairs(player.GetAll()) do
                    if p:IsActiveDrunk() then
                        if math.random() <= GetConVar("ttt_drunk_innocent_chance"):GetFloat() then
                            p:SetRole(ROLE_INNOCENT)
                            p:SetNWBool("WasDrunk", true)
                            p:PrintMessage(HUD_PRINTTALK, "You have remembered that you are an innocent.")
                            p:PrintMessage(HUD_PRINTCENTER, "You have remembered that you are an innocent.")
                        else
                            p:SetRole(ROLE_TRAITOR)
                            p:SetNWBool("WasDrunk", true)
                            p:SetCredits(1)
                            p:PrintMessage(HUD_PRINTTALK, "You have remembered that you are a traitor.")
                            p:PrintMessage(HUD_PRINTCENTER, "You have remembered that you are a traitor.")
                        end
                        SendFullStateUpdate()
                    elseif p:IsDrunk() and not p:Alive() and not timer.Exists("waitfordrunkrespawn") then
                        timer.Create("waitfordrunkrespawn", 0.1, 0, function()
                            local dead_drunk = false
                            for _, p2 in pairs(player.GetAll()) do
                                if p2:IsActiveDrunk() then
                                    if math.random() <= GetConVar("ttt_drunk_innocent_chance"):GetFloat() then
                                        p2:SetRole(ROLE_INNOCENT)
                                        p2:SetNWBool("WasDrunk", true)
                                        p2:PrintMessage(HUD_PRINTTALK, "You have remembered that you are an innocent.")
                                        p2:PrintMessage(HUD_PRINTCENTER, "You have remembered that you are an innocent.")
                                    else
                                        p2:SetRole(ROLE_TRAITOR)
                                        p2:SetNWBool("WasDrunk", true)
                                        p2:SetCredits(1)
                                        p2:PrintMessage(HUD_PRINTTALK, "You have remembered that you are a traitor.")
                                        p2:PrintMessage(HUD_PRINTCENTER, "You have remembered that you are a traitor.")
                                    end
                                    SendFullStateUpdate()
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

        -- Clown logic
        if v:GetRole() == ROLE_CLOWN then
            v:SetNWBool("KillerClownActive", false)
        end

        -- Deputy and Impersonator logic
        if v:GetRole() == ROLE_DEPUTY or v:GetRole() == ROLE_IMPERSONATOR then
            v:SetNWBool("HasPromotion", false)
        end

        -- Old Man logic
        if v:GetRole() == ROLE_OLDMAN then
            local health = GetConVar("ttt_old_man_starting_health"):GetInt()
            v:SetMaxHealth(health)
            v:SetHealth(health)
        end
    end

    net.Start("TTT_ResetScoreboard")
    net.Broadcast()

    for _, v in pairs(player.GetAll()) do
        if revenger_lover then
            v:SetNWString("RevengerLover", revenger_lover:Nick() or "")
        end

        if v:Alive() and v:IsTerror() then
            net.Start("TTT_SpawnedPlayers")
            net.WriteString(v:Nick())
            net.Broadcast()
        end
    end

    -- Give the StateUpdate messages ample time to arrive
    timer.Simple(1.5, TellTraitorsAboutTraitors)
    timer.Simple(2.5, ShowRoundStartPopup)

    -- Start the win condition check timer
    StartWinChecks()
    StartNameChangeChecks()
    timer.Create("selectmute", 1, 1, function() MuteForRestart(false) end)

    GAMEMODE.DamageLog = {}
    GAMEMODE.RoundStartTime = CurTime()

    -- Sound start alarm
    SetRoundState(ROUND_ACTIVE)
    LANG.Msg("round_started")
    ServerLog("Round proper has begun...\n")

    GAMEMODE:UpdatePlayerLoadouts() -- needs to happen when round_active

    hook.Call("TTTBeginRound")

    ents.TTT.TriggerRoundStateOutputs(ROUND_BEGIN)
end

function PrintResultMessage(type)
    ServerLog("Round ended.\n")
    if type == WIN_TIMELIMIT then
        LANG.Msg("win_time")
        ServerLog("Result: timelimit reached, traitors lose.\n")
    elseif type == WIN_TRAITOR then
        LANG.Msg("win_traitor")
        ServerLog("Result: Traitors win.\n")
    elseif type == WIN_INNOCENT then
        LANG.Msg("win_innocent")
        ServerLog("Result: Innocent win.\n")
    elseif type == WIN_JESTER then
        LANG.Msg("win_jester")
        ServerLog("Result: Jester wins.\n")
    elseif type == WIN_CLOWN then
        LANG.Msg("win_clown")
        ServerLog("Result: Clown wins.\n")
    else
        ServerLog("Result: unknown victory condition!\n")
    end
end

function CheckForMapSwitch()
    -- Check for mapswitch
    local rounds_left = math.max(0, GetGlobalInt("ttt_rounds_left", 6) - 1)
    SetGlobalInt("ttt_rounds_left", rounds_left)

    local time_left = math.max(0, (GetConVar("ttt_time_limit_minutes"):GetInt() * 60) - CurTime())
    local switchmap = false
    local nextmap = string.upper(game.GetMapNext())

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

    hook.Remove("PlayerDeath", "CheckRevengerLoverDeath")

    if timer.Exists("revengerloverkiller") then timer.Remove("revengerloverkiller") end
    if timer.Exists("drunkremember") then timer.Remove("drunkremember") end
    if timer.Exists("waitfordrunkrespawn") then timer.Remove("waitfordrunkrespawn") end

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
    hook.Call("TTTEndRound", GAMEMODE, type)

    ents.TTT.TriggerRoundStateOutputs(ROUND_POST, type)
end

function GM:MapTriggeredEnd(wintype)
    self.MapWin = wintype
end

-- The most basic win check is whether both sides have one dude alive
function GM:TTTCheckForWin()
    if ttt_dbgwin:GetBool() then return WIN_NONE end

    if GAMEMODE.MapWin == WIN_TRAITOR or GAMEMODE.MapWin == WIN_INNOCENT then
        local mw = GAMEMODE.MapWin
        GAMEMODE.MapWin = WIN_NONE
        return mw
    end

    local traitor_alive = false
    local innocent_alive = false
    local jester_alive = false
    local drunk_alive = false
    local clown_alive = false
    local old_man_alive = false

    local killer_clown_active = false

    for _, v in ipairs(player.GetAll()) do
        if v:Alive() and v:IsTerror() then
            if v:IsTraitorTeam() then
                traitor_alive = true
            elseif v:IsJester() then
                jester_alive = true
            elseif v:IsDrunk() then
                drunk_alive = true
            elseif v:IsClown() then
                clown_alive = true
                killer_clown_active = v:GetNWBool("KillerClownActive", false)
            elseif v:IsOldMan() then
                old_man_alive = true
            else
                innocent_alive = true
            end
        end

        if traitor_alive and innocent_alive and jester_alive then
            return WIN_NONE --early out
        end
    end

    local win_type = WIN_NONE

    if jester_killed then
        win_type = WIN_JESTER
    elseif not innocent_alive then
        win_type = WIN_TRAITOR
    elseif not traitor_alive then
        win_type = WIN_INNOCENT
    end

    -- Drunk logic
    if drunk_alive then
        if win_type == WIN_INNOCENT then
            if timer.Exists("drunkremember") then timer.Remove("drunkremember") end
            if timer.Exists("waitfordrunkrespawn") then timer.Remove("waitfordrunkrespawn") end
            for _, v in ipairs(player.GetAll()) do
                if v:Alive() and v:IsTerror() and v:IsDrunk() then
                    v:SetRole(ROLE_TRAITOR)
                    v:SetNWBool("WasDrunk", true)
                    v:SetCredits(1)
                    v:PrintMessage(HUD_PRINTTALK, "You have remembered that you are a traitor.")
                    v:PrintMessage(HUD_PRINTCENTER, "You have remembered that you are a traitor.")
                    SendFullStateUpdate()
                end
            end
            win_type = WIN_NONE
        elseif win_type == WIN_TRAITOR then
            if timer.Exists("drunkremember") then timer.Remove("drunkremember") end
            if timer.Exists("waitfordrunkrespawn") then timer.Remove("waitfordrunkrespawn") end
            for _, v in ipairs(player.GetAll()) do
                if v:Alive() and v:IsTerror() and v:IsDrunk() then
                    v:SetRole(ROLE_INNOCENT)
                    v:SetNWBool("WasDrunk", true)
                    v:PrintMessage(HUD_PRINTTALK, "You have remembered that you are an innocent.")
                    v:PrintMessage(HUD_PRINTCENTER, "You have remembered that you are an innocent.")
                    SendFullStateUpdate()
                end
            end
            win_type = WIN_NONE
        end
    end

    -- Clown logic
    if clown_alive then
        if not killer_clown_active and (win_type == WIN_INNOCENT or win_type == WIN_TRAITOR) then
            for _, v in ipairs(player.GetAll()) do
                if v:IsClown() then
                    v:SetNWBool("KillerClownActive", true)
                    v:PrintMessage(HUD_PRINTTALK, "KILL THEM ALL!")
                    v:PrintMessage(HUD_PRINTCENTER, "KILL THEM ALL!")
                    net.Start("TTT_ClownActivate")
                    net.WriteEntity(v)
                    net.Broadcast()
                end
            end
            win_type = WIN_NONE
        elseif killer_clown_active and not traitor_alive and not innocent_alive then
            win_type = WIN_CLOWN
        else
            win_type = WIN_NONE
        end
    end

    -- Old Man logic
    if old_man_alive then
        if win_type ~= WIN_NONE then
            net.Start("TTT_UpdateOldManWins")
            net.WriteBool(true)
            net.Broadcast()
        end
    end

    return win_type
end

local function GetTraitorCount(ply_count)
    -- get number of traitors: pct of players rounded up
    local traitor_count = math.ceil(ply_count * GetConVar("ttt_traitor_pct"):GetFloat())
    -- make sure there is at least 1 traitor
    traitor_count = math.Clamp(traitor_count, 1, GetConVar("ttt_traitor_max"):GetInt())

    return traitor_count
end

local function GetDetectiveCount(ply_count)
    local detective_count = math.ceil(ply_count * GetConVar("ttt_detective_pct"):GetFloat())

    detective_count = math.Clamp(detective_count, 1, GetConVar("ttt_detective_max"):GetInt())

    return detective_count
end

local function GetSpecialTraitorCount(ply_count)
    -- get number of special traitors: pct of traitors rounded up
    local special_traitor_count = math.ceil(ply_count * GetConVar("ttt_special_traitor_pct"):GetFloat())

    return special_traitor_count
end

local function GetSpecialInnocentCount(ply_count)
    -- get number of special innocents: pct of innocents rounded up
    local special_innocent_count = math.ceil(ply_count * GetConVar("ttt_special_innocent_pct"):GetFloat())

    return special_innocent_count
end

function SelectRoles()
    local choices = {}
    local prev_roles = {
        [ROLE_INNOCENT] = {},
        [ROLE_TRAITOR] = {},
        [ROLE_DETECTIVE] = {},
        [ROLE_JESTER] = {},
        [ROLE_SWAPPER] = {},
        [ROLE_GLITCH] = {},
        [ROLE_PHANTOM] = {},
        [ROLE_HYPNOTIST] = {},
        [ROLE_REVENGER] = {},
        [ROLE_DRUNK] = {},
        [ROLE_CLOWN] = {},
        [ROLE_DEPUTY] = {},
        [ROLE_IMPERSONATOR] = {},
        [ROLE_BEGGAR] = {},
        [ROLE_OLDMAN] = {}
    };

    if not GAMEMODE.LastRole then GAMEMODE.LastRole = {} end

    local plys = player.GetAll()

    for k, v in ipairs(plys) do
        -- everyone on the spec team is in specmode
        if IsValid(v) and (not v:IsSpec()) then
            -- save previous role and sign up as possible traitor/detective

            local r = GAMEMODE.LastRole[v:SteamID64()] or v:GetRole() or ROLE_INNOCENT

            table.insert(prev_roles[r], v)

            table.insert(choices, v)
        end

        v:SetRole(ROLE_INNOCENT)
    end

    -- determine how many of each role we want
    local choice_count = #choices
    local traitor_count = GetTraitorCount(choice_count)
    local detective_count = GetDetectiveCount(choice_count)
    local independent_count = 1 and (math.random() <= GetConVar("ttt_independent_chance"):GetFloat()) or 0
    local max_special_traitor_count = GetSpecialTraitorCount(traitor_count)

    -- special spawning cvars
    local deputy_only = false
    local impersonator_only = false
    if GetConVar("ttt_single_deputy_impersonator"):GetBool() then
        if math.random() <= 0.5 then
            deputy_only = true
        else
            impersonator_only = true
        end
    end

    if choice_count == 0 then return end

    -- pick detectives
    if choice_count >= GetConVar("ttt_detective_min_players"):GetInt() then
        for i = 1, detective_count do
            if #choices > 0 then
                local plyPick = math.random(1, #choices)
                local ply = choices[plyPick]
                ply:SetRole(ROLE_DETECTIVE)
                ply:SetHealth(GetConVar("ttt_detective_starting_health"):GetInt())
                table.remove(choices, plyPick)
            end
        end
    end

    -- pick traitors
    local traitors = {}
    for i = 1, traitor_count do
        if #choices > 0 then
            local plyPick = math.random(1, #choices)
            local ply = choices[plyPick]
            ply:SetRole(ROLE_TRAITOR)
            table.insert(traitors, ply)
            table.remove(choices, plyPick)
        end
    end

    -- pick special traitors
    local specialTraitorRoles = {}
    if GetConVar("ttt_hypnotist_enabled"):GetBool() and choice_count >= GetConVar("ttt_hypnotist_min_players"):GetInt() then
        for i = 1, GetConVar("ttt_hypnotist_spawn_weight"):GetInt() do
            table.insert(specialTraitorRoles, ROLE_HYPNOTIST)
        end
    end
    if GetConVar("ttt_impersonator_enabled"):GetBool() and detective_count > 0 and not deputy_only and choice_count >= GetConVar("ttt_impersonator_min_players"):GetInt() then
        for i = 1, GetConVar("ttt_impersonator_spawn_weight"):GetInt() do
            table.insert(specialTraitorRoles, ROLE_IMPERSONATOR)
        end
    end
    for i = 1, max_special_traitor_count do
        if #specialTraitorRoles ~= 0 and math.random() <= GetConVar("ttt_special_traitor_chance"):GetFloat() and #traitors > 0 then
            local plyPick = math.random(1, #traitors)
            local ply = traitors[plyPick]
            local rolePick = math.random(1, #specialTraitorRoles)
            local role = specialTraitorRoles[rolePick]
            ply:SetRole(role)
            table.remove(traitors, plyPick)
            for i = #specialTraitorRoles, 1, -1 do
                if specialTraitorRoles[i] == role then
                    table.remove(specialTraitorRoles, i)
                end
            end
        end
    end

    -- pick independent
    if independent_count ~= 0 and #choices > 0 then
        local independentRoles = {}
        if GetConVar("ttt_jester_enabled"):GetBool() and choice_count >= GetConVar("ttt_jester_min_players"):GetInt() then
            for i = 1, GetConVar("ttt_jester_spawn_weight"):GetInt() do
                table.insert(independentRoles, ROLE_JESTER)
            end
        end
        if GetConVar("ttt_swapper_enabled"):GetBool() and choice_count >= GetConVar("ttt_swapper_min_players"):GetInt() then
            for i = 1, GetConVar("ttt_swapper_spawn_weight"):GetInt() do
                table.insert(independentRoles, ROLE_SWAPPER)
            end
        end
        if GetConVar("ttt_drunk_enabled"):GetBool() and choice_count >= GetConVar("ttt_drunk_min_players"):GetInt() then
            for i = 1, GetConVar("ttt_drunk_spawn_weight"):GetInt() do
                table.insert(independentRoles, ROLE_DRUNK)
            end
        end
        if GetConVar("ttt_clown_enabled"):GetBool() and choice_count >= GetConVar("ttt_clown_min_players"):GetInt() then
            for i = 1, GetConVar("ttt_clown_spawn_weight"):GetInt() do
                table.insert(independentRoles, ROLE_CLOWN)
            end
        end
        if GetConVar("ttt_beggar_enabled"):GetBool() and choice_count >= GetConVar("ttt_beggar_min_players"):GetInt() then
            for i = 1, GetConVar("ttt_beggar_spawn_weight"):GetInt() do
                table.insert(independentRoles, ROLE_BEGGAR)
            end
        end
        if GetConVar("ttt_old_man_enabled"):GetBool() and choice_count >= GetConVar("ttt_old_man_min_players"):GetInt() then
            for i = 1, GetConVar("ttt_old_man_spawn_weight"):GetInt() do
                table.insert(independentRoles, ROLE_OLDMAN)
            end
        end
        if #independentRoles ~= 0 then
            local plyPick = math.random(1, #choices)
            local ply = choices[plyPick]
            local rolePick = math.random(1, #independentRoles)
            local role = independentRoles[rolePick]
            ply:SetRole(role)
            table.remove(choices, plyPick)
            for i = #independentRoles, 1, -1 do
                if independentRoles[i] == role then
                    table.remove(independentRoles, i)
                end
            end
        end
    end

    -- pick special innocents
    local max_special_innocent_count = GetSpecialInnocentCount(#choices)
    local specialInnocentRoles = {}
    if GetConVar("ttt_glitch_enabled"):GetBool() and #traitors > 1 and choice_count >= GetConVar("ttt_glitch_min_players"):GetInt() then
        for i = 1, GetConVar("ttt_glitch_spawn_weight"):GetInt() do
            table.insert(specialInnocentRoles, ROLE_GLITCH)
        end
    end
    if GetConVar("ttt_phantom_enabled"):GetBool() and choice_count >= GetConVar("ttt_phantom_min_players"):GetInt() then
        for i = 1, GetConVar("ttt_phantom_spawn_weight"):GetInt() do
            table.insert(specialInnocentRoles, ROLE_PHANTOM)
        end
    end
    if GetConVar("ttt_revenger_enabled"):GetBool() and choice_count > 1 and choice_count >= GetConVar("ttt_revenger_min_players"):GetInt() then
        for i = 1, GetConVar("ttt_revenger_spawn_weight"):GetInt() do
            table.insert(specialInnocentRoles, ROLE_REVENGER)
        end
    end
    if GetConVar("ttt_deputy_enabled"):GetBool() and detective_count > 0 and not impersonator_only and choice_count >= GetConVar("ttt_deputy_min_players"):GetInt() then
        for i = 1, GetConVar("ttt_deputy_spawn_weight"):GetInt() do
            table.insert(specialInnocentRoles, ROLE_DEPUTY)
        end
    end
    for i = 1, max_special_innocent_count do
        if #specialInnocentRoles ~= 0 and math.random() <= GetConVar("ttt_special_innocent_chance"):GetFloat() and #choices > 0 then
            local plyPick = math.random(1, #choices)
            local ply = choices[plyPick]
            local rolePick = math.random(1, #specialInnocentRoles)
            local role = specialInnocentRoles[rolePick]
            ply:SetRole(role)
            table.remove(choices, plyPick)
            for i = #specialInnocentRoles, 1, -1 do
                if specialInnocentRoles[i] == role then
                    table.remove(specialInnocentRoles, i)
                end
            end
        end
    end

    GAMEMODE.LastRole = {}

    for _, ply in ipairs(plys) do
        -- initialize credit count for everyone based on their role
        ply:SetDefaultCredits()

        -- store a steamid -> role map
        GAMEMODE.LastRole[ply:SteamID64()] = ply:GetRole()
    end
end

local function ForceRoundRestart(ply, command, args)
    -- ply is nil on dedicated server console
    if (not IsValid(ply)) or ply:IsAdmin() or ply:IsSuperAdmin() or cvars.Bool("sv_cheats", 0) then
        LANG.Msg("round_restart")

        StopRoundTimers()

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

-- Hit Markers
hook.Add("EntityTakeDamage", "HitmarkerDetector", function(ent, dmginfo)
    local att = dmginfo:GetAttacker()

    if (IsValid(att) and att:IsPlayer() and att ~= ent) then
        if (ent:IsPlayer() or ent:IsNPC()) then
            net.Start("TTT_DrawHitMarker")
            net.WriteBool(ent:GetNWBool("LastHitCrit"))
            net.Send(att) -- Send the message to the attacker
        end
    end
end)

hook.Add("ScalePlayerDamage", "HitmarkerPlayerCritDetector", function(ply, hitgroup, dmginfo)
    ply:SetNWBool("LastHitCrit", hitgroup == HITGROUP_HEAD)
end)

hook.Add("ScaleNPCDamage", "HitmarkerPlayerCritDetector", function(npc, hitgroup, dmginfo)
    npc:SetNWBool("LastHitCrit", hitgroup == HITGROUP_HEAD)
end)

-- Death messages
hook.Add("PlayerDeath", "Kill_Reveal_Notify", function(victim, entity, killer)
    if gmod.GetGamemode().Name == "Trouble in Terrorist Town" then
        local reason = "nil"
        local killerName = "nil"
        local role = ROLE_NONE

        if victim.DiedByWater then
            reason = "water"
        elseif killer == victim then
            reason = "suicide"
        elseif IsValid(entity) then
            if victim:IsPlayer() and (string.StartWith(entity:GetClass(), "prop_physics") or entity:GetClass() == "prop_dynamic") then
                -- If the killer is also a prop
                reason = "prop"
            elseif IsValid(killer) then
                if entity:GetClass() == "entityflame" and killer:GetClass() == "entityflame" then
                    reason = "burned"
                elseif entity:GetClass() == "worldspawn" and killer:GetClass() == "worldspawn" then
                    reason = "fell"
                elseif killer:IsPlayer() and victim ~= killer then
                    reason = "ply"
                    killerName = killer:Nick()
                    role = killer:GetRole()
                end
            end
        end

        -- Send the buffer message with the death information to the victim
        net.Start("TTT_ClientDeathNotify")
        net.WriteString(killerName)
        net.WriteUInt(role, 8)
        net.WriteString(reason)
        net.Send(victim)
    end
end)

-- Sprint
net.Receive("TTT_SprintSpeedSet", function(len, ply)
    local mul = net.ReadFloat()
    if mul ~= 0 then
        ply.mult = 1 + mul
    else
        ply.mult = nil
    end
end)

-- Send ConVars if requested
net.Receive("TTT_SprintGetConVars", function(len, ply)
    local Table = {
        [1] = speedMultiplier:GetFloat();
        [2] = recovery:GetFloat();
        [3] = traitorRecovery:GetFloat();
        [4] = consumption:GetFloat();
    }
    net.Start("TTT_SprintGetConVars")
    net.WriteTable(Table)
    net.Send(ply)
end)

-- return Speed
hook.Add("TTTPlayerSpeedModifier", "TTTSprintPlayerSpeed", function(ply, _, _)
    return GetSprintMultiplier(ply, ply.mult ~= nil)
end)