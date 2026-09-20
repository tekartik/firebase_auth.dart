---
name: tekartik-firebase-auth-sembast-local-auth
description: >-
  Use when a Dart app, test or simulator needs a local email/password and
  anonymous FirebaseAuth backend stored in a sembast database, with
  tekartik_firebase_auth_sembast: FirebaseAuthServiceSembast(databaseFactory:),
  FirebaseAuthSembast, newFirebaseAuthMemory, newFirebaseAuthServiceMemory, the
  admin API (createUser, setUser, getUser, getUserByEmail, deleteUser,
  onUserRecord), signInWithEmailAndPassword/signInAnonymously, and
  firebaseAuthSembastInitDbBuilders / firebaseAuthCurrentUserRecord.
---

# Sembast local auth (tekartik_firebase_auth_sembast)

A `tekartik_firebase_auth` backend (`FirebaseAuth`, `User`, `UserCredential`)
that stores users and the current session in a sembast database - in memory for
tests, on disk for an offline app or a simulator. It also implements
`FirebaseAuthLocalAdmin` / `FirebaseAuthAdmin`, so code can seed and inspect
users directly.

## Guidelines

* Git-only package (not on pub.dev):

  ```yaml
  dependencies:
    tekartik_firebase_auth_sembast:
      git:
        url: https://github.com/tekartik/firebase_auth.dart
        path: auth_sembast
  ```

* Import `package:tekartik_firebase_auth_sembast/auth_sembast.dart`. It
  re-exports `package:tekartik_firebase_auth/auth.dart` (`FirebaseAuth`,
  `FirebaseAuthService`, `User`, `UserRecord`, `UserCredential`,
  `FirebaseAuthCreateUserRequest`, ...). Add
  `package:tekartik_firebase_local/firebase_local.dart` for `FirebaseLocal`,
  `newFirebaseMemory`, `newFirebaseAppLocal`, `FirebaseAppLocal`, and a
  sembast factory library (`package:sembast/sembast_memory.dart` or
  `package:sembast/sembast_io.dart`).
* Build it in two steps:
  `FirebaseAuthServiceSembast(databaseFactory: ...)` then
  `authService.auth(app)`. The app **must** be a `FirebaseAppLocal` (the
  service asserts it): use `FirebaseLocal().initializeApp(name: ...)`,
  `newFirebaseMemory().initializeApp()` or `newFirebaseAppLocal()`. The
  database is `auth.db` under the app `localPath`, so distinct app names or
  local paths keep separate user sets.
* Database factory: `newDatabaseFactoryMemory()` (a *fresh* isolated in-memory
  factory, best for tests) or `databaseFactoryMemory` (shared) from
  `package:sembast/sembast_memory.dart`; `databaseFactoryIo` from
  `package:sembast/sembast_io.dart` to persist on the vm.
* Shortcuts for tests: `newFirebaseAuthServiceMemory()` returns a service on a
  new memory factory, `newFirebaseAuthMemory()` returns a `FirebaseAuth` on a
  new memory app. Each call is fully isolated. Cast the result
  `as FirebaseAuthSembast` to reach the admin API, and
  `await auth.app.delete()` in `tearDown`.
* Admin API on `FirebaseAuthSembast`:
  * `createUser(FirebaseAuthCreateUserRequest(uid:, email:, password:,
    displayName:, emailVerified:, disabled:, phoneNumber:, photoURL:))`
    returns a `UserRecord`; it throws `StateError('uid-already-exists')` or
    `StateError('email-already-exists')`. Without a `uid` one is generated.
  * `setUser(uid, email:, emailVerified:, isAnonymous:)` **replaces** the
    whole record (password, display name and dates are dropped) and first
    deletes any other user with that email. To seed a user with a password
    use `createUser` or the `getOrCreateUserWithEmailAndPassword(email:,
    password:)` extension of `package:tekartik_firebase_auth/auth_admin.dart`.
  * `getUser(uid)`, `getUserByEmail(email)`, `deleteUser(uid)` and
    `onUserRecord(uid)`, a stream that re-emits on every change and `null`
    when the user does not exist.
  * `getSignInWithEmailAndPasswordUserCredential(email:, password:)` and
    `getSignInAnonymouslyUserCredential()` build the credential (creating the
    user if needed) **without** touching `currentUser`.
* Sign-in: `createUserWithEmailAndPassword` creates then signs in;
  `signInWithEmailAndPassword` throws `StateError('user-not-found')` or
  `StateError('wrong-password')` - a user stored without a password (from
  `setUser`) accepts any password. `signInAnonymously()` creates a throw-away
  anonymous user that `signOut()` deletes. `sendPasswordResetEmail(email:)`
  only checks the user exists (`StateError('user-not-found')`), no mail is
  sent.
* The current user is persisted in the same database (store `info`, record
  `currentUser`): with `databaseFactoryIo` the session survives a restart.
  `currentUser` is updated synchronously by sign in/out, `onCurrentUser` emits
  once the database is open and re-emits when the user record changes.
* Unsupported here (they throw `UnsupportedError` from the base mixin):
  `listUsers` (`supportsListUsers` is `false`, `supportsCurrentUser` is
  `true`), `getUsers`, `verifyIdToken`, `signIn(provider)` and
  `sendEmailVerification`. `reloadCurrentUser()` just returns `currentUser`.
* Passwords are stored in clear text in the sembast database: this is a test
  and offline backend, never a security boundary.
* `package:tekartik_firebase_auth_sembast/auth_sembast_mixin.dart` exposes
  `firebaseAuthSembastInitDbBuilders()`, `DbCurrentUser` and
  `firebaseAuthCurrentUserRecord` for code opening the same `auth.db` with cv
  records; the builders are registered automatically when a service is
  created, call the function explicitly only if you read the database before
  that.
* Validate the backend (or a new database factory) with the shared suites of
  `tekartik_firebase_auth_test`: `runAuthTests`, `localAdminTests`,
  `firebaseAuthAdminTests`, `firebaseAuthSignInDeleteTests`. This backend
  passes all four.
* Siblings with the same `FirebaseAuthLocalAdmin` API:
  `tekartik_firebase_auth_sdb` (prefer it in a Flutter app that must also run
  on the web), `tekartik_firebase_auth_local` (pure memory, two fixed users)
  and `tekartik_firebase_auth_sim` (served over the firebase sim protocol).

## Examples

### Persistent local auth in a Dart app

```dart
import 'package:sembast/sembast_io.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

/// Auth persisted in `<localPath>/auth.db`.
FirebaseAuthSembast initAuth() {
  var app = FirebaseLocal().initializeApp(
    name: 'my_app',
    options: FirebaseAppOptions(projectId: 'my-app-local'),
  );
  var authService = FirebaseAuthServiceSembast(
    databaseFactory: databaseFactoryIo,
  );
  return authService.auth(app) as FirebaseAuthSembast;
}

Future<void> main() async {
  var auth = initAuth();
  // The session is restored from the database.
  var user = await auth.onCurrentUser.first;
  if (user == null) {
    await auth.createUserWithEmailAndPassword(
      email: 'user@example.com',
      password: 'password1',
    );
  }
  print('signed in as ${auth.currentUser?.email}');
}
```

### Seeding and signing in users in a test

```dart
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:test/test.dart';

void main() {
  late FirebaseAuthSembast auth;

  setUp(() {
    // Isolated in-memory app + database.
    auth = newFirebaseAuthMemory() as FirebaseAuthSembast;
  });
  tearDown(() => auth.app.delete());

  test('create, sign in, delete', () async {
    var record = await auth.createUser(
      FirebaseAuthCreateUserRequest(
        email: 'user@example.com',
        password: 'password1',
        displayName: 'User',
      ),
    );
    expect((await auth.getUserByEmail('user@example.com'))!.uid, record.uid);
    expect(
      () => auth.createUser(
        FirebaseAuthCreateUserRequest(email: 'user@example.com'),
      ),
      throwsA(isA<StateError>()), // email-already-exists
    );

    var credential = await auth.signInWithEmailAndPassword(
      email: 'user@example.com',
      password: 'password1',
    );
    expect(credential.user.uid, record.uid);
    expect(auth.currentUser?.email, 'user@example.com');

    // setUser replaces the record: no password left, any password signs in.
    await auth.setUser('admin', email: 'admin@example.com', emailVerified: true);
    expect((await auth.getUser('admin'))!.emailVerified, isTrue);

    await auth.signOut();
    expect(auth.currentUser, isNull);
  });

  test('anonymous user is deleted on sign out', () async {
    var credential = await auth.signInAnonymously();
    expect(credential.user.isAnonymous, isTrue);
    await auth.signOut();
    expect(await auth.getUser(credential.user.uid), isNull);
  });
}
```

### Run the shared auth test suites

```dart
import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_auth_test/auth_admin_test_runner.dart';
import 'package:tekartik_firebase_auth_test/auth_local_admin_test_runner.dart';
import 'package:tekartik_firebase_auth_test/auth_sign_in_delete_test_runner.dart';
import 'package:tekartik_firebase_auth_test/auth_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  runAuthTests(
    firebase: FirebaseLocal(),
    authService: FirebaseAuthServiceSembast(
      databaseFactory: newDatabaseFactoryMemory(),
    ),
  );

  group('sign in', () {
    late FirebaseLocal firebase;
    late FirebaseAppLocal app;
    late FirebaseAuthSembast auth;

    setUp(() {
      firebase = newFirebaseMemory();
      app = firebase.initializeApp();
      auth =
          FirebaseAuthServiceSembast(
                databaseFactory: newDatabaseFactoryMemory(),
              ).auth(app)
              as FirebaseAuthSembast;
    });
    tearDownAll(() => app.delete());

    localAdminTests(
      getAuth: () => auth,
      newApp: () => firebase.initializeApp(name: 'local_admin_test'),
    );
    firebaseAuthAdminTests(
      getAuth: () => auth,
      email: 'sembastemail',
      password: 'sembastpassword',
    );
    firebaseAuthSignInDeleteTests(
      getAuth: () => auth,
      email: 'sembastemail',
      password: 'sembastpassword',
    );
  });
}
```
