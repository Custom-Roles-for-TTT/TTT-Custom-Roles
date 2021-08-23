# Beta Release Notes

## 1.1.8

### Additions
- Added ability for glitch to see and use traitor traps (disabled by default)

### Changes
- Changed round summary role tooltip to be translateable

### Fixes
- Fixed the detective's DNA scanner not being removed when they should have lost their role weapons
- Fixed external monster roles not naturally spawning

### Developer
- Changed more aspects of role creation to be dynamic
  - Adding icons to the download list
  - Creation of ttt_force_{ROLENAME} commands
  - Role selection logic
  - Role default buyable equipment

## 1.1.7
**Released: August 22nd, 2021**

### Additions
- Added the medium
- Added the ability to give clowns bonus health if they are healed when they are activated
- Added message to the clown if they are healed when they activate
- Added role name to mouseover for icons on the round summary
- Added monster support for external roles

### Changes
- Changes bloody phantom killer footsteps to have priority over tracker footsteps

### Fixes
- Fixed beggar role being revealed on a traitor's scoreboard even if ttt_beggar_reveal_traitor was 0

### Developer
- Added missing tracker sprites to resource download list

## 1.1.6
**Released: August 21st, 2021**

### Additions
- Added the tracker
- Added missing force_paladin command

### Changes
- Changed paladin default damage reduction to 30%

### Fixes
- Fixed special detectives using special innocent colors
- Fixed not being able to use weapons when ttt_weaponswitcher_stay was enabled and ttt_weaponswitcher_fast was disabled
- Fixed error when trying to calculate the height of some models

### Developer
- Added oldmanwins parameter to TTTScoringWinTitle hook

## 1.1.5
**Released: August 19th, 2021**

### Fixes
- Fixed paladin not counting as an innocent
- Fixed external special detectives not counting as innocent

### Developer
- Added TTTScoringSummaryRender client hook to change how players are displayed in the round summary

## 1.1.4
**Released: August 18th, 2021**

### Additions
- Added special detectives
- Added the paladin