# Beta Release Notes

## 1.2.7
**Released:**

### Additions
- Added ttt_roleweapons admin command which opens a configuration interface for the roleweapons shop configuration system
- Added new dynamic tutorial system using HTML and hook-generated pages per role
- Added ability to reward vampires with credits when they drain a living target using their fangs (disabled by default)
- Added ability to set a different amount of health overheal if a vampire drains a living target (disabled by default)
- Added ability to block rewarding vampires when they (or their allies) kill someone (disabled by default)
- Added ability to give the veteran credits when they are activated (disabled by default)

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
- Fixed promoted deputies not being grouped with other detectives in assassin targetting logic
- Fixed independent vampire popup still having "{comrades}" placeholder

### Developer
- Added TTTBlockPlayerFootstepSound hook to block a player's footstep sound
- Added TTTKarmaGiveReward hook to block a player from receiving karma
- Added TTTKarmaShouldGivePenalty hook to determine whether a player should have their karma rewarded or penalized
- Added TTTPlayerSpawnForRound hook to react to when a player is spawned (or respawed)
- Added TTTEventFinishText and TTTEventFinishIconText hooks to add detail to the round finished event row for custom win conditions
- Added TTTPlayerRoleChanged hook to react to when a player's role changes
- Added TTTShouldPlayerSmoke hook to affect whether a player should smoke and how that should look
- Added TTTTutorialRolePage and TTTTutorialRoleText hooks for generating tutorial pages for an external role
- Added TTTRolePopupParams hook to allow roles add parameters to their start-of-round popup message translation
- Added startingRole and finalRole parameters to the TTTScoringSummaryRender hook
- Added plymeta:GetRoleTeam to get the appropriate ROLE_TEAM_* enum value for the player
- Added plymeta:ShouldDelayAnnouncements to determine whether announcements when a player is killed should be delayed for this player
- Added player.GetLivingRole, player.IsRoleLiving, and player.AreTeamsLiving static methods
- Added player.GetRoleTeam static method to get the appropriate ROLE_TEAM_* enum value for a role
- Added ability for external roles to define their role selection predicate function
- Added ability for external roles to run specific logic when a player is initially assigned a role or when they steal a role from someone else
- Added GetRoleTeamInfo and GetRoleTeamName global methods
- Changed OnPlayerHighlightEnabled to be globally available so other roles can use the same highlighting logic
- Changed all EXTERNAL_ROLE_* tables to be named ROLE_* in preparation for role separation
- Fixed returning false for the first parameter of TTTTargetIDPlayerRoleIcon not stopping the role icon from showing

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
