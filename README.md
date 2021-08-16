**WORK IN PROGRESS - MORE ROLES WILL BE ADDED OVER TIME**

# Custom Roles for TTT

This is the development version of my [Custom Roles for TTT](https://steamcommunity.com/sharedfiles/filedetails/?id=2421039084) mod. Use at your own risk! This version of the mod could be unstable and is updated regularly. Do not use the development version if you need the mod to be reliable. (e.g. for streaming, youtube, etc.)

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
- Release - See [here](CONVARS.md#Renaming-Roles)
- Beta/Development - See [here](CONVARS_BETA.md#Renaming-Roles)
### *Creating Custom Roles*
If you would like to create your own role to integrate with Custom Roles for TTT, see, see [here](CREATE_YOUR_OWN_ROLE.md).\

## Configuration
This addon has many ConVars available so it can be customized to how you want your server to run. All custom roles are disabled by default.\
A full list of ConVars can be found [here](CONVARS.md) (for the release version) or [here](CONVARS_BETA.md) (for the beta and development versions).\
\
If you would like to test the available configurations, we recommend using ULX/ULib and our ULX plugin for Custom Roles for TTT. See below for links to the various versions:
- [Release](https://steamcommunity.com/sharedfiles/filedetails/?id=2421043753)
- [Beta](https://steamcommunity.com/sharedfiles/filedetails/?id=2414297330)
- [Development](https://github.com/NoxxFlame/TTT-Custom-Roles-ULX)

**NOTE**: Changing settings via the ULX module will *NOT* save them when the map changes or server restarts. You can use the ULX module to test settings changes and identify which ones to put in the appropriate configuration file for your server (see above).

## Special Thanks:
- [Jenssons](https://steamcommunity.com/profiles/76561198044525091) for the ['Town of Terror'](https://steamcommunity.com/sharedfiles/filedetails/?id=1092556189) mod which was the foundation of this mod.
- [hendrikbl](https://steamcommunity.com/id/gamerhenne) for the ['Better Equipment Menu'](https://steamcommunity.com/sharedfiles/filedetails/?id=878772496) mod which is integrated into this mod.
- [Silky](https://steamcommunity.com/profiles/76561198094798859) for the code used to create the pile of bones after the Vampire eats a body taken from the ['TTT Traitor Weapon Evolve'](https://steamcommunity.com/sharedfiles/filedetails/?id=1240572856) mod.
- [Minty](https://steamcommunity.com/id/_Minty_) for the code used for the Hypnotist's brain washing device taken from the ['Defibrillator for TTT'](https://steamcommunity.com/sharedfiles/filedetails/?id=801433502) mod.
- [Fresh Garry](https://steamcommunity.com/id/Fresh_Garry) for the ['TTT Sprint'](https://steamcommunity.com/sharedfiles/filedetails/?id=933056549) mod which was used as the base for this mod's sprinting mechanics.
- [Game icons](https://game-icons.net), [Noun Project](https://thenounproject.com), and [Icons8](https://icons8.com) for the role icons.
- Kommandos, Lix3, FunCheetah, B1andy413, Cooliew, The_Samarox, Arack12, and Aspirin for helping us test.
- Everyone on the Discord server for their suggestions and help testing.

## Conflicts
- Any other addon that adds roles such as Town of Terror, TTT2, or the outdated versions of Custom Roles for TTT. There is no reason to use more than one role addon so remove all the ones you don't want.
- [Better Equipment Menu](https://steamcommunity.com/sharedfiles/filedetails/?id=878772496) - This has its functionality built in
- [TTT Damage Logs](https://github.com/Tommy228/tttdamagelogs) - Use [this version](https://steamcommunity.com/sharedfiles/filedetails/?id=2306802961) instead
- [TTT DeadRinger](https://steamcommunity.com/sharedfiles/filedetails/?id=2045444087) - Overrides several scripts that are core to TTT that this also overrides (notably, the scoreboard and client initialization). As a workaround, you can use [this version](https://steamcommunity.com/sharedfiles/filedetails/?id=810154456) instead.

## FAQs
**Do I need the other versions of Custom Roles or Town of Terror as well?**\
No, you should only use one addon that adds roles. That means only this version of Custom Roles, no Town of Terror, no TT2, etc.

**This lags everyone when I play on my peer-to-peer (aka listen, aka local) server/game**\
Everyone needs to subscribe to this workshop item, not just the host. We're not sure why that is, but having everyone subscribed to the addon seems to help.\
\
I would suggest making a workshop collection of the addons you have and then having your friends subscribe to them all.

**How do I change X, Y, or Z?**\
Check out the [Configuration](#Configuration) section above and add the setting value you want in your server.cfg (for dedicated servers) or listenserver.cfg (For peer-to-peer, listen, and local servers). If you don't see a setting for what you want to change, leave a comment on the workshop or join the Discord server (see below) and we'll either help you find it or try to add one.

**How do I make a Detective spawn every round?**\
Set the following settings:\
\
_ttt_detective_min_players_ 1\
_ttt_detective_pct_ 1\
\
Also if you want ONLY one detective, set:\
_ttt_detective_max_ 1

**My shop is not working for anyone but the Detective and Traitor/I am getting errors when I try to open the shop/My shop is not loading correctly, it's just a blank grey window**\
This is probably due to another mod conflicting with this one. Check for things like the 'Better Equipment Menu' mod (which is integrated into this one). If that doesn't fix the problem, join the Discord server (See below) and we'll try to help you identify any other conflicts.

## Official Links:
- GitHub: https://github.com/NoxxFlame/TTT-Custom-Roles
- Steam Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=2421039084
- Steam Workshop (Beta): https://steamcommunity.com/sharedfiles/filedetails/?id=2404251054
- Discord: https://discord.gg/BAPZrykC3F
