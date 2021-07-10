# Beta Release Notes

## 1.0.2
**Released:**

### Changes
- Changed shop to not show "loadout" equipment items that you already own because you can't buy them and might not have known you were given them for free
- Changed Killer's knife to not conflict with shop weapons
- Changed Phantom smoke to be disabled by default
- Changed head icons to be based on view offset so scaled players have their icon in the right place

### Fixes
- Fixed some client ConVars not saving
- Fixed equipment exclusion system accidentally excluding ALL equipment for a role
- Fixed target ID showing when a player is hidden using the prop disguiser
- Fixed improper team highlighting for Zombie/Vampire after they switched teams
- Fixed parasite cure being buyable when parasite is not enabled
- Fixed karma percentage on scoreboard not matching damage factor when max karma was greater than 1000

### Additions
- Added CanUseShop method which checks IsShopRole and NWBools
- Added resource download commands to avoid missing textures
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
- Added more nil protection in the vampire fangs
- Added TTTSprintStaminaPost hook which can be used to overwrite player stamina

### Updates
- Updated role sync documentation to hopefully make it clearer how it all works