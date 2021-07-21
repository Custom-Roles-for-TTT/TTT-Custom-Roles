# Server Configurations

Add the following to your server.cfg (for dedicated servers) or listenserver.cfg (for peer-to-peer servers):

```cpp
// ----------------------------------------
// Custom Role Settings
// ----------------------------------------

// ROLE SPAWN REQUIREMENTS
ttt_traitor_pct                             0.25    // Percentage of players, rounded up, that can spawn as a traitor or "special traitor"
ttt_detective_pct                           0.13    // Percentage of players, rounded up, that can spawn as a detective
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
ttt_oldman_enabled                          0       // Whether or not the old man should spawn
ttt_killer_enabled                          0       // Whether or not the killer should spawn
ttt_zombie_enabled                          0       // Whether or not the zombie should spawn
ttt_trickster_enabled                       0       // Whether or not the trickster should spawn

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
ttt_oldman_spawn_weight                     1       // The weight assigned to spawning the old man
ttt_killer_spawn_weight                     1       // The weight assigned to spawning the killer
ttt_zombie_spawn_weight                     1       // The weight assigned to spawning the zombie
ttt_trickster_spawn_weight                  1       // The weight assigned to spawning the trickster
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
ttt_oldman_min_players                      0       // The minimum number of players required to spawn the old man
ttt_killer_min_players                      0       // The minimum number of players required to spawn the killer
ttt_zombie_min_players                      0       // The minimum number of players required to spawn the zombie
ttt_trickster_min_players                   0       // The minimum number of players required to spawn the trickster

// ----------------------------------------

// TRAITOR TEAM SETTINGS
ttt_traitor_vision_enable                   0       // Whether members of the traitor team can see other members of the traitor team (including Glitches) through walls via a highlight effect

// Impersonator
ttt_impersonator_damage_penalty             0       // Damage penalty that the impersonator has before being promoted (e.g. 0.5 = 50% less damage)
ttt_impersonator_credits_starting           1       // The number of credits an impersonator should start with
ttt_impersonator_use_detective_icon         1       // Whether a promoted impersonator should show the detective icon over their head instead of the impersonator icon (only for traitors, non-traitors will use the equivalent deputy setting)
ttt_single_deputy_impersonator              0       // Whether only a single deputy or impersonator should spawn in a round

// Hypnotist
ttt_hypnotist_credits_starting              1       // The number of credits a hypnotist should start with

// Assassin
ttt_assassin_show_target_icon               0       // Whether assassins have an icon over their target's heads showing who to kill. Server or round must be restarted for changes to take effect
ttt_assassin_next_target_delay              2       // The delay (in seconds) before an assassin is assigned their next target
ttt_assassin_target_damage_bonus            1       // Damage bonus that the assassin has against their target (e.g. 0.5 = 50% extra damage)
ttt_assassin_wrong_damage_penalty           0.5     // Damage penalty that the assassin has when attacking someone who is not their target (e.g. 0.5 = 50% less damage)
ttt_assassin_failed_damage_penalty          0.5     // Damage penalty that the assassin has after they have failed their contract by killing the wrong person (e.g. 0.5 = 50% less damage)
ttt_assassin_shop_roles_last                0       // Whether the assassin should target the shop roles right before Detective or not
ttt_assassin_credits_starting               1       // The number of credits an assassin should start with

// Vampire
ttt_vampires_are_monsters                   0       // Whether vampires should be treated as members of the Monster team.
ttt_vampire_vision_enable                   0       // Whether vampires have their special vision highlights enabled
ttt_vampire_drain_enable                    1       // Whether vampires have the ability to drain other players' blood using their fangs
ttt_vampire_convert_enable                  0       // Whether vampires have the ability to convert other players to vampire thrals using their fangs
ttt_vampire_show_target_icon                0       // Whether vampires have an icon over other players' heads showing who to kill. Server or round must be restarted for changes to take effect.
ttt_vampire_damage_reduction                0       // The fraction an attacker's bullet damage will be reduced by when they are shooting a vampire.
ttt_vampire_fang_timer                      5       // The amount of time fangs must be used to fully drain a target's blood
ttt_vampire_fang_heal                       50      // The amount of health a vVampire will heal by when they fully drain a target's blood
ttt_vampire_fang_overheal                   25      // The amount over the vampire's normal maximum health (e.g. 100 + this ConVar) that the vampire can heal to by drinking blood.
ttt_vampire_prime_death_mode                0       // What to do when the prime vampire(s) (e.g. playters who spawn as vampires originally) are killed. 0 - Do nothing. 1 - Kill all vampire thralls (non-prime vampires). 2 - Revert all vampire thralls (non-prime vampires) to their original role.
ttt_vampire_prime_only_convert              1       // Whether only prime vampires (e.g. players who spawn as vampire originally) are allowed to convert other players.
ttt_vampire_credits_starting                1       // The number of credits a vampire should start with

// Quack
ttt_quack_credits_starting                  1       // The number of credits a quack should start with
ttt_single_doctor_quack                     0       // Whether only a single doctor or quack should spawn in a round

// Parasite
ttt_parasite_infection_time                 90      // The time it takes in seconds for the parasite to fully infect someone
ttt_parasite_respawn_mode                   0       // The way in which the parasite respawns. 0 - Take over host. 1 - Respawn at the parasite's body. 2 - Respawn at a random location.
ttt_parasite_respawn_health                 100     // The health on which the parasite respawns
ttt_parasite_announce_infection             0       // Whether players are notified when they are infected with the parasite
ttt_parasite_credits_starting               1       // The number of credits a parasite should start with

// ----------------------------------------

// INNOCENT TEAM SETTINGS
// Detective
ttt_detective_search_only                   1       // Whether only detectives can search bodies or not
ttt_all_search_postround                    1       // Whether non-detectives can search bodies post-round or not

// Phantom
ttt_phantom_respawn_health                  50      // The amount of health a phantom will respawn with
ttt_phantom_weaker_each_respawn             0       // Whether a phantom respawns weaker (1/2 as much HP) each time they respawn, down to a minimum of 1
ttt_phantom_killer_smoke                    0       // Whether to show smoke on the player who killed the phantom
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
ttt_deputy_credits_starting                 0       // The number of credits a deputy should start with
ttt_deputy_use_detective_icon               1       // Whether a promoted deputy should show the detective icon over their head instead of the deputy icon

// Mercenary
ttt_mercenary_credits_starting              1       // The number of credits a mercenary should start with

// Veteran
ttt_veteran_damage_bonus                    0.5     // Damage bonus that the veteran has when they are the last innocent alive (e.g. 0.5 = 50% more damage)
ttt_veteran_full_heal                       1       // Whether the veteran gets a full heal upon becoming the last remaining innocent or not

// Doctor
ttt_doctor_mode                             0       // What tool the doctor starts with (0=Health Station, 1=Defib then Health Station)

// ----------------------------------------

// JESTER TEAM SETTINGS
ttt_jesters_trigger_traitor_testers         1       // Whether jesters trigger traitor testers as if they were traitors
ttt_jesters_visible_to_traitors             1       // Whether jesters are revealed (via head icons, color/icon on the scoreboard, etc.) to members of the traitor team
ttt_jesters_visible_to_monsters             1       // Whether jesters are revealed (via head icons, color/icon on the scoreboard, etc.) to members of the monster team
ttt_jesters_visible_to_independents         1       // Whether jesters are revealed (via head icons, color/icon on the scoreboard, etc.) to independent players

// Jester
ttt_jester_win_by_traitors                  1       // Whether the jester will win the round if they are killed by a traitor
ttt_jester_notify_mode                      0       // The logic to use when notifying players that a jester is killed. 0 - Don't notify anyone. 1 - Only notify traitors and detective. 2 - Only notify traitors. 3 - Only notify detective. 4 - Notify everyone.
ttt_jester_notify_sound                     0       // Whether to play a cheering sound when a jester is killed
ttt_jester_notify_confetti                  0       // Whether to throw confetti when a jester is a killed
ttt_jester_credits_starting                 0       // The number of credits a jester should start with

// Swapper
ttt_swapper_respawn_health                  100     // What amount of health to give the swapper when they are killed and respawned
ttt_swapper_weapon_mode                     1       // How to handle weapons when the Swapper is killed. 0 - Don't swap anything. 1 - Swap role weapons (if there are any). 2 - Swap all weapons.
ttt_swapper_notify_mode                     0       // The logic to use when notifying players that a swapper is killed. 0 - Don't notify anyone. 1 - Only notify traitors and detective. 2 - Only notify traitors. 3 - Only notify detective. 4 - Notify everyone.
ttt_swapper_notify_sound                    0       // Whether to play a cheering sound when a swapper is killed
ttt_swapper_notify_confetti                 0       // Whether to throw confetti when a swapper is a killed
ttt_swapper_killer_health                   100     // What amount of health to give the person who killed the swapper. Set to "0" to kill them
ttt_swapper_credits_starting                0       // The number of credits a swapper should start with

// Clown
ttt_clown_damage_bonus                      0       // Damage bonus that the clown has after being activated (e.g. 0.5 = 50% more damage)
ttt_clown_activation_credits                0       // The number of credits to give the clown when they are activated
ttt_clown_hide_when_active                  0       // Whether the clown should be hidden from other players' Target ID (overhead icons) when they are activated. Server or round must be restarted for changes to take effect
ttt_clown_show_target_icon                  0       // Whether the clown has an icon over other players' heads showing who to kill. Server or round must be restarted for changes to take effect
ttt_clown_heal_on_activate                  0       // Whether the clown should fully heal when they activate or not
ttt_clown_credits_starting                  0       // The number of credits a clown should start with

// Beggar
ttt_beggar_reveal_change                    1       // Whether the beggar is revealed to you when they join your team or not
ttt_beggar_respawn                          0       // Whether the beggar respawns when they are killed before joining another team
ttt_beggar_respawn_delay                    3       // The delay to use when respawning the begger (if "ttt_beggar_respawn" is enabled)
ttt_beggar_notify_mode                      0       // The logic to use when notifying players that a beggar is killed. 0 - Don't notify anyone. 1 - Only notify traitors and detective. 2 - Only notify traitors. 3 - Only notify detective. 4 - Notify everyone.
ttt_beggar_notify_sound                     0       // Whether to play a cheering sound when a beggar is killed
ttt_beggar_notify_confetti                  0       // Whether to throw confetti when a beggar is a killed

// Bodysnatcher
ttt_bodysnatcher_destroy_body               0       // Whether the bodysnatching device destroys the body it is used on or not
ttt_bodysnatcher_show_role                  1       // Whether the bodysnatching device shows the role of the corpse it is used on or not

// ----------------------------------------

// INDEPENDENT TEAM SETTINGS
ttt_independents_trigger_traitor_testers    0       // Whether independents trigger traitor testers as if they were traitors

// Drunk
ttt_drunk_sober_time                        180     // Time in seconds for the drunk to remember their role
ttt_drunk_innocent_chance                   0.7     // Chance that the drunk will become an innocent when remembering their role

// Old Man
ttt_oldman_drain_health_to                  0       // The amount of health to drain the old man down to. Set to 0 to disable

// Killer
ttt_killer_knife_enabled                    1       // Whether the killer knife is enabled
ttt_killer_crowbar_enabled                  1       // Whether the killer throwable crowbar is enabled
ttt_killer_smoke_enabled                    1       // Whether the killer smoke is enabled
ttt_killer_smoke_timer                      60      // Number of seconds before a killer will start to smoke after their last kill
ttt_killer_show_target_icon                 1       // Whether killers have an icon over other players' heads showing who to kill. Server or round must be restarted for changes to take effect
ttt_killer_damage_penalty                   0.25    // The fraction a killer's damage will be scaled by when they are attacking without using their knife
ttt_killer_damage_reduction                 0       // The fraction an attacker's bullet damage will be reduced by when they are shooting a killer
ttt_killer_warn_all                         0       // Whether to warn all players if there is a killer. If 0, only traitors will be warned
ttt_killer_vision_enable                    1       // Whether killers have their special vision highlights enabled
ttt_killer_credits_starting                 2       // The number of credits a killer should start with

// Zombie
ttt_zombies_are_monsters                    0       // Whether zombies should be treated as members of the monster team.
ttt_zombies_are_traitors                    0       // Whether zombies should be treated as members of the traitors team.
ttt_zombie_round_chance                     0.1     // The chance that a "zombie round" will occur where all players who would have been traitors are made zombies instead. Only usable when "ttt_zombies_are_traitors" is set to "1"
ttt_zombie_vision_enable                    0       // Whether zombies have their special vision highlights enabled
ttt_zombie_spit_enable                      1       // Whether zombies have their spit attack enabled
ttt_zombie_leap_enable                      1       // Whether zombies have their leap attack enabled
ttt_zombie_show_target_icon                 0       // Whether zombies have an icon over other players' heads showing who to kill. Server or round must be restarted for changes to take effect.
ttt_zombie_damage_penalty                   0.5     // The fraction a zombie's damage will be scaled by when they are attacking without using their claws.
ttt_zombie_damage_reduction                 0       // The fraction an attacker's bullet damage will be reduced by when they are shooting a zombie.
ttt_zombie_prime_only_weapons               1       // Whether only prime zombies (e.g. players who spawn as zombies originally) are allowed to pick up weapons.
ttt_zombie_prime_attack_damage              65      // The amount of a damage a prime zombie (e.g. player who spawned as a zombie originally) does with their claws. Server or round must be restarted for changes to take effect.
ttt_zombie_prime_attack_delay               0.7     // The amount of time between claw attacks for a prime zombie (e.g. player who spawned as a zombie originally). Server or round must be restarted for changes to take effect.
ttt_zombie_prime_speed_bonus                0.35    // The amount of bonus speed a prime zombie (e.g. player who spawned as a zombie originally) should get when using their claws. Server or round must be restarted for changes to take effect.
ttt_zombie_thrall_attack_damage             45      // The amount of a damage a zombie thrall (e.g. non-prime zombie) does with their claws. Server or round must be restarted for changes to take effect.
ttt_zombie_thrall_attack_delay              1.4     // The amount of time between claw attacks for a zombie thrall (e.g. non-prime zombie). Server or round must be restarted for changes to take effect.
ttt_zombie_thrall_speed_bonus               0.15    // The amount of bonus speed a zombie thrall (e.g. non-prime zombie) should get when using their claws. Server or round must be restarted for changes to take effect.
ttt_zombie_respawn_health                   100     // The amount of health a player should respawn with when they are converted to a zombie thrall.

// ----------------------------------------

// WEAPON SHOP SETTINGS
// Random Shop Restriction Percent
ttt_shop_random_percent                     50      // The percent chance that a weapon in the shop will be not be shown
ttt_shop_random_position                    0       // Whether to randomize the position of the items in the shop

// Role Specific Random Shop Restriction Percent
ttt_traitor_shop_random_percent             0       // The percent chance that a weapon in the shop will be not be shown for traitors
ttt_detective_shop_random_percent           0       // The percent chance that a weapon in the shop will be not be shown for detectives
ttt_hypnotist_shop_random_percent           0       // The percent chance that a weapon in the shop will be not be shown for hypnotists
ttt_deputy_shop_random_percent              0       // The percent chance that a weapon in the shop will be not be shown for deputies
ttt_impersonator_shop_random_percent        0       // The percent chance that a weapon in the shop will be not be shown for impersonators
ttt_assassin_shop_random_percent            0       // The percent chance that a weapon in the shop will be not be shown for assassins
ttt_killer_shop_random_percent              0       // The percent chance that a weapon in the shop will be not be shown for killers
ttt_jester_shop_random_percent              0       // The percent chance that a weapon in the shop will be not be shown for jesters
ttt_swapper_shop_random_percent             0       // The percent chance that a weapon in the shop will be not be shown for swappers
ttt_zombie_shop_random_percent              0       // The percent chance that a weapon in the shop will be not be shown for zombies
ttt_vampire_shop_random_percent             0       // The percent chance that a weapon in the shop will be not be shown for vampires
ttt_clown_shop_random_percent               0       // The percent chance that a weapon in the shop will be not be shown for clowns
ttt_quack_shop_random_percent               0       // The percent chance that a weapon in the shop will be not be shown for quacks
ttt_parasite_shop_random_percent            0       // The percent chance that a weapon in the shop will be not be shown for parasites

// Enable/Disable Individual Role Random Shop Restrictions
ttt_traitor_shop_random_enabled             0       // Whether role shop randomization is enabled for traitors
ttt_detective_shop_random_enabled           0       // Whether role shop randomization is enabled for detectives
ttt_hypnotist_shop_random_enabled           0       // Whether role shop randomization is enabled for hypnotists
ttt_deputy_shop_random_enabled              0       // Whether role shop randomization is enabled for deputies
ttt_impersonator_shop_random_enabled        0       // Whether role shop randomization is enabled for impersonators
ttt_assassin_shop_random_enabled            0       // Whether role shop randomization is enabled for assassins
ttt_killer_shop_random_enabled              0       // Whether role shop randomization is enabled for killers
ttt_jester_shop_random_enabled              0       // Whether role shop randomization is enabled for jesters
ttt_swapper_shop_random_enabled             0       // Whether role shop randomization is enabled for swappers
ttt_zombie_shop_random_enabled              0       // Whether role shop randomization is enabled for zombies
ttt_vampire_shop_random_enabled             0       // Whether role shop randomization is enabled for vampires
ttt_clown_shop_random_enabled               0       // Whether role shop randomization is enabled for clowns
ttt_quack_shop_random_enabled               0       // Whether role shop randomization is enabled for quacks
ttt_parasite_shop_random_enabled            0       // Whether role shop randomization is enabled for parasites

// Role Sync (Server or round must be restarted for changes to take effect)
ttt_mercenary_shop_mode                     2       // What items are available to the mercenary in the shop (0=None, 1=Either detective OR traitor (aka Union), 2=Both detective AND traitor (aka Intersect), 3=Just detective, 4=Just traitor)
ttt_clown_shop_mode                         0       // What items are available to the clown in the shop (0=None, 1=Either detective OR traitor (aka Union), 2=Both detective AND traitor (aka Intersect), 3=Just detective, 4=Just traitor)
ttt_hypnotist_shop_sync                     0       // Whether Hypnotists should have all weapons that vanilla Traitors have in their weapon shop
ttt_impersonator_shop_sync                  0       // Whether Impersonators should have all weapons that vanilla Traitors have in their weapon shop
ttt_assassin_shop_sync                      0       // Whether Assassins should have all weapons that vanilla Traitors have in their weapon shop
ttt_vampire_shop_sync                       0       // Whether Vampires should have all weapons that vanilla Traitors have in their weapon shop (if they are a Traitor)
ttt_zombie_shop_sync                        0       // Whether Zombies should have all weapons that vanilla Traitors have in their weapon shop (if they are a Traitor)
ttt_quack_shop_sync                         0       // Whether Quacks should have all weapons that vanilla Traitors have in their weapon shop
ttt_parasite_shop_sync                      0       // Whether Parasites should have all weapons that vanilla Traitors have in their weapon shop

// ----------------------------------------

// OTHER SETTINGS
// Individual Role Starting Health
ttt_traitor_starting_health                 100     // The amount of health a traitor starts with
ttt_hypnotist_starting_health               100     // The amount of health the hypnotist starts with
ttt_impersonator_starting_health            100     // The amount of health the impersonator starts with
ttt_assassin_starting_health                100     // The amount of health the assassin starts with
ttt_vampire_starting_health                 100     // The amount of health the vampire starts with
ttt_quack_starting_health                   100     // The amount of health the quack starts with
ttt_parasite_starting_health                100     // The amount of health the parasite starts with
ttt_innocent_starting_health                100     // The amount of health an innocent starts with
ttt_detective_starting_health               100     // The amount of health the detective starts with
ttt_glitch_starting_health                  100     // The amount of health the glitch starts with
ttt_phantom_starting_health                 100     // The amount of health the phantom starts with
ttt_revenger_starting_health                100     // The amount of health the revenger starts with
ttt_deputy_starting_health                  100     // The amount of health the deputy starts with
ttt_mercenary_starting_health               100     // The amount of health the mercenary starts with
ttt_veteran_starting_health                 100     // The amount of health the veteran starts with
ttt_doctor_starting_health                  100     // The amount of health the doctor starts with
ttt_jester_starting_health                  100     // The amount of health the jester starts with
ttt_swapper_starting_health                 100     // The amount of health the swapper starts with
ttt_clown_starting_health                   100     // The amount of health the clown starts with
ttt_beggar_starting_health                  100     // The amount of health the beggar starts with
ttt_bodysnatcher_starting_health            100     // The amount of health the bodysnatcher starts with
ttt_drunk_starting_health                   100     // The amount of health the drunk starts with
ttt_oldman_starting_health                  1       // The amount of health the old man starts with
ttt_killer_starting_health                  150     // The amount of health the killer starts with
ttt_zombie_starting_health                  100     // The amount of health the zombie starts with
ttt_trickster_starting_health               100     // The amount of health the trickster starts with

// Individual Role Max Health
ttt_traitor_max_health                      100     // The maximum amount of health a traitor can have
ttt_hypnotist_max_health                    100     // The maximum amount of health the hypnotist can have
ttt_impersonator_max_health                 100     // The maximum amount of health the impersonator can have
ttt_assassin_max_health                     100     // The maximum amount of health the assassin can have
ttt_vampire_max_health                      100     // The maximum amount of health the vampire can have
ttt_quack_max_health                        100     // The maximum amount of health the quack can have
ttt_parasite_max_health                     100     // The maximum amount of health the parasite can have
ttt_innocent_max_health                     100     // The maximum amount of health an innocent can have
ttt_detective_max_health                    100     // The maximum amount of health the detective can have
ttt_glitch_max_health                       100     // The maximum amount of health the glitch can have
ttt_phantom_max_health                      100     // The maximum amount of health the phantom can have
ttt_revenger_max_health                     100     // The maximum amount of health the revenger can have
ttt_deputy_max_health                       100     // The maximum amount of health the deputy can have
ttt_mercenary_max_health                    100     // The maximum amount of health the mercenary can have
ttt_veteran_max_health                      100     // The maximum amount of health the veteran can have
ttt_doctor_max_health                       100     // The maximum amount of health the doctor can have
ttt_jester_max_health                       100     // The maximum amount of health the jester can have
ttt_swapper_max_health                      100     // The maximum amount of health the swapper can have
ttt_clown_max_health                        100     // The maximum amount of health the clown can have
ttt_beggar_max_health                       100     // The maximum amount of health the beggar can have
ttt_bodysnatcher_max_health                 100     // The maximum amount of health the bodysnatcher can have
ttt_drunk_max_health                        100     // The maximum amount of health the drunk can have
ttt_oldman_max_health                       1       // The maximum amount of health the old man can have
ttt_killer_max_health                       150     // The maximum amount of health the killer can have
ttt_zombie_max_health                       100     // The maximum amount of health the zombie can have
ttt_trickster_max_health                    100     // The maximum amount of health the trickster can have

// Logging
ttt_debug_logkills                          1       // Whether to log when a player is killed in the console
ttt_debug_logroles                          1       // Whether to log what roles players are assigned in the console

// Karma    
ttt_karma_jesterkill_penalty                50      // Karma penalty for killing the jester
ttt_karma_jesterdmg_ratio                   0.5     // Ratio of damage to jesters, to be taken from karma

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
