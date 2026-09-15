---
name: tekartik-firebase-auth-api
description: >-
  Use when signing users in or out, creating email/password or anonymous
  accounts, observing the current user, sending password reset or email
  verification mails, getting an ID token, or looking up UserRecord data
  (getUser, getUserByEmail, listUsers) through the tekartik_firebase_auth
  abstraction (FirebaseAuthService, FirebaseAuth, User, UserCredential),
  whatever the backend (Flutter, REST, node, sembast, sdb, sim, local).
---

# tekartik_firebase_auth API

Backend-independent Firebase Auth abstraction: a `FirebaseAuthService` creates
one `FirebaseAuth` per `FirebaseApp`. The service comes from a sibling package:
`tekartik_firebase_auth_flutter` (`firebaseAuthServiceFlutter`),
`tekartik_firebase_auth_rest` (`firebaseAuthServiceRest`),
`tekartik_firebase_auth_node` (`authServiceNode`), or the in-process
`tekartik_firebase_auth_sembast`, `tekartik_firebase_auth_sdb`,
`tekartik_firebase_auth_sim` and `tekartik_firebase_auth_local`.

## Guidelines

* Import `package:tekartik_firebase_auth/auth.dart`; it re-exports
  `package:tekartik_firebase/firebase.dart` (`Firebase`, `FirebaseApp`,
  `AppOptions`). `package:tekartik_firebase_auth/auth_admin.dart` adds
  `FirebaseAuthAdmin`/`FirebaseAuthLocalAdmin` but does not re-export
  `auth.dart`: import both when you also need `UserRecord` or `FirebaseAuth`.
* Get the instance with `authService.auth(app)` (cached per app) or, once a
  service is bound to the app, `app.auth()`; `app.authOrNull()` returns `null`
  instead of throwing. `FirebaseAuth.instance` resolves the product of
  `FirebaseApp.instance` (default app) and throws when none is registered.
  Prefer passing the `FirebaseAuth` explicitly to services and widgets.
* Use `FirebaseAuth`, `FirebaseAuthService`, `User` (same type as
  `FirebaseUser`), `UserInfo`, `AuthCredential`. `Auth` and `AuthService` are
  legacy aliases: do not use them in new code.
* Check the service capabilities in generic code: `supportsCurrentUser`
  (sign-in, `currentUser`, `onCurrentUser`) and `supportsListUsers`
  (`listUsers`, `getUsers`, `getUser`, `getUserByEmail`). Unsupported members
  throw `UnsupportedError`. Flutter, REST, sembast, sdb and sim report
  `supportsListUsers == false` (sembast/sdb still answer `getUser` and
  `getUserByEmail` through their admin interface, see the backend skill).
* `currentUser` is a synchronous snapshot, `null` until the backend resolved
  the persisted session. React to sign-in state with `onCurrentUser`: it
  replays the latest known value (possibly `null`) to new listeners and emits
  on sign-in, sign-out and, on some backends, token refresh. Wait for the
  initial state with `await auth.onCurrentUser.first`.
* `signInWithEmailAndPassword`, `createUserWithEmailAndPassword` and
  `signInAnonymously` return a `UserCredential` whose `user` is never `null`;
  they update `currentUser` and notify `onCurrentUser`. Failures throw a
  backend-specific exception (native `FirebaseAuthException`, REST or local
  errors): catch, log and display `e.toString()`, do not match on types.
* `signInOrUpWithEmailAndPassword` (extension `TekartikFirebaseAuthExt`)
  signs in and falls back to creating the account, leaving the user signed in.
  `getOrCreateUserWithEmailAndPassword` on a plain `FirebaseAuth` does the same
  then calls `signOut()` and returns only the `FirebaseUser`: use it in setup
  code, never in a login flow.
* `signOut()` completes with `currentUser == null` and `onCurrentUser`
  emitting `null`. `user.delete()` deletes and signs out the account; native
  backends may require a recent login (`requires-recent-login`).
* `sendPasswordResetEmail(email:)` (since 0.9.2) needs no signed-in user.
  `sendEmailVerification()` acts on `currentUser` and throws when nobody is
  signed in. In-process backends (sembast, sdb, sim, local) only check that
  the email exists and send nothing; backends without support throw
  `UnsupportedError`.
* After a server-side change (email verified, profile edit) call
  `reloadCurrentUser()`; `currentUser` is not refreshed on its own.
* To call your own API with a Firebase ID token check
  `user is UserInfoWithIdToken`, then `getIdToken(forceRefresh: true)`.
  Server side, `verifyIdToken(idToken, checkRevoked: true)` returns a
  `DecodedIdToken` (`uid`).
* `signIn(authProvider, options:)` (Google, Facebook...) returns an
  `AuthSignInResult`: when `hasInfo` is `false` (redirect flows) the outcome
  arrives later on `onCurrentUser`, and `credential` may be `null` even on
  success. `AuthProvider` implementations are backend specific
  (`AuthProviderRest`, `AuthLocalProvider`).
* Admin lookups return `UserRecord` (`uid`, `email`, `displayName`,
  `emailVerified`, `disabled`, `isAnonymous`, `customClaims`, `providerData`,
  `metadata` with `creationTime`/`lastSignInTime`), not `User`.
  `listUsers(maxResults:, pageToken:)` pages through `ListUsersResult` until
  `pageToken` is `null`; its `users` entries are nullable and `getUsers` omits
  unknown uids. `userRecordToJson`
  (`package:tekartik_firebase_auth/utils/json_utils.dart`) exports the
  non-empty fields. Field names follow the JS SDK: `photoURL`, `providerId`.
* Do not build sign-in screens directly on this API: use
  `tekartik_firebase_ui_auth` (`FirebaseUiAuthService`), which works with any
  backend. In tests use `newFirebaseAuthSdbMemory()` (sdb) or
  `newFirebaseAuthMemory()` (sembast) instead of mocking `FirebaseAuth`.

## Examples

### Binding a service and signing in

```dart
import 'package:tekartik_firebase_auth/auth.dart';

/// [authService] comes from a backend package, for example
/// `firebaseAuthServiceFlutter` or `FirebaseAuthServiceSdb(sdbFactory: ...)`.
FirebaseAuth initAuth(Firebase firebase, FirebaseAuthService authService) {
  var app = firebase.initializeApp();
  return authService.auth(app); // `app.auth()` works from now on
}

Future<User> signInOrRegister(
  FirebaseAuth auth, {
  required String email,
  required String password,
}) async {
  var credential = await auth.signInOrUpWithEmailAndPassword(
    email: email,
    password: password,
  );
  return credential.user;
}
```

### Observing the current user and getting an ID token

```dart
import 'dart:async';

import 'package:tekartik_firebase_auth/auth.dart';

StreamSubscription<User?> watchUser(FirebaseAuth auth) {
  return auth.onCurrentUser.listen((user) {
    print(user == null ? 'signed out' : 'signed in as ${user.uid}');
  });
}

Future<String?> currentIdToken(FirebaseAuth auth) async {
  var user = await auth.onCurrentUser.first;
  if (user is UserInfoWithIdToken) {
    return await (user as UserInfoWithIdToken).getIdToken();
  }
  return null;
}
```

### Anonymous session, password reset, email verification

```dart
import 'package:tekartik_firebase_auth/auth.dart';

Future<void> guestSession(FirebaseAuth auth) async {
  var credential = await auth.signInAnonymously();
  assert(credential.user.isAnonymous);
  await auth.signOut();
}

Future<String?> requestPasswordReset(FirebaseAuth auth, String email) async {
  try {
    await auth.sendPasswordResetEmail(email: email);
    return null;
  } catch (e) {
    return 'Could not send the reset email: $e';
  }
}

Future<bool> ensureEmailVerified(FirebaseAuth auth) async {
  var user = await auth.reloadCurrentUser();
  if (user == null) {
    return false;
  }
  if (!user.emailVerified) {
    await auth.sendEmailVerification();
  }
  return user.emailVerified;
}
```

### Admin lookups (server side)

```dart
import 'package:tekartik_firebase_auth/auth.dart';
import 'package:tekartik_firebase_auth/utils/json_utils.dart';

Future<List<Map<String, Object?>>> exportUsers(FirebaseAuth auth) async {
  if (!auth.service.supportsListUsers) {
    throw UnsupportedError('listUsers not supported by ${auth.service}');
  }
  var result = <Map<String, Object?>>[];
  String? pageToken;
  do {
    var page = await auth.listUsers(maxResults: 100, pageToken: pageToken);
    for (var record in page.users) {
      if (record != null) {
        result.add(userRecordToJson(record));
      }
    }
    pageToken = page.pageToken;
  } while (pageToken != null);
  return result;
}

Future<String?> findUid(FirebaseAuth auth, String email) async =>
    (await auth.getUserByEmail(email))?.uid;
```
