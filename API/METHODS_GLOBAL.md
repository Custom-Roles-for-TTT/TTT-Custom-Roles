## Global Methods
Methods available globally (within the defined realm)

**AssignAssassinTarget(ply, start, delay)** - Assigns the target player their next assassination target (if they are the assassin role).\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *ply* - The target player
- *start* - Whether this is running at the start of the round (Defaults to `false`)
- *delay* - Whether the assassin's target assignment is delayed (Defaults to false)

**CRVersion(version)** - Whether the current version is equal to or newer than the version number given.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *version* - The version number to compare against the currently installed version. Must be in the "#.#.#" format

**FindRespawnLocation(pos)** - Finds a possible respawn position based on accessible areas around the given position.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *pos* - The position around which a respawn position will be found

*Returns*: An accessible position around the given position or `false` if none can be found

**GenerateNewEventID(role)** - Generates a new ID to be used for custom scoring events.\
*Realm:* Client *(Deprecated in 1.4.6)* and Server\
*Added in:* 1.2.5\
*Parameters:*
- *role* - The ID of the role that the generated event ID belongs to. Pass `ROLE_NONE` if this should not be associated with any role *(Added in 1.4.2)*

*NOTE:* To get this value on the client, use the `TTTSyncEventIDs` hook and pull the value out of the `EVENTS_BY_ROLE` global table

**GenerateNewWinID(role)** - Generates a new ID to be used for custom win conditions.\
*Realm:* Client *(Deprecated in 1.4.6)* and Server\
*Added in:* 1.2.5\
*Parameters:*
- *role* - The ID of the role that the generated win ID belongs to. Pass `ROLE_NONE` if this should not be associated with any role *(Added in 1.4.2)*

*NOTE:* To get this value on the client, use the `TTTSyncWinIDs` hook and pull the value out of the `WINS_BY_ROLE` global table

**GetEquipmentItemById(id)** - Gets an equipment item's definition by their ID.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *id* - The ID of the equipment item being looked up (e.g. EQUIP_RADAR)

**GetEquipmentItemByName(name)** - Gets an equipment item's definition by their name.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *name* - The name of the equipment item being looked up

**Get{RoleName}Filter(aliveOnly)** - Dynamically created functions for each role that returns a function that filters net messages to players that are role. For example: `GetTraitorFilter()` and `GetPhantomFilter()` return a filter function that can be used to send a message to players who are a traitor or a phantom, respectively.\
*Realm:* Server\
*Added in:* Whenever each role is added\
*Parameters:*
- *aliveOnly* - Whether this filter should only include live players (Defaults to `false`)

**GetInnocentTeamFilter(aliveOnly)** - Returns a function that filters net messages to players that are on the innocent team.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *aliveOnly* - Whether this filter should only include live players (Defaults to `false`)

**GetJesterTeamFilter(aliveOnly)** - Returns a function that filters net messages to players that are on the jester team.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *aliveOnly* - Whether this filter should only include live players (Defaults to `false`)

**GetIndependentTeamFilter(aliveOnly)** - Returns a function that filters net messages to players that are on the independent team.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *aliveOnly* - Whether this filter should only include live players (Defaults to `false`)

**GetMonsterTeamFilter(aliveOnly)** - Returns a function that filters net messages to players that are on the monster team.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *aliveOnly* - Whether this filter should only include live players (Defaults to `false`)

**GetRoleTeamColor(roleTeam, type)** - Gets the color belonging to the specified role team (see ROLE_TEAM_* global enumeration).\
*Realm:* Client\
*Added in:* 1.1.8\
*Parameters:*
- *roleTeam* - Which team role to get the color for (see ROLE_TEAM_* global enumeration)
- *type* - The color modification type. Options are: "dark", "highlight", "radar", "scoreboard", or "sprite". (Optional)

**GetRoleTeamInfo(roleTeam, simpleColor)** - Gets the name and color belonging to the specified role team (see ROLE_TEAM_* global enumeration).\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *roleTeam* - Which team role to get the color for (see ROLE_TEAM_* global enumeration)
- *simpleColor* - Whether to use simple team colors (e.g. all innocents are the same color and all traitors are the same color)

*Returns:*
- *roleTeamName* - The name of the provided role team
- *roleTeamColor* - The color of the provided role team

**GetRoleTeamName(roleTeam)** - Gets the name belonging to the specified role team (see ROLE_TEAM_* global enumeration).\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *roleTeam* - Which team role to get the color for (see ROLE_TEAM_* global enumeration)

**GetSprintMultiplier(ply, sprinting)** - Gets the given player's current sprint multiplier.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *ply* - The target player
- *sprinting* - Whether the player is currently sprinting

**GetTeamRoles(team_table, exclude)** - Gets a table of role numbers that belong to the team whose lookup table is given.\
*Realm:* Client and Server\
*Added in:* 1.0.2\
*Parameters:*
- *team_table* - Team lookup table
- *exclude* - Lookup table of roles to exclude from the team (Optional)

**GetTraitorTeamFilter(aliveOnly)** - Returns a function that filters net messages to players that are on the traitor team.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *aliveOnly* - Whether this filter should only include live players (Defaults to `false`)

**JesterTeamKilledNotification(attacker, victim, getKillString, shouldShow)** - Used to disply a message, play a sound, and/or create confetti when a member of the jester team is killed. Automatically checks `ttt_%NAMERAW%_notify_mode`, `ttt_%NAMERAW%_notify_sound`, and `ttt_%NAMERAW%_notify_confetti` convars.\
*Realm:* Server\
*Added in:* 1.3.1\
*Parameters:*
- *attacker* - The player that killed the victim
- *victim* - The player that was killed
- *getKillString(ply)* - A callback function which returns the message that the player given as a parameter should be shown
- *shouldShow(ply)* - A callback function which returns whether the player given as a parameter should be shown a message (Optional, defaults to `true`)

**OnPlayerHighlightEnabled(client, alliedRoles, showJesters, hideEnemies, traitorAllies, onlyShowEnemies)** - Handles player highlighting (colored glow around players) rules for the local player.\
*Realm:* Client\
*Added in:* 1.2.7\
*Parameters:*
- *client* - The local player
- *alliedRoles* - Table of role IDs that should show as allied to the current player
- *showJesters* - Whether jester roles should be highlighted in the jester color. If `false`, jesters will appear in the generic enemy color instead
- *hideEnemies* - Whether enemy roles (e.g. anyone that isn't an ally or a jester if *showJesters* is enabled) should be highlighted
- *traitorAllies* - Whether this role's allies are traitors. If `true`, allied roles will be shown in the traitor color. Otherwise allied roles will be shown in the innocent color
- *onlyShowEnemies* - Whether to only highlight players whose roles are explicitly enemies of the local player. If this is `true` then allies will not be highlighted. If both this and *showJesters* are `true` then neither allies nor jesters will be highlighted

**RegisterRole(roleTable)** - Registers a role with Custom Roles for TTT. See [here](CREATE_YOUR_OWN_ROLE.md) for instructions on how to create a role and role table structure.\
*Realm:* Client and Server\
*Added in:* 1.0.9

**SetRoleHealth(ply)** - Sets the target player's health and max health based on their role convars.\
*Realm:* Client and Server\
*Added in:* 1.0.3\
*Parameters:*
- *ply* - The target player

**SetRoleMaxHealth(ply)** - Sets the target player's max health based on their role convars.\
*Realm:* Client and Server\
*Added in:* 1.0.15\
*Parameters:*
- *ply* - The target player

**SetRoleStartingHealth(ply)** - Sets the target player's health based on their role convars.\
*Realm:* Client and Server\
*Added in:* 1.0.15\
*Parameters:*
- *ply* - The target player

**ShouldPromoteDetectiveLike()** - Whether an unpromoted detective-like player (deputy/impersonator) should be promoted.\
*Realm:* Server\
*Added in:* 1.2.5

**StartsWithVowel(str)** - Whether the given string starts with a vowel.\
*Realm:* Client and Server\
*Added in:* 1.0.8

**UpdateRoleColours()/UpdateRoleColors()** - Updates the role color tables based on the color convars and color type convar.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**UpdateRoleStrings()** - Updates the role string tables based on the role name convars.\
*Realm:* Client and Server\
*Added in:* 1.0.7

**UpdateRoleWeaponState()** - Enables and disables weapons based on which roles are enabled.\
*Realm:* Client and Server\
*Added in:* 1.0.5

**UpdateRoleState()** - Updates the team membership, colors, and weapon state based on which roles are enabled and belong to which teams.\
*Realm:* Client and Server\
*Added in:* 1.0.0