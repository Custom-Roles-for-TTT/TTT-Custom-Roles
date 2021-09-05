# Beta Release Notes

## 1.1.11
**Released:**

### Fixes
- Fixed case where the medium ghosts would temporarily show up as floating kleiner models

## 1.1.10
**Released: September 4th, 2021**

### Additions
- Added the option to set the amount of time it takes a vampire to drain a dead body to a different amount of time than if the target is alive (disabled by default)
- Added option to enable shop for all roles (disabled by default)

### Fixes
- Fixed vampires not being able to drain dead players
- Fixed traitors being able to see detective, special detective, and clown icons through walls

## 1.1.9
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
- Updated GetTeamRoles to take an optional lookup table of excluded roles
- Changed TTTScoringWinTitle hook to allow dynamically setting a secondary win role (like the old man)
- Added new hooks to handle cases where a player would want to appear as a different role in-game
  - TTTScoreboardPlayerRole - What role/color the player should show as on the scoreboard
  - TTTScoreboardPlayerName - What name the player should have on the scoreboard (useful for adding things like the assassin's "(TARGET)")
  - TTTTargetIDPlayerKillIcon - Whether the "KILL" icon should be shown over the target's head
  - TTTTargetIDPlayerRoleIcon - What role icon and background color should be shown over the target's head
  - TTTTargetIDPlayerText - What text and color to use for the Target ID (when you look at a player)
- Added SWEP.ShopName to weapon_tttbase to allow for weapons to have different names for when they are in the shop as opposed to when they are an entity in world

## 1.1.8
**Released: August 26th, 2021**

### Additions
- Added ability for glitch to see and use traitor traps (disabled by default)
- Added ability for a phantom to lose their powers if their body is destroyed (disabled by default)
- Added ability to remove all detective roles' ability to loot credits from corpses (disabled by default)
- Added the option for the mediums' spirits to be colored similar to tracker footsteps (enabled by default)

### Changes
- Changed round summary role tooltip to be translateable
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
- Added GetRoleTeamColor global client method for getting the color for a role team
- Added ability to give a player bonus points via a scoring event if the sid64 and bonus properties are set
- Added ability for external roles to explicitly deny credit looting and traitor button usage via the "canlootcredits" and "canusetraitorbuttons" role table properties

## 1.1.7
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

## 1.1.6
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
- Added oldmanwins parameter to TTTScoringWinTitle hook

## 1.1.5
**Released: August 19th, 2021**

### Fixes
- Fixed paladin not counting as an innocent
- Fixed external special detectives not counting as innocent

### Developer
- Added TTTScoringSummaryRender client hook to change how players are displayed in the round summary

## 1.1.4
**Released: August 18th, 2021**

### Additions
- Added special detectives
- Added the paladin