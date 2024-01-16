# Global Enumerations
Enumerations available globally (within the defined realm). There are additional enumerations used internally for configuration and event reporting that are not included here. If you need them, for whatever reason, you will need to find them or ask one of the developers in Discord.

### ROLE_{ROLENAME}
Every role that is added has its role number available as a global enum value. In addition, `ROLE_MAX` is defined as the highest role number assigned, `ROLE_NONE` is the role number a player is given before another role is assigned, and `ROLE_EXTERNAL_START` is the first role number assigned to roles defined outside of the code Custom Roles for TTT addon.\
*Realm:* Client and Server\
*Added in:* Whenever each role is added

### ROLE_CONVAR_TYPE_
What type the convar for an external role is. Used by the ULX plugin to dynamically generate the configuration UI.\
*Realm:* Client and Server\
*Added in:* 1.0.11\
*Values:*
- ROLE_CONVAR_TYPE_NUM - A number. Will use a slider in the configuration UI.
- ROLE_CONVAR_TYPE_BOOL - A boolean. Will use a checkbox in the configuration UI.
- ROLE_CONVAR_TYPE_TEXT - A text value. Will use a text box in the configuration UI.
- ROLE_CONVAR_TYPE_DROPDOWN - A dropdown value. Will use a dropdown in the configuration UI. *(Added in 2.0.2)*

### ROLE_TEAM_
Which role team an external role is registered to. A "role team" is a way of grouping roles by common functionality and mostly maps to the logical team with the exception of the detective role team. The detective role team is part of the innocent logical team.\
*Realm:* Client and Server\
*Added in:* 1.0.9\
*Values:*
- ROLE_TEAM_INNOCENT
- ROLE_TEAM_TRAITOR
- ROLE_TEAM_JESTER
- ROLE_TEAM_INDEPENDENT
- ROLE_TEAM_MONSTER *(Added in 1.1.7)*
- ROLE_TEAM_DETECTIVE *(Added in 1.1.3)*

### SHOP_SYNC_MODE_
What mode to use when synchronizing shop weapons and equipment between the traitor and/or detective shop and a target role.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Values:*
- SHOP_SYNC_MODE_NONE - No additional weapons or equipment will be added to the target role's shop
- SHOP_SYNC_MODE_UNION - All weapons available to EITHER the traitor or the detective
- SHOP_SYNC_MODE_INTERSECT - Only weapons available to BOTH the traitor and the detective
- SHOP_SYNC_MODE_DETECTIVE - All weapons available to the detective
- SHOP_SYNC_MODE_TRAITOR - All weapons available to the traitor