# Creating Your Own Custom Roles for TTT Role

## Table of Contents
1. [Before You Start](#Before-You-Start)
1. [Code](#Code)
   1. [Role Table](#Role-Table)
   1. [Role Strings](#Role-Strings)
   1. [Description](#Description)
   1. [Team](#Team)
   1. [Shop and Loadout Items](#Shop-and-Loadout-Items)
      1. [Weapon](#Weapon)
      1. [Equipment](#Equipment)
   1. [Credits](#Credits)
   1. [Health](#Health)
   1. [Role Activation](#Role-Activation)
   1. [Acting Like a Jester](#Acting-Like-a-Jester)
   1. [Translations](#Translations)
   1. [Optional Rules](#Optional-Rules)
   1. [ConVars](#ConVars)
   1. [Custom Win Conditions](#Custom-Win-Conditions)
      1. [Win Identifier](#Win-Identifier)
      1. [Win Condition](#Win-Condition)
      1. [Round Summary Screen](#Round-Summary-Screen)
      1. [Round Result Message](#Round-Result-Message)
      1. [Full Win Condition Example](#Full-Win-Condition-Example)
   1. [Role Registration](#Role-Registration)
   1. [Final Block](#Final-Block)
   1. [Example File](#Example-File)
1. [Sprites](#Sprites)
   1. [Finding a Role Icon](#Finding-a-Role-Icon)
   1. [Tab File](#Tab-File)
   1. [Score File](#Score-File)
   1. [Sprite File](#Sprite-File)
   1. [Icon File](#Icon-File)
   1. [.vmt Files](#vmt-Files)
1. [Uploading Your Addon](#Uploading-Your-Addon)
   1. [addon.json](#addonjson)
   1. [Workshop Icon](#Workshop-Icon)
   1. [Folder Name](#Folder-Name)
   1. [Final Checks](#Final-Checks)
   1. [Uploading](#Uploading)
1. [Wrapping Up](#Wrapping-Up)

## Before You Start
In order to create your own role you will need to make sure you have downloaded tools to edit the following file types:

- **.psd** - For this guide we will be using Photoshop but [GIMP](https://www.gimp.org/) is a great free alternative.
- **.lua** - This can be done in Notepad in a pinch but at the very least we would recommend [Notepad++](https://notepad-plus-plus.org/).
- **.vmt and .vtf** - [VTFEdit](https://nemstools.github.io/pages/VTFLib-Download.html) is the best way to edit these files but if you know what you are doing there are plugins for other apps.

In this guide we will be walking through how we made the Summoner role and you can download all the templates we are using [here](/templates).

Last thing to do before you are ready to get started is to unzip that file which should give you 4 .psd files and a folder like this:

![TemplateContents.png](https://i.imgur.com/UCyxklx.png)

## Code

Open up 'Role Addon Template' > 'lua' > 'customroles' and rename '%NAMERAW%.lua' to whatever you want the name of your role to be. In this case we will rename it to 'summoner.lua'.

Open up that file and you should see something like this:

```lua
local ROLE = {}

ROLE.nameraw = ""
ROLE.name = ""
ROLE.nameplural = ""
ROLE.nameext = ""
ROLE.nameshort = ""

ROLE.desc = [[]]

ROLE.team = 

ROLE.shop = nil
ROLE.loadout = {}

ROLE.startingcredits = nil

ROLE.startinghealth = nil
ROLE.maxhealth = nil

ROLE.isactive = nil
ROLE.shouldactlikejester = nil

ROLE.translations = {}

ROLE.convars = {}

RegisterRole(ROLE)

if SERVER then  
    AddCSLuaFile()
end
```

Lets break that down piece by piece.

### Role Table

First we have this line here:

```lua
local ROLE = {}
```

You don't need to touch this line. The ROLE table will store everything CR for TTT needs to understand your role.

### Role Strings

The next chunk here is all about the name of your role:

```lua
ROLE.nameraw = ""  
ROLE.name = ""  
ROLE.nameplural = ""  
ROLE.nameext = ""  
ROLE.nameshort = ""
```

`nameraw` is used to create all the necessary ConVars for your role. It should only contain lowercase characters a-z, without spaces or punctuation.

`name`, `nameplural` and `nameext` are all about how your role is presented to the user. `name` is the title case name of your role. `nameplural` is the title case name for the plural of your role. `nameext` is the title case name for your role with this associated indefinite article. (i.e. a or an)

`nameshort` is used for sprites and other files relevant to your role. It should be 3 characters long and only contain lowercase characters a-z, without spaces or punctuation. Try to make this unique to your role and not just a generic string of characters to avoid clashes with other roles.

For the Summoner that block of code will now look like this.

```lua
ROLE.nameraw = "summoner"  
ROLE.name = "Summoner"  
ROLE.nameplural = "Summoners"  
ROLE.nameext = "a Summoner"  
ROLE.nameshort = "sum"
```

### Description

The next line cares about the description of your role that shows up at the start of the round. Lua uses double square brackets for multi-line strings so you don't need quotes or newline characters here, plaintext should do the trick.

There are a few strings here that can be used within curly brackets which are replaced with role names or other information that isn't constant. Below is a table of replacement strings you might find useful.

| Replacement String | Description | Example |
| --- | --- | --- |
| `{role}` | The name of your role | Summoner |
| `{innocent}` | The name of the Innocent role | Innocent |
| `{innocents}` | The plural form of the Innocent role | Innocents |
| `{aninnocent}` | The name of the Innocent role with an article | an Innocent |
| `{traitor}` | The name of the Traitor role | Traitor |
| `{traitors}` | The plural form of the Traitor role | Traitors |
| `{atraitor}` | The name of the Traitor role with an article | a Traitor |
| `{detective}` | The name of the Detective role | Detective |
| `{detectives}` | The plural form of the Detective role | Detectives |
| `{adetective}` | The name of the Detective role with an article | a Detective |
| `{jester}` | The name of the Jester role | Jester |
| `{jesters}` | The plural form of the Jester role | Jesters |
| `{ajester}` | The name of the Jester role with an article | a Jester |
| `{comrades}` | Information about fellow traitors and glitches | These are your comrades: (includes a list of traitors) |
| `{menukey}` | The key bound to open the shop | C |

The description for the Summoner will look like this:

```lua
ROLE.desc = [[You are {role}! {comrades}  
  
Summon minions to help defeat your enemies.  
  
Press {menukey} to receive your special equipment!]]
```

### Team
Next we have the team. You can set which team your role is a member of by using the the following values

| Team | Value |
| --- | --- |
| Innocent | `ROLE_TEAM_INNOCENT` |
| Traitor | `ROLE_TEAM_TRAITOR` |
| Detective | `ROLE_TEAM_DETECTIVE` |
| Jester | `ROLE_TEAM_JESTER` |
| Independent | `ROLE_TEAM_INDEPENDENT` |
| Monster | `ROLE_TEAM_MONSTER` |

So for the Summoner, which is a traitor we have:

```lua
ROLE.team = ROLE_TEAM_TRAITOR
```

### Shop and Loadout Items

The next two lines are all about shop and loadout items:

```lua
ROLE.shop = nil
ROLE.loadout = {}
```

If you want your role to have access to a shop or if you want them to spawn with any items, this is where you can add that.

Traitors automatically have access to body armor, a radar and a disguiser in the shop. Detectives have access to a radar in the shop and spawn with body armor.

To give your role a shop, first change the shop property to read: `ROLE.shop = {}`. By default a role will not have a shop. If a role is given a shop, the `ttt_%NAMERAW%_shop_random_percent`, `ttt_%NAMERAW%_shop_random_enabled`, and (if applicable) `ttt_%NAMERAW%_shop_mode` or `ttt_%NAMERAW%_shop_sync` convars will be created automatically.

Inside the curly brackets for the shop or loadout add the class names of any other weapons or equipment you want, separated by commas. To find the class name of a weapon or equipment you can do the following:

#### Weapon:
1. Start a local server with TTT as the selected gamemode
2. Spawn 1 bot by using the _bot_ command in console
3. Obtain the weapon whose class you want. If it is already available to buy from a certain role's shop, either force yourself to be that role via the _ttt\_force\_*_ commands or via a ULX plugin.
4. Run the following command in console to get a list of all of your weapon classes: `lua_run PrintTable(player.GetHumans()[1]:GetWeapons())`

#### Equipment:
1. Start a local server with TTT as the selected gamemode
2. Spawn 1 bot by using the _bot_ command in console
3. Obtain the equipment item whose name you want. If it is already available to buy from a certain role's shop, either force yourself to be that role via the _ttt\_force\_*_ commands or via a ULX plugin.
4. Run the following command in console to get a full list of your equipment item names: `lua_run GetEquipmentItemById(EQUIP_RADAR); lua_run for id, e in pairs(EquipmentCache) do if player.GetHumans()[1]:HasEquipmentItem(id) then print(id .. " = " .. e.name) end end`

*(Note: Equipment items can only be added to the loadout table for roles in version 1.2.1 and above!)*

For the Summoner, we don't want any loadout items but we do want the shop to have access to a few different items so we can add them like this:

```lua
ROLE.shop = {"weapon_ttt_beenade", "weapon_ttt_barnacle", "surprisecombine", "weapon_antlionsummoner", "weapon_controllable_manhack", "weapon_doncombinesummoner"}  
ROLE.loadout = {}
```

### Credits

Now that you have a shop set up for you role, what about the credits to actually buy things? Well, if your role is `ROLE_TEAM_TRAITOR` or `ROLE_TEAM_DETECTIVE` then they will automatically have 1 starting credit. If they belong to another team or you want to change your role to have a different amount of starting credits than the default, you can use the `ROLE.startingcredits` property:

```lua
ROLE.startingcredits = nil
```

Whatever number you assign to this property will automatically be set as the default for the `ttt_%NAMERAW%_credits_starting` convar. This convar is automatically created for all roles that have credits. For the Summoner, let's have them start with 2 credits so they can use a couple different shop items in the same round:

```lua
ROLE.startingcredits = 2
```

### Health

The next couple of properties have to do with the health for your role:

```lua
ROLE.startinghealth = nil
ROLE.maxhealth = nil
```

If these aren't set the role will use *100* for the starting and maxmium health by default. Also, if you only set the `ROLE.startinghealth` property then the maximum health will match by default as well.

For the Summoner we want to keep it at the *100* default health, but for the sake of this example we're going to change the starting and maximum health so they start with *125* but have a maximum of *150*, allowing them to heal a little:

```lua
ROLE.startinghealth = 125
ROLE.maxhealth = 150
```

### Role Activation

Some roles may have special logic that changes how they behave after some activation event. For example, the Clown is activated when only one team remains and the effect of their activation is they can now do damage. If you want to be able to do something like that we recommend using the entity networked properties system (such as [SetNWBool](https://wiki.facepunch.com/gmod/Entity:SetNWBool)). When the role is activated you could `ply:SetNWBool("SummonerActive", true)` and then check that they are active in other places to change their behavior using `ply:GetNWBool("SummonerActive", false)`. To make this slightly nicer, we introduced the `ply:IsRoleActive()` method in v1.2.2 which is also used in delayed shop activation (see [Optional Rules](#Optional-Rules)).

The next line in our role definition has to do with tying into the `ply:IsRoleActive()` method, allowing you to define if your role is "active" on your own terms:

```lua
ROLE.isactive = nil
```

This property should be a function with a single parameter that takes a player object and returns a boolean. Continuing our example from the paragraph above, we should define this property like so:

```lua
ROLE.isactive = function(ply)
    return ply:GetNWBool("SummonerActive", false)
end
```

Once that is defined you can use `ply:IsRoleActive()` anywhere you need to check your role's activation state.

### Acting Like a Jester

The next part of the file will help you create a role that sometimes acts like a jester. The perfect example of this functionality is the clown role -- when they first spawn, they:
1. Cannot do damage
1. Don't take various forms of damage (fire, explosion, falling, etc.)
1. Appear as a jester to other roles (on the radar, scoreboard, icon over their head, etc.)

Once the role activates (in the case of the clown, this happens when there is only one team remaining) then they no longer act like a jester, allowing them to do damage and potentially win the round.

To make your role behave similarly, you need to define the following property:

```lua
ROLE.shouldactlikejester = nil
```

This property should be a function with a single parameter that takes a player object and returns a boolean. In the case of our example Summoner, we're going to have them to act like a jester until they are activated. To accomplish that, we define the property like this:

```lua
ROLE.shouldactlikejester = function(ply)
    return not ply:IsRoleActive()
end
```

Once that is defined you can use `ply:ShouldActLikeJester()` anywhere you need to check whether they should still act like a jester. Custom Roles for TTT will automatically use your defined function when doing damage calculations (damage taken and damage given) as well as role display in thinks like the radar and target ID (icon over the head, name and circle when looking at a player).

### Translations

Next there is a line that looks like this:

```lua
ROLE.translations = {}
```

This line allows you to define custom translations to be used elsewhere in your role. The `ROLE.translations` variable is a table that maps a language name to a list of key-value pairs where the `key` is the name of the translation and the `value` is the translated string in the desired language.

For example, if we wanted to add a custom translation for the `english` language, it would look something like this:

```lua
ROLE.translations = {
    ["english"] = {
        ["summoner_testtranslation"] = "This is in English"
    }
}
```

From here you can add additional entries for each language you want to add support for. The list of currently-supported languages is available on the [Facepunch Garry's Mod GitHub](https://github.com/Facepunch/garrysmod/tree/master/garrysmod/gamemodes/terrortown/gamemode/lang). For exmaple, if we wanted to add a Spanish version of our translation then it would look like this:

```lua
ROLE.translations = {
    ["english"] = {
        ["summoner_testtranslation"] = "This is in English"
    },
    ["español"] = {
        ["summoner_testtranslation"] = "Esto es en español"
    }
}
```

*(Note: At the very least there should be an english version of every translation you add. The english translation will be used as the default if a translation is not available in the client's chosen language)*

### Optional Rules

There are a few options for roles that aren't covered in the template because they don't apply to every role. Add any of these that you want to apply to your role to the file.

| Option | Description | Added in |
| --- | --- | --- |
| `ROLE.canlootcredits` | Whether this role can loot credits from dead bodies. Automatically enabled if the role has a shop, but setting to `false` can make it so the role has a shop but cannot loot credits. Setting this to `true` will allow this role to loot credits regardless of whether they have a shop and will automatically create the `ttt_%NAMERAW%_credits_starting` convar. | 1.1.8 |
| `ROLE.canusetraitorbuttons` | Whether this role can see and use traitor traps. Automatically enabled if the role is part of `ROLE_TEAM_TRAITOR`, but setting to `false` can make it so the role is a traitor that cannot use traitor traps. Setting to `true` will allow this role to use traitor traps regardless of their team association. | 1.1.8 |
| `ROLE.shoulddelayshop` | Whether this role's shop purchases are delayed. Purchases will only be given to the player when `plymeta:GiveDelayedShopItems` is called by your own role logic. Enabling this feature will automatically create `ttt_%NAMERAW%_shop_active_only` and `ttt_%NAMERAW%_shop_delay` convars. Requires that the role has a shop and has role activation defined (see [Role Activation](#Role-Activation)) | 1.2.2 |

The Summoner doesn't need these options to be set because it is `ROLE_TEAM_TRAITOR` and has a shop, but just for an example, here's what it would look like if we wanted to remove their credit looting and traitor trap abilities and delay their shop item delivery:

```lua
ROLE.canlootcredits = false
ROLE.canusetraitorbuttons = false
ROLE.shoulddelayshop = true
```

### ConVars

By default CR for TTT will handle and create some of the ConVars that are required for your role to function.
These ConVars all use the string you gave for `nameraw` in their definition. The following ConVars are all created by default:

```
ttt_%NAMERAW%_enabled (Used to enable or disable the role)
ttt_%NAMERAW%_spawn_weight (The weight assigned for spawning the role)
ttt_%NAMERAW%_min_players (The minimum number of player required to spawn the role)
ttt_%NAMERAW%_starting_health (The amount of health the role starts each round with)
ttt_%NAMERAW%_max_health (The maximum health of the role)
ttt_%NAMERAW%_name (Used to rename the role)
ttt_%NAMERAW%_name_plural (Used to rename the plural form of the role)
ttt_%NAMERAW%_name_article (Used to rename the indefinite article of the role)
```

These next convars are created only if the role has access to a shop:

```
ttt_%NAMERAW%_credits_starting (The number of credits the role spawns with)
ttt_%NAMERAW%_shop_random_enabled (Whether shop randomization is enabled for the role)
ttt_%NAMERAW%_shop_random_percent (The percent chance that each weapon in the roles shop will not be shown)
```

Finally, these convars are only created if the role has access to a shop AND is either a traitor, detective or independent role:

```
ttt_%NAMERAW%_shop_sync (Whether the role should have access to all traitor/detective shop items) [TRAITOR AND DETECTIVE ONLY]
ttt_%NAMERAW%_shop_mode (Whether the role should have access to traitor and/or detective shop items) [INDEPENDENT ONLY]
```

For more information on the specifics of these ConVars you can read the full list of ConVars [here](https://github.com/NoxxFlame/TTT-Custom-Roles/blob/master/CONVARS.md#server-configurations).

If you would like to add your own ConVars that aren't automatically created you can do so here. First create the ConVars as you would normally with `CreateConVar`. *(Note: Please try to keep your ConVars as consistently named as possible. The recommended naming scheme for role specific convars is `ttt_%NAMERAW%_...`.)*

Once you have defined your ConVar you can add it to the `convars` table to get it to show up inside ULX menus. Each entry in the `convars` table needs two properties. `cvar` is the name of the ConVar you want to add and `type` is one of three values depending on if you want your ConVar to show up as a slider, checkbox or textbox.

| Type | Value |
| --- | --- |
| Slider | `ROLE_CONVAR_TYPE_NUM` |
| Checkbox | `ROLE_CONVAR_TYPE_BOOL` |
| Textbox | `ROLE_CONVAR_TYPE_TEXT` |

If your ConVar is a number using a slider you can optionally add a third property `decimal` which determines how many decimal places of precision you want to give the user. *(Note: Max and min values for sliders are determined by the max and min values you specified when you defined the ConVar)*

The Summoner does not have any extra ConVars but for the sake of example we will add three useless ConVars.

```lua
if SERVER then
    CreateConVar("ttt_summoner_slider", "0", FCVAR_NONE, "This is a useless slider", 0, 10)
    CreateConVar("ttt_summoner_checkbox", "0")
    CreateConVar("ttt_summoner_textbox", "0")
end
ROLE.convars = {}
table.insert(ROLE.convars, {
    cvar = "ttt_summoner_slider",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE.convars, {
    cvar = "ttt_summoner_checkbox",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE.convars, {
    cvar = "ttt_summoner_textbox",
    type = ROLE_CONVAR_TYPE_TEXT
})
```

### Custom Win Conditions

One of the more complicated parts of creating a new role comes with creating a custom win condition. The good news is this is only required if you don't want to use one of the existing "Traitors Win!", "Innocents Win!", etc. messages. A good rule of thumb is if you are creating a role that is `ROLE_TEAM_JESTER` or `ROLE_TEAM_INDEPENDENT` then you would probably need to create a custom win condition as well.

To create a custom win condition, you will need to define a global unique win identifier and use three separate hooks.

#### Win Identifier

The identifier must be unique to make sure you can differentiate between your role's win and any other role's win. Starting in version 1.2.5, Custom Roles for TTT provides a method for generating a unique win identifier for you. If you want to ensure compatibility with Custom Roles for TTT prior to version 1.2.5 you shoud come up with your own unique number for your role.

The following code should be run on both the server and the client and will generate a new win condition identifier. It then saves the generated value to the global `WIN_SUMMONER` value to be used later:

```lua
hook.Add("Initialize", "SummonerInitialize", function()
    -- Use 245 if we're on Custom Roles for TTT earlier than version 1.2.5
    -- 245 is summation of the ASCII values for the characters "S", "U", and "M"
    WIN_SUMMONER = GenerateNewWinID and GenerateNewWinID() or 245
end)
```

Once we have our unique win condition identifier created it's time to write the code that uses it.

#### Win Condition

The first piece of code that will use our new win condition identifier is the code that determines if our role should win the round. To do that we have to hook the `TTTCheckForWin` method on the server side. For this hook it is important to only return a value if you want to have a specific result. For example, if you want to block the round from ending you return `WIN_NONE` and if you want your role to win then you return the win condition identifer we made above (in our example case: `WIN_SUMMONER`). If you return nothing then the default win condition logic will run as normal. See below for a template example of how to set up this hook:

```lua
if SERVER then
    hook.Add("TTTCheckForWin", "SummonerCheckForWin", function()
        local summonerWins = false
        --[[
            Insert logic to determine whether our role should win here
        ]]--

        if summonerWins then
            return WIN_SUMMONER
        end
    end)
end
```

We'll leave the actual logic to determine whether our role wins blank as an exercise for you to fill out on your own. Once our role can actually win we need to define two more hooks to let everyone know when that it happened.

#### Round Summary Screen

The first hook to show that our role won is the one for the round summary screen. This hook (which runs on the client side) allows you to return an object which describes the text to show when your win condition happens.

The first property of the object that the hook expects is `txt` which is the translation string for the text being shown. There are two default translation strings that are available specifically for this purpose. Choose whichever one makes sense for your role:

| Translation String | Text |
| --- | --- |
| hilite_win_role_singular | THE {role} WINS |
| hilite_win_role_plural | THE {role} WIN |

The second property is `params` which is another object with the values to use when replacing placeholders in the translation string. When using the translation strings above, the only placeholder is `role` so the only property inside the `params` object should be `role`. The value for this property should be the role string for your role in the correct singular or plural form depending on which translation string you used above. For example, if you used `hilite_win_role_singular` then `role` would be `ROLE_STRINGS[ROLE_SUMMONER]` but if you used `hilite_win_role_plural` then `role` would be `ROLE_STRINGS_PLURAL[ROLE_SUMMONER]`.

The final parameter of the returned object is `c`, representing the color to show in the background behind the winning text. In general you should use the role color for your role. In our case that would look like this: `ROLE_COLORS[ROLE_SUMMONER]`.

Putting all the properties together, the hook would look something like the following:

```lua
if CLIENT then
    hook.Add("TTTScoringWinTitle", "SummonerScoringWinTitle", function(wintype, wintitles, title, secondaryWinRole)
        if wintype == WIN_SUMMONER then
            return { txt = "hilite_win_role_singular", params = { role = ROLE_STRINGS[ROLE_SUMMONER] }, c = ROLE_COLORS[ROLE_SUMMONER] }
        end
    end)
end
```

#### Round Result Message

The final hook to set up our custom win condition is the one that displays the winning message in the top-right of the screen. It also prints the winning team to the server console, but that's not something the players will see. This hook is on the server side but requires a translation to be set up on the client side for the actual message to display.

The standard name we use for the translation string for this is the same as the win condition identifier global, but in all lowercase. In our example, that would be `win_summoner`. When we set up the translation we deliberately use a placeholder for the role name so that the role can be renamed dynamically. We then have to pass the role string for our role when we use the translation. The full example of the hook and the translation string setup can be seen below:

```lua
if SERVER then
    hook.Add("TTTPrintResultMessage", "SummonerPrintResultMessage", function(type)
        if type == WIN_SUMMONER then
            LANG.Msg("win_summoner", { role = ROLE_STRINGS[ROLE_SUMMONER] })
            ServerLog("Result: " .. ROLE_STRINGS[ROLE_SUMMONER] .. " wins.\n")
            return true
        end    
    end)
else
    LANG.AddToLanguage("english", "win_summoner", "The {role}'s minions have overwhelmed their enemies!")
end
```

The `LANG.Msg` call is the one that sends the message to each client and tells them to translate it. Below that, the `ServerLog` call writes a simpler message to the server console, just in case. Finally we `return true` from the hook to tell Custom Roles for TTT not to run the default logic for printing these messages since we've already handled it.

#### Full Win Condition Example

If we piece together all the bits of code from the preivous sections it would come out looking something like this:

```lua
    hook.Add("Initialize", "SummonerInitialize", function()
        -- Use 245 if we're on Custom Roles for TTT earlier than version 1.2.5
        -- 245 is summation of the ASCII values for the characters "S", "U", and "M"
        WIN_SUMMONER = GenerateNewWinID and GenerateNewWinID() or 245
    end)

    if SERVER then
        hook.Add("TTTCheckForWin", "SummonerCheckForWin", function()
            local summonerWins = false
            --[[
                Insert logic to determine whether our role should win here
            ]]--

            if summonerWins then
                return WIN_SUMMONER
            end
        end)

        hook.Add("TTTPrintResultMessage", "SummonerPrintResultMessage", function(type)
            if type == WIN_SUMMONER then
                LANG.Msg("win_summoner", { role = ROLE_STRINGS[ROLE_SUMMONER] })
                ServerLog("Result: " .. ROLE_STRINGS[ROLE_SUMMONER] .. " wins.\n")
                return true
            end
        end)
    else
        LANG.AddToLanguage("english", "win_summoner", "The {role}'s minions have overwhelmed their enemies!")

        hook.Add("TTTScoringWinTitle", "SummonerScoringWinTitle", function(wintype, wintitles, title, secondaryWinRole)
            if wintype == WIN_SUMMONER then
                return { txt = "hilite_win_role_singular", params = { role = ROLE_STRINGS[ROLE_SUMMONER] }, c = ROLE_COLORS[ROLE_SUMMONER] }
            end
        end)
    end
```

### Role Registration

The next line simply tells CR for TTT to register your role and passes through all the relevent information. You do not need to edit this line. CR for TTT automatically defines an enumeration for your role, `ROLE_%NAMERAW%` as well as helper functions `Get%NAMERAW%`, `Is%NAMERAW%` and `IsActive%NAMERAW%` if you would like to use them to add extra logic for your role.

### Final Block

Finally we have this block of code:

```lua
if SERVER then  
    AddCSLuaFile()
end
```

When this code is run on the server it makes sure the client downloads this file so they know everything you have done up until now. Any logic that should only run on the server-side should be in an `if SERVER then` block like this.

### Example File

Once you have done that you are finished with coding. You can close your file and move on to creating your sprites. One last time before moving on to that, here is the full summoner.lua file for reference, as it appears on the workshop:

```lua
local ROLE = {}  

ROLE.nameraw = "summoner"  
ROLE.name = "Summoner"  
ROLE.nameplural = "Summoners"  
ROLE.nameext = "a Summoner"  
ROLE.nameshort = "sum"

ROLE.desc = [[You are {role}! {comrades}  

Summon minions to help defeat your enemies.  

Press {menukey} to receive your special equipment!]]

ROLE.team = ROLE_TEAM_TRAITOR

ROLE.shop = {"weapon_ttt_beenade", "weapon_ttt_barnacle", "surprisecombine", "weapon_antlionsummoner", "weapon_controllable_manhack", "weapon_doncombinesummoner"} 
ROLE.loadout = {}

RegisterRole(ROLE)  

if SERVER then  
    AddCSLuaFile()
end
```

## Sprites

There are four different sprites used within CR for TTT and you will need to make a separate image file for each.

### Finding a Role Icon
Before you start messing with each individual sprite you need to find a good role icon. Your role icon should be solid white and you should avoid too much detail. One of the best places we know to find icons like this is https://game-icons.net/.

For the Summoner we are going to use their "minions" icon with some slight changes. Make sure your icon is white with a transparent background. Here is the final version of the icon we are using for the summoner:

![SummonerIcon.png](https://i.imgur.com/vbuDVHP.png)

### Tab File

The tab file is the simplest icon of the bunch. This icon shows up next to players that you know the role of when you are holding tab. There is no template for the tab icon as all you need to do is resize your icon down to 16x16. This icon should be saved as 'tab_%NAMESHORT%.png' where `%NAMESHORT%` is replaced with whatever you defined `nameshort` as earlier. All of the icons in this guide should be saved in 'Role Addon Template' > 'materials' > 'vgui' > 'ttt'.

Here is what we ended with for 'tab_sum.png':

![tab_sum.png](https://i.imgur.com/XocV4qu.png)

### Score File

The score file is what shows up in the round summary at the end of each round. Open up 'Score Template.psd' and you should see a white dashed outline. This is the guide for the size of your icon. Click on the 'Icon' layer and paste in your role icon. You should automatically see a shadow appear behind your icon. Resize this icon until the white is all inside the dashed outline. *(Note: It doesn't matter if some shadow spills out of the outline as long as all the white is inside the guide.)* Once you are happy with the positioning of the icon you can click the eye symbol next to the 'Icon Guide' layer to hide the dashed outline guide. Save this image as 'score_%NAMESHORT%.png' where `%NAMESHORT%` is replaced as you did before. Once again this should be saved in 'Role Addon Template' > 'materials' > 'vgui' > 'ttt'.

Here is what we have for 'score_sum.png':

![score_sum.png](https://i.imgur.com/zZkU611.png)

### Sprite File

The sprite file is what shows up above players heads when you know their role. Open up 'Sprite Template.psd' and once again you should see a white dashed outline. Repeat the same process as you did for the score icon. Click on the 'Icon' layer, paste in your role icon, resize to fit the outline and hide the outline guide layer. Save this image as 'sprite_%NAMESHORT%.png'.

For some icons GMod likes to use a .vtf or Valve Texture Format file. In order to do this we need to first create a .tga or Targa file. Targa files use an alpha layer for transparency so we need to convert our .png into a .tga. While Photoshop and GIMP can do this natively they do not properly create the alpha layer we need. The best method we have found is to use [Aconvert.com](https://www.aconvert.com/image/png-to-tga/) so upload your 'sprite_%NAMESHORT%.png' file here and download the converted Targa file.

Finally we can turn our .tga into the .vtf file we need. Open VTFEdit, click 'File' > 'Import' and select the converted Targa file. You should see your icon inside of VTFEdit except the shadows should have turned solid black and any transparency is now white. While this may look incredibly strange, this is actually exactly what we want! Save this file as 'sprite_%NAMESHORT%.vtf' in 'Role Addon Template' > 'materials' > 'vgui' > 'ttt'.

Here is the final version of 'sprite_sum.vtf':

![sprite_sum.vtf](https://i.imgur.com/IhFJfmp.png)

### Icon File

The icon file is shown when a body is searched to reveal that players role. Open up 'Icon Template.psd' and yet again you should see a guide outline. Repeat the same process you did for both the score and sprite files. The icon file also needs to have a .vtf format so save your file as a .png, upload it to [Aconvert.com](https://www.aconvert.com/image/png-to-tga/), download your .tga file and import it into VTFEdit. Save this file as 'icon_%NAMESHORT%.vtf' in 'Role Addon Template' > 'materials' > 'vgui' > 'ttt'.

Here is the final version of 'icon_sum.vtf':

![icon_sum.vtf](https://i.imgur.com/Jeh8sHo.png)

### .vmt Files

The final step you need to take to finish your role sprites is to update the three .vmt files that were already present in 'Role Addon Template' > 'materials' > 'vgui' > 'ttt' when you started. Rename each of the files to replace `%NAMESHORT%` with what you defined `nameshort` as in your earlier coding. Open up each file and you should see one line that looks like this:
```
"$basetexture" "vgui/ttt/sprite_%NAMESHORT%"
```
or this:
```
"$basetexture" "vgui/ttt/icon_%NAMESHORT%"
```
Replace `%NAMESHORT%` with whatever you set `nameshort` to earlier and save each of those three files.

For example, here is what 'sprite_sum_noz.vmt' looks like:
```
"UnlitGeneric"
{
    "$basetexture" "vgui/ttt/sprite_sum"
    "$nocull" 1
    "$ignorez" 1
    "$nodecal" 1
    "$nolod" 1
    "$vertexcolor" 1
    "$vertexalpha" 1
    "$translucent" 1
}
```

## Uploading Your Addon

Your role is almost ready to go! The last thing you need to do is upload your addon to the steam workshop. Before you can do that there are 2 more files you need to make 'addon.json' and your workshop icon.

### addon.json

'addon.json' is found inside the 'Role Addon Template' folder. Open it up and set `%NAME%` to whatever the name of your role is.

For example 'addon.json' for the Summoner role looks like this:
```
{
  "title": "Summoner (CR for TTT)",
  "type": "ServerContent",
  "ignore": []
}
```

### Workshop Icon

Now is the time to open the last template. This step is completely optional, you can use whatever workshop icon you want! However, if you want to keep it consistent with other CR for TTT roles open up 'Workshop Icon Template.psd'.

Right about now you should be getting a feeling of déjà vu because out friend the white dashed outline is back. Copy your role icon onto the 'Icon' layer and this time instead of a shadow you should see a thick coloured outline. Resize your icon so the white all fits within the guide, it doesn't matter if the coloured outline spills outside the guide. Hide the 'Icon Guide' layer and you are almost good to go.

Each team in CR for TTT has it's own colour it is identified by and this template works best if you switch out the background to match that colour. In the layers window you should see four different background colours. Hide all the ones that don't match your roles team. You should also see four different stroke outline effects on the 'Role Icon' layer. Hide all the ones that don't match the colour of the background.

In the case of the Summoner or another traitor role it should look like this:

![RoleLayers.png](https://i.imgur.com/x5sUaXT.png)

Once you have done that you are ready to hit save. This time you want to put your icon in the same folder as 'Role Addon Template', not inside it! Steam workshop needs the icon file to be a .jpg so make sure you save it as the right format.

Here is my finalised 'SummonerRole.jpg':

![SummonerRole.jpg](https://i.imgur.com/wTMTtEj.png)

### Folder Name

While we are at it now is a good time to rename 'Role Addon Template' because it's not a template anymore, it's yours! Name it the same thing as whatever you named your workshop icon.

Before you get to uploading now is a great time to test your addon. In Steam right click on Garry's Mod and click 'Manage' > 'Browse local files'. A folder should open up which contains your GMod files. Open 'garrysmod' > 'addons' and paste the folder you just renamed in here. When you next boot up GMod your addon should load and you can test it out before uploading to the workshop.

### Final Checks

Before you upload your addon, now is a great time to check that your file structure is all correct! For reference here is the file structure of my completed Summoner addon:

```
├─ SummonerRole.jpg
└─ SummonerRole
   ├─ addon.json
   ├─ lua
   │  └─ customroles
   │     └─ summoner.lua
   └─ materials
      └─ vgui
         └─ ttt
            ├─ score_sum.png
            ├─ tab_sum.png
            ├─ icon_sum.vtf
            ├─ icon_sum.vmt
            ├─ sprite_sum.vtf
            ├─ sprite_sum.vmt
            └─ sprite_sum_noz.vmt
```

### Uploading

Now you are ready to upload your addon. In Steam right click on Garry's Mod and click 'Manage' > 'Browse local files'. A folder should open up which contains your GMod files. Open 'bin' and you should see a file called 'gmad.exe'. Drag and drop your addon folder onto 'gmad.exe'. You should see a new file appear next to your addon folder. It should have the same name as your folder but with the file extension '.gma'. In my case we now have a new file called 'SummonerRole.gma'.

Go back to the same folder where you found 'gmad.exe'. Click on the address bar up the top and type 'cmd'. This should open up the command prompt where you need to type this command to upload your addon.

```
gmpublish.exe create -addon %PATHTOGMA% -icon %PATHTOJPG%
```

Replace `%PATHTOGMA%` and `%PATHTOJPG%` with the file paths to your .gma addon file and .jpg workshop icon respectively.

For my Summoner addon it looks like this:

```
gmpublish.exe create -addon "C:\Development\GMod\SummonerRole.gma" -icon "C:\Development\GMod\SummonerRole.jpg"
```

Hit enter and you should see your addon upload to Steam! Once it is done you can view your addon by opening steam, hovering over your name up the top and clicking 'Content'. Click the 'Workshop Items' tab and your addon should be there! Here you can give your addon a description and then change its visibility to public. *(Note: If you ever need to update a pre-existing addon you can read how to do that [here](https://wiki.facepunch.com/gmod/Workshop_Addon_Updating).)*

Once you have made your addon public, we would love to hear about it! Jump into [our discord server](https://discord.gg/BAPZrykC3F) and show us what you have made!

## Wrapping Up

If you have any problems or questions please jump into the [Custom Roles for TTT Discord Server](https://discord.gg/BAPZrykC3F)! We love to see what everyone has making and there are almost always people online willing to help out if you need a hand.
