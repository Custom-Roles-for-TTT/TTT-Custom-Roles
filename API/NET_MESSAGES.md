# Net Messages
Messages that the Custom Roles for TTT addon is set up to listen to in the defined realm.

### TTT_ResetBuyableWeaponsCache
Resets the client's buyable weapons cache. This should be called if a weapon's CanBuy list has been updated.\
*Realm:* Client\
*Added in:* 1.0.0

### TTT_PlayerFootstep
Adds a footstep to the list's list of footsteps to show.\
*Realm:* Client\
*Added in:* 1.0.0\
*Parameters:*
- *Player* - The player whose footsteps are being recorded *(Changed from Entity to Player in 2.1.10)*
- *Vector* - The position to place the footsteps at
- *Angle* - The angle to place the footsteps with
- *Bit* - Which foot's step is currently being recorded (0 = Left, 1 = Right)
- *Table* - The R, G, and B values of the color for the placed footstep
- *UInt(8)* - The amount of time (in seconds) before the footsteps should fade completely from view
- *Float* - The size scale ot use for the footsteps. *(Added in 2.0.6)*

### TTT_ClearPlayerFootsteps
Resets the client's list of footsteps to show.\
*Realm:* Client\
*Added in:* 1.0.0

### TTT_RoleChanged
Logs that a player's role has changed.\
*Realm:* Client\
*Added in:* 1.0.0\
*Parameters:*
- *String* - The player's SteamID64 value
- *UInt(8) (Versions <= 1.1.1), Int(8) (Versions >= 1.1.2)* - The player's new role number. *(NOTE: Starting in 2.3.3, the number of bits this uses dynamically increases from 8 based on how many role are registered. Use [util.RoleBits](./METHODS_UTIL.md#utilrolebits) to determine the correct value to use.)*

### TTT_UpdateRoleNames
Causes the client to update their local role name tables based on convar values.\
*Realm:* Client\
*Added in:* 1.0.7
