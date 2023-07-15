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

### util.ExecFile(filePath, errorIfMissing)
Executes a file at the given path, relative to the root game location.\
*Realm:* Server\
*Added in:* 1.6.7\
*Parameters:*
- *filePath* - The path to the file to be executed, relative to the root game location
- *errorIfMissing* - Whether to throw an error if the file is missing (Defaults to `false`)