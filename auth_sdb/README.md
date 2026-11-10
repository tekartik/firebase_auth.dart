# tekartik_firebase_auth_sdb

A local backend of [tekartik_firebase_auth](../auth/README.md) storing the
users and the signed in user in an sdb database (`idb_shim`): in memory for
tests, IndexedDB on the web, sembast or sqflite in a Flutter app.
Email/password and anonymous sign in, plus an admin API to seed, list and
inspect users. No network.

Runs everywhere (Dart VM, Flutter, web). It is the local backend to pick for
an app; `tekartik_firebase_auth_sembast` is its sembast twin.

## Getting started

Git package, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_auth_sdb:
    git:
      url: https://github.com/tekartik/firebase_auth.dart
      path: auth_sdb
  tekartik_firebase_local:
    git:
      url: https://github.com/tekartik/firebase.dart
      path: firebase_local
```

```dart
import 'package:idb_shim/sdb.dart';
import 'package:tekartik_firebase_auth_sdb/auth_sdb.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

Future<void> main() async {
  // A local app, the database is `auth.db` under its local path.
  var app = newFirebaseMemory().initializeApp();
  var authService = FirebaseAuthServiceSdb(sdbFactory: newSdbFactoryMemory());
  var auth = authService.auth(app) as FirebaseAuthSdb;

  await auth.createUser(
    FirebaseAuthCreateUserRequest(email: 'bob@example.com', password: 'p1'),
  );
  await auth.signInWithEmailAndPassword(
    email: 'bob@example.com',
    password: 'p1',
  );
  print(auth.currentUser?.email); // bob@example.com
  print((await auth.listUsers()).users.length); // 1

  await auth.signOut();
  print(auth.currentUser); // null
  await app.delete();
}
```

`newFirebaseAuthSdbMemory()` does the same in one call (a new memory app
each time), handy in a test.

## Platforms

| Target | sdb factory |
|---|---|
| tests, Dart VM, web | `sdbFactoryMemory` / `newSdbFactoryMemory()` (in memory) |
| web | `sdbFactoryWeb` (IndexedDB, `package:idb_shim/sdb.dart`) |
| Flutter app | `getSdbFactory(packageName: ...)` of `tekartik_app_flutter_idb` |

## What to know

* The app must be a local app (`FirebaseLocal().initializeApp()`,
  `newFirebaseMemory().initializeApp()`, `newFirebaseAppLocal()`): the
  service asserts it.
* With a persistent factory the session survives a restart: the signed in
  user comes back (`await auth.onCurrentUser.first`).
* Cast to `FirebaseAuthSdb` for the admin API: `createUser`, `setUser`,
  `getUser`, `getUserByEmail`, `getUsers`, `listUsers` (pages ordered by uid,
  the last page has no page token), `deleteUser`, `onUserRecord`.
* `currentUser` is set when a sign in, a sign out or the deletion of the
  signed in user completes; `onCurrentUser` emits once per change.
* Errors are `StateError`s named like the Firebase codes:
  `user-not-found`, `wrong-password`, `email-already-exists`,
  `uid-already-exists`.
* Local only, not a security boundary: passwords are stored in clear, a user
  without password (created without one, or by `setUser`) signs in with any
  password, a disabled user signs in too, the id token is the uid.
* `setUser(uid, email: ...)` deletes any other user holding that email.
* The database is not closed when the app is deleted.

The [tekartik-firebase-auth-sdb-local-auth skill](skills/tekartik-firebase-auth-sdb-local-auth/SKILL.md)
has more examples (Flutter app, tests, widget tests).
