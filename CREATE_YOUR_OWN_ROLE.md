# Creating Your Own Custom Roles for TTT Role
## Before You Start
In order to create your own role you will need to make sure you have downloaded tools to edit the following file types:

-   **.psd** - For this guide I will be using Photoshop but  [GIMP](https://www.gimp.org/) is a great free alternative.
-   **.lua** - This can be done in Notepad in a pinch but at the very least I would reccomend  [Notepad++](https://notepad-plus-plus.org/).
-   **.vmt and .vtf**  -  [VTFEdit](https://nemstools.github.io/pages/VTFLib-Download.html) is the best way to edit these files but if you know what you are doing there are plugins for other apps.

In this guide I will be walking through how I made the Summoner role and you can download all the templates I am using [here](https://drive.google.com/uc?export=download&id=1W6_LV1aqdXXwah-Q2Op2wdOtVkBs-S6Q).

Last thing to do before you are ready to get started is to unzip that file which should give you 4 .psd files and a folder like this:

![TemplateContents.png](https://i.imgur.com/UCyxklx.png)

## Code

Open up 'Role Addon Template' > 'lua' > 'customroles' and rename '%NAMERAW%.lua' to whatever you want the name of your role to be. In this case I will rename it to 'summoner.lua'.

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
  
ROLE.shop = {}  
  
ROLE.loadout = {}  

ROLE.convars = {}
  
RegisterRole(ROLE)  
  
if SERVER then  
	AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/icon_%NAMESHORT%.vmt")  
	resource.AddFile("materials/vgui/ttt/sprite_%NAMESHORT%.vmt")  
	resource.AddSingleFile("materials/vgui/ttt/sprite_%NAMESHORT%_noz.vmt")  
	resource.AddSingleFile("materials/vgui/ttt/score_%NAMESHORT%.png")  
	resource.AddSingleFile("materials/vgui/ttt/tab_%NAMESHORT%.png")  
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
| Detective (BETA ONLY) | `ROLE_TEAM_DETECTIVE` |
| Jester | `ROLE_TEAM_JESTER` |
| Independent | `ROLE_TEAM_INDEPENDENT` |

So for the Summoner, which is a traitor we have:

```lua
ROLE.team = ROLE_TEAM_TRAITOR
```

### Shop and Loadout Items

The next two lines are all about shop and loadout items:

```lua
ROLE.shop = {}  
  
ROLE.loadout = {}
```

If you want your role to have access to a shop or if you want them to spawn with any items, this is where you can add that.

Inside the curly brackets add the class names of any weapons or equipment you want, separated by commas. To find the class name of a weapon or equipment you can do the following:

#### Weapon:
1. Start a local server with TTT as the selected gamemode
2. Spawn 1 bot by using the _bot_ command in console
3. Obtain the weapon whose class you want. If it is already available to buy from a certain role's shop, either force yourself to be that role via the _ttt\_force\_*_ commands or via a ULX plugin.
4. Run the following command in console to get a list of all of your weapon classes: `lua_run PrintTable(player.GetHumans()[1]:GetWeapons())`

#### Equipment:
To find the name of an equipment item to use above, follow the steps below
1. Start a local server with TTT as the selected gamemode
2. Spawn 1 bot by using the _bot_ command in console
3. Obtain the equipment item whose name you want. If it is already available to buy from a certain role's shop, either force yourself to be that role via the _ttt\_force\_*_ commands or via a ULX plugin.
4. Run the following command in console to get a full list of your equipment item names: `lua_run GetEquipmentItemById(EQUIP_RADAR); lua_run for id, e in pairs(EquipmentCache) do if player.GetHumans()[1]:HasEquipmentItem(id) then print(id .. " = " .. e<area>.name) end end`

For the Summoner, I don't want any loadout items but I do want the shop to have access to a few different items so I can add them like this:

```lua
ROLE.shop = {"weapon_ttt_beenade", "weapon_ttt_barnacle", "surprisecombine", "weapon_antlionsummoner", "weapon_controllable_manhack", "weapon_doncombinesummoner", "item_armor", "item_radar", "item_disg"}  
  
ROLE.loadout = {}
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

The Summoner does not have any extra ConVars but for the sake of example I will add three useless ConVars.

```lua
if SERVER then
    CreateConVar("ttt_summoner_slider", "0", FCVAR_NONE, "This is a useless slider", 0, 10)
    CreateConVar("ttt_summoner_checkbox", "0")
    CreateConVar("ttt_summoner_textbox", "0")
end
ROLE.convars = {
	{
		cvar = "ttt_summoner_slider",
		type = ROLE_CONVAR_TYPE_NUM,
		decimal = 2
	},
	{
		cvar = "ttt_summoner_checkbox",
		type = ROLE_CONVAR_TYPE_BOOL
	},
	{
		cvar = "ttt_summoner_textbox",
		type = ROLE_CONVAR_TYPE_TEXT
	}
}
```

### Role Registration

The next line simply tells CR for TTT to register your role and passes through all the relevent information. You do not need to edit this line. CR for TTT automatically defines an enumeration for your role, `ROLE_%NAMERAW%` as well as helper functions `Get%NAMERAW%`, `Is%NAMERAW%` and `IsActive%NAMERAW%` if you would like to use them to add extra logic for your role.

### Sprites

Finally we have this block of code:

```lua
if SERVER then  
	AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/icon_%NAMESHORT%.vmt")  
	resource.AddFile("materials/vgui/ttt/sprite_%NAMESHORT%.vmt")  
	resource.AddSingleFile("materials/vgui/ttt/sprite_%NAMESHORT%_noz.vmt")  
	resource.AddSingleFile("materials/vgui/ttt/score_%NAMESHORT%.png")  
	resource.AddSingleFile("materials/vgui/ttt/tab_%NAMESHORT%.png")  
end
```

When this code is run on the server it makes sure that the client will download all the required files if they haven't already. `AddCSLuaFile()` makes sure the client downloads this file so they know everything you have done up until now. The next five lines make sure the client downloads all the sprites or images for your role. Swap `%NAMESHORT%` for whatever you set `nameshort` to earlier.

For the summoner that looks like this:

```lua
if SERVER then  
	AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/icon_sum.vmt")  
	resource.AddFile("materials/vgui/ttt/sprite_sum.vmt")  
	resource.AddSingleFile("materials/vgui/ttt/sprite_sum_noz.vmt")  
	resource.AddSingleFile("materials/vgui/ttt/score_sum.png")  
	resource.AddSingleFile("materials/vgui/ttt/tab_sum.png")  
end
```

### Example File

Once you have done that you are finished with coding. You can close your file and move on to creating your sprites. One last time before moving on to that, here is the full summoner.lua file for reference:

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
  
ROLE.shop = {"weapon_ttt_beenade", "weapon_ttt_barnacle", "surprisecombine", "weapon_antlionsummoner", "weapon_controllable_manhack", "weapon_doncombinesummoner", "item_armor", "item_radar", "item_disg"} 
  
ROLE.loadout = {}  

if SERVER then
    CreateConVar("ttt_summoner_slider", "0", FCVAR_NONE, "This is a useless slider", 0, 10)
    CreateConVar("ttt_summoner_checkbox", "0")
    CreateConVar("ttt_summoner_textbox", "0")
end
ROLE.convars = {
	{
		cvar = "ttt_summoner_slider",
		type = ROLE_CONVAR_TYPE_NUM,
		decimal = 2
	},
	{
		cvar = "ttt_summoner_checkbox",
		type = ROLE_CONVAR_TYPE_BOOL
	},
	{
		cvar = "ttt_summoner_textbox",
		type = ROLE_CONVAR_TYPE_TEXT
	}
}
  
RegisterRole(ROLE)  
  
if SERVER then  
	AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/icon_sum.vmt")  
	resource.AddFile("materials/vgui/ttt/sprite_sum.vmt")  
	resource.AddSingleFile("materials/vgui/ttt/sprite_sum_noz.vmt")  
	resource.AddSingleFile("materials/vgui/ttt/score_sum.png")  
	resource.AddSingleFile("materials/vgui/ttt/tab_sum.png")  
end
```

## Sprites

There are four different sprites used within CR for TTT and you will need to make a separate image file for each.

### Finding a Role Icon
Before you start messing with each individual sprite you need to find a good role icon. Your role icon should be solid white and you should avoid too much detail. One of the best places I know to find icons like this is https://game-icons.net/.

For the Summoner I am going to use their minions with some slight changes. Make sure your icon is white with a transparent background. Here is the final version of the icon I am using for the summoner:

![SummonerIcon.png](https://i.imgur.com/vbuDVHP.png)

### Tab File

The tab file is the simplest icon of the bunch. This icon shows up next to players that you know the role of when you are holding tab. There is no template for the tab icon as all you need to do is resize your icon down to 16x16. This icon should be saved as 'tab_%NAMESHORT%.png' where `%NAMESHORT%` is replaced with whatever you defined `nameshort` as earlier. All of the icons in this guide should be saved in 'Role Addon Template' > 'materials' > 'vgui' > 'ttt'.

Here is what I ended with for 'tab_sum.png':

![tab_sum.png](https://i.imgur.com/XocV4qu.png)

### Score File

The score file is what shows up in the round summary at the end of each round. Open up 'Score Template.psd' and you should see a white dashed outline. This is the guide for the size of your icon. Click on the 'Icon' layer and paste in your role icon. You should automatically see a shadow appear behind your icon. Resize this icon until the white is all inside the dashed outline. *(Note: It doesn't matter if some shadow spills out of the outline as long as all the white is inside the guide.)* Once you are happy with the positioning of the icon you can click the eye symbol next to the 'Icon Guide' layer to hide the dashed outline guide. Save this image as 'score_%NAMESHORT%.png' where `%NAMESHORT%` is replaced as you did before. Once again this should be saved in 'Role Addon Template' > 'materials' > 'vgui' > 'ttt'.

Here is what I have for 'score_sum.png':

![score_sum.png](https://i.imgur.com/zZkU611.png)

### Sprite File

The sprite file is what shows up above players heads when you know their role. Open up 'Sprite Template.psd' and once again you should see a white dashed outline. Repeat the same process as you did for the score icon. Click on the 'Icon' layer, paste in your role icon, resize to fit the outline and hide the outline guide layer. Save this image as 'sprite_%NAMESHORT%.png'.

For some icons GMod likes to use a .vtf or Valve Texture Format file. In order to do this we need to first create a .tga or Targa file. Targa files use an alpha layer for transparency so we need to convert our .png into a .tga. While Photoshop and GIMP can do this natively they do not properly create the alpha layer we need. The best method I have found is to use [Aconvert.com](https://www.aconvert.com/image/png-to-tga/) so upload your 'sprite_%NAMESHORT%.png' file here and download the converted Targa file.

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
	"$vertexcolor" 	1
	"$vertexalpha" 	1
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

Now you are ready to upload your addon. In Steam right click on Garry's Mod and click 'Manage' > 'Browse local files'. A folder should open up which contains your GMod files. Open 'bin' and you should see a file called 'gmad.exe'. Drag and drop your addon folder onto 'gmad.exe'. You should see a new file appear next to your addon folder. It should have the same name as your folder but with the file extension '.gma'. In my case I now have a new file called 'SummonerRole.gma'.

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
