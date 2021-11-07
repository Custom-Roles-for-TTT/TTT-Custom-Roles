## Player Object
Methods available when called from a Player object (within the defined realm)

**plymeta:BeginRoleChecks()** - Sets up role logic for the player to handle role-specific events and checks.\
*Realm:* Server\
*Added in:* 1.1.9

**plymeta:Celebrate(snd, showConfetti)** - Plays a celebration effect (sound and or confetti) at the player's location.\
*Realm:* Client\
*Added in:* 1.3.1\
*Parameters:*
- *snd* - What sound to play (if any) as part of this celebration
- *showConfetti* - Whether to show confetti as part of this celebration

**plymeta:Is{RoleName}()/plymeta:Get{RoleName}()** - Dynamically created functions for each role that returns whether the player is that role. For example: `plymeta:IsTraitor()` and `plymeta:IsPhantom()` return whether the player is a traitor or a phantom, respectively.\
*Realm:* Client and Server\
*Added in:* Whenever each role is added

**plymeta:IsActive{RoleName}()** - Dynamically created functions for each role that returns whether `plymeta:Is{RoleName}` returns `true` and the player is active. For example: `plymeta:IsActiveTraitor()` and `plymeta:IsActivePhantom()` return whether the player is active and a traitor or a phantom, respectively.\
*Realm:* Client and Server\
*Added in:* Whenever each role is added

**plymeta:IsActiveCustom()** - Whether `plymeta:IsCustom` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsActiveDetectiveLike()** - Whether `plymeta:IsActiveDetectiveLike` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsActiveIndependentTeam()** - Whether `plymeta:IsIndependentTeam` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsActiveInnocentTeam()** - Whether `plymeta:IsInnocentTeam` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsActiveJesterTeam()** - Whether `plymeta:IsJesterTeam` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsActiveMonsterTeam()** - Whether `plymeta:IsMonsterTeam` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsActiveTraitorTeam()** - Whether `plymeta:IsTraitorTeam` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsActiveShopRole()** - Whether `plymeta:IsActiveShopRole` returns `true` and the player is active.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:CanLootCredits(activeOnly)** - Whether the player can loot credits from a corpse that has them.\
*Realm:* Client and Server\
*Added in:* 1.0.5\
*Parameters:*
- *activeOnly* - Whether the player must also be active (Defaults to `false`)

**plymeta:CanUseShop()** - Whether the player can currently open the shop menu.\
*Realm:* Client and Server\
*Added in:* 1.0.2

**plymeta:CanUseTraitorButton(activeOnly)** - Whether the player can see and use traitor buttons.\
*Realm:* Client and Server\
*Added in:* 1.0.5\
*Parameters:*
- *activeOnly* - Whether the player must also be active (Defaults to `false`)

**plymeta:GetHeight()** - Gets the *estimated* height of the player based on their player model.\
*Realm:* Client\
*Added in:* 1.0.2

**plymeta:GetRoleTeam(detectivesAreInnocent)** - Gets which "role team" a player belongs to (see ROLE_TEAM_* global enumeration).\
*Realm:* Client and Server\
*Added in:* 1.2.7\
*Parameters:*
- *detectivesAreInnocent* - Whether to include members of the detective "role team" in the innocent "role team" to match the logical teams

**plymeta:GetVampirePreviousRole()** - Gets the player's previous role if they are a Vampire that has been converted or `ROLE_NONE` otherwise.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:GiveDelayedShopItems()** - Give the player their shop items that were being held due to the role having a delayed shop.\
*Realm:* Server\
*Added in:* 1.2.2

**plymeta:HandleDetectiveLikePromotion()** - Handles the player's promotion as a detective-like role (deputy/impersonator). Promotes the player and sends necessary net events.\
*Realm:* Server\
*Added in:* 1.2.5

**plymeta:IsCustom()** - Whether the player's role is not one of the three default TTT roles.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsDetectiveLike()/plymeta:GetDetectiveLike()** - Whether the player's role is like a detective (e.g. detective or promoted deputy/impersonator).\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsDetectiveLikePromotable()/plymeta:GetDetectiveLikePromotable()** - Whether the player's role is an unpromoted detective-like role (deputy/impersonator).\
*Realm:* Client and Server\
*Added in:* 1.2.5

**plymeta:IsIndependentTeam()** - Whether the player is on the independent team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsInnocentTeam()** - Whether the player is on the innocent team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsJesterTeam()** - Whether the player is on the jester team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsMonsterTeam()** - Whether the player is on the monster team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsRoleActive()** - Whether the player's role feature has been activated.\
*Realm:* Client and Server\
*Added in:* 1.2.2

**plymeta:IsSameTeam(target)** - Whether the player is on the same team as the target.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *target* - The other player whose team is being compared

**plymeta:IsShopRole()** - Whether the player has a shop (see `plymeta:CanUseShop` for determining if it is openable).\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsTraitorTeam()** - Whether the player is on the traitor team.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsVampireAlly()/plymeta:GetVampireAlly()** - Whether the player is allied with the vampire role.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsVampirePrime()/plymeta:GetVampirePrime()** - Whether the player is the prime (e.g. first-spawned) vampire.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsZombieAlly()/plymeta:GetZombieAlly()** - Whether the player is allied with the zombie role.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:IsZombiePrime()/plymeta:GetZombiePrime()** - Whether the player is the prime (e.g. first-spawned) zombie.\
*Realm:* Client and Server\
*Added in:* 1.0.0

**plymeta:MoveRoleState(target, keepOnSource)** - Moves role state data (such as promotion and monster prime status) to the target.\
*Realm:* Client and Server\
*Added in:* 1.0.5\
*Parameters:*
- *target* - The player to move the role state data to
- *keepOnSource* - Wheter the source player should also keep the role state data (Defaults to `false`)

**plymeta:SetRoleAndBroadcast(role)** - Sets the player's role to the given one and (if called on the server) broadcasts the change to all clients for scoreboard tracking.\
*Realm:* Client and Server\
*Added in:* 1.0.0\
*Parameters:*
- *role* - The role number to set this player to

**plymeta:SetVampirePreviousRole(previousRole)** - Sets the player's previous role for when they are turned into a vampire.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *previousRole* - The previous role this player had before becoming a vampire

**plymeta:SetVampirePrime(isPrime)** - Sets whether the player is a prime (e.g. first-spawned) vampire.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *isPrime* - Whether the player is a prime vampire

**plymeta:SetZombiePrime(isPrime)** - Sets whether the player is a prime (e.g. first-spawned) zombie.\
*Realm:* Server\
*Added in:* 1.0.0\
*Parameters:*
- *isPrime* - Whether the player is a prime zombie

**plymeta:ShouldActLikeJester()** - Whether the player should act like a jester (e.g. in what damage they do, what damage they take, how they appear to other players, etc.).\
*Realm:* Client and Server\
*Added in:* 1.2.5

**plymeta:ShouldDelayAnnouncements()** - Whether this role should delay announcements when they kill a player that shows a message (like phantom and parasite). Used for things like preventing the assassin's target update message from getting overlapped.\
*Realm:* Client and Server\
*Added in:* 1.2.7

**plymeta:ShouldDelayShopPurchase()** - Whether the player's shop purchase deliveries should be delayed.\
*Realm:* Client and Server\
*Added in:* 1.2.2

**plymeta:ShouldHideJesters()** - Whether the player should hide a jester player's role (in radar, on the scoreboard, in target ID, etc.).\
*Realm:* Client and Server\
*Added in:* 1.2.5

**plymeta:ShouldRevealBeggar(tgt)** - Whether the player should reveal the fact that the target player is no longer a beggar (e.g. converted to an innocent or traitor).\
*Realm:* Client and Server\
*Added in:* 1.2.5\
*Parameters:*
- *tgt* - The target player beggar. If a value is not provided, the context player will be used instead (e.g. `ply:ShouldRevealBeggar()` is the same as `ply:ShouldRevealBeggar(ply)`)

**plymeta:ShouldRevealBodysnatcher(tgt)** - Whether the player should reveal the fact that the target player is no longer a bodysnatcher (e.g. has snatched a role from a dead body).\
*Realm:* Client and Server\
*Added in:* 1.2.5\
*Parameters:*
- *tgt* - The target player bodysnatcher. If a value is not provided, the context player will be used instead (e.g. `ply:ShouldRevealBodysnatcher()` is the same as `ply:ShouldRevealBodysnatcher(ply)`)

**plymeta:ShouldShowSpectatorHUD()** - Whether this player should currently be shown a spectator HUD. Used for things like the Phantom and Parasite spectator HUDs.\
*Realm:* Client and Server\
*Added in:* 1.3.1

**plymeta:SoberDrunk(team)** - Runs the logic for when a drunk sobers up and remembers their role.\
*Realm:* Server\
*Added in:* 1.1.9\
*Parameters:*
- *team* - Which team to choose a role from (see ROLE_TEAM_* global enumeration)

**plymeta:DrunkRememberRole(role)** - Sets the drunk's role and runs required checks for that role.\
*Realm:* Server\
*Added in:* 1.1.9\
*Parameters:*
- *role* - Which role to set the drunk to (see ROLE_* global enumeration)

**plymeta:StripRoleWeapons()** - Strips all weapons from the player whose `Category` property matches the global `WEAPON_CATEGORY_ROLE` value.\
*Realm:* Client and Server\
*Added in:* 1.0.5

**plymeta:SetPlayerScale(scale)** - Set's the players size by adjusting models, step sizes, hulls and view offsets.\
*Realm:* Server\
*Added in:* 1.3.1\
*Parameters:*
- *scale* - The value with which to scale the players size, relative to their current size.

**plymeta:ResetPlayerScale()** - Reset's the players size to default by adjusting models, step sizes, hulls and view offsets.\
*Realm:* Server\
*Added in:* 1.3.1