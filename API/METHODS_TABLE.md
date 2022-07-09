# Table Methods
Methods created to help with the manipulation of tables

### table.ExcludedKeys(tbl, excludes)
Returns new table that contains the keys not present as values in in the given exclude table.\
*Realm:* Client and Server\
*Added in:* 1.2.3
*Parameters:*
- *tbl* - The table whose keys are being inspected
- *excludes* - Table of values to exclude

### table.IntersectedKeys(first_tbl, second_tbl, excludes)
Returns new table that contains the keys that are only present in both given tables, excluding those which appear as values in the given exclude table (if it is given).\
*Realm:* Client and Server\
*Added in:* 1.2.3
*Parameters:*
- *first_tbl* - The first table whose keys are being intersected
- *second_tbl* - The second table whose keys are being intersected
- *excludes* - Table of values to exclude from the intersect. (Optional)

### table.LookupKeys(tbl)
Returns new table that contains the keys that have a truth-y value in the given table.\
*Realm:* Client and Server\
*Added in:* 1.2.3
*Parameters:*
- *tbl* - The table whose keys are being inspected

### table.ToLookup(tbl)
Returns a new table whose keys are the values of the given table and whose values are all the literal boolean `true`. Used for fast lookups by key.\
*Realm:* Client and Server\
*Added in:* 1.2.3
*Parameters:*
- *tbl* - The table whose keys are being inspected

### table.UnionedKeys(first_tbl, second_tbl, excludes)
Returns new table that contains a combination of the keys present in first table and the second table, excluding those which appear as values in the given exclude table (if it is given).\
*Realm:* Client and Server\
*Added in:* 1.2.3
*Parameters:*
- *first_tbl* - The first table whose keys are being unioned
- *second_tbl* - The second table whose keys are being unioned
- *excludes* - Table of values to exclude from the union. (Optional)