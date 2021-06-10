# Server Configurations

Add the following to your server config:

```cpp
// ----------------------------------------
// Custom Role Settings
// ----------------------------------------

// Weapon Shop
ttt_shop_random_percent     50 // The percent chance that a weapon in the shop will be not be shown
ttt_shop_random_tra_percent 0  // The percent chance that a weapon in the shop will be not be shown for the Traitors
ttt_shop_random_det_percent 0  // The percent chance that a weapon in the shop will be not be shown for the Detectives
ttt_shop_random_hyp_percent 0  // The percent chance that a weapon in the shop will be not be shown for the Hypnotists
ttt_shop_random_dep_percent 0  // The percent chance that a weapon in the shop will be not be shown for the Deputies
ttt_shop_random_imp_percent 0  // The percent chance that a weapon in the shop will be not be shown for the Impersonators
ttt_shop_random_tra_enabled 0  // Whether role shop randomization is enabled for Traitors
ttt_shop_random_det_enabled 0  // Whether role shop randomization is enabled for Detectives
ttt_shop_random_hyp_enabled 0  // Whether role shop randomization is enabled for Hypnotists
ttt_shop_random_dep_enabled 0  // Whether role shop randomization is enabled for Deputies
ttt_shop_random_imp_enabled 0  // Whether role shop randomization is enabled for Impersonators
ttt_shop_hypnotist_sync     0  // Whether Hypnotists should have all weapons that vanilla Traitors have in their weapon shop

// Phantom
ttt_phantom_respawn_health           50  // The amount of health a Phantom will respawn with
ttt_phantom_weaker_each_respawn      0   // Whether a Phantom respawns weaker (1/2 as much HP) each time they respawn, down to a minimum of 1
ttt_phantom_killer_smoke             1   // Whether to show smoke on the player who killed the Phantom
ttt_phantom_killer_footstep_time     0   // The amount of time a Phantom's killer's footsteps should show before fading. 0 to disable
ttt_phantom_announce_death           0   // Whether to announce to Detectives (and promoted Deputies and Imposters) that a Phantom has been killed or respawned
ttt_phantom_killer_haunt             1   // Whether to have the Phantom haunt their killer
ttt_phantom_killer_haunt_power_max   100 // The maximum amount of power a Phantom can have when haunting their killer
ttt_phantom_killer_haunt_power_rate  10  // The amount of power to regain per second when a Phantom is haunting their killer
ttt_phantom_killer_haunt_move_cost   25  // The amount of power to spend when a Phantom is moving their killer via a haunting. 0 to disable
ttt_phantom_killer_haunt_jump_cost   50  // The amount of power to spend when a Phantom is making their killer jump via a haunting. 0 to disable
ttt_phantom_killer_haunt_drop_cost   75  // The amount of power to spend when a Phantom is making their killer drop their weapon via a haunting. 0 to disable
ttt_phantom_killer_haunt_attack_cost 100 // The amount of power to spend when a Phantom is making their killer attack via a haunting. 0 to disable

// Jesters
ttt_jester_win_by_traitors  1   // Whether the Jester will win the round if they are killed by a traitor
ttt_jester_notify_mode      1   // The logic to use when notifying players that a Jester is killed. 0 - Don't notify anyone. 1 - Only notify Traitors and Detective. 2 - Only notify Traitors. 3 - Only notify Detective. 4 - Notify everyone.
ttt_jester_notify_sound     0   // Whether to play a cheering sound when a Jester is killed
ttt_jester_notify_confetti  0   // Whether to throw confetti when a Jester is a killed
ttt_swapper_respawn_health  100 // What amount of health to give the Swapper when they are killed and respawned
ttt_swapper_notify_mode     1   // The logic to use when notifying players that a Swapper is killed. 0 - Don't notify anyone. 1 - Only notify Traitors and Detective. 2 - Only notify Traitors. 3 - Only notify Detective. 4 - Notify everyone.
ttt_swapper_notify_sound    0   // Whether to play a cheering sound when a Swapper is killed
ttt_swapper_notify_confetti 0   // Whether to throw confetti when a Swapper is a killed
ttt_swapper_killer_health   100 // What amount of health to give the person who killed the Swapper. Set to "0" to kill them

// Other
ttt_traitor_vision_enable             0  // Whether members of the Traitor team can see other members of the Traitor team (including Glitches) through walls via a highlight effect.

// Logging
ttt_debug_logkills 1 // Whether to log when a player is killed in the console
ttt_debug_logroles 1 // Whether to log what roles players are assigned in the console
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

Equipment are items that a role can use that do not take up an equipment slot, such as the body armor or radar. To add equipment items to a role (that already has a shop), create a .txt file with the equipment item's name (e.g. "bruh bunker.txt") in the garrysmod/data/roleweapons/{rolename} folder.\
**NOTE**: If the _roleweapons_ folder does not already exist in garrysmod/data, create it.\
**NOTE**: The name of the role must be all lowercase for cross-operating system compatibility. For example: garrysmod/data/roleweapons/detective/bruh bunker.txt

## Finding an Equipment Item's Name

To find the name of an equipment item to use above, follow the steps below
1. Start a local server with TTT as the selected gamemode
2. Spawn 1 bot by using the _bot_ command in console
3. Obtain the equipment item whose name you want. If it is already available to buy from a certain role's shop, either force yourself to be that role via the _ttt\_force\_*_ commands or via a ULX plugin.
4. Run the following command in console to get a full list of your equipment item names: _lua\_run GetEquipmentItemById(EQUIP\_RADAR); lua\_run for id, e in pairs(EquipmentCache) do if player.GetHumans()[1]:HasEquipmentItem(id) then print(id .. " = " .. e.name) end end_
