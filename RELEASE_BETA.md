# Beta Release Notes

## 1.1.2
**Released:**

### Changes
- Changed the slot number in the weapon switch GUI to still be centered for 2 digit slots

### Fixes
- Fixed jesters being visible via highlighting when ttt_jesters_visible_to_* was disabled
- Fixed error in round summary caused by a player being an in invalid role state
- Fixed weapon switch GUI not updating when you picked up a new weapon and ttt_weaponswitcher_stay was enabled
- Fixed weapon switch GUI closing when you dropped a weapon and ttt_weaponswitcher_stay was enabled
- Fixed weapon switch GUI closing when you tried to drop an undroppable weapon
- Fixed player not appearing on the round summary screen if they were idled to spectator last round and only un-spectated during this round's preparation phase

### Developers
- Changed TTT_RoleChanged to use Int for role number
- Changed TTT_SpawnedPlayers to use Int for role number