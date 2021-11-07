## Player Static Methods
Methods available having to do with players but without needing a specific Player object

**player.AreTeamsLiving(ignorePassiveWinners)** - Returns whether the there are members of the various teams left alive.\
*Realm:* Client and Server\
*Added in:* 1.2.7\
*Parameters:*
- *ignorePassiveWinners* - Whether to ignore roles who win passively (like the old man) *(Added in 1.3.1)*

*Returns:*
- *traitor_alive* - Whether there are members of the traitor team left alive
- *innocent_alive* - Whether there are members of the innocent team left alive
- *indep_alive* - Whether there are members of the independent team left alive
- *monster_alive* - Whether there are members of the monster team left alive
- *jester_alive* - Whether there are members of the jester team left alive

**player.ExecuteAgainstTeamPlayers(roleTeam, detectivesAreInnocent, aliveOnly, callback)** - Executes a callback function against the players that are members of the specified "role team" (see ROLE_TEAM_* global enumeration).\
*Realm:* Client and Server\
*Added in:* 1.3.1\
*Parameters:*
- *roleTeam* - The "role team" whose members to execute the callback against (see ROLE_TEAM_* global enumeration)
- *detectivesAreInnocent* - Whether to include members of the detective "role team" in the innocent "role team" to match the logical teams
- *aliveOnly* - Whether to only include alive players
- *callback* - The function to execute against each "role team" player. Takes a player as the single argument

**player.GetLivingRole(role)** - Returns a single player that is alive and belongs to the given role (or `nil` if none exist). Useful when trying to get the player belonging to a role that can only occur once in a round.\
*Realm:* Client and Server\
*Added in:* 1.2.7\
*Parameters:*
- *role* - The desired role ID of the alive player to be found

**player.GetRoleTeam(role, detectivesAreInnocent)** - Gets which "role team" a role belongs to (see ROLE_TEAM_* global enumeration).\
*Realm:* Client and Server\
*Added in:* 1.2.7\
*Parameters:*
- *role* - The role ID in question
- *detectivesAreInnocent* - Whether to include members of the detective "role team" in the innocent "role team" to match the logical teams

**player.GetTeamPlayers(roleTeam, detectivesAreInnocent, aliveOnly)** - Returns a table containing the players that are members of the specified "role team" (see ROLE_TEAM_* global enumeration).\
*Realm:* Client and Server\
*Added in:* 1.3.1\
*Parameters:*
- *roleTeam* - The "role team" to find the members of (see ROLE_TEAM_* global enumeration)
- *detectivesAreInnocent* - Whether to include members of the detective "role team" in the innocent "role team" to match the logical teams
- *aliveOnly* - Whether to only include alive players

**player.IsRoleLiving(role)** - Returns whether a player belonging to the given role exists and is alive.\
*Realm:* Client and Server\
*Added in:* 1.2.7\
*Parameters:*
- *role* - The role ID in question

**player.LivingCount(ignorePassiveWinners)** - Returns the number of players left alive.\
*Realm:* Client and Server\
*Added in:* 1.3.1\
*Parameters:*
- *ignorePassiveWinners* - Whether to ignore roles who win passively (like the old man)

**player.TeamLivingCount(ignorePassiveWinners)** - Returns the number of members of the various teams left alive.\
*Realm:* Client and Server\
*Added in:* 1.3.1\
*Parameters:*
- *ignorePassiveWinners* - Whether to ignore roles who win passively (like the old man)

*Returns:*
- *traitor_alive* - The number of members of the traitor team left alive
- *innocent_alive* - The number of members of the innocent team left alive
- *indep_alive* - The number of members of the independent team left alive
- *monster_alive* - The number of members of the monster team left alive
- *jester_alive* - The number of members of the jester team left alive