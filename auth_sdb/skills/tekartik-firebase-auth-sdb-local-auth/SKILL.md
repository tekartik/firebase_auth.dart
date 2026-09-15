---
name: tekartik-firebase-auth-sdb-local-auth
description: >-
  Use when a Dart or Flutter app or test needs a local email/password
  FirebaseAuth backend stored in an sdb database (in memory, IndexedDB on the
  web, sembast/sqflite elsewhere) with tekartik_firebase_auth_sdb:
  FirebaseAuthServiceSdb, newFirebaseAuthSdbMemory, the FirebaseAuthSdb admin
  API (setUser, createUser, getUser, deleteUser), persisting users with
  getSdbFactory, and the runAsync/pump widget test pattern.
---

# tekartik_firebase_auth_sdb local auth

Local `tekartik_firebase_auth` backend (`FirebaseAuth`, `User`, `UserCredential`)
storing users and the current session in an sdb database (`idb_shim` sdb). Meant
for tests and offline apps: it also implements `FirebaseAuthLocalAdmin` /
`FirebaseAuthAdmin` so code can seed and inspect users directly.

## Guidelines

* Import `package:tekartik_firebase_auth_sdb/auth_sdb.dart`. It re-exports
  `package:tekartik_firebase_auth/auth.dart` (`FirebaseAuth`, `User`,
  `UserRecord`, `UserCredential`, `FirebaseAuthCreateUserRequest`,
  `FirebaseAppOptions`, ...). Add
  `package:tekartik_firebase_local/firebase_local.dart` for
  `newFirebaseAppLocal`, `newFirebaseMemory`, `FirebaseLocal` and
  `package:tekartik_app_cv_sdb/app_cv_sdb.dart` for `SdbFactory` and
  `sdbFactoryMemory` in pure Dart code.
* Build the auth in two steps: `FirebaseAuthServiceSdb(sdbFactory: ...)` then
  `authService.auth(app)`. The app must be a `FirebaseAppLocal` (the service
  asserts it): create it with
  `newFirebaseAppLocal(options: FirebaseAppOptions(projectId: ...))` or
  `FirebaseLocal().initializeApp()`. The database is `auth.db` under the app
  `localPath`, so different app names/local paths keep separate users.
* Pick the sdb factory per target: `sdbFactoryMemory` for tests and CLI
  scripts; in a Flutter app, `getSdbFactory(packageName: ...)` from
  `package:tekartik_app_flutter_idb/sdb.dart` (IndexedDB on the web,
  sembast/sqflite elsewhere; that library also exports `SdbFactory`). Keep the
  package name stable, it determines where the data lives.
* In tests prefer `newFirebaseAuthSdbMemory()`: each call returns an isolated
  in-memory app and database. Cast the result `as FirebaseAuthSdb` to reach the
  admin API and call `auth.app.delete()` in `tearDown`.
  `newFirebaseAuthServiceSdbMemory()` returns the service when you need it.
* Admin API on `FirebaseAuthSdb`:
  * `createUser(FirebaseAuthCreateUserRequest(email:, password:,
    displayName:, uid:, emailVerified:, disabled:, ...))` returns a
    `UserRecord`; throws `StateError('uid-already-exists')` or
    `StateError('email-already-exists')`.
  * `setUser(uid, email:, emailVerified:, isAnonymous:)` creates or replaces
    the whole record (password and display name are dropped) and removes other
    users with the same email. Use `createUser` or
    `createUserWithEmailAndPassword` to seed a user with a password.
  * `getUser(uid)`, `getUserByEmail(email)`, `onUserRecord(uid)` (stream),
    `deleteUser(uid)` which also signs the current session out.
  * `getOrCreateUserWithEmailAndPassword(email:, password:)` is an extension
    from `package:tekartik_firebase_auth/auth_admin.dart`.
* Sign-in: `createUserWithEmailAndPassword` creates the user then signs in.
  `signInWithEmailAndPassword` throws `StateError('user-not-found')` or
  `StateError('wrong-password')`; a user stored without password (from
  `setUser`) accepts any password. `signInAnonymously` creates a temporary
  user that `signOut` deletes.
* The current user is persisted (`info/currentUser` record): with a persistent
  factory the session survives an app restart. `onCurrentUser` emits once the
  database is open; `currentUser` is updated synchronously by sign in/out.
* `sendPasswordResetEmail(email:)` only checks that the user exists (throws
  `StateError('user-not-found')`), nothing is sent. `sendEmailVerification()`
  throws `UnsupportedError`. `supportsListUsers` is `false`
  (`supportsCurrentUser` is `true`).
* Passwords are stored in clear text in the local database: never use this
  backend as a security boundary. Real apps use `tekartik_firebase_auth_flutter`
  (native) or the REST backend; keep sdb for tests, demos and offline data.
* Operations run in the real async zone. In widget tests wrap auth calls in
  `tester.runAsync` and alternate short real delays with `tester.pump`; do not
  rely on `pumpAndSettle` while a busy indicator animates.
* `package:tekartik_firebase_auth_sdb/auth_sdb_mixin.dart` exposes
  `firebaseAuthSdbInitDbBuilders()`, `DbCurrentUser` and
  `firebaseAuthCurrentUserRecord` for code opening the same database; the cv
  builders are registered automatically when the service is created.
* Sibling backends with the same `FirebaseAuthLocalAdmin` API:
  `tekartik_firebase_auth_sembast` (`FirebaseAuthServiceSembast`, sembast
  database), `tekartik_firebase_auth_local` and `tekartik_firebase_auth_sim`.
  Prefer sdb for Flutter apps that must also run on the web.
* Validate a backend or a new sdb factory with the shared suites of
  `tekartik_firebase_auth_test`: `runAuthTests`, `localAdminTests`,
  `firebaseAuthAdminTests`, `firebaseAuthSignInDeleteTests`.

## Examples

### Flutter app persisting users

```dart
import 'package:flutter/widgets.dart';
import 'package:tekartik_app_flutter_idb/sdb.dart';
import 'package:tekartik_firebase_auth_sdb/auth_sdb.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

/// Package name used for the local database location.
const packageName = 'com.example.my_app';

/// Local firebase app with an auth service backed by sdb.
FirebaseAuth initFirebaseAuthSdb({required SdbFactory sdbFactory}) {
  var app = newFirebaseAppLocal(
    options: FirebaseAppOptions(projectId: 'my-app-local'),
  );
  var authService = FirebaseAuthServiceSdb(sdbFactory: sdbFactory);
  return authService.auth(app);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseAuth = initFirebaseAuthSdb(
    sdbFactory: getSdbFactory(packageName: packageName),
  );
  runApp(MyApp(firebaseAuth: firebaseAuth));
}
```

### Seeding users in a Dart test

```dart
import 'package:tekartik_firebase_auth_sdb/auth_sdb.dart';
import 'package:test/test.dart';

void main() {
  late FirebaseAuthSdb auth;
  setUp(() {
    auth = newFirebaseAuthSdbMemory() as FirebaseAuthSdb;
  });
  tearDown(() => auth.app.delete());

  test('seed and sign in', () async {
    var record = await auth.createUser(
      FirebaseAuthCreateUserRequest(
        email: 'user@example.com',
        password: 'password1',
        displayName: 'User',
      ),
    );
    expect(await auth.getUserByEmail('user@example.com'), isNotNull);

    var credential = await auth.signInWithEmailAndPassword(
      email: 'user@example.com',
      password: 'password1',
    );
    expect(credential.user.uid, record.uid);
    expect(auth.currentUser?.email, 'user@example.com');

    // No password: any password signs this user in.
    await auth.setUser('admin', email: 'admin@example.com', emailVerified: true);
    expect((await auth.getUser('admin'))?.emailVerified, isTrue);

    await auth.deleteUser(record.uid); // also signs out
    expect(auth.currentUser, isNull);
  });
}
```

### Widget test (real zone + pump)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_firebase_auth_sdb/auth_sdb.dart';

void main() {
  late FirebaseAuth auth;
  setUp(() => auth = newFirebaseAuthSdbMemory());
  tearDown(() => auth.app.delete());

  testWidgets('shows the signed-in user', (tester) async {
    // Auth operations run in the real zone; let notifications flush.
    await tester.runAsync(() async {
      await auth.createUserWithEmailAndPassword(
        email: 'user@example.com',
        password: 'password1',
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpWidget(
      MaterialApp(
        home: StreamBuilder<User?>(
          stream: auth.onCurrentUser,
          builder: (context, snapshot) =>
              Text(snapshot.data?.email ?? 'Not signed in'),
        ),
      ),
    );
    // Real delay for the db work, then a fake clock pump (no pumpAndSettle).
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('user@example.com'), findsOneWidget);
  });
}
```
