# Beta Release Notes

## 1.3.1
**Released:**

### Additions
- Added the loot goblin
- Added tutorial pages for all roles
- Added ability to allow the deputy to use their shop before activation (disabled by default)
- Added ability to delay a deputy's shop purchases until they are activated (disabled by default)
- Added ability to give a deputy some credits when they activate (disabled by default)
- Added ability for a clown to see and use traitor traps when they activate (disabled by default)
- Added ability to configure the amount of damage the killer's crowbar does (when bashing or throwing)
- Added ability to configure the amount of damage the old man's shotgun does
- Added ability to limit the number of times a beggar can respawn, if that is enabled (disabled by default)
- Added ability to have the bodysnatcher respawn if they are killed before they use their device (disabled by default)
- Added ability to use common jester notifications (message, sound, confetti) when the bodysnatcher is killed (disabled by default)
- Added ability to make the paramedic defib rebuyable if ttt_paramedic_device_shop is enabled (disabled by default)
- Added ability to make the hypnotist brainwashing device rebuyable if ttt_hypnotist_device_shop is enabled (disabled by default)
- Added ability to prevent the drunk and clown from being selected in the same round (disabled by default)
- Added ability to show loadout equipment in shops (disabled by default)
- Added ability to configure the amount of time the various role devices take to be used
  - Bodysnatching Device
  - Hypnotist's Brainwashing Device
  - Mad Scientist's Zombificator
  - Paramedic's Defibrillator
  - Phantom Exorcism Device
  - Doctor's Parasite Cure
  - Quack's Fake Parasite Cure

### Changes
- Changed vampire fang unfreeze logic to hopefully fix rare case where the target would stay frozen if the vampire was killed
- Updated Parasite Cures and Phantom Exorcism device to use renamed role strings
- Removed support for old version of role and shop convars, originally deprecated in v1.0.14

### Fixes
- Fixed teamkilling monster team members not having their karma reduced
- Fixed renaming jester, swapper, or beggar causing errors when trying to show killed notifications
- Fixed clown not winning the round when just them and the old man are left alive
- Fixed error using role colors on the client before the first round preparation phase
- Fixed "beggar converted to innocent" entry in the round summary Events tab using the "traitor" icon
- Fixed vampire eating a body not dropping bones
- Fixed special detectives (paladin, medium, tracker) not counting as detectives in the ttt_logic_role entity
- Fixed error when selecting weapon after respawning a parasite

### Developer
- Added ability to define a role as on that wins passively (like the old man)
- Added parameter to `player.AreTeamsLiving` to ignore players who win passively (like the old man)
- Added `player.TeamLivingCount` and `player.LivingCount` to help tracking how many players are alive
- Added `player.GetTeamPlayers` to get all the players belonging to a player
- Added `player.ExecuteAgainstTeamPlayers` to execute a function against the players belonging to a role team
- Added TTTWinCheckBlocks and TTTWinCheckComplete hooks to allow manipulating and reacting to the win type
- Added TTTHUDInfoPaint hook to add informational messages to a player's HUD (above their health bar)
- Added TTTPlayerAliveClientThink hook to handle the Think event for each currently living player on the client
- Added TTTRadarRender hook to handle custom radar entry rendering
- Added TTTPlayerDefibRoleChange hook to handle a player being resurrected as a different role
- Added TTTSpectatorShowHUD hook to handle showing a player a spectator HUD
- Added TTTSpectatorHUDKeyPress hook to handle the key press event for a player who should be viewing a spectator HUD
- Added `plymeta:Celebrate` to celebrate with sound and or confetti
- Added `plymeta:ShouldShowSpectatorHUD` to determine whether a player should have a spectator HUD displayed
- Added `HUD:PaintPowersHUD` method to render phantom-like spectator HUD in a generic way
- Changed radar's `DrawTarget` method to be accessible in the RADAR namespace as `RADAR:DrawTarget`
- Changed HUD's `PaintBar` and `ShadowedText` methods to be accessible in the HUD namespace as `HUD:PaintBar` and `HUD:ShadowedText` respectively
- Changed `JesterTeamKilledNotification` to be globally accessible
- Renamed `SWEP.BoughtBuy` to `SWEP.BoughtBy`
- Removed deprecated global `ShouldHideJesters`. Use `plymeta:ShouldHideJesters` instead
