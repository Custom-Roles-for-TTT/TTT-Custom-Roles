# Entity Object Methods
Methods available when called from an Entity object (within the defined realm)

### entmeta:ClearProperty(name, targets)
Clears the value of the property with the given `name` on this entity then synchronizes the clear to all `targets`. Wrapper around [SYNC:ClearEntityProperty](METHODS_SYNC.md#syncclearentitypropertyent-propertyname-targets).\
*Realm:* Server\
*Added in:* 2.3.2\
*Parameters:*
- *name* - The name of the property being cleared.
- *targets* - The targets that should have this value cleared on their clients. *(Defaults to sending to all players)*

### entmeta:SetProperty(name, value, targets)
Sets the value of the property with the given `name` on this entity to equal `value` and then synchronizes that value to all `targets`. Wrapper around [SYNC:SetEntityProperty](METHODS_SYNC.md#syncsetentitypropertyent-propertyname-propertyvalue-targets).\
*Realm:* Server\
*Added in:* 2.3.2\
*Parameters:*
- *name* - The name of the property being set.
- *value* - The value the property is being set to.
- *targets* - The targets that should have this value available on their clients. *(Defaults to sending to all players)*