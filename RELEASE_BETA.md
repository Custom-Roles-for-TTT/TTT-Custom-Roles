# Beta Release Notes

## 1.0.5
**Released:**

### Changes
- Changed revenger to receive a different message if their lover is killed when they are already dead
- Changed deputy/impersonator to not receive a message about their promotion if they are already dead
- Changed traitors to receive a slightly different message if their dead impersonator teammate has been promoted

### Additions
- Added ability for non-traitor roles to be configurably able to use traitor buttons
- Added ability for non-shop roles to be configurably able to see and loot credits
- Added new trickster role
- Added settings to control whether the deputy/impersonator should use their own icons or the Detective icon over their head
- Added setting to have the old man have their health drained to a certain minimum value over time
- Added a message to a parasite victim when they are killed by the parasite coming back to life
- Added a message to a non-prime vampire when they are killed/reverted if the prime was killed

### Fixes
- Fixed vampire victims getting stuck frozen if the vampire is killed while draining their blood
- Fixed error caused by trying to set a player with no role's starting health
- Fixed monster team count check when zombie was on the independent team
- Fixed revenger losing karma when they killed their soulmate's killer if they were innocent
- Fixed parasite cure showing in Deputy/Impersonator shop but not being buyable
- Fixed beggar who converted to a traitor still showing the traitor icon over their head even when ttt_beggar_reveal_change was disabled
- Fixed swapper/bodysnatcher not being promoted when swapping roles with a promoted deputy/impersonator
- Fixed swapper/bodysnatcher not inheriting the revenger's lover when swapping roles with a revenger
- Fixed bodysnatcher not getting zombie/vampire prime status when a prime zombie/vampire swaps with them
- Fixed bodysnatcher not being promoted when they snatch the deputy/impersonator role and no detectives are left alive

### Developer
- Added plymeta:StripRoleWeapons which removes all weapons with the WEAPON_CATEGORY_ROLE from a player
- Added plymeta:MoveRoleState which moves the role NW values from a player to a target
- Added missing things to resource download list

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