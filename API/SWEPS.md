## SWEPs
Changes made to SWEPs (the data structure used when defining new weapons)

**SWEP.BlockShopRandomization** - Whether this weapon should block the shop randomization logic. Setting this to `true` will ensure this SWEP *always* shows in the applicable role's shop.\
*Added in:* 1.0.7

**SWEP.Category** - Updated so role weapons added by Custom Roles for TTT have a fixed global value: `WEAPON_CATEGORY_ROLE`. This is used to easily identify which weapons belong to specific roles.\
*Added in:* 1.0.5

**SWEP.EquipMenuData** - Updated so `name`, `type`, and `desc` properties can be parameterless functions to allow for parameterized translation.\
*Added in:* 1.0.8

**SWEP.ShopName** - The weapon name to use in the shop menu. If not provided, `SWEP.PrintName` is used instead.\
*Added in:* 1.1.9