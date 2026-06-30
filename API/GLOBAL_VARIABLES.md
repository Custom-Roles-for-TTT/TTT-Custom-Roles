# Global Variables
Variables available globally (within the defined realm)

### CAN_LOOT_CREDITS_ROLES
Lookup table for whether a role can loot credits off of a corpse.\
*Realm:* Client and Server\
*Added in:* 1.0.5

### COLOR_INNOCENT
Table of the default colors to use for the innocent role for each color type.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### COLOR_SPECIAL_INNOCENT
Table of the default colors to use for the special innocent roles for each color type.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### COLOR_TRAITOR
Table of the default colors to use for the traitor role for each color type.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### COLOR_SPECIAL_TRAITOR
Table of the default colors to use for the special traitor roles for each color type.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### COLOR_DETECTIVE
Table of the default colors to use for the detective role for each color type.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### COLOR_JESTER
Table of the default colors to use for the jester roles for each color type.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### COLOR_INDEPENDENT
Table of the default colors to use for the independent roles for each color type.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### COLOR_MONSTER
Table of the default colors to use for the monster team for each color type.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### CORPSE_ICON_TYPES
Table of the types of icons shown in the corpse search dialog.\
*Realm:* Client and Server\
*Added in:* 1.5.2

### CR_VERSION
The current version number for Custom Roles for TTT.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### DEFAULT_ROLES
Lookup table for whether a role is a default TTT role.\
*Realm:* Client and Server\
*Added in:* 1.0.3

### DELAYED_SHOP_ROLES
Lookup table for the roles whose shop purchases can be delayed.\
*Realm:* Client and Server\
*Added in:* 1.2.2

### DETECTIVE_ROLES
Lookup table for whether a role is a detective or special detective role.\
*Realm:* Client and Server\
*Added in:* 1.1.3

### DETECTIVE_LIKE_ROLES
Lookup table for whether a role is a detective-like role.\
*Realm:* Client and Server\
*Added in:* 1.9.9

### EVENT_MAX
The maximum event identifier.\
*Realm:* Client and Server\
*Added in:* 1.2.5

### EVENTS_BY_ROLE
Table of event IDs for each role. If a role has multiple events, the value in this table will be a table of all event IDs for the role.\
*Realm:* Client and Server\
*Added in:* 1.4.2

### INDEPENDENT_ROLES
Lookup table for whether a role is on the independent team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### INNOCENT_ROLES
Lookup table for whether a role is on the innocent team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### JESTER_ROLES
Lookup table for whether a role is on the jester team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### MONSTER_ROLES
Lookup table for whether a role is on the monster team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### ROLE_DATA_EXTERNAL
Table of definition data for each external role.\
*Realm:* Client and Server\
*Added in:* 1.4.9

### ROLE_EXTERNAL_START
The role number where the externally-loaded roles start.\
*Realm:* Client and Server\
*Added in:* 1.0.10

### ROLE_HOOK_REGISTRATION_KEY  
Table of role to key for use with the Hook Management system. Used when multiple roles share the same set of hooks (e.g. the Twins).\
*Realm*: Client and Server\
*Added in*: 2.4.6 

### ROLE_NONE
Updated to be -1 so players who have not been given a role can be identified.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### ROLE_MAX
The maximum role number.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### ROLE_PACK_DETAILS
Table of extra role pack details (e.g. display name and description) for the currently enabled role pack.\
*Realm:* Client and Server\
*Added in:* 2.4.2

### ROLE_PACK_ROLES
Mapping of which roles are in the currently enabled role pack.\
*Realm:* Client and Server\
*Added in:* 2.0.7

### ROLE_REGISTERED_HOOKS  
Mapping of role to table of registered hooks. Used by automated Hook Management system.\
The inner table is a mapping of hook names to hook handler functions or a table of identifier-handler functions. For example:
```lua
local function MyRole_EntityTakeDamage(ent, dmginfo)
    if ent:IsMyRole() then
        print("MyRole did damage!")
    end
end
local function MyRole_TTTEndRound()
    print("Round ended for MyRole!")
end
local function MyRole_Congrats_TTTEndRound()
    print("Congrats to the winners from MyRole!")
end

ROLE_REGISTERED_HOOKS[ROLE_MYROLE] = {
    ["EntityTakeDamage"] = MyRole_EntityTakeDamage,
    ["TTTEndRound"] = {
        ["MyRole_TTTEndRound"] = MyRole_TTTEndRound,
        ["MyRole_Congrats_TTTEndRound"] = MyRole_Congrats_TTTEndRound
    }
}
```
*Realm*: Client and Server\
*Added in*: 2.4.6 

### ROLE_SCORE_ICON_MATERIALS
Table of cached [Materials](https://wiki.facepunch.com/gmod/IMaterial) representing the `score` icons for each role by their role short string.\
*Realm:* Client and Server\
*Added in:* 1.6.3

### ROLE_STRINGS
Table of title-case names for each role.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### ROLE_STRINGS_DEFAULT
Table of title-case names for each role. Copy of `ROLE_STRINGS` from before role strings are changed by ConVars.\
*Realm:* Client and Server\
*Added in:* 2.4.4

### ROLE_STRINGS_EXT
Table of extended (e.g. prefixed by an article) names for each role.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### ROLE_STRINGS_PLURAL
Table of pluralized names for each role.\
*Realm:* Client and Server\
*Added in:* 1.0.7

### ROLE_STRINGS_RAW
Table of raw names for each role (used in convars).\
*Realm:* Client and Server\
*Added in:* 1.0.7

### ROLE_STRINGS_SHORT
Table of short names for each role (used in icon names).\
*Realm:* Client and Server\
*Added in:* 1.0.0

### ROLE_TAB_ICON_MATERIALS
Table of cached [Materials](https://wiki.facepunch.com/gmod/IMaterial) representing the `tab` (16x16) icons for each role by their role short string.\
*Realm:* Client and Server\
*Added in:* 1.6.3

### ROLE_TEAMS_WITH_SHOP
The lookup table of which *ROLE_TEAM_* enumeration values normally have a shop.\
*Realm:* Client and Server\
*Added in:* 1.5.8

### SHOP_ROLES
Lookup table for whether a role has a shop.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### TRAITOR_BUTTON_ROLES
Lookup table for whether a role can use traitor buttons.\
*Realm:* Client and Server\
*Added in:* 1.0.5

### TRAITOR_ROLES
Lookup table for whether a role is on the traitor team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### WIN_MAX
The maximum win state identifier.\
*Realm:* Client and Server\
*Added in:* 1.2.5

### WINS_BY_ROLE
Table of win IDs for each role.\
*Realm:* Client and Server\
*Added in:* 1.4.2