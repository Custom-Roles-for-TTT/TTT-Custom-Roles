# Beta Release Notes

## 1.2.5
**Released:**

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

### Changes
- Changed beggar to not be able to use or see traitor chat (text or voice) when the beggar reveal mode is disabled for traitors
- Changed credit-lootable roles without a shop (like the trickster) to have starting credits convars

### Fixes
- Fixed zombies sometimes spawning in non-zombie rounds if they are on the traitor team
- Fixed beggar who converted to traitor and then was resurrected by a hypnotist not showing as a traitor when beggar reveal was disabled for traitors

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
- Fixed returning false for either text value in TTTTargetIDPlayerText hook not actually stopping the original text from being used
- Fixed ttt_debug_preventwin not blocking when TTTCheckForWin returns a value or when the round time ends

## 1.2.4
**Released: September 15th, 2021**

### Additions
- Added ability for the old man to enter an adrenaline rush and hold off death for 5 seconds (enabled by default)
- Added double barrel shotgun which is given to the old man when they enter an adrenaline rush (enabled by default)
