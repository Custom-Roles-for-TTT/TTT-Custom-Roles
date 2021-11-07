# Application Programming Interface (API)
## Overview
These documents aim to explain the things that we have added to Custom Roles for TTT that are usable by other developers for integration.

*NOTE:* Any entries in these documents marked as *deprecated* will provide a version number where we will begin issuing a warning message in the server console if they are used. Anything marked as *deprecated* will be removed in the first beta version following the next major release from the deprecation version. For example: If something is marked as "deprecated in version 1.2.5" and the next released version number is 1.2.6 then that deprecated thing will be deleted in the beta version after that (1.2.7, for example).

## Table of Contents
1. [Global Variables](GLOBAL_VARIABLES.md)
1. [Global Enumerations](GLOBAL_ENUMERATIONS.md)
1. Methods
   1. [Global](METHODS_GLOBAL.md)
   1. [Player Object](METHODS_PLAYER_OBJECT.md)
   1. [Player Static](METHODS_PLAYER_STATIC.md)
   1. [Table](METHODS_TABLE.md)
   1. [HUD](METHODS_HUD.md)
1. [Hooks](HOOKS.md)
1. [SWEPs](SWEPS.md)
1. [Commands](COMMANDS.md)
   1. [Client Commands](COMMANDS.md#Client-Commands)
   1. [Server Commands](COMMANDS.md#Server-Commands)
1. [Net Messages](NET_MESSAGES.md)