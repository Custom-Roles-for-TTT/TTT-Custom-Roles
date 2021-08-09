# Beta Release Notes

## 1.0.9
**Released: August 9th, 2021**

### Fixes
- Fixed role weapons not being removed when a player is hypnotized
- Fixed multiple monsters spawning in one round

### Changes
- Split beggar reveal convar in two to allow finer control over when the beggar is revealed and who they are revealed to
- Separated doctor modes into 2 separate roles
  - The doctor now has a shop and can buy a health station or the parasite cure (based off doctor mode 0)
  - The paramedic has a defibrillator that cannot be dropped or used by anyone else (based off doctor mode 1)
- The quack now has to buy the bomb station from a shop instead of spawning with it
  - The quack can also buy a real health station and the parasite cure

### Additions
- Added ability for parasite's infection to transfer to a new player if their killer is killed (disabled by default)
  - There is also a new convar to determine whether the infection progress should be reset if the infection is transferred to a new player
- Added ability to respawn the parasite if their infected target kills themselves (disabled by default)
- Added glitch modes to allow glitches to function in rounds where there are 2 or more members of the traitor team but less than 2 regular traitors
- Added convars to prevent the paramedic and hypnotist, or the phantom and parasite from spawning together
- Added a fake parasite cure that does nothing except play the parasite cure sounds which is buyable for the quack

## 1.0.8
**Released: August 7th, 2021**

### Fixes
- Fixed role selection message not always using custom role strings
- Fixed win message for singular roles not being properly pluralized (e.g. "THE JESTER WIN" instead of "THE JESTER WINS")
- Fixed "AND THE OLD MAN WINS" round summary message missing
- Fixed the "Highlights" round summary tab message missing the winning role name
- Fixed revenger being mislabeled as "tevenger" in some messages
- Fixed body call messages not using correct custom role articles
- Fixed promoted deputy/impersonator not being able to pick up Visualizers
- Fixed detectives showing as deputy on the scoreboard if ttt_deputy_use_detective_icon is disabled

### Additions
- Added convar to have the clown's shop purchases be held back until they are activated
- Added convar to drain a revenger's health down to a specified number when their lover has died
- Re-added Radio menu and added ability to choose which button to use via the F1 menu

### Updates
- Updated the role string logic to handle more plural cases
- Updated more places to use customizable role strings
  - Round summary events
  - Round summary score table
  - Round start role popups
  - HUD messages for beggar and deputy/impersonator
  - Role logic messages
  - Equipment descriptions
  - Tips

### Developer
- Added ability for SWEP name, type, and description to use functions for formatting

## 1.0.7
**Released: August 4th, 2021**

### Fixes
- Fixed team player count calculations not always being accurate by truncating the "_pct" convars to 3 digits to work around floating point inaccuracy
- Fixed assassin not getting a target sometimes because they were treated as having a failed contract by default
- Fixed missing ttt_clown_shop_mode
- Fixed weapons added to detective or traitor via the roleweapons system not being buyable by roles using the shop mode convars
- Fixed old man not also winning when a map declares a winning team
- Fixed the glitch from being shown as a traitor to zombies if zombies are on the traitor team

### Changes
- Changed ttt_beggar_notify_sound and ttt_beggar_notify_confetti to be off by default to better match default beggar behaviour
- Changed end-of-round summary to automatically add a row if there are both independents and jesters in a round (via something like a Randomat event)
- Changed parasite cure to have a 3-second charge time to prevent it from being used as an instant-kill weapon
- Changed parasite cure to never be removed if shop randomization is enabled

### Additions
- Added convars to control whether members of the jesters teams are visible to other teams (via the head icons, color/icon on the scoreboard, etc.)
- Added ability to give the veteran a health bonus (in addition to the heal) when they are activated
- Added ability to notify other remaining players when a veteran is activated
- Added convar to control what happens when a parasite cure is used on someone who is not infected
- Added ability for the clown to always have access to their shop via a new convar
- Added convars to rename roles

### Developer
- Added the ability for SWEPs to not be randomized out of the shop by setting "SWEP.BlockShopRandomization = true"
- Renamed ROLE_STRINGS to ROLE_STRINGS_RAW

## 1.0.6
**Released: July 20th, 2021**

### Fixes
- Fixed detective showing deputy icon when ttt_deputy_use_detective_icon is enabled
- Fixed scoreboard icons not obeying ttt_deputy_use_detective_icon and ttt_impersonator_use_detective_icon
- Fixed error trying to assign an assassin target preventing rounds from starting when there was an assassin
- Fixed potential error picking an assassin target when ttt_assassin_shop_roles_last was enabled
- Fixed "next"/"final" label sometimes being incorrect for an assassin getting their next target if ttt_assassin_shop_roles_last was enabled

## 1.0.5
**Released: July 19th, 2021**

### Changes
- Changed revenger to receive a different message if their lover is killed when they are already dead
- Changed deputy/impersonator to not receive a message about their promotion if they are already dead
- Changed traitors to receive a slightly different message if their dead impersonator teammate has been promoted
- Changed the killer/phantom smoke to be viewable from further away
- Changed corpse identified message to also send for non-vanilla traitors to non-vanilla innocents

### Additions
- Added ability for non-traitor roles to be configurably able to use traitor buttons
- Added ability for non-shop roles to be configurably able to see and loot credits
- Added new trickster role
- Added settings to control whether the deputy/impersonator should use their own icons or the Detective icon over their head
- Added setting to have the old man have their health drained to a certain minimum value over time
- Added a message to a parasite victim when they are killed by the parasite coming back to life
- Added a message to a non-prime vampire when they are killed/reverted if the prime was killed
- Ported "TTT: add more validation to corpse commands" from base TTT
- Added new Assassin target priority CVar
- Added new CVar to heal the Clown when they activate

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
- Added plymeta:StripRoleWeapons which removes all weapons with the WEAPON_CATEGORY_ROLE from a player
- Added plymeta:MoveRoleState which moves the role NW values from a player to a target
- Added missing things to resource download list
- Changed TTTCanIdentifyCorpse hook "was_traitor" parameter to be true for any role on the traitor team rather than just the vanilla traitor

## 1.0.4
**Released: July 11th, 2021**

### Changes
- Changed the drunk so they lose karma for hurting/killing people before they sober up

### Additions
- Added new shop random position CVar
- Added new CVar to control how to handle weapons when a swapper is killed

### Fixes
- Fixed ttt_*_shop_mode cvars
- Fixed "Kill" icon showing over jester players' heads when the client knows they are a Jester
- Fixed swapper not getting zombie/vampire prime status when a prime zombie/vampire swaps with them

## 1.0.3 
**Released: July 11th, 2021**

### Changes
- Changed convars to use '_ttt_ROLENAME\_\*_' formatting wherever possible
  - NOTE: Old convars still work at this stage but may be removed later. Please update to the new convars now to avoid problems later

### Additions
- Added starting and max health convars to all roles

## 1.0.2
**Released: July 11th, 2021**

### Changes
- Changed shop to not show "loadout" equipment items that you already own because you can't buy them and might not have known you were given them for free
- Changed killer's knife to not conflict with shop weapons
- Changed phantom smoke to be disabled by default
- Changed head icons to be based on player model size and scale so they have their icon in the right place

### Fixes
- Fixed some client ConVars not saving
- Fixed equipment exclusion system accidentally excluding ALL equipment for a role
- Fixed target ID showing when a player is hidden using the prop disguiser
- Fixed improper team highlighting for zombie/vampire after they switched teams
- Fixed parasite cure being buyable when parasite is not enabled
- Fixed karma percentage on scoreboard not matching damage factor when max karma was greater than 1000
- Fixed potential errors by adding more nil protection in the vampire fangs

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

### Updates
- Updated role sync documentation to hopefully make it clearer how it all works

### Developer
- Added plymeta:CanUseShop method which checks IsShopRole and NWBools
- Added TTTSprintStaminaPost hook which can be used to overwrite player stamina
- Added resource download commands to avoid missing textures