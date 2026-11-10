# tekartik_firebase_auth_sembast

A local backend of [tekartik_firebase_auth](../auth/README.md) storing the
users and the signed in user in a [sembast](https://pub.dev/packages/sembast)
database: in memory for tests, in a file for an offline Dart program or a
simulator. Email/password and anonymous sign in, plus an admin API to seed and
inspect users. No network.

Runs everywhere sembast runs (Dart VM, Flutter, web with `sembast_web`). For
new app code prefer the sdb sibling `tekartik_firebase_auth_sdb` (same API,
IndexedDB on the web, also lists the users).

## Getting started

Git package, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_auth_sembast:
    git:
      url: https://github.com/tekartik/firebase_auth.dart
      path: auth_sembast
  tekartik_firebase_local:
    git:
      url: https://github.com/tekartik/firebase.dart
      path: firebase_local
  sembast: any
```

```dart
import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

Future<void> main() async {
  // A local app, the database is `auth.db` under its local path.
  var app = newFirebaseMemory().initializeApp();
  var authService = FirebaseAuthServiceSembast(
    databaseFactory: newDatabaseFactoryMemory(),
  );
  var auth = authService.auth(app);

  await auth.createUserWithEmailAndPassword(
    email: 'bob@example.com',
    password: 'password1',
  );
  print(auth.currentUser?.email); // bob@example.com

  await auth.signOut();
  print(auth.currentUser); // null
  await app.delete();
}
```

`newFirebaseAuthMemory()` does the same in one call (a new memory app and
database each time), handy in a test.

## What to know

* The app must be a local app (`FirebaseLocal().initializeApp()`,
  `newFirebaseMemory().initializeApp()`, `newFirebaseAppLocal()`): the
  service asserts it.
* `databaseFactoryIo` (`package:sembast/sembast_io.dart`) persists the users
  and the session: the signed in user is restored at the next start
  (`await auth.onCurrentUser.first`).
* Cast to `FirebaseAuthSembast` for the admin API: `createUser`, `setUser`,
  `getUser`, `getUserByEmail`, `getUsers`, `deleteUser`, `onUserRecord`.
* `currentUser` is set when a sign in, a sign out or the deletion of the
  signed in user completes; `onCurrentUser` emits once per change.
* Errors are `StateError`s named like the Firebase codes:
  `user-not-found`, `wrong-password`, `email-already-exists`,
  `uid-already-exists`.
* Local only, not a security boundary: passwords are stored in clear, a user
  without password (created without one, or by `setUser`) signs in with any
  password, a disabled user signs in too, the id token is the uid.
* `setUser(uid, email: ...)` deletes any other user holding that email.
* `listUsers` is not supported (`supportsListUsers` is false); nothing is sent
  by `sendPasswordResetEmail` (it checks the user exists).
* The database is not closed when the app is deleted.

The [tekartik-firebase-auth-sembast-local-auth skill](skills/tekartik-firebase-auth-sembast-local-auth/SKILL.md)
has more examples (persistent auth, tests, the shared auth test suites).
