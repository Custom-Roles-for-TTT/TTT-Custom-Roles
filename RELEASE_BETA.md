# Beta Release Notes

## 1.2.3
**Released:**

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
- Added ShouldHideJesters global function to determine whether the given player should hide a jester player's role
- Added ability for external roles to define:
  - Starting credits
  - Starting health
  - Maximum health
  - Extra translations
- Added TTTTargetIDPlayerRing hook which allows overriding whether the Target ID ring is shown and what color it should be shown as
- Added nameLabel parameter to TTTScoringSummaryRender hook, allowing you to override what is displayed for a player's name
- Added TTTRadarPlayerRender hook which allows overriding whether a radar ping is shown and what color it should be shown as
- Added TTTSelectRoles*Options for each team to allow external roles to affect the available roles and their weights

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
- Adjusted medium ghost logic to hopefully fix another "floating kliener" case

### Developer
- Added plymeta:GiveDelayedShopItems to give a player their delayed shop items
- Added plymeta:IsRoleActive to determine if a player's role feature is active
- Added plymeta:ShouldDelayShopPurchase to determine if a player's shop purchases should be delayed
- Added DELAYED_SHOP_ROLES lookup table for roles whose shop purchases can be delayed