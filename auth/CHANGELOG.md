# 0.9.4

- add `UserMetadata.lastRefreshTime` (last ID token refresh, null when unknown)
- add `DecodedIdToken.signInProvider` (the `firebase.sign_in_provider` claim,
  for example `firebaseAuthAnonymousProviderId`, null when unknown)
- add `FirebaseAuthLocalIdTokenMixin` and `FirebaseUserLocalIdTokenMixin`: the
  local backends (local, sembast, sdb, sim) give the uid as the ID token of
  their users and `verifyIdToken` accepts it while the user exists

# 0.9.3

- add `FirebaseUser.linkWithCredential` and `FirebaseAuthEmailPasswordCredential`
- add `FirebaseAuthLocalAdmin.linkUserWithCredential` (sdb, sembast, sim)

# 0.9.2

- add `sendPasswordResetEmail`

# 0.5.0+1

- add `getUser` and `getUserByEmail`