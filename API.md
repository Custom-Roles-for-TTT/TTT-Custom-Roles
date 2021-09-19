# Application Programming Interface (API)
## Table of Contents
1. [Overview](#Overview)
1. [Global Variables](#Global-Variables)
1. [Global Enumerations](#Global-Enumerations)
1. [Methods](#Methods)
   1. [Global](#Global)
   1. [Player](#Player)
   1. [Table](#Table)
1. [Hooks](#Hooks)
1. [SWEPs](#SWEPs)
   1. [SWEP Properties](#SWEP-Properties)
1. [Commands](#Commands)
   1. [Client Commands](#Client-Commands)
   1. [Server Commands](#Server-Commands)
1. [Net Messages](#Net-Messages)

## Overview
This document aims to explain the things that we have added to Custom Roles for TTT that are usable by other developers for integration.

## Global Variables
Variables available globally (within the defined realm)

**CAN_LOOT_CREDITS_ROLES** - Lookup table for whether a role can loot credits off of a corpse.\
*Realm:* Client and Server\
*Added in:* 1.0.5

**COLOR_INNOCENT** - Table of the default colors to use for the innocent role for each color type.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**COLOR_SPECIAL_INNOCENT** - Table of the default colors to use for the special innocent roles for each color type.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**COLOR_TRAITOR** - Table of the default colors to use for the traitor role for each color type.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**COLOR_SPECIAL_TRAITOR** - Table of the default colors to use for the special traitor roles for each color type.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**COLOR_DETECTIVE** - Table of the default colors to use for the detective role for each color type.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**COLOR_JESTER** - Table of the default colors to use for the jester roles for each color type.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**COLOR_INDEPENDENT** - Table of the default colors to use for the independent roles for each color type.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**COLOR_MONSTER** - Table of the default colors to use for the monster team for each color type.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**CR_VERSION** - The current version number for Custom Roles for TTT.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**DELAYED_SHOP_ROLES** - Lookup table for the roles whose shop purchases can be delayed.\
*Realm:* Client and Server\
*Added in:* 1.2.2

**ROLE_NONE** - Updated to be -1 so players who have not been given a role can be identified.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**ROLE_MAX** - The maximum role number.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**ROLE_EXTERNAL_START** - The role number where the externally-loaded roles start.\
*Realm:* Client and Server\
*Added in:* 1.0.10

**ROLE_STRINGS** - Table of title-case names for each role.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**ROLE_STRINGS_EXT** - Table of extended (e.g. prefixed by an article) names for each role.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**ROLE_STRINGS_PLURAL** - Table of pluralized names for each role.\
*Realm:* Client and Server\
*Added in:* 1.0.7

**ROLE_STRINGS_RAW** - Table of raw names for each role (used in convars).\
*Realm:* Client and Server\
*Added in:* 1.0.7

**ROLE_STRINGS_SHORT** - Table of short names for each role (used in icon names).\
*Realm:* Client and Server\
*Added in:* 1.0.0

**SHOP_ROLES** - Lookup table for whether a role has a shop.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**DEFAULT_ROLES** - Lookup table for whether a role is a default TTT role.\
*Realm:* Client and Server\
*Added in:* 1.0.3

**INDEPENDENT_ROLES** - Lookup table for whether a role is on the independent team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**INNOCENT_ROLES** - Lookup table for whether a role is on the innocent team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**JESTER_ROLES** - Lookup table for whether a role is on the jester team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**MONSTER_ROLES** - Lookup table for whether a role is on the monster team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**TRAITOR_BUTTON_ROLES** - Lookup table for whether a role can use traitor buttons.\
*Realm:* Client and Server\
*Added in:* 1.0.5

**TRAITOR_ROLES** - Lookup table for whether a role is on the traitor team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

## Global Enumerations
Enumerations available globally (within the defined realm). There are additional enumerations used internally for configuration and event reporting that are not included here. If you need them, for whatever reason, you will need to find them or ask one of the developers in Discord.

**ROLE_{ROLENAME}** - Every role that is added has its role number available as a global enum value. In addition, `ROLE_MAX` is defined as the highest role number assigned, `ROLE_NONE` is the role number a player is given before another role is assigned, and `ROLE_EXTERNAL_START` is the first role number assigned to roles defined outside of the code Custom Roles for TTT addon.\
*Realm:* Client and Server\
*Added in:* Whenever each role is added

**ROLE_CONVAR_TYPE_\*** - What type the convar for an external role is. Used by the ULX plugin to dynamically generate the configuration UI.\
*Realm:* Client and Server\
*Added in:* 1.0.11\
*Values:*
- ROLE_CONVAR_TYPE_NUM - A number. Will use a slider in the configuration UI.
- ROLE_CONVAR_TYPE_BOOL = A boolean. Will use a checkbox in the configuration UI.
- ROLE_CONVAR_TYPE_TEXT = A text value. Will use a text box in the configuration UI.

**ROLE_TEAM_\*** - Which team an external role is registered to.\
*Realm:* Client and Server\
*Added in:* 1.0.9\
*Values:*
- ROLE_TEAM_INNOCENT
- ROLE_TEAM_TRAITOR
- ROLE_TEAM_JESTER
- ROLE_TEAM_INDEPENDENT
- ROLE_TEAM_MONSTER *(Added in 1.1.7)*
- ROLE_TEAM_DETECTIVE *(Added in 1.1.3)*

## Methods

### *Global*
Methods available globally (within the defined realm)

**AssignAssassinTarget(ply, start, delay)** - Assigns the target player their next assassination target (if they are the assassin role).\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *ply* - The target player
- *start* - Whether this is running at the start of the round (Defaults to `false`).
- *delay* - Whether the assassin's target assignment is delayed (Defaults to false)

**CRVersion(version)** - Whether the current version is equal to or newer than the version number given.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *version* - The version number to compare against the currently installed version. Must be in the "#.#.#" format

**GetEquipmentItemById(id)** - Gets an equipment item's definition by their ID.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*\
*Parameters:*
- *id* - The ID of the equipment item being looked up (e.g. EQUIP_RADAR)

**GetEquipmentItemByName(name)** - Gets an equipment item's definition by their name.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *name* - The name of the equipment item being looked up

**Get{RoleName}Filter(aliveOnly)** - Dynamically created functions for each role that returns a function that filters net messages to players that are role. For example: `GetTraitorFilter()` and `GetPhantomFilter()` return a filter function that can be used to send a message to players who are a traitor or a phantom, respectively.\
*Realm:* Server\
*Added in:* Whenever each role is added\
*Parameters:*
- *aliveOnly* - Whether this filter should only include live players (Defaults to `false`).

**GetInnocentTeamFilter(aliveOnly)** - Returns a function that filters net messages to players that are on the innocent team.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *aliveOnly* - Whether this filter should only include live players (Defaults to `false`).

**GetJesterTeamFilter(aliveOnly)** - Returns a function that filters net messages to players that are on the jester team.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *aliveOnly* - Whether this filter should only include live players (Defaults to `false`).

**GetIndependentTeamFilter(aliveOnly)** - Returns a function that filters net messages to players that are on the independent team.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *aliveOnly* - Whether this filter should only include live players (Defaults to `false`).

**GetMonsterTeamFilter(aliveOnly)** - Returns a function that filters net messages to players that are on the monster team.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *aliveOnly* - Whether this filter should only include live players (Defaults to `false`).

**GetRoleTeamColor(roleTeam, type)** - Gets the color belonging to the specified role team (see ROLE_TEAM_* global enumeration).\
*Realm:* Client\
*Added in:* 1.1.8\
*Parameters:*
- *roleTeam* - Which team role to get the color for (see ROLE_TEAM_* global enumeration).
- *type* - The color modification type. Options are: "dark", "highlight", "radar", "scoreboard", or "sprite". (Optional)

**GetSprintMultiplier(ply, sprinting)** - Gets the given player's current sprint multiplier.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *ply* - The target player
- *sprinting* - Whether the player is currently sprinting

**GetTeamRoles(team_table, exclude)** - Gets a table of role numbers that belong to the team whose lookup table is given.\
*Realm:* Client and Server\
*Added in:* 1.0.2\
*Parameters:*
- *team_table* - Team lookup table
- *exclude* - Lookup table of roles to exclude from the team (Optional).

**GetTraitorTeamFilter(aliveOnly)** - Returns a function that filters net messages to players that are on the traitor team.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *aliveOnly* - Whether this filter should only include live players (Defaults to `false`).

**RegisterRole(roleTable)** - Registers a role with Custom Roles for TTT. See [here](CREATE_YOUR_OWN_ROLE.md) for instructions on how to create a role and role table structure.\
*Realm:* Client and Server\
*Added in:* 1.0.9

**SetRoleHealth(ply)** - Sets the target player's health and max health based on their role convars.\
*Realm:* Client and Server\
*Added in:* 1.0.3\
*Parameters:*
- *ply* - The target player

**SetRoleMaxHealth(ply)** - Sets the target player's max health based on their role convars.\
*Realm:* Client and Server\
*Added in:* 1.0.15\
*Parameters:*
- *ply* - The target player

**SetRoleStartingHealth(ply)** - Sets the target player's health based on their role convars.\
*Realm:* Client and Server\
*Added in:* 1.0.15\
*Parameters:*
- *ply* - The target player

**ShouldHideJesters(ply)** - Whether the target player should hide a jester player's role (in radar, on the scoreboard, in target ID, etc.).\
*Realm:* Client and Server\
*Added in:* 1.2.3\
*Parameters:*
- *ply* - The target player

**ShouldPromoteDetectiveLike()** - Whether an unpromoted detective-like player (deputy/impersonator) should be promoted.\
*Realm:* Server\
*Added in:* 1.2.5

**StartsWithVowel(str)** - Whether the given string starts with a vowel.\
*Realm:* Client and Server\
*Added in:* 1.0.8

**UpdateRoleColours()/UpdateRoleColors()** - Updates the role color tables based on the color convars and color type convar.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**UpdateRoleStrings()** - Updates the role string tables based on the role name convars.\
*Realm:* Client and Server\
*Added in:* 1.0.7

**UpdateRoleWeaponState()** - Enables and disables weapons based on which roles are enabled.\
*Realm:* Client and Server\
*Added in:* 1.0.5

**UpdateRoleState()** - Updates the team membership, colors, and weapon state based on which roles are enabled and belong to which teams.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### *Player*
Variables available when called from a Player object (within the defined realm)

**plymeta:BeginRoleChecks()** - Sets up role logic for the player to handle role-specific events and checks.\
*Realm:* Server\
*Added in:* 1.1.9

**plymeta:Is{RoleName}()/plymeta:Get{RoleName}()** - Dynamically created functions for each role that returns whether the player is that role. For example: `plymeta:IsTraitor()` and `plymeta:IsPhantom()` return whether the player is a traitor or a phantom, respectively.\
*Realm:* Client and Server\
*Added in:* Whenever each role is added

**plymeta:IsActive{RoleName}()** - Dynamically created functions for each role that returns whether `plymeta:Is{RoleName}` returns `true` and the player is active. For example: `plymeta:IsActiveTraitor()` and `plymeta:IsActivePhantom()` return whether the player is active and a traitor or a phantom, respectively.\
*Realm:* Client and Server\
*Added in:* Whenever each role is added

**plymeta:IsActiveCustom()** - Whether `plymeta:IsCustom` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsActiveDetectiveLike()** - Whether `plymeta:IsActiveDetectiveLike` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsActiveIndependentTeam()** - Whether `plymeta:IsIndependentTeam` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsActiveInnocentTeam()** - Whether `plymeta:IsInnocentTeam` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsActiveJesterTeam()** - Whether `plymeta:IsJesterTeam` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsActiveMonsterTeam()** - Whether `plymeta:IsMonsterTeam` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsActiveTraitorTeam()** - Whether `plymeta:IsTraitorTeam` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsActiveShopRole()** - Whether `plymeta:IsActiveShopRole` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:CanLootCredits(activeOnly)** - Whether the player can loot credits from a corpse that has them.\
*Realm:* Client and Server\
*Added in:* 1.0.5\
*Parameters:*
- *activeOnly* - Whether the player must also be active (Defaults to `false`)

**plymeta:CanUseShop()** - Whether the player can currently open the shop menu.\
*Realm:* Client and Server\
*Added in:* 1.0.2

**plymeta:CanUseTraitorButton(activeOnly)** - Whether the player can see and use traitor buttons.\
*Realm:* Client and Server\
*Added in:* 1.0.5\
*Parameters:*
- *activeOnly* - Whether the player must also be active (Defaults to `false`)

**plymeta:GetHeight()** - Gets the *estimated* height of the player based on their player model.\
*Realm:* Client\
*Added in:* 1.0.2

**plymeta:GetVampirePreviousRole()** - Gets the player's previous role if they are a Vampire that has been converted or `ROLE_NONE` otherwise.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:GiveDelayedShopItems()** - Give the player their shop items that were being held due to the role having a delayed shop.\
*Realm:* Server\
*Added in:* 1.2.2

**plymeta:HandleDetectiveLikePromotion()** - Handles the player's promotion as a detective-like role (deputy/impersonator). Promotes the player and sends necessary net events.\
*Realm:* Server\
*Added in:* 1.2.5

**plymeta:IsCustom()** - Whether the player's role is not one of the three default TTT roles.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsDetectiveLike()/plymeta:GetDetectiveLike()** - Whether the player's role is like a detective (e.g. detective or promoted deputy/impersonator).\
*Realm:* Client and Server\
*Added in:* 1.0.0\

**plymeta:IsDetectiveLikePromotable()/plymeta:GetDetectiveLikePromotable()** - Whether the player's role is an unpromoted detective-like role (deputy/impersonator).\
*Realm:* Client and Server\
*Added in:* 1.2.5\

**plymeta:IsIndependentTeam()** - Whether the player is on the independent team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsInnocentTeam()** - Whether the player is on the innocent team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsJesterTeam()** - Whether the player is on the jester team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsMonsterTeam()** - Whether the player is on the monster team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsRoleActive()** - Whether the player's role feature has been activated.\
*Realm:* Client and Server\
*Added in:* 1.2.2

**plymeta:IsSameTeam(target)** - Whether the player is on the same team as the target.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *target* - The other player whose team is being compared

**plymeta:IsShopRole()** - Whether the player has a shop (see `plymeta:CanUseShop` for determining if it is openable).\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsTraitorTeam()** - Whether the player is on the traitor team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsVampireAlly()/plymeta:GetVampireAlly()** - Whether the player is allied with the vampire role.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsVampirePrime()/plymeta:GetVampirePrime()** - Whether the player is the prime (e.g. first-spawned) vampire.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsZombieAlly()/plymeta:GetZombieAlly()** - Whether the player is allied with the zombie role.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsZombiePrime()/plymeta:GetZombiePrime()** - Whether the player is the prime (e.g. first-spawned) zombie.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:MoveRoleState(target, keepOnSource)** - Moves role state data (such as promotion and monster prime status) to the target.\
*Realm:* Client and Server\
*Added in:* 1.0.5\
*Parameters:*
- *target* - The player to move the role state data to
- *keepOnSource* - Wheter the source player should also keep the role state data (Defaults to `false`)

**plymeta:SetRoleAndBroadcast(role)** - Sets the player's role to the given one and (if called on the server) broadcasts the change to all clients for scoreboard tracking.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *role* - The role number to set this player to

**plymeta:SetVampirePreviousRole(previousRole)** - Sets the player's previous role for when they are turned into a vampire.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *previousRole* - The previous role this player had before becoming a vampire

**plymeta:SetVampirePrime(isPrime)** - Sets whether the player is a prime (e.g. first-spawned) vampire.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *isPrime* - Whether the player is a prime vampire

**plymeta:SetZombiePrime(isPrime)** - Sets whether the player is a prime (e.g. first-spawned) zombie.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *isPrime* - Whether the player is a prime zombie

**plymeta:ShouldActLikeJester()** - Whether the player should act like a jester (e.g. in what damage they do, what damage they take, how they appear to other players, etc.).\
*Realm:* Client and Server\
*Added in:* 1.2.5

**plymeta:ShouldDelayShopPurchase()** - Whether the player's shop purchase deliveries should be delayed.\
*Realm:* Client and Server\
*Added in:* 1.2.2

**plymeta:SoberDrunk(team)** - Runs the logic for when a drunk sobers up and remembers their role.\
*Realm:* Server\
*Added in:* 1.1.9\
*Parameters:*
- *team* - Which team to choose a role from (see ROLE_TEAM_* global enumeration)

**plymeta:DrunkRememberRole(role)** - Sets the drunk's role and runs required checks for that role.\
*Realm:* Server\
*Added in:* 1.1.9\
*Parameters:*
- *role* - Which role to set the drunk to (see ROLE_* global enumeration)

**plymeta:StripRoleWeapons()** - Strips all weapons from the player whose `Category` property matches the global `WEAPON_CATEGORY_ROLE` value.\
*Realm:* Client and Server\
*Added in:* 1.0.5

### *Table*
Methods created to help with the manipulation of tables

**table.ExcludedKeys(tbl, excludes)** - Returns new table that contains the keys not present as values in in the given exclude table.\
*Realm:* Client and Server\
*Added in:* 1.2.3
*Parameters:*
- *tbl* - The table whose keys are being inspected
- *excludes* - Table of values to exclude

**table.IntersectedKeys(first_tbl, second_tbl, excludes)** - Returns new table that contains the keys that are only present in both given tables, excluding those which appear as values in the given exclude table (if it is given).\
*Realm:* Client and Server\
*Added in:* 1.2.3
*Parameters:*
- *first_tbl* - The first table whose keys are being intersected
- *second_tbl* - The second table whose keys are being intersected
- *excludes* - Table of values to exclude from the intersect. (Optional)

**table.LookupKeys(tbl)** - Returns new table that contains the keys that have a truth-y value in the given table.\
*Realm:* Client and Server\
*Added in:* 1.2.3
*Parameters:*
- *tbl* - The table whose keys are being inspected

**table.ToLookup(tbl)** - Returns a new table whose keys are the values of the given table and whose values are all the literal boolean `true`. Used for fast lookups by key.\
*Realm:* Client and Server\
*Added in:* 1.2.3
*Parameters:*
- *tbl* - The table whose keys are being inspected

**table.UnionedKeys(first_tbl, second_tbl, excludes)** - Returns new table that contains a combination of the keys present in first table and the second table, excluding those which appear as values in the given exclude table (if it is given).\
*Realm:* Client and Server\
*Added in:* 1.2.3
*Parameters:*
- *first_tbl* - The first table whose keys are being unioned
- *second_tbl* - The second table whose keys are being unioned
- *excludes* - Table of values to exclude from the union. (Optional)

## Hooks
Custom and modified event hooks available within the defined realm

***NOTE:*** When using a hook with multiple return values, you *must* return a non-`nil` value for all properties up to the one(s) you are modifying or the hook results will be ignored entirely.

For example, if there is a hook that returns three parameters: `first`, `second`, and `third` and you want to modify the `second` parameter you must return the `first` parameter as non-`nil` as well, like this: `return first, newSecond`. Any return parameters after `second` can be omitted and the default value will be used.

**TTTCanIdentifyCorpse(ply, rag, wasTraitor)** - Changed `was_traitor` parameter to be `true` for any member of the traitor team, rather than just the traitor role.\
*Realm:* Server\
*Added in:* 1.0.5\
*Parameters:*
- *ply* - The player who is attempting to identify a corpse
- *rag* - The ragdoll being identified
- *wasTraitor* - Whether the player who the targetted ragdoll represents belonged to the traitor team

*Return:* Whether or not the given player should be able to identify the given corpse (Defaults to `false`).

**TTTPrintResultMessage(type)** - Called before the round win results message is printed to the top-right corner of the screen. Can be used to print a replacement message for custom win types that this would not normally handle.\
*Realm:* Server\
*Added in:* 1.0.14\
*Parameters:*
- *type* - The round win type

*Return:* `true` if the default print messages should be skipped (Defaults to `false`).

**TTTRadarPlayerRender(client, tgt, color, hidden)** - Called before a target's radar ping is rendered, allowing the color and whether the ping should be shown to be changed.\
*Realm:* Client\
*Added in:* 1.2.3\
*Parameters:*
- *client* - The local player
- *tgt* - The target player's radar data. Can contain the following properties:
  - `pos` - The target's position
  - `role` - The target's role, if any
  - `was_beggar` - If the target was a beggar but was converted to another role
  - `killer_clown_active` - whether the target is a Clown that has been activated
  - `sid64` - The [SteamID64](https://wiki.facepunch.com/gmod/Player:SteamID64) value of the target
  - The following properties can be added (only one or the other) to `tgt` to change what is displayed with the radar ping
    - `nick` - A string value that will be shown under the radar ping circle
    - `t` - A time number value that will be calculated as the difference from "now" and shown in the "##:##" format
- *color* - The color that would normally be used for the radar ping for the target, if any
- *hidden* - Whether the radar ping for the target would normally be hidden

*Return:*
- *color* - The new color value to use or the original passed into the hook
- *hidden* - The new hidden value to use or the original passed into the hook

**TTTScoreboardPlayerName(ply, client, currentName)** - Called before a player's row in the scoreboard (tab menu) is shown, allowing the name to be changed.\
*Realm:* Client\
*Added in:* 1.1.9\
*Parameters:*
- *ply* - The player being rendered
- *client* - The local player
- *currentName* - The current name string (including extra information)

*Return:*
- *name* - The new name value to show on the scoreboard

**TTTScoreboardPlayerRole(ply, client, color, roleFileName)** - Called before a player's row in the scoreboard (tab menu) is shown, allowing the colors and icon to be changed.\
*Realm:* Client\
*Added in:* 1.1.9\
*Parameters:*
- *ply* - The player being rendered
- *client* - The local player
- *color* - The background [Color](https://wiki.facepunch.com/gmod/Global.Color) to use
- *roleFileName* - The portion of the scoring icon path that indicates which role it belongs to. Used in the following icon path pattern: "vgui/ttt/tab_{roleFileName}.png"

*Return:*
- *color* - The new color value to use or the original passed into the hook
- *roleFileName* - The new roleFileName value to use or the original passed into the hook
- *flashRole* - If a valid role is provided, this will cause the target player's scoreboard role to have a flashing border in the given role's color (see ROLE_* global enumeration)

**TTTScoringSummaryRender(ply, roleFileName, groupingRole, roleColor, nameLabel)** - Called before the round summary screen is shown. Used to modify the color, position, and icon for a player.\
*Realm:* Client\
*Added in:* 1.1.5\
*Parameters:*
- *ply* - The player being rendered
- *roleFileName* - The portion of the scoring icon path that indicates which role it belongs to. Used in the following icon path pattern: "vgui/ttt/score_{roleFileName}.png"
- *groupingRole* - The role to use when determining the section to of the summary screen to put this player in
- *roleColor* - The background [Color](https://wiki.facepunch.com/gmod/Global.Color) to use behind the role icon
- *nameLabel* - The name that is going to be used for this player on the round summary *(Added in 1.2.3)*

*Return:*
- *roleFileName* - The new roleFileName value to use or the original passed into the hook
- *groupingRole* - The new groupingRole value to use or the original passed into the hook
- *roleColor* - The new roleColor value to use or the original passed into the hook
- *newName* - The new nameLabel value to use for the original passed into the hook *(Added in 1.2.3)*

**TTTScoringWinTitle(wintype, wintitles, title, secondaryWinRole)** - Called before each round summary screen is shown with the winning team. Return the win title object to use on the summary screen.\
*Realm:* Client\
*Added in:* 1.0.14\
*Parameters:*
- *wintype* - The round win type
- *wintitles* - Table of default win title parameters
- *title* - The currently selected win title
- *secondaryWinRole* - Which role (if any) is sharing the win for this round (see ROLE_* global enumeration) *(Added in 1.1.9)*

*Return:*
- *newTitle*
  - *txt* - The translation string to use to get the winning team text
  - *c* - The background [Color](https://wiki.facepunch.com/gmod/Global.Color) to use
  - *params* - Any parameters to use when translating `txt` (Optional if `new_secondary_win_role` is also omitted)
- *newSecondaryWinRole* - Which role should share in the win for this round (see ROLE_* global enumeration) (Optional) *(Added in 1.1.9)*

**TTTSelectRoles(choices, prevRoles)** - Called before players are randomly assigned roles. If a player is assigned a role during this hook, they will not be randomly assigned one later.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *choices* - The table of players who will be assigned roles
- *prevRoles* - The table whose keys are role numbers and values are tables of players who had that role last round

**TTTSelectRolesDetectiveOptions(roleTable, choices, choiceCount, traitors, traitorCount)** - Called before players are assigned a detective role, allowing the available roles and their weights (how many times they appear in the table) to be manipulated.\
*Realm:* Server\
*Added in:* 1.2.3\
*Parameters:*
- *roleTable* - The table of roles representing the available detective roles and their weight (how many times they appear in the table). This table should be manipulated to effect change
- *choices* - The table of available player choices that will not be (and have not already been) assigned a traitor or detective role. Manipulating this table will have no effect
- *choiceCount* - The total number of player choices there are
- *traitors* - The table of available player choices that will be (or have already been) assigned a traitor role. Manipulating this table will have no effect
- *traitorCount* - The number of players that will be (or have already been) assigned a traitor role
- *detectives* - The table of available player choices that will be (or have already been) assigned a detective role. Manipulating this table will have no effect
- *detectiveCount* - The number of players that will be (or have already been) assigned a detective role

**TTTSelectRolesIndependentOptions(roleTable, choices, choiceCount, traitors, traitorCount)** - Called before players are assigned a independent role, allowing the available roles and their weights (how many times they appear in the table) to be manipulated.\
*Realm:* Server\
*Added in:* 1.2.3\
*Parameters:*
- *roleTable* - The table of roles representing the available independent roles and their weight (how many times they appear in the table). This table should be manipulated to effect change
- *choices* - The table of available player choices that will not be (and have not already been) assigned a traitor or detective role. Manipulating this table will have no effect
- *choiceCount* - The total number of player choices there are
- *traitors* - The table of available player choices that will be (or have already been) assigned a traitor role. Manipulating this table will have no effect
- *traitorCount* - The number of players that will be (or have already been) assigned a traitor role
- *detectives* - The table of available player choices that will be (or have already been) assigned a detective role. Manipulating this table will have no effect
- *detectiveCount* - The number of players that will be (or have already been) assigned a detective role

**TTTSelectRolesInnocentOptions(roleTable, choices, choiceCount, traitors, traitorCount)** - Called before players are assigned an innocent role, allowing the available roles and their weights (how many times they appear in the table) to be manipulated.\
*Realm:* Server\
*Added in:* 1.2.3\
*Parameters:*
- *roleTable* - The table of roles representing the available innocent roles and their weight (how many times they appear in the table). This table should be manipulated to effect change
- *choices* - The table of available player choices that will not be (and have not already been) assigned a traitor or detective role. Manipulating this table will have no effect
- *choiceCount* - The total number of player choices there are
- *traitors* - The table of available player choices that will be (or have already been) assigned a traitor role. Manipulating this table will have no effect
- *traitorCount* - The number of players that will be (or have already been) assigned a traitor role
- *detectives* - The table of available player choices that will be (or have already been) assigned a detective role. Manipulating this table will have no effect
- *detectiveCount* - The number of players that will be (or have already been) assigned a detective role

**TTTSelectRolesJesterOptions(roleTable, choices, choiceCount, traitors, traitorCount)** - Called before players are assigned a jester role, allowing the available roles and their weights (how many times they appear in the table) to be manipulated.\
*Realm:* Server\
*Added in:* 1.2.3\
*Parameters:*
- *roleTable* - The table of roles representing the available jester roles and their weight (how many times they appear in the table). This table should be manipulated to effect change
- *choices* - The table of available player choices that will not be (and have not already been) assigned a traitor or detective role. Manipulating this table will have no effect
- *choiceCount* - The total number of player choices there are
- *traitors* - The table of available player choices that will be (or have already been) assigned a traitor role. Manipulating this table will have no effect
- *traitorCount* - The number of players that will be (or have already been) assigned a traitor role
- *detectives* - The table of available player choices that will be (or have already been) assigned a detective role. Manipulating this table will have no effect
- *detectiveCount* - The number of players that will be (or have already been) assigned a detective role

**TTTSelectRolesMonsterOptions(roleTable, choices, choiceCount, traitors, traitorCount)** - Called before players are assigned a monster role, allowing the available roles and their weights (how many times they appear in the table) to be manipulated.\
*Realm:* Server\
*Added in:* 1.2.3\
*Parameters:*
- *roleTable* - The table of roles representing the available monster roles and their weight (how many times they appear in the table). This table should be manipulated to effect change
- *choices* - The table of available player choices that will not be (and have not already been) assigned a traitor or detective role. Manipulating this table will have no effect
- *choiceCount* - The total number of player choices there are
- *traitors* - The table of available player choices that will be (or have already been) assigned a traitor role. Manipulating this table will have no effect
- *traitorCount* - The number of players that will be (or have already been) assigned a traitor role
- *detectives* - The table of available player choices that will be (or have already been) assigned a detective role. Manipulating this table will have no effect
- *detectiveCount* - The number of players that will be (or have already been) assigned a detective role

**TTTSelectRolesTraitorOptions(roleTable, choices, choiceCount, traitors, traitorCount)** - Called before players are assigned a traitor role, allowing the available roles and their weights (how many times they appear in the table) to be manipulated.\
*Realm:* Server\
*Added in:* 1.2.3\
*Parameters:*
- *roleTable* - The table of roles representing the available traitor roles and their weight (how many times they appear in the table). This table should be manipulated to effect change
- *choices* - The table of available player choices that will not be (and have not already been) assigned a traitor or detective role. Manipulating this table will have no effect
- *choiceCount* - The total number of player choices there are
- *traitors* - The table of available player choices that will be (or have already been) assigned a traitor role. Manipulating this table will have no effect
- *traitorCount* - The number of players that will be (or have already been) assigned a traitor role
- *detectives* - The table of available player choices that will be (or have already been) assigned a detective role. Manipulating this table will have no effect
- *detectiveCount* - The number of players that will be (or have already been) assigned a detective role

**TTTSpeedMultiplier(ply, mults)** - Called when determining what speed the player should be moving at.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *ply* - The target player
- *mults* - The table of speed multipliers that should be applied to this player. Insert any multipliers you would like to apply to the target player into this table

**TTTSprintStaminaPost(ply, stamina, sprintTimer, consumption)** - Called after a player's sprint stamina is reduced. Return value is the new stamina value for the player.\
*Realm:* Client\
*Added in:* 1.0.2\
*Parameters:*
- *ply* - Player whose stamina is being adjusted
- *stamina* - Player's currents stamina
- *sprintTimer* - Time representing when the player last sprinted
- *consumption* - The stamina consumption rate

*Return:* The stamina value to assign to the player. If none is provided, the player's stamina will not be changed.

**TTTTargetIDPlayerKillIcon(ply, client, showKillIcon, showJester)** - Called before player Target ID icon (over their head) is rendered to determine if the "KILL" icon should be shown.\
*Realm:* Client\
*Added in:* 1.1.9\
*Parameters:*
- *ply* - The target player being rendered
- *client* - The local player
- *showKillIcon* - Whether the kill icon would normally be shown for this player
- *showJester* - Whether the target is a jester and the local player would normally know that

*Return:* `true` if the kill icon should be shown or `false` if not. Returning nothing or a non-boolean value will default to the given *showKillIcon* value.

**TTTTargetIDPlayerRing(ent, client, ringVisible)** - Called before a player Target ID ring (shown when you look at a player) is rendered.\
*Realm:* Client\
*Added in:* 1.2.3\
*Parameters:*
- *ent* - The target entity being rendered. Not necessarily a player so be sure to check `ent:IsPlayer()` if needed
- *client* - The local player
- *ringVisible* - Whether the ring would normally be visible for this target

*Return:*
- *newVisible* - The new ringVisible value to use or the original passed into the hook
- *colorOverride* - The [Color](https://wiki.facepunch.com/gmod/Global.Color) to use for the ring. Return `false` if you don't want to override the color. *NOTE:* For some reason colors that are near-black do not render so try a lighter color if you are having trouble

**TTTTargetIDPlayerRoleIcon(ply, client, role, noZ, colorRole, hideBeggar, showJester)** - Called before player Target ID icon (over their head) is rendered allowing changing the icon and color shown.\
*Realm:* Client\
*Added in:* 1.1.9\
*Parameters:*
- *ply* - The target player being rendered
- *client* - The local player
- *role* - What role is currently being shown for the target player
- *noZ* - Whether the icon is currently visible through walls
- *colorRole* - What role is being used for the icon background color (Only used when a different color than the only belonging to *role* is being used)
- *hideBeggar* - Whether the target was a beggar whose new role should be hidden
- *showJester* - Whether the target is a jester and the local player would normally know that

*Return:*
- *role* - The new role value to use or the original passed into the hook. Return `false` to stop the icon from being rendered
- *noZ* - The new noZ value to use or the original passed into the hook. *NOTE:* The matching icon .vmt for this flag needs to exist. If *noZ* is `true`, a "sprite\_{ROLESHORTNAME}\_noz.vmt" file must exist and if *noZ* is `false`, a "sprite_{ROLESHORTNAME}.vmt" file must exist
- *colorRole* - The new colorRole value to use or the original passed into the hook

**TTTTargetIDPlayerText(ent, client, text, clr, secondaryText)** - Called before player Target ID text (shown when you look at a player) is rendered.\
*Realm:* Client\
*Added in:* 1.1.9\
*Parameters:*
- *ent* - The target entity being rendered. Not necessarily a player so be sure to check `ent:IsPlayer()` if needed
- *client* - The local player
- *text* - The first line of text being shown
- *clr* - The color of the text being used
- *secondaryText* - The second line of text being shown

*Return:*
- *text* - The new text value to use or the original passed into the hook. Return `false` to not show text at all
- *clr* - The new clr value to use or the original passed into the hook
- *secondaryText* - The new secondaryText value to use or the original passed into the hook

## SWEPs
Changes made to SWEPs (the data structure used when defining new weapons)

### *SWEP Properties*

**SWEP.BlockShopRandomization** - Whether this weapon should block the shop randomization logic. Setting this to `true` will ensure this SWEP *always* shows in the applicable role's shop.\
*Added in:* 1.0.7

**SWEP.Category** - Updated so role weapons added by Custom Roles for TTT have a fixed global value: `WEAPON_CATEGORY_ROLE`. This is used to easily identify which weapons belong to specific roles.\
*Added in:* 1.0.5

**SWEP.EquipMenuData** - Updated so `name`, `type`, and `desc` properties can be parameterless functions to allow for parameterized translation.\
*Added in:* 1.0.8

**SWEP.ShopName** - The weapon name to use in the shop menu. If not provided, `SWEP.PrintName` is used instead.\
*Added in:* 1.1.9

## Commands

### *Client Commands*

**ttt_reset_weapons_cache** - Resets the client's equipment cache used in shop display. Useful when debugging changed shop rules.\
*Added in*: 1.0.11

### *Server Commands*

**ttt_kill_from_random** - Kills the local player by a random non-jester team player. *NOTE*: Cheats must be enabled to use this command.\
*Added in:* 1.0.0\
*Parameters:*
- *remove_body* - Whether to remove the local player's body after killing them (Defaults to `false`)

**ttt_kill_from_player** - Kills the local player by another player with the given name. *NOTE*: Cheats must be enabled to use this command.\
*Added in:* 1.0.0\
*Parameters:*
- *killer_name* - The name of the player who will kill the local player
- *remove_body* - Whether to remove the local player's body after killing them (Defaults to `false`)

**ttt_kill_target_from_random** - Kills the target player by a random non-jester team player. *NOTE*: Cheats must be enabled to use this command.\
*Added in:* 1.0.0\
*Parameters:*
- *target_name* - The name of the player who will be killed
- *remove_body* - Whether to remove the target player's body after killing them (Defaults to `false`)

**ttt_kill_target_from_player** - Kills the target player by another player with the given name. *NOTE*: Cheats must be enabled to use this command.\
*Added in:* 1.0.0\
*Parameters:*
- *target_name* - The name of the player who will be killed
- *killer_name* - The name of the player who will kill the target player
- *remove_body* - Whether to remove the target player's body after killing them (Defaults to `false`)

## Net Messages
Messages that the Custom Roles for TTT addon is set up to listen to in the defined realm.

**TTT_ResetBuyableWeaponsCache** - Resets the client's buyable weapons cache. This should be called if a weapon's CanBuy list has been updated.\
*Realm:* Client\
*Added in:* 1.0.0

**TTT_PlayerFootstep** - Adds a footstep to the list's list of footsteps to show.\
*Realm:* Client\
*Added in:* 1.0.0\
*Parameters:*
- *Entity* - The player whose footsteps are being recorded
- *Vector* - The position to place the footsteps at
- *Angle* - The angle to place the footsteps with
- *Bit* - Which foot's step is currently being recorded (0 = Left, 1 = Right)
- *Table* - The R, G, and B values of the color for the placed footstep
- *UInt(8)* - The amount of time (in seconds) before the footsteps should fade completely from view

**TTT_ClearPlayerFootsteps** - Resets the client's list of footsteps to show.\
*Realm:* Client\
*Added in:* 1.0.0

**TTT_RoleChanged** - Logs that a player's role has changed.\
*Realm:* Client\
*Added in:* 1.0.0
*Parameters:*
- *String* - The player's SteamID64 value
- *UInt (Versions <= 1.1.1), Int (Versions >= 1.1.2)* - The player's new role number

**TTT_UpdateRoleNames** - Causes the client to update their local role name tables based on convar values.\
*Realm:* Client\
*Added in:* 1.0.7