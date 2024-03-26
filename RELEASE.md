# Release Notes

## 2.1.9 (Beta)
**Released:**

### Fixes
- Fixed rare error in defib-like devices when used on a corpse that doesn't have a Steam ID property set
- Fixed freeze caused by the spy's flaregun when running CR4TTT alongside wget's TTT Weapons Rework
- Fixed footprints sometimes being giant and sometimes not showing at all

## 2.1.8
**Released: March 17th, 2024**

### Additions
- Added immune and jester hitmarkers to the old man and jester roles revealed by the informant

### Changes
- Changed bodysnatcher disguise name label to not show to innocents even if they are on the same team as the disguised player
- Changed round summary to show who was bodysnatched by who if `ttt_bodysnatcher_swap_mode` is configured so that the dead player becomes a bodysnatcher
- Changed drunk sobering with `ttt_drunk_any_role` enabled so that they can only sober into a role that spawns naturally
  - e.g. If the mad scientist was enabled but not the zombie, the drunk would only be able to become the mad scientist

### Fixes
- Fixed player being turned into a bodysnatcher not getting the bodysnatching device
- Fixed round restarts not clearing bodysnatcher and spy disguises
- Fixed players who swap identities with a bodysnatcher sometimes being stuck ducking
- Fixed name label when looking at an allied player with a bodysnatcher disguise not showing their real name
- Fixed a few pieces of data getting stuck in bodysnatcher, phantom, and parasite that may have been caused by a change in the march GMod update
- Fixed "doused" label showing for the arsonist on entities that cannot be doused

### Developer
- Added `ROLE_BLOCK_SPAWN_CONVARS` table which can be used to prevent `ttt_rolename_enabled`, `ttt_rolename_spawn_weight`, and `ttt_rolename_min_players` ConVars from being created for specific roles
- Added `ROLE_BLOCK_HEALTH_CONVARS` table which can be used to prevent `ttt_rolename_starting_health` and `ttt_rolename_max_health` ConVars from being created for specific roles
- Added `ROLE_BLOCK_SHOP_CONVARS` table which can be used to prevent shop related ConVars from being created for specific roles

## 2.1.7
**Released: March 11th, 2024**\
Includes beta update [2.1.6](#216-beta).

### Developer
- Changed `TTTBodySearchEquipment` so it now has multiple levels of fallback
  - Call with the equipment table
  - Temporarily override `util.BitSet` to be `table.HasValue` and call with the equipment table again
  - Call with a `0` instead of the equipment table

## 2.1.6 (Beta)
**Released: March 9th, 2024**

### Additions
- Added option to have players who use the spongifier be fully healed after becoming the sponge (disabled by default)
- Added the option for the Tracker to have the tracking radar as part of their loadout (disabled by default)

### Changes
- Changed how jester and sponge win logic is performed to fix compatibility with other addons that occur on round end
- Changed player color generation for the Medium and the Tracker to use the golden ratio so that colors are not too similar

### Fixes
- Fixed player who becomes the new swapper not getting any role weapons the swapper may have (like the spongifier)
- Fixed `ttt_spectators_see_roles` not working sometimes when a hook overwrote the target ID and/or scoreboard row information
- Fixed `ttt_drunk_join_losing_team` not taking role packs into account when calculating the losing team

### Developer
- Changed `TTTBodySearchEquipment` so if an error occurs when it is called (most likely due to the equipment tracking changes) it will be called again with `0` for the `eq` parameter instead of a table
  - This is to work around the search dialog not opening if an addon is attempting to use the `eq` parameter as a number
- Changed `plymeta:RemoveEquipmentItem` to only sync to the client if something was actually removed from the equipment list
- Fixed `plymeta:AddEquipmentItem` adding duplicate entries if it was called with a value already in the equipment list

## 2.1.5
**Released: March 4th, 2024**\
Includes beta updates [2.1.2](#212-beta) to [2.1.4](#214-beta).

### Additions
- Added the ability for a role to block itself when configuring role blocks for role packs

### Changes
- Ported "TTT: optimise radar ping network traffic" from base TTT
  - Also updated the mad scientist's death radar and the tracker's tracking radar to have the same optimization

### Fixes
- Fixed an issue that would cause role pack specific role blocks to not work if there was no main role blocks file
- Fixed an issue that would sometimes copy role pack specific role blocks into the main role blocks file

## 2.1.4 (Beta)
**Released: March 2nd, 2024**

### Additions
- Added `ttt_roleblocks` command which opens the new role blocks UI
  - Role blocks allow more control over which roles are not able to spawn together in a round
  - **BREAKING CHANGE** - This replaces the old `ttt_single_role1_role2` ConVars. If you are currently using these ConVars your configuration will automatically be imported into the new role blocks system.
- Added role blocks tab to the role packs UI to allow for role pack specific role blocks
- Added an option to prevent the sponge's aura from shrinking when players die (disabled by default)
- Added an option to allow players to damage each other if they are both within the sponge's aura without redirecting damage to the sponge (disabled by default)
- Added an option for players to have a brief window of time after leaving a sponge's aura where they are still effected by the sponge (disabled by default)
- Added an option to have the bodysnatcher and their target swap:
  - Nothing (default)
  - Roles
  - Identities (role, model, name, location). NOTE: Also respawns the target
- Added ability to set a multiplier for the speed of cupid's arrow (defaults to 1)
- Added ability for cupid's bow to use hitscan instead of projectiles to calculate whether something is hit (disabled by default)

### Changes
- Changed spy name override to also show in the chat
  - Doesn't affect the spy or their teammates

### Fixes
- Fixed an issue where the medium would briefly start to scan a spirit before it was visible if the medium was close enough to where the player died
- Fixed an issue where the medium would be able to scan spirits that were spectating players if they started to scan them before they were spectating a player
- Fixed an issue that caused errors in the hud at the start of a round if the player was previously a spectator and so did not have a role assigned
- Fixed bodysnatcher not removing or receiving role weapons when swapping to a role that has them (e.g. the mad scientist)
- Fixed conflict between new medium seance logic and informant scanning
- Fixed case where all parasites infecting the same host would respawn even after the host was killed by the first infection
  - Now, all but the first parasite will have their infection cancelled when their host dies
- Fixed parasite cure not showing in shops when the parasite is enabled via rolepacks
- Fixed roles enabled via rolepacks not having their per-role configurations show in the F1 menu's "Roles" tab
- Fixed roles enabled via rolepacks that have role-specific assassin targeting convars not correctly showing in the assassin tutorial
- Fixed magneto stick showing pinning instructions to non-traitors when `ttt_ragdoll_pinning_innocents` was enabled but `ttt_ragdoll_pinning` was disabled
- Fixed non-vanilla traitors not seeing the player disguise label on their allies
- Fixed non-vanilla traitors not being able to pin ragdolls when `ttt_ragdoll_pinning` was enabled but `ttt_ragdoll_pinning_innocents` was disabled
- Fixed role packs sometimes asking you to save again if you attempt to close the window after saving
- Fixed "press KEY to possess" label showing on corpses for living players after the round has ended

### Developer
- Added `TTTDrawHitMarker` hook that is called when a player damages an entity before hitmarkers are drawn
- Added `TTTChatPlayerName` hook to override the player name as shown in chat

## 2.1.3 (Beta)
**Released: February 24th, 2024**

### Additions
- Added an option to require the arsonist to have line of sight with their target to douse them (enabled by default)
- Added an option to prevent the arsonist from being able to douse corpses (disabled by default)
- Added an option for the arsonist to have a brief window of time after leaving range or losing line of sight of their target before dousing is cancelled (1 second by default)
- Added an option to change the amount of time after an arsonist fails to douse a target before they can start dousing again (3 seconds by default)
- Added an option for the medium to be able to scan spirits to learn their name, team and role (disabled by default)
- Added option for spectators (not dead players) to be able to see the roles of all players (disabled by default)
- Added an option for whether to show a progress bar for the when the shadow's buff will be activated (enabled by default)

### Changes
- Changed shadow buff message for stealing role to state that explicitly instead of just say they will "give [their] target a buff"

### Fixes
- Fixed minor typo in vindicator event log entry
- Fixed hive mind all having the same number of credits on their body, allowing their killer to loot many times the credits they should have gotten
- Fixed some players who switched roles to become a medium not being able to see spirits of players that died prior to the medium switching roles

### Developer
- Added `TTTBodyCreditsLooted` hook that is called when a player loots credits from a body

## 2.1.2 (Beta)
**Released: February 17th, 2024**

### Changes
- Changed guesser team info messages to lowercase the team names for consistency and to help differentiate from role names
- Changed shadow to no longer have a win condition when the "steal role" buff is configured

### Fixes
- Fixed role pack weapon config not taking priority over role weapons config
- Fixed role pack weapon config unselecting some equipment items when re-opening the role pack UI
- Fixed role pack weapon config prompting to save when no changes had been made
- Fixed role pack weapon config sometimes adding duplicate weapons to saved .json files
- Fixed renaming or deleting a role pack causing the list of role packs to display incorrectly
- Fixed potential errors and weird behavior due to type mismatch when sending purchased equipment back to the client
- Fixed shadow not getting new role weapons when they swap to their target's role when the "steal role" buff is applied
- Fixed vindicator not dying when their target was killed by a non-player

### Developer
- Added `plymeta:RemoveEquipmentItem` to allow removal of a player's equipment
- **BREAKING CHANGE** - Changed equipment system to use sequential equipment IDs and store in a table instead of as a bit mask
  - This was deemed necessary to allow more than 32 equipment IDs to be generated and used
  - `ply.equipment_items` is now a table and the `plymeta:GetEquipmentItems` method now returns that table
  - The `TTT_Equipment` net method has been updated to transmit the equipment items table instead of the bit mask
  - The `TTT_RagdollSearch` net method has been updated to transmit the equipment items table instead of the bit mask
- Added ability for `ttt_kill_from_player` and `ttt_kill_target_from_player` to use "world" as the killer parameter

## 2.1.1
**Released: February 13th, 2024**

### Fixes
- Fixed an issue where enabling a role pack with less slots than players could cause the incorrect number of special traitors and detectives to spawn

### Developer
- Changed `Get{ROLE}`, `Is{ROLE}` and `IsActive{ROLE}` functions to not be dynamically assigned for a role if the resulting function shares a name with a pre-existing method

## 2.1.0
**Released: February 5th, 2024**\
Includes beta updates [2.0.5](#205-beta) to [2.0.7](#207-beta).

### Fixes
- Fixed players joining the hive mind not having their role weapons removed
- Fixed players joining the hive mind when they were zombifying
- Fixed potential client error when using zombie claws and leaping
- Fixed rolepack role assignment so that it correctly accounts for `ttt_detective_karma_min` and players with 'Avoid Detective' enabled
- Fixed `ttt_drunk_any_role` not allowing the drunk to become a role that was enabled via role pack

## 2.0.7 (Beta)
**Released: February 3rd, 2024**

### Additions
- Added `ttt_rolepacks` command which opens the new role pack UI
  - Role packs allow for greater control over how roles spawn, as well as what weapons are available in role shops and any addition ConVar configuration
  - Multiple role packs can be configured independently but only one role pack can apply at a time
- Added convar, `ttt_marshal_prevent_deputy`, to control whether to only spawn the marshal when there isn't already a deputy or impersonator in the round (defaults to enabled to match prior behavior).
- Added ability for jester roles to have a device that converts them to be a sponge
  - Global announcement is made when a player starts using the device
  - Disabled by default but can be individually enabled for each jester role by the new `ttt_sponge_device_for_*` convars
- Added ability for the shadow to be on the jester team (disabled by default)
- Added ability to have the shadow's target only be assigned after a configurable delay (disabled by default)
- Added ability to have the shadow become a jester or a swapper when they fail to stay near their target for enough time (disabled by default)
- Added ability for the shadow to steal their target's role and kill them if they stay together for enough time (disabled by default)

### Changes
- Changed quartermaster to block Randomat events that prevent their role feature from working
- Changed roleweapons system to use one JSON file per role instead of a folder per role and a text file per weapon
  - Legacy text files will be automatically converted to new format on first server load
  - Roleweapons UI (`ttt_roleweapons`) and commands (`sv_ttt_roleweapons`) have been updated to support new format as well

### Fixes
- Fixed loot goblin dropping buyable weapons that are not available in any role's shop
- Fixed player assigned the role of shadow after the round started not having a target assigned
- Fixed shadow that was killed but not because they killed their target not being allowed to resurrect

### Developer
- Added `TTTTeamChatTargets` hook which allows role chat messages to be blocked or have their recipients changed
- Added `TTTCanUseTraitorVoice` hook which allows overriding who can use traitor voice, both speaking and listening
- Added `TTTTeamVoiceChatTargets` hook which allows team voice state messages to be blocked or have their recipients changed
- Added cheat-only `ttt_team_chat_as_player` command for sending role chat messages as another player
- Added `plymeta:ForceRoleNextRound`, `plymeta:GetForcedRole`, and `plymeta:ClearForcedRole` methods to allow forcing player's roles in the next round
- Added `util.CanRoleSpawnNaturally` method to check if a role can spawn in the round naturally (i.e. because it is enabled via ConVars or role packs)
- Added `util.GetRoleIconPath` to get the path to a role's icon file
- Added optional `ply` parameter to `WEPS.HandleRoleEquipment` to allow sending roleweapons data to specific players
- Added optional `rolepack_weps` parameter to `WEPS.HandleCanBuyOverrides` to allow changing behavior of the CanBuy overrides with regards to configured rolepack weapons

## 2.0.6 (Beta)
**Released: January 14th, 2024**

### Fixes
- Fixed guesser not removing or receiving role weapons when swapping with a role that has them (e.g. the mad scientist)
- Fixed radar timer label still showing on the UI when it was disabled
- Fixed old man erroring and not dying when their adrenaline rush ended

### Developer
- Added optional scale parameter to `TTT_PlayerFootstep` net message

## 2.0.5 (Beta)
**Released: January 7th, 2024**

### Fixes
- Fixed any player using text chat with a hive mind in the round causing the hive mind to repeat their message
- Fixed player role and name not revealed to non-detectives in the body search dialog after a detective searches body with certain convars enabled
- Fixed assassin and shadow target messages being shown to players whose roles were changed by something when the round started

### Developer
- Removed all deprecated methods, hooks, convars, and role features from before 2.0.0
- Added optional `predicate` parameter to server-side `plymeta:QueueMessage`

## 2.0.4
**Released: January 1st, 2024**\
Includes beta updates [2.0.1](#201-beta) to [2.0.3](#203-beta).

### Fixes
- Fixed status message tooltips not working in the shop window

### Developer
- Added ability for weapons and equipment to specify other weapons or equipment that must be be owned to make this item available
  - For equipment, this is used by setting the optional `req` property
  - For weapons (SWEPs), this is used by setting the optional `RequiredItems` property

## 2.0.3 (Beta)
**Released: December 28th, 2023**

### Changes
- Changed shadow to have their target copied to players that steal their role
  - This affects roles such as the guesser and swapper

### Fixes
- Fixed guesser not copying the role state of the player they guessed
  - For example, assassin target
- Fixed another error in the shop if a weapon is somehow set up to be bought by a role that either doesn't exist or hasn't been set up properly

## 2.0.2 (Beta)
**Released: December 16th, 2023**

### Additions
- Added ability to override player's role color setting at the server level, `ttt_color_mode_override` (disabled by default) (Thanks to The Stig!)
- Added a notification message when a detective re-searches a corpse and discovers more information
  - This happens if `ttt_detectives_search_only` is disabled but something like `ttt_detectives_search_only_role` is enabled
- Added corpse hint text for spectators to tell them the key combo for possessing a player corpse (ALT+E, by default)
- Added convar to control whether spectators can search corpses (`ttt_spectator_corpse_search`), enabled by default to maintain currently functionality
- Added convar to force non-detective-like players to do covert corpse searching (`ttt_corpse_search_not_shared`), disabled by default
  - This causes search results to not be shared with other players except when a detective-like player searches a corpse
- Added ability for detective-like players to be rewarded credits for searching bodies (disabled by default)
  - See `ttt_detectives_search_credits`, `ttt_detectives_search_credits_friendly`, and `ttt_detectives_search_credits_share` for options

### Changes
- Changed the magneto stick to use an updated model which uses custom player model arms
- Changed convars that have a fixed set of options to use a labeled dropdown in ULX

### Fixes
- Fixed corpse find notifications showing "unknown" for name and role after the round ended
- Fixed player corpses that were searched by a non-detective (when `ttt_detectives_search_only` is disabled) not having their information sent to other players
  - This resulted in the scoreboard not updating except for the player(s) that inspected the corpse
- Fixed spectators seeing the covert search hint text for a player corpse even though they don't have that ability
- Fixed player information not showing on the scoreboard when their corpse was searched by the local player but it wasn't shared to other players
- Fixed swapper notify convars not showing in ULX

### Developer
- Added new dropdown type for role convars, `ROLE_CONVAR_TYPE_DROPDOWN`
  - Use the `choices` property to define a table of the dropdown options
  - If the convar represents numeric options, but you want to have a string label then use `choices` to provide the labels and `isNumeric` and `numericOffset` to configure the values

## 2.0.1 (Beta)
**Released: December 9th, 2023**

### Additions
- Added ability for the clown to be activated when a certain percentage of players are left alive, `ttt_clown_activation_pct` (disabled by default)
  - This is in addition to activating when a team would win the round
- Added ability to override the loot goblin's radar beep sound setting at the server level, `ttt_lootgoblin_radar_beep_sound_override` (disabled by default) (Thanks to The Stig!)

### Changes
- Changed zombie claw HUD hint to not mention features that are disabled

### Fixes
- Fixed players who swap roles with an activated vindicator not having their team set back to innocent
- Fixed an error in the shop if a weapon is somehow set up to be bought by a role that either doesn't exist or hasn't been set up properly
- Fixed player seeing their own name in the credit transfer dropdown sometimes
- Fixed all end-of-round awards regarding most used weapons not working
- Fixed spy not copying skin and bodygroups of the player they killed when `ttt_spy_steal_model` was enabled
- Fixed spy not getting their own skin and bodygroups back at the end of the round when `ttt_spy_steal_model` was enabled

### Developer
- Added `TTTDetectiveLikePromoted` hook to detect when a detective-like (deputy, impersonator, etc.) player is promoted
- Fixed `plymeta:HandleDetectiveLikePromotion` existing on the client side when it should not have

## 2.0.0
**Released: November 21st, 2023**\
Includes beta updates [1.9.3](#193-beta) to [1.9.14](#1914-beta).

### Changes
- Changed hive mind to be able to see jesters and that players are missing-in-action on the scoreboard by default

### Fixes
- Fixed various low-frequency errors by adding sanity checks
- Fixed edge case errors when a role changes to independent part-way through the round but doesn't have certain independent-only convars created

### Developer
- Removed bot SteamID64 client-side shims now that the client-side values match the server-side

## 1.9.14 (Beta)
**Released: November 11th, 2023**

### Additions
- Added `ttt_beggar_announce_delay` (disabled by default) to allow delaying the announcement of the beggar's role change

### Changes
- **BREAKING CHANGE** - Renamed `ttt_traitor_credits_timer` to `ttt_traitors_credits_timer`
- **BREAKING CHANGE** - Renamed the following ConVars to change the `_enable` ending to `_enabled` for consistency:
  - ttt_assassin_target_vision_enable -> ttt_assassin_target_vision_enabled
  - ttt_cupid_lover_vision_enable -> ttt_cupid_lover_vision_enabled
  - ttt_death_notifier_enable -> ttt_death_notifier_enabled
  - ttt_detective_glow_enable -> ttt_detective_glow_enabled
  - ttt_hivemind_vision_enable -> ttt_hivemind_vision_enabled
  - ttt_infected_respawn_enable -> ttt_infected_respawn_enabled
  - ttt_killer_vision_enable -> ttt_killer_vision_enabled
  - ttt_madscientist_respawn_enable -> ttt_madscientist_respawn_enabled
  - ttt_vampire_convert_enable -> ttt_vampire_convert_enabled
  - ttt_vampire_drain_enable -> ttt_vampire_drain_enabled
  - ttt_vampire_vision_enable -> ttt_vampire_vision_enabled
  - ttt_zombie_leap_enable -> ttt_zombie_leap_enabled
  - ttt_zombie_spit_enable -> ttt_zombie_spit_enabled
  - ttt_zombie_vision_enable -> ttt_zombie_vision_enabled
- **BREAKING CHANGE** - Changed vampire to use the new `ttt_vampire_credits_award_pct`, `ttt_vampire_credits_award_size`, and `ttt_vampire_credits_award_repeat` convars instead of the traitor ones when the vampire is not a traitor
- **BREAKING CHANGE** - Changed killer to use the new `ttt_killer_credits_award_pct`, `ttt_killer_credits_award_size`, and `ttt_killer_credits_award_repeat` convars instead of the traitor ones

### Fixes
- Ported "TTT: Prevent error when NPC fires SWEP derived from weapon_tttbase" from base TTT
- Fixed `ttt_monster_max` greater than 1 not working
- Fixed infected player that is in the process of respawning due dying while `ttt_infected_respawn_enabled` is enabled not counting as zombifying for the purposes of delaying the round end
- Fixed paramedic's defibrillator not changing detective-like roles not on the innocent or traitor teams to be their base role when resurrected

## 1.9.13 (Beta)
**Released: October 21st, 2023**

### Additions
- Added new mode for the `ttt_beggar_reveal_*` convars, allowing the beggar's team change to be announced and shown to any role that can see jesters (e.g. traitors, monsters, and independents with that feature enabled)
- Added new mode for the `ttt_bodysnatcher_reveal_*` convars, allowing the beggar's team change to be announced and shown to any role that can see jesters (e.g. traitors, monsters, and independents with that feature enabled)

### Fixes
- Fixed killer highlighting of jesters not obeying `ttt_killer_can_see_jesters`
- Fixed killer seeing generic jester role icon instead of question mark
- Fixed minor capitalization typo in the cupid pairing message
- Fixed view angle corruption when using the cupid's bow
- Fixed bodysnatchers that joined the traitor team receiving traitor team text chat even if `ttt_bodysnatcher_reveal_traitor` is set to `0` (none)
- Fixed some role information not being properly hidden when a role (like the beggar or bodysnatcher) changes to another role but that change is not revealed

## 1.9.12 (Beta)
**Released: October 7th, 2023**

### Additions
- Added new tracking radar to the tracker's shop, allow them to track living players and player corpses
  - The tracking radar icons use the same color as the tracker footprints

### Changes
- Changed zombie claws weapon to use a player's custom model if they have one and it's compatible
  - They also change to the zombie color to make it match how other players see them
- Changed the clown to become an independent when activated to make their ability to do damage make more sense
- Changed player colors used by tracker and medium to avoid brightnesses and saturations that can be hard to see

### Fixes
- Fixed vindicator win result message conflicting with killer
- Fixed minor capitalization typo in the vindicator announcement message
- Fixed vindicator not having their team changed and their target shown on the round summary if their target died before they respawned

### Developer
- Added `plymeta:IsVictimChangingRole` and corresponding role feature to help determine whether a player killed by another player will be changing their role (e.g. zombie, hive mind)
- Changed `player.ExecuteAgainstTeamPlayers` to skip the rest of the execution when `callback` returns `true`

## 1.9.11 (Beta)
**Released: October 1st, 2023**

### Changes
- Changed the vindicator so they don't see the role of their killer in their death message

## 1.9.10 (Beta)
**Released: September 23rd, 2023**

### Additions
- Added new innocent role: vindicator

## 1.9.9 (Beta)
**Released: September 17th, 2023**

### Changes
- Changed informant and beggar scan logic to work better with roles that are revealed when they activate

### Fixes
- Fixed marshal badge use distance being shorter than intended
- Fixed error on round start when a hive mind was being spawned
- Fixed new zombie leap animation not working on dedicated servers
- Fixed spy breaking other addons trying to manipulate or hide player names when mousing over players

### Developer
- Added `ROLE.isdetectivelike` optional feature to make it easier for custom roles to be treated like deputy and impersonator
- Added `ROLE.shouldrevealrolewhenactive` optional feature to control whether a role's information should be revealed (over their head, on the scoreboard, etc.) when they are active

## 1.9.8 (Beta)
**Released: September 9th, 2023**

### Fixes
- Fixed quartermaster not always counting as an innocent (for example, on the round summary screen)
- Fixed error on round start sometimes when there was a hive mind in the round
- Fixed parasite cures to attribute target kills to the owner so jester wins are properly triggered

## 1.9.7 (Beta)
**Released: August 27th, 2023**

### Additions
- Added convar (`ttt_drunk_any_role_include_disabled`) to control whether disabled roles are included in the list of possible drunk roles when `ttt_drunk_any_role` is enabled (disabled by default)
- Added ability for an activated loot goblin to periodically drop weapons behind them while they are alive (disabled by default)
- Added ability to show a warning message to all players when there is a guesser in a round (disabled by default)
- Added ability to have the hive mind be healed by a percentage of a new member's former max health (defaults to 0.25, or 25%)
- Added ability for the hive mind to have a health regeneration over time that scales up as more players are assimilated (disabled by default)

### Changes
- Changed players who join the hive mind to keep the credits they had before death
- Changed hive mind to sync available credits between members
- Changed hive mind tutorial to mention the shared health pool feature

### Fixes
- Fixed clown not being revealed when they activate when there's an informant in the round

### Developer
- Added `TTTPlayerCreditsChanged` hook to detect when a player's credits were added to or subtracted from

## 1.9.6 (Beta)
**Released: August 19th, 2023**

### Additions
- Added new special detective role: quartermaster
- Added convar to control whether a zombie killing a player with spit converts that player to be a zombie as well (defaults to disabled)
- Added sound and animation when a zombie uses their spit weapon

### Changes
- Changed zombie claws to randomly alternate between attacking with left and right claws
- Changed zombies to use more appropriate thirdperson animations while using the claws

### Fixes
- Fixed typo in the hive mind's tutorial
- Fixed players getting zombie claws as non-zombies if they were turned right before a round restarted
- Fixed sponge role being hidden to traitors when there was an informant in the round

### Developer
- Added `TTTInformantDefaultScanStage` hook to help roles override their default informant scan stage

## 1.9.5 (Beta)
**Released: August 13th, 2023**

### Additions
- Added new independent role: hive mind
- Added new jester role: guesser
- Added heart icon over the head of the revenger's soulmate

### Changes
- Changed infected icon so that it is unique and not shared with zombies

### Fixes
- Fixed parasite infecting a dead host if they died at the exact same time as their attacker
- Fixed error when a queued message tries to send to a player who has disconnected

### Developer
- Added `ROLE.hasshopmode` and `ROLE.hasshopsync` optional role features to control creation of `ttt_*_shop_mode` and `ttt_*_shop_sync` convars
- Added `ROLE.shopsyncroles` optional role feature to allow a role to automatically inherit the shop items from a list of other roles
- Added `TTTPlayerHealthChanged` hook for detecting when a player's health changed using `entmeta:SetHealth`
- Added `TTTRoleSpawnsArtificially` hook to determine if a role could be spawned artificially. (i.e. Spawned in a way other than naturally spawning when the role is enabled)
- Added `util.CanRoleSpawnArtificially` and `util.CanRoleSpawn` methods to check if roles could be spawned into a round

## 1.9.4 (Beta)
**Released: August 5th, 2023**

### Additions
- Added new traitor role: spy
- Added target icon above undoused player's heads for the arsonist, lover's heads for cupid and the lovers, and the shadow's target's head for the shadow
- Added jester player information to the clown's scoreboard when they are active, matching their target ID (icon, ring, text) visibility

### Changes
- Changed appearance of 'KILL' icon used by multiple roles
- Expanded the `ttt_roleweapons` admin command to have additional modes such as list, clean, and reload. See the command documentation for more information.
- Changed jester and missing in action (MIA) visibility for independent roles to be configurable on a per role basis (Arsonist, killer, mad scientist, and zombie enabled by default. Drunk, old man, and shadow disabled by default)
  - **BREAKING CHANGE** - The previous convars that governed these features for the independent team (`ttt_jesters_visible_to_independents` and `ttt_independents_update_scoreboard`) have been removed
- Changed many role tutorials to include additional information for new and changed features

### Fixes
- Fixed clown seeing jester icons (instead of question mark icons) over all jester team members' heads when they are activated
- Fixed clown seeing jester icon over the activated loot goblin's head (instead of the loot goblin icon)
- Fixed `ttt_cupid_lovers_notify_mode` not working
- Fixed loot goblin not being revealed to traitor team members if they had an informant on their team
- Fixed cupid's bow having two crosshairs

### Developer
- Changed `plymeta:IsActive` to ensure the player is alive like it was always supposed to
- Added `weapon_cr_defibbase` and updated all defib-like weapons to use it
- Added `TTTTargetIDPlayerTargetIcon` hook to control what target icon and background color should be shown over the target's head
- Added `plymeta:QueueMessage` method to queue messages to be printed to chat and the center of the screen one at a time
- Fixed loot goblin's definition of `ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN` and `ROLE_IS_TARGETID_OVERRIDDEN` using the parameters backwards
- **BREAKING CHANGE** - Deprecated `TTTTargetIDPlayerKillIcon`
  - Use the `TTTTargetIDPlayerTargetIcon` hook instead and return `"kill", true, ROLE_COLORS_SPRITE[ply:GetRole()], "down"`
- **BREAKING CHANGE** - Deprecated `plymeta:ShouldDelayAnnouncements` and the corresponding `ROLE_SHOULD_DELAY_ANNOUNCEMENTS` table and `ROLE.shoulddelayannouncements` external role feature
  - Use `plymeta:QueueMessage` to automatically queue announcements instead

## 1.9.3 (Beta)
**Released: July 29th, 2023**

### Changes
- Changed settings menu entry for notification sound cue to match base TTT
- **BREAKING CHANGE** - Renamed some convars so similar convars now have consistent plurality. Added a warning message when the old convars are being used so server admins can find and rename these convars before the old one are removed in the major release after this change goes into effect. The list of convars changed is:
  - ttt_detective_hide_special_mode -> ttt_detectives_hide_special_mode
  - ttt_detective_search_only -> ttt_detectives_search_only
  - ttt_detective_search_only_* -> ttt_detectives_search_only_*
  - ttt_detective_disable_looting -> ttt_detectives_disable_looting
  - ttt_traitor_vision_enable -> ttt_traitors_vision_enable
  - ttt_beggars_are_independent -> ttt_beggar_is_independent
  - ttt_bodysnatchers_are_independent -> ttt_bodysnatcher_is_independent
  - ttt_cupids_are_independent -> ttt_cupid_is_independent
  - ttt_detective_glow_enable -> ttt_detectives_glow_enable
  - ttt_detective_credits_timer -> ttt_detectives_credits_timer
  - ttt_vampires_are_monsters -> ttt_vampire_is_monster
  - ttt_vampires_are_independent -> ttt_vampire_is_independent
  - ttt_zombies_are_monsters -> ttt_zombie_is_monster
  - ttt_zombies_are_traitors -> ttt_zombie_is_traitor

### Fixes
- Fixed `ttt_sapper_protect_self` not allowing sapper to be protected from a different sapper if there are somehow multiple
- Fixed sprinting, then changing your crosshair size, then sprinting again causing your crosshair to revert to the original unchanged size
- Fixed sprinting causing crosshair size to be rounded to the nearest whole number
- Fixed loot goblin transform message being shown multiple times
- Fixed `ttt_bodysnatcher_respawn_delay` not working
- Fixed deputy, impersonator and zombie tutorial screens so they show if the marshal or madscientist could spawn them while the role isn't enabled

## 1.9.2
**Released: July 22nd, 2023**

### Additions
- Added ability to have the shadow be killed when anything kills their target, but not vice versa. Set `ttt_shadow_soul_link 2` to enable this behavior.

### Changes
- Changed weapons that use the C4 model to use the updated model that supports custom player model hand skins

### Fixes
- Fixed double message when a shadow killed their target and soul link was enabled
- Fixed conflict between beggar and informant causing error when `ttt_beggar_respawn` was enabled
- Fixed conflict between arsonist and informant causing some convars to not correctly sync with the client
- Fixed the death radar not initializing on the client before the round starts

### Developer
- Changed how some roles set their default shop equipment (passive) items so they don't overwrite other things also adding to the lists if the timing isn't perfect
- Changed role logic to load shared files first

## 1.9.1 (Beta)
**Released: July 16th, 2023**

### Additions
- Added arsonist dousing information to a corpse's search window
- Added ability to allow the arsonist to use their igniter at any time instead of waiting for all players to be doused (disabled by default)
- Added message to tell the arsonist how many players they set on fire after using the igniter
- Added ability to temporarily reduce the shadow's maximum health over time while they are outside of the target circle instead of killing them (disabled by default)

### Changes
- Changed arsonist's igniter to a set player's corpse on fire if they were doused before being killed
- Changed arsonist to try to douse a player's corpse if a living player is not found close enough

### Developer
- Added `util.BurnRagdoll` to burn a player's ragdoll, show scorch marks, and automatically destroy it unless it's been extinguished

## 1.9.0
**Released: July 9th, 2023**\
Includes beta updates [1.8.3](#183-beta) to [1.8.11](#1811-beta).

### Additions
- Added `ttt_shadow_target_notify_mode` convar to control whether the shadow's target is told if they have a shadow or not (disabled by default)
- Added `ttt_lootgoblin_radar_beep_sound` client-side convar to control whether the loot goblin radar should beep whenever the location updates (enabled by default)
- Added a button to the F1 settings menu to disable the sound that is played when a popup message appears

### Changes
- Changed shadow buff delay to 90 seconds by default
- Changed shadow target buff notifications to be disabled by default
- Changed shadow who killed their target to die immediately upon respawn (by defib, etc.)
- Changed loot goblin win tracking logic to hopefully fix the case where the round summary will show a loot goblin win when that role wasn't in the round

### Fixes
- Fixed phantoms being stuck possessing a dead player if their attacker died before they did
- Fixed everyone being able to see whether someone was doused by the arsonist on the scoreboard
- Fixed players being notified that they were doused by the arsonist after they were already ignited
- Fixed players being notified that they were doused by the arsonist even if they were dead

### Developer
- Removed old, unused code from the paramedic's defib, hypnotist's brainwashing device, and mad scientists zombification device
- Updated debug commands for damaging and killing players to take an optional argument allowing dead players to be the source

## 1.8.11 (Beta)
**Released: July 2nd, 2023**

### Additions
- Added `ttt_shadow_target_buff_role_copy` convar to control whether the shadow copies the role of the target player if the team join buff is active (disabled by default)
- Added `ttt_shadow_soul_link` convar to control whether the shadow dies when their target dies and vice-versa (disabled by default)

### Changes
- Changed shadow buff to "team join" by default
- Changed messages displayed to the shadow if the join team buff is active to be more accurate

## 1.8.10 (Beta)
**Released: June 25th, 2023**

### Additions
- Added new convar (`ttt_lootgoblin_active_display`) to control whether the loot goblin's role is revealed when they are activated (defaults to enabled to keep current behavior)
- Added sprint speed and stamina recovery bonuses to the shadow when they are outside of their target's radius
  - Both values are configurable and can be disabled
  - Both values also scale up to a maximum value (also configurable) the further the shadow is from their target
- Added the ability to move the parasite onto the monster team (disabled by default)
- Added the ability to control whether the shadow's target is notified when they are buffed (enabled by default)
- Added the ability to control whether the shadow can target jesters (enabled by default)
- Added the ability to control whether the shadow can target independents (enabled by default)
- Added a new buff option (`ttt_shadow_target_buff 4`) for the shadow: joining their target's team
  - If this is enabled, the shadow will join the same team as their target after the buff delay has elapsed

### Changes
- **BREAKING CHANGE** - Renamed `ttt_beggar_traitor_scan*` convars to `ttt_beggar_scan*`
- Changed `ttt_beggar_scan` to have a second mode (`ttt_beggar_scan 2`) which allows beggars to scan whether a player has a shop

### Fixes
- Fixed conflict between loot goblin and revenger radar timing convars
- Fixed loot goblin stamina recovery not being synced across client and server
- Fixed disabling invisibility setting the glass material which should be clear but isn't for everyone
- Fixed beggar scanning circle showing even when beggar scanning was disabled
- Fixed roles promoted by the marshal not having their health adjusted
- Fixed `ttt_impersonator_detective_chance` not working

## 1.8.9 (Beta)
**Released: May 28th, 2023**

### Additions
- Added a buff to the shadow's target after they have been together for enough time
  - By default the buff is health regeneration, but it can be disabled and or configured as a single respawn or a damage bonus instead

### Changes
- Changed jester team roles to no longer be immune to map-triggered damage (such as "out of map" kill zones)

### Fixes
- Fixed beggar client config section showing when traitor scans are not enabled
- Fixed error in the shadow client code if a non-player ragdoll exists

## 1.8.8 (Beta)
**Released: May 20th, 2023**

### Additions
- Added ability to use the DNA scanner on the body parts left behind when a vampire eats a player or corpse

### Changes
- Overhauled sprinting system to fix prediction issues (Thanks @wgetJane for letting us know and helping to fix parts of it!)
- Changed Hitmarkers settings menu labels to be translatable
- Changed Equipment/Shop settings menu labels to be translatable
- Changed death notification messages to be translatable

### Fixes
- Fixed "You fell to death!" death notification not working
- Fixed "You burned to death!" death notification not working for some types of fires
- Fixed hit sound playing if enable hitmarkers after shooting someone with them disabled
- Fixed jesters who have been searched showing question mark icons on the scoreboard
- Ported "TTT: Fix wrong argument in SortByMember" from base TTT

### Developer
- Changed the DNA Tester to be marked a role weapon for easier interaction with addons that expect that
- Changed `TTTSprintKey`, `TTTSprintStaminaPost`, and `TTTSprintStaminaRecovery` to also run on the server
- Added `TTTSprintStateChange` hook which runs when a player starts or stops sprinting
- Added `plymeta:GetSprinting`, `plymeta:SetSprinting`, `plymeta:GetSprintStamina`, and `plymeta:SetSprintStamina`

## 1.8.7 (Beta)
**Released: May 6th, 2023**

### Additions
- Added ability for the beggar to scan players (`ttt_beggar_traitor_scan`) to determine whether they are traitors (disabled by default)
- Added buyable Death Radar for the mad scientist which will update periodically to mark dead bodies
- Added ability to warn a player infected by the parasite after a configurable (`ttt_parasite_infection_warning_time`) amount of time (disabled by default)

### Developer
- Added `table.HasItemWithPropertyValue` static method
- Added equipment frame as parameter to `TTTEquipmentTabs`

## 1.8.6 (Beta)
**Released: April 30th, 2023**

### Additions
- Added convar to control who a bodysnatcher's role change is revealed to when they join the jester team (`ttt_bodysnatcher_reveal_jester`)

### Changes
- Changed hint text for a player corpse to show "call a Detective" instead of "search" when `ttt_detective_search_only` was set to `1`
- Changed sponge to show icon and color on the scoreboard for everyone
- Changed arsonist notification message delay time range to be longer by default
- Changed arsonist douse max distance to be larger by default
- Ported "TTT: fix knife effect_fn not being cleared" from base TTT

### Fixes
- Fixed covert search hint text showing on a player corpse that has already been searched
- Fixed aura icons showing on the bottom of the screen even when the source player has died
- Fixed shadow seeing their target highlighted even after they've died
- Fixed conflict between informant logic and convars that controlled beggar and bodysnatcher role change reveal scope
- Fixed old man getting stuck with a huge amount of health when they are hit by two damage events simultaneously (e.g. by a Holy Hand Grenade explosion)

### Developer
- Added `GetRawRoleTeamName` global function to get the untranslated name of a team by `ROLE_TEAM_*` enumeration

## 1.8.5 (Beta)
**Released: April 22nd, 2023**

### Additions
- Added new independent role: arsonist

### Changes
- Ported "TTT: Fix ironsight position when in singleplayer" from base TTT

## 1.8.4 (Beta)
**Released: April 16th, 2023**

### Additions
- Added HUD element for tracking player breath when under water

### Fixes
- Fixed ragdoll spectator flag not being reset immediately when a player un-spectates
- Fixed glitch bluff role never getting set to a special traitor when `ttt_glitch_mode` was set to `1`

## 1.8.3 (Beta)
**Released: April 8th, 2023**

### Additions
- Added new jester role: sponge
- Added button to body search dialog to take a DNA sample (or open the DNA scanner UI if a sample was already taken) when the player has a DNA Tester
  - Can be disabled via the new `ttt_dna_scan_on_dialog` convar
- Added screen effect when a player is inside an aura to make it more clear they are being affected

### Changes
- Changed "call detective" button on body search dialog to be hidden when the local player is a detective
- Changed corpse icons on DNA scanner UI to have the player's name in the hover tooltip

### Fixes
- Fixed covert body search not working properly and text hint missing
- Fixed body search text hint not using correct key if it was rebound
- Fixed killer win server log being overridden by jester win server log
- Fixed minor plurality issue in the server log message when the jester wins
- Fixed shadow role translations overriding sapper translations
- Fixed role team name and color being incorrect in the body search dialog

### Developer
- Added new `CORPSE.CanBeSearched` method to make it easier to check if a corpse can be searched by a player
- Added new `TTTBodySearchButtons` hook to add buttons to the body search dialog
- Added `player.GetLivingInRadius` to get all living players within a radius of the given position
- Added new `CRHUD:PaintStatusEffect` method to slightly tint the screen and add floating particle effects to the bottom of the HUD

## 1.8.2
**Released: April 2nd, 2023**

### Additions
- Added showing a player's team in the body search dialog if `ttt_detective_search_only` is disabled and `ttt_detective_search_only_role` is enabled

### Changes
- Changed players who are in a lovers pair due to cupid's arrow to not be killed if their lover died but is guaranteed to respawn (e.g. death by zombie claws, being killed as the swapper, etc.)
- Changed lovers who are in love with a swapper or a swapper's attacker to swap lovers between the swapper and their attacker when the swapper swaps (enabled by default)
- Changed lovers who are in love with a parasite or a phantom to not die when their lover is dead as long as their lover is infecting/haunting another player (enabled by default)
- Changed shop and player loadout retry timers to stop retrying after 60 seconds or when a new round is being prepared, whichever comes first
- Changed round start popups to close at the start of the next round if they are still around

### Fixes
- Fixed tips and idle warning messages not using the new config tab name
- Fixed cupid & lovers not winning with jesters or roles with passive wins were left in the round
- Fixed missing space before "YOUR TARGET" scoreboard marker for shadow
- Fixed some player role information showing on the scoreboard when there was an informant at the start of the round but then roles were switched by something external, like a Randomat event
- Fixed glitch who was paired with a traitor by cupid's arrow having their role icon use the traitor color

### Developer
- Added new `TTTParasiteRespawn` hook to detect when a parasite respawns
- Added new `TTTCupidShouldLoverSurvive` hook to detect when a cupid lover is about to be killed because their lover is dead

## 1.8.1
**Released: March 6th, 2023**

### Additions
- Added ability for deputies and impersonators to start promoted (defaults to disabled)

### Changes
- Ported "Translatability improvements and fixes" from base TTT
- Changed jesters to be able to do damage after the round ends (if `ttt_postround_dm` is enabled)

### Fixes
- Fixed checkboxes not being accurate in the `ttt_roleweapons` configuration window when an equipment item's name wasn't translated and had capitol letters (e.g. Bruh Bunker)
- Fixed minor plurality issue in the server log message when the killer wins
- Fixed independents being able to see each other's Target ID (icon, target ring, role text) information
- Fixed target ID ring and role text for deputies showing detective when `ttt_deputy_use_detective_icon` was disabled

## 1.8.0
**Released: February 15th, 2023**\
Includes beta updates [1.7.2](#172-beta) and [1.7.3](#173-beta).

### Fixes
- Fixed client-side error in certain win conditions when a player joins late

## 1.7.3 (Beta)
**Released: February 2nd, 2023**

### Additions
- Added new independent role: shadow
- Added `ttt_jester_independent_chance` convar to control the chance of a jester or independent spawning when `ttt_multiple_jesters_independents` is enabled (0.5 by default)
- Added `ttt_zombie_respawn_block_win` convar to control whether a player respawning as a zombie will block the end of the round (disabled by default)
- Added `ttt_single_jester_swapper` convar which prevents a jester and a swapper from spawning in the same round when `ttt_multiple_jesters_independents` is enabled (disabled by default)
- Added `ttt_single_*_*_chance` convars which control how likely it is for one role to spawn over the other when using convars such as `ttt_single_jester_swapper` or `ttt_single_deputy_impersonator` (0.5 by default)

### Changes
- Changed BEM and Hitmarkers settings to be in the Settings tab instead of in their own tabs
- Renamed the "Settings" tab of the Help/Settings dialog to "Config" to make it slightly less confusing
- Changed informant's `ttt_informant_show_scan_radius` convar to be client-side and added it to the new `Roles` tab in the Help and Settings menu
- Changed cupid's arrow to make it a little easier to hit players

### Fixes
- Fixed some traitor role weapons being randomly removed from the shop when shop randomization is enabled
- Fixed `ttt_vampire_drain_mute_target` only blocking messages the first time
- Fixed all independent roles seeing each other on the scoreboard
- Fixed informant's scan radius circle disappearing when the scan was in progress
- Fixed issue where the turncoat would change team if they killed themselves when `ttt_turncoat_change_innocent_kill` was enabled
- Fixed cupid's arrow getting stuck on some maps
- Fixed parasites gaining role weapons when successfully taking over other players

### Developer
- Added new `TTTScoringWinTitleOverride` hook for non-role addons to override the title and color shown on round summary screens
- Added new return value to the `TTTEquipmentTabs` hook, allowing addons to add new tabs that open the dialog even if none of the default tabs normally would
- Added new `TTTSettingsConfigTabFields` hook to make it easier to add to the existing help menu's Config tab sections
- Added new `TTTSettingsConfigTabSections` hook to make it easier to add new sections to the help menu's Config tab
- Added new `TTTSettingsRolesTabSections` hook to allow developers to add a configuration section for a role to the help menu's Roles tab
- Added new `sprinting` parameter to the `TTTSpeedMultiplier` hook
- Changed the help menu's Config tab to use `DScrollPanel` instead of the deprecated `DPanelList`
- Fixed `plymeta:IsZombieAlly` returning `true` for all independent roles rather than just other zombies and the mad scientist

## 1.7.2 (Beta)
**Released: January 21st, 2023**

### Additions
- Added option for the drunk to join the losing team when their sober timer runs out (disabled by default)
  - *NOTE*: We can't actually know for sure which team is losing, but we can make an educated guess based on the total amount of health each team has and how that compares to the percentage of players that should spawn as traitors. If you are curious the full algorithm can be found in `plymeta:DrunkJoinLosingTeam`.

### Changes
- Changed vampire drain UI to be clearer which action is in progress

### Fixes
- Fixed new vampire drain UI not working on dedicated servers
- Fixed vampire weapon convars being created on the client

### Developer
- Removed deprecated `TTTPlayerDefibRoleChange`

## 1.7.1
**Released: January 16th, 2023**

### Additions
- Added options to merge jester and independent role pools and allow multiple jesters and independents to spawn in each round (disabled by default)

### Fixes
- Fixed scoreboard incorrectly resizing when running the game as windowed
- Fixed hypnotist brainwashing device not converting special detectives to impersonator when `ttt_hypnotist_convert_detectives` is enabled
- Fixed assassin round start popup not displaying properly when there are no valid targets

### Developer
- Updated `SteamID64` and `GetBySteamID64` methods so that they can be called client-side on bots

## 1.7.0
**Released: January 8th, 2023**\
Includes all beta updates from [1.6.14](#1614-beta) to [1.6.19](#1619-beta).

### Additions
- Added messages in chat when hit by cupid's arrow or paired with another player
- Added information about cupid and the lovers to the scoreboard
- Added message for the target when a player is being deputized by the marshal

### Fixes
- Fixed round summary window appearing shorter if the summary tab was disabled
- Fixed minor error in cupid's tutorial page
- Fixed issue caused when one player was hit by cupid's arrow then died before being paired with another player
- Fixed cupid pairing score event attribution
- Fixed round not ending when it was just cupid and the lovers on opposite teams remaining
- Fixed some beggar information not being properly hidden when `ttt_beggar_reveal_traitor` was `0`

### Developer
-  Fixed not being able to target yourself using the `ttt_kill_target_*` and `ttt_damage_target_*` debug commands

## 1.6.19 (Beta)
**Released: January 4th, 2023**

### Additions
- Added option to give detectives and traitors credits over time (disabled by default)

### Changes
- Changed round summary to show multiple jester/independent players on individual rows
- Changed the shop to sort items alphabetically (enabled by default)
  - Optionally this can sort by slot first, then alphabetically (disabled by default)

### Developer
- Added `CRHUD:PaintProgressBar` global method

## 1.6.18 (Beta)
**Released: December 28th, 2022**

### Additions
- Added option to disable the ring that shows the approximate radius of the informant's scanner (enabled by default)
- Added option to disable setting starting and maximum health for each role (set the role's health convars to 0 or -1 to disable)

### Changes
- Changed vampire convert/drain UI to show separate segments for converting and draining progress

### Fixes
- Fixed cupid winning the round if all players died, regardless of whether cupid was even in the round to begin with
- Fixed killing the jester causing the round to end even if `ttt_debug_preventwin` was enabled

## 1.6.17 (Beta)
**Released: December 23rd, 2022**

### Additions
- Added new jester role: cupid
- Added option to enable a radar that reveals the previous location of the loot goblin (disabled by default)

### Changes
- Changed round summary panel to use increasingly smaller fonts to try and fit text into the box
- Changed vampire prime to get randomly assigned to a vampire thrall if the prime leaves the game
- Changed zombie prime to get randomly assigned to a zombie thrall if the prime leaves the game
- Changed revenger to be randomly assigned a new lover if their lover leaves the game

### Fixes
- Fixed minor typo in jester tutorial
- Fixed hypnotist device being usable on fake bodies which caused living players to change roles and teleport
- Fixed marshal's deputy badge not removing role weapons or restoring default weapons when changing someone's role
- Fixed assassin not getting new target when their current target leaves the game
- Fixed some roles with custom win conditions causing "unknown win condition" server logs when they won
- Fixed a client error that can occur when a player disconnecting ends the round

### Developer
- Added new `otherName` and `label` return values to the `TTTScoringSummaryRender` hook
- Changed how the following round summary information is rendered to be cleaner and less hard-coded
  - Jester "Killed by"
  - Swapper "Killed"
  - Beggars who joined a team
  - People who were hypnotized
- Added new `secondary_color` return value to the `TTTTargetIDPlayerText` hook
- Added new `TTTRoleWeaponsLoaded` hook which is called on both the server and client when the role weapons configuration is loaded
- Added new `TTTRoleWeaponUpdated` hook which is called on both the server and client when a role weapon configuration is changed for a specific role and weapon

## 1.6.16 (Beta)
**Released: November 26th, 2022**

### Developer
- **BREAKING CHANGE** - Deprecated `TTTPlayerDefibRoleChange`
- Added `TTTInformantScanStageChanged` which is called when an informant has scanned additional information from a target player
- Added `TTTMadScientistZombifyBegin` which is called when a mad scientist begins to zombify a target
- Added `TTTPaladinAuraHealed` which is called when a paladin heals a target with their aura
- Added `TTTPlayerRoleChangedByItem` to replace `TTTPlayerDefibRoleChange` and implemented it for bodysnatcher, hypnotist, mad scientist, marshal, paramedic, vampire, and zombie
- Added `TTTShopRandomBought` which is called when a player buys a random item from the shop
- Added `TTTSmokeGrenadeExtinguish` which is called when a smoke grenade extinguishes a fire entity
- Added `TTTTurncoatTeamChanged` which is called when the turncoat changes teams
- Added `TTTVampireBodyEaten` and `TTTVampireInvisibilityChange` to help track vampire ability usage

## 1.6.15 (Beta)
**Released: November 12th, 2022**

### Additions
- Added new special detective role: the marshal
- Added new special innocent role: the infected

### Changes
- Changed sprint speed to be more resistant to client-side speed hacking (Thanks @wgetJane for letting us know!)
- Changed the round summary screen to automatically lower the font size of the winning team if it's more than 18 characters, down from 20
- Changed loot goblin cackle min and max convars to not cause problems when the min is greater than the max

### Fixes
- Fixed players who respawn as zombies when `ttt_zombie_prime_only_weapons` is disabled still losing their default weapons in some cases

### Developer
- Added definition of `IsRoleActive` for the turncoat
- Added `prime` parameter to `RespawnAsZombie`

## 1.6.14 (Beta)
**Released: September 24th, 2022**

### Changes
- Changed usages of `IsAdmin` to check `IsSuperAdmin` as well to work around the rare case where `IsAdmin` was `false` where `IsSuperAdmin` was `true`
  - Fixes locking SuperAdmins out of the Role Weapons system in certain circumstances

### Fixes
- Fixed old man not dying when taking damage from something other than a player
- Fixed error in the weapon switch HUD when dropping weapons that use the base GMod weapon instead of the base TTT weapon

## 1.6.13
**Released: September 10th, 2022**\
Includes all beta updates from [1.6.5](#165-beta) to [1.6.12](#1612-beta).

### Fixes
- Fixed old man being invincible if they didn't take enough damage to die
- Fixed old man with more than 10 health not dying after their adrenaline rush

## 1.6.12 (Beta)
**Released: September 3rd, 2022**

### Additions
- Added ability to set chance a drunk will become a traitor explicitly rather than the default logic where traitor roles have the same chance as all non-innocent roles (disabled by default)
- Added ability to mute a player being drained by a vampire (disabled by default)

## 1.6.11 (Beta)
**Released: August 27th, 2022**

### Additions
- Added ability to control whether player colors are set each time they spawn (enabled by default)

### Changes
- Changed informant to be able to scan players passively without needed to hold the scanner (enabled by default)

### Developer
- Added new `activeLabels` parameter to TTTHUDInfoPaint hook to allow position offset based on the number of existing labels

## 1.6.10 (Beta)
**Released: August 21st, 2022**

### Additions
- Added ability to change how zombie-to-zombie friendly-fire is handled
  - There are three options: 0 - Do nothing, 1 - Reflect damage on to attacker, 2 - Negate damage
  - Defaults to negating damage which was the previous behavior

### Changes
- Changed vampire (thrall -> prime) friendly-fire handling to allow damage negation instead of reflection (disabled by default) (Thanks @neon_leitz!)
  - There are now three options: 0 - Do nothing, 1 - Reflect damage on to attacker, 2 - Negate damage
  - Setting renamed from `ttt_vampire_prime_reflect_friendly_fire` to `ttt_vampire_prime_friendly_fire`
- Changed quack's station bomb to be on a different sub-slot so it can be bought at the same time as the health station
- Changed player state overrides (like movement speed) to be set on each player spawn to ensure other addons don't leave players in a broken state

## 1.6.9 (Beta)
**Released: August 13th, 2022**

### Fixes
- Fixed paladin's damage reduction aura working even when they were dead
- Fixed sapper's explosion protection working even when they were dead
- Fixed role weapons which have a progress bar not resetting to 0% when the player switches to another weapon

## 1.6.8 (Beta)
**Released: August 7th, 2022**

### Additions
- Added ability for the beggar to respawn as the opposite role of the person that killed them (disabled by default)
- Added ability to set the maximum health of the swapper's killer (disabled by default)

### Changes
- Changed the shop to refresh when an item is added or removed from your favorites (Thanks @Callum!)

### Fixes
- Fixed the `ttt_beggar_respawn_delay` convar not working

## 1.6.7 (Beta)
**Released: July 30th, 2022**

### Additions
- Added ability to have map-specific config files
  - Create a `.cfg` file with the map's name (e.g. `ttt_lego.cfg`) in the `cfg` directory

### Fixes
- Fixed award for killing all monsters not using the translation for "monsters"
- Fixed award for killing all innocents assuming the player was a traitor
- Fixed award for killing all traitors assuming the player was an innocent

### Developer
- Added `util.ExecFile` for executing the contents of a file

## 1.6.6 (Beta)
**Released: July 24th, 2022**

### Additions
- Added option to have turncoat automatically change teams when they kill a innocent team member (disabled by default)

### Changes
- Changed turncoat's announcement message to say explicitly that they joined the traitors
- Changed so killing the old man does not award credits to anyone

### Fixes
- Fixed traitors seeing the deputy role icon on the scoreboard for promoted deputies instead of the detective icon
- Fixed traitors seeing the detective role icon on the scoreboard for impersonators who haven't been promoted yet when `ttt_impersonator_use_detective_icon` is enabled
- Fixed error rendering the weapon switch and HUD with certain workshop weapons
- Fixed traitors not being awarded credits if `ttt_credits_award_repeat` is disabled and something caused the first credit award amount to be 0
- Fixed error switching tabs in the equipment window if shop tab wasn't displaying any items (Thanks @Callum!)
- Fixed beggar sometimes being shown duplicate team join notifications depending on the `ttt_beggar_reveal_*` convars

## 1.6.5 (Beta)
**Released: July 16th, 2022**

### Additions
- Added ability for smoke grenades to extinguish fire (enabled by default)
- Added ability for non-prime vampires to have their damage against prime vampires reflected back on them (disabled by default) (Thanks @Excentyl!)
- Added ability to configure the amount of haunting willpower a phantom starts with when they are killed (0 by default)

### Changes
- Changed how round end logic interacts with different roles to hopefully prevent an error from stopping the round from ending

### Fixes
- Fixed roles which can block wins from causing invalid win conditions if their logic doesn't return anything
  - Fixes an error that occurred when a round ended due to a map win or time limit win before the drunk had sobered up
- Fixed turncoat who was an assassin's target changing teams not causing the assassin to get a new target

## 1.6.4 
**Released: July 9th, 2022**\
Includes all beta updates from [1.6.1](#161-beta) to [1.6.3](#163-beta).

## 1.6.3 (Beta)
**Released: July 8th, 2022**

### Additions
- Added ability for time limit wins to be counted as draws, controlled by the new `ttt_roundtime_win_draw` convar (disabled by default)
- Added ability for detectives to glow the detective role color (disabled by default)

### Changes
- Changed small role icons to be cached to improve performance when rendering the scoreboard (Thanks @TheXnator!)
- Changed overhead role icons to be cached to improve performance

### Fixes
- Fixed NPC hack used for medium ghost positions being targeted by AI like manhacks
- Fixed timeout wins not being detectable by `TTTScoringWinTitle` and `TTTScoringSecondaryWins` hooks
- Fixed a few instances of not using the "monsters" translation in the round summary window
- Fixed radio only being usable by vanilla traitors
- Fixed incompatibility with the cloaking device on the workshop

## 1.6.2 (Beta)
**Released: June 26th, 2022**

### Changes
- Changed player role icons (over their heads) and highlighting to ignore map optimizations which prevented them from updating regularly (Thanks to @wgetJane for the logic help!)
  - This is controlled by a new client-side convar, `ttt_bypass_culling`, which is enabled by default and available in the F1 settings menu

### Fixes
- Fixed scoreboard showing the impersonator color and icon when there was a glitch and `ttt_glitch_mode` was `2`
- Fixed scoreboard showing the detective color and icon for a promoted impersonator when `ttt_impersonator_use_detective_icon` was `0`
- Fixed overhead role icon showing the impersonator color and icon when there was a glitch and `ttt_glitch_mode` was `2`
- Fixed chance of two impersonators spawning when `ttt_impersonator_detective_chance` is used
- Fixed impersonator not getting activation credits when they are immediately promoted because `ttt_impersonator_detective_chance` is used

### Developer
- Added `plymeta:ShouldAvoidDetective` as an alias for `plymeta:GetAvoidDetective`
- Added `plymeta:GetBypassCulling`/`plymeta:ShouldBypassCulling` as a way to get a player's `ttt_bypass_culling` setting value
- Added `plymeta:IsOnScreen` to determine if an entity or position is on screen within a value limit
- Added optional `keep_existing` parameter to `plymeta:SetDefaultCredits`

## 1.6.1 (Beta)
**Released: June 18th, 2022**

### Additions
- Added setting to control whether sprint is enabled (enabled by default)
- Added setting to move the mad scientist to the monster team (disabled by default)
- Added setting to control the maximum number of monsters to spawn each round (defaults to 1)

### Changes
- Changed round end summary tab to have a scrollbar if it is too tall to fit on the screen

### Fixes
- Fixed monster role count logic not working for external monster roles
- Fixed body search window title showing the name of the body for non-detectives when `ttt_detective_search_only` was disabled and `ttt_detective_search_only_nick` was enabled
- Fixed non-detectives triggering "body found" messages including player name and role when those pieces of information should be hidden based on the `ttt_detective_search_only_*` convars
- Fixed non-detectives triggering "confirmed the death of..." messages when `ttt_detective_search_only` was disabled and `ttt_detective_search_only_nick` was enabled
- Fixed non-detectives searching a body a second time revealing information that should be hidden based on the `ttt_detective_search_only_*` convars
- Fixed non-detectives searching a dead player causing their name to show when looking at the body when `ttt_detective_search_only` was disabled and `ttt_detective_search_only_nick` was enabled
- Fixed non-detectives searching a dead player causing them to move on the scoreboard and revealing their name when `ttt_detective_search_only` was disabled and `ttt_detective_search_only_nick` was enabled

## 1.6.0
**Released: June 6th, 2022**\
Includes all beta updates from [1.5.9](#159-beta) to [1.5.17](#1517-beta).

## 1.5.17 (Beta)
**Released: June 4th, 2022**

### Changes
- Changed additional role messages and features to be hidden or disabled when `ttt_hide_role` is enabled (Thanks Callum!)
- Ported Steam chat filtering from base TTT

## 1.5.16 (Beta)
**Released: May 29th, 2022**

### Additions
- Added ability to configure maximum informant scanner distance
- Added total kills to the round summary score tab

### Changes
- Changed traitor team to show question mark icons over their head and on the scoreboard when there is a glitch
  - Which specific roles show as a question mark depends on the ttt_glitch_mode convar
- Ported "TTT: fix weapons disappearing during round reset" from base TTT

### Fixes
- Fixed an error that can occur when a player disconnects while respawning
- Fixed some players' roles being revealed to traitors the round after they are a detective
- Fixed error in the shop search when certain symbols were entered
- Fixed error opening the shop when `ttt_bem_allow_change` was disabled

## 1.5.15 (Beta)
**Released: May 21st, 2022**

### Additions
- Added new special traitor role: the informant
- Added information on the scoreboard when the clown is activated
- Added information on the scoreboard when the old man is activated

### Changes
- Changed jester team to show question mark icons over their head and on the scoreboard instead of the jester icon
- Changed maps which send messages to specific vanilla roles to instead send those messages to the equivalent team
- Changed detective team to show question mark icons over their head and on the scoreboard instead of the detective icon if roles are hidden
- Changed hidden detective HUD text to make it clear that the role is unknown but others still know its a detective
- Updated detective tutorials to explain role hiding logic

### Developer
- Added `plymeta:IsTargetIDOverridden` to determine whether the player is currently overriding a piece of Target ID information
- Added ability for external roles to define their own `plymeta:IsTargetIDOverridden`
- Added `plymeta:IsScoreboardInfoOverridden` to determine whether the player is currently overriding a piece of scoreboard information
- Added ability for external roles to define their own `plymeta:IsScoreboardInfoOverridden`
- Added `plymeta:IsTargetHighlighted` to determine whether the target is being highlighted per the player's role rules
- Added ability for external roles to define their own `plymeta:IsTargetHighlighted`
- Changed `ttt_game_text` entity to use the team-equivalent for existing role receivers (e.g. RECEIVE_TRAITOR now sends to the traitor team, not just the traitor role)
- Added ability for `ttt_game_text` entity to set the receiver to be jesters (5), independents (6), or monsters (7)

## 1.5.14 (Beta)
**Released: May 15th, 2022**

### Additions
- Added new special innocent role: the turncoat
- Added new special detective role: the sapper
- Added convar to control whether killer notification messages are enabled (enabled by default)

### Developer
- Added `TTTDeathNotifyOverride` hook to allow developers to change what name and role shows in the death notification message
- Added `plymeta:CanSeeC4` to determine whether the player can see the C4 radar icon like traitors
- Added ability for external roles to define their own `plymeta:CanSeeC4`
- Changed the `TTTC4Disarm` hook to allow changing the defusal result via the new return value

## 1.5.13 (Beta)
**Released: May 6th, 2022**

### Changes
- Increased head icon offset when a player's head is scaled up so the icon is visible on models with larger heads
- Changed the shop to only be openable if the player has buyable items (previously this behavior only happened when shop-for-all was enabled)

### Fixes
- Fixed binoculars showing while a player is dead if they died while their binoculars are out

## 1.5.12 (Beta)
**Released: April 23rd, 2022**

### Additions
- Added ability for mad scientist to respawn as a zombie when they die (disabled by default)

### Fixes
- Fixed zombie respawn notification getting trampled by the "medium can sense your spirit" notification
- Fixed minor grammatical problem in the zombie tutorial when the role is renamed

### Developer
- Added `plymeta:IsZombifying()` to check whether a player is respawning as a zombie
- Added `plymeta:RespawnAsZombie()` to allow respawning a player as a zombie

## 1.5.11 (Beta)
**Released: April 16th, 2022**

### Additions
- Added ability for beggar to be on the independent team (disabled by default)

### Fixes
- Fixed bodysnatcher role popup and tutorial not showing the correct team when they are configured to be independent

### Developer
- Added new `TTTRolePopupRoleStringOverride` hook to allow overriding the role string used when building the role start-of-round popup

## 1.5.10 (Beta)
**Released: April 9th, 2022**

### Additions
- Added model for the detective binocular weapon

### Fixes
- Fixed rare case where a player could get the role weapons from their previous role in a new round

## 1.5.9 (Beta)
**Released: April 3rd, 2022**

### Changes
- Changed head icon height calculation again to hopefully help more with model scaling

### Fixes
- Fixed beggar converted to innocent still showing as a jester to traitors when ttt_beggar_reveal_innocent was set to "traitors"

## 1.5.8
**Released: March 22nd, 2022**\
Includes beta updates [1.5.6](#156-beta) and [1.5.7](#157-beta).

### Fixes
- Fixed roles without shops by default belonging to teams that normally get shops by default not having the "shop sync" convars created
- Fixed error using search in shop or role weapons config menu
- Fixed loot goblins being shown in traitor vision when it was enabled

## 1.5.7 (Beta)
**Released: March 19th, 2022**

### Additions
- Added convars to control whether the assassin is allowed to kill the loot goblin, zombie, or vampire even if they aren't the target (enabled by default)
- Added ability for search in role shop and roleweapons config menu to search by item description as well
- Added ability for jester and swapper to have their max health reduced by a health station instead of being healed (enabled by default)

### Changes
- Changed zombies to no longer be able to drown
- Changed the activated clown to be able to see other jesters so they don't kill them
- Changed the jester to win, like normal, if they are somehow to killed by other members of the jester team
- Changed the parasite cure to be available to all special detectives when the parasite is enabled

### Fixes
- Fixed beggar changed to traitor showing traitor highlighting when beggar reveal is disabled
- Fixed bodysnatcher changed to traitor showing traitor highlighting when bodysnatcher reveal is disabled
- Fixed scoreboard search icons not having tooltips due to them refreshing too often
- Fixed body armor icon showing when the info UI was not (e.g. when scoped in and when the main menu is open)
- Fixed glitch being revealed by assassin target information on the scoreboard when ttt_glitch_mode was not the default of 0
- Fixed casing on "A Drunk has remembered their role" message
- Fixed roleweapons config menu not applying search bar value when updating the same role as the one the search was used on
- Fixed tooltip on bomb station not updating if a player's role changed after it was placed
- Fixed role checks not starting for the role with the highest role ID

### Developer
- Added new `plymeta:ShouldNotDrown` to determine if a player should drown
- Added new `ROLE.shouldnotdrown` optional rule for external roles
- Added `should_reduce` parameter to `TTTPlayerUsedHealthStation` hook
- Added ability for entities to use a function for their `TargetIDHint` value

## 1.5.6 (Beta)
**Released: March 6th, 2022**

### Additions
- Added the ability for loot goblins to regenerate health under certain circumstances
  - By default, the loot goblin will now regen health slowly while standing still

### Fixes
- Fixed players whose roles are changed to loot goblin not being granted the jump boost
- Fixed old man's view being stuck if their adrenaline rush activated while they were using a scoped weapon (Thanks Lillie!)

## 1.5.5
**Released: February 28th, 2022**\
Includes all beta updates from [1.5.1](#151-beta) to [1.5.4](#154-beta).

## 1.5.4 (Beta)
**Released: February 26th, 2022**

### Additions
- Added ability to control how often a revenger loses health after their lover is killed, if that is enabled

### Fixes
- Fixed body armor icon not going away once you died
- Fixed players converted to vampire not being unfrozen immediately

## 1.5.3 (Beta)
**Released: February 23rd, 2022**

### Additions
- Added ability to hide weapon ammo display
- Added ability to hide a special detective's true role, showing "detective" everywhere instead
  - This can be set to only hide the role for other players (e.g. the special detective can see their real role but others can't) or for everyone

### Fixes
- Fixed assassin target information not being cleared from the scoreboard if an assassin's role was changed
- Fixed parasite infection not being cured on a player if they resurrected the parasite and changed their role
- Fixed phantom haunting state not being cleared when their role was changed

### Developer
- Added new `TTTTutorialRoleTextExtra` hook to allow addons to provide more text information for a role's tutorial page
- Added new `TTTTutorialRolePageExtra` hook to allow addons to manipulate the tutorial page controls for a role
- Added new `TTTRolesLoaded` hook which is called after all roles and role modifications and loaded
- Added new `TTTRoleRegistered` hook which is called after an external role has been registered
- Added the ability to load role modifications immediately after roles are initially loaded
- Added the ability to spread external role logic between client, server and shared files
- Added convars for default roles to ROLE_CONVARS table to allow for dynamic loading with ULX

## 1.5.2 (Beta)
**Released: February 20th, 2022**

### Additions
- Added shield icon on the left of the health bar when a player has body armor equipped
- Added icons for speed and regeneration equipments to the body search dialog
- Added ability to control which parts of the corpse search window are visible to non-detectives (if ttt_detective_search_only is disabled)

### Fixes
- Fixed HL2 neurotoxin suit overlay showing when a player took poison damage
- Fixed veteran damage bonus getting removed if something assigned them the same role again
- Fixed players not always being able to look at a body that was already searched by a detective when ttt_detective_search_only is enabled

## 1.5.1 (Beta)
**Released: February 12th, 2022**

### Fixes
- Fixed a few cases where roles without items in their shop could open the shop when Shop For All was enabled

### Developer
- Removed deprecated global `GenerateNewEventID` from the client realm. Use the `TTTSyncEventIDs` hook instead
- Removed deprecated global `GenerateNewWinID` from the client realm. Use the `TTTSyncWinIDs` hook instead
- Changed custom win and event tracking to be protected against file reloading, preventing errors while debugging

## 1.5.0
**Released: February 9th, 2022**\
Includes all beta updates from [1.4.5](#145-beta) to [1.4.9](#149-beta).

### Changes
- Changed vampire unfreeze delay to be longer by default to help vampires with high pings
- Changed vampire fang usage hint to be translatable and to show that the primary fire button must be held to drain blood

### Fixes
- Fixed very minor bug with loadout items hook, making it consistent with normal shop usage
- Fixed vampire fang usage hint not showing
- Fixed roles without shop items being able to open the shop and to loot credits if Shop For All was enabled
- Fixed old man being invincible if adrenaline rush was disabled
- Fixed errors displaying radar points when there was a decoy being used
- Fixed roles added after the initial load not showing their role icon in the body search dialog
- Fixed some external role icons not working in the body search dialog

### Developer
- Renamed HUD namespace to CRHUD to avoid conflicts

## 1.4.9 (Beta)
**Released: February 6th, 2022**

### Fixes
- Fixed shop sync not working for custom equipment items for special detectives
- Fixed external detective roles not being able to be configured to disallow looting credits

## 1.4.8 (Beta)
**Released: January 29th, 2022**

### Changes
- Changed loot goblin activation timer to be a random number of seconds within a configurable range

### Developer
- Added new hooks for controlling who, when, and how many credits to award when players are killed

## 1.4.7 (Beta)
**Released: January 23rd, 2022**

### Additions
- Added map name to scoreboard and round summary title
- Added "Find my role" button to the tutorial page

### Changes
- Changed head icon placement to hopefully work better with scaled-up heads

### Fixes
- Fixed detective-like players (deputy, impersonator) not being promoted when the active detective team player's role is changed
- Fixed veteran buff state not being reset if their role was changed
- Fixed role logic not starting if someone's role was changed

## 1.4.6 (Beta)
**Released: January 15th, 2022**

### Changes
- Changed role selection logic to shuffle the list of players to hopefully help the randomization
- Changed role vision logic to hopefully increase performance for traitors

### Fixes
- Fixed error caused by vampire fangs when trying to consume a body that didn't contain player information
- Fixed the "A loot goblin has been spotted!" message not updating when the role is renamed

### Developer
- Added ability to pass a table of role data to the TTTScoringSecondaryWins hook to customize how secondary wins are displayed
- Reworked Event ID and Win ID generation to fix case where external roles could have their conditions conflict due to the client and server not generating IDs in the same order. This involved the following changes:
  - **BREAKING CHANGE** - Deprecated `GenerateNewEventID` on the client and made it a no-op that prints an error message reminding the developer to update
  - **BREAKING CHANGE** - Deprecated `GenerateNewWinID` on the client and made it a no-op that prints an error message reminding the developer to update
  - Added TTTSyncEventIDs hook to allow developers to get generated Event IDs on the client after they have been synced
  - Added TTTSyncWinIDs hook to allow developers to get generated Win IDs on the client after they have been synced

## 1.4.5 (Beta)
**Released: January 8th, 2022**

### Additions
- Added the ability to show karma on the scoreboard as a percentage of the total
- Added the ability to re-add score and deaths columns to the scoreboard
- Added the ability to rearrange and disable the tabs in the round summary window
- Added more incompatible addons to the list

### Fixes
- Fixed assassin being penalized for killing the loot goblin

## 1.4.4
**Released: December 30th, 2021**

### Fixes
- Fixed old man's adrenaline rush ability being triggered by things that don't cause damage (Thanks for the idea Spaaz)
- Fixed error in disguiser UI caused by refactoring

## 1.4.3
**Released: December 15th, 2021**\
Includes all beta updates from [1.4.1](#141-beta) to [1.4.2](#142-beta).

### Changes
- Changed parasite cures (real and fake) to mention in the message that it's directed at traitors

### Fixes
- Fixed parasite's infection conflicting with the brain parasite weapon from the workshop
- Fixed voice chat UI error

## 1.4.2 (Beta)
**Released: December 10th, 2021**

### Additions
- Added ability to allow spirits to see each other when there is a medium (enabled by default)

### Changes
- Ported change from base TTT: "TTT uses new permissions.EnableVoiceChat"
- Changed large parts across most of the addon in an attempt to increase performance

### Fixes
- Fixed bodysnatcher killed event redefining existing event ID
- Fixed freeze in round summary when a player has multi-byte characters in their name
- Fixed round summary highlights player stats spacing
- Fixed killing a jester team member causing the team kill "awards" to show on the round summary highlight tab
- Fixed medium being told there was a medium when they died
- Fixed assassin not getting a new target when their target's role changes to one that is an invalid target

### Developer
- Added parameter to `GenerateNewEventID` to allow roles to associate generated event IDs back to the role
- Added warning message to `GenerateNewEventID` when role parameter is missing so developers know to update
- Added parameter to `GenerateNewWinID` to allow roles to associate generated win IDs back to the role
- Added warning message to `GenerateNewWinID` when role parameter is missing so developers know to update

*NOTE*: If the role parameter is not passed, we try to figure out the role that the generated ID belongs to but this is not promised to work. Developers should update to use the new parameter as soon as possible. Developers who are using these methods to generate IDs not linked to roles should pass `ROLE_NONE`.

## 1.4.1 (Beta)
**Released: December 4th, 2021**

### Additions
- Added ability to give the impersonator credits when they are activated (disabled by default)
- Added ability to configure a chance for a promoted impersonator to spawn instead of a detective (disabled by default)
- Added ability to remind players that there is a medium when they die (enabled by default)

### Changes
- Changed old man to lose karma if they hurt or kill players when their adrenaline rush is not active
- Changed so innocents that hurt or kill the old man will lose karma
- Changed old man adrenaline rush logic so it shows what player ultimately killed them in chat rather than "You killed yourself"
- Changed old man adrenaline rush message to also show in the center of the screen to make it more obvious when it's happening

### Fixes
- Fixed loot goblin and old man not sharing a timelimit win with the innocents
- Fixed loot goblin and old man not sharing a win with each other (if they are both in the same round) on the round summary screen

### Developer
- Changed TTTCanIdentifyCorpse and TTTCanSearchCorpse hooks to allow changing the corpse's stored role
- Fixed TTTWinCheckComplete not being called when the win type was WIN_TIMELIMIT
- Added new TTTScoringSecondaryWins hook to allow multiple roles to have secondary wins at the same time
- **BREAKING CHANGE** - Removed secondaryWinRole parameter from TTTScoringWinTitle hook

## 1.4.0
**Released: November 15th, 2021**\
Includes all beta updates from [1.3.1](#131-beta) to [1.3.7](#137-beta).

## 1.3.7 (Beta)
**Released: November 13th, 2021**

### Fixes
- Fixed player tag overlapping role icon on the scoreboard
- Fixed error when bodysnatcher tried to snatch a deputy's body when the detective had been killed, preventing the bodysnatcher deputy from being promoted
- Fixed ttt_logic_role entity ROLE_ANY checks not working as expected

### Developer
- Split API document into multiple files to make it easier to navigate and maintain
- Fixed ttt_kill_target_from_random and ttt_kill_target_from_player not working when the remove_body parameter was given
- Added ttt_damage_* commands which damage the target to aid in development and debugging

## 1.3.6 (Beta)
**Released: November 6th, 2021**

### Additions
- Added ability to configure killer knife attack speed and damage
- Added ability for quack to buy an item which converts a health station into a bomb station (disabled by default)
- Added adjustable speed and stamina recovery boost to activated loot goblin

### Fixes
- Fixed some role round start popup message spacings

### Developer
- Added TTTSprintStaminaRecovery hook to allow adjusting how fast a player's stamina is recovered

## 1.3.5 (Beta)
**Released: October 26th, 2021**

### Fixes
- Fixed roles without weapons assigned directly to them (like deputy) not being able to open their shops in certain circumstances
- Fixed loot goblin not counting as a "passive win" role for living checks

### Developer
- Added TTTTargetIDPlayerBlockIcon and TTTTargetIDPlayerBlockInfo hooks to block target ID information more easily

## 1.3.4 (Beta)

**Released: October 25th, 2021**

### Changes
- Changed addon incompatibility check to ignore disabled addons

### Fixes
- Fixed devices which change a player's role while resurrecting them not using the configured health and max health for the target role
- Fixed bodysnatching device not updating the owner's max health to match that of their new role
- Fixed loot goblin announcement timer not pausing if a goblin is killed and resurrected as a different role (by a hypnotist, for example)
- Fixed parasite whose role changes after they are killed not having their infection cleared from their target

### Developer
- Moved role icons and sprites to their own folders

## 1.3.3 (Beta)
**Released: October 24th, 2021**

### Fixes
- Fixed deputy and impersonator not being promoted if they spawned in a round without a detective team role and ttt_deputy_impersonator_promote_any_death was enabled
- Fixed loot goblin jump height calculation to work for more size scales than just the default

## 1.3.2 (Beta)
**Released: October 21st, 2021**

### Additions
- Added ability for an old man having an adrenaline rush to have target ID information (icon over the head, ring and text when you look at them) (enabled by default)
- Added ability to control whether the old man plays the rambling speech sound when they are having an adrenaline rush (enabled by default)
- Added ability to control whether the loot goblin plays its cackle and/or jingle sounds (enabled by default)

### Changes
- Updated some of the loot goblin's text (tutorial, round start popup) to add clarity and fix minor errors
- Changed loot goblin to jump higher once they are activated to compensate for their smaller size

### Fixes
- Fixed error in the round after one with a loot goblin that didn't activate
- Fixed convar creation order causing error related to the ttt_drunk_can_be_ convars and ULX

## 1.3.1 (Beta)
**Released: October 20th, 2021**

### Additions
- Added the loot goblin
- Added tutorial pages for all roles
- Added ability to allow the deputy to use their shop before activation (disabled by default)
- Added ability to delay a deputy's shop purchases until they are activated (disabled by default)
- Added ability to give a deputy some credits when they activate (disabled by default)
- Added ability for a clown to see and use traitor traps when they activate (disabled by default)
- Added ability to configure the amount of damage the killer's crowbar does (when bashing or throwing)
- Added ability to configure the amount of damage the old man's shotgun does
- Added ability to limit the number of times a beggar can respawn, if that is enabled (disabled by default)
- Added ability to have the bodysnatcher respawn if they are killed before they use their device (disabled by default)
- Added ability to use common jester notifications (message, sound, confetti) when the bodysnatcher is killed (disabled by default)
- Added ability to make the paramedic defib rebuyable if ttt_paramedic_device_shop is enabled (disabled by default)
- Added ability to make the hypnotist brainwashing device rebuyable if ttt_hypnotist_device_shop is enabled (disabled by default)
- Added ability to prevent the drunk and clown from being selected in the same round (disabled by default) (Thanks Matty!)
- Added ability to show loadout equipment in shops (disabled by default)
- Added ability to configure the amount of time the various role devices take to be used
  - Bodysnatching Device
  - Hypnotist's Brainwashing Device
  - Mad Scientist's Zombificator
  - Paramedic's Defibrillator
  - Phantom Exorcism Device
  - Doctor's Parasite Cure
  - Quack's Fake Parasite Cure

### Changes
- Changed vampire fang unfreeze logic to hopefully fix rare case where the target would stay frozen if the vampire was killed
- Updated Parasite Cures and Phantom Exorcism device to use renamed role strings
- Removed support for old version of role and shop convars, originally deprecated in v1.0.14

### Fixes
- Fixed teamkilling monster team members not having their karma reduced
- Fixed renaming jester, swapper, or beggar causing errors when trying to show killed notifications
- Fixed clown not winning the round when just them and the old man are left alive
- Fixed error using role colors on the client before the first round preparation phase
- Fixed "beggar converted to innocent" entry in the round summary Events tab using the "traitor" icon
- Fixed vampire eating a body not dropping bones
- Fixed special detectives (paladin, medium, tracker) not counting as detectives in the ttt_logic_role entity
- Fixed error when selecting weapon after respawning a parasite

### Developer
- Added ability to define a role as on that wins passively (like the old man)
- Added parameter to `player.AreTeamsLiving` to ignore players who win passively (like the old man)
- Added `player.TeamLivingCount` and `player.LivingCount` to help tracking how many players are alive
- Added `player.GetTeamPlayers` to get all the players belonging to a player
- Added `player.ExecuteAgainstTeamPlayers` to execute a function against the players belonging to a role team
- Added TTTWinCheckBlocks and TTTWinCheckComplete hooks to allow manipulating and reacting to the win type
- Added TTTHUDInfoPaint hook to add informational messages to a player's HUD (above their health bar)
- Added TTTPlayerAliveClientThink hook to handle the Think event for each currently living player on the client
- Added TTTRadarRender hook to handle custom radar entry rendering
- Added TTTPlayerDefibRoleChange hook to handle a player being resurrected as a different role
- Added TTTSpectatorShowHUD hook to handle showing a player a spectator HUD
- Added TTTSpectatorHUDKeyPress hook to handle the key press event for a player who should be viewing a spectator HUD
- Added `plymeta:Celebrate` to celebrate with sound and or confetti
- Added `plymeta:ShouldShowSpectatorHUD` to determine whether a player should have a spectator HUD displayed
- Added `HUD:PaintPowersHUD` method to render phantom-like spectator HUD in a generic way
- Changed radar's `DrawTarget` method to be accessible in the RADAR namespace as `RADAR:DrawTarget`
- Changed HUD's `PaintBar` and `ShadowedText` methods to be accessible in the HUD namespace as `HUD:PaintBar` and `HUD:ShadowedText` respectively
- Changed `JesterTeamKilledNotification` to be globally accessible
- Renamed `SWEP.BoughtBuy` to `SWEP.BoughtBy`
- Removed deprecated global `ShouldHideJesters`. Use `plymeta:ShouldHideJesters` instead

## 1.3.0
**Released: October 5th, 2021**\
Includes all beta updates from [1.2.4](#124-beta) to [1.2.9](#129-beta).

## 1.2.9 (Beta)
**Released: October 24th, 2021**

### Additions
- Added a check that prints incompatible addons to the console when the server starts

### Developer
- Added CR_BETA flag to check whether the version being played is a beta or release version

## 1.2.8 (Beta)
**Released: October 3rd, 2021**

### Additions
- Added ability for independents to see missing in action players on the scoreboard (disabled by default) (Thanks Matty!)
- Added ability for the killer to see missing in action players on the scoreboard (enabled by default) (Thanks Matty!)
- Added ability to control whether a vampire can loot credits (enabled by default)
- Added ability to control whether special detectives (all detective roles other than the original detective itself) get armor automatically for free (enabled by default)

## 1.2.7 (Beta)
**Released: October 2nd, 2021**

### Additions
- Added ttt_roleweapons admin command which opens a configuration interface for the roleweapons shop configuration system
- Added new dynamic tutorial system using HTML and hook-generated pages per role
- Added ability to reward vampires with credits when they drain a living target using their fangs (disabled by default)
- Added ability to set a different amount of health overheal if a vampire drains a living target (disabled by default)
- Added ability to block rewarding vampires when they (or their allies) kill someone (disabled by default)
- Added ability to give the veteran credits when they are activated (disabled by default)
- Added ability to set the maximum number of players before "single jester or independent" is automatically disabled (disabled by default)

### Changes
- Changed custom win events to show in the end-of-round summary's Events tab with an "unknown win event" message until the new TTTEventFinishText hooks are used

### Fixes
- Fixed vampire prime death effects still happening after the round has ended
- Fixed external roles with custom win conditions blocking jester wins
- Fixed tip about radio usage not using the correct key
- Fixed assassin being shown "No targets remaining" after already being told their current target was their final target
  - This does allow players who are resurrected after the assassin is assigned their final target to slide under the radar
- Fixed roles with custom win conditions being able to block jester, clown, and old man wins as well as drunks remembering their role
- Fixed traitor vampires being able to drain glitches
- Fixed promoted deputies not being grouped with other detectives in assassin targeting logic
- Fixed independent vampire popup still having "{comrades}" placeholder
- Fixed a drunk who becomes a clown in the same round as another jester role showing in the same row on the round summary screen
- Fixed error when a vampire is killed after they release a target being drained but before that target gets unfrozen

### Developer
- Added TTTBlockPlayerFootstepSound hook to block a player's footstep sound
- Added TTTKarmaGiveReward hook to block a player from receiving karma
- Added TTTKarmaShouldGivePenalty hook to determine whether a player should have their karma rewarded or penalized
- Added TTTPlayerSpawnForRound hook to react to when a player is spawned (or respawned)
- Added TTTEventFinishText and TTTEventFinishIconText hooks to add detail to the round finished event row for custom win conditions
- Added TTTPlayerRoleChanged hook to react to when a player's role changes
- Added TTTShouldPlayerSmoke hook to affect whether a player should smoke and how that should look
- Added TTTTutorialRolePage, TTTTutorialRoleText, and TTTTutorialRoleEnabled hooks for generating tutorial pages for an external role
- Added TTTRolePopupParams hook to allow roles add parameters to their start-of-round popup message translation
- Added `startingRole` and `finalRole` parameters to the TTTScoringSummaryRender hook
- Added `plymeta:GetRoleTeam` to get the appropriate `ROLE_TEAM_*` enum value for the player
- Added `plymeta:ShouldDelayAnnouncements` to determine whether announcements when a player is killed should be delayed for this player
- Added `player.GetLivingRole`, `player.IsRoleLiving`, and `player.AreTeamsLiving` static methods
- Added `player.GetRoleTeam` static method to get the appropriate `ROLE_TEAM_*` enum value for a role
- Added ability for external roles to define their role selection predicate function
- Added ability for external roles to run specific logic when a player is initially assigned a role or when they steal a role from someone else
- Added `GetRoleTeamInfo` and `GetRoleTeamName` global methods
- Changed `OnPlayerHighlightEnabled` to be globally available so other roles can use the same highlighting logic
- Changed all `EXTERNAL_ROLE_*` tables to be named `ROLE_*` in preparation for role separation
- Fixed returning false for the first parameter of TTTTargetIDPlayerRoleIcon not stopping the role icon from showing

## 1.2.6 (Beta)
**Released: September 25th, 2021**

### Fixes
- Fixed external roles with long names and custom win conditions having their win title cut off
- Fixed map wins being ignored when an external role with a custom win condition was in use

### Developer
- Fixed generated win and event identifiers resetting if lua is refreshed

## 1.2.5 (Beta)
**Released: September 25th, 2021**

### Additions
- Added ability to have a jester and an independent both spawn in the same round (disabled by default)
- Added ability for deputy/impersonator to be promoted when any detective dies, rather than all detectives (disabled by default)
- Added ability for deputy to spawn when there isn't a detective and be pre-promoted (disabled by default)
- Added ability for impersonator to spawn when there isn't a detective and be pre-promoted (disabled by default)
- Added ability to configure zombie conversion to be based on chance, separately for prime and thralls (disabled by default)
- Added ability for a paramedic's defib to convert all roles to a vanilla innocent (disabled by default)
- Added ability to add the hypnotist's device to their shop (disabled by default)
- Added ability to add the paramedic's defib to their shop (disabled by default, requires shop-for-all to be enabled)
- Added ability to control whether the hypnotist spawns with their device (enabled by default)
- Added ability to control whether the paramedic spawns with their defib (enabled by default)
- Added ability for hypnotist device to convert detective and deputies that appear as detective to impersonator (disabled by default)
- Added ability for traitor or quack to buy an exorcism device usable to remove a haunting phantom (disabled by default)
- Added configuration for whether assassin damage bonus applies to weapons bought from the shop (enabled by default)
- Added ability for bodysnatcher's role change to be hidden based on which team they joined (disabled by default)
- Added a shop icon for the bomb station
- Added new microphone volume tip from base TTT

### Changes
- Changed beggar to not be able to use or see traitor chat (text or voice) when the beggar reveal mode is disabled for traitors
- Changed credit-lootable roles without a shop (like the trickster) to have starting credits convars
- Changed bodysnatcher to automatically be given any role weapons the body had on them when they died
- Changed bodysnatcher to inherit an assassin's target (or be given a new one) when they snatch an assassin's body

### Fixes
- Fixed zombies sometimes spawning in non-zombie rounds if they are on the traitor team
- Fixed beggar who converted to traitor and then was resurrected by a hypnotist not showing as a traitor when beggar reveal was disabled for traitors
- Fixed some buyable role weapons showing the "custom" icon in the shop
- Fixed resurrected players getting their full loadouts even if they've already used their one-use weapons (like the hypnotist brainwashing device)
- Fixed potential case where assassin's new target would get immediately cleared if a delay wasn't being used

### Developer
- Added ability for external roles to define when they are "active", tying directly into the `plymeta:IsRoleActive` function
- Added `plymeta:ShouldActLikeJester` to determine if a player should act like a jester (damage in, damage out, appearance, etc.)
- Added ability for external roles to define if/when they should act like a jester, tying directly into the `plymeta:ShouldActLikeJester` function
- Added `GenerateNewEventID` method for generating a unique ID for custom scoring events
- Added `GenerateNewWinID` method for generating a unique ID for custom win conditions
- Added TTTTargetIDPlayerHealth hook for controlling what text to show when rendering a player's health
- Added TTTTargetIDPlayerKarma hook for controlling what text to show when rendering a player's karma
- Added TTTTargetIDEntityHintLabel hook for controlling what text to show when rendering a player or entity's hint label
- Added TTTTargetIDPlayerHintText hook for controlling what text to show when rendering an entity's hint text
- Added TTTTargetIDPlayerName hook for controlling what text to show when rendering a player's name
- Added TTTTargetIDRagdollName hook for controlling what text to show when rendering a ragdoll's name
- Added `plymeta:ShouldRevealBeggar` to determine if a player should be able to tell that a target player is no longer a beggar (e.g. converted to an innocent or traitor)
- Added `plymeta:ShouldRevealBodysnatcher` to determine if a player should be able to tell that a target player is no longer a bodysnatcher (e.g. has snatched a role from a dead body)
- Added `was_bodysnatcher` property to TTTRadarPlayerRender hook's `tgt` parameter
- Changed the global `ShouldHideJesters` to be deprecated in favor of `plymeta:ShouldHideJesters`
- Fixed returning false for either text value in TTTTargetIDPlayerText hook not actually stopping the original text from being used
- Fixed ttt_debug_preventwin not blocking when TTTCheckForWin returns a value or when the round time ends
- Fixed `plymeta:SoberDrunk` not calling PlayerLoadout hook when granting the player their new role loadout

## 1.2.4 (Beta)
**Released: September 15th, 2021**

### Additions
- Added ability for the old man to enter an adrenaline rush and hold off death for 5 seconds (enabled by default)
- Added double barrel shotgun which is given to the old man when they enter an adrenaline rush (enabled by default)

## 1.2.3
**Released: September 15th, 2021**

### Additions
- Added version number to the scoreboard and round summary title bar
- Added ability for the bodysnatcher to be on the independent team (disabled by default)
- Added ability for vampires to be on the independent team (disabled by default)

### Fixes
- Fixed jesters being marked in pink on a traitor's radar when ttt_jesters_visible_to_traitors was disabled
- Fixed beggars showing as their new role on a traitor's radar when ttt_beggar_reveal_traitor was not 1 or 2
- Fixed killer clowns showing on radar after they are activated if ttt_clown_hide_when_active is enabled
- Fixed error in the radar when ttt_glitch_mode was 2
- Fixed round ending when a swapper is killed by the last member of one of the teams but the attacker remains alive

### Developer
- Added `ShouldHideJesters` global function to determine whether the given player should hide a jester player's role
- Added ability for external roles to define:
  - Starting credits
  - Starting health
  - Maximum health
  - Extra translations
- Added TTTTargetIDPlayerRing hook which allows overriding whether the Target ID ring is shown and what color it should be shown as
- Added `nameLabel` parameter to TTTScoringSummaryRender hook, allowing you to override what is displayed for a player's name
- Added TTTRadarPlayerRender hook which allows overriding whether a radar ping is shown and what color it should be shown as
- Added TTTSelectRoles*Options for each team to allow external roles to affect the available roles and their weights
- Added new table methods
  - `table.IntersectedKeys`
  - `table.UnionedKeys`
  - `table.ExcludedKeys`
  - `table.LookupKeys`
  - `table.ToLookup`

## 1.2.2
**Released: September 12th, 2021**

### Additions
- Added ability to allow anyone to use binoculars to inspect bodies (disabled by default)
- Added ability to give the veteran a shop when they are activated (enabled by default)
- Added ability to delay giving shop weapons to the veteran until after they are activated (disabled by default)
- Added ability to set the vampire fangs to drain their target first rather than convert first (disabled by default)

### Fixes
- Fixed error trying to give a loadout equipment item as a weapon at the start of the round
- Fixed some equipment item states not being properly reset if they were part of a custom role loadout due to the loadout being added during the prep phase as well as during the active round
- Fixed translations in C4 UI not working sometimes
- Fixed a player who is turning into a zombie not stopping the round from ending
- Fixed medium ghosts creating shadows
- Adjusted medium ghost logic to hopefully fix another "floating kleiner" case

### Developer
- Added `plymeta:GiveDelayedShopItems` to give a player their delayed shop items
- Added `plymeta:IsRoleActive` to determine if a player's role feature is active
- Added `plymeta:ShouldDelayShopPurchase` to determine if a player's shop purchases should be delayed
- Added `DELAYED_SHOP_ROLES` lookup table for roles whose shop purchases can be delayed

## 1.2.1
**Released: September 6th, 2021**

### Fixes
- Fixed external roles not being able to give equipment items in their loadout

## 1.2.0
**Released: September 5th, 2021**\
Includes all beta updates from [1.1.4](#114-beta) to [1.1.11](#1111-beta).

## 1.1.11 (Beta)
**Released: September 5th, 2021**

### Fixes
- Fixed case where the medium ghosts would temporarily show up as floating kleiner models

## 1.1.10 (Beta)
**Released: September 4th, 2021**

### Additions
- Added the option to set the amount of time it takes a vampire to drain a dead body to a different amount of time than if the target is alive (disabled by default)
- Added option to enable shop for all roles (disabled by default)

### Fixes
- Fixed vampires not being able to drain dead players
- Fixed traitors being able to see detective, special detective, and clown icons through walls

## 1.1.9 (Beta)
**Released: September 2nd, 2021**

### Additions
- Added the option for the drunk to become any enabled role except for another drunk or the glitch (disabled by default)
- Added the option for the drunk to become the clown if the round would end before they sober up (disabled by default)
- Added the option to notify players when the drunk sobers up (disabled by default)
- Added the option for the paladin's damage reduction aura to protect themselves (disabled by default)
- Added the option for the paladin's healing aura to heal themselves (enabled by default)
- Added the option for the quack's fake parasite cure to kill uninfected users (disabled by default)
- Added a message that is displayed when a traitor picks up a parasite cure to distinguish if it is real or fake

### Changes
- Changed the quack's fake parasite cure to display as a real parasite cure

### Fixes
- Fixed mad scientist's zombificator, bodysnatcher's bodysnatching device, and paramedic's defib being usable on fake bodies with odd side effects
- Fixed bodysnatcher's bodysnatching device showing and taking the corpse player's current role rather than the role on the corpse (relevant for fake bodies and things that resurrect without destroying the body)
- Fixed case where multiple vampires draining the same target would have the target unfreeze when any of the vampires quit draining
- Fixed assassin not being able to see which players are infected by a parasite on the scoreboard
- Fixed only assassin target or parasite infection showing on the scoreboard and target ID (when you look at a player) even if a player should see both

### Developer
- Updated `GetTeamRoles` to take an optional lookup table of excluded roles
- Changed TTTScoringWinTitle hook to allow dynamically setting a secondary win role (like the old man)
- Added new hooks to handle cases where a player would want to appear as a different role in-game
  - TTTScoreboardPlayerRole - What role/color the player should show as on the scoreboard
  - TTTScoreboardPlayerName - What name the player should have on the scoreboard (useful for adding things like the assassin's "(TARGET)")
  - TTTTargetIDPlayerKillIcon - Whether the "KILL" icon should be shown over the target's head
  - TTTTargetIDPlayerRoleIcon - What role icon and background color should be shown over the target's head
  - TTTTargetIDPlayerText - What text and color to use for the Target ID (when you look at a player)
- Added `SWEP.ShopName` to weapon_tttbase to allow for weapons to have different names for when they are in the shop as opposed to when they are an entity in world

## 1.1.8 (Beta)
**Released: August 26th, 2021**

### Additions
- Added ability for glitch to see and use traitor traps (disabled by default)
- Added ability for a phantom to lose their powers if their body is destroyed (disabled by default)
- Added ability to remove all detective roles' ability to loot credits from corpses (disabled by default)
- Added the option for the mediums' spirits to be colored similar to tracker footsteps (enabled by default)

### Changes
- Changed round summary role tooltip to be translatable
- Changed some role features to give the player bonus points when used successfully (hypnotist, bodysnatcher, swapper, beggar)

### Fixes
- Fixed the detective's DNA scanner not being removed when they should have lost their role weapons
- Fixed external monster roles not naturally spawning
- Fixed credit message popping up for detectives when ttt_det_credits_traitordead was 0
- Fixed error opening the shop when checking whether a weapon is equipment and it is missing a core method
- Fixed round summary highlight tab not showing the correct number of traitors
- Fixed potential error in vampire fangs when the vampire lost their target
- Fixed paladin heal removing a player's overheal
- Fixed minor issue where a role could be set to not being a shop role but still have shop role convars created
- Fixed special traitors having orange radar pings when glitch mode was set to 2
- Fixed medium spirit positions updating infrequently

### Developer
- Changed more aspects of role creation to be dynamic
  - Adding icons to the download list
  - Creation of ttt_force_{ROLENAME} commands
  - Role selection logic
  - Role default buyable equipment
- Added `GetRoleTeamColor` global client method for getting the color for a role team
- Added ability to give a player bonus points via a scoring event if the sid64 and bonus properties are set
- Added ability for external roles to explicitly deny credit looting and traitor button usage via the `canlootcredits` and `canusetraitorbuttons` role table properties

## 1.1.7 (Beta)
**Released: August 22nd, 2021**

### Additions
- Added the medium
- Added the ability to give clowns bonus health if they are healed when they are activated
- Added message to the clown if they are healed when they activate
- Added role name to mouseover for icons on the round summary
- Added monster support for external roles

### Changes
- Changes bloody phantom killer footsteps to have priority over tracker footsteps

### Fixes
- Fixed beggar role being revealed on a traitor's scoreboard even if ttt_beggar_reveal_traitor was 0

### Developer
- Added missing tracker sprites to resource download list

## 1.1.6 (Beta)
**Released: August 21st, 2021**

### Additions
- Added the tracker
- Added missing force_paladin command

### Changes
- Changed paladin default damage reduction to 30%

### Fixes
- Fixed special detectives using special innocent colors
- Fixed not being able to use weapons when ttt_weaponswitcher_stay was enabled and ttt_weaponswitcher_fast was disabled
- Fixed error when trying to calculate the height of some models

### Developer
- Added `oldmanwins` parameter to TTTScoringWinTitle hook

## 1.1.5 (Beta)
**Released: August 19th, 2021**

### Fixes
- Fixed paladin not counting as an innocent
- Fixed external special detectives not counting as innocent

### Developer
- Added TTTScoringSummaryRender client hook to change how players are displayed in the round summary

## 1.1.4 (Beta)
**Released: August 18th, 2021**

### Additions
- Added special detectives
- Added the paladin

## 1.1.3
**Released: August 18th, 2021**

### Additions
- Added ability to keep weapon switch menu open when a weapon is selected and fast weapon switching is disabled

### Changes
- Changed weapon switcher to keep track of your last highlighted weapon slot and to automatically select the same one when it is refreshed

### Fixes
- Fixed an error in the round summary when a player's role was invalid
- Fixed innocent win console message saying "Innocents were defeated"

## 1.1.2
**Released: August 16th, 2021**

### Changes
- Changed the slot number in the weapon switch GUI to still be centered for 2 digit slots

### Fixes
- Fixed jesters being visible via highlighting when ttt_jesters_visible_to_* was disabled
- Fixed error in round summary caused by a player being an in invalid role state
- Fixed weapon switch GUI not updating when you picked up a new weapon and ttt_weaponswitcher_stay was enabled
- Fixed weapon switch GUI closing when you dropped a weapon and ttt_weaponswitcher_stay was enabled
- Fixed weapon switch GUI closing when you tried to drop an undroppable weapon
- Fixed player not appearing on the round summary screen if they were idled to spectator last round and only un-spectated during this round's preparation phase

### Developer
- Changed TTT_RoleChanged to use Int for role number
- Changed TTT_SpawnedPlayers to use Int for role number

## 1.1.1
**Released: August 15th, 2021**

### Fixes
- Fixed an error in round summary where an entry in the scores table did not have the 'role' property
- Fixed assassin target not showing in start of round role summary

## 1.1.0
**Released: August 15th, 2021**\
Includes all beta updates from [1.0.2](#102-beta) to [1.0.15](#1015-beta).

## 1.0.15 (Beta)
**Released: August 15th, 2021**

### Additions
- Added "Buy random equipment" button to the shop
- Added mouseover tooltip to the "Toggle favorite" button in the shop

### Changes
- Changed radio menu to default to the "n" key to avoid conflicting with the "drop ammo" key
- Changed vampire drain/convert to automatically abort if the target is converted to a vampire by someone else before you're done
- Changed the mad scientist's zombification device to have unlimited charges

### Fixes
- Fixed error in round summary when a player started the round as a role and ended as a spectator
- Fixed players not having their max health set correctly when being converted to a vampire
- Fixed players who were moved to spectator by some external addon not showing as spectator on the scoreboard
- Fixed buttons in shop being slightly misaligned

## 1.0.14 (Beta)
**Released: August 14th, 2021**

### Changes
- Reverted traitor icon to a knife instead of a handgun

### Developer
- Added TTTScoringWinTitle client hook for determining which text and color to use for the round summary screen
- Added TTTPrintResultMessage server hook for printing which team won as a message in the top-right corner

## 1.0.13 (Beta)
**Released: August 13th, 2021**

### Additions
- Added ability for assassin to have their target highlighted by an aura visible through walls (disabled by default)

### Fixes
- Re-added mistakenly deleted brainwashing device

### Developer
- Changed `Get{ROLE}Filter` functions to be dynamically assigned for each role
- Added sanity checks for external role definitions
- Added missing things to resource download list

## 1.0.12 (Beta)
**Released: August 12th, 2021**

### Fixes
- Added missing convars ttt_single_phantom_parasite and ttt_single_paramedic_hypnotist

### Developer
- Added additional replacement strings for role descriptions

## 1.0.11 (Beta)
**Released: August 11th, 2021**

### Additions
- Added convar to prevent maps from ending the round

### Fixes
- Fixed team name in monsters round start popup
- Fixed only the first weapon added or excluded via roleweapons actually being added or excluded

### Developer
- Added client-side command to reset the equipment cache
- Added ability to register convars with an external role for it to be picked up by ULX
- Changed `Get{ROLE}`, `Is{ROLE}` and `IsActive{ROLE}` functions to be dynamically assigned for each role

## 1.0.10 (Beta)
**Released: August 10th, 2021**

### Additions
- Added new mad scientist role
- Added the ability for other mods to create their own simple roles

### Changes
- Resized role name font for longer role names

## 1.0.9 (Beta)
**Released: August 9th, 2021**

### Additions
- Added ability for parasite's infection to transfer to a new player if their killer is killed (disabled by default)
    - There is also a new convar to determine whether the infection progress should be reset if the infection is transferred to a new player
- Added ability to respawn the parasite if their infected target kills themselves (disabled by default)
- Added glitch modes to allow glitches to function in rounds where there are 2 or more members of the traitor team but less than 2 regular traitors
- Added convars to prevent the paramedic and hypnotist, or the phantom and parasite from spawning together
- Added a fake parasite cure that does nothing except play the parasite cure sounds which is buyable for the quack

### Changes
- Split beggar reveal convar in two to allow finer control over when the beggar is revealed and who they are revealed to
- Separated doctor modes into 2 separate roles
    - The doctor now has a shop and can buy a health station or the parasite cure (based off doctor mode 0)
    - The paramedic has a defibrillator that cannot be dropped or used by anyone else (based off doctor mode 1)
- The quack now has to buy the bomb station from a shop instead of spawning with it
    - The quack can also buy a real health station and the parasite cure
- Changed parasite infection time to 45 seconds (down from 90)

### Fixes
- Fixed role weapons not being removed when a player is hypnotized
- Fixed multiple monsters spawning in one round

## 1.0.8 (Beta)
**Released: August 7th, 2021**

### Additions
- Added convar to have the clown's shop purchases be held back until they are activated
- Added convar to drain a revenger's health down to a specified number when their lover has died
- Re-added Radio menu and added ability to choose which button to use via the F1 menu

### Changes
- Updated the role string logic to handle more plural cases
- Updated more places to use customizable role strings
    - Round summary events
    - Round summary score table
    - Round start role popups
    - HUD messages for beggar and deputy/impersonator
    - Role logic messages
    - Equipment descriptions
    - Tips

### Fixes
- Fixed role selection message not always using custom role strings
- Fixed win message for singular roles not being properly pluralized (e.g. "THE JESTER WIN" instead of "THE JESTER WINS")
- Fixed "AND THE OLD MAN WINS" round summary message missing
- Fixed the "Highlights" round summary tab message missing the winning role name
- Fixed revenger being mislabeled as "tevenger" in some messages
- Fixed body call messages not using correct custom role articles
- Fixed promoted deputy/impersonator not being able to pick up Visualizers
- Fixed detectives showing as deputy on the scoreboard if ttt_deputy_use_detective_icon is disabled

### Developer
- Added ability for SWEP name, type, and description to use functions for formatting

## 1.0.7 (Beta)
**Released: August 4th, 2021**

### Additions
- Added convars to control whether members of the jesters teams are visible to other teams (via the head icons, color/icon on the scoreboard, etc.)
- Added ability to give the veteran a health bonus (in addition to the heal) when they are activated
- Added ability to notify other remaining players when a veteran is activated
- Added convar to control what happens when a parasite cure is used on someone who is not infected
- Added ability for the clown to always have access to their shop via a new convar
- Added convars to rename roles

### Changes
- Changed ttt_beggar_notify_sound and ttt_beggar_notify_confetti to be off by default to better match default beggar behaviour
- Changed end-of-round summary to automatically add a row if there are both independents and jesters in a round (via something like a Randomat event)
- Changed parasite cure to have a 3-second charge time to prevent it from being used as an instant-kill weapon
- Changed parasite cure to never be removed if shop randomization is enabled

### Fixes
- Fixed team player count calculations not always being accurate by truncating the "_pct" convars to 3 digits to work around floating point inaccuracy
- Fixed assassin not getting a target sometimes because they were treated as having a failed contract by default
- Fixed missing ttt_clown_shop_mode
- Fixed weapons added to detective or traitor via the roleweapons system not being buyable by roles using the shop mode convars
- Fixed old man not also winning when a map declares a winning team
- Fixed the glitch from being shown as a traitor to zombies if zombies are on the traitor team (Thanks Matty!)

### Developer
- Added the ability for SWEPs to not be randomized out of the shop by setting "SWEP.BlockShopRandomization = true"
- Renamed ROLE_STRINGS to ROLE_STRINGS_RAW

## 1.0.6 (Beta)
**Released: July 20th, 2021**

### Fixes
- Fixed detective showing deputy icon when ttt_deputy_use_detective_icon is enabled
- Fixed scoreboard icons not obeying ttt_deputy_use_detective_icon and ttt_impersonator_use_detective_icon
- Fixed error trying to assign an assassin target preventing rounds from starting when there was an assassin
- Fixed potential error picking an assassin target when ttt_assassin_shop_roles_last was enabled
- Fixed "next"/"final" label sometimes being incorrect for an assassin getting their next target if ttt_assassin_shop_roles_last was enabled

## 1.0.5 (Beta)
**Released: July 19th, 2021**

### Additions
- Added new trickster role
- Added settings to control whether the deputy/impersonator should use their own icons or the Detective icon over their head
- Added setting to have the old man have their health drained to a certain minimum value over time
- Added a message to a parasite victim when they are killed by the parasite coming back to life
- Added a message to a non-prime vampire when they are killed/reverted if the prime was killed
- Ported "TTT: add more validation to corpse commands" from base TTT
- Added new Assassin target priority convar (Thanks Matty!)
- Added new convar to heal the clown when they activate (Thanks Matty!)

### Changes
- Changed revenger to receive a different message if their lover is killed when they are already dead
- Changed deputy/impersonator to not receive a message about their promotion if they are already dead
- Changed traitors to receive a slightly different message if their dead impersonator teammate has been promoted
- Changed the killer/phantom smoke to be viewable from further away
- Changed corpse identified message to also send for non-vanilla traitors to non-vanilla innocents

### Fixes
- Fixed vampire victims getting stuck frozen if the vampire is killed while draining their blood
- Fixed error caused by trying to set a player with no role's starting health
- Fixed monster team count check when zombie was on the independent team
- Fixed revenger losing karma when they killed their soulmate's killer if they were innocent
- Fixed parasite cure showing in deputy/impersonator shop but not being buyable
- Fixed beggar who converted to a traitor still showing the traitor icon over their head even when ttt_beggar_reveal_change was disabled
- Fixed swapper/bodysnatcher not being promoted when swapping roles with a promoted deputy/impersonator
- Fixed swapper/bodysnatcher not inheriting the revenger's lover when swapping roles with a revenger
- Fixed bodysnatcher not getting zombie/vampire prime status when a prime zombie/vampire swaps with them
- Fixed bodysnatcher not being promoted when they snatch the deputy/impersonator role and no detectives are left alive
- Fixed players who were moved to spectator for being AFK not showing as dead on the end-of-round summary screen
- Fixed killer/phantom smoke not always working when multiple players should be smoking at once
- Fixed monster team occurring more than it should due to calculating the number of players too late

### Developer
- Added `plymeta:StripRoleWeapons` which removes all weapons with the `WEAPON_CATEGORY_ROLE` from a player
- Added `plymeta:MoveRoleState` which moves the role NW values from a player to a target
- Added missing things to resource download list
- Changed TTTCanIdentifyCorpse hook "was_traitor" parameter to be true for any role on the traitor team rather than just the vanilla traitor
- Added ability for non-traitor roles to be configurably able to use traitor buttons
- Added ability for non-shop roles to be configurably able to see and loot credits

## 1.0.4 (Beta)
**Released: July 11th, 2021**

### Additions
- Added new shop random position convar
- Added new convar to control how to handle weapons when a swapper is killed

### Changes
- Changed the drunk so they lose karma for hurting/killing people before they sober up

### Fixes
- Fixed ttt_*_shop_mode convars
- Fixed "Kill" icon showing over jester players' heads when the client knows they are a Jester
- Fixed swapper not getting zombie/vampire prime status when a prime zombie/vampire swaps with them

## 1.0.3 (Beta)
**Released: July 11th, 2021**

### Additions
- Added starting and max health convars to all roles

### Changes
- Changed convars to use '_ttt_ROLENAME\_\*_' formatting wherever possible
    - *NOTE*: Old convars still work at this stage but may be removed later. Please update to the new convars now to avoid problems later

## 1.0.2 (Beta)
**Released: July 11th, 2021**

### Additions
- Added ttt_clown_hide_when_active which hides the clown from player Target IDs when they are active
- Added ttt_clown_show_target_icon to show the KILL icon over targets when the clown is active
- Added convars for more zombie configurability
    - Respawn health (defaults to 100)
    - Prime Attack Damage (defaults to 65)
    - Prime Attack Delay (defaults to 0.7)
    - Prime Speed Bonus (defaults to 0.35)
    - Thrall Attack Damage (defaults to 45)
    - Thrall Attack Delay (defaults to 1.7)
    - Thrall Speed Bonus (defaults to 0.15)

### Changes
- Changed shop to not show "loadout" equipment items that you already own because you can't buy them and might not have known you were given them for free
- Changed killer's knife to not conflict with shop weapons
- Changed phantom smoke to be disabled by default
- Changed head icons to be based on player model size and scale so they have their icon in the right place
- Updated role sync documentation to hopefully make it clearer how it all works

### Fixes
- Fixed some client ConVars not saving
- Fixed equipment exclusion system accidentally excluding ALL equipment for a role
- Fixed target ID showing when a player is hidden using the prop disguiser
- Fixed improper team highlighting for zombie/vampire after they switched teams
- Fixed parasite cure being buyable when parasite is not enabled
- Fixed karma percentage on scoreboard not matching damage factor when max karma was greater than 1000
- Fixed potential errors by adding more nil protection in the vampire fangs

### Developer
- Added `plymeta:CanUseShop` method which checks `IsShopRole` and NWBools
- Added TTTSprintStaminaPost hook which can be used to overwrite player stamina
- Added resource download commands to avoid missing textures

## 1.0.1
**Released: June 30th, 2021**

### Additions
- Added an option to disable headshots

## 1.0.0
**Released: June 30th, 2021**

### Additions
- Initial release with all classic roles
