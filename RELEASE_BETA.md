# Beta Release Notes

## 1.3.1
**Released:**

### Additions
- Added tutorial pages for more roles
- Added ability to configure the amount of time the various role devices take to be used
  - Bodysnatching Device
  - Hypnotist's Brainwashing Device
  - Mad Scientist's Zombificator
  - Paramedic's Defibrillator
  - Phantom Exorcism Device
  - Doctor's Parasite Cure
  - Quack's Fake Parasite Cure

### Changes
- Removed support for old version of role and shop convars, originally deprecated in v1.0.14

### Fixes
- Fixed teamkilling monster team members not having their karma reduced
- Fixed renaming jester, swapper, or beggar causing errors when trying to show killed notifications
- Fixed clown not winning the round when just them and the old man are left alive
- Fixed error using role colors on the client before the first round preparation phase

### Developer
- Added ability to define a role as on that wins passively (like the old man)
- Added parameter to player.AreTeamsLiving to ignore players who win passively (like the old man)
- Changed JesterTeamKilledNotification to be globally accessible
- Removed deprecated global ShouldHideJesters. Use plymeta:ShouldHideJesters instead