**WORK IN PROGRESS - MORE ROLES WILL BE ADDED OVER TIME**

# Custom Roles for TTT

This is the development version of [Custom Roles for TTT](https://steamcommunity.com/sharedfiles/filedetails/?id=2421039084). Use at your own risk! This version of the mod could be unstable and is updated regularly. Do not use the development version if you need the mod to be reliable. (e.g. for streaming, youtube, etc.)

## Important Notes

1. All custom roles are disabled by default. Please read the ConVar list to find out how to turn them on.
2. Traitor voice chat has been rebound to allow sprint to be shift by default. You will need to bind a new key to "Suit Zoom" to use traitor voice chat.
3. The radio menu (quick chat) has been rebound to "n" by default but that can be changed in the F1 settings menu.

## Roles
### *List*
See the links below for the list of available roles in each available version:
- Release - Please see [this](https://steamcommunity.com/workshop/filedetails/discussion/2421039084/3108019427651795196/) discussion on the Steam Workshop
- Beta/Development - Please see [this](https://steamcommunity.com/workshop/filedetails/discussion/2404251054/3110277460812045123/) discussion on the Steam Workshop
### *Renaming*
If you would like to rename one of the existing roles, see below for how to do it for each available version:
- Release - See [here](https://github.com/NoxxFlame/TTT-Custom-Roles/blob/release/CONVARS.md#Renaming-Roles)
- Beta/Development - See [here](https://github.com/NoxxFlame/TTT-Custom-Roles/blob/beta/CONVARS.md#Renaming-Roles)
### *Creating Custom Roles*
If you would like to create your own role to integrate with Custom Roles for TTT, see, see [here](CREATE_YOUR_OWN_ROLE.md).

## Configuration
This addon has many ConVars available so it can be customized to how you want your server to run. All custom roles are disabled by default.\
A full list of ConVars can be found [here](https://github.com/NoxxFlame/TTT-Custom-Roles/blob/release/CONVARS.md) (for the release version) or [here](https://github.com/NoxxFlame/TTT-Custom-Roles/blob/beta/CONVARS.md) (for the beta and development versions).\
\
If you would like to test the available configurations, we recommend using ULX/ULib and our ULX plugin for Custom Roles for TTT. See below for links to the various versions:
- [Release](https://steamcommunity.com/sharedfiles/filedetails/?id=2421043753)
- [Beta](https://steamcommunity.com/sharedfiles/filedetails/?id=2414297330)
- [Development](https://github.com/NoxxFlame/TTT-Custom-Roles-ULX)

**NOTE**: Changing settings via the ULX module will *NOT* save them when the map changes or server restarts. You can use the ULX module to test settings changes and identify which ones to put in the appropriate configuration file (server.cfg for dedicated servers or listenserver.cfg for peer-to-peer, listen, and local servers)

## Special Thanks:
- [Jenssons](https://steamcommunity.com/profiles/76561198044525091) for the ['Town of Terror'](https://steamcommunity.com/sharedfiles/filedetails/?id=1092556189) mod which was the foundation of this mod.
- [hendrikbl](https://steamcommunity.com/id/gamerhenne) for the ['Better Equipment Menu'](https://steamcommunity.com/sharedfiles/filedetails/?id=878772496) mod which is integrated into this mod.
- [Silky](https://steamcommunity.com/profiles/76561198094798859) for the code used to create the pile of bones after the Vampire eats a body taken from the ['TTT Traitor Weapon Evolve'](https://steamcommunity.com/sharedfiles/filedetails/?id=1240572856) mod.
- [Minty](https://steamcommunity.com/id/_Minty_) for the code used in many items taken from the ['Defibrillator for TTT'](https://steamcommunity.com/sharedfiles/filedetails/?id=801433502) mod.
- [Fresh Garry](https://steamcommunity.com/id/Fresh_Garry) for the ['TTT Sprint'](https://steamcommunity.com/sharedfiles/filedetails/?id=933056549) mod which was used as the base for this mod's sprinting mechanics.
- [Lykrast](https://steamcommunity.com/id/Lykrast) for the code and models used to create the old man's double barrel shotgun taken from ['Lykrast's TTT Weapon Collection'](https://steamcommunity.com/sharedfiles/filedetails/?id=337994500).
- [Game icons](https://game-icons.net), [Noun Project](https://thenounproject.com), and [Icons8](https://icons8.com) for the role icons.
- [Videvo](https://www.videvo.net/profile/videvo/) for the royalty-free [extinguish sound](https://www.videvo.net/sound-effect/short-light-fire-exti-pe363704/255924/) and cough sounds: [1](https://www.videvo.net/sound-effect/human-cough-33/427996/), [2](https://www.videvo.net/sound-effect/human-cough-36/427999/), [3](https://www.videvo.net/sound-effect/human-cough-39/428002/), [4](https://www.videvo.net/sound-effect/human-cough-63/428026/)
- Our friends and everyone on the Discord server for their suggestions and help testing.

## Conflicts
- Any other addon that adds roles such as Town of Terror, TTT2, or the outdated versions of Custom Roles for TTT. There is no reason to use more than one role addon so remove all the ones you don't want.
- [Better Equipment Menu](https://steamcommunity.com/sharedfiles/filedetails/?id=878772496) - This has its functionality built in
- [TTT Damage Logs](https://github.com/Tommy228/tttdamagelogs) - Use [this version](https://steamcommunity.com/sharedfiles/filedetails/?id=2306802961) instead
- [TTT DeadRinger](https://steamcommunity.com/sharedfiles/filedetails/?id=254779132) - Overrides several scripts that are core to TTT that this also overrides (notably, the scoreboard and client initialization). As a workaround, you can use [this version](https://steamcommunity.com/sharedfiles/filedetails/?id=810154456) instead.
- [TTT: Advanced Body Search](https://steamcommunity.com/sharedfiles/filedetails/?id=367945571) - Overwrites the body search dialog in ways that don't keep compatibility with the changes we also make to the same dialog.
- [TTT SimpleHUD](https://steamcommunity.com/sharedfiles/filedetails/?id=2209392671) - Overrides several scripts that are core to TTT that this also overrides (notably, the weapon switch HUD). Claims compatibility with Custom Roles, but only supports the outdated version.

## FAQs
**How do I use Custom Roles for TTT?**\
To use CR for TTT, subscribe to the addon in the Steam workshop and refer to the [Configuration](#Configuration) section above for how to change settings (including enabling the new roles).

**How do I get this on my server?**\
The easiest way to get CR for TTT onto a dedicated server is to create use an addon collection. See [this guide](https://wiki.facepunch.com/gmod/Workshop_for_Dedicated_Servers) on how to create and use a collection for your dedicated server.

If you're using a peer-to-peer, listen, or local server then we still recommend using an addon collection, but any addon you subscribe to and have enabled will automatically be loaded when you start the server. Having an addon collection makes it easier for your players to get the same addons without having to download them from you each time they want to play.

**How do I get the changed convars to save? The settings I change reset when I restart the server -- how do I save them?**\
The convars added in Custom Roles for TTT follow the precedent of many of the convars from the base TTT: They do not archive (save) automatically.
To save the convar changes, add the changed values to your server.cfg (for dedicated servers) or listenserver.cfg (for peer-to-peer, listen, and local servers).

**Do I need the other versions of Custom Roles or Town of Terror as well?**\
No, you should only use one addon that adds roles. That means only this version of Custom Roles, no Town of Terror, no TTT2, etc.

**This lags everyone when I play on my peer-to-peer (aka listen, aka local) server/game**\
Everyone needs to subscribe to this workshop item, not just the host. We're not sure why that is, but having everyone subscribed to the addon seems to help.\
\
We would suggest making a workshop collection of the addons you have and then having your friends subscribe to them all.

**How do I enable the new roles? How do I change X, Y, or Z?**\
Check out the [Configuration](#Configuration) section above and add the setting value you want in your server.cfg (for dedicated servers) or listenserver.cfg (for peer-to-peer, listen, and local servers). If you don't see a setting for what you want to change, leave a comment on the workshop or join the Discord server (see below) and we'll either help you find it or try to add one.

**How do I make a Detective spawn every round?**\
Set the following settings:\
\
_ttt_detective_min_players_ 1\
_ttt_detective_pct_ 1\
\
Also if you want ONLY one detective, set:\
_ttt_detective_max_ 1

**My shop is not working for anyone but the Detective and Traitor/I am getting errors when I try to open the shop/My shop is not loading correctly, it's just a blank grey window**\
This is probably due to another mod conflicting with this one. Check for things like the 'Better Equipment Menu' mod (which is integrated into this one). If removing that doesn't fix the problem, join the Discord server (see below) and we'll try to help you identify any other conflicts.

**Nothing happens when I search a body as a detective**\
This is most likely caused by a conflict with a mod like 'TTT: Advanced Body Search'. If removing that doesn't fix the problem, join the Discord server (see below) and we'll try to help you identify any other conflicts.

**The addon doesn't load when I place it in the `addons` folder on my server**\
If you are using a Linux machine to host your server you may need to lowercase the folder name for it to be loaded properly. For example, `[INSTALL_DIR]/garrysmod/addons/TTT-Custom-Roles` would become `[INSTALL_DIR]/garrysmod/ttt-custom-roles`. See [GMod Linux Dedicated Server Hosting](https://wiki.facepunch.com/gmod/Linux_Dedicated_Server_Hosting#addonsnotworking) for details.

## Official Links:
- GitHub: https://github.com/NoxxFlame/TTT-Custom-Roles
- Steam Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=2421039084
- Steam Workshop (Beta): https://steamcommunity.com/sharedfiles/filedetails/?id=2404251054
- Discord: https://discord.gg/BAPZrykC3F
