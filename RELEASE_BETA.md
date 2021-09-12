# Beta Release Notes

## 1.2.3
**Released:**

### Additions
- Added ability for the old man to enter an adrenaline rush and hold off death for 5 seconds (enabled by default)
- Added double barrel shotgun which is given to the old man when they enter an adrenaline rush (enabeld by default)

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