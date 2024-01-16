# WEPS Methods
Methods used to manage and manipulate weapons.

### WEPS.ClearRetryTimers()
Clears the outstanding weapon purchase and loadout failure retry timers.\
*Realm:* Server\
*Added in:* 1.8.2

### WEPS.ClearWeaponsLists()
Clears the weapon lists used by the roleweapons system.\
*Realm:* Client and Server\
*Added in:* 1.9.4

### WEPS.DisguiseToggle(ply)
Toggle's the player's disguise, if they have one.\
*NOTE:* This method was not added by Custom Roles for TTT, but was modified to allow any player with the disguise equipment to use this functionality. In unmodified TTT, this method is restricted to traitors only.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *ply* - The player whose disguise is being toggled

### WEPS.DoesRoleHaveWeapon(role, promoted)
Checks whether the role has weapons or equipment available in their shop.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *role* - The role being checked for shop weapons and equipment
- *promoted* - Whether the role has been promoted. Determines whether `ROLE_DETECTIVE` weapons and equipment should also be checked *(Added in 1.3.6)*

### WEPS.HandleCanBuyOverrides(wep, role, block_randomization, sync_traitor_weapons, sync_detective_weapons, block_exclusion, sync_roles)
Updates the `CanBuy` property of the given weapon to only include weapons that the provided role is allowed to purchase based on all of the parameters.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *wep* - The weapon whose `CanBuy` property is being updated
- *role* - The role who purchase ability is being determined
- *block_randomization* - Whether to block shop randomization for this weapon
- *sync_traitor_weapons* - Whether the given role should also be able to buy all items that the traitor role can buy
- *sync_detective_weapons* - Whether the given role should also be able to buy all items that the detective role can buy
- *block_exclusion* - Whether to ignore the fact that this weapon would normally be excluded for this role *(Added in 1.2.7)*
- *sync_roles* - The list of roles that should also be checked when determining if this role can purchase this weapon *(Added in 1.9.5)*

### WEPS.HandleRoleEquipment()
Handles loading the roleweapons configuration from the server data files.\
*Realm:* Server\
*Added in:* 1.8.8

### WEPS.PlayerOwnsWepReqs(ply, wep)
Checks whether the player has the required weapons or equipment for `wep`.\
*Realm:* Client and Server\
*Added in:* 2.0.4\
*Parameters:*
- *ply* - The player whose weapon requirements are being checked
- *wep* - The weapon or equipment whose requirements are being checked

### WEPS.PrepWeaponsLists(role)
Prepares the roleweapons lists for the provided role.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *role* - The role whose roleweapons lists are being prepared

### WEPS.ResetRoleWeaponCache()
Resets the cache of the role weapon overrides.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### WEPS.ResetWeaponsCache()
Resets the cache of the role weapon overrides and resets all changed weapon `CanBuy` properties back to their defaults.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### WEPS.UpdateWeaponLists(role, weapon, includeSelected, excludeSelected, noRandomSelected)
Updates the roleweapons lists for the provided role and weapon.\
*Realm:* Client and Server\
*Added in:* 1.9.4\
*Parameters:*
- *role* - The role whole roleweapons lists are being updated
- *weapon* - The weapon being added or removed from the various lists
- *includeSelected* - Whether the "include" option is selected. Determines whether the given `weapon` should be in the [WEPS.BuyableWeapons](WEPS.md#wepsbuyableweapons) list
- *excludeSelected* - Whether the "include" option is selected. Determines whether the given `weapon` should be in the [WEPS.ExcludeWeapons](WEPS.md#wepsexcludeweapons) list
- *noRandomSelected* - Whether the "include" option is selected. Determines whether the given `weapon` should be in the [WEPS.BypassRandomWeapons](WEPS.md#wepsbypassrandomweapons) list