# Release Notes

## 1.6.17
**Released:**

### Additions
- Added new jester role: cupid
- Added option to enable a radar that reveals the previous location of the loot goblin (disabled by default)

### Changes
- Changed round summary panel to use increasingly smaller fonts to try and fix text into the box
- Changed vampire prime to get randomly assigned to a vampire thrall if the prime leaves the game
- Changed zombie prime to get randomly assigned to a zombie thrall if the prime leaves the game
- Changed revenger to be randomly assigned a new lover if their lover leaves the game

### Fixes
- Fixed minor typo in jester tutorial
- Fixed hypnotist device being usable on fake bodies, causing living players to change roles and teleport
- Fixed marshal's deputy badge not removing role weapons or restoring default weapons when changing someone's role
- Fixed assassin not getting new target when their current target leaves the game
- Fixed some roles with custom win conditions causing "unknown win condition" server logs when they won

### Developer
- Added new `otherName` and `label` return values to the `TTTScoringSummaryRender` hook
- Changed how the following round summary information is rendered to be cleaner and less hard-coded
  - Jester "Killed by"
  - Swapper "Killed"
  - Beggars who joined a team
  - People who were hypnotized

## 1.6.16
**Released: November 26th, 2022**

### Developer
- Deprecated `TTTPlayerDefibRoleChange`
- Added `TTTInformantScanStageChanged` which is called when an informant has scanned additional information from a target player
- Added `TTTMadScientistZombifyBegin` which is called when a mad scientist begins to zombify a target
- Added `TTTPaladinAuraHealed` which is called when a paladin heals a target with their aura
- Added `TTTPlayerRoleChangedByItem` to replace `TTTPlayerDefibRoleChange` and implemented it for bodysnatcher, hypnotist, mad scientist, marshal, paramedic, vampire, and zombie
- Added `TTTShopRandomBought` which is called when a player buys a random item from the shop
- Added `TTTSmokeGrenadeExtinguish` which is called when a smoke grenade extinguishes a fire entity
- Added `TTTTurncoatTeamChanged` which is called when the turncoat changes teams
- Added `TTTVampireBodyEaten` and `TTTVampireInvisibilityChange` to help track vampire ability usage

## 1.6.15
**Released: November 12th, 2022**

### Additions
- Added new special detective role: the marshal
- Added new special innocent role: the infected

### Changes
- Changed sprint speed to be more resistant to client-side speed hacking (Thanks wget for letting us know!)
- Changed the round summary screen to automatically lower the font size of the winning team if it's more than 18 characters, down from 20
- Changed loot goblin cackle min and max convars to not cause problems when the min is greater than the max

### Fixes
- Fixed players who respawn as zombies when `ttt_zombie_prime_only_weapons` is disabled still losing their default weapons in some cases

### Developer
- Added definition of `IsRoleActive` for the turncoat
- Added `prime` parameter to `RespawnAsZombie`

## 1.6.14
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
- Changed player role icons (over their heads) and highlighting to ignore map optimizations which prevented them from updating regularly (Thanks to wget for the logic help!)
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
    - NOTE: Old convars still work at this stage but may be removed later. Please update to the new convars now to avoid problems later

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
