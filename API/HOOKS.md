# Hooks
Custom and modified event hooks available within the defined realm. A list of default TTT hooks is available [here](https://www.troubleinterroristtown.com/development/hooks/) but note that they may have been modified (see below).

***NOTE:*** When using a hook with multiple return values, you *must* return a non-`nil` value for all properties up to the one(s) you are modifying or the hook results will be ignored entirely.

For example, if there is a hook that returns three parameters: `first`, `second`, and `third` and you want to modify the `second` parameter you must return the `first` parameter as non-`nil` as well, like this: `return first, newSecond`. Any return parameters after `second` can be omitted and the default value will be used.

***NOTE:*** Be careful that you only return from a hook when you absolutely want to change something. Due to the way GMod hooks work, whichever hook instance returns first causes the *remaining hook instances to be completely skipped*. This is useful for certain hooks when you want to stop a behavior from happening, but it can also accidentally cause functionality to break because its code is completely ignored.

### TTTBodyCreditsLooted(ply, deadPly, rag, credits)
Called when a player loots credits off of a dead player's body.\
*Realm:* Server\
*Added in:* 2.1.3\
*Parameters:*
- *ply* - The player who is looting credits
- *deadPly* - The dead player whose corpse was looted
- *rag* - The corpse that was looted
- *credits* - The number of credits looted

### TTTBodySearchButtons(ply, rag, buttons, searchRaw, detectiveSearchOnly)
Called when a player opens the body search dialog. Used to add new buttons to the dialog.\
*Realm:* Client\
*Added in:* 1.8.3\
*Parameters:*
- *ply* - The player who is opening the body search dialog
- *rag* - The `prop_ragdoll` representing a player's body being searched
- *buttons* - The table of buttons being rendered on the body search dialog. Insert a new descriptive object into this table to add a button to the window. The possible descriptive object properties are:
  - *text* - The text to show on the button
  - *onclick* - The function to call when the button is clicked. The only parameter passed to this function is the [DButton](https://wiki.facepunch.com/gmod/DButton) instance.
  - *disabled* - A boolean or function which returns a boolean used to determine whether this button should be clickable. Defaults to `true` if not provided.
- *searchRaw* - The raw search data
- *detectiveSearchOnly* - Whether only detectives should be able to search bodies

### TTTBlockPlayerFootstepSound(ply)
Called when a player is making a footstep. Used to determine if the player's footstep sound should be stopped.\
*Realm:* Client and Server\
*Added in:* 1.2.7\
*Parameters:*
- *ply* - The player who is making footsteps

*Return:* Whether or not the given player's footstep sounds should be stopped (Defaults to `false`).

### TTTC4Disarm(bomb, result, ply)
Modified to allow changing the defusal result via the new return value.\
*Realm:* Server\
*Added in:* 1.5.14\
*Parameters:*
- *bomb* - The bomb entity being defused
- *result* - Whether the defusal was successful
- *ply* - The player defusing the bomb

*Return:*
- *result* - The new result value to use or the original passed into the hook

### TTTCanIdentifyCorpse(ply, rag, wasTraitor)
Changed `was_traitor` parameter to be `true` for any member of the traitor team, rather than just the traitor role.\
*Realm:* Server\
*Added in:* 1.0.5\
*Parameters:*
- *ply* - The player who is attempting to identify a corpse
- *rag* - The ragdoll being identified
- *wasTraitor* - Whether the player who the targeted ragdoll represents belonged to the traitor team

*Return:* Whether or not the given player should be able to identify the given corpse (Defaults to `false`).

### TTTCanUseTraitorVoice(ply)
Called when a player is attempting to use traitor chat, both speaking and listening. Used to change the default behavior.\
*Realm:* Client and Server\
*Added in:* 2.0.7\
*Parameters:*
- *ply* - The player who is trying to use traitor voice. This is called for both speaking and listening

*Return:* Whether to allow this player to use traitor voice chat. (Defaults to checking whether the player is on the traitor team)

### TTTCupidShouldLoverSurvive(ply, lover)
Called before a player is killed because their lover (as set by Cupid's arrows) has been killed. Allows developers to prevent the player from being killed.\
*Realm:* Server\
*Added in:* 1.8.2\
*Parameters:*
- *ply* - The player who may be killed
- *lover* - The player's lover who is already dead

*Return:* If `ply` should not be killed, return `true`. Otherwise do not return anything.

### TTTDeathNotifyOverride(victim, inflictor, attacker, reason, killerName, role)
Called before the name and role of a player's killer is shown to the victim. Used to change the death message reason, killer name, and/or killer role.\
*Realm:* Server\
*Added in:* 1.5.14\
*Parameters:*
- *victim* - The player who was killed
- *inflictor* - The thing that was used to kill them
- *attacker* - The player that killed the victim
- *reason* - The kind of death the player experienced (e.g. `water`, `suicide`, `prop`, `burned`, `fell`, or `ply`)
- *killerName* - The name of the player that killed the victim (used when `reason` is `ply`)
- *role* - The role of the player that killed the victim (used when `reason` is `ply`)

*Return:*
- *reason* - The new reason value to use or the original passed into the hook
- *killerName* - The new killerName value to use or the original passed into the hook
- *role* - The new role value to use or the original passed into the hook. Use `ROLE_NONE` to hide the attacker's role from the victim

### TTTDetectiveLikePromoted(ply)
Called when a detective-like (deputy, impersonator, etc.) player is promoted.\
*Realm:* Server\
*Added in:* 2.0.1\
*Parameters:*
- *ply* - The detective-like player who was promoted

### TTTDrawHitMarker(ent, dmginfo)
Called when an entity is attacked by a player, before hitmarkers are drawn.\
*Realm:* Server\
*Added in:* 2.1.4\
*Parameters:*
- *ent* - The entity being attacked
- *dmginfo* - The damage to be applied to the attacked entity

*Return:*
- *shouldDraw* - If the hitmarker should be drawn
- *drawCrit* - If the hitmarker should be drawn as a crit
- *drawImmune* - If the hitmarker should be drawn as an immune hit (Takes priority over crits and jester hits)
- *drawJester* - If the hitmarker should be drawn as a jester hit (Takes priority over jester hits)

### TTTEventFinishText(e)
Called before the event text for the "round finished" event is rendered in the end-of-round summary's Events tab.\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *e* - Event parameters. Contains the following properties:
  - `id` - The event identifier (always `EVENT_FINISH`)
  - `t` - The time when this event occurred
  - `win` - The win condition identifier

*Return:* Text to show in events list at the end of the round

### TTTEventFinishIconText(e, winString, roleString)
Called before the event icon for the "round finished" event is rendered in the end-of-round summary's Events tab. Used to change the mouseover text for the icon.\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *e* - Event parameters. Contains the following properties:
  - `id` - The event identifier (always `EVENT_FINISH`)
  - `t` - The time when this event occurred
  - `win` - The win condition identifier
- *winString* - The translation string that will be used to display the icon mouseover text
- *roleString* - The role string to use in place of the `role` placeholder in the translation string

*Return:*
- *winString* - The new winString value to use or the original passed into the hook
- *roleString* - The new roleString value to use or the original passed into the hook

### TTTEquipmentTabs(dsheet, dframe)
Allows creation of new tabs for the equipment (shop) menu.\
*Realm:* Client\
*Added in:* 1.0.0\
*Parameters:*
- *dsheet* - The [DPropertySheet](https://wiki.facepunch.com/gmod/DPropertySheet) used by the equipment window
- *dframe* - The [DFrame](https://wiki.facepunch.com/gmod/DFrame) representing the equipment window *(Added in 1.8.7)*

*Return:* If `true`, the equipment window will show even if the player doesn't have any of the default tabs. *(Added in 1.7.3)*

### TTTHUDInfoPaint(client, labelX, labelY, activeLabels)
Called after player information such as role, health, and ammo and equipment information such as radar cooldown and disguiser activation are drawn on the screen. Used to write additional persistent text on the screen for player reference.\
*Realm:* Client\
*Added in:* 1.3.1\
*Parameters:*
- *client* - The local player
- *labelX* - The X value representing the correct indentation from the left side of the screen to add information
- *labelY* - The Y value representing the first clear space to add information
- *activeLabels* - The list of current active additional labels. Used to determine the labelY offset to use via: `labelY = labelY + (20 * #activeLabels)`. Be sure to insert an entry when you add your own label so other addons can space appropriately. *(Added in 1.6.11)*

### TTTInformantDefaultScanStage(ply, oldRole, newRole)
Called when an informant is trying to determine the default scan stage of a plyer. Used to override that value.\
*Realm:* Server\
*Added in:* 1.9.6\
*Parameters:*
- *ply* - The player whose default stage stage is being determined
- *oldRole* - The target player's old role. Only used when this hook is called due to a player's role changing
- *newRole* - The target player's new role. Only used when this hook is called due to a player's role changing

*Return:* The default scan stage to use for this player. If you have no opinion (e.g. let other logic determine this) then don't return anything at all.

### TTTInformantScanStageChanged(ply, tgt, stage)
Called when an informant has scanned additional information from a target player.\
*Realm:* Server\
*Added in:* 1.6.16\
*Parameters:*
- *ply* - The informant performing the scan
- *tgt* - The player being scanned
- *stage* - The new scan stage

### TTTKarmaGiveReward(ply, reward, victim)
Called before a player is rewarded with karma. Used to block a player's karma reward.\
*Realm:* Server\
*Added in:* 1.2.7\
*Parameters:*
- *ply* - The player who will be rewarded karma
- *reward* - The amount of karma the player will be rewarded with
- *victim* - The victim of the event that is rewarding the player with karma. If this is not a player, karma is being rewarded as part of the end of the round

*Return:* Whether or not the given player should be prevented from being rewarded with karma (Defaults to `false`).

### TTTKarmaShouldGivePenalty(attacker, victim)
Called before a player's karma effect is decided. Used to determine if a player should be penalized or rewarded.\
*Realm:* Server\
*Added in:* 1.2.7\
*Parameters:*
- *attacker* - The player who hurt or killed the victim
- *victim* - The player who was hurt or killed

*Return:* `true` if the attacker should be penalized or `false` if they should not. If you have no opinion (e.g. let other logic determine this) then don't return anything at all.

### TTTMadScientistZombifyBegin(ply, tgt)
Called when a mad scientist begins zombifying a target.\
*Realm:* Server\
*Added in:* 1.6.16\
*Parameters:*
- *ply* - The mad scientist doing the zombifying
- *tgt* - The target being zombified

### TTTPaladinAuraHealed(ply, tgt, healed)
Called when a paladin heals a target.\
*Realm:* Server\
*Added in:* 1.6.16\
*Parameters:*
- *ply* - The paladin doing the healing
- *tgt* - The target being healed
- *healed* - The amount healed

### TTTParasiteRespawn(parasite, attacker)
Called when a parasite respawns.\
*Realm:* Server\
*Added in:* 1.8.2\
*Parameters:*
- *parasite* - The parasite that is respawning
- *attacker* - The player that originally killed the parasite (aka the "host")

### TTTPlayerAliveClientThink(client, ply)
Called for each player who is alive during the `Think` hook.\
*Realm:* Client\
*Added in:* 1.3.1\
*Parameters:*
- *client* - The local player
- *ply* - The current alive player target

### TTTPlayerAliveThink(ply)
Called for each player who is alive during the `Tick` hook.\
*Realm:* Server\
*Added in:* 1.2.7\
*Parameters:*
- *ply* - The current alive player target

### TTTPlayerCreditsChanged(ply, amount)
Called whenever a player's credits are added to or subtracted from.\
*Realm:* Server\
*Added in:* 1.9.7\
*Parameters:*
- *ply* - The player whose credits changed
- *amount* - The amount the player's credits changed by

### TTTPlayerHealthChanged(ply, oldHealth, newHealth)
Called when a player's health changes.\
*Realm:* Client and Server\
*Added in:* 1.9.5\
*Parameters:*
- *ply* - The player whose health changed
- *oldHealth* - The player's old health
- *newHealth* - The player's new health

### TTTPlayerRoleChanged(ply, oldRole, newRole)
Called after a player's role has changed.\
*Realm:* Client and Server\
*Added in:* 1.2.7\
*Parameters:*
- *ply* - The player whose role is being changed
- *oldRole* - The role the player had before this change
- *newRole* - The role the player is changing to

### TTTPlayerRoleChangedByItem(ply, tgt, item)
Called after a player's role has been changed by a weapon or item.\
*Realm:* Server\
*Added in:* 1.6.16\
*Parameters:*
- *ply* - The player using the role changing device
- *tgt* - The target player having their role changed
- *item* - The weapon or item used to change the target's role

### TTTPlayerSpawnForRound(ply, deadOnly)
Called before a player is spawned for a round. Also used when reviving a player (via a defib, zombie conversion, etc.).\
*Realm:* Server\
*Added in:* 1.2.7\
*Parameters:*
- *ply* - The player who is being spawned or respawned
- *deadOnly* - Whether this call is specifically targeted at dead players

### TTTPlayerUsedHealthStation(ply, station, healed, should_reduce)
Called after a player uses a health station. Added `should_reduce` parameter which is not present in vanilla TTT.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *ply* - The player who is using the health station
- *station* - The health station being used
- *healed* - The amount the player's health changed
- *should_reduce* - Whether the player's max health was reduced instead of their health being increased *(Added in 1.5.7)*

### TTTPrintResultMessage(type)
Called before the round win results message is printed to the top-right corner of the screen. Can be used to print a replacement message for custom win types that this would not normally handle.\
*Realm:* Server\
*Added in:* 1.0.14\
*Parameters:*
- *type* - The round win type

*Return:* `true` if the default print messages should be skipped (Defaults to `false`).

#### TTTQuartermasterCrateOpened(ply, tgt, item_id)
Called when a player opens a crate from a quartermaster.\
*Realm:* Server\
*Added in:* 1.9.6\
*Parameters:*
- *ply* - The quartermaster who provided the crate
- *tgt* - The player who opened the crate
- *item_id* - The ID of the item/equipment in the crate

### TTTRadarPlayerRender(client, tgt, color, hidden)
Called before a target's radar ping is rendered, allowing the color and whether the ping should be shown to be changed.\
*Realm:* Client\
*Added in:* 1.2.3\
*Parameters:*
- *client* - The local player
- *tgt* - The target player's radar data. Can contain the following properties:
  - `pos` - The target's position
  - `role` - The target's role, if any
  - `was_beggar` - If the target was a beggar but was converted to another role
  - `was_bodysnatcher` - If the target was a bodysnatcher but was converted to another role
  - `killer_clown_active` - whether the target is a Clown that has been activated
  - `sid64` - The [SteamID64](https://wiki.facepunch.com/gmod/Player:SteamID64) value of the target
  - The following properties can be added (only one or the other) to `tgt` to change what is displayed with the radar ping
    - `nick` - A string value that will be shown under the radar ping circle
    - `t` - A time number value that will be calculated as the difference from "now" and shown in the "##:##" format
- *color* - The color that would normally be used for the radar ping for the target, if any
- *hidden* - Whether the radar ping for the target would normally be hidden

*Return:*
- *color* - The new color value to use or the original passed into the hook
- *hidden* - The new hidden value to use or the original passed into the hook

### TTTRadarRender(client)
Called after non-player radar points are rendered and before players are rendered. Used for rendering custom non-player radar points.\
*Realm:* Client\
*Added in:* 1.3.1\
*Parameters:*
- *client* - The local player

### TTTRewardDetectiveTraitorDeathAmount(victim, attacker, amount)
Called before all detectives are awarded credits for a traitor being killed.\
*Realm:* Server\
*Added in:* 1.4.8\
*Parameters:*
- *victim* - The player who was killed
- *attacker* - The player who killed the victim
- *amount* - The number of credits that all detectives will be awarded

*Return:*
- *new_amount* - The new number of credits that all detectives will be awarded

### TTTRewardDetectiveTraitorDeath(ply, victim, attacker, amount)
Called before a player awarded credits for a traitor being killed.\
*Realm:* Server\
*Added in:* 1.4.8\
*Parameters:*
- *ply* - The player who is being given credits
- *victim* - The player who was killed
- *attacker* - The player who killed the victim
- *amount* - The number of credits being awarded

*Return:* `true` to prevent the given player from being awarded credits

### TTTRewardPlayerKilledAmount(victim, attacker, amount)
Called before a player is awarded credits for killing an opponent.\
*Realm:* Server\
*Added in:* 1.4.8\
*Parameters:*
- *victim* - The player who was killed
- *attacker* - The player who killed the victim
- *amount* - The number of credits that the attacker will be awarded

*Return:*
- *new_amount* - The new number of credits that the attacker will be awarded

### TTTRewardTraitorInnocentDeathAmount(victim, attacker, amount)
Called before all traitors are awarded credits for a non-traitor being killed.\
*Realm:* Server\
*Added in:* 1.4.8\
*Parameters:*
- *victim* - The player who was killed
- *attacker* - The player who killed the victim
- *amount* - The number of credits that all traitors will be awarded

*Return:*
- *new_amount* - The new number of credits that all traitors will be awarded

### TTTRewardTraitorInnocentDeath(ply, victim, attacker, amount)
Called before a player awarded credits for a non-traitor being killed.\
*Realm:* Server\
*Added in:* 1.4.8\
*Parameters:*
- *ply* - The player who is being given credits
- *victim* - The player who was killed
- *attacker* - The player who killed the victim
- *amount* - The number of credits being awarded

*Return:* `true` to prevent the given player from being awarded credits

### TTTRolePopupParams(client)
Called before a player's role start-of-round popup message is displayed, allowing the parameters to be added to.\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *client* - The local player

*Return:*
- *params* - Table of name-value parameters to be used in this player's role start-of-round popup message

### TTTRolePopupRoleStringOverride(client, roleString)
Called before a player's role start-of-round popup message is displayed, allowing the target translation string to be changed.\
*Realm:* Client\
*Added in:* 1.5.11\
*Parameters:*
- *client* - The local player
- *roleString* - The string representing role of the local player. Is normally used to build the role info popup translation

*Return:*
- *roleString* - The new string to use when building the role info popup translation

### TTTRolesLoaded()
Called after all roles and role modifications have been loaded.\
*Realm:* Client\
*Added in:* 1.5.3

### TTTRoleSpawnsArtificially(role)
Called when checking if a role can be spawned artificially. (i.e. Spawned in a way other than naturally spawning when the role is enabled.)\
*Realm:* Client and Server\
*Added in:* 1.9.5\
*Parameters:*
- *roleID* - The ID of the role being checked

*Return:* `true` when the role could be spawned artificially. Don't return anything otherwise

### TTTRoleRegistered(roleID)
Called after an external role has been registered.\
*Realm:* Client\
*Added in:* 1.5.3\
*Parameters:*
- *roleID* - The unique identifier for the registered role

### TTTRoleWeaponsLoaded()
Called after the role weapons configuration is loaded.\
*Realm:* Client and Server\
*Added in:* 1.6.17

### TTTRoleWeaponUpdated(role, weapon, include, exclude, noRandom)
Called after a role weapon configuration is changed for a specific role and weapon.\
*Realm:* Client and Server\
*Added in:* 1.6.17\
*Parameters:*
- *role* - The role being updated
- *weapon* - The weapon class or equipment name being updated
- *include* - Whether this weapon is being added to `WEPS.BuyableWeapons`
- *exclude* - Whether this weapon is being added to `WEPS.ExcludeWeapons`
- *noRandom* - Whether this weapon is being added to `WEPS.BypassRandomWeapons`

### TTTScoreboardPlayerName(ply, client, currentName)
Called before a player's row in the scoreboard (tab menu) is shown, allowing the name to be changed.\
*Realm:* Client\
*Added in:* 1.1.9\
*Parameters:*
- *ply* - The player being rendered
- *client* - The local player
- *currentName* - The current name string (including extra information)

*Return:*
- *name* - The new name value to show on the scoreboard

### TTTScoreboardPlayerRole(ply, client, color, roleFileName)
Called before a player's row in the scoreboard (tab menu) is shown, allowing the colors and icon to be changed.\
*Realm:* Client\
*Added in:* 1.1.9\
*Parameters:*
- *ply* - The player being rendered
- *client* - The local player
- *color* - The background [Color](https://wiki.facepunch.com/gmod/Color) to use
- *roleFileName* - The portion of the scoring icon path that indicates which role it belongs to. Used in one of the following icon path patterns: "vgui/ttt/tab_{roleFileName}.png" (1.1.9+), "vgui/ttt/roles/{roleFileName}/tab_{roleFileName}.png"  (1.3.4+)

*Return:*
- *color* - The new color value to use or the original passed into the hook
- *roleFileName* - The new roleFileName value to use or the original passed into the hook
- *flashRole* - If a valid role is provided, this will cause the target player's scoreboard role to have a flashing border in the given role's color (see ROLE_* global enumeration)

### TTTScoringSecondaryWins(wintype, secondaryWins)
Called before each round summary screen is shown with the winning team. Used to add roles to the secondary win display (e.g. AND THE OLD MAN WINS).\
*Realm:* Client\
*Added in:* 1.4.1\
*Parameters:*
- *wintype* - The round win type
- *secondaryWins* - The table of role information for who should have a secondary win on the round summary. Insert any role data you would like to display into this table. Role data can either be the role's identifier (to use the default text and color logic) or, *as of version 1.4.6*, a table of the following data (to use your own text and colors):
  - txt - The text to display
  - col - The background color to use

### TTTScoringSummaryRender(ply, roleFileName, groupingRole, roleColor, nameLabel, startingRole, finalRole)
Called before the round summary screen is shown. Used to modify the color, position, and icon for a player.\
*Realm:* Client\
*Added in:* 1.1.5\
*Parameters:*
- *ply* - The player being rendered
- *roleFileName* - The portion of the scoring icon path that indicates which role it belongs to. Used in one of the following icon path patterns: "vgui/ttt/score_{roleFileName}.png" (1.1.5+), "vgui/ttt/roles/{roleFileName}/score_{roleFileName}.png" (1.3.4+)
- *groupingRole* - The role to use when determining the section to of the summary screen to put this player in
- *roleColor* - The background [Color](https://wiki.facepunch.com/gmod/Color) to use behind the role icon
- *nameLabel* - The name that is going to be used for this player on the round summary *(Added in 1.2.3)*
- *startingRole* - The role that this player started the round with *(Added in 1.2.7)*
- *finalRole* - The role that this player ended the round with *(Added in 1.2.7)*

*Return:*
- *roleFileName* - The new roleFileName value to use or the original passed into the hook
- *groupingRole* - The new groupingRole value to use or the original passed into the hook
- *roleColor* - The new roleColor value to use or the original passed into the hook
- *newName* - The new nameLabel value to use for the original passed into the hook *(Added in 1.2.3)*
- *otherName* - Another name to pair with the label parameter (below) when rendering this player's information. Parameters will be used like "newName (label otherName)" *(Added in 1.6.17)*
- *label* - The label to use when pairing the name and otherName together (see above) *(Added in 1.6.17)*

### TTTScoringWinTitle(wintype, wintitles, title)
Called multiple times before the round end screen is shown with the winning team. For each tab of the round end screen that shows the winning team, this hook is first called with `WIN_INNOCENT` to get the default value and then called with the actual winning team. Return a new win title object to override what would normally be shown on the round end screen. This should be used by roles to customize what is shown on the round summary screen.\
*Realm:* Client\
*Added in:* 1.0.14\
*Parameters:*
- *wintype* - The round win type
- *wintitles* - Table of default win title parameters
- *title* - The currently selected win title

*Return:*
- *newTitle*
  - *txt* - The translation string to use to get the winning team text
  - *c* - The background [Color](https://wiki.facepunch.com/gmod/Color) to use
  - *params* - Any parameters to use when translating `txt`

### TTTScoringWinTitleOverride(wintype, wintitles, title)
Called multiple times before the round end screen is shown with the winning team. For each tab of the round end screen that shows the winning team this is called with the winning team. Return a new win title object to override what would normally be shown on the round end screen. This should be used by external addons to change the look of the round summary screen, *not* by roles to set their custom win titles. For a role's custom win title, use `TTTScoringWinTitle` instead.\
*Realm:* Client\
*Added in:* 1.7.3\
*Parameters:*
- *wintype* - The round win type
- *wintitles* - Table of default win title parameters
- *title* - The currently selected win title

*Return:*
- *newTitle*
  - *txt* - The translation string to use to get the winning team text
  - *c* - The background [Color](https://wiki.facepunch.com/gmod/Color) to use
  - *params* - Any parameters to use when translating `txt`

### TTTSelectRoles(choices, prevRoles)
Called before players are randomly assigned roles. If a player is assigned a role during this hook, they will not be randomly assigned one later.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *choices* - The table of players who will be assigned roles
- *prevRoles* - The table whose keys are role numbers and values are tables of players who had that role last round

### TTTSelectRolesDetectiveOptions(roleTable, choices, choiceCount, traitors, traitorCount)
Called before players are assigned a detective role, allowing the available roles and their weights (how many times they appear in the table) to be manipulated.\
*Realm:* Server\
*Added in:* 1.2.3\
*Parameters:*
- *roleTable* - The table of roles representing the available detective roles and their weight (how many times they appear in the table). This table should be manipulated to effect change
- *choices* - The table of available player choices that will not be (and have not already been) assigned a traitor or detective role. Manipulating this table will have no effect
- *choiceCount* - The total number of player choices there are
- *traitors* - The table of available player choices that will be (or have already been) assigned a traitor role. Manipulating this table will have no effect
- *traitorCount* - The number of players that will be (or have already been) assigned a traitor role
- *detectives* - The table of available player choices that will be (or have already been) assigned a detective role. Manipulating this table will have no effect
- *detectiveCount* - The number of players that will be (or have already been) assigned a detective role

### TTTSelectRolesIndependentOptions(roleTable, choices, choiceCount, traitors, traitorCount)
Called before players are assigned a independent role, allowing the available roles and their weights (how many times they appear in the table) to be manipulated.\
*Realm:* Server\
*Added in:* 1.2.3\
*Parameters:*
- *roleTable* - The table of roles representing the available independent roles (and jester roles, if ttt_single_jester_independent or ttt_multiple_jesters_independents is enabled) and their weight (how many times they appear in the table). This table should be manipulated to effect change
- *choices* - The table of available player choices that will not be (and have not already been) assigned a traitor or detective role. Manipulating this table will have no effect
- *choiceCount* - The total number of player choices there are
- *traitors* - The table of available player choices that will be (or have already been) assigned a traitor role. Manipulating this table will have no effect
- *traitorCount* - The number of players that will be (or have already been) assigned a traitor role
- *detectives* - The table of available player choices that will be (or have already been) assigned a detective role. Manipulating this table will have no effect
- *detectiveCount* - The number of players that will be (or have already been) assigned a detective role

### TTTSelectRolesInnocentOptions(roleTable, choices, choiceCount, traitors, traitorCount)
Called before players are assigned an innocent role, allowing the available roles and their weights (how many times they appear in the table) to be manipulated.\
*Realm:* Server\
*Added in:* 1.2.3\
*Parameters:*
- *roleTable* - The table of roles representing the available innocent roles and their weight (how many times they appear in the table). This table should be manipulated to effect change
- *choices* - The table of available player choices that will not be (and have not already been) assigned a traitor or detective role. Manipulating this table will have no effect
- *choiceCount* - The total number of player choices there are
- *traitors* - The table of available player choices that will be (or have already been) assigned a traitor role. Manipulating this table will have no effect
- *traitorCount* - The number of players that will be (or have already been) assigned a traitor role
- *detectives* - The table of available player choices that will be (or have already been) assigned a detective role. Manipulating this table will have no effect
- *detectiveCount* - The number of players that will be (or have already been) assigned a detective role

### TTTSelectRolesJesterOptions(roleTable, choices, choiceCount, traitors, traitorCount)
Called before players are assigned a jester role, allowing the available roles and their weights (how many times they appear in the table) to be manipulated.\
*Realm:* Server\
*Added in:* 1.2.3\
*Parameters:*
- *roleTable* - The table of roles representing the available jester roles (and independent roles, if ttt_single_jester_independent or ttt_multiple_jesters_independents is enabled) and their weight (how many times they appear in the table). This table should be manipulated to effect change
- *choices* - The table of available player choices that will not be (and have not already been) assigned a traitor or detective role. Manipulating this table will have no effect
- *choiceCount* - The total number of player choices there are
- *traitors* - The table of available player choices that will be (or have already been) assigned a traitor role. Manipulating this table will have no effect
- *traitorCount* - The number of players that will be (or have already been) assigned a traitor role
- *detectives* - The table of available player choices that will be (or have already been) assigned a detective role. Manipulating this table will have no effect
- *detectiveCount* - The number of players that will be (or have already been) assigned a detective role

### TTTSelectRolesMonsterOptions(roleTable, choices, choiceCount, traitors, traitorCount)
Called before players are assigned a monster role, allowing the available roles and their weights (how many times they appear in the table) to be manipulated.\
*Realm:* Server\
*Added in:* 1.2.3\
*Parameters:*
- *roleTable* - The table of roles representing the available monster roles and their weight (how many times they appear in the table). This table should be manipulated to effect change
- *choices* - The table of available player choices that will not be (and have not already been) assigned a traitor or detective role. Manipulating this table will have no effect
- *choiceCount* - The total number of player choices there are
- *traitors* - The table of available player choices that will be (or have already been) assigned a traitor role. Manipulating this table will have no effect
- *traitorCount* - The number of players that will be (or have already been) assigned a traitor role
- *detectives* - The table of available player choices that will be (or have already been) assigned a detective role. Manipulating this table will have no effect
- *detectiveCount* - The number of players that will be (or have already been) assigned a detective role

### TTTSelectRolesTraitorOptions(roleTable, choices, choiceCount, traitors, traitorCount)
Called before players are assigned a traitor role, allowing the available roles and their weights (how many times they appear in the table) to be manipulated.\
*Realm:* Server\
*Added in:* 1.2.3\
*Parameters:*
- *roleTable* - The table of roles representing the available traitor roles and their weight (how many times they appear in the table). This table should be manipulated to effect change
- *choices* - The table of available player choices that will not be (and have not already been) assigned a traitor or detective role. Manipulating this table will have no effect
- *choiceCount* - The total number of player choices there are
- *traitors* - The table of available player choices that will be (or have already been) assigned a traitor role. Manipulating this table will have no effect
- *traitorCount* - The number of players that will be (or have already been) assigned a traitor role
- *detectives* - The table of available player choices that will be (or have already been) assigned a detective role. Manipulating this table will have no effect
- *detectiveCount* - The number of players that will be (or have already been) assigned a detective role

### TTTSettingsConfigTabFields(sectionName, parentForm)
Called after each section of the help menu's Config tab has been created, allowing developers to add controls to that section.\
*Realm:* Client\
*Added in:* 1.7.3\
*Parameters:*
- *sectionName* - The name of the section of the help menu's Settings tab that is being created. Expected values: Interface, Gameplay, Color, Language, BEM, Hitmarkers
- *parentForm* - The parent [DForm](https://wiki.facepunch.com/gmod/DForm) for the section being processed

### TTTSettingsConfigTabSections(parentPanel)
Called after the Config tab of the help menu has been created, allowing developers to add sections to it.\
*Realm:* Client\
*Added in:* 1.7.3\
*Parameters:*
- *parentPanel* - The parent [DScrollPanel](https://wiki.facepunch.com/gmod/DScrollPanel) for the tab

### TTTSettingsRolesTabSections(role, parentForm)
Called for each role, allowing developers to add a configuration section for it.\
*Realm:* Client\
*Added in:* 1.7.3\
*Parameters:*
- *role* - The ID of the role whose setting section is being added
- *parentForm* - The parent [DForm](https://wiki.facepunch.com/gmod/DForm) for the role being processed

*Return:*
- *add_section* - Return `true` to add this role config section to the dialog. If you have no opinion (e.g. let other logic determine this) then don't return anything at all.

### TTTShopRandomBought(client, item)
Called when a player buys a random item from the shop.\
*Realm:* Client\
*Added in:* 1.6.16\
*Parameters:*
- *client* - The player who is buying a random item
- *item* - The random item that was selected

### TTTSmokeGrenadeExtinguish(ent_class, ent_pos)
Called when a smoke grenade extinguishes a fire entity.\
*Realm:* Server\
*Added in:* 1.6.16\
*Parameters:*
- *ent_class* - The class of fire entity that was extinguished
- *ent_pos* - The position of the fire entity that was extinguished

### TTTSpectatorHUDKeyPress(ply, tgt, powers)
Called when a player who is being shown a role-specific spectator HUD presses a button, allowing the hook to intercept that button press and perform specific logic if necessary.\
*Realm:* Server\
*Added in:* 1.3.1\
*Parameters:*
- *ply* - The spectator player who is attempting to press a key
- *tgt* - The target playing being spectated
- *powers* - The table of key-value pairs of spectator powers where the key is the [IN](https://wiki.facepunch.com/gmod/Enums/IN) enum value of the desired button press and the value is an object with the following properties:
  - *start_command* - The console command to run to start the power effect
  - *end_command* - The console command to run to end the power effect
  - *time* - The amount of time before the end command should be run
  - *cost* - The cost of using this power

*Return:*
- *skip* - Whether the remaining spectator keypress logic should be skipped
- *power_property* - The NWInt property name to use when getting and updating the current spectator power level

### TTTSpectatorShowHUD(client, tgt)
Called when a player should be shown a role-specific spectator HUD, allowing that role's logic to render the HUD as needed.\
*Realm:* Client\
*Added in:* 1.3.1\
*Parameters:*
- *client* - The local player
- *tgt* - The target playing being spectated

### TTTSpeedMultiplier(ply, mults, sprinting)
Called when determining what speed the player should be moving at.\
*NOTE:* This hook is [predicted](https://wiki.facepunch.com/gmod/prediction). This means that in singleplayer, it will not be called in the Client realm.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *ply* - The target player
- *mults* - The table of speed multipliers that should be applied to this player. Insert any multipliers you would like to apply to the target player into this table
- *sprinting* - Whether the player is currently sprinting *(Added in 1.7.3)*

### TTTSprintKey(ply)
Called when determining if a player is sprinting. Allows overriding of which directional key needs to be pressed for sprinting to start.\
*NOTE:* This hook is [predicted](https://wiki.facepunch.com/gmod/prediction). This means that in singleplayer, it will not be called in the Client realm.\
*Realm:* Client and Server\
*Added in:* 1.0.0 on Client and 1.8.8 on Server\
*Parameters:*
- *ply* - Player who is being checked for sprinting

*Return:* The [IN_*](https://wiki.facepunch.com/gmod/Enums/IN) enum value representing the key that must be pressed in addition to `IN_SPEED` to start sprinting. If none provided, default of `IN_FORWARD` will be used.

### TTTSprintStaminaPost(ply, stamina, sprintTimer, consumption)
Called after a player's sprint stamina is reduced. Used to adjust the player's new stamina amount.\
*NOTE:* This hook is [predicted](https://wiki.facepunch.com/gmod/prediction). This means that in singleplayer, it will not be called in the Client realm.\
*Realm:* Client and Server\
*Added in:* 1.0.2 on Client and 1.8.8 on Server\
*Parameters:*
- *ply* - Player whose stamina is being adjusted
- *stamina* - Player's current stamina
- *sprintTimer* - Time representing when the player last sprinted
- *consumption* - The stamina consumption rate

*Return:* The stamina value to assign to the player. If none is provided, the player's stamina will not be changed.

### TTTSprintStaminaRecovery(ply, recovery)
Called before a player's sprint stamina is recovered. Used to adjust how fast the player's stamina will recover.\
*NOTE:* This hook is [predicted](https://wiki.facepunch.com/gmod/prediction). This means that in singleplayer, it will not be called in the Client realm.\
*Realm:* Client and Server\
*Added in:* 1.3.6 on Client and 1.8.8 on Server\
*Parameters:*
- *ply* - Player whose stamina is being adjusted
- *recovery* - Player's current stamina recovery rate

*Return:* The stamina recovery rate to assign to the player. If none is provided, the player's default stamina recovery rate will be used.

### TTTSprintStateChange(ply, sprinting, wasSprinting)
Called when a player starts or stops sprinting.\
*NOTE*: This represents the change in player speed, not the change in the `Sprinting` player variable.\
*NOTE:* This hook is [predicted](https://wiki.facepunch.com/gmod/prediction). This means that in singleplayer, it will not be called in the Client realm.\
*Realm:* Client and Server\
*Added in:* 1.8.8\
*Parameters:*
- *ply* - Player whose sprint state changed
- *sprinting* - Whether the player is now sprinting
- *wasSprinting* - Whether the player was sprinting

### TTTShouldPlayerSmoke(ply, client, shouldSmoke, smokeColor, smokeParticle, smokeOffset)
.\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *ply* - The target player being rendered
- *client* - The local player
- *shouldSmoke* - Whether the player would normally emit smoke
- *smokeColor* - What [Color](https://wiki.facepunch.com/gmod/Color) the smoke will be. (Defaults to `COLOR_BLACK`)
- *smokeParticle* - What particle the smoke will use. Should be the relative path the the `.vmt` file for the particle. (Defaults to `"particle/snow.vmt"`)
- *smokeOffset* - A [Vector](https://wiki.facepunch.com/gmod/Vector) representing the relative offset from the player's feet. (Defaults to `Vector(0, 0, 30)`)

*Return:*
- *shouldSmoke* - The new shouldSmoke value to use or the original passed into the hook
- *smokeColor* - The new smokeColor value to use or the original passed into the hook
- *smokeParticle* - The new smokeParticle value to use or the original passed into the hook
- *smokeOffset* - The new smokeOffset value to use or the original passed into the hook

### TTTSyncEventIDs()
Called when the server is syncing generated event IDs to the client.\
*Realm:* Client\
*Added in:* 1.4.6

### TTTSyncGlobals()
Called when the server is syncing convars to global variables for client access.\
*Realm:* Server\
*Added in:* 1.2.7

### TTTSyncWinIDs()
Called when the server is syncing generated win IDs to the client.\
*Realm:* Client\
*Added in:* 1.4.6

### TTTTargetIDPlayerBlockIcon(ply, client)
Called before a player's overhead icon is shown, allowing you to block it.\
*Realm:* Client\
*Added in:* 1.3.5\
*Parameters:*
- *ply* - The target player being rendered
- *client* - The local player

*Return:* `true` to stop this information from being rendered

### TTTTargetIDPlayerBlockInfo(ply, client)
Called before a player's target information (name, health, hint text, karma, and ring) are shown, allowing you to block it.\
*Realm:* Client\
*Added in:* 1.3.5\
*Parameters:*
- *ply* - The target player being rendered
- *client* - The local player

*Return:* `true` to stop this information from being rendered

### TTTTargetIDPlayerHealth(ply, client, text, clr)
Called before a player's heath status (shown when you look at a player) is rendered.\
*Realm:* Client\
*Added in:* 1.2.5\
*Parameters:*
- *ply* - The target player being rendered
- *client* - The local player
- *text* - The health-related text being shown
- *clr* - The [Color](https://wiki.facepunch.com/gmod/Color) of the text being used

*Return:*
- *text* - The new text value to use or the original passed into the hook. Return `false` to not show text at all
- *clr* - The new clr value to use or the original passed into the hook

### TTTTargetIDEntityHintLabel(ent, client, label, clr)
Called before an entity's hint label (shown when you look at an entity) is rendered.\
*Realm:* Client\
*Added in:* 1.2.5\
*Parameters:*
- *ent* - The target entity being rendered. Guaranteed to not be a player.
- *client* - The local player
- *text* - The label for the hint-related text being shown
- *clr* - The [Color](https://wiki.facepunch.com/gmod/Color) of the text being used

*Return:*
- *text* - The new text value to use or the original passed into the hook. Return `false` to not show text at all
- *clr* - The new clr value to use or the original passed into the hook

### TTTTargetIDPlayerHintText(ent, client, text, clr)
Called before an entity's hint text (shown when you look at an entity) is rendered.\
*Realm:* Client\
*Added in:* 1.2.5\
*Parameters:*
- *ent* - The target entity being rendered. Not necessarily a player so be sure to check `ent:IsPlayer()` if needed
- *client* - The local player
- *text* - The hint-related text being shown
- *clr* - The [Color](https://wiki.facepunch.com/gmod/Color) of the text being used

*Return:*
- *text* - The new text value to use or the original passed into the hook. Return `false` to not show text at all
- *clr* - The new clr value to use or the original passed into the hook
- *secondary_text* - A secondary text value to show under `text`. Return `false` or nothing to not show secondary text at all
- *secondary_color* - The [Color](https://wiki.facepunch.com/gmod/Color) to use for `secondary_text`. If not provided, `clr` value will be used instead *(Added in 1.6.17)*

### TTTTargetIDPlayerKarma(ply, client, text, clr)
Called before a player's karma status text (shown when you look at a player) is rendered.\
*Realm:* Client\
*Added in:* 1.2.5\
*Parameters:*
- *ply* - The target player being rendered
- *client* - The local player
- *text* - The karma-related text being shown
- *clr* - The [Color](https://wiki.facepunch.com/gmod/Color) of the text being used

*Return:*
- *text* - The new text value to use or the original passed into the hook. Return `false` to not show text at all
- *clr* - The new clr value to use or the original passed into the hook

### TTTTargetIDPlayerName(ply, client, text, clr)
Called before a player's name (shown when you look at a player) is rendered.\
*Realm:* Client\
*Added in:* 1.2.5\
*Parameters:*
- *ply* - The target player being rendered
- *client* - The local player
- *text* - The player's name text being shown
- *clr* - The [Color](https://wiki.facepunch.com/gmod/Color) of the text being used

*Return:*
- *text* - The new text value to use or the original passed into the hook. Return `false` to not show text at all
- *clr* - The new clr value to use or the original passed into the hook

### TTTTargetIDPlayerRing(ent, client, ringVisible)
Called before an entity's Target ID ring (shown when you look at an entity) is rendered.\
*Realm:* Client\
*Added in:* 1.2.3\
*Parameters:*
- *ent* - The target entity being rendered. Not necessarily a player so be sure to check `ent:IsPlayer()` if needed
- *client* - The local player
- *ringVisible* - Whether the ring would normally be visible for this target

*Return:*
- *newVisible* - The new ringVisible value to use or the original passed into the hook
- *colorOverride* - The [Color](https://wiki.facepunch.com/gmod/Color) to use for the ring. Return `false` if you don't want to override the color. *NOTE:* For some reason colors that are near-black do not render so try a lighter color if you are having trouble

### TTTTargetIDPlayerRoleIcon(ply, client, role, noZ, colorRole, hideBeggar, showJester, hideBodysnatcher)
Called before player Target ID icon (over their head) is rendered allowing changing the icon and color shown.\
*Realm:* Client\
*Added in:* 1.1.9\
*Parameters:*
- *ply* - The target player being rendered
- *client* - The local player
- *role* - What role is currently being shown for the target player
- *noZ* - Whether the icon is currently visible through walls
- *colorRole* - What role is being used for the icon background color (Only used when a different color than the one belonging to *role* is being used)
- *hideBeggar* - Whether the target was a beggar whose new role should be hidden
- *showJester* - Whether the target is a jester and the local player would normally know that
- *hideBodysnatcher* - Whether the target is a bodysnatcher whose new role should be hidden *(Added in 1.2.5)*

*Return:*
- *role* - The new role value to use or the original passed into the hook. Return `false` to stop the icon from being rendered
- *noZ* - The new noZ value to use or the original passed into the hook. *NOTE:* The matching icon .vmt for this flag needs to exist. If *noZ* is `true`, a "sprite\_{ROLESHORTNAME}\_noz.vmt" file must exist and if *noZ* is `false`, a "sprite_{ROLESHORTNAME}.vmt" file must exist
- *colorRole* - The new colorRole value to use or the original passed into the hook

### TTTTargetIDPlayerTargetIcon(ply, client, showJester)
Called before player Target ID icon (over their head) is rendered allowing adding a secondary icon.\
*Realm:* Client\
*Added in:* 1.9.4\
*Parameters:*
- *ply* - The target player being rendered
- *client* - The local player
- *showJester* - Whether the target is a jester and the local player would normally know that

*Return:*
- *icon* - The icon name used in the filename of the icon
- *iconNoZ* - Whether the icon should be visible through walls. *NOTE:* A .vmt file for the icon must exist in "vgui/ttt/targeticons/{ICONTYPE}". If *iconNoZ* is `true`, a "sprite_target_{ICONNAME}_noz.vmt" file must exist and if *iconNoZ* is `false`, a "sprite_target_{ICONNAME}.vmt" file must exist
- *iconColor* - The [Color](https://wiki.facepunch.com/gmod/Color) to use for the icon
- *iconType* - The icon type used in the filename of the icon. `"down"` if you want the icon background to be a downwards pointing triangle, or `"up"` for an upwards pointing triangle

### TTTTargetIDPlayerText(ent, client, text, clr, secondaryText)
Called before player Target ID text (shown when you look at a player) is rendered.\
*Realm:* Client\
*Added in:* 1.1.9\
*Parameters:*
- *ent* - The target entity being rendered. Not necessarily a player so be sure to check `ent:IsPlayer()` if needed
- *client* - The local player
- *text* - The first line of text being shown
- *clr* - The [Color](https://wiki.facepunch.com/gmod/Color) of the text being used
- *secondaryText* - The second line of text being shown

*Return:*
- *text* - The new text value to use or the original passed into the hook. Return `false` to not show text at all
- *clr* - The new clr value to use or the original passed into the hook
- *secondaryText* - The new secondaryText value to use or the original passed into the hook. Return `false` to not show text at all

### TTTTargetIDRagdollName(ent, client, text, clr)
Called before a ragdoll's name (shown when you look at a ragdoll) is rendered.\
*Realm:* Client\
*Added in:* 1.2.5\
*Parameters:*
- *ent* - The target ragdoll being rendered
- *client* - The local player
- *text* - The ragdoll's name text being shown
- *clr* - The [Color](https://wiki.facepunch.com/gmod/Color) of the text being used

*Return:*
- *text* - The new text value to use or the original passed into the hook. Return `false` to not show text at all
- *clr* - The new clr value to use or the original passed into the hook

### TTTTeamChatTargets(sender, msg, targets, from_chat)
Called before a team chat message is sent. Used to modify the targets of the team message.\
*Realm:* Server\
*Added in:* 2.0.7\
*Parameters:*
- *sender* - The player sending the chat message
- *msg* - The message being sent
- *targets* - The table of players that this message will be sent to. Add or remove players from this table to change the message recipients
- *from_chat* - Whether this hook is being called from the actual chat send method

*Return:* Whether or not this team chat message should be sent (Defaults to `true`)

### TTTTeamVoiceChatTargets(speaker, targets)
Called before a team voice state message is sent. Used to modify the targets of the team voice state message.\
*Realm:* Server\
*Added in:* 2.0.7\
*Parameters:*
- *speaker* - The player trying to send their team voice state message
- *targets* - The table of players that this message will be sent to. Add or remove players from this table to change the message recipients

*Return:* Whether or not this team voice state message should be sent (Defaults to `true`)

### TTTTurncoatTeamChanged(ply, traitor)
Called when a turncoat's team is changed
*Realm:* Server\
*Added in:* 1.6.16\
*Parameters:*
- *ply* - The player who triggered the turncoat team change (most likely would be the turncoat themselves)
- *traitor* - Whether the turncoat is changing to the traitor team

### TTTTutorialRoleEnabled(role)
Called before a role's tutorial page is rendered. This can be used to allow a page to be shown when it normally would not be because the role is disabled. Useful for situations like showing the Zombie tutorial page when the Mad Scientist is enabled (because the Mad Scientist creates Zombies).\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *role* - Which role's tutorial page is being rendered

*Return:* `true` to show this page when it normally would not be

### TTTTutorialRolePage(role, parentPanel, titleLabel, roleIcon)
Called before a role's tutorial page is rendered. This can be used to render a completely custom page with information about a role.\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *role* - Which role's tutorial page is being rendered
- *parentPanel* - The parent [DPanel](https://wiki.facepunch.com/gmod/DPanel) that this tutorial page is being rendered within
- *titleLabel* - The [DLabel](https://wiki.facepunch.com/gmod/DLabel) that is being used as the title of the rendered tutorial page. Has the role's name automatically set as the label text
- *roleIcon* - The [DImage](https://wiki.facepunch.com/gmod/DImage) that is being used to show the role's icon on the rendered tutorial page

*Return:* `true` to tell the tutorial page to use the content set in this hook rather than calling the `TTTTutorialRoleText` hook

### TTTTutorialRolePageExtra(role, parentPanel, titleLabel, roleIcon)
Called after a role's tutorial page is rendered. This can be used to provide additional data to show for a role.\
*Realm:* Client\
*Added in:* 1.5.3\
*Parameters:*
- *role* - Which role's tutorial page is being rendered
- *parentPanel* - The parent [DPanel](https://wiki.facepunch.com/gmod/DPanel) that this tutorial page is being rendered within
- *titleLabel* - The [DLabel](https://wiki.facepunch.com/gmod/DLabel) that is being used as the title of the rendered tutorial page. Has the role's name automatically set as the label text
- *roleIcon* - The [DImage](https://wiki.facepunch.com/gmod/DImage) that is being used to show the role's icon on the rendered tutorial page

### TTTTutorialRoleText(role, titleLabel, roleIcon)
Called before a role's tutorial page is rendered. This can be used to provide the text to show for a role.\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *role* - Which role's tutorial page is being rendered
- *titleLabel* - The [DLabel](https://wiki.facepunch.com/gmod/DLabel) that is being used as the title of the rendered tutorial page. Has the role's name automatically set as the label text
- *roleIcon* - The [DImage](https://wiki.facepunch.com/gmod/DImage) that is being used to show the role's icon on the rendered tutorial page

*Return:* The string value to show on the tutorial page for this role. Can be HTML and will be rendered within a `<div>`

### TTTTutorialRoleTextExtra(role, titleLabel, roleIcon, htmlData)
Called before a role's tutorial page is rendered but after `TTTTutorialRoleText` is called. This can be used to provide additional text to show for a role.\
*Realm:* Client\
*Added in:* 1.5.3\
*Parameters:*
- *role* - Which role's tutorial page is being rendered
- *titleLabel* - The [DLabel](https://wiki.facepunch.com/gmod/DLabel) that is being used as the title of the rendered tutorial page. Has the role's name automatically set as the label text
- *roleIcon* - The [DImage](https://wiki.facepunch.com/gmod/DImage) that is being used to show the role's icon on the rendered tutorial page
- *htmlData* - The string HTML data that would be shown for the given role. It does not include the closing `</div>` tag, meaning additional HTML can be appended to the end without worrying about proper structure.

*Return:* The full string value to show on the tutorial page for this role. Should not include the closing `</div>` tag as this is appended automatically.

### TTTUpdateRoleState()
Called after globals are synced but but before role colors and strings are set. Can be used to update role states (team membership) and role weapon (buyable, loadout, etc.) states based on configurations.\
*Realm:* Client and Server\
*Added in:* 1.2.7

### TTTVampireBodyEaten(ply, ent, living, healed)
Called after a vampire eats a body.\
*Realm:* Server\
*Added in:* 1.6.16\
*Parameters:*
- *ply* - The vampire eating the body
- *ent* - The target entity. Generally either a player or a ragdoll
- *living* - Whether the target entity was living at the time they were eaten
- *healed* - The amount of health the player gained from eating the body

### TTTVampireInvisibilityChange(ply, invisible)
Called when a vampire starts or ends their invisibility.\
*Realm:* Server\
*Added in:* 1.6.16\
*Parameters:*
- *ply* - The vampire changing invisibility state
- *ent* - The target entity. Generally either a player or a ragdoll

### TTTWinCheckBlocks(winBlocks)
Called after the `TTTCheckForWins` has already been called, allowing for an addon to block a win. Used for roles like the clown and the drunk to have them activate when the round would normally end the first time.\
*Realm:* Server\
*Added in:* 1.3.1\
*Parameters:*
- *winBlocks* - The table of callback functions that are given the current win type and return either the same win type they are given or a different win type if it should be changed. The callback function should **always** return a value.

### TTTWinCheckComplete(win)
Called after a win condition has been set and right before the round eds. Used for roles like the old man that perform some logic before the end of the round without changing the outcome.\
*Realm:* Server\
*Added in:* 1.3.1\
*Parameters:*
- *win* - The win type that the round is about to end with