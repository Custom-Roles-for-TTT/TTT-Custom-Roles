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

-- Role spawn parameters
CreateConVar("ttt_special_innocent_pct", 0.33)
CreateConVar("ttt_special_innocent_chance", 0.5)
CreateConVar("ttt_special_traitor_pct", 0.33)
CreateConVar("ttt_special_traitor_chance", 0.5)
CreateConVar("ttt_independent_chance", 0.5)
CreateConVar("ttt_monster_pct", 0.33)
CreateConVar("ttt_monster_chance", 0.5)

for role = 0, ROLE_MAX do
    local rolestring = ROLE_STRINGS_RAW[role]
    if not DEFAULT_ROLES[role] then
        CreateConVar("ttt_" .. rolestring .. "_enabled", "0", FCVAR_REPLICATED)
        CreateConVar("ttt_" .. rolestring .. "_spawn_weight", "1", FCVAR_REPLICATED)
        CreateConVar("ttt_" .. rolestring .. "_min_players", "0", FCVAR_REPLICATED)
    end

    local health = "100"
    if role == ROLE_OLDMAN then health = "1"
    elseif role == ROLE_KILLER then health = "150" end
    CreateConVar("ttt_" .. rolestring .. "_starting_health", health, FCVAR_REPLICATED)
    CreateConVar("ttt_" .. rolestring .. "_max_health", health, FCVAR_REPLICATED)
    CreateConVar("ttt_" .. rolestring .. "_name", "", FCVAR_REPLICATED)
    CreateConVar("ttt_" .. rolestring .. "_name_plural", "", FCVAR_REPLICATED)
    CreateConVar("ttt_" .. rolestring .. "_name_article", "", FCVAR_REPLICATED)
end

-- Traitor role properties
CreateConVar("ttt_traitor_vision_enable", "0")

CreateConVar("ttt_impersonator_damage_penalty", "0")
CreateConVar("ttt_impersonator_use_detective_icon", "1")

CreateConVar("ttt_assassin_show_target_icon", "0")
CreateConVar("ttt_assassin_next_target_delay", "5")
CreateConVar("ttt_assassin_target_damage_bonus", "1")
CreateConVar("ttt_assassin_wrong_damage_penalty", "0.5")
CreateConVar("ttt_assassin_failed_damage_penalty", "0.5")
CreateConVar("ttt_assassin_shop_roles_last", "0")

CreateConVar("ttt_vampires_are_monsters", "0")
CreateConVar("ttt_vampire_show_target_icon", "0")
CreateConVar("ttt_vampire_damage_reduction", "0")
CreateConVar("ttt_vampire_prime_death_mode", "0")
CreateConVar("ttt_vampire_vision_enable", "0")

CreateConVar("ttt_parasite_infection_time", 90)
CreateConVar("ttt_parasite_infection_transfer", 0)
CreateConVar("ttt_parasite_infection_transfer_reset", 1)
CreateConVar("ttt_parasite_respawn_mode", 0)
CreateConVar("ttt_parasite_respawn_health", 100)
CreateConVar("ttt_parasite_announce_infection", 0)

-- Innocent role properties
CreateConVar("ttt_detective_search_only", "1")
CreateConVar("ttt_all_search_postround", "1")

CreateConVar("ttt_phantom_respawn_health", "50")
CreateConVar("ttt_phantom_weaker_each_respawn", "0")
CreateConVar("ttt_phantom_killer_smoke", "0")
CreateConVar("ttt_phantom_killer_footstep_time", "0")
CreateConVar("ttt_phantom_announce_death", "0")
CreateConVar("ttt_phantom_killer_haunt", "1")
CreateConVar("ttt_phantom_killer_haunt_power_max", "100")
CreateConVar("ttt_phantom_killer_haunt_power_rate", "10")
CreateConVar("ttt_phantom_killer_haunt_move_cost", "25")
CreateConVar("ttt_phantom_killer_haunt_jump_cost", "50")
CreateConVar("ttt_phantom_killer_haunt_drop_cost", "75")
CreateConVar("ttt_phantom_killer_haunt_attack_cost", "100")

CreateConVar("ttt_doctor_mode", "0")

CreateConVar("ttt_revenger_radar_timer", "15")
CreateConVar("ttt_revenger_damage_bonus", "0")
CreateConVar("ttt_revenger_drain_health_to", "-1")

CreateConVar("ttt_deputy_damage_penalty", "0")
CreateConVar("ttt_deputy_use_detective_icon", "1")

CreateConVar("ttt_veteran_damage_bonus", "0.5")
CreateConVar("ttt_veteran_full_heal", "1")
CreateConVar("ttt_veteran_heal_bonus", "0")
CreateConVar("ttt_veteran_announce", "0")

-- Jester role properties
CreateConVar("ttt_jesters_trigger_traitor_testers", "1")
CreateConVar("ttt_jesters_visible_to_traitors", "1")
CreateConVar("ttt_jesters_visible_to_monsters", "1")
CreateConVar("ttt_jesters_visible_to_independents", "1")

CreateConVar("ttt_jester_win_by_traitors", "1")
CreateConVar("ttt_jester_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that the Jester is killed", 0, 4)
CreateConVar("ttt_jester_notify_sound", "0")
CreateConVar("ttt_jester_notify_confetti", "0")

CreateConVar("ttt_swapper_killer_health", "100")
CreateConVar("ttt_swapper_respawn_health", "100")
CreateConVar("ttt_swapper_weapon_mode", "1", FCVAR_NONE, "How to handle weapons when the Swapper is killed", 0, 2)
CreateConVar("ttt_swapper_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that the Swapper is killed", 0, 4)
CreateConVar("ttt_swapper_notify_sound", "0")
CreateConVar("ttt_swapper_notify_confetti", "0")

CreateConVar("ttt_clown_damage_bonus", "0")
CreateConVar("ttt_clown_activation_credits", "0")
CreateConVar("ttt_clown_hide_when_active", "0")
CreateConVar("ttt_clown_show_target_icon", "0")
CreateConVar("ttt_clown_heal_on_activate", "0")
CreateConVar("ttt_clown_shop_active_only", "1")
CreateConVar("ttt_clown_shop_delay", "0")

CreateConVar("ttt_beggar_reveal_change", "1")
CreateConVar("ttt_beggar_respawn", "0")
CreateConVar("ttt_beggar_respawn_delay", "3")
CreateConVar("ttt_beggar_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that the Beggar is killed", 0, 4)
CreateConVar("ttt_beggar_notify_sound", "0")
CreateConVar("ttt_beggar_notify_confetti", "0")

CreateConVar("ttt_bodysnatcher_destroy_body", "0")
CreateConVar("ttt_bodysnatcher_show_role", "1")

-- Independent role properties
CreateConVar("ttt_independents_trigger_traitor_testers", "0")

CreateConVar("ttt_drunk_sober_time", "180")
CreateConVar("ttt_drunk_innocent_chance", "0.7")

CreateConVar("ttt_oldman_drain_health_to", "0")

CreateConVar("ttt_killer_knife_enabled", "1")
CreateConVar("ttt_killer_crowbar_enabled", "1")
CreateConVar("ttt_killer_smoke_enabled", "1")
CreateConVar("ttt_killer_smoke_timer", "60")
CreateConVar("ttt_killer_show_target_icon", "1")
CreateConVar("ttt_killer_damage_penalty", "0.25")
CreateConVar("ttt_killer_damage_reduction", "0")
CreateConVar("ttt_killer_warn_all", "0")
CreateConVar("ttt_killer_vision_enable", "1")

CreateConVar("ttt_zombies_are_monsters", "0")
CreateConVar("ttt_zombies_are_traitors", "0")
CreateConVar("ttt_zombie_round_chance", 0.1)
CreateConVar("ttt_zombie_show_target_icon", "0")
CreateConVar("ttt_zombie_damage_penalty", "0.5")
CreateConVar("ttt_zombie_damage_reduction", "0")
CreateConVar("ttt_zombie_prime_only_weapons", "1")
CreateConVar("ttt_zombie_prime_speed_bonus", "0.35")
CreateConVar("ttt_zombie_thrall_speed_bonus", "0.15")
CreateConVar("ttt_zombie_vision_enable", "0")

-- Other custom role properties
CreateConVar("ttt_single_deputy_impersonator", "0")
CreateConVar("ttt_single_doctor_quack", "0")

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

-- Shop parameters
for _, role in ipairs(table.GetKeys(SHOP_ROLES)) do
    local rolestring = ROLE_STRINGS_RAW[role]
    if not DEFAULT_ROLES[role] then
        local credits = "0"
        if TRAITOR_ROLES[role] then credits = "1"
        elseif role == ROLE_MERCENARY then credits = "1"
        elseif role == ROLE_KILLER then credits = "2" end
        CreateConVar("ttt_" .. rolestring .. "_credits_starting", credits, FCVAR_REPLICATED)
    end

    CreateConVar("ttt_" .. rolestring .. "_shop_random_percent", "0", FCVAR_REPLICATED, "The percent chance that a weapon in the shop will not be shown for the " .. rolestring, 0, 100)
    CreateConVar("ttt_" .. rolestring .. "_shop_random_enabled", "0", FCVAR_REPLICATED, "Whether shop randomization should run for the " .. rolestring)

    if (TRAITOR_ROLES[role] and role ~= ROLE_TRAITOR) or role == ROLE_ZOMBIE then -- This all happens before we run UpdateRoleState so we need to manually add zombies
        CreateConVar("ttt_" .. rolestring .. "_shop_sync", "0", FCVAR_REPLICATED)
    end

    if role == ROLE_MERCENARY then
        CreateConVar("ttt_" .. rolestring .. "_shop_mode", "2", FCVAR_REPLICATED)
    elseif (INDEPENDENT_ROLES[role] and role ~= ROLE_ZOMBIE) or role == ROLE_CLOWN then
        CreateConVar("ttt_" .. rolestring .. "_shop_mode", "0", FCVAR_REPLICATED)
    end
end
CreateConVar("ttt_shop_random_percent", "50", FCVAR_REPLICATED, "The percent chance that a weapon in the shop will not be shown by default", 0, 100)
CreateConVar("ttt_shop_random_position", "0", FCVAR_REPLICATED, "Whether to randomize the position of the items in the shop")

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

-- bem server convars
CreateConVar("ttt_bem_allow_change", 1, { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE }, "Allow clients to change the look of the shop menu")
CreateConVar("ttt_bem_sv_cols", 4, { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE }, "Sets the number of columns in the shop menu's item list (serverside)")
CreateConVar("ttt_bem_sv_rows", 5, { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE }, "Sets the number of rows in the shop menu's item list (serverside)")
CreateConVar("ttt_bem_sv_size", 64, { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE }, "Sets the item size in the shop menu's item list (serverside)")

-- sprint convars
local speedMultiplier = CreateConVar("ttt_sprint_bonus_rel", "0.4", FCVAR_SERVER_CAN_EXECUTE, "The relative speed bonus given while sprinting. Def: 0.4")
local recovery = CreateConVar("ttt_sprint_regenerate_innocent", "0.08", FCVAR_SERVER_CAN_EXECUTE, "Sets stamina regeneration for innocents. Def: 0.08")
local traitorRecovery = CreateConVar("ttt_sprint_regenerate_traitor", "0.12", FCVAR_SERVER_CAN_EXECUTE, "Sets stamina regeneration speed for traitors. Def: 0.12")
local consumption = CreateConVar("ttt_sprint_consume", "0.2", FCVAR_SERVER_CAN_EXECUTE, "Sets stamina consumption speed. Def: 0.2")

local ttt_detective = CreateConVar("ttt_sherlock_mode", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY)
local ttt_minply = CreateConVar("ttt_minimum_players", "2", FCVAR_ARCHIVE + FCVAR_NOTIFY)

-- debuggery
local ttt_dbgwin = CreateConVar("ttt_debug_preventwin", "0")
CreateConVar("ttt_debug_logkills", "1")
local ttt_dbgroles = CreateConVar("ttt_debug_logroles", "1")

local function OldCVarWarning(oldName, newName)
    cvars.AddChangeCallback(oldName, function(convar, oldValue, newValue)
        RunConsoleCommand(newName, newValue)
        ErrorNoHalt("WARNING: ConVar \'" .. oldName .. "\' deprecated. Use \'" .. newName .. "\' instead!\n")
    end)
end

-- OLD CVARS CHECKS
CreateConVar("ttt_old_man_enabled", 0)
OldCVarWarning("ttt_old_man_enabled", "ttt_oldman_enabled")

CreateConVar("ttt_old_man_spawn_weight", "1")
OldCVarWarning("ttt_old_man_spawn_weight", "ttt_oldman_spawn_weight")

CreateConVar("ttt_old_man_min_players", "0")
OldCVarWarning("ttt_old_man_min_players", "ttt_oldman_min_players")

CreateConVar("ttt_old_man_starting_health", "1")
OldCVarWarning("ttt_old_man_starting_health", "ttt_oldman_starting_health")

CreateConVar("ttt_reveal_beggar_change", "1")
OldCVarWarning("ttt_reveal_beggar_change", "ttt_beggar_reveal_change")

CreateConVar("ttt_hyp_credits_starting", "1")
OldCVarWarning("ttt_hyp_credits_starting", "ttt_hypnotist_credits_starting")

CreateConVar("ttt_imp_credits_starting", "1")
OldCVarWarning("ttt_imp_credits_starting", "ttt_impersonator_credits_starting")

CreateConVar("ttt_asn_credits_starting", "1")
OldCVarWarning("ttt_asn_credits_starting", "ttt_assassin_credits_starting")

CreateConVar("ttt_vam_credits_starting", "1")
OldCVarWarning("ttt_vam_credits_starting", "ttt_vampire_credits_starting")

CreateConVar("ttt_qua_credits_starting", "1")
OldCVarWarning("ttt_qua_credits_starting", "ttt_quack_credits_starting")

CreateConVar("ttt_par_credits_starting", "1")
OldCVarWarning("ttt_par_credits_starting", "ttt_parasite_credits_starting")

CreateConVar("ttt_mer_credits_starting", "1")
OldCVarWarning("ttt_mer_credits_starting", "ttt_mercenary_credits_starting")

CreateConVar("ttt_jes_credits_starting", "0")
OldCVarWarning("ttt_jes_credits_starting", "ttt_jester_credits_starting")

CreateConVar("ttt_swa_credits_starting", "0")
OldCVarWarning("ttt_swa_credits_starting", "ttt_swapper_credits_starting")

CreateConVar("ttt_kil_credits_starting", "2")
OldCVarWarning("ttt_kil_credits_starting", "ttt_killer_credits_starting")

CreateConVar("ttt_zom_credits_starting", "0")
OldCVarWarning("ttt_zom_credits_starting", "ttt_zombie_credits_starting")

CreateConVar("ttt_shop_hyp_sync", "0")
OldCVarWarning("ttt_shop_hyp_sync", "ttt_hypnotist_shop_sync")

CreateConVar("ttt_shop_imp_sync", "0")
OldCVarWarning("ttt_shop_imp_sync", "ttt_impersonator_shop_sync")

CreateConVar("ttt_shop_asn_sync", "0")
OldCVarWarning("ttt_shop_asn_sync", "ttt_assassin_shop_sync")

CreateConVar("ttt_shop_vam_sync", "0")
OldCVarWarning("ttt_shop_vam_sync", "ttt_vampire_shop_sync")

CreateConVar("ttt_shop_zom_sync", "0")
OldCVarWarning("ttt_shop_zom_sync", "ttt_zombie_shop_sync")

CreateConVar("ttt_shop_qua_sync", "0")
OldCVarWarning("ttt_shop_qua_sync", "ttt_quack_shop_sync")

CreateConVar("ttt_shop_par_sync", "0")
OldCVarWarning("ttt_shop_par_sync", "ttt_parasite_shop_sync")

CreateConVar("ttt_shop_mer_mode", "2")
OldCVarWarning("ttt_shop_mer_mode", "ttt_mercenary_shop_mode")

CreateConVar("ttt_shop_clo_mode", "0")
OldCVarWarning("ttt_shop_clo_mode", "ttt_clown_shop_mode")

for _, role in ipairs(table.GetKeys(SHOP_ROLES)) do
    local shortstring = ROLE_STRINGS_SHORT[role]
    local rolestring = ROLE_STRINGS_RAW[role]
    CreateConVar("ttt_shop_random_" .. shortstring .. "_percent", "0", FCVAR_REPLICATED, "The percent chance that a weapon in the shop will not be shown for the " .. rolestring, 0, 100)
    OldCVarWarning("ttt_shop_random_" .. shortstring .. "_percent", "ttt_" .. rolestring .. "_shop_random_percent")
    CreateConVar("ttt_shop_random_" .. shortstring .. "_enabled", "0", FCVAR_REPLICATED, "Whether shop randomization should run for the " .. rolestring)
    OldCVarWarning("ttt_shop_random_" .. shortstring .. "_enabled", "ttt_" .. rolestring .. "_shop_random_enabled")
end

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
util.AddNetworkString("TTT_PlayerDisconnected")
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
util.AddNetworkString("TTT_CreateBlood")
util.AddNetworkString("TTT_OpenMixer")
util.AddNetworkString("TTT_ClientDeathNotify")
util.AddNetworkString("TTT_SprintSpeedSet")
util.AddNetworkString("TTT_SprintGetConVars")
util.AddNetworkString("TTT_SpawnedPlayers")
util.AddNetworkString("TTT_Defibrillated")
util.AddNetworkString("TTT_RoleChanged")
util.AddNetworkString("TTT_SwapperSwapped")
util.AddNetworkString("TTT_BeggarConverted")
util.AddNetworkString("TTT_BeggarKilled")
util.AddNetworkString("TTT_Promotion")
util.AddNetworkString("TTT_DrunkSober")
util.AddNetworkString("TTT_PhantomHaunt")
util.AddNetworkString("TTT_ParasiteInfect")
util.AddNetworkString("TTT_LogInfo")
util.AddNetworkString("TTT_ResetScoreboard")
util.AddNetworkString("TTT_RevengerLoverKillerRadar")
util.AddNetworkString("TTT_UpdateOldManWins")
util.AddNetworkString("TTT_BuyableWeapons")
util.AddNetworkString("TTT_ResetBuyableWeaponsCache")
util.AddNetworkString("TTT_PlayerFootstep")
util.AddNetworkString("TTT_ClearPlayerFootsteps")
util.AddNetworkString("TTT_JesterDeathCelebration")
util.AddNetworkString("TTT_LoadMonsterEquipment")
util.AddNetworkString("TTT_VampirePrimeDeath")
util.AddNetworkString("TTT_UpdateRoleNames")

local jester_killed = false

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
    GAMEMODE.AwardedKillerCredits = false
    GAMEMODE.AwardedKillerCreditsDead = 0
    GAMEMODE.AwardedVampireCredits = false
    GAMEMODE.AwardedVampireCreditsDead = 0

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

    UpdateRoleStrings()

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
    SetGlobalBool("ttt_all_search_postround", GetConVar("ttt_all_search_postround"):GetBool())

    SetGlobalInt("ttt_shop_random_percent", GetConVar("ttt_shop_random_percent"):GetInt())
    SetGlobalBool("ttt_shop_random_position", GetConVar("ttt_shop_random_position"):GetBool())

    for role = 0, ROLE_MAX do
        local rolestring = ROLE_STRINGS_RAW[role]
        SetGlobalString("ttt_" .. rolestring .. "_name", GetConVar("ttt_" .. rolestring .. "_name"):GetString())
        SetGlobalString("ttt_" .. rolestring .. "_name_plural", GetConVar("ttt_" .. rolestring .. "_name_plural"):GetString())
        SetGlobalString("ttt_" .. rolestring .. "_name_article", GetConVar("ttt_" .. rolestring .. "_name_article"):GetString())
        if SHOP_ROLES[role] then
            SetGlobalInt("ttt_" .. rolestring .. "_shop_random_percent", GetConVar("ttt_" .. rolestring .. "_shop_random_percent"):GetInt())
            SetGlobalBool("ttt_" .. rolestring .. "_shop_random_enabled", GetConVar("ttt_" .. rolestring .. "_shop_random_enabled"):GetBool())

            local sync_cvar = "ttt_" .. rolestring .. "_shop_sync"
            if ConVarExists(sync_cvar) then
                SetGlobalBool(sync_cvar, GetConVar(sync_cvar):GetBool())
            end

            local mode_cvar = "ttt_" .. rolestring .. "_shop_mode"
            if ConVarExists(mode_cvar) then
                SetGlobalInt(mode_cvar, GetConVar(mode_cvar):GetInt())
            end
        end
    end

    SetGlobalBool("ttt_phantom_killer_smoke", GetConVar("ttt_phantom_killer_smoke"):GetBool())
    SetGlobalInt("ttt_phantom_killer_haunt_power_max", GetConVar("ttt_phantom_killer_haunt_power_max"):GetInt())
    SetGlobalInt("ttt_phantom_killer_haunt_move_cost", GetConVar("ttt_phantom_killer_haunt_move_cost"):GetInt())
    SetGlobalInt("ttt_phantom_killer_haunt_attack_cost", GetConVar("ttt_phantom_killer_haunt_attack_cost"):GetInt())
    SetGlobalInt("ttt_phantom_killer_haunt_jump_cost", GetConVar("ttt_phantom_killer_haunt_jump_cost"):GetInt())
    SetGlobalInt("ttt_phantom_killer_haunt_drop_cost", GetConVar("ttt_phantom_killer_haunt_drop_cost"):GetInt())

    SetGlobalBool("ttt_deputy_use_detective_icon", GetConVar("ttt_deputy_use_detective_icon"):GetBool())

    SetGlobalBool("ttt_traitor_vision_enable", GetConVar("ttt_traitor_vision_enable"):GetBool())

    SetGlobalBool("ttt_assassin_show_target_icon", GetConVar("ttt_assassin_show_target_icon"):GetBool())

    SetGlobalBool("ttt_impersonator_use_detective_icon", GetConVar("ttt_impersonator_use_detective_icon"):GetBool())

    SetGlobalBool("ttt_vampires_are_monsters", GetConVar("ttt_vampires_are_monsters"):GetBool())
    SetGlobalBool("ttt_vampire_show_target_icon", GetConVar("ttt_vampire_show_target_icon"):GetBool())
    SetGlobalBool("ttt_vampire_vision_enable", GetConVar("ttt_vampire_vision_enable"):GetBool())

    SetGlobalInt("ttt_parasite_infection_time", GetConVar("ttt_parasite_infection_time"):GetInt())
    SetGlobalBool("ttt_parasite_enabled", GetConVar("ttt_parasite_enabled"):GetBool())

    SetGlobalBool("ttt_killer_show_target_icon", GetConVar("ttt_killer_show_target_icon"):GetBool())
    SetGlobalBool("ttt_killer_vision_enable", GetConVar("ttt_killer_vision_enable"):GetBool())

    SetGlobalBool("ttt_zombies_are_monsters", GetConVar("ttt_zombies_are_monsters"):GetBool())
    SetGlobalBool("ttt_zombies_are_traitors", GetConVar("ttt_zombies_are_traitors"):GetBool())
    SetGlobalBool("ttt_zombie_show_target_icon", GetConVar("ttt_zombie_show_target_icon"):GetBool())
    SetGlobalBool("ttt_zombie_vision_enable", GetConVar("ttt_zombie_vision_enable"):GetBool())
    SetGlobalFloat("ttt_zombie_prime_speed_bonus", GetConVar("ttt_zombie_prime_speed_bonus"):GetFloat())
    SetGlobalFloat("ttt_zombie_thrall_speed_bonus", GetConVar("ttt_zombie_thrall_speed_bonus"):GetFloat())

    SetGlobalInt("ttt_revenger_radar_timer", GetConVar("ttt_revenger_radar_timer"):GetInt())

    SetGlobalBool("ttt_jesters_visible_to_traitors", GetConVar("ttt_jesters_visible_to_traitors"):GetBool())
    SetGlobalBool("ttt_jesters_visible_to_monsters", GetConVar("ttt_jesters_visible_to_monsters"):GetBool())
    SetGlobalBool("ttt_jesters_visible_to_independents", GetConVar("ttt_jesters_visible_to_independents"):GetBool())

    SetGlobalBool("ttt_beggar_reveal_change", GetConVar("ttt_beggar_reveal_change"):GetBool())

    SetGlobalBool("ttt_clown_show_target_icon", GetConVar("ttt_clown_show_target_icon"):GetBool())
    SetGlobalBool("ttt_clown_hide_when_active", GetConVar("ttt_clown_hide_when_active"):GetBool())
    SetGlobalBool("ttt_clown_shop_active_only", GetConVar("ttt_clown_shop_active_only"):GetBool())
    SetGlobalBool("ttt_clown_shop_delay", GetConVar("ttt_clown_shop_delay"):GetBool())

    SetGlobalBool("ttt_bem_allow_change", GetConVar("ttt_bem_allow_change"):GetBool())
    SetGlobalInt("ttt_bem_sv_cols", GetConVar("ttt_bem_sv_cols"):GetBool())
    SetGlobalInt("ttt_bem_sv_rows", GetConVar("ttt_bem_sv_rows"):GetBool())
    SetGlobalInt("ttt_bem_sv_size", GetConVar("ttt_bem_sv_size"):GetBool())

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

local function GetPlayerName(ply)
    local name = ply:GetNWString("PlayerName", nil)
    if name == nil then
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
                if ply.has_spawned and ply.spawn_nick ~= GetPlayerName(ply) and not hook.Call("TTTNameChangeKick", GAMEMODE, ply) then
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
    for _, ply in pairs(player.GetAll()) do
        ply.spawn_nick = GetPlayerName(ply)
    end

    if not timer.Exists("namecheck") then
        timer.Create("namecheck", 3, 0, NameChangeKick)
    end
end

local function OnPlayerDeath(victim, infl, attacker)
    if victim:IsJester() and attacker:IsPlayer() and (not attacker:IsJesterTeam()) and GetRoundState() == ROUND_ACTIVE then
        -- Don't track that the jester was killed (for win reporting) if they were killed by a traitor
        -- and the functionality that blocks Jester wins from Traitor deaths is enabled
        if GetConVar("ttt_jester_win_by_traitors"):GetBool() or not attacker:IsTraitorTeam() then
            jester_killed = true
        end
    else
        local vamp_prime_death_mode = GetConVar("ttt_vampire_prime_death_mode"):GetFloat()
        -- If the prime died and we're doing something when that happens
        if victim:IsVampirePrime() and vamp_prime_death_mode > VAMPIRE_DEATH_NONE then
            local living_vampire_primes = 0
            local vampires = {}
            -- Find all the living vampires anmd count the primes
            for _, v in pairs(player.GetAll()) do
                if v:Alive() and v:IsTerror() and v:IsVampire() then
                    if v:IsVampirePrime() then
                        living_vampire_primes = living_vampire_primes + 1
                    end
                    table.insert(vampires, v)
                end
            end

            -- If there are no more living primes, do something with the non-primes
            if living_vampire_primes == 0 and #vampires > 0 then
                net.Start("TTT_VampirePrimeDeath")
                net.WriteUInt(vamp_prime_death_mode, 4)
                net.WriteString(victim:Nick())
                net.Broadcast()

                -- Kill them
                if vamp_prime_death_mode == VAMPIRE_DEATH_KILL_CONVERED then
                    for _, vnp in pairs(vampires) do
                        vnp:PrintMessage(HUD_PRINTTALK, "Your " .. ROLE_STRINGS[ROLE_VAMPIRE] .. " overlord has been slain and you die with them")
                        vnp:PrintMessage(HUD_PRINTCENTER, "Your " .. ROLE_STRINGS[ROLE_VAMPIRE] .. " overlord has been slain and you die with them")
                        vnp:Kill()
                    end
                -- Change them back to their previous roles
                elseif vamp_prime_death_mode == VAMPIRE_DEATH_REVERT_CONVERTED then
                    local converted = false
                    for _, vnp in pairs(vampires) do
                        local prev_role = vnp:GetVampirePreviousRole()
                        if prev_role ~= ROLE_NONE then
                            vnp:PrintMessage(HUD_PRINTTALK, "Your " .. ROLE_STRINGS[ROLE_VAMPIRE] .. " overlord has been slain and you feel their grip over you subside")
                            vnp:PrintMessage(HUD_PRINTCENTER, "Your " .. ROLE_STRINGS[ROLE_VAMPIRE] .. " overlord has been slain and you feel their grip over you subside")
                            vnp:SetRoleAndBroadcast(prev_role)
                            vnp:StripWeapon("weapon_vam_fangs")
                            vnp:SelectWeapon("weapon_zm_improvised")
                            converted = true
                        end
                    end

                    -- Tell everyone if a role was updated
                    if converted then
                        SendFullStateUpdate()
                    end
                end
            end
        end
    end
end

function StartWinChecks()
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
        v:SetNWBool("Haunted", false)
        v:SetNWBool("Haunting", false)
        v:SetNWString("HauntingTarget", nil)
        v:SetNWInt("HauntingPower", 0)
        timer.Remove(v:Nick() .. "HauntingPower")
        timer.Remove(v:Nick() .. "HauntingSpectate")
        v:SetNWString("RevengerLover", "")
        v:SetNWString("RevengerKiller", "")
        v:SetNWString("JesterKiller", "")
        v:SetNWString("SwappedWith", "")
        v:SetNWString("AssassinTarget", "")
        v:SetNWBool("AssassinFailed", false)
        timer.Remove(v:Nick() .. "AssassinTarget")
        v:SetNWBool("WasDrunk", false)
        v:SetNWBool("WasHypnotised", false)
        v:SetNWBool("KillerClownActive", false)
        v:SetNWBool("KillerSmoke", false)
        v:SetNWBool("HasPromotion", false)
        v:SetNWBool("WasBeggar", false)
        timer.Remove(v:Nick() .. "BeggarRespawn")
        v:SetNWBool("VeteranActive", false)
        v:SetNWBool("IsZombifying", false)
        v:SetNWBool("Infected", false)
        v:SetNWBool("Infecting", false)
        v:SetNWString("InfectingTarget", nil)
        v:SetNWInt("InfectionProgress", 0)
        timer.Remove(v:Nick() .. "InfectionProgress")
        timer.Remove(v:Nick() .. "InfectingSpectate")
        -- Keep previous naming scheme for backwards compatibility
        v:SetNWBool("zombie_prime", false)
        v:SetNWBool("vampire_prime", false)
        v:SetNWInt("vampire_previous_role", ROLE_NONE)
        -- Workaround to prevent GMod sprint from working
        v:SetRunSpeed(v:GetWalkSpeed())
    end

    net.Start("TTT_UpdateOldManWins")
    net.WriteBool(false)
    net.Broadcast()

    net.Start("TTT_RevengerLoverKillerRadar")
    net.WriteBool(false)
    net.Broadcast()

    jester_killed = false

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
    GAMEMODE.AwardedKillerCredits = false
    GAMEMODE.AwardedKillerCreditsDead = 0
    GAMEMODE.AwardedVampireCredits = false
    GAMEMODE.AwardedVampireCreditsDead = 0

    SCORE:Reset()

    -- Update damage scaling
    KARMA.RoundBegin()

    WEPS.ResetWeaponsCache()
    WEPS.ResetRoleWeaponCache()

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
    local plys = player.GetAll()

    local traitornicks = {}
    local hasGlitch = false
    local hasKiller = false
    for _, v in ipairs(plys) do
        if v:IsTraitorTeam() then
            table.insert(traitornicks, v:Nick())
        elseif v:IsGlitch() then
            table.insert(traitornicks, v:Nick())
            hasGlitch = true
        elseif v:IsKiller() then
            hasKiller = true
        end
    end

    -- This is ugly as hell, but it's kinda nice to filter out the names of the
    -- traitors themselves in the messages to them
    for _, v in ipairs(plys) do
        local isTraitor = v:IsTraitorTeam()
        if isTraitor then
            if hasGlitch then
                v:PrintMessage(HUD_PRINTTALK, "There is " .. ROLE_STRINGS_EXT[ROLE_GLITCH] .. ".")
                v:PrintMessage(HUD_PRINTCENTER, "There is " .. ROLE_STRINGS_EXT[ROLE_GLITCH] .. ".")
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
                names = string.sub(names, 1, -3)
                LANG.Msg(v, "round_traitors_more", { role = ROLE_STRINGS[ROLE_TRAITOR], names = names })
            end
        end

        -- Warn this player about the Killer if they are a traitor or we are configured to warn everyone
        if not v:IsKiller() and (isTraitor or GetConVar("ttt_killer_warn_all"):GetBool()) and hasKiller then
            v:PrintMessage(HUD_PRINTTALK, "There is " .. ROLE_STRINGS_EXT[ROLE_KILLER] .. ".")
            -- Only delay this if the player is a traitor and there is a Glitch
            -- This gives time for the Glitch warning to go away
            if isTraitor and hasGlitch then
                timer.Simple(3, function()
                    v:PrintMessage(HUD_PRINTCENTER, "There is " .. ROLE_STRINGS_EXT[ROLE_KILLER] .. ".")
                end)
            else
                v:PrintMessage(HUD_PRINTCENTER, "There is " .. ROLE_STRINGS_EXT[ROLE_KILLER] .. ".")
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

local function DrunkSober(ply, traitor)
    local role
    if traitor then
        role = ROLE_TRAITOR
        ply:SetCredits(GetConVar("ttt_credits_starting"):GetInt())
    else
        role = ROLE_INNOCENT
    end

    ply:SetNWBool("WasDrunk", true)
    ply:SetRole(role)
    ply:PrintMessage(HUD_PRINTTALK, "You have remembered that you are " .. ROLE_STRINGS_EXT[role] .. ".")
    ply:PrintMessage(HUD_PRINTCENTER, "You have remembered that you are " .. ROLE_STRINGS_EXT[role] .. ".")

    net.Start("TTT_DrunkSober")
    net.WriteString(ply:Nick())
    net.WriteString(ROLE_STRINGS_EXT[role])
    net.Broadcast()

    SendFullStateUpdate()
end

function BeginRound()
    GAMEMODE:SyncGlobals()

    if CheckForAbort() then return end

    HandleRoleEquipment()
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

    for _, v in pairs(player.GetAll()) do
        local role = v:GetRole()

        -- Revenger logic
        if role == ROLE_REVENGER then
            local potentialSoulmates = {}
            for _, p in pairs(player.GetAll()) do
                if p:Alive() and not p:IsSpec() and p ~= v then
                    table.insert(potentialSoulmates, p)
                end
            end
            if #potentialSoulmates > 0 then
                local revenger_lover = potentialSoulmates[math.random(#potentialSoulmates)]
                v:SetNWString("RevengerLover", revenger_lover:SteamID64() or "")
                v:PrintMessage(HUD_PRINTTALK, "You are in love with " .. revenger_lover:Nick() .. ".")
                v:PrintMessage(HUD_PRINTCENTER, "You are in love with " .. revenger_lover:Nick() .. ".")
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
        SetGlobalFloat("ttt_drunk_remember", CurTime() + GetConVar("ttt_drunk_sober_time"):GetInt())
        if role == ROLE_DRUNK then
            timer.Create("drunkremember", GetConVar("ttt_drunk_sober_time"):GetInt(), 1, function()
                for _, p in pairs(player.GetAll()) do
                    if p:IsActiveDrunk() then
                        if math.random() <= GetConVar("ttt_drunk_innocent_chance"):GetFloat() then
                            DrunkSober(p, false)
                        else
                            DrunkSober(p, true)
                        end
                    elseif p:IsDrunk() and not p:Alive() and not timer.Exists("waitfordrunkrespawn") then
                        timer.Create("waitfordrunkrespawn", 0.1, 0, function()
                            local dead_drunk = false
                            for _, p2 in pairs(player.GetAll()) do
                                if p2:IsActiveDrunk() then
                                    if math.random() <= GetConVar("ttt_drunk_innocent_chance"):GetFloat() then
                                        DrunkSober(p2, false)
                                    else
                                        DrunkSober(p2, true)
                                    end
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
        if role == ROLE_OLDMAN and oldman_drain_health > 0 then
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
        if role == ROLE_ASSASSIN then
            AssignAssassinTarget(v, true, false)
        end

        -- Killer logic
        if role == ROLE_KILLER then
            if GetConVar("ttt_killer_knife_enabled"):GetBool() then
                v:Give("weapon_kil_knife")
            end
            if GetConVar("ttt_killer_crowbar_enabled"):GetBool() then
                v:StripWeapon("weapon_zm_improvised")
                v:Give("weapon_kil_crowbar")
                v:SelectWeapon("weapon_kil_crowbar")
            end
        end

        -- Doctor Logic
        if role == ROLE_DOCTOR then
            local mode = GetConVar("ttt_doctor_mode"):GetInt()
            if mode == DOCTOR_MODE_STATION then
                v:Give("weapon_ttt_health_station")
            elseif mode == DOCTOR_MODE_EMT then
                v:Give("weapon_doc_defib")
            end
        end

        SetRoleHealth(v)
    end

    net.Start("TTT_ResetScoreboard")
    net.Broadcast()

    for _, v in pairs(player.GetAll()) do
        if v:Alive() and v:IsTerror() then
            net.Start("TTT_SpawnedPlayers")
            net.WriteString(v:Nick())
            net.WriteUInt(v:GetRole(), 8)
            net.Broadcast()
        end
    end

    -- Give the StateUpdate messages ample time to arrive
    timer.Simple(1.5, TellTraitorsAboutTraitors)
    timer.Simple(2.5, ShowRoundStartPopup)

    -- EQUIP_REGEN health regeneration tick
    timer.Create("RegenEquipmentTick", 0.66, 0, function()
        for _, v in pairs(player.GetAll()) do
            if v:Alive() and not v:IsSpec() and v:HasEquipmentItem(EQUIP_REGEN) then
                local hp = v:Health()
                if hp < v:GetMaxHealth() then
                    v:SetHealth(hp + 1)
                end
            end
        end
    end)

    -- Start watching for specific deaths
    hook.Add("PlayerDeath", "OnPlayerDeath", OnPlayerDeath)

    -- Start the win condition check timer
    StartWinChecks()
    StartNameChangeChecks()
    timer.Create("selectmute", 1, 1, function() MuteForRestart(false) end)

    GAMEMODE.DamageLog = {}
    GAMEMODE.RoundStartTime = CurTime()

    local zombies_are_monsters = MONSTER_ROLES[ROLE_ZOMBIE]
    local vampires_are_monsters = MONSTER_ROLES[ROLE_VAMPIRE]
    LoadMonsterEquipment(zombies_are_monsters, vampires_are_monsters)
    -- Send the status to the client because at this point the globals haven't synced
    net.Start("TTT_LoadMonsterEquipment")
    net.WriteBool(zombies_are_monsters)
    net.WriteBool(vampires_are_monsters)
    net.Broadcast()

    -- Sound start alarm
    SetRoundState(ROUND_ACTIVE)
    LANG.Msg("round_started")
    ServerLog("Round proper has begun...\n")
    ClearAllFootsteps()
    GAMEMODE:UpdatePlayerLoadouts() -- needs to happen when round_active

    hook.Call("TTTBeginRound")

    ents.TTT.TriggerRoundStateOutputs(ROUND_BEGIN)
end

function PrintResultMessage(type)
    ServerLog("Round ended.\n")
    if type == WIN_TIMELIMIT then
        LANG.Msg("win_time", { role = ROLE_STRINGS_PLURAL[ROLE_INNOCENT] })
        ServerLog("Result: timelimit reached, " .. ROLE_STRINGS_PLURAL[ROLE_TRAITOR] .. " lose.\n")
    elseif type == WIN_TRAITOR then
        LANG.Msg("win_traitor", { role = ROLE_STRINGS_PLURAL[ROLE_TRAITOR] })
        ServerLog("Result: " .. ROLE_STRINGS_PLURAL[ROLE_TRAITOR] .. " win.\n")
    elseif type == WIN_INNOCENT then
        LANG.Msg("win_innocent", { role = ROLE_STRINGS_PLURAL[ROLE_INNOCENT] })
        ServerLog("Result: " .. ROLE_STRINGS_PLURAL[ROLE_INNOCENT] .. " win.\n")
    elseif type == WIN_JESTER then
        LANG.Msg("win_jester", { role = ROLE_STRINGS_PLURAL[ROLE_JESTER] })
        ServerLog("Result: " .. ROLE_STRINGS[ROLE_JESTER] .. " wins.\n")
    elseif type == WIN_CLOWN then
        LANG.Msg("win_clown", { role = ROLE_STRINGS_PLURAL[ROLE_CLOWN] })
        ServerLog("Result: " .. ROLE_STRINGS[ROLE_CLOWN] .. " wins.\n")
    elseif type == WIN_KILLER then
        LANG.Msg("win_killer", { role = ROLE_STRINGS_PLURAL[ROLE_KILLER] })
        ServerLog("Result: " .. ROLE_STRINGS[ROLE_KILLER] .. " wins.\n")
    elseif type == WIN_MONSTER then
        -- If Zombies are not monsters then Vampires win
        if not MONSTER_ROLES[ROLE_ZOMBIE] then
            LANG.Msg("win_vampires", { role = ROLE_STRINGS_PLURAL[ROLE_VAMPIRE] })
            ServerLog("Result: " .. ROLE_STRINGS_PLURAL[ROLE_VAMPIRE] .. " win.\n")
        -- And vice versa
        elseif not MONSTER_ROLES[ROLE_VAMPIRE] then
            LANG.Msg("win_zombies", { role = ROLE_STRINGS_PLURAL[ROLE_ZOMBIE] })
            ServerLog("Result: " .. ROLE_STRINGS_PLURAL[ROLE_ZOMBIE] .. " win.\n")
        -- Otherwise the monsters legit win
        else
            LANG.Msg("win_monster")
            ServerLog("Result: Monsters win.\n")
        end
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

    if timer.Exists("revengerloverkiller") then timer.Remove("revengerloverkiller") end
    if timer.Exists("drunkremember") then timer.Remove("drunkremember") end
    if timer.Exists("waitfordrunkrespawn") then timer.Remove("waitfordrunkrespawn") end
    if timer.Exists("oldmanhealthdrain") then timer.Remove("oldmanhealthdrain") end
    if timer.Exists("revengerhealthdrain") then timer.Remove("revengerhealthdrain") end

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

local function CheckForOldManWin(win_type)
    if win_type ~= WIN_NONE then
        net.Start("TTT_UpdateOldManWins")
        net.WriteBool(true)
        net.Broadcast()
    end
end

-- The most basic win check is whether both sides have one dude alive
function GM:TTTCheckForWin()
    if ttt_dbgwin:GetBool() then return WIN_NONE end

    local traitor_alive = false
    local innocent_alive = false
    local drunk_alive = false
    local clown_alive = false
    local oldman_alive = false
    local killer_alive = false
    local zombie_alive = false
    local monster_alive = false

    local killer_clown_active = false

    for _, v in ipairs(player.GetAll()) do
        local zombifying = v:GetNWBool("IsZombifying", false)
        if (v:Alive() and v:IsTerror()) or zombifying then
            if v:IsTraitorTeam() or (TRAITOR_ROLES[ROLE_ZOMBIE] and zombifying) then
                traitor_alive = true
            elseif v:IsMonsterTeam() or (MONSTER_ROLES[ROLE_ZOMBIE] and zombifying) then
                monster_alive = true
            elseif v:IsDrunk() then
                drunk_alive = true
            elseif v:IsClown() then
                clown_alive = true
                killer_clown_active = v:GetNWBool("KillerClownActive", false)
            elseif v:IsOldMan() then
                oldman_alive = true
            elseif v:IsInnocentTeam() then
                innocent_alive = true
            elseif v:IsKiller() then
                killer_alive = true
            elseif (v:IsZombie() or zombifying) and INDEPENDENT_ROLES[ROLE_ZOMBIE] then
                zombie_alive = true
            end
        end
    end

    if GAMEMODE.MapWin ~= WIN_NONE then
        local mw = GAMEMODE.MapWin
        GAMEMODE.MapWin = WIN_NONE

        -- Old Man logic for map win
        if oldman_alive then
            CheckForOldManWin(mw)
        end

        return mw
    end

    if traitor_alive and innocent_alive and not jester_killed then
        return WIN_NONE --early out
    end

    local win_type = WIN_NONE

    if jester_killed then
        win_type = WIN_JESTER
    -- If everyone is dead the traitors win
    elseif not innocent_alive and not monster_alive and not killer_alive and not zombie_alive then
        win_type = WIN_TRAITOR
    -- If all the "bad" people are dead, innocents win
    elseif not traitor_alive and not monster_alive and not killer_alive and not zombie_alive then
        win_type = WIN_INNOCENT
    -- If the monsters are the only ones left, they win
    elseif  not innocent_alive and not traitor_alive and not killer_alive and not zombie_alive then
        win_type = WIN_MONSTER
    -- If the killer is the only one left alive, they win
    elseif not traitor_alive and not innocent_alive and not monster_alive and not zombie_alive and killer_alive then
        win_type = WIN_KILLER
    -- If the zombies are the only ones left, they win
    elseif not traitor_alive and not innocent_alive and not monster_alive and not killer_alive and zombie_alive then
        win_type = WIN_ZOMBIE
    end

    -- Drunk logic
    if drunk_alive then
        if not traitor_alive then
            if timer.Exists("drunkremember") then timer.Remove("drunkremember") end
            if timer.Exists("waitfordrunkrespawn") then timer.Remove("waitfordrunkrespawn") end
            for _, v in ipairs(player.GetAll()) do
                if v:Alive() and v:IsTerror() and v:IsDrunk() then
                    DrunkSober(v, true)
                end
            end
            win_type = WIN_NONE
        elseif not innocent_alive then
            if timer.Exists("drunkremember") then timer.Remove("drunkremember") end
            if timer.Exists("waitfordrunkrespawn") then timer.Remove("waitfordrunkrespawn") end
            for _, v in ipairs(player.GetAll()) do
                if v:Alive() and v:IsTerror() and v:IsDrunk() then
                    DrunkSober(v, false)
                end
            end
            win_type = WIN_NONE
        end
    end

    -- Clown logic
    if clown_alive then
        if not killer_clown_active and (win_type == WIN_INNOCENT or win_type == WIN_TRAITOR or win_type == WIN_MONSTER or win_type == WIN_KILLER or win_type == WIN_ZOMBIE) then
            for _, v in ipairs(player.GetAll()) do
                if v:IsClown() then
                    v:SetNWBool("KillerClownActive", true)
                    v:PrintMessage(HUD_PRINTTALK, "KILL THEM ALL!")
                    v:PrintMessage(HUD_PRINTCENTER, "KILL THEM ALL!")
                    v:AddCredits(GetConVar("ttt_clown_activation_credits"):GetInt())
                    if GetConVar("ttt_clown_heal_on_activate"):GetBool() then
                        v:SetHealth(v:GetMaxHealth())
                    end
                    net.Start("TTT_ClownActivate")
                    net.WriteEntity(v)
                    net.Broadcast()

                    -- Give the clown their shop items if purchase was delayed
                    if v.bought and GetConVar("ttt_clown_shop_delay"):GetBool() then
                        for _, item_id in ipairs(v.bought) do
                            local id_num = tonumber(item_id)
                            local isequip = id_num and 1 or 0

                            -- Give the item to the player
                            if id_num then
                                v:GiveEquipmentItem(id_num)
                            else
                                v:Give(item_id)
                                local wep = weapons.GetStored(item_id)
                                if wep and wep.WasBought then
                                    wep:WasBought(v)
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
                            net.Send(v)
                        end
                    end
                end
            end
            win_type = WIN_NONE
        elseif killer_clown_active and not traitor_alive and not innocent_alive and not killer_alive and not monster_alive then
            win_type = WIN_CLOWN
        else
            win_type = WIN_NONE
        end
    end

    -- Old Man logic
    if oldman_alive then
        CheckForOldManWin(win_type)
    end

    return win_type
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

local function GetMonsterCount(ply_count)
    if not MONSTER_ROLES[ROLE_ZOMBIE] and not MONSTER_ROLES[ROLE_VAMPIRE] then
        return 0
    end
    return math.ceil(ply_count * math.Round(GetConVar("ttt_monster_pct"):GetFloat(), 3))
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

    local plys = player.GetAll()

    for _, v in ipairs(plys) do
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

    local choice_count = #choices

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

    local doctor_only = false
    local quack_only = false
    if GetConVar("ttt_single_doctor_quack"):GetBool() then
        if math.random() <= 0.5 then
            doctor_only = true
        else
            quack_only = true
        end
    end

    if choice_count == 0 then return end

    local choices_copy = table.Copy(choices)
    local prev_roles_copy = table.Copy(prev_roles)

    hook.Call("TTTSelectRoles", GAMEMODE, choices_copy, prev_roles_copy)

    local forcedTraitorCount = 0
    local forcedSpecialTraitorCount = 0
    local forcedDetectiveCount = 0
    local forcedSpecialInnocentCount = 0
    local forcedIndependentCount = 0
    local forcedMonsterCount = 0

    local hasHypnotist = false
    local hasImpersonator = false
    local hasAssassin = false
    local hasVampire = false
    local hasZombie = false
    local hasQuack = false
    local hasParasite = false

    local hasPhantom = false
    local hasGlitch = false
    local hasRevenger = false
    local hasDeputy = false
    local hasMercenary = false
    local hasVeteran = false
    local hasDoctor = false
    local hasTrickster = false

    local hasIndependent = false

    PrintRoleText("-----CHECKING EXTERNALLY CHOSEN ROLES-----")
    for _, v in pairs(player.GetAll()) do
        if IsValid(v) and (not v:IsSpec()) then
            local role = v:GetRole()
            if role > ROLE_NONE and role <= ROLE_MAX then
                local index = 0
                for i, j in pairs(choices) do
                    if v == j then
                        index = i
                    end
                end

                table.remove(choices, index)
                -- TRAITOR ROLES
                if role == ROLE_TRAITOR then
                    forcedTraitorCount = forcedTraitorCount + 1
                elseif role == ROLE_HYPNOTIST then
                    hasHypnotist = true
                    forcedSpecialTraitorCount = forcedSpecialTraitorCount + 1
                elseif role == ROLE_IMPERSONATOR then
                    hasImpersonator = true
                    if GetConVar("ttt_single_deputy_impersonator"):GetBool() then
                        impersonator_only = true
                    end
                    forcedSpecialTraitorCount = forcedSpecialTraitorCount + 1
                elseif role == ROLE_ASSASSIN then
                    hasAssassin = true
                    forcedSpecialTraitorCount = forcedSpecialTraitorCount + 1
                elseif role == ROLE_VAMPIRE then
                    hasVampire = true
                    if TRAITOR_ROLES[role] then
                        forcedSpecialTraitorCount = forcedSpecialTraitorCount + 1
                    else
                        forcedMonsterCount = forcedMonsterCount + 1
                    end
                elseif role == ROLE_QUACK then
                    hasQuack = true
                    if GetConVar("ttt_single_doctor_quack"):GetBool() then
                        quack_only = true
                    end
                    forcedSpecialTraitorCount = forcedSpecialTraitorCount + 1
                elseif role == ROLE_PARASITE then
                    hasParasite = true
                    forcedSpecialTraitorCount = forcedSpecialTraitorCount + 1

                -- INNOCENT ROLES
                elseif role == ROLE_DETECTIVE then
                    forcedDetectiveCount = forcedDetectiveCount + 1
                elseif role == ROLE_PHANTOM then
                    hasPhantom = true
                    forcedSpecialInnocentCount = forcedSpecialInnocentCount + 1
                elseif role == ROLE_GLITCH then
                    hasGlitch = true
                    forcedSpecialInnocentCount = forcedSpecialInnocentCount + 1
                elseif role == ROLE_REVENGER then
                    hasRevenger = true
                    forcedSpecialInnocentCount = forcedSpecialInnocentCount + 1
                elseif role == ROLE_DEPUTY then
                    hasDeputy = true
                    if GetConVar("ttt_single_deputy_impersonator"):GetBool() then
                        deputy_only = true
                    end
                    forcedSpecialInnocentCount = forcedSpecialInnocentCount + 1
                elseif role == ROLE_MERCENARY then
                    hasMercenary = true
                    forcedSpecialInnocentCount = forcedSpecialInnocentCount + 1
                elseif role == ROLE_VETERAN then
                    hasVeteran = true
                    forcedSpecialInnocentCount = forcedSpecialInnocentCount + 1
                elseif role == ROLE_DOCTOR then
                    hasDoctor = true
                    if GetConVar("ttt_single_doctor_quack"):GetBool() then
                        doctor_only = true
                    end
                    forcedSpecialInnocentCount = forcedSpecialInnocentCount + 1
                elseif role == ROLE_TRICKSTER then
                    hasTrickster = true
                    forcedSpecialInnocentCount = forcedSpecialInnocentCount + 1

                -- JESTER/INDEPENDENT ROLES
                elseif role == ROLE_JESTER then
                    hasIndependent = true
                    forcedIndependentCount = forcedIndependentCount + 1
                elseif role == ROLE_SWAPPER then
                    hasIndependent = true
                    forcedIndependentCount = forcedIndependentCount + 1
                elseif role == ROLE_DRUNK then
                    hasIndependent = true
                    forcedIndependentCount = forcedIndependentCount + 1
                elseif role == ROLE_CLOWN then
                    hasIndependent = true
                    forcedIndependentCount = forcedIndependentCount + 1
                elseif role == ROLE_BEGGAR then
                    hasIndependent = true
                    forcedIndependentCount = forcedIndependentCount + 1
                elseif role == ROLE_OLDMAN then
                    hasIndependent = true
                    forcedIndependentCount = forcedIndependentCount + 1
                elseif role == ROLE_BODYSNATCHER then
                    hasIndependent = true
                    forcedIndependentCount = forcedIndependentCount + 1
                elseif role == ROLE_KILLER then
                    hasIndependent = true
                    forcedIndependentCount = forcedIndependentCount + 1
                elseif role == ROLE_ZOMBIE then
                    hasZombie = true
                    if INDEPENDENT_ROLES[role] then
                        hasIndependent = true
                        forcedIndependentCount = forcedIndependentCount + 1
                    elseif TRAITOR_ROLES[role] then
                        forcedSpecialTraitorCount = forcedSpecialTraitorCount + 1
                    else
                        forcedMonsterCount = forcedMonsterCount + 1
                    end
                end

                PrintRole(v, role)
            end
        end
    end

    PrintRoleText("-----RANDOMLY PICKING REMAINING ROLES-----")

    -- determine how many of each role we want
    local detective_count = GetDetectiveCount(choice_count) - forcedDetectiveCount
    local traitor_count = GetTraitorCount(choice_count) - forcedTraitorCount - forcedSpecialTraitorCount
    local max_special_traitor_count = GetSpecialTraitorCount(traitor_count) - forcedSpecialTraitorCount
    local independent_count = ((math.random() <= GetConVar("ttt_independent_chance"):GetFloat()) and 1 or 0) - forcedIndependentCount
    local monster_count = GetMonsterCount(choice_count) - forcedMonsterCount

    -- pick detectives
    if choice_count >= GetConVar("ttt_detective_min_players"):GetInt() then
        local min_karma = GetConVar("ttt_detective_karma_min"):GetInt()
        local options = {}
        local secondary_options = {}
        local tertiary_options = {}
        for _, p in ipairs(choices) do
            if not KARMA.IsEnabled() or p:GetBaseKarma() >= min_karma then
                if not p:GetAvoidDetective() then
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
                local ply = options[plyPick]
                ply:SetRole(ROLE_DETECTIVE)
                PrintRole(ply, ROLE_DETECTIVE)
                table.RemoveByValue(choices, ply)
                table.remove(options, plyPick)
            end
        end
    end

    -- pick traitors
    local traitors = {}
    for _ = 1, traitor_count do
        if #choices > 0 then
            local plyPick = math.random(1, #choices)
            local ply = choices[plyPick]
            table.insert(traitors, ply)
            table.remove(choices, plyPick)
        end
    end

    if ((GetConVar("ttt_zombie_enabled"):GetBool() and math.random() <= GetConVar("ttt_zombie_round_chance"):GetFloat() and (forcedTraitorCount <= 0) and (forcedSpecialTraitorCount <= 0)) or hasZombie) and TRAITOR_ROLES[ROLE_ZOMBIE] then
        -- This is a zombie round so all traitors become zombies
        for _, v in pairs(traitors) do
            v:SetRole(ROLE_ZOMBIE)
            PrintRole(v, ROLE_ZOMBIE)
        end
    else
        -- pick special traitors
        if max_special_traitor_count > 0 then
            local specialTraitorRoles = {}
            if not hasHypnotist and GetConVar("ttt_hypnotist_enabled"):GetBool() and choice_count >= GetConVar("ttt_hypnotist_min_players"):GetInt() then
                for _ = 1, GetConVar("ttt_hypnotist_spawn_weight"):GetInt() do
                    table.insert(specialTraitorRoles, ROLE_HYPNOTIST)
                end
            end
            if not hasImpersonator and GetConVar("ttt_impersonator_enabled"):GetBool() and choice_count >= GetConVar("ttt_impersonator_min_players"):GetInt() and detective_count > 0 and not deputy_only then
                for _ = 1, GetConVar("ttt_impersonator_spawn_weight"):GetInt() do
                    table.insert(specialTraitorRoles, ROLE_IMPERSONATOR)
                end
            end
            if not hasAssassin and GetConVar("ttt_assassin_enabled"):GetBool() and choice_count >= GetConVar("ttt_assassin_min_players"):GetInt() then
                for _ = 1, GetConVar("ttt_assassin_spawn_weight"):GetInt() do
                    table.insert(specialTraitorRoles, ROLE_ASSASSIN)
                end
            end
            if not hasVampire and GetConVar("ttt_vampire_enabled"):GetBool() and choice_count >= GetConVar("ttt_vampire_min_players"):GetInt() and TRAITOR_ROLES[ROLE_VAMPIRE] then
                for _ = 1, GetConVar("ttt_vampire_spawn_weight"):GetInt() do
                    table.insert(specialTraitorRoles, ROLE_VAMPIRE)
                end
            end
            if not hasQuack and GetConVar("ttt_quack_enabled"):GetBool() and choice_count >= GetConVar("ttt_quack_min_players"):GetInt() and not doctor_only then
                for _ = 1, GetConVar("ttt_quack_spawn_weight"):GetInt() do
                    table.insert(specialTraitorRoles, ROLE_QUACK)
                end
            end
            if not hasParasite and GetConVar("ttt_parasite_enabled"):GetBool() and choice_count >= GetConVar("ttt_parasite_min_players"):GetInt() then
                for _ = 1, GetConVar("ttt_parasite_spawn_weight"):GetInt() do
                    table.insert(specialTraitorRoles, ROLE_PARASITE)
                end
            end
            for _ = 1, max_special_traitor_count do
                if #specialTraitorRoles ~= 0 and math.random() <= GetConVar("ttt_special_traitor_chance"):GetFloat() and #traitors > 0 then
                    local plyPick = math.random(1, #traitors)
                    local ply = traitors[plyPick]
                    local rolePick = math.random(1, #specialTraitorRoles)
                    local role = specialTraitorRoles[rolePick]
                    ply:SetRole(role)
                    PrintRole(ply, role)
                    table.remove(traitors, plyPick)
                    for i = #specialTraitorRoles, 1, -1 do
                        if specialTraitorRoles[i] == role then
                            table.remove(specialTraitorRoles, i)
                        end
                    end
                end
            end
        end

        -- Any of these left is a vanilla traitor
        for _, v in pairs(traitors) do
            v:SetRole(ROLE_TRAITOR)
            PrintRole(v, ROLE_TRAITOR)
        end
    end

    -- pick independent
    if not hasIndependent and independent_count > 0 and #choices > 0 then
        local independentRoles = {}
        if GetConVar("ttt_jester_enabled"):GetBool() and choice_count >= GetConVar("ttt_jester_min_players"):GetInt() then
            for _ = 1, GetConVar("ttt_jester_spawn_weight"):GetInt() do
                table.insert(independentRoles, ROLE_JESTER)
            end
        end
        if GetConVar("ttt_swapper_enabled"):GetBool() and choice_count >= GetConVar("ttt_swapper_min_players"):GetInt() then
            for _ = 1, GetConVar("ttt_swapper_spawn_weight"):GetInt() do
                table.insert(independentRoles, ROLE_SWAPPER)
            end
        end
        if GetConVar("ttt_drunk_enabled"):GetBool() and choice_count >= GetConVar("ttt_drunk_min_players"):GetInt() then
            for _ = 1, GetConVar("ttt_drunk_spawn_weight"):GetInt() do
                table.insert(independentRoles, ROLE_DRUNK)
            end
        end
        if GetConVar("ttt_clown_enabled"):GetBool() and choice_count >= GetConVar("ttt_clown_min_players"):GetInt() then
            for _ = 1, GetConVar("ttt_clown_spawn_weight"):GetInt() do
                table.insert(independentRoles, ROLE_CLOWN)
            end
        end
        if GetConVar("ttt_beggar_enabled"):GetBool() and choice_count >= GetConVar("ttt_beggar_min_players"):GetInt() then
            for _ = 1, GetConVar("ttt_beggar_spawn_weight"):GetInt() do
                table.insert(independentRoles, ROLE_BEGGAR)
            end
        end
        if GetConVar("ttt_oldman_enabled"):GetBool() and choice_count >= GetConVar("ttt_oldman_min_players"):GetInt() then
            for _ = 1, GetConVar("ttt_oldman_spawn_weight"):GetInt() do
                table.insert(independentRoles, ROLE_OLDMAN)
            end
        end
        if GetConVar("ttt_bodysnatcher_enabled"):GetBool() and choice_count >= GetConVar("ttt_bodysnatcher_min_players"):GetInt() then
            for _ = 1, GetConVar("ttt_bodysnatcher_spawn_weight"):GetInt() do
                table.insert(independentRoles, ROLE_BODYSNATCHER)
            end
        end
        if GetConVar("ttt_killer_enabled"):GetBool() and choice_count >= GetConVar("ttt_killer_min_players"):GetInt() then
            for _ = 1, GetConVar("ttt_killer_spawn_weight"):GetInt() do
                table.insert(independentRoles, ROLE_KILLER)
            end
        end
        if GetConVar("ttt_zombie_enabled"):GetBool() and choice_count >= GetConVar("ttt_zombie_min_players"):GetInt() and INDEPENDENT_ROLES[ROLE_ZOMBIE] then
            for _ = 1, GetConVar("ttt_zombie_spawn_weight"):GetInt() do
                table.insert(independentRoles, ROLE_ZOMBIE)
            end
        end
        if #independentRoles ~= 0 then
            local plyPick = math.random(1, #choices)
            local ply = choices[plyPick]
            local rolePick = math.random(1, #independentRoles)
            local role = independentRoles[rolePick]
            ply:SetRole(role)
            PrintRole(ply, role)
            table.remove(choices, plyPick)
            for i = #independentRoles, 1, -1 do
                if independentRoles[i] == role then
                    table.remove(independentRoles, i)
                end
            end
        end
    end

    -- pick special innocents
    local max_special_innocent_count = GetSpecialInnocentCount(#choices) - forcedSpecialInnocentCount
    if max_special_innocent_count > 0 then
        local map_has_traitor_buttons = #ents.FindByClass("ttt_traitor_button") > 0
        local specialInnocentRoles = {}
        if not hasGlitch and GetConVar("ttt_glitch_enabled"):GetBool() and choice_count >= GetConVar("ttt_glitch_min_players"):GetInt() and #traitors > 1 then
            for _ = 1, GetConVar("ttt_glitch_spawn_weight"):GetInt() do
                table.insert(specialInnocentRoles, ROLE_GLITCH)
            end
        end
        if not hasPhantom and GetConVar("ttt_phantom_enabled"):GetBool() and choice_count >= GetConVar("ttt_phantom_min_players"):GetInt() then
            for _ = 1, GetConVar("ttt_phantom_spawn_weight"):GetInt() do
                table.insert(specialInnocentRoles, ROLE_PHANTOM)
            end
        end
        if not hasRevenger and GetConVar("ttt_revenger_enabled"):GetBool() and choice_count >= GetConVar("ttt_revenger_min_players"):GetInt() and choice_count > 1 then
            for _ = 1, GetConVar("ttt_revenger_spawn_weight"):GetInt() do
                table.insert(specialInnocentRoles, ROLE_REVENGER)
            end
        end
        if not hasDeputy and GetConVar("ttt_deputy_enabled"):GetBool() and choice_count >= GetConVar("ttt_deputy_min_players"):GetInt() and detective_count > 0 and not impersonator_only then
            for _ = 1, GetConVar("ttt_deputy_spawn_weight"):GetInt() do
                table.insert(specialInnocentRoles, ROLE_DEPUTY)
            end
        end
        if not hasMercenary and GetConVar("ttt_mercenary_enabled"):GetBool() and choice_count >= GetConVar("ttt_mercenary_min_players"):GetInt() then
            for _ = 1, GetConVar("ttt_mercenary_spawn_weight"):GetInt() do
                table.insert(specialInnocentRoles, ROLE_MERCENARY)
            end
        end
        if not hasVeteran and GetConVar("ttt_veteran_enabled"):GetBool() and choice_count >= GetConVar("ttt_veteran_min_players"):GetInt() then
            for _ = 1, GetConVar("ttt_veteran_spawn_weight"):GetInt() do
                table.insert(specialInnocentRoles, ROLE_VETERAN)
            end
        end
        if not hasDoctor and GetConVar("ttt_doctor_enabled"):GetBool() and choice_count >= GetConVar("ttt_doctor_min_players"):GetInt() and not quack_only then
            for _ = 1, GetConVar("ttt_doctor_spawn_weight"):GetInt() do
                table.insert(specialInnocentRoles, ROLE_DOCTOR)
            end
        end
        if not hasTrickster and GetConVar("ttt_trickster_enabled"):GetBool() and choice_count >= GetConVar("ttt_trickster_min_players"):GetInt() and map_has_traitor_buttons then
            for _ = 1, GetConVar("ttt_trickster_spawn_weight"):GetInt() do
                table.insert(specialInnocentRoles, ROLE_TRICKSTER)
            end
        end
        for _ = 1, max_special_innocent_count do
            if #specialInnocentRoles ~= 0 and math.random() <= GetConVar("ttt_special_innocent_chance"):GetFloat() and #choices > 0 then
                local plyPick = math.random(1, #choices)
                local ply = choices[plyPick]
                local rolePick = math.random(1, #specialInnocentRoles)
                local role = specialInnocentRoles[rolePick]
                ply:SetRole(role)
                PrintRole(ply, role)
                table.remove(choices, plyPick)
                for i = #specialInnocentRoles, 1, -1 do
                    if specialInnocentRoles[i] == role then
                        table.remove(specialInnocentRoles, i)
                    end
                end
            end
        end
    end

    if monster_count > 0 then
        local monsterRoles = {}
        if MONSTER_ROLES[ROLE_ZOMBIE] and not hasZombie and GetConVar("ttt_zombie_enabled"):GetBool() and choice_count >= GetConVar("ttt_zombie_min_players"):GetInt() then
            for _ = 1, GetConVar("ttt_zombie_spawn_weight"):GetInt() do
                table.insert(monsterRoles, ROLE_ZOMBIE)
            end
        end
        if MONSTER_ROLES[ROLE_VAMPIRE] and not hasVampire and GetConVar("ttt_vampire_enabled"):GetBool() and choice_count >= GetConVar("ttt_vampire_min_players"):GetInt() then
            for _ = 1, GetConVar("ttt_vampire_spawn_weight"):GetInt() do
                table.insert(monsterRoles, ROLE_VAMPIRE)
            end
        end
        local monster_chosen = false
        for _ = 1, monster_count do
            if #monsterRoles ~= 0 and math.random() <= GetConVar("ttt_monster_chance"):GetFloat() and #choices > 0 and not monster_chosen then
                local plyPick = math.random(1, #choices)
                local ply = choices[plyPick]
                local rolePick = math.random(1, #monsterRoles)
                local role = monsterRoles[rolePick]
                ply:SetRole(role)
                PrintRole(ply, role)
                table.remove(choices, plyPick)
                for i = #monsterRoles, 1, -1 do
                    if monsterRoles[i] == role then
                        table.remove(monsterRoles, i)
                    end
                end
                monster_chosen = true
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

    for _, ply in ipairs(plys) do
        -- initialize credit count for everyone based on their role
        if IsValid(ply) and not ply:IsSpec() then
            if ply:GetRole() == ROLE_NONE then
                ErrorNoHalt("WARNING: " .. ply:Nick() .. " was not assigned a role! Forcing them to be " .. ROLE_STRINGS[ROLE_INNOCENT] .. "...\n")
                ply:SetRole(ROLE_INNOCENT)
            end

            if ply:GetRole() == ROLE_ZOMBIE then
                ply:SetZombiePrime(true)
            elseif ply:GetRole() == ROLE_VAMPIRE then
                ply:SetVampirePrime(true)
            end

            ply:SetDefaultCredits()
        end

        -- store a steamid -> role map
        GAMEMODE.LastRole[ply:SteamID64()] = ply:GetRole()
    end
end

local function ForceRoundRestart(ply, command, args)
    -- ply is nil on dedicated server console
    if (not IsValid(ply)) or ply:IsAdmin() or ply:IsSuperAdmin() or cvars.Bool("sv_cheats", 0) then
        LANG.Msg("round_restart")

        StopRoundTimers()

        -- Let addons know that a round ended
        hook.Call("TTTEndRound", GAMEMODE, WIN_NONE)

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
-- Creator: Exho

resource.AddFile("sound/hitmarkers/mlghit.wav")
hook.Add("EntityTakeDamage", "HitmarkerDetector", function(ent, dmginfo)
    local att = dmginfo:GetAttacker()
    local pos = dmginfo:GetDamagePosition()

    if (IsValid(att) and att:IsPlayer() and att ~= ent) then
        if (ent:IsPlayer() or ent:IsNPC()) then -- Only players and NPCs show hitmarkers
            local drawCrit = ent:GetNWBool("LastHitCrit") and not GetConVar("ttt_disable_headshots"):GetBool()

            net.Start("TTT_DrawHitMarker")
            net.WriteBool(drawCrit)
            net.Send(att) -- Send the message to the attacker

            net.Start("TTT_CreateBlood")
            net.WriteVector(pos)
            net.Broadcast()
        end
    end
end)

hook.Add("ScalePlayerDamage", "HitmarkerPlayerCritDetector", function(ply, hitgroup, dmginfo)
    ply:SetNWBool("LastHitCrit", hitgroup == HITGROUP_HEAD)
end)

hook.Add("ScaleNPCDamage", "HitmarkerPlayerCritDetector", function(npc, hitgroup, dmginfo)
    npc:SetNWBool("LastHitCrit", hitgroup == HITGROUP_HEAD)
end)

hook.Add("PlayerSay", "ColorMixerOpen", function(ply, text, team_only)
    text = string.lower(text)
    if (string.sub(text, 1, 12) == "!hmcritcolor") then
        net.Start("TTT_OpenMixer")
        net.WriteBool(true)
        net.Send(ply)
        return false
    elseif (string.sub(text, 1, 8) == "!hmcolor") then
        net.Start("TTT_OpenMixer")
        net.WriteBool(false)
        net.Send(ply)
        return false
    end
end)

-- Death messages
hook.Add("PlayerDeath", "TTT_ClientDeathNotify", function(victim, entity, killer)
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

                    -- If this Phantom was killed by a player and they are supposed to haunt them, hide their killer's role
                    if GetRoundState() == ROUND_ACTIVE and victim:IsPhantom() and GetConVar("ttt_phantom_killer_haunt"):GetBool() then
                        role = ROLE_NONE
                    else
                        role = killer:GetRole()
                    end
                end
            end
        end

        -- Send the buffer message with the death information to the victim
        net.Start("TTT_ClientDeathNotify")
        net.WriteString(killerName)
        net.WriteInt(role, 8)
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
    local convars = {
        [1] = speedMultiplier:GetFloat();
        [2] = recovery:GetFloat();
        [3] = traitorRecovery:GetFloat();
        [4] = consumption:GetFloat();
    }
    net.Start("TTT_SprintGetConVars")
    net.WriteTable(convars)
    net.Send(ply)
end)

-- return Speed
hook.Add("TTTPlayerSpeedModifier", "TTTSprintPlayerSpeed", function(ply, _, _)
    return GetSprintMultiplier(ply, ply.mult ~= nil)
end)

-- If this logic or the list of roles who can buy is changed, it must also be updated in weaponry.lua and cl_equip.lua
-- This also sends a cache reset request to every client so that things like shop randomization happen every round
function HandleRoleEquipment()
    local handled = false
    for id, name in pairs(ROLE_STRINGS_RAW) do
        WEPS.PrepWeaponsLists(id)
        local rolefiles, _ = file.Find("roleweapons/" .. name .. "/*.txt", "DATA")
        local roleexcludes = { }
        local roleenorandoms = { }
        local roleweapons = { }
        for _, v in pairs(rolefiles) do
            local exclude = false
            local norandom = false
            -- Extract the weapon name from the file name
            local lastdotpos = v:find("%.")
            local weaponname = v:sub(0, lastdotpos - 1)

            -- Check that there isn't a two-part extension (e.g. "something.exclude.txt")
            local extension = v:sub(lastdotpos + 1, #v)
            lastdotpos = extension:find("%.")

            -- If there is, check if it equals "exclude"
            if lastdotpos ~= nil then
                extension = extension:sub(0, lastdotpos - 1)
                if extension:lower() == "exclude" then
                    exclude = true
                elseif extension:lower() == "norandom" then
                    norandom = true
                end
            end

            if exclude then
                table.insert(WEPS.ExcludeWeapons[id], weaponname)
                table.insert(roleexcludes, weaponname)
            elseif norandom then
                table.insert(WEPS.BypassRandomWeapons[id], weaponname)
                table.insert(roleenorandoms, weaponname)
            else
                table.insert(WEPS.BuyableWeapons[id], weaponname)
                table.insert(roleweapons, weaponname)
            end
        end

        if #roleweapons > 0 or #roleexcludes > 0 or #roleenorandoms > 0 then
            net.Start("TTT_BuyableWeapons")
            net.WriteInt(id, 16)
            net.WriteTable(roleweapons)
            net.WriteTable(roleexcludes)
            net.WriteTable(roleenorandoms)
            net.Broadcast()
            handled = true
        end
    end

    -- Send this once if the roleweapons feature wasn't used (which resets the cache on its own)
    if not handled then
        net.Start("TTT_ResetBuyableWeaponsCache")
        net.Broadcast()
    end
end