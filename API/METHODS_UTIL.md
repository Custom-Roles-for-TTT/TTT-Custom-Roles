# Utility Methods
Utility methods created to help with various common scenarios

### util.BurnRagdoll(rag, burn_time, scorch)
Burns a player ragdoll, shows scorch marks, and automatically destroys the ragdoll unless it's been extinguished by water.\
*Realm:* Server\
*Added in:* 1.9.1\
*Parameters:*
- *rag* - The `prop_ragdoll` to set on fire
- *burn_time* - How long the ragdoll should burn for before being destroyed
- *scorch* - Whether scorch marks should be created under the ragdoll (Defaults to `true`)

### util.CanRoleSpawn(role)
Returns whether a role can be spawned either naturally at the start of a round or artificially.\
*Realm:* Client and Server\
*Added in:* 1.9.5\
*Parameters:*
- *role* - The role ID in question

### util.CanRoleSpawnArtificially(role)
Returns whether a role can be spawned artificially. (i.e. Spawned in a way other than naturally spawning when the role is enabled.)\
*Realm:* Client and Server\
*Added in:* 1.9.5\
*Parameters:*
- *role* - The role ID in question
- 
### util.CanRoleSpawnNaturally(role)
Returns whether a role can be spawned naturally. (i.e. Spawned in at the start of the round if they are enabled or used in a role pack.)\
*Realm:* Client and Server\
*Added in:* 2.0.7\
*Parameters:*
- *role* - The role ID in question

### util.ExecFile(filePath, errorIfMissing)
Executes a file at the given path, relative to the root game location.\
*Realm:* Server\
*Added in:* 1.6.7\
*Parameters:*
- *filePath* - The path to the file to be executed, relative to the root game location
- *errorIfMissing* - Whether to throw an error if the file is missing (Defaults to `false`)