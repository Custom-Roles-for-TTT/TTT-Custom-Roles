# Application Programming Interface (API)
## Table of Contents
1. [Overview](#Overview)
1. [Global Variables](#Global-Variables)
1. [Global Enumerations](#Global-Enumerations)
1. [Methods](#Methods)
   1. [Global](#Global)
   1. [Player Object](#Player-Object)
   1. [Player Static](#Player-Static)
   1. [Table](#Table)
   1. [HUD](#HUD)
1. [Hooks](#Hooks)
1. [SWEPs](#SWEPs)
   1. [SWEP Properties](#SWEP-Properties)
1. [Commands](#Commands)
   1. [Client Commands](#Client-Commands)
   1. [Server Commands](#Server-Commands)
1. [Net Messages](#Net-Messages)

## Overview
This document aims to explain the things that we have added to Custom Roles for TTT that are usable by other developers for integration.

*NOTE:* Any entries in this document marked as *deprecated* will provide a version number where we will begin issuing a warning message in the server console if they are used. Anything marked as *deprecated* will be removed in the first beta version following the next major release from the deprecation version. For example: If something is marked as "deprecated in version 1.2.5" and the next released version number is 1.2.6 then that deprecated thing will be deleted in the beta version after that (1.2.7, for example).

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

**DEFAULT_ROLES** - Lookup table for whether a role is a default TTT role.\
*Realm:* Client and Server\
*Added in:* 1.0.3

**DELAYED_SHOP_ROLES** - Lookup table for the roles whose shop purchases can be delayed.\
*Realm:* Client and Server\
*Added in:* 1.2.2

**EVENT_MAX** - The maximum event identifier.\
*Realm:* Client and Server\
*Added in:* 1.2.5

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

**TRAITOR_BUTTON_ROLES** - Lookup table for whether a role can use traitor buttons.\
*Realm:* Client and Server\
*Added in:* 1.0.5

**TRAITOR_ROLES** - Lookup table for whether a role is on the traitor team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**WIN_MAX** - The maximum win state identifier.\
*Realm:* Client and Server\
*Added in:* 1.2.5

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

**ROLE_TEAM_\*** - Which role team an external role is registered to. A "role team" is a way of grouping roles by common functionality and mostly maps to the logical team with the exception of the detective role team. The detective role team is part of the innocent logical team.\
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
- *start* - Whether this is running at the start of the round (Defaults to `false`)
- *delay* - Whether the assassin's target assignment is delayed (Defaults to false)

**CRVersion(version)** - Whether the current version is equal to or newer than the version number given.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *version* - The version number to compare against the currently installed version. Must be in the "#.#.#" format

**GenerateNewEventID()** - Generates a new ID to be used for custom scoring events.\
*Realm:* Client and Server\
*Added in:* 1.2.5

**GenerateNewWinID()** - Generates a new ID to be used for custom win conditions.\
*Realm:* Client and Server\
*Added in:* 1.2.5

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
- *aliveOnly* - Whether this filter should only include live players (Defaults to `false`)

**GetInnocentTeamFilter(aliveOnly)** - Returns a function that filters net messages to players that are on the innocent team.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *aliveOnly* - Whether this filter should only include live players (Defaults to `false`)

**GetJesterTeamFilter(aliveOnly)** - Returns a function that filters net messages to players that are on the jester team.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *aliveOnly* - Whether this filter should only include live players (Defaults to `false`)

**GetIndependentTeamFilter(aliveOnly)** - Returns a function that filters net messages to players that are on the independent team.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *aliveOnly* - Whether this filter should only include live players (Defaults to `false`)

**GetMonsterTeamFilter(aliveOnly)** - Returns a function that filters net messages to players that are on the monster team.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *aliveOnly* - Whether this filter should only include live players (Defaults to `false`)

**GetRoleTeamColor(roleTeam, type)** - Gets the color belonging to the specified role team (see ROLE_TEAM_* global enumeration).\
*Realm:* Client\
*Added in:* 1.1.8\
*Parameters:*
- *roleTeam* - Which team role to get the color for (see ROLE_TEAM_* global enumeration)
- *type* - The color modification type. Options are: "dark", "highlight", "radar", "scoreboard", or "sprite". (Optional)

**GetRoleTeamInfo(roleTeam, simpleColor)** - Gets the name and color belonging to the specified role team (see ROLE_TEAM_* global enumeration).\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *roleTeam* - Which team role to get the color for (see ROLE_TEAM_* global enumeration)
- *simpleColor* - Whether to use simple team colors (e.g. all innocents are the same color and all traitors are the same color)

*Returns:*
- *roleTeamName* - The name of the provided role team
- *roleTeamColor* - The color of the provided role team

**GetRoleTeamName(roleTeam)** - Gets the name belonging to the specified role team (see ROLE_TEAM_* global enumeration).\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *roleTeam* - Which team role to get the color for (see ROLE_TEAM_* global enumeration)

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
- *exclude* - Lookup table of roles to exclude from the team (Optional)

**GetTraitorTeamFilter(aliveOnly)** - Returns a function that filters net messages to players that are on the traitor team.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *aliveOnly* - Whether this filter should only include live players (Defaults to `false`)

**JesterTeamKilledNotification(attacker, victim, getKillString, shouldShow)** - Used to disply a message, play a sound, and/or create confetti when a member of the jester team is killed. Automatically checks `ttt_%NAMERAW%_notify_mode`, `ttt_%NAMERAW%_notify_sound`, and `ttt_%NAMERAW%_notify_confetti` convars.\
*Realm:* Server\
*Added in:* 1.3.1\
*Parameters:*
- *attacker* - The player that killed the victim
- *victim* - The player that was killed
- *getKillString(ply)* - A callback function which returns the message that the player given as a parameter should be shown
- *shouldShow(ply)* - A callback function which returns whether the player given as a parameter should be shown a message (Optional, defaults to `true`)

**OnPlayerHighlightEnabled(client, alliedRoles, showJesters, hideEnemies, traitorAllies, onlyShowEnemies)** - Handles player highlighting (colored glow around players) rules for the local player.\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *client* - The local player
- *alliedRoles* - Table of role IDs that should show as allied to the current player
- *showJesters* - Whether jester roles should be highlighted in the jester color. If `false`, jesters will appear in the generic enemy color instead
- *hideEnemies* - Whether enemy roles (e.g. anyone that isn't an ally or a jester if *showJesters* is enabled) should be highlighted
- *traitorAllies* - Whether this role's allies are traitors. If `true`, allied roles will be shown in the traitor color. Otherwise allied roles will be shown in the innocent color
- *onlyShowEnemies* - Whether to only highlight players whose roles are explicitly enemies of the local player. If this is `true` then allies will not be highlighted. If both this and *showJesters* are `true` then neither allies nor jesters will be highlighted

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

### *Player Object*
Methods available when called from a Player object (within the defined realm)

**plymeta:BeginRoleChecks()** - Sets up role logic for the player to handle role-specific events and checks.\
*Realm:* Server\
*Added in:* 1.1.9

**plymeta:Celebrate(snd, showConfetti)** - Plays a celebration effect (sound and or confetti) at the player's location.\
*Realm:* Client\
*Added in:* 1.3.1\
*Parameters:*
- *snd* - What sound to play (if any) as part of this celebration
- *showConfetti* - Whether to show confetti as part of this celebration

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

**plymeta:GetRoleTeam(detectivesAreInnocent)** - Gets which "role team" a player belongs to (see ROLE_TEAM_* global enumeration).\
*Realm:* Client and Server\
*Added in:* 1.2.7\
*Parameters:*
- *detectivesAreInnocent* - Whether to include members of the detective "role team" in the innocent "role team" to match the logical teams

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
*Added in:* 1.0.0

**plymeta:IsDetectiveLikePromotable()/plymeta:GetDetectiveLikePromotable()** - Whether the player's role is an unpromoted detective-like role (deputy/impersonator).\
*Realm:* Client and Server\
*Added in:* 1.2.5

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

**plymeta:ShouldDelayAnnouncements()** - Whether this role should delay announcements when they kill a player that shows a message (like phantom and parasite). Used for things like preventing the assassin's target update message from getting overlapped.\
*Realm:* Client and Server\
*Added in:* 1.2.7

**plymeta:ShouldDelayShopPurchase()** - Whether the player's shop purchase deliveries should be delayed.\
*Realm:* Client and Server\
*Added in:* 1.2.2

**plymeta:ShouldHideJesters()** - Whether the player should hide a jester player's role (in radar, on the scoreboard, in target ID, etc.).\
*Realm:* Client and Server\
*Added in:* 1.2.5

**plymeta:ShouldRevealBeggar(tgt)** - Whether the player should reveal the fact that the target player is no longer a beggar (e.g. converted to an innocent or traitor).\
*Realm:* Client and Server\
*Added in:* 1.2.5\
*Parameters:*
- *tgt* - The target player beggar. If a value is not provided, the context player will be used instead (e.g. `ply:ShouldRevealBeggar()` is the same as `ply:ShouldRevealBeggar(ply)`)

**plymeta:ShouldRevealBodysnatcher(tgt)** - Whether the player should reveal the fact that the target player is no longer a bodysnatcher (e.g. has snatched a role from a dead body).\
*Realm:* Client and Server\
*Added in:* 1.2.5\
*Parameters:*
- *tgt* - The target player bodysnatcher. If a value is not provided, the context player will be used instead (e.g. `ply:ShouldRevealBodysnatcher()` is the same as `ply:ShouldRevealBodysnatcher(ply)`)

**plymeta:ShouldShowSpectatorHUD()** - Whether this player should currently be shown a spectator HUD. Used for things like the Phantom and Parasite spectator HUDs.\
*Realm:* Client and Server\
*Added in:* 1.3.1

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

**plymeta:SetPlayerScale(scale)** - Set's the players size by adjusting models, step sizes, hulls and view offsets.\
*Realm:* Server\
*Added in:* 1.3.1\
*Parameters:*
- *scale* - The value with which to scale the players size, relative to their current size.

**plymeta:ResetPlayerScale()** - Reset's the players size to default by adjusting models, step sizes, hulls and view offsets.\
*Realm:* Server\
*Added in:* 1.3.1

### *Player Static*
Methods available having to do with players but without needing a specific Player object

**player.AreTeamsLiving(ignorePassiveWinners)** - Returns whether the there are members of the various teams left alive.\
*Realm:* Client and Server\
*Added in:* 1.2.7\
*Parameters:*
- *ignorePassiveWinners* - Whether to ignore roles who win passively (like the old man) *(Added in 1.3.1)*

*Returns:*
- *traitor_alive* - Whether there are members of the traitor team left alive
- *innocent_alive* - Whether there are members of the innocent team left alive
- *indep_alive* - Whether there are members of the independent team left alive
- *monster_alive* - Whether there are members of the monster team left alive
- *jester_alive* - Whether there are members of the jester team left alive

**player.ExecuteAgainstTeamPlayers(roleTeam, detectivesAreInnocent, aliveOnly, callback)** - Executes a callback function against the players that are members of the specified "role team" (see ROLE_TEAM_* global enumeration).\
*Realm:* Client and Server\
*Added in:* 1.3.1\
*Parameters:*
- *roleTeam* - The "role team" whose members to execute the callback against (see ROLE_TEAM_* global enumeration)
- *detectivesAreInnocent* - Whether to include members of the detective "role team" in the innocent "role team" to match the logical teams
- *aliveOnly* - Whether to only include alive players
- *callback* - The function to execute against each "role team" player. Takes a player as the single argument

**player.GetLivingRole(role)** - Returns a single player that is alive and belongs to the given role (or `nil` if none exist). Useful when trying to get the player belonging to a role that can only occur once in a round.\
*Realm:* Client and Server\
*Added in:* 1.2.7\
*Parameters:*
- *role* - The desired role ID of the alive player to be found

**player.GetRoleTeam(role, detectivesAreInnocent)** - Gets which "role team" a role belongs to (see ROLE_TEAM_* global enumeration).\
*Realm:* Client and Server\
*Added in:* 1.2.7\
*Parameters:*
- *role* - The role ID in question
- *detectivesAreInnocent* - Whether to include members of the detective "role team" in the innocent "role team" to match the logical teams

**player.GetTeamPlayers(roleTeam, detectivesAreInnocent, aliveOnly)** - Returns a table containing the players that are members of the specified "role team" (see ROLE_TEAM_* global enumeration).\
*Realm:* Client and Server\
*Added in:* 1.3.1\
*Parameters:*
- *roleTeam* - The "role team" to find the members of (see ROLE_TEAM_* global enumeration)
- *detectivesAreInnocent* - Whether to include members of the detective "role team" in the innocent "role team" to match the logical teams
- *aliveOnly* - Whether to only include alive players

**player.IsRoleLiving(role)** - Returns whether a player belonging to the given role exists and is alive.\
*Realm:* Client and Server\
*Added in:* 1.2.7\
*Parameters:*
- *role* - The role ID in question

**player.LivingCount(ignorePassiveWinners)** - Returns the number of players left alive.\
*Realm:* Client and Server\
*Added in:* 1.3.1\
*Parameters:*
- *ignorePassiveWinners* - Whether to ignore roles who win passively (like the old man)

**player.TeamLivingCount(ignorePassiveWinners)** - Returns the number of members of the various teams left alive.\
*Realm:* Client and Server\
*Added in:* 1.3.1\
*Parameters:*
- *ignorePassiveWinners* - Whether to ignore roles who win passively (like the old man)

*Returns:*
- *traitor_alive* - The number of members of the traitor team left alive
- *innocent_alive* - The number of members of the innocent team left alive
- *indep_alive* - The number of members of the independent team left alive
- *monster_alive* - The number of members of the monster team left alive
- *jester_alive* - The number of members of the jester team left alive

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

### *HUD*
Helper methods that can be used when displaying client-side UIs

**HUD:PaintBar(r, x, y, w, h, colors, value)** - Paints a rounded bar that is some-percentaged filled. Can be used as a progress bar.\
*Realm:* Client\
*Added in:* 1.3.1\
*Parameters:*
- *r* - The amount the bar should be rounded
- *x* - The position from the left of the screen
- *y* - The position from the top of the screen
- *w* - The width of the bar
- *h* - The height of the bar
- *colors* - Object containing [Colors](https://wiki.facepunch.com/gmod/Color) to be used when displaying the bar
  - *background* - The background color of the bar
  - *fill* - The color to use to show the percentage of the bar filled
- *value* - The percent of the bar to be filled

**HUD:PaintPowersHUD(powers, max_power, current_power, colors, title, subtitle)** - Paints a HUD for showing available powers and their associated costs. Used for roles such as the Phantom.\
*Realm:* Client\
*Added in:* 1.3.1\
*Parameters:*
- *powers* - Table of key-value pairs where each key is the label for a power and the associated value is the cost of using it. The key can contain a `{num}` placeholder which will be replaced with the percentage of maximum power that the power costs
- *max_power* - The maximum amount of a power a player can have
- *current_power* - The current amount of power a player has
- *colors* - Object containing [Colors](https://wiki.facepunch.com/gmod/Color) to be used when displaying the powers
  - *background* - The background color of the progress bar used to show power level percentage
  - *fill* - The color to use for the current power level in the progress bar
- *title* - Title text to show within the power level progress bar
- *subtitle* - The sub-title text, used for hints, that is shown in small text above the power level progress bar

**HUD:ShadowedText(text, font, x, y, color, xalign, yalign)** - Renders text with an offset black background to emulate a shadow.\
*Realm:* Client\
*Added in:* 1.3.1\
*Parameters:*
- *text* - The text to render
- *font* - The name of the font to use
- *x* - The position from the left of the screen
- *y* - The position from the top of the screen
- *color* - The color to use for the rendered text
- *xalign* - The [TEXT_ALIGN](https://wiki.facepunch.com/gmod/Enums/TEXT_ALIGN) enum value to use for the horizontal alignment of the text
- *yalign* - The [TEXT_ALIGN](https://wiki.facepunch.com/gmod/Enums/TEXT_ALIGN) enum value to use for the vertical alignment of the text

## Hooks
Custom and modified event hooks available within the defined realm. A list of default TTT hooks is available [here](https://www.troubleinterroristtown.com/development/hooks/) but note that they may have been modified (see below).

***NOTE:*** When using a hook with multiple return values, you *must* return a non-`nil` value for all properties up to the one(s) you are modifying or the hook results will be ignored entirely.

For example, if there is a hook that returns three parameters: `first`, `second`, and `third` and you want to modify the `second` parameter you must return the `first` parameter as non-`nil` as well, like this: `return first, newSecond`. Any return parameters after `second` can be omitted and the default value will be used.

***NOTE:*** Be careful that you only return from a hook when you absolutely want to change something. Due to the way GMod hooks work, whichever hook instance returns first causes the *remaining hook instances to be completely skipped*. This is useful for certain hooks when you want to stop a behavior from happening, but it can also accidentally cause functionality to break because its code is completely ignored.

**TTTBlockPlayerFootstepSound(ply)** - Called when a player is making a footstep. Used to determine if the player's footstep sound should be stopped.\
*Realm:* Client and Server\
*Added in:* 1.2.7\
*Parameters:*
- *ply* - The player who is making footsteps

*Return:* Whether or not the given player's footstep sounds should be stopped (Defaults to `false`).

**TTTCanIdentifyCorpse(ply, rag, wasTraitor)** - Changed `was_traitor` parameter to be `true` for any member of the traitor team, rather than just the traitor role.\
*Realm:* Server\
*Added in:* 1.0.5\
*Parameters:*
- *ply* - The player who is attempting to identify a corpse
- *rag* - The ragdoll being identified
- *wasTraitor* - Whether the player who the targetted ragdoll represents belonged to the traitor team

*Return:* Whether or not the given player should be able to identify the given corpse (Defaults to `false`).

**TTTEventFinishText(e)** - Called before the event text for the "round finished" event is rendered in the end-of-round summary's Events tab.\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *e* - Event parameters. Contains the following properties:
  - `id` - The event identifier (always `EVENT_FINISH`)
  - `t` - The time when this event occurred
  - `win` - The win condition identifier

*Return:* Text to show in events list at the end of the round

**TTTEventFinishIconText(e, winString, roleString)** - Called before the event icon for the "round finished" event is rendered in the end-of-round summary's Events tab. Used to change the mouseover text for the icon.\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *e* - Event parameters. Contains the following properties:
  - `id` - The event identifier (always `EVENT_FINISH`)
  - `t` - The time when this event occurred
  - `win` - The win condition identifier
- *winString* - The translation string that will be used to display the icon mouseover text
- *roleString* - The role string to use in place of the `role` placeholder in the translation string

*Return:*
- *winString* - The new winString value to use or the original passed into the hook
- *roleString* - The new roleString value to use or the original passed into the hook

**TTTHUDInfoPaint(client, labelX, labelY)** - Called after player information such as role, health, and ammo and equipment information such as radar cooldown and disguiser activation are drawn on the screen. Used to write additional persistent text on the screen for player reference.\
*Realm:* Client\
*Added in:* 1.3.1\
*Parameters:*
- *client* - The local player
- *labelX* - The X value representing the correct indentation from the left side of the screen to add information
- *labelY* - The Y value representing the first clear space to add information

**TTTKarmaGiveReward(ply, reward, victim)** - Called before a player is rewarded with karma. Used to block a player's karma reward.\
*Realm:* Server\
*Added in:* 1.2.7\
*Parameters:*
- *ply* - The player who will be rewarded karma
- *reward* - The amount of karma the player will be rewarded with
- *victim* - The victim of the event that is rewarding the player with karma. If this is not a player, karma is being rewarded as part of the end of the round

*Return:* Whether or not the given player should be prevented from being rewarded with karma (Defaults to `false`).

**TTTKarmaShouldGivePenalty(attacker, victim)** - Called before a player's karma effect is decided. Used to determine if a player should be penalized or rewarded.\
*Realm:* Server\
*Added in:* 1.2.7\
*Parameters:*
- *attacker* - The player who hurt or killed the victim
- *victim* - The player who was hurt or killed

*Return:* `true` if the attacker should be penalized or `false` if they should not. If you have no opinion (e.g. let other logic determine this) then don't return anything at all.

**TTTPlayerAliveClientThink(client, ply)** - Called for each player who is alive during the Think hook.\
*Realm:* Client\
*Added in:* 1.3.1\
*Parameters:*
- *client* - The local player
- *ply* - The current alive player target

**TTTPlayerDefibRoleChange(ply, tgt)** - Called after a player has been resurrected by a device that also changes their role.\
*Realm:* Server\
*Added in:* 1.3.1\
*Parameters:*
- *ply* - The player using the resurrection device
- *tgt* - The target player being resurrected

**TTTPlayerRoleChanged(ply, oldRole, newRole)** - Called after a player's role has changed.\
*Realm:* Client and Server\
*Added in:* 1.2.7\
*Parameters:*
- *ply* - The player whose role is being changed
- *oldRole* - The role the player had before this change
- *newRole* - The role the player is changing to

**TTTPlayerSpawnForRound(ply, deadOnly)** - Called before a player is spawned for a round. Also used when reviving a player (via a defib, zombie conversion, etc.).\
*Realm:* Server\
*Added in:* 1.2.7\
*Parameters:*
- *ply* - The player who is being spawned or respawned
- *deadOnly* - Whether this call is specifically targetted at dead players

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
  - `was_bodysnatcher` - If the target was a bodysnatcher but was converted to another role
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

**TTTRadarRender(client)** - Called after non-player radar points are rendered and before players are rendered. Used for rendering custom non-player radar points.\
*Realm:* Client\
*Added in:* 1.3.1\
*Parameters:*
- *client* - The local player

**TTTRolePopupParams(client)** - Called before a player's role start-of-round popup message is displayed, allowing the parameters to be added to.\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *client* - The local player

*Return:*
- *params* - Table of name-value parameters to be used in this player's role start-of-round popup message

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
- *color* - The background [Color](https://wiki.facepunch.com/gmod/Color) to use
- *roleFileName* - The portion of the scoring icon path that indicates which role it belongs to. Used in the following icon path pattern: "vgui/ttt/tab_{roleFileName}.png"

*Return:*
- *color* - The new color value to use or the original passed into the hook
- *roleFileName* - The new roleFileName value to use or the original passed into the hook
- *flashRole* - If a valid role is provided, this will cause the target player's scoreboard role to have a flashing border in the given role's color (see ROLE_* global enumeration)

**TTTScoringSummaryRender(ply, roleFileName, groupingRole, roleColor, nameLabel, startingRole, finalRole)** - Called before the round summary screen is shown. Used to modify the color, position, and icon for a player.\
*Realm:* Client\
*Added in:* 1.1.5\
*Parameters:*
- *ply* - The player being rendered
- *roleFileName* - The portion of the scoring icon path that indicates which role it belongs to. Used in the following icon path pattern: "vgui/ttt/score_{roleFileName}.png"
- *groupingRole* - The role to use when determining the section to of the summary screen to put this player in
- *roleColor* - The background [Color](https://wiki.facepunch.com/gmod/Color) to use behind the role icon
- *nameLabel* - The name that is going to be used for this player on the round summary *(Added in 1.2.3)*
- *startingRole* - The role that this player started the round with *(Added in 1.2.7)*
- *finalRole* - The role that this player ended the round with *(Added in 1.2.7)*

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
  - *c* - The background [Color](https://wiki.facepunch.com/gmod/Color) to use
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
- *roleTable* - The table of roles representing the available independent roles (and jester roles, if ttt_single_jester_independent is enabled) and their weight (how many times they appear in the table). This table should be manipulated to effect change
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
- *roleTable* - The table of roles representing the available jester roles (and independent roles, if ttt_single_jester_independent is enabled) and their weight (how many times they appear in the table). This table should be manipulated to effect change
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

**TTTSpectatorHUDKeyPress(ply, tgt, powers)** - Called when a player who is being shown a role-specific spectator HUD presses a button, allowing the hook to intercept that button press and perform specific logic if necessary.\
*Realm:* Server\
*Added in:* 1.3.1\
*Parameters:*
- *ply* - The spectator player who is attemping to press a key
- *tgt* - The target playing being spectated
- *powers* - The table of key-value pairs of spectator powers where the key is the [IN](https://wiki.facepunch.com/gmod/Enums/IN) enum value of the desired button press and the value is an object with the following properties:
  - *start_command* - The console command to run to start the power effect
  - *end_command* - The console command to run to end the power effect
  - *time* - The amount of time before the end command should be run
  - *cost* - The cost of using this power

*Return:*
- *skip* - Whether the remaining spectator keypress logic should be skipped
- *power_property* - The NWInt property name to use when getting and updating the current spectator power level

**TTTSpectatorShowHUD(client, tgt)** - Called when a player should be shown a role-specific spectator HUD, allowing that role's logic to render the HUD as needed.\
*Realm:* Client\
*Added in:* 1.3.1\
*Parameters:*
- *client* - The local player
- *tgt* - The target playing being spectated

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

**TTTShouldPlayerSmoke(ply, client, shouldSmoke, smokeColor, smokeParticle, smokeOffset)** - .\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *ply* - The target player being rendered
- *client* - The local player
- *shouldSmoke* - Whether the player would normally emit smoke
- *smokeColor* - What [Color](https://wiki.facepunch.com/gmod/Color) the smoke will be. (Defaults to `COLOR_BLACK`)
- *smokeParticle* - What particle the smoke will use. Should be the relative path the the `.vmt` file for the particle. (Defaults to `"particle/snow.vmt"`)
- *smokeOffset* - A [Vector](https://wiki.facepunch.com/gmod/Vector) representing the relative offset from the player's feet. (Defaults to `Vector(0, 0, 30)`)

*Return:*
- *shouldSmoke* - The new shouldSmoke value to use or the original passed into the hook
- *smokeColor* - The new smokeColor value to use or the original passed into the hook
- *smokeParticle* - The new smokeParticle value to use or the original passed into the hook
- *smokeOffset* - The new smokeOffset value to use or the original passed into the hook

**TTTSyncGlobals()** - Called when the server is syncing convars to global variables for client access.\
*Realm:* Server\
*Added in:* 1.2.7

**TTTTargetIDPlayerHealth(ply, client, text, clr)** - Called before a player's heath status (shown when you look at a player) is rendered.\
*Realm:* Client\
*Added in:* 1.2.5\
*Parameters:*
- *ply* - The target player being rendered
- *client* - The local player
- *text* - The health-related text being shown
- *clr* - The [Color](https://wiki.facepunch.com/gmod/Color) of the text being used

*Return:*
- *text* - The new text value to use or the original passed into the hook. Return `false` to not show text at all
- *clr* - The new clr value to use or the original passed into the hook

**TTTTargetIDEntityHintLabel(ent, client, label, clr)** - Called before an entity's hint label (shown when you look at an entity) is rendered.\
*Realm:* Client\
*Added in:* 1.2.5\
*Parameters:*
- *ent* - The target entity being rendered. Guaranteed to not be a player.
- *client* - The local player
- *text* - The label for the hint-related text being shown
- *clr* - The [Color](https://wiki.facepunch.com/gmod/Color) of the text being used

*Return:*
- *text* - The new text value to use or the original passed into the hook. Return `false` to not show text at all
- *clr* - The new clr value to use or the original passed into the hook

**TTTTargetIDPlayerHintText(ent, client, text, clr)** - Called before an entity's hint text (shown when you look at an entity) is rendered.\
*Realm:* Client\
*Added in:* 1.2.5\
*Parameters:*
- *ent* - The target entity being rendered. Not necessarily a player so be sure to check `ent:IsPlayer()` if needed
- *client* - The local player
- *text* - The hint-related text being shown
- *clr* - The [Color](https://wiki.facepunch.com/gmod/Color) of the text being used

*Return:*
- *text* - The new text value to use or the original passed into the hook. Return `false` to not show text at all
- *clr* - The new clr value to use or the original passed into the hook

**TTTTargetIDPlayerKarma(ply, client, text, clr)** - Called before a player's karma status text (shown when you look at a player) is rendered.\
*Realm:* Client\
*Added in:* 1.2.5\
*Parameters:*
- *ply* - The target player being rendered
- *client* - The local player
- *text* - The karma-related text being shown
- *clr* - The [Color](https://wiki.facepunch.com/gmod/Color) of the text being used

*Return:*
- *text* - The new text value to use or the original passed into the hook. Return `false` to not show text at all
- *clr* - The new clr value to use or the original passed into the hook

**TTTTargetIDPlayerKillIcon(ply, client, showKillIcon, showJester)** - Called before player Target ID icon (over their head) is rendered to determine if the "KILL" icon should be shown.\
*Realm:* Client\
*Added in:* 1.1.9\
*Parameters:*
- *ply* - The target player being rendered
- *client* - The local player
- *showKillIcon* - Whether the kill icon would normally be shown for this player
- *showJester* - Whether the target is a jester and the local player would normally know that

*Return:* `true` if the kill icon should be shown or `false` if not. Returning nothing or a non-boolean value will default to the given *showKillIcon* value.

**TTTTargetIDPlayerName(ply, client, text, clr)** - Called before a player's name (shown when you look at a player) is rendered.\
*Realm:* Client\
*Added in:* 1.2.5\
*Parameters:*
- *ply* - The target player being rendered
- *client* - The local player
- *text* - The player's name text being shown
- *clr* - The [Color](https://wiki.facepunch.com/gmod/Color) of the text being used

*Return:*
- *text* - The new text value to use or the original passed into the hook. Return `false` to not show text at all
- *clr* - The new clr value to use or the original passed into the hook

**TTTTargetIDPlayerRing(ent, client, ringVisible)** - Called before an entity's Target ID ring (shown when you look at an entity) is rendered.\
*Realm:* Client\
*Added in:* 1.2.3\
*Parameters:*
- *ent* - The target entity being rendered. Not necessarily a player so be sure to check `ent:IsPlayer()` if needed
- *client* - The local player
- *ringVisible* - Whether the ring would normally be visible for this target

*Return:*
- *newVisible* - The new ringVisible value to use or the original passed into the hook
- *colorOverride* - The [Color](https://wiki.facepunch.com/gmod/Color) to use for the ring. Return `false` if you don't want to override the color. *NOTE:* For some reason colors that are near-black do not render so try a lighter color if you are having trouble

**TTTTargetIDPlayerRoleIcon(ply, client, role, noZ, colorRole, hideBeggar, showJester, hideBodysnatcher)** - Called before player Target ID icon (over their head) is rendered allowing changing the icon and color shown.\
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
- *hideBodysnatcher* - Whether the target is a bodysnatcher whose new role should be hidden *(Added in 1.2.5)*

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
- *clr* - The [Color](https://wiki.facepunch.com/gmod/Color) of the text being used
- *secondaryText* - The second line of text being shown

*Return:*
- *text* - The new text value to use or the original passed into the hook. Return `false` to not show text at all
- *clr* - The new clr value to use or the original passed into the hook
- *secondaryText* - The new secondaryText value to use or the original passed into the hook. Return `false` to not show text at all

**TTTTargetIDRagdollName(ent, client, text, clr)** - Called before a ragdoll's name (shown when you look at a ragdoll) is rendered.\
*Realm:* Client\
*Added in:* 1.2.5\
*Parameters:*
- *ent* - The target ragdoll being rendered
- *client* - The local player
- *text* - The ragdoll's name text being shown
- *clr* - The [Color](https://wiki.facepunch.com/gmod/Color) of the text being used

*Return:*
- *text* - The new text value to use or the original passed into the hook. Return `false` to not show text at all
- *clr* - The new clr value to use or the original passed into the hook

**TTTTutorialRoleEnabled(role)** - Called before a role's tutorial page is rendered. This can be used to allow a page to be shown when it normally would not be because the role is disabled. Useful for situations like showing the Zombie tutorial page when the Mad Scientist is enabled (because the Mad Scientist creates Zombies).\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *role* - Which role's tutorial page is being rendered

*Return:* `true` to show this page when it normally would not be

**TTTTutorialRolePage(role, parentPanel, titleLabel, roleIcon)** - Called before a role's tutorial page is rendered. This can be used to render a completely custom page with information about a role.\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *role* - Which role's tutorial page is being rendered
- *parentPanel* - The parent [DPanel](https://wiki.facepunch.com/gmod/DPanel) that this tutorial page is being rendered within
- *titleLabel* - The [DLabel](https://wiki.facepunch.com/gmod/DLabel) that is being used as the title of the rendered tutorial page. Has the role's name automatically set as the label text
- *roleIcon* - The [DImage](https://wiki.facepunch.com/gmod/DImage) that is being used to show the role's icon on the rendered tutorial page

*Return:* `true` to tell the tutorial page to use the content set in this hook rather than calling the `TTTTutorialRoleText` hook

**TTTTutorialRoleText(role, titleLabel, roleIcon)** - Called before a role's tutorial page is rendered. This can be used to provide the text to show for a role.\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *role* - Which role's tutorial page is being rendered
- *titleLabel* - The [DLabel](https://wiki.facepunch.com/gmod/DLabel) that is being used as the title of the rendered tutorial page. Has the role's name automatically set as the label text
- *roleIcon* - The [DImage](https://wiki.facepunch.com/gmod/DImage) that is being used to show the role's icon on the rendered tutorial page

*Return:* The string value to show on the tutorial page for this role. Can be HTML and will be rendered within a `<div>`

**TTTUpdateRoleState()** - Called after globals are synced but but before role colors and strings are set. Can be used to update role states (team membership) and role weapon (buyable, loadout, etc.) states based on configurations.\
*Realm:* Client and Server\
*Added in:* 1.2.7

**TTTWinCheckBlocks(winBlocks)** - Called after the `TTTCheckForWins` has already been called, allowing for an addon to block a win. Used for roles like the clown and the drunk to have them activate when the round would normally end the first time.\
*Realm:* Server\
*Added in:* 1.3.1\
*Parameters:*
- *winBlocks* - The table of callback functions that are given the current win type and return either the same win type they are given or a different win type if it should be changed. The callback function should **always** return a value.

**TTTWinCheckComplete(win)** - Called after a win condition has been set and right before the round eds. Used for roles like the old man that perform some logic before the end of the round without changing the outcome.\
*Realm:* Server\
*Added in:* 1.3.1\
*Parameters:*
- *win* - The win type that the round is about to end with

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
