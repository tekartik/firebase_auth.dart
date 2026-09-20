---
name: tekartik-firebase-auth-local-setup
description: >-
  Use when a Dart test, demo or CLI needs a fake in-memory FirebaseAuth with
  two ready-made users instead of a real Firebase backend, with
  tekartik_firebase_auth_local: firebaseAuthServiceLocal,
  newFirebaseAuthServiceLocal, newFirebaseAuthLocal, FirebaseAuthServiceLocal,
  FirebaseAuthLocal/AuthLocal, localAdminUser, localRegularUser,
  AuthLocalProvider, AuthLocalSignInOptions, UserRecordLocal, and running
  runAuthTests / firebaseAuthAdminTests against it.
---

# In-memory local auth (tekartik_firebase_auth_local)

A `tekartik_firebase_auth` backend that keeps everything in memory: it starts
with two hard-coded users (an "admin" and a regular "user"), signs the admin in
immediately, and never talks to the network. Meant for unit tests, demos and
dev builds; nothing is persisted.

## Guidelines

* Git-only package (not on pub.dev):

  ```yaml
  dependencies:
    tekartik_firebase_auth_local:
      git:
        url: https://github.com/tekartik/firebase_auth.dart
        path: auth_local
      version: '>=0.3.8'
  ```

* Import `package:tekartik_firebase_auth_local/auth_local.dart`. It re-exports
  `package:tekartik_firebase_auth/auth.dart`, so `FirebaseAuth`, `User`,
  `UserRecord`, `UserCredential`, `UserInfoWithIdToken`,
  `FirebaseAuthCreateUserRequest` and `FirebaseAppOptions` come with it. Add
  `package:tekartik_firebase_local/firebase_local.dart` for `FirebaseLocal`,
  `newFirebaseAppLocal`, `newFirebaseAppMemory` and
  `package:tekartik_firebase_auth/auth_admin.dart` for the
  `FirebaseAuthAdmin` / `FirebaseAuthLocalAdmin` interfaces.
* The app must be a local app: `FirebaseAuthServiceLocal.auth(app)` casts it
  to `AppLocal`. Build it with `FirebaseLocal().initializeApp(name: ...)`,
  `newFirebaseAppLocal()` or `newFirebaseAppMemory()`; passing a REST/node app
  throws.
* Three ways to get an auth instance:
  * `firebaseAuthServiceLocal` - the process-wide service singleton, then
    `firebaseAuthServiceLocal.auth(app)` (one instance per app, cached).
  * `newFirebaseAuthServiceLocal()` - a fresh, isolated service; use it when a
    test must not share users with another test.
  * `newFirebaseAuthLocal()` - shortcut returning a `FirebaseAuth` on a brand
    new in-memory app; each call is independent.
  * `authServiceLocal`, `newAuthServiceLocal()`, `newAuthLocal()` and the
    typedefs `AuthLocal` / `AuthServiceLocal` are older aliases; the bare
    `authService` getter is deprecated.
* Cast to `FirebaseAuthLocal` (alias `AuthLocal`) to reach the two seeded
  users: `localAdminUser` (uid `'1'`, `admin@example.com`, display name
  `admin`) and `localRegularUser` (uid `'2'`, `user@example.com`, display name
  `user`). The admin is already the `currentUser` right after
  `authService.auth(app)`, before any sign-in.
* Sign in as one of them with the local provider:
  `auth.signIn(AuthLocalProvider(), options: AuthLocalSignInOptions(auth.localRegularUser))`.
  `AuthLocalSignInOptions` only accepts a `UserRecordLocal` (i.e. a user you
  got from `localAdminUser`, `localRegularUser`, `getUser` or `createUser`);
  the provider id is `_local`. `signOut()` sets the current user to `null`.
* Email/password: `createUserWithEmailAndPassword` creates then signs in;
  `signInWithEmailAndPassword` throws `StateError('user <email> not found')`
  or `StateError('invalid password')`. A user created without a password
  (including the two seeded ones) accepts **any** password.
  `sendPasswordResetEmail(email:)` only checks the user exists, nothing is
  sent.
* The id token is the uid itself: `await (user as UserInfoWithIdToken)
  .getIdToken()` returns the uid, and `auth.verifyIdToken(token)` returns a
  `DecodedIdToken` whose `uid` is that token. Never let this backend anywhere
  near production code that trusts id tokens.
* Admin side (`FirebaseAuthAdmin` + `FirebaseAuthLocalAdmin`):
  `createUser(FirebaseAuthCreateUserRequest(uid:, email:, password:,
  displayName:))` (throws `StateError` on a duplicate uid or email),
  `setUser(uid, email:, isAnonymous:, emailVerified:)`, `getUser`, `getUsers`,
  `getUserByEmail`, `deleteUser` (which also signs out) and
  `listUsers(maxResults:, pageToken:)` - the page token is the next start
  index as a string. `supportsListUsers` and `supportsCurrentUser` are both
  `true`.
* Not implemented here, they throw: `signInAnonymously()` and
  `sendEmailVerification()` (`UnsupportedError`), `onUserRecord(uid)`
  (`UnimplementedError`), and the
  `getSignInAnonymouslyUserCredential` /
  `getSignInWithEmailAndPasswordUserCredential` helpers of
  `FirebaseAuthLocalAdmin`. So run `runAuthTests`, `firebaseAuthAdminTests`
  and `firebaseAuthSignInDeleteTests` from `tekartik_firebase_auth_test`
  against it, but not `localAdminTests`.
* Users live in the `FirebaseAuth` object only: deleting the app or creating a
  new service resets everything, and nothing survives a restart. When a test
  needs persistence or the full local admin API, use
  `tekartik_firebase_auth_sembast` (sembast file/memory database),
  `tekartik_firebase_auth_sdb` or `tekartik_firebase_auth_sim`.
* Always `await app.delete()` in `tearDown`/`tearDownAll` so the next test
  starts from a clean service instance.

## Examples

### Sign in as the seeded admin or regular user

```dart
import 'package:tekartik_firebase_auth_local/auth_local.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

Future<void> main() async {
  var app = newFirebaseAppLocal();
  var auth = firebaseAuthServiceLocal.auth(app) as FirebaseAuthLocal;

  // The admin user is signed in from the start.
  print(auth.currentUser?.uid); // 1
  print(auth.localAdminUser.email); // admin@example.com

  var provider = AuthLocalProvider(); // providerId '_local'
  await auth.signIn(
    provider,
    options: AuthLocalSignInOptions(auth.localRegularUser),
  );
  print(auth.currentUser?.email); // user@example.com

  // The id token is the uid.
  var user = auth.currentUser! as UserInfoWithIdToken;
  var idToken = await user.getIdToken();
  print((await auth.verifyIdToken(idToken)).uid); // 2

  await auth.signOut();
  print(auth.currentUser); // null

  await app.delete();
}
```

### Seed users and sign in with email/password in a test

```dart
import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:tekartik_firebase_auth_local/auth_local.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  late FirebaseAppLocal app;
  late FirebaseAuthLocal auth;

  setUp(() {
    // A new service: users are not shared with the other tests.
    app = newFirebaseAppLocal();
    auth = newFirebaseAuthServiceLocal().auth(app) as FirebaseAuthLocal;
  });
  tearDown(() => app.delete());

  test('create and sign in', () async {
    var record = await auth.createUser(
      FirebaseAuthCreateUserRequest(
        email: 'test@example.com',
        password: 'password1',
        displayName: 'Test',
      ),
    );
    expect((await auth.getUserByEmail('test@example.com'))!.uid, record.uid);

    var credential = await auth.signInWithEmailAndPassword(
      email: 'test@example.com',
      password: 'password1',
    );
    expect(auth.currentUser!.uid, credential.user.uid);

    // Wrong password is refused, unknown user too.
    expect(
      () => auth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'bad',
      ),
      throwsA(isA<StateError>()),
    );

    // The seeded users have no password: any password works for them.
    await auth.signInWithEmailAndPassword(
      email: 'admin@example.com',
      password: 'whatever',
    );
    expect(auth.currentUser!.uid, auth.localAdminUser.uid);

    await auth.deleteUser(record.uid); // also signs out
    expect(auth.currentUser, isNull);
  });

  test('listUsers', () async {
    var result = await auth.listUsers(maxResults: 1);
    expect(result.users.length, 1);
    expect(result.pageToken, '1'); // next start index
  });
}
```

### Run the shared auth test suites against it

```dart
import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:tekartik_firebase_auth_local/auth_local.dart';
import 'package:tekartik_firebase_auth_test/auth_admin_test_runner.dart';
import 'package:tekartik_firebase_auth_test/auth_sign_in_delete_test_runner.dart';
import 'package:tekartik_firebase_auth_test/auth_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  // Generic service/app/currentUser suite.
  runAuthTests(firebase: FirebaseLocal(), authService: firebaseAuthServiceLocal);

  group('sign in', () {
    late FirebaseAppLocal app;
    late FirebaseAuthAdmin auth;

    setUp(() {
      app = newFirebaseAppLocal();
      auth = firebaseAuthServiceLocal.auth(app) as FirebaseAuthAdmin;
    });
    tearDownAll(() => app.delete());

    firebaseAuthAdminTests(
      getAuth: () => auth,
      email: 'testemail',
      password: 'testpwd',
    );
    firebaseAuthSignInDeleteTests(
      getAuth: () => auth,
      email: 'testemail',
      password: 'testpwd',
    );
  });
}
```
