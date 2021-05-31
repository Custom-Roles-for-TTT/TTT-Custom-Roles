# Server Configurations

Add the following to your server config:

```cpp
// ----------------------------------------
// Custom Role Settings
// ----------------------------------------

// Weapon Shop
ttt_shop_random_percent 50    // The percent chance that a weapon in the shop will be not be shown
ttt_shop_random_tra_percent 0 // The percent chance that a weapon in the shop will be not be shown for the Innocents
ttt_shop_random_det_percent 0 // The percent chance that a weapon in the shop will be not be shown for the Detectives
ttt_shop_random_hyp_percent 0 // The percent chance that a weapon in the shop will be not be shown for the Hypnotists
ttt_shop_random_dep_percent 0 // The percent chance that a weapon in the shop will be not be shown for the Deputies
ttt_shop_random_imp_percent 0 // The percent chance that a weapon in the shop will be not be shown for the Impersonators
ttt_shop_random_tra_enabled 0 // Whether role shop randomization is enabled for Innocents
ttt_shop_random_det_enabled 0 // Whether role shop randomization is enabled for Detectives
ttt_shop_random_hyp_enabled 0 // Whether role shop randomization is enabled for Hypnotists
ttt_shop_random_dep_enabled 0 // Whether role shop randomization is enabled for Deputies
ttt_shop_random_imp_enabled 0 // Whether role shop randomization is enabled for Impersonators
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