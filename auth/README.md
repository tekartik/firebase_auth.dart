# tekartik_firebase_auth

Platform neutral Firebase Auth API: sign in and out (email/password,
anonymous, providers), the current user and its changes, ID tokens, and the
admin user lookups. The same code runs on Flutter, REST, node, the admin SDK
and in memory (tests): pick the backend in the app.

This package has no backend of its own, see [Backends](#backends).

## Getting started

Git package, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_auth:
    git:
      url: https://github.com/tekartik/firebase_auth.dart
      path: auth
```

The in memory backend (sembast), for tests and tools:

```yaml
dev_dependencies:
  tekartik_firebase_auth_sembast:
    git:
      url: https://github.com/tekartik/firebase_auth.dart
      path: auth_sembast
```

```dart
// Re-exports package:tekartik_firebase_auth/auth.dart.
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';

Future<void> main() async {
  // In memory: swap for the service of your platform (see below).
  var auth = newFirebaseAuthMemory();

  var credential = await auth.createUserWithEmailAndPassword(
    email: 'alex@example.com',
    password: 'a password',
  );
  print(credential.user.email); // alex@example.com

  // React to sign in and sign out.
  var subscription = auth.onCurrentUser.listen((User? user) {
    print(user == null ? 'signed out' : 'signed in ${user.email}');
  });
  await auth.signOut();
  await auth.signInWithEmailAndPassword(
    email: 'alex@example.com',
    password: 'a password',
  );
  await subscription.cancel();
  await auth.app.delete();
}
```

## Backends

A `FirebaseAuth` always comes from a `FirebaseAuthService`:
`authService.auth(app)` (one instance per app, also returned by
`app.auth()`).

| Backend | Package (repo, path) | Service | Runs on |
|---|---|---|---|
| In memory (sembast) | `tekartik_firebase_auth_sembast` (firebase_auth.dart, `auth_sembast`) | `newFirebaseAuthServiceMemory()` (`newFirebaseAuthMemory()` for a ready auth) | everywhere (tests) |
| In memory or IndexedDB (sdb) | `tekartik_firebase_auth_sdb` (firebase_auth.dart, `auth_sdb`) | `FirebaseAuthServiceSdb(sdbFactory: ...)`, `newFirebaseAuthServiceSdbMemory()` | everywhere |
| Flutter | `tekartik_firebase_auth_flutter` (firebase_flutter, `auth_flutter`) | `firebaseAuthServiceFlutter` | Flutter (firebase_auth) |
| REST | `tekartik_firebase_auth_rest` (firebase_rest.dart, `auth_rest`) | `firebaseAuthServiceRest` | Dart VM, web |
| Node | `tekartik_firebase_auth_node` (firebase_node.dart, `auth_node`) | `authServiceNode` | node, Cloud Functions |
| Admin SDK | `tekartik_firebase_admin_sdk` (firebase_admin_sdk.dart, `firebase_admin_sdk`) | `firebaseAuthServiceAdminSdk` | Dart VM server |

All the repos are under `https://github.com/tekartik/`. The local backends
(sembast, sdb, sim, local) also implement `FirebaseAuthLocalAdmin` to seed
users in tests.

## When to use what

* `package:tekartik_firebase_auth/auth.dart`: the client API
  (`FirebaseAuth`, `User`, `UserCredential`, `UserRecord`...). It re-exports
  `package:tekartik_firebase/firebase.dart`.
* `currentUser` is a snapshot, `null` until the backend restored the session:
  listen to `onCurrentUser` (it gives the latest value to a new listener).
* `signInWithEmailAndPassword`, `createUserWithEmailAndPassword`,
  `signInAnonymously`, `signIn(provider)`, `signOut`.
* `sendPasswordResetEmail`, `sendEmailVerification`, `reloadCurrentUser`.
* ID token for your server: `(user as UserInfoWithIdToken).getIdToken()`,
  checked server side with `verifyIdToken`.
* Admin lookups (`getUser`, `getUserByEmail`, `listUsers`) when
  `auth.service.supportsListUsers`; `package:tekartik_firebase_auth/auth_admin.dart`
  for `createUser`/`deleteUser`.
* Backend authors: the mixins of `auth_mixin.dart`, the shared tests of
  `tekartik_firebase_auth_test`.

## Common pitfalls

* An unsupported operation throws `UnsupportedError` (on the default mixin,
  `createUserWithEmailAndPassword` throws `UnimplementedError`).
* `signInOrUpWithEmailAndPassword` creates the account after any sign in
  failure, a wrong password included: the error you get is then the creation
  one ("already exists"). Do not use it in a login screen.
* `FirebaseAuthAdminExt.getOrCreateUser` needs an email when the user is not
  found by uid (it throws a `StateError` otherwise).
* The ID token of the local backends is the uid itself: unsigned, for tests
  only.
* Errors are backend specific (native `FirebaseAuthException`, REST errors...):
  display `e.toString()` rather than matching types.

## Skills

* [API](skills/tekartik-firebase-auth-api/SKILL.md): sign in, current user,
  ID tokens, admin lookups.
* [Backends](skills/tekartik-firebase-auth-backend/SKILL.md): implementing a
  backend, admin API, seeding local backends, shared tests.
