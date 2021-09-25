# Beta Release Notes

## 1.2.6
**Released: September 25th, 2021**

### Fixes
- Fixed external roles with long names and custom win conditions having their win title cut off
- Fixed map wins being ignored when an external role with a custom win condition was in use

### Developer
- Fixed generated win and event identifiers resetting if lua is refreshed

## 1.2.5
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
- Added ability for bodysnatcher's role change to be hidden based on which team they joined (disbled by default)
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
- Added ability for external roles to define when they are "active", tying directly into the "plymeta:IsRoleActive" function
- Added "plymeta:ShouldActLikeJester" to determine if a player should act like a jester (damage in, damage out, appearance, etc.)
- Added ability for external roles to define if/when they should act like a jester, tying directly into the "plymeta:ShouldActLikeJester" function
- Added GenerateNewEventID method for generating a unique ID for custom scoring events
- Added GenerateNewWinID method for generating a unique ID for custom win conditions
- Added TTTTargetIDPlayerHealth hook for controlling what text to show when rendering a player's health
- Added TTTTargetIDPlayerKarma hook for controlling what text to show when rendering a player's karma
- Added TTTTargetIDEntityHintLabel hook for controlling what text to show when rendering a player or entity's hint label
- Added TTTTargetIDPlayerHintText hook for controlling what text to show when rendering an entity's hint text
- Added TTTTargetIDPlayerName hook for controlling what text to show when rendering a player's name
- Added TTTTargetIDRagdollName hook for controlling what text to show when rendering a ragdoll's name
- Added "plymeta:ShouldRevealBeggar" to determine if a palyer should be able to tell that a target player is no longer a beggar (e.g. converted to an innocent or traitor)
- Added "plymeta:ShouldRevealBodysnatcher" to determine if a palyer should be able to tell that a target player is no longer a bodysnatcher (e.g. has snatched a role from a dead body)
- Added "was_bodysnatcher" property to TTTRadarPlayerRender hook's "tgt" parameter
- Changed the global "ShouldHideJesters" to be deprecated in favor of "plymeta:ShouldHideJesters"
- Fixed returning false for either text value in TTTTargetIDPlayerText hook not actually stopping the original text from being used
- Fixed ttt_debug_preventwin not blocking when TTTCheckForWin returns a value or when the round time ends
- Fixed "plymeta:SoberDrunk" not calling PlayerLoadout hook when granting the player their new role loadout

## 1.2.4
**Released: September 15th, 2021**

### Additions
- Added ability for the old man to enter an adrenaline rush and hold off death for 5 seconds (enabled by default)
- Added double barrel shotgun which is given to the old man when they enter an adrenaline rush (enabled by default)
