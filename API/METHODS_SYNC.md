# SYNC Methods
Methods used for synchronizing data between the server and specific clients without relying on built-in systems that continuously send traffic even when there are no changes (NWVars) or only send data to players within the target's PVS (NW2Vars).

*NOTE*: These values are synchronized at the exact moment the method is called and that is it. They are *not* sent to new players upon joining the game.

### SYNC:SetPlayerProperty(ply, propertyName, propertyValue, targets)
Sets the value of the property with the given `propertyName` on `ply` to equal `propertyValue` and then synchronizes that value to all `targets`.\
*Realm:* Server\
*Added in:* 2.1.18\
*Parameters:*
- *ply* - The player whose property value is being set.
- *propertyName* - The name of the property being set.
- *propertyValue* - The value the property is being set to.
- *targets* - The targets that should have this value available on their clients. *(Defaults to sending to all players)*

### SYNC:ClearPlayerProperty(ply, propertyName, targets)
Clears the value of the property with the given `propertyName` on `ply` then synchronizes the clear to all `targets`.\
*Realm:* Server\
*Added in:* 2.1.18\
*Parameters:*
- *ply* - The player whose property value is being cleared.
- *propertyName* - The name of the property being cleared.
- *targets* - The targets that should have this value cleared on their clients. *(Defaults to sending to all players)*

### SYNC:SetEntityProperty(ent, propertyName, propertyValue, targets)
Sets the value of the property with the given `propertyName` on `ent` to equal `propertyValue` and then synchronizes that value to all `targets`.\
*Realm:* Server\
*Added in:* 2.3.2\
*Parameters:*
- *ent* - The entity whose property value is being set.
- *propertyName* - The name of the property being set.
- *propertyValue* - The value the property is being set to.
- *targets* - The targets that should have this value available on their clients. *(Defaults to sending to all players)*

### SYNC:ClearEntityProperty(ent, propertyName, targets)
Clears the value of the property with the given `propertyName` on `ent` then synchronizes the clear to all `targets`.\
*Realm:* Server\
*Added in:* 2.3.2\
*Parameters:*
- *ent* - The entity whose property value is being cleared.
- *propertyName* - The name of the property being cleared.
- *targets* - The targets that should have this value cleared on their clients. *(Defaults to sending to all players)*