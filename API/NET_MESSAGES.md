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
- *Entity* - The player whose footsteps are being recorded
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
- *UInt (Versions <= 1.1.1), Int (Versions >= 1.1.2)* - The player's new role number

### TTT_UpdateRoleNames
Causes the client to update their local role name tables based on convar values.\
*Realm:* Client\
*Added in:* 1.0.7
