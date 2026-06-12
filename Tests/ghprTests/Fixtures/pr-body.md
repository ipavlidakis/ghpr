### Motivation:

SwiftPM materializes dependency working copies via `git clone --shared` from a bare mirror in a shared cache (`~/Library/Caches/org.swift.swiftpm`). If this clone is interrupted (e.g. by a crash, force quit, etc...) then only part of the git tree is copied, leaving an incomplete object store. During subsequent resolution attempts SwiftPM assumes that if the shared cache copy exists then it's valid, and if the information for the commit its looking for never made it in to the bare mirror then it fails with an error like `"unable to read tree <sha>"`.

### Modifications:

Add `withObjectStoreRecovery` and pipe through git-resolving operations through it so that if we see an error that matches the "corrupt object store" pattern, we purge the repository from both the working location and the shared cache and then retry. If, after the retry, we still get an error then we pass that through. 

### Result:

SwiftPM can recover from a partial clone of its mirrored repo. This approach means we aren't adding any cost to the happy-path and we can recover from these types of errors without user intervention.

We pattern match against the following types of git errors to determine if we want to purge and retry fetching the mirrored repository:

```
"unable to read tree"
"not a tree object"
"not a valid object name"
"bad object"
"is corrupt"
"object file"
"missing blob object"
"missing tree object"
"missing commit object"
```
