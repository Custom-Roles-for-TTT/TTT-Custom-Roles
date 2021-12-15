## Hooks
Custom and modified event hooks available within the defined realm. A list of default TTT hooks is available [here](https://www.troubleinterroristtown.com/development/hooks/) but note that they may have been modified (see below).

***NOTE:*** When using a hook with multiple return values, you *must* return a non-`nil` value for all properties up to the one(s) you are modifying or the hook results will be ignored entirely.

For example, if there is a hook that returns three parameters: `first`, `second`, and `third` and you want to modify the `second` parameter you must return the `first` parameter as non-`nil` as well, like this: `return first, newSecond`. Any return parameters after `second` can be omitted and the default value will be used.

***NOTE:*** Be careful that you only return from a hook when you absolutely want to change something. Due to the way GMod hooks work, whichever hook instance returns first causes the *remaining hook instances to be completely skipped*. This is useful for certain hooks when you want to stop a behavior from happening, but it can also accidentally cause functionality to break because its code is completely ignored.

**TTTBlockPlayerFootstepSound(ply)** - Called when a player is making a footstep. Used to determine if the player's footstep sound should be stopped.\
*Realm:* Client and Server\
*Added in:* 1.2.7\
*Parameters:*
- *ply* - The player who is making footsteps

*Return:* Whether or not the given player's footstep sounds should be stopped (Defaults to `false`).

**TTTCanIdentifyCorpse(ply, rag, wasTraitor)** - Changed `was_traitor` parameter to be `true` for any member of the traitor team, rather than just the traitor role.\
*Realm:* Server\
*Added in:* 1.0.5\
*Parameters:*
- *ply* - The player who is attempting to identify a corpse
- *rag* - The ragdoll being identified
- *wasTraitor* - Whether the player who the targetted ragdoll represents belonged to the traitor team

*Return:* Whether or not the given player should be able to identify the given corpse (Defaults to `false`).

**TTTEventFinishText(e)** - Called before the event text for the "round finished" event is rendered in the end-of-round summary's Events tab.\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *e* - Event parameters. Contains the following properties:
  - `id` - The event identifier (always `EVENT_FINISH`)
  - `t` - The time when this event occurred
  - `win` - The win condition identifier

*Return:* Text to show in events list at the end of the round

**TTTEventFinishIconText(e, winString, roleString)** - Called before the event icon for the "round finished" event is rendered in the end-of-round summary's Events tab. Used to change the mouseover text for the icon.\
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

**TTTHUDInfoPaint(client, labelX, labelY)** - Called after player information such as role, health, and ammo and equipment information such as radar cooldown and disguiser activation are drawn on the screen. Used to write additional persistent text on the screen for player reference.\
*Realm:* Client\
*Added in:* 1.3.1\
*Parameters:*
- *client* - The local player
- *labelX* - The X value representing the correct indentation from the left side of the screen to add information
- *labelY* - The Y value representing the first clear space to add information

**TTTKarmaGiveReward(ply, reward, victim)** - Called before a player is rewarded with karma. Used to block a player's karma reward.\
*Realm:* Server\
*Added in:* 1.2.7\
*Parameters:*
- *ply* - The player who will be rewarded karma
- *reward* - The amount of karma the player will be rewarded with
- *victim* - The victim of the event that is rewarding the player with karma. If this is not a player, karma is being rewarded as part of the end of the round

*Return:* Whether or not the given player should be prevented from being rewarded with karma (Defaults to `false`).

**TTTKarmaShouldGivePenalty(attacker, victim)** - Called before a player's karma effect is decided. Used to determine if a player should be penalized or rewarded.\
*Realm:* Server\
*Added in:* 1.2.7\
*Parameters:*
- *attacker* - The player who hurt or killed the victim
- *victim* - The player who was hurt or killed

*Return:* `true` if the attacker should be penalized or `false` if they should not. If you have no opinion (e.g. let other logic determine this) then don't return anything at all.

**TTTPlayerAliveClientThink(client, ply)** - Called for each player who is alive during the Think hook.\
*Realm:* Client\
*Added in:* 1.3.1\
*Parameters:*
- *client* - The local player
- *ply* - The current alive player target

**TTTPlayerDefibRoleChange(ply, tgt)** - Called after a player has been resurrected by a device that also changes their role.\
*Realm:* Server\
*Added in:* 1.3.1\
*Parameters:*
- *ply* - The player using the resurrection device
- *tgt* - The target player being resurrected

**TTTPlayerRoleChanged(ply, oldRole, newRole)** - Called after a player's role has changed.\
*Realm:* Client and Server\
*Added in:* 1.2.7\
*Parameters:*
- *ply* - The player whose role is being changed
- *oldRole* - The role the player had before this change
- *newRole* - The role the player is changing to

**TTTPlayerSpawnForRound(ply, deadOnly)** - Called before a player is spawned for a round. Also used when reviving a player (via a defib, zombie conversion, etc.).\
*Realm:* Server\
*Added in:* 1.2.7\
*Parameters:*
- *ply* - The player who is being spawned or respawned
- *deadOnly* - Whether this call is specifically targetted at dead players

**TTTPrintResultMessage(type)** - Called before the round win results message is printed to the top-right corner of the screen. Can be used to print a replacement message for custom win types that this would not normally handle.\
*Realm:* Server\
*Added in:* 1.0.14\
*Parameters:*
- *type* - The round win type

*Return:* `true` if the default print messages should be skipped (Defaults to `false`).

**TTTRadarPlayerRender(client, tgt, color, hidden)** - Called before a target's radar ping is rendered, allowing the color and whether the ping should be shown to be changed.\
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

**TTTRadarRender(client)** - Called after non-player radar points are rendered and before players are rendered. Used for rendering custom non-player radar points.\
*Realm:* Client\
*Added in:* 1.3.1\
*Parameters:*
- *client* - The local player

**TTTRolePopupParams(client)** - Called before a player's role start-of-round popup message is displayed, allowing the parameters to be added to.\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *client* - The local player

*Return:*
- *params* - Table of name-value parameters to be used in this player's role start-of-round popup message

**TTTScoreboardPlayerName(ply, client, currentName)** - Called before a player's row in the scoreboard (tab menu) is shown, allowing the name to be changed.\
*Realm:* Client\
*Added in:* 1.1.9\
*Parameters:*
- *ply* - The player being rendered
- *client* - The local player
- *currentName* - The current name string (including extra information)

*Return:*
- *name* - The new name value to show on the scoreboard

**TTTScoreboardPlayerRole(ply, client, color, roleFileName)** - Called before a player's row in the scoreboard (tab menu) is shown, allowing the colors and icon to be changed.\
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

**TTTScoringSecondaryWins(wintype, secondaryWins)** - Called before each round summary screen is shown with the winning team. Used to add roles to the secondary win display (e.g. AND THE OLD MAN WINS).\
*Realm:* Client\
*Added in:* 1.4.1\
*Parameters:*
- *wintype* - The round win type
- *secondaryWins* - The table of role identifiers for roles who should have a secondary win on the round summary. Insert any role identifiers you would like to display into this table

**TTTScoringSummaryRender(ply, roleFileName, groupingRole, roleColor, nameLabel, startingRole, finalRole)** - Called before the round summary screen is shown. Used to modify the color, position, and icon for a player.\
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

**TTTScoringWinTitle(wintype, wintitles, title)** - Called before each round summary screen is shown with the winning team. Return the win title object to use on the summary screen.\
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

**TTTSelectRoles(choices, prevRoles)** - Called before players are randomly assigned roles. If a player is assigned a role during this hook, they will not be randomly assigned one later.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *choices* - The table of players who will be assigned roles
- *prevRoles* - The table whose keys are role numbers and values are tables of players who had that role last round

**TTTSelectRolesDetectiveOptions(roleTable, choices, choiceCount, traitors, traitorCount)** - Called before players are assigned a detective role, allowing the available roles and their weights (how many times they appear in the table) to be manipulated.\
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

**TTTSelectRolesIndependentOptions(roleTable, choices, choiceCount, traitors, traitorCount)** - Called before players are assigned a independent role, allowing the available roles and their weights (how many times they appear in the table) to be manipulated.\
*Realm:* Server\
*Added in:* 1.2.3\
*Parameters:*
- *roleTable* - The table of roles representing the available independent roles (and jester roles, if ttt_single_jester_independent is enabled) and their weight (how many times they appear in the table). This table should be manipulated to effect change
- *choices* - The table of available player choices that will not be (and have not already been) assigned a traitor or detective role. Manipulating this table will have no effect
- *choiceCount* - The total number of player choices there are
- *traitors* - The table of available player choices that will be (or have already been) assigned a traitor role. Manipulating this table will have no effect
- *traitorCount* - The number of players that will be (or have already been) assigned a traitor role
- *detectives* - The table of available player choices that will be (or have already been) assigned a detective role. Manipulating this table will have no effect
- *detectiveCount* - The number of players that will be (or have already been) assigned a detective role

**TTTSelectRolesInnocentOptions(roleTable, choices, choiceCount, traitors, traitorCount)** - Called before players are assigned an innocent role, allowing the available roles and their weights (how many times they appear in the table) to be manipulated.\
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

**TTTSelectRolesJesterOptions(roleTable, choices, choiceCount, traitors, traitorCount)** - Called before players are assigned a jester role, allowing the available roles and their weights (how many times they appear in the table) to be manipulated.\
*Realm:* Server\
*Added in:* 1.2.3\
*Parameters:*
- *roleTable* - The table of roles representing the available jester roles (and independent roles, if ttt_single_jester_independent is enabled) and their weight (how many times they appear in the table). This table should be manipulated to effect change
- *choices* - The table of available player choices that will not be (and have not already been) assigned a traitor or detective role. Manipulating this table will have no effect
- *choiceCount* - The total number of player choices there are
- *traitors* - The table of available player choices that will be (or have already been) assigned a traitor role. Manipulating this table will have no effect
- *traitorCount* - The number of players that will be (or have already been) assigned a traitor role
- *detectives* - The table of available player choices that will be (or have already been) assigned a detective role. Manipulating this table will have no effect
- *detectiveCount* - The number of players that will be (or have already been) assigned a detective role

**TTTSelectRolesMonsterOptions(roleTable, choices, choiceCount, traitors, traitorCount)** - Called before players are assigned a monster role, allowing the available roles and their weights (how many times they appear in the table) to be manipulated.\
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

**TTTSelectRolesTraitorOptions(roleTable, choices, choiceCount, traitors, traitorCount)** - Called before players are assigned a traitor role, allowing the available roles and their weights (how many times they appear in the table) to be manipulated.\
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

**TTTSpectatorHUDKeyPress(ply, tgt, powers)** - Called when a player who is being shown a role-specific spectator HUD presses a button, allowing the hook to intercept that button press and perform specific logic if necessary.\
*Realm:* Server\
*Added in:* 1.3.1\
*Parameters:*
- *ply* - The spectator player who is attemping to press a key
- *tgt* - The target playing being spectated
- *powers* - The table of key-value pairs of spectator powers where the key is the [IN](https://wiki.facepunch.com/gmod/Enums/IN) enum value of the desired button press and the value is an object with the following properties:
  - *start_command* - The console command to run to start the power effect
  - *end_command* - The console command to run to end the power effect
  - *time* - The amount of time before the end command should be run
  - *cost* - The cost of using this power

*Return:*
- *skip* - Whether the remaining spectator keypress logic should be skipped
- *power_property* - The NWInt property name to use when getting and updating the current spectator power level

**TTTSpectatorShowHUD(client, tgt)** - Called when a player should be shown a role-specific spectator HUD, allowing that role's logic to render the HUD as needed.\
*Realm:* Client\
*Added in:* 1.3.1\
*Parameters:*
- *client* - The local player
- *tgt* - The target playing being spectated

**TTTSpeedMultiplier(ply, mults)** - Called when determining what speed the player should be moving at.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *ply* - The target player
- *mults* - The table of speed multipliers that should be applied to this player. Insert any multipliers you would like to apply to the target player into this table

**TTTSprintStaminaPost(ply, stamina, sprintTimer, consumption)** - Called after a player's sprint stamina is reduced. Return value is the new stamina value for the player.\
*Realm:* Client\
*Added in:* 1.0.2\
*Parameters:*
- *ply* - Player whose stamina is being adjusted
- *stamina* - Player's current stamina
- *sprintTimer* - Time representing when the player last sprinted
- *consumption* - The stamina consumption rate

*Return:* The stamina value to assign to the player. If none is provided, the player's stamina will not be changed.

**TTTSprintStaminaRecovery(client, recovery)** - Called before a player's sprint stamina is recovered. Used to adjust how fast the player's stamina will recover.\
*Realm:* Client\
*Added in:* 1.3.6\
*Parameters:*
- *client* - The local player
- *recovery* - Player's current stamina recovery rate

*Return:* The stamina recovery rate to assign to the player. If none is provided, the player's default stamina recovery rate will be used.

**TTTShouldPlayerSmoke(ply, client, shouldSmoke, smokeColor, smokeParticle, smokeOffset)** - .\
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

**TTTSyncGlobals()** - Called when the server is syncing convars to global variables for client access.\
*Realm:* Server\
*Added in:* 1.2.7

**TTTTargetIDPlayerBlockIcon(ply, client)** - Called before a player's overhead icon is shown, allowing you to block it.\
*Realm:* Client\
*Added in:* 1.3.5\
*Parameters:*
- *ply* - The target player being rendered
- *client* - The local player

*Return:* `true` to stop this information from being rendered

**TTTTargetIDPlayerBlockInfo(ply, client)** - Called before a player's target information (name, health, hint text, karma, and ring) are shown, allowing you to block it.\
*Realm:* Client\
*Added in:* 1.3.5\
*Parameters:*
- *ply* - The target player being rendered
- *client* - The local player

*Return:* `true` to stop this information from being rendered

**TTTTargetIDPlayerHealth(ply, client, text, clr)** - Called before a player's heath status (shown when you look at a player) is rendered.\
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

**TTTTargetIDEntityHintLabel(ent, client, label, clr)** - Called before an entity's hint label (shown when you look at an entity) is rendered.\
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

**TTTTargetIDPlayerHintText(ent, client, text, clr)** - Called before an entity's hint text (shown when you look at an entity) is rendered.\
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

**TTTTargetIDPlayerKarma(ply, client, text, clr)** - Called before a player's karma status text (shown when you look at a player) is rendered.\
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

**TTTTargetIDPlayerKillIcon(ply, client, showKillIcon, showJester)** - Called before player Target ID icon (over their head) is rendered to determine if the "KILL" icon should be shown.\
*Realm:* Client\
*Added in:* 1.1.9\
*Parameters:*
- *ply* - The target player being rendered
- *client* - The local player
- *showKillIcon* - Whether the kill icon would normally be shown for this player
- *showJester* - Whether the target is a jester and the local player would normally know that

*Return:* `true` if the kill icon should be shown or `false` if not. Returning nothing or a non-boolean value will default to the given *showKillIcon* value.

**TTTTargetIDPlayerName(ply, client, text, clr)** - Called before a player's name (shown when you look at a player) is rendered.\
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

**TTTTargetIDPlayerRing(ent, client, ringVisible)** - Called before an entity's Target ID ring (shown when you look at an entity) is rendered.\
*Realm:* Client\
*Added in:* 1.2.3\
*Parameters:*
- *ent* - The target entity being rendered. Not necessarily a player so be sure to check `ent:IsPlayer()` if needed
- *client* - The local player
- *ringVisible* - Whether the ring would normally be visible for this target

*Return:*
- *newVisible* - The new ringVisible value to use or the original passed into the hook
- *colorOverride* - The [Color](https://wiki.facepunch.com/gmod/Color) to use for the ring. Return `false` if you don't want to override the color. *NOTE:* For some reason colors that are near-black do not render so try a lighter color if you are having trouble

**TTTTargetIDPlayerRoleIcon(ply, client, role, noZ, colorRole, hideBeggar, showJester, hideBodysnatcher)** - Called before player Target ID icon (over their head) is rendered allowing changing the icon and color shown.\
*Realm:* Client\
*Added in:* 1.1.9\
*Parameters:*
- *ply* - The target player being rendered
- *client* - The local player
- *role* - What role is currently being shown for the target player
- *noZ* - Whether the icon is currently visible through walls
- *colorRole* - What role is being used for the icon background color (Only used when a different color than the only belonging to *role* is being used)
- *hideBeggar* - Whether the target was a beggar whose new role should be hidden
- *showJester* - Whether the target is a jester and the local player would normally know that
- *hideBodysnatcher* - Whether the target is a bodysnatcher whose new role should be hidden *(Added in 1.2.5)*

*Return:*
- *role* - The new role value to use or the original passed into the hook. Return `false` to stop the icon from being rendered
- *noZ* - The new noZ value to use or the original passed into the hook. *NOTE:* The matching icon .vmt for this flag needs to exist. If *noZ* is `true`, a "sprite\_{ROLESHORTNAME}\_noz.vmt" file must exist and if *noZ* is `false`, a "sprite_{ROLESHORTNAME}.vmt" file must exist
- *colorRole* - The new colorRole value to use or the original passed into the hook

**TTTTargetIDPlayerText(ent, client, text, clr, secondaryText)** - Called before player Target ID text (shown when you look at a player) is rendered.\
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

**TTTTargetIDRagdollName(ent, client, text, clr)** - Called before a ragdoll's name (shown when you look at a ragdoll) is rendered.\
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

**TTTTutorialRoleEnabled(role)** - Called before a role's tutorial page is rendered. This can be used to allow a page to be shown when it normally would not be because the role is disabled. Useful for situations like showing the Zombie tutorial page when the Mad Scientist is enabled (because the Mad Scientist creates Zombies).\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *role* - Which role's tutorial page is being rendered

*Return:* `true` to show this page when it normally would not be

**TTTTutorialRolePage(role, parentPanel, titleLabel, roleIcon)** - Called before a role's tutorial page is rendered. This can be used to render a completely custom page with information about a role.\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *role* - Which role's tutorial page is being rendered
- *parentPanel* - The parent [DPanel](https://wiki.facepunch.com/gmod/DPanel) that this tutorial page is being rendered within
- *titleLabel* - The [DLabel](https://wiki.facepunch.com/gmod/DLabel) that is being used as the title of the rendered tutorial page. Has the role's name automatically set as the label text
- *roleIcon* - The [DImage](https://wiki.facepunch.com/gmod/DImage) that is being used to show the role's icon on the rendered tutorial page

*Return:* `true` to tell the tutorial page to use the content set in this hook rather than calling the `TTTTutorialRoleText` hook

**TTTTutorialRoleText(role, titleLabel, roleIcon)** - Called before a role's tutorial page is rendered. This can be used to provide the text to show for a role.\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *role* - Which role's tutorial page is being rendered
- *titleLabel* - The [DLabel](https://wiki.facepunch.com/gmod/DLabel) that is being used as the title of the rendered tutorial page. Has the role's name automatically set as the label text
- *roleIcon* - The [DImage](https://wiki.facepunch.com/gmod/DImage) that is being used to show the role's icon on the rendered tutorial page

*Return:* The string value to show on the tutorial page for this role. Can be HTML and will be rendered within a `<div>`

**TTTUpdateRoleState()** - Called after globals are synced but but before role colors and strings are set. Can be used to update role states (team membership) and role weapon (buyable, loadout, etc.) states based on configurations.\
*Realm:* Client and Server\
*Added in:* 1.2.7

**TTTWinCheckBlocks(winBlocks)** - Called after the `TTTCheckForWins` has already been called, allowing for an addon to block a win. Used for roles like the clown and the drunk to have them activate when the round would normally end the first time.\
*Realm:* Server\
*Added in:* 1.3.1\
*Parameters:*
- *winBlocks* - The table of callback functions that are given the current win type and return either the same win type they are given or a different win type if it should be changed. The callback function should **always** return a value.

**TTTWinCheckComplete(win)** - Called after a win condition has been set and right before the round eds. Used for roles like the old man that perform some logic before the end of the round without changing the outcome.\
*Realm:* Server\
*Added in:* 1.3.1\
*Parameters:*
- *win* - The win type that the round is about to end with