# Player Object Methods
Methods available when called from a Player object (within the defined realm)

### plymeta:BeginRoleChecks()
Sets up role logic for the player to handle role-specific events and checks.\
*Realm:* Server\
*Added in:* 1.1.9

### plymeta:Celebrate(snd, showConfetti)
Plays a celebration effect (sound and or confetti) at the player's location.\
*Realm:* Client\
*Added in:* 1.3.1\
*Parameters:*
- *snd* - What sound to play (if any) as part of this celebration
- *showConfetti* - Whether to show confetti as part of this celebration

### plymeta:CanLootCredits(activeOnly)
Whether the player can loot credits from a corpse that has them.\
*Realm:* Client and Server\
*Added in:* 1.0.5\
*Parameters:*
- *activeOnly* - Whether the player must also be active (Defaults to `false`)

### plymeta:CanSeeC4()
Whether the player can see the C4 icons like traitors can.\
*Realm:* Client and Server\
*Added in:* 1.5.14

### plymeta:CanUseShop()
Whether the player can currently open the shop menu.\
*Realm:* Client and Server\
*Added in:* 1.0.2

### plymeta:CanUseTraitorButton(activeOnly)
Whether the player can see and use traitor buttons.\
*Realm:* Client and Server\
*Added in:* 1.0.5\
*Parameters:*
- *activeOnly* - Whether the player must also be active (Defaults to `false`)

### plymeta:ClearForcedRole()
Clears the player's forced role if one was set with `plymeta:ForceRoleNextRound(role)`.\
*Realm:* Server\
*Added in:* 2.0.7

### plymeta:ClearProperty(name, targets)
Clears the value of the property with the given `name` on this player then synchronizes the clear to all `targets`. Wrapper around [SYNC:ClearPlayerProperty](METHODS_SYNC.md#syncclearplayerpropertyply-propertyname-targets).\
*Realm:* Server\
*Added in:* 2.1.18\
*Parameters:*
- *name* - The name of the property being cleared.
- *targets* - The targets that should have this value cleared on their clients. *(Defaults to sending to all players)*

### plymeta:ClearQueuedMessage(id)
Removes queued messages with the given ID from the queue and clears any currently displayed messages with the given ID.\
*Realm:* Client and Server\
*Added in:* 2.2.1\
*Parameters:*
- *id* - The identifier of the message(s) you want to clear

### plymeta:DrunkJoinLosingTeam()
Attempts to find the losing team and calls `self:SoberDrunk(team)` using the losing team as the *team* parameter.\
*Realm:* Server\
*Added in:* 1.7.2

### plymeta:DrunkRememberRole(role)
Sets the drunk's role and runs required checks for that role.\
*Realm:* Server\
*Added in:* 1.1.9\
*Parameters:*
- *role* - Which role to set the drunk to (see ROLE_* global enumeration)

### plymeta:ForceRoleNextRound(role)
Forces a player to spawn as the specified role next round. Returns `true` if successful, `false` if that player has already been forced to be another role.\
*Realm:* Server\
*Added in:* 2.0.7\
*Parameters:*
- *role* - Which role to force the player to be next round

### plymeta:GetAvoidDetective()/plymeta:ShouldAvoidDetective() (Added in 1.6.2)
Whether this player wants to avoid being a detective role.\
*Realm:* Server\
*Added in:* 1.0.0

### plymeta:GetBypassCulling()/plymeta:ShouldBypassCulling()
Whether this player wants to bypass map optimizations like vis leafs and culling for things like role head icons and highlighting.\
*Realm:* Server\
*Added in:* 1.6.2

### plymeta:GetDisplayedRole()
Gets the role that should be displayed for the player.\
*Realm:* Client and Server\
*Added in:* 1.5.3

*Returns:*
- *display_role* - The role that should be displayed for the player.
- *changed* - Whether the return value was changed and should be hidden

### plymeta:GetForcedRole()
Gets the player's forced role if one was set with `plymeta:ForceRoleNextRound(role)`. Returns `false` otherwise.\
*Realm:* Server\
*Added in:* 2.0.7

### plymeta:GetHeight()
Gets the *estimated* height of the player based on their player model.\
*Realm:* Client\
*Added in:* 1.0.2

### plymeta:GetRoleTeam(detectivesAreInnocent)
Gets which "role team" a player belongs to (see ROLE_TEAM_* global enumeration).\
*Realm:* Client and Server\
*Added in:* 1.2.7\
*Parameters:*
- *detectivesAreInnocent* - Whether to include members of the detective "role team" in the innocent "role team" to match the logical teams

### plymeta:GetSprinting()
Gets whether the player is currently sprinting.\
*Realm:* Client and Server\
*Added in:* 1.8.8

### plymeta:GetSprintStamina()
Gets the player's current sprint stamina.\
*Realm:* Client and Server\
*Added in:* 1.8.8

### plymeta:GetVampirePreviousRole()
Gets the player's previous role if they are a Vampire that has been converted or `ROLE_NONE` otherwise.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### plymeta:GiveDelayedShopItems()
Give the player their shop items that were being held due to the role having a delayed shop.\
*Realm:* Server\
*Added in:* 1.2.2

### plymeta:HandleDetectiveLikePromotion()
Handles the player's promotion as a detective-like role (deputy/impersonator). Promotes the player and sends necessary net events.\
*Realm:* Server\
*Added in:* 1.2.5

### plymeta:Is{RoleName}()/plymeta:Get{RoleName}()
Dynamically created functions for each role that returns whether the player is that role. For example: `plymeta:IsTraitor()` and `plymeta:IsPhantom()` return whether the player is a traitor or a phantom, respectively.\
*Realm:* Client and Server\
*Added in:* Whenever each role is added

### plymeta:IsActive{RoleName}()
Dynamically created functions for each role that returns whether `plymeta:Is{RoleName}` returns `true` and the player is active. For example: `plymeta:IsActiveTraitor()` and `plymeta:IsActivePhantom()` return whether the player is active and a traitor or a phantom, respectively.\
*Realm:* Client and Server\
*Added in:* Whenever each role is added

### plymeta:IsActiveCustom()
Whether `plymeta:IsCustom` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### plymeta:IsActiveDetectiveLike()
Whether `plymeta:IsActiveDetectiveLike` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### plymeta:IsActiveIndependentTeam()
Whether `plymeta:IsIndependentTeam` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### plymeta:IsActiveInnocentTeam()
Whether `plymeta:IsInnocentTeam` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### plymeta:IsActiveJesterTeam()
Whether `plymeta:IsJesterTeam` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### plymeta:IsActiveMonsterTeam()
Whether `plymeta:IsMonsterTeam` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### plymeta:IsActiveTraitorTeam()
Whether `plymeta:IsTraitorTeam` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### plymeta:IsActiveShopRole()
Whether `plymeta:IsActiveShopRole` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### plymeta:IsCustom()
Whether the player's role is not one of the three default TTT roles.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### plymeta:IsDetectiveLike()/plymeta:GetDetectiveLike()
Whether the player's role is like a detective (e.g. detective or promoted deputy/impersonator).\
*Realm:* Client and Server\
*Added in:* 1.0.0

### plymeta:IsDetectiveLikePromotable()/plymeta:GetDetectiveLikePromotable()
Whether the player's role is an unpromoted detective-like role (deputy/impersonator).\
*Realm:* Client and Server\
*Added in:* 1.2.5

### plymeta:IsIndependentTeam()
Whether the player is on the independent team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### plymeta:IsInnocentTeam()
Whether the player is on the innocent team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### plymeta:IsInvulnerable()
Whether the player is invulnerable.\
*Realm:* Client and Server\
*Added in:* 2.1.17

### plymeta:IsJesterTeam()
Whether the player is on the jester team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### plymeta:IsMonsterTeam()
Whether the player is on the monster team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### plymeta:IsOnScreen(ent_or_pos, limit)
Whether the entity or position given is on screen for the player, within the given value limit.\
*Realm:* Client and Server\
*Added in:* 1.6.2\
*Parameters:*
- *ent_or_pos* - The entity or position vector that is being checked
- *limit* - The maximum value limit before a player is determined to be "off screen" (Defaults to 1)

### plymeta:IsRespawning()
Whether this player is currently respawning.\
*Realm:* Client and Server\
*Added in:* 2.1.12

### plymeta:IsRoleActive()
Whether the player's role feature has been activated.\
*Realm:* Client and Server\
*Added in:* 1.2.2

### plymeta:IsSameTeam(target)
Whether the player is on the same team as the target.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *target* - The other player whose team is being compared

### plymeta:IsScoreboardInfoOverridden(target)
Whether the player is currently overriding a piece of scoreboard information.\
*Realm:* Client\
*Added in:* 1.5.15\
*Parameters:*
- *target* - The player whose scoreboard info is being rendered

*Returns:*
- *isNameOverridden* - Whether the player name is currently overridden
- *isRoleOverridden* - Whether the role color or icon is currently overridden

### plymeta:IsShopRole()
Whether the player has a shop (see `plymeta:CanUseShop` for determining if it is openable).\
*Realm:* Client and Server\
*Added in:* 1.0.0

### plymeta:IsTargetHighlighted(target)
Whether the target player is highlighted based the player's role rules.\
*Realm:* Client\
*Added in:* 1.5.15\
*Parameters:*
- *target* - The player whose scoreboard info is being rendered

### plymeta:IsTargetIDOverridden(target, showJester)
Whether the player is currently overriding a piece of target ID information.\
*Realm:* Client\
*Added in:* 1.5.15\
*Parameters:*
- *target* - The player whose scoreboard info is being rendered
- *showJester* - Whether the target is a jester and the local player would normally know that

*Returns:*
- *isIconOverridden* - Whether the target ID role icon is currently overridden
- *isRingOverridden* - Whether the target ID identification ring is currently overridden
- *isTextOverridden* - Whether the target ID text is currently overridden

### plymeta:IsTraitorTeam()
Whether the player is on the traitor team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### plymeta:IsVampireAlly()/plymeta:GetVampireAlly()
Whether the player is allied with the vampire role.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### plymeta:IsVampirePrime()/plymeta:GetVampirePrime()
Whether the player is the prime (e.g. first-spawned) vampire.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### plymeta:IsVictimChangingRole(victim)
Whether victims killed by this player are changing their role.\
*Realm:* Client and Server\
*Added in:* 1.9.12\
*Parameters:*
- *victim* - The player who was killed by this player

### plymeta:IsZombieAlly()/plymeta:GetZombieAlly()
Whether the player is allied with the zombie role.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### plymeta:IsZombiePrime()/plymeta:GetZombiePrime()
Whether the player is the prime (e.g. first-spawned) zombie.\
*Realm:* Client and Server\
*Added in:* 1.0.0

### plymeta:IsZombifying()
Whether the player is in the process of respawning as a zombie.\
*Realm:* Client and Server\
*Added in:* 1.5.12

### plymeta:MoveRoleState(target, keepOnSource)
Moves role state data (such as promotion and monster prime status) to the target.\
*Realm:* Client and Server\
*Added in:* 1.0.5\
*Parameters:*
- *target* - The player to move the role state data to
- *keepOnSource* - Whether the source player should also keep the role state data (Defaults to `false`)

### plymeta:PrintMessageQueue()
Begins printing messages from the message queue if it's not already. Automatically called by `plymeta:QueueMessage`.\
*Realm:* Server\
*Added in:* 1.9.4

### plymeta:QueueMessage(message_type, message, time, id, predicate)
Queues a message to be shown to the player. Useful in situations where multiple center-screen messages could be shown at the same time and overlapped. This ensures each message is shown in order without overlap.\
*Realm:* Client and Server\
*Added in:* 1.9.4\
*Parameters:*
- *message_type* - The [MSG_PRINT*](GLOBAL_ENUMERATIONS.md#msg_print) value representing the display target for this message
- *message* - The message being shown
- *time* - The amount of time to display the message in the center of the screen. Only used when *message_type* is *MSG_PRINTBOTH* or *MSG_PRINTCENTER* (Optional. Defaults to 5 seconds if not provided)
- *id* - An identifier string that can be used to clear the message or remove it from the queue (Optional) *(Added in 2.2.1)*
- *predicate* - Predicate function called with the player as the sole parameter before the message is sent. Return *true* to allow the message or *false* to prevent it (Optional) *(Added in 2.0.5)* *(Only available on the server realm)*

### plymeta:RemoveEquipmentItem(item_id)
Removes the equipment item with given ID from this player.\
*Realm:* Server\
*Added in:* 2.1.1\
*Parameters:*
- *item_id* - The ID of the item being removed from this player

### plymeta:ResetMessageQueue()
Clears the message queue for the player.\
*Realm:* Server\
*Added in:* 1.9.4

### plymeta:ResetPlayerScale()
Reset's the players size to default by adjusting models, step sizes, hulls and view offsets.\
*Realm:* Server\
*Added in:* 1.3.1

### plymeta:RespawnAsZombie(prime)
Respawns the player as a zombie after a 3 second delay.\
*Realm:* Server\
*Added in:* 1.5.12\
*Parameters:*
- *prime* - Whether to mark the respawning player as the prime zombie *(Added in 1.6.15)*

### plymeta:SetDefaultCredits(keep_existing)
Sets the credits on the player based on their role's starting credits convars.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *keep_existing* - Whether to keep the player's existing credits (Defaults to `false`) *(Added in 1.6.2)*

### plymeta:SetInvulnerable(invulnerable, play_sound)
Controls if the player should be invulnerable or not.\
*Realm:* Server\
*Added in:* 2.1.17\
*Parameters:*
- *invulnerable* - `true` to enable invulnerability, `false` to disable
- *play_sound* - Whether to play sound effects or not

### plymeta:SetPlayerScale(scale)
Sets the player's size by adjusting models, step sizes, hulls and view offsets.\
*Realm:* Server\
*Added in:* 1.3.1\
*Parameters:*
- *scale* - The value with which to scale the players size, relative to their current size.

### plymeta:SetProperty(name, value, targets)
Sets the value of the property with the given `name` on this player to equal `value` and then synchronizes that value to all `targets`. Wrapper around [SYNC:SetPlayerProperty](METHODS_SYNC.md#syncsetplayerpropertyply-propertyname-propertyvalue-targets).\
*Realm:* Server\
*Added in:* 2.1.18\
*Parameters:*
- *name* - The name of the property being set.
- *value* - The value the property is being set to.
- *targets* - The targets that should have this value available on their clients. *(Defaults to sending to all players)*

### plymeta:SetRoleAndBroadcast(role)
Sets the player's role to the given one and (if called on the server) broadcasts the change to all clients for scoreboard tracking.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *role* - The role number to set this player to

### plymeta:SetSprinting(sprinting)
Sets whether the player is currently sprinting.\
*Realm:* Client and Server\
*Added in:* 1.8.8
*Parameters:*
- *sprinting* - Whether the player is sprinting

### plymeta:SetSprintStamina(stamina)
Sets the player's current sprint stamina.\
*Realm:* Client and Server\
*Added in:* 1.8.8
*Parameters:*
- *stamina* - The player's new sprint stamina

### plymeta:SetVampirePreviousRole(previousRole)
Sets the player's previous role for when they are turned into a vampire.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *previousRole* - The previous role this player had before becoming a vampire

### plymeta:SetVampirePrime(isPrime)
Sets whether the player is a prime (e.g. first-spawned) vampire.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *isPrime* - Whether the player is a prime vampire

### plymeta:SetZombiePrime(isPrime)
Sets whether the player is a prime (e.g. first-spawned) zombie.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *isPrime* - Whether the player is a prime zombie

### plymeta:ShouldActLikeJester()
Whether the player should act like a jester (e.g. in what damage they do, what damage they take, how they appear to other players, etc.).\
*Realm:* Client and Server\
*Added in:* 1.2.5

### plymeta:ShouldDelayShopPurchase()
Whether the player's shop purchase deliveries should be delayed.\
*Realm:* Client and Server\
*Added in:* 1.2.2

### plymeta:ShouldHideJesters()
Whether the player should hide a jester player's role (in radar, on the scoreboard, in target ID, etc.).\
*Realm:* Client and Server\
*Added in:* 1.2.5

### plymeta:ShouldNotDrown()
Whether the player should not show the drown effect or take drowning damage.\
*Realm:* Client and Server\
*Added in:* 1.5.7

### plymeta:ShouldRevealBeggar(tgt)
Whether the player should reveal the fact that the target player is no longer a beggar (e.g. converted to an innocent or traitor).\
*Realm:* Client and Server\
*Added in:* 1.2.5\
*Parameters:*
- *tgt* - The target player beggar. If a value is not provided, the context player will be used instead (e.g. `ply:ShouldRevealBeggar()` is the same as `ply:ShouldRevealBeggar(ply)`)

### plymeta:ShouldRevealBodysnatcher(tgt)
Whether the player should reveal the fact that the target player is no longer a bodysnatcher (e.g. has snatched a role from a dead body).\
*Realm:* Client and Server\
*Added in:* 1.2.5\
*Parameters:*
- *tgt* - The target player bodysnatcher. If a value is not provided, the context player will be used instead (e.g. `ply:ShouldRevealBodysnatcher()` is the same as `ply:ShouldRevealBodysnatcher(ply)`)

### plymeta:ShouldRevealRoleWhenActive()
Whether this player should have their role revealed (over their head, on the scoreboard, etc.) when their role is active.\
*Realm:* Client and Server\
*Added in:* 1.9.9

### plymeta:ShouldShowSpectatorHUD()
Whether this player should currently be shown a spectator HUD. Used for things like the Phantom and Parasite spectator HUDs.\
*Realm:* Client and Server\
*Added in:* 1.3.1

### plymeta:SoberDrunk(team)
Runs the logic for when a drunk sobers up and remembers their role.\
*Realm:* Server\
*Added in:* 1.1.9\
*Parameters:*
- *team* - Which team to choose a role from (see ROLE_TEAM_* global enumeration)

### plymeta:StopRespawning()
Stops the player from respawning due to a role feature.\
*Realm:* Server\
*Added in:* 2.1.12

*Returns:* `true` if a respawn was stopped, `false` otherwise.

### plymeta:StripRoleWeapons()
Strips all weapons from the player whose `Category` property matches the global `WEAPON_CATEGORY_ROLE` value.\
*Realm:* Client and Server\
*Added in:* 1.0.5