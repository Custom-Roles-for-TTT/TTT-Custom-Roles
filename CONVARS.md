# Server Configurations

Add the following to your server.cfg (for dedicated servers) or listenserver.cfg (for peer-to-peer servers):

```cpp
// ----------------------------------------
// Custom Role Settings
// ----------------------------------------

// ROLE SPAWN REQUIREMENTS
ttt_special_traitor_pct                     0.33    // Percentage of traitors, rounded up, that can spawn as a "special traitor" (e.g. hypnotist, impersonator, etc.)
ttt_special_traitor_chance                  0.5     // The chance that a "special traitor" will spawn in each available slot made by "ttt_special_traitor_pct"
ttt_special_innocent_pct                    0.33    // Percentage of innocents, rounded up, that can spawn as a "special innocent" (e.g. glitch, phantom, etc.)
ttt_special_innocent_chance                 0.5     // The chance that a "special innocent" will spawn in each available slot made by "ttt_special_innocent_pct"
ttt_monster_pct                             0.33    // Percentage of innocents, rounded up, that can spawn as a "monster" (e.g. zombie, vampire)
ttt_monster_chance                          0.5     // The chance that a "monster" will spawn in each available slot made by "ttt_monster_pct"
ttt_independent_chance                      0.5     // The chance that an independent or jester (e.g. drunk, swapper, etc.) will spawn in a round.
// (Note: Only one independent or jester can spawn per round.)

// Enable/Disable Individual Roles
ttt_hypnotist_enabled                       0       // Whether or not the hypnotist should spawn
ttt_impersonator_enabled                    0       // Whether or not the impersonator should spawn
ttt_assassin_enabled                        0       // Whether or not the assassin should spawn
ttt_vampire_enabled                         0       // Whether or not the vampire should spawn
ttt_quack_enabled                           0       // Whether or not the quack should spawn
ttt_parasite_enabled                        0       // Whether or not the parasite should spawn
ttt_glitch_enabled                          0       // Whether or not the glitch should spawn
ttt_phantom_enabled                         0       // Whether or not the phantom should spawn
ttt_revenger_enabled                        0       // Whether or not the revenger should spawn
ttt_deputy_enabled                          0       // Whether or not the deputy should spawn
ttt_mercenary_enabled                       0       // Whether or not the mercenary should spawn
ttt_veteran_enabled                         0       // Whether or not the veteran should spawn
ttt_doctor_enabled                          0       // Whether or not the doctor should spawn
ttt_jester_enabled                          0       // Whether or not the jester should spawn
ttt_swapper_enabled                         0       // Whether or not the swapper should spawn
ttt_clown_enabled                           0       // Whether or not the clown should spawn
ttt_beggar_enabled                          0       // Whether or not the beggar should spawn
ttt_bodysnatcher_enabled                    0       // Whether or not the bodysnatcher should spawn
ttt_drunk_enabled                           0       // Whether or not the drunk should spawn
ttt_old_man_enabled                         0       // Whether or not the old man should spawn
ttt_killer_enabled                          0       // Whether or not the killer should spawn
ttt_zombie_enabled                          0       // Whether or not the zombie should spawn

// Individual Role Spawn Weights
ttt_hypnotist_spawn_weight                  1       // The weight assigned to spawning the hypnotist
ttt_impersonator_spawn_weight               1       // The weight assigned to spawning the impersonator
ttt_assassin_spawn_weight                   1       // The weight assigned to spawning the assassin
ttt_vampire_spawn_weight                    1       // The weight assigned to spawning the vampire
ttt_quack_spawn_weight                      1       // The weight assigned to spawning the quack
ttt_parasite_spawn_weight                   1       // The weight assigned to spawning the parasite
ttt_glitch_spawn_weight                     1       // The weight assigned to spawning the glitch
ttt_phantom_spawn_weight                    1       // The weight assigned to spawning the phantom
ttt_revenger_spawn_weight                   1       // The weight assigned to spawning the revenger
ttt_deputy_spawn_weight                     1       // The weight assigned to spawning the deputy
ttt_mercenary_spawn_weight                  1       // The weight assigned to spawning the mercenary
ttt_veteran_spawn_weight                    1       // The weight assigned to spawning the veteran
ttt_doctor_spawn_weight                     1       // The weight assigned to spawning the doctor
ttt_jester_spawn_weight                     1       // The weight assigned to spawning the jester
ttt_swapper_spawn_weight                    1       // The weight assigned to spawning the swapper
ttt_clown_spawn_weight                      1       // The weight assigned to spawning the clown
ttt_beggar_spawn_weight                     1       // The weight assigned to spawning the beggar
ttt_bodysnatcher_spawn_weight               1       // The weight assigned to spawning the bodysnatcher
ttt_drunk_spawn_weight                      1       // The weight assigned to spawning the drunk
ttt_old_man_spawn_weight                    1       // The weight assigned to spawning the old man
ttt_killer_spawn_weight                     1       // The weight assigned to spawning the killer
ttt_zombie_spawn_weight                     1       // The weight assigned to spawning the zombie
// (Note: Each role is limited to one player per round.)

// Individual Role Minimum Player Requirements
ttt_hypnotist_min_players                   0       // The minimum number of players required to spawn the hypnotist
ttt_impersonator_min_players                0       // The minimum number of players required to spawn the impersonator
ttt_assassin_min_players                    0       // The minimum number of players required to spawn the assassin
ttt_vampire_min_players                     0       // The minimum number of players required to spawn the vampire
ttt_quack_min_players                       0       // The minimum number of players required to spawn the quack
ttt_parasite_min_players                    0       // The minimum number of players required to spawn the parasite
ttt_glitch_min_players                      0       // The minimum number of players required to spawn the glitch
ttt_phantom_min_players                     0       // The minimum number of players required to spawn the phantom
ttt_revenger_min_players                    0       // The minimum number of players required to spawn the revenger
ttt_deputy_min_players                      0       // The minimum number of players required to spawn the deputy
ttt_mercenary_min_players                   0       // The minimum number of players required to spawn the mercenary
ttt_veteran_min_players                     0       // The minimum number of players required to spawn the veteran
ttt_doctor_min_players                      0       // The minimum number of players required to spawn the doctor
ttt_jester_min_players                      0       // The minimum number of players required to spawn the jester
ttt_swapper_min_players                     0       // The minimum number of players required to spawn the swapper
ttt_clown_min_players                       0       // The minimum number of players required to spawn the clown
ttt_beggar_min_players                      0       // The minimum number of players required to spawn the beggar
ttt_bodysnatcher_min_players                0       // The minimum number of players required to spawn the bodysnatcher
ttt_drunk_min_players                       0       // The minimum number of players required to spawn the drunk
ttt_old_man_min_players                     0       // The minimum number of players required to spawn the old man
ttt_killer_min_players                      0       // The minimum number of players required to spawn the killer
ttt_zombie_min_players                      0       // The minimum number of players required to spawn the zombie

// ----------------------------------------

// TRAITOR TEAM SETTINGS
ttt_traitor_vision_enable                   0       // Whether members of the traitor team can see other members of the traitor team (including Glitches) through walls via a highlight effect

// Impersonator
ttt_impersonator_damage_penalty             0       // Damage penalty that the impersonator has before being promoted (e.g. 0.5 = 50% less damage)
ttt_imp_credits_starting                    1       // The number of credits an impersonator should start with

// Hypnotist
ttt_hyp_credits_starting                    1       // The number of credits a hypnotist should start with

// Assassin
ttt_assassin_show_target_icon               0       // Whether assassins have an icon over their target's heads showing who to kill. Server or round must be restarted for changes to take effect
ttt_assassin_next_target_delay              2       // The delay (in seconds) before an assassin is assigned their next target
ttt_assassin_target_damage_bonus            1       // Damage bonus that the assassin has against their target (e.g. 0.5 = 50% extra damage)
ttt_assassin_wrong_damage_penalty           0.5     // Damage penalty that the assassin has when attacking someone who is not their target (e.g. 0.5 = 50% less damage)
ttt_assassin_failed_damage_penalty          0.5     // Damage penalty that the assassin has after they have failed their contract by killing the wrong person (e.g. 0.5 = 50% less damage)
ttt_asn_credits_starting                    1       // The number of credits an assassin should start with

// Vampire
ttt_vampires_are_monsters                   0       // Whether Vampires should be treated as members of the Monster team.
ttt_vampire_vision_enable                   0       // Whether Vampires have their special vision highlights enabled
ttt_vampire_drain_enable                    1       // Whether Vampires have the ability to drain other players' blood using their fangs
ttt_vampire_convert_enable                  0       // Whether Vampires have the ability to convert other players to vampire thrals using their fangs
ttt_vampire_show_target_icon                0       // Whether Vampires have an icon over other players' heads showing who to kill. Server or round must be restarted for changes to take effect.
ttt_vampire_damage_reduction                0       // The fraction an attacker's bullet damage will be reduced by when they are shooting a Vampire.
ttt_vampire_fang_timer                      5       // The amount of time fangs must be used to fully drain a target's blood
ttt_vampire_fang_heal                       50      // The amount of health a Vampire will heal by when they fully drain a target's blood
ttt_vampire_fang_overheal                   25      // The amount over the Vampire's normal maximum health (e.g. 100 + this ConVar) that the Vampire can heal to by drinking blood.
ttt_vampire_prime_death_mode                0       // What to do when the Prime Vampire(s) (e.g. playters who spawn as Vampires originally) are killed. 0 - Do nothing. 1 - Kill all non-prime Vampires. 2 - Revert all non-prime Vampires to their original role.
ttt_vampire_prime_only_convert              1       // Whether only Prime Vampires (e.g. players who spawn as Vampire originally) are allowed to convert other players.
ttt_vam_credits_starting                    1       // The number of credits a vampire should start with

// Quack
ttt_qua_credits_starting                    1       // The number of credits a quack should start with

// Parasite
ttt_par_credits_starting                    1       // The number of credits a parasite should start with

// ----------------------------------------

// INNOCENT TEAM SETTINGS
// Detective
ttt_detective_search_only                   1       // Whether only detectives can search bodies or not
ttt_all_search_postround                    1       // Whether non-detectives can search bodies post-round or not
ttt_detective_starting_health               100     // The amount of health the detective spawns with

// Phantom
ttt_phantom_respawn_health                  50      // The amount of health a phantom will respawn with
ttt_phantom_weaker_each_respawn             0       // Whether a phantom respawns weaker (1/2 as much HP) each time they respawn, down to a minimum of 1
ttt_phantom_killer_smoke                    1       // Whether to show smoke on the player who killed the phantom
ttt_phantom_announce_death                  0       // Whether to announce to detectives (and promoted deputies and impersonators) that a phantom has been killed or respawned
ttt_phantom_killer_haunt                    1       // Whether to have the phantom haunt their killer
ttt_phantom_killer_haunt_power_max          100     // The maximum amount of power a phantom can have when haunting their killer
ttt_phantom_killer_haunt_power_rate         10      // The amount of power to regain per second when a phantom is haunting their killer
ttt_phantom_killer_haunt_move_cost          25      // The amount of power to spend when a phantom is moving their killer via a haunting. 0 to disable
ttt_phantom_killer_haunt_jump_cost          50      // The amount of power to spend when a phantom is making their killer jump via a haunting. 0 to disable
ttt_phantom_killer_haunt_drop_cost          75      // The amount of power to spend when a phantom is making their killer drop their weapon via a haunting. 0 to disable
ttt_phantom_killer_haunt_attack_cost        100     // The amount of power to spend when a phantom is making their killer attack via a haunting. 0 to disable
ttt_phantom_killer_footstep_time            0       // The amount of time a phantom's killer's footsteps should show before fading. 0 to disable

// Revenger
ttt_revenger_radar_timer                    15      // The amount of time between radar pings for the revenger's lover's killer
ttt_revenger_damage_bonus                   0       // Extra damage that the revenger deals to their lover's killer (e.g. 0.5 = 50% extra damage)

// Deputy
ttt_deputy_damage_penalty                   0       // Damage penalty that the deputy has before being promoted (e.g. 0.5 = 50% less damage)

// Mercenary
ttt_shop_mer_mode                           2       // What items are available to the mercenary in the shop (0=None, 1=detective OR traitor, 2=detective AND traitor, 3=detective, 4=traitor)

// Veteran
ttt_veteran_damage_bonus                    0.5     // Damage bonus that the veteran has when they are the last innocent alive (e.g. 0.5 = 50% more damage)
ttt_veteran_full_heal                       1       // Whether the veteran gets a full heal upon becoming the last remaining innocent or not

// Mercenary
ttt_mer_credits_starting                    1       // The number of credits a mercenary should start with

// Doctor
ttt_doctor_mode                             0       // How the Doctor should be played (0=Health Station, 1=Defib then Health Station)
ttt_doc_credits_starting                    0       // How many credits the Doctor starts with

// ----------------------------------------

// JESTER TEAM SETTINGS
ttt_jesters_trigger_traitor_testers         1       // Whether jesters trigger traitor traps as if they were traitors

// Jester
ttt_jester_win_by_traitors                  1       // Whether the jester will win the round if they are killed by a traitor
ttt_jester_notify_mode                      0       // The logic to use when notifying players that a jester is killed. 0 - Don't notify anyone. 1 - Only notify Traitors and Detective. 2 - Only notify Traitors. 3 - Only notify Detective. 4 - Notify everyone.
ttt_jester_notify_sound                     0       // Whether to play a cheering sound when a jester is killed
ttt_jester_notify_confetti                  0       // Whether to throw confetti when a jester is a killed
ttt_jes_credits_starting                    0       // The number of credits a jester should start with

// Swapper
ttt_swapper_respawn_health                  100     // What amount of health to give the swapper when they are killed and respawned
ttt_swapper_notify_mode                     0       // The logic to use when notifying players that a swapper is killed. 0 - Don't notify anyone. 1 - Only notify Traitors and Detective. 2 - Only notify Traitors. 3 - Only notify Detective. 4 - Notify everyone.
ttt_swapper_notify_sound                    0       // Whether to play a cheering sound when a swapper is killed
ttt_swapper_notify_confetti                 0       // Whether to throw confetti when a swapper is a killed
ttt_swapper_killer_health                   100     // What amount of health to give the person who killed the swapper. Set to "0" to kill them
ttt_swa_credits_starting                    0       // The number of credits a swapper should start with

// Clown
ttt_clown_damage_bonus                      0       // Damage bonus that the clown has after being activated (e.g. 0.5 = 50% more damage)
ttt_clown_activation_credits                0       // The number of credits to give the clown when they are activated
ttt_shop_clo_mode                           0       // What items are available to the clown in the shop (0=None, 1=Detective OR Traitor, 2=Detective AND Traitor, 3=Detective, 4=Traitor)

// Beggar
ttt_reveal_beggar_change                    1       // Whether the beggar is revealed to you when they join your team or not
ttt_beggar_respawn                          0       // Whether the beggar respawns when they are killed before joining another team
ttt_beggar_respawn_delay                    3       // The delay to use when respawning the begger (if "ttt_beggar_respawn" is enabled)
ttt_beggar_notify_mode                      0       // The logic to use when notifying players that a beggar is killed. 0 - Don't notify anyone. 1 - Only notify Traitors and Detective. 2 - Only notify Traitors. 3 - Only notify Detective. 4 - Notify everyone.
ttt_beggar_notify_sound                     1       // Whether to play a cheering sound when a beggar is killed
ttt_beggar_notify_confetti                  1       // Whether to throw confetti when a beggar is a killed

// Bodysnatcher
ttt_bodysnatcher_destroy_body               0       // Whether the bodysnatching device destroys the body it is used on or not
ttt_bodysnatcher_show_role                  1       // Whether the bodysnatching device shows the role of the corpse it is used on or not

// ----------------------------------------

// INDEPENDENT TEAM SETTINGS
ttt_independents_trigger_traitor_testers    0       // Whether independents trigger traitor traps as if they were traitors

// Drunk
ttt_drunk_sober_time                        180     // Time in seconds for the drunk to remember their role
ttt_drunk_innocent_chance                   0.7     // Chance that the drunk will become an innocent when remembering their role

// Old Man
ttt_old_man_starting_health                 1       // The amount of health the old man spawns with

// Killer
ttt_killer_max_health                       150     // The killer's starting and maximum health
ttt_killer_knife_enabled                    1       // Whether the killer knife is enabled
ttt_killer_crowbar_enabled                  1       // Whether the killer throwable crowbar is enabled
ttt_killer_smoke_enabled                    1       // Whether the killer smoke is enabled
ttt_killer_smoke_timer                      60      // Number of seconds before a killer will start to smoke after their last kill
ttt_killer_show_target_icon                 1       // Whether killer have an icon over other players' heads showing who to kill. Server or round must be restarted for changes to take effect
ttt_killer_damage_penalty                   0.25    // The fraction a killer's damage will be scaled by when they are attacking without using their knife
ttt_killer_damage_reduction                 0       // The fraction an attacker's bullet damage will be reduced by when they are shooting a killer
ttt_killer_warn_all                         0       // Whether to warn all players if there is a killer. If 0, only traitors will be warned
ttt_killer_vision_enable                    1       // Whether killers have their special vision highlights enabled
ttt_kil_credits_starting                    2       // The number of credits a killer should start with

// Zombie
ttt_zombies_are_monsters                    0       // Whether Zombies should be treated as members of the Monster team.
ttt_zombies_are_traitors                    0       // Whether Zombies should be treated as members of the Traitors team.
ttt_zombie_round_chance                     0.1     // The chance that a "Zombie Round" will occur where all players who would have been Traitors are made Zombies instead. Only usable when "ttt_zombies_are_traitors" is set to "1"
ttt_zombie_vision_enable                    0       // Whether Zombies have their special vision highlights enabled
ttt_zombie_spit_enable                      1       // Whether Zombies have their spit attack enabled
ttt_zombie_leap_enable                      1       // Whether Zombies have their leap attack enabled
ttt_zombie_show_target_icon                 0       // Whether Zombies have an icon over other players' heads showing who to kill. Server or round must be restarted for changes to take effect.
ttt_zombie_damage_penalty                   0.5     // The fraction a Zombie's damage will be scaled by when they are attacking without using their claws.
ttt_zombie_damage_reduction                 0       // The fraction an attacker's bullet damage will be reduced by when they are shooting a Zombie.
ttt_zombie_prime_only_weapons               1       // Whether only Prime Zombies (e.g. players who spawn as Zombies originally) are allowed to pick up weapons.

// ----------------------------------------

// WEAPON SHOP SETTINGS
// Random Shop Restriction Percent
ttt_shop_random_percent                     50      // The percent chance that a weapon in the shop will be not be shown

// Role Specific Random Shop Restriction Percent
ttt_shop_random_tra_percent                 0       // The percent chance that a weapon in the shop will be not be shown for the traitors
ttt_shop_random_det_percent                 0       // The percent chance that a weapon in the shop will be not be shown for the detectives
ttt_shop_random_hyp_percent                 0       // The percent chance that a weapon in the shop will be not be shown for the hypnotists
ttt_shop_random_dep_percent                 0       // The percent chance that a weapon in the shop will be not be shown for the deputies
ttt_shop_random_imp_percent                 0       // The percent chance that a weapon in the shop will be not be shown for the impersonators
ttt_shop_random_asn_percent                 0       // The percent chance that a weapon in the shop will be not be shown for the assassins
ttt_shop_random_kil_percent                 0       // The percent chance that a weapon in the shop will be not be shown for the killers
ttt_shop_random_jes_percent                 0       // The percent chance that a weapon in the shop will be not be shown for the jesters
ttt_shop_random_swa_percent                 0       // The percent chance that a weapon in the shop will be not be shown for the swappers
ttt_shop_random_zom_percent                 0       // The percent chance that a weapon in the shop will be not be shown for the zombies
ttt_shop_random_vam_percent                 0       // The percent chance that a weapon in the shop will be not be shown for the vampires
ttt_shop_random_clo_percent                 0       // The percent chance that a weapon in the shop will be not be shown for the clowns

// Enable/Disable Individual Role Random Shop Restrictions
ttt_shop_random_tra_enabled                 0       // Whether role shop randomization is enabled for traitors
ttt_shop_random_det_enabled                 0       // Whether role shop randomization is enabled for detectives
ttt_shop_random_hyp_enabled                 0       // Whether role shop randomization is enabled for hypnotists
ttt_shop_random_dep_enabled                 0       // Whether role shop randomization is enabled for deputies
ttt_shop_random_imp_enabled                 0       // Whether role shop randomization is enabled for impersonators
ttt_shop_random_asn_enabled                 0       // Whether role shop randomization is enabled for assassins
ttt_shop_random_kil_enabled                 0       // Whether role shop randomization is enabled for killers
ttt_shop_random_jes_enabled                 0       // Whether role shop randomization is enabled for jesters
ttt_shop_random_swa_enabled                 0       // Whether role shop randomization is enabled for swappers
ttt_shop_random_zom_enabled                 0       // Whether role shop randomization is enabled for zombies
ttt_shop_random_vam_enabled                 0       // Whether role shop randomization is enabled for vampires
ttt_shop_random_clo_enabled                 0       // Whether role shop randomization is enabled for clowns

// Role Sync
ttt_shop_hyp_sync                           0       // Whether Hypnotists should have all weapons that vanilla Traitors have in their weapon shop
ttt_shop_imp_sync                           0       // Whether Impersonators should have all weapons that vanilla Traitors have in their weapon shop
ttt_shop_asn_sync                           0       // Whether Assassins should have all weapons that vanilla Traitors have in their weapon shop
ttt_shop_vam_sync                           0       // Whether Vampires should have all weapons that vanilla Traitors have in their weapon shop (if they are a Traitor)
ttt_shop_zom_sync                           0       // Whether Zombies should have all weapons that vanilla Traitors have in their weapon shop (if they are a Traitor)
ttt_shop_qua_sync                           0       // Whether Quacks should have all weapons that vanilla Traitors have in their weapon shop
ttt_shop_par_sync                           0       // Whether Parasites should have all weapons that vanilla Traitors have in their weapon shop

// ----------------------------------------

// OTHER SETTINGS
// Logging
ttt_debug_logkills                          1       // Whether to log when a player is killed in the console
ttt_debug_logroles                          1       // Whether to log what roles players are assigned in the console

// Karma    
ttt_karma_jesterkill_penalty                50      // Karma penalty for killing the jester
ttt_karma_jester_ratio                      0.5     // Ratio of damage to jesters, to be taken from karma

// Sprint
ttt_sprint_bonus_rel                        0.4     // The relative speed bonus given while sprinting (e.g. 0.4 = 40% speed increase)
ttt_sprint_regenerate_innocent              0.08    // Stamina regeneration for non-traitors
ttt_sprint_regenerate_traitor               0.12    // Stamina regeneration for traitors
ttt_sprint_consume                          0.2     // Stamina consumption speed

// Better Equipment Menu
ttt_bem_allow_change                        1       // Allow clients to change the look of the shop menu
ttt_bem_sv_cols                             4       // Sets the number of columns in the shop menu's item list (serverside)
ttt_bem_sv_rows                             5       // Sets the number of rows in the shop menu's item list (serverside)
ttt_bem_sv_size                             64      // Sets the item size in the shop menu's item list (serverside)
```

Thanks to [KarlOfDuty](https://github.com/KarlOfDuty) for his original version of this document, [here](https://github.com/KarlOfDuty/TTT-Custom-Roles/blob/patch-1/README.md).

# Role Weapon Shop

In TTT some roles have shops where they are allowed to purchase weapons. Given the prevalence of custom weapons from the workshop, the ability to add more weapons to each role's shop has been added.

## Adding Weapons

To add weapons to a role (that already has a shop), create a .txt file with the weapon class (e.g. weapon_ttt_somethingcool.txt) in the garrysmod/data/roleweapons/{rolename} folder.\
**NOTE**: If the _roleweapons_ folder does not already exist in garrysmod/data, create it.\
**NOTE**: The name of the role must be all lowercase for cross-operating system compatibility. For example: garrysmod/data/roleweapons/detective/weapon_ttt_somethingcool.txt

Also note the ttt_shop_* ConVars that are available above which can help control some of the role weapon shop lists.

## Removing Weapons

At the same time, there are some workshop weapons that are given to multiple roles that maybe you don't want to be available to certain roles. In order to handle that case, the ability to exclude weapons from a role's weapon shop has been added.

To remove weapons from a role's shop, create a .exclude.txt file with the weapon class (e.g. weapon_ttt_somethingcool.exclude.txt) in the garrysmod/data/roleweapons/{rolename} folder.\
**NOTE**: If the _roleweapons_ folder does not already exist in garrysmod/data, create it.\
**NOTE**: The name of the role must be all lowercase for cross-operating system compatibility. For example: garrysmod/data/roleweapons/detective/weapon_ttt_somethingcool.exclude.txt

## Bypassing Weapon Randomization

With the addition of the Shop Randomization feature (and the ttt_shop_random_* ConVars), weapons may not always appear in the shop (which is the point). If, however, you want certain weapons to _always_ be in the shop while other weapons are randomized, the ability to bypass shop randomization for a weapon in a role's weapon shop has been added.

To stop a weapon from being removed from a role's shop via randomization, create a .norandom.txt file with the weapon class (e.g. weapon_ttt_somethingcool.norandom.txt) in the garrysmod/data/roleweapons/{rolename} folder.\
**NOTE**: If the _roleweapons_ folder does not already exist in garrysmod/data, create it.\
**NOTE**: The name of the role must be all lowercase for cross-operating system compatibility. For example: garrysmod/data/roleweapons/detective/weapon_ttt_somethingcool.norandom.txt

## Finding a Weapon's Class

To find the class name of a weapon to use above, follow the steps below
1. Start a local server with TTT as the selected gamemode
2. Spawn 1 bot by using the _bot_ command in console
3. Obtain the weapon whose class you want. If it is already available to buy from a certain role's shop, either force yourself to be that role via the _ttt\_force\_*_ commands or via a ULX plugin.
4. Run the following command in console to get a list of all of your weapon classes: _lua\_run PrintTable(player.GetHumans()[1]:GetWeapons())_

## Adding Equipment

Equipment are items that a role can use that do not take up a weapon slot, such as the body armor or radar. To add equipment items to a role (that already has a shop), create a .txt file with the equipment item's name (e.g. "bruh bunker.txt") in the garrysmod/data/roleweapons/{rolename} folder.\
**NOTE**: If the _roleweapons_ folder does not already exist in garrysmod/data, create it.\
**NOTE**: The name of the role must be all lowercase for cross-operating system compatibility. For example: garrysmod/data/roleweapons/detective/bruh bunker.txt

## Removing Equipment

Similarly there are some equipment items that you want to prevent a specific role from buying. To handle that case, the addon has the ability to exclude specific equipment items from the shop in a similar way.

To remove equipment from a role's shop, create a .exclude.txt file with the item's name (e.g. "bruh bunker.exclude.txt") in the garrysmod/data/roleweapons/{rolename} folder.\
**NOTE**: If the _roleweapons_ folder does not already exist in garrysmod/data, create it.\
**NOTE**: The name of the role must be all lowercase for cross-operating system compatibility. For example: garrysmod/data/roleweapons/detective/bruh bunker.exclude.txt

## Finding an Equipment Item's Name

To find the name of an equipment item to use above, follow the steps below
1. Start a local server with TTT as the selected gamemode
2. Spawn 1 bot by using the _bot_ command in console
3. Obtain the equipment item whose name you want. If it is already available to buy from a certain role's shop, either force yourself to be that role via the _ttt\_force\_*_ commands or via a ULX plugin.
4. Run the following command in console to get a full list of your equipment item names: _lua\_run GetEquipmentItemById(EQUIP\_RADAR); lua\_run for id, e in pairs(EquipmentCache) do if player.GetHumans()[1]:HasEquipmentItem(id) then print(id .. " = " .. e.name) end end_
