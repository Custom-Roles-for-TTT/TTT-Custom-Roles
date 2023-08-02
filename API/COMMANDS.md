# Commands

## *Client Commands*

### ttt_reset_weapons_cache
Resets the client's equipment cache used in shop display. Useful when debugging changed shop rules.\
*Added in*: 1.0.11

### ttt_roleweapons
Allows for viewing and editing which weapons are available in each role's shop.\
*Added in*: 1.2.7\
*Parameters:*
- *command* - Which command should be run *(Added in 1.9.4)*
  - *open (aka show)* - Opens the configuration UI. See [this tutorial](../CONVARS.md#Configuration-by-UI) for how to use the UI. (This command is the default if no parameter is provided)
  - *list (aka print)* - Prints the current configuration in the server console, highlighting anything invalid
  - *clean* - Removes any invalid configurations. WARNING: This CANNOT be undone!
  - *reload* - Reloads the configurations from the server's filesystem

## *Server Commands*

### sv_ttt_roleweapons
Allows for viewing and editing which weapons are available in each role's shop. Server-side version of [ttt_roleweapons](COMMANDS.md#ttt_roleweapons).\
*Added in*: 1.9.4\
*Parameters:*
- *command* - Which command should be run
  - *list (aka print)* - Prints the current configuration in the console, highlighting anything invalid
  - *clean* - Removes any invalid configurations. WARNING: This CANNOT be undone!
  - *reload* - Reloads the configurations from the filesystem

### ttt_damage_from_random
Damages the local player by a random non-jester team player. *NOTE*: Cheats must be enabled to use this command.\
*Added in:* 1.3.7\
*Parameters:*
- *damage* - How much damage to do to the local player (Defaults to 1)
- *allow_dead* - Whether to allow the randomly selected player to be dead (Defaults to `false`) *(Added in 1.9.0)*

### ttt_damage_from_player
Damages the local player by another player with the given name. *NOTE*: Cheats must be enabled to use this command.\
*Added in:* 1.3.7\
*Parameters:*
- *killer_name* - The name of the player who will kill the local player
- *damage* - How much damage to do to the local player (Defaults to 1)
- *allow_dead* - Whether to allow the specified player to be dead (Defaults to `false`) *(Added in 1.9.0)*

### ttt_damage_target_from_random
Damages the target player by a random non-jester team player. *NOTE*: Cheats must be enabled to use this command.\
*Added in:* 1.3.7\
*Parameters:*
- *target_name* - The name of the player who will be killed
- *damage* - How much damage to do to the target (Defaults to 1)
- *allow_dead* - Whether to allow the randomly selected player to be dead (Defaults to `false`) *(Added in 1.9.0)*

### ttt_damage_target_from_player
Damages the target player by another player with the given name. *NOTE*: Cheats must be enabled to use this command.\
*Added in:* 1.3.7\
*Parameters:*
- *target_name* - The name of the player who will be killed
- *killer_name* - The name of the player who will kill the target player
- *damage* - How much damage to do to the target (Defaults to 1)
- *allow_dead* - Whether to allow the specified player to be dead (Defaults to `false`) *(Added in 1.9.0)*

### ttt_kill_from_random
Kills the local player by a random non-jester team player. *NOTE*: Cheats must be enabled to use this command.\
*Added in:* 1.0.0\
*Parameters:*
- *remove_body* - Whether to remove the local player's body after killing them (Defaults to `false`)
- *allow_dead* - Whether to allow the randomly selected player to be dead (Defaults to `false`) *(Added in 1.9.0)*

### ttt_kill_from_player
Kills the local player by another player with the given name. *NOTE*: Cheats must be enabled to use this command.\
*Added in:* 1.0.0\
*Parameters:*
- *killer_name* - The name of the player who will kill the local player
- *remove_body* - Whether to remove the local player's body after killing them (Defaults to `false`)
- *allow_dead* - Whether to allow the specified player to be dead (Defaults to `false`) *(Added in 1.9.0)*

### ttt_kill_target_from_random
Kills the target player by a random non-jester team player. *NOTE*: Cheats must be enabled to use this command.\
*Added in:* 1.0.0\
*Parameters:*
- *target_name* - The name of the player who will be killed
- *remove_body* - Whether to remove the target player's body after killing them (Defaults to `false`)
- *allow_dead* - Whether to allow the randomly selected player to be dead (Defaults to `false`) *(Added in 1.9.0)*

### ttt_kill_target_from_player
Kills the target player by another player with the given name. *NOTE*: Cheats must be enabled to use this command.\
*Added in:* 1.0.0\
*Parameters:*
- *target_name* - The name of the player who will be killed
- *killer_name* - The name of the player who will kill the target player
- *remove_body* - Whether to remove the target player's body after killing them (Defaults to `false`)
- *allow_dead* - Whether to allow the specified player to be dead (Defaults to `false`) *(Added in 1.9.0)*

### ttt_order_for_someone
Orders a shop item on behalf of a another player with the given name. *NOTE*: Cheats must be enabled to use this command.\
*Added in:* 1.0.0\
*Parameters:*
- *target_name* - The name of the player who will be killed
- *order* - The weapon class string or equipment ID number to be ordered
