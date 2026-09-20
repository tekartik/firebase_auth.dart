---
name: tekartik-firebase-auth-test-suites
description: >-
  Use when validating a tekartik_firebase_auth backend (local, sembast, sdb,
  sim, rest, flutter) against the shared conformance suites of
  tekartik_firebase_auth_test: runAuthTests, runAuthAppTests,
  firebaseAuthAdminTests, localAdminTests, firebaseAuthSignInDeleteTests, what
  FirebaseAuthService / FirebaseAuthAdmin / FirebaseAuthLocalAdmin each one
  needs, and the firebaseAuthMainMenu / FirebaseAuthMainMenuContext dev menu.
---

# Shared auth test suites (tekartik_firebase_auth_test)

Ready-made `package:test` suites that any `tekartik_firebase_auth`
implementation can run to prove it behaves like the others, plus a small
interactive dev menu for manual checks. Every suite is written against the
public `FirebaseAuth` / `FirebaseAuthAdmin` / `FirebaseAuthLocalAdmin`
interfaces, so it is backend agnostic.

## Guidelines

* Git-only package (not on pub.dev), used as a dev dependency by the backend
  it tests:

  ```yaml
  dev_dependencies:
    tekartik_firebase_auth_test:
      git:
        url: https://github.com/tekartik/firebase_auth.dart
        path: auth_test
      version: '>=0.3.8'
  ```

* Four libraries, one per suite; import only the ones you call:
  * `package:tekartik_firebase_auth_test/auth_test.dart` - `runAuthTests`,
    `runAuthAppTests` (it also re-exports
    `package:tekartik_firebase_auth/auth.dart`).
  * `.../auth_admin_test_runner.dart` - `firebaseAuthAdminTests`.
  * `.../auth_local_admin_test_runner.dart` - `localAdminTests`.
  * `.../auth_sign_in_delete_test_runner.dart` -
    `firebaseAuthSignInDeleteTests`.
* Every entry point *declares* `group`/`test`, it does not run anything: call
  it synchronously from `main()` or from a `group()` body, never inside
  `setUp`, `test` or after an `await`.
* `runAuthTests({required Firebase firebase, required FirebaseAuthService
  authService, String? name, AppOptions? options})` is the basic service
  suite: it calls `firebase.initializeApp(...)` itself, checks `auth.app`,
  `auth.service`, instance unicity (`authService.auth(app)`,
  `app.getProduct<FirebaseAuth>()`, `app.auth()`), `listUsers` and the current
  user, and deletes the app in `tearDownAll`. Give it a `name` when a single
  test file declares it twice, so the two apps do not collide.
* `runAuthAppTests({required FirebaseAuthService authService, FirebaseAuth?
  auth, required App app})` is the same suite on an app you own (it does not
  delete it). `runApp(...)` is the deprecated former name.
* The `listUsers` and `currentUser` groups are skipped automatically from
  `authService.supportsListUsers` / `authService.supportsCurrentUser`, so a
  backend that does not support them still passes - report the capability
  correctly on the service instead of skipping the suite.
* The other three take a `getAuth` callback, called from inside each test, so
  an instance rebuilt in `setUp` is picked up:
  * `firebaseAuthAdminTests({required FirebaseAuthAdmin Function() getAuth,
    required String email, required String password})` - `createUser`,
    `getUser`, `getUserByEmail`, `createUserWithEmailAndPassword`,
    `signOut`, `deleteUser`, and expects a `StateError` when creating a
    second user with the same email. It deletes any pre-existing user with
    that email first, so give each backend its own `email` value.
  * `firebaseAuthSignInDeleteTests({required FirebaseAuth Function() getAuth,
    required String email, required String password})` - the pure client
    flow: create, sign out, sign in again, `user.delete()`, and signing in
    after the delete must fail.
  * `localAdminTests({required FirebaseAuthLocalAdmin Function() getAuth,
    FirebaseApp Function()? newApp})` - the full local backend contract:
    `setUser` (including re-assigning an email to another uid),
    `createUser` with every field plus duplicate uid/email errors,
    `getOrCreateUserWithEmailAndPassword`, `signInWithEmailAndPassword`,
    `sendPasswordResetEmail` (throws for an unknown user),
    `signInAnonymously` + `getSignInAnonymouslyUserCredential`, and
    `service.getExistingInstance(app)` before/after `app.delete()`. It starts
    by asserting that **no user is signed in**, so do not sign in in `setUp`.
  * Pass `newApp` to `localAdminTests` only when the backend persists its
    state: the last test deletes the app, rebuilds one with `newApp()` and
    expects the same current user to come back.
* `email` and `password` are plain strings, they need not look like real
  emails (`'user1'`, `'testemail'` are used in the repo); use a value unique
  to the file so parallel suites do not fight over the same record.
* Pick the suites the backend actually supports:
  `tekartik_firebase_auth_sembast`, `_sdb` and `_sim` pass all of them;
  `tekartik_firebase_auth_local` has no anonymous sign-in and no
  `onUserRecord`, so it runs `runAuthTests`, `firebaseAuthAdminTests` and
  `firebaseAuthSignInDeleteTests` but not `localAdminTests`.
* `skipConcurrentTransactionTests` is a top-level flag kept for
  compatibility; the suites here do not use it.
* `package:tekartik_firebase_auth_test/menu/firebase_auth_client_menu.dart`
  adds an interactive console: `firebaseAuthMainMenu(context:
  FirebaseAuthMainMenuContext(auth: firebaseAuth))` inside a `mainMenu(args,
  ...)` from `package:tekartik_app_dev_menu/dev_menu.dart` (re-exported by
  that library) gives entries for the current user, an `onCurrentUser`
  subscription, anonymous sign-in and sign out. Use it in an `example/`
  client, not in automated tests.
* This package declares `test` as a regular dependency (that is how it can
  expose the runners) and is `publish_to: none`: depend on it from
  `dev_dependencies` only.

## Examples

### Full conformance run for a local backend

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
  // Service level suite: it creates and deletes its own app.
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
      // Rebuilt for each test, getAuth() below returns the current one.
      firebase = newFirebaseMemory();
      app = firebase.initializeApp();
      auth =
          FirebaseAuthServiceSembast(
                databaseFactory: newDatabaseFactoryMemory(),
              ).auth(app)
              as FirebaseAuthSembast;
    });
    tearDownAll(() => app.delete());

    // Persistent backend: newApp checks the session is restored.
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

### Suites a partial backend can run

```dart
import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:tekartik_firebase_auth_local/auth_local.dart';
import 'package:tekartik_firebase_auth_test/auth_admin_test_runner.dart';
import 'package:tekartik_firebase_auth_test/auth_sign_in_delete_test_runner.dart';
import 'package:tekartik_firebase_auth_test/auth_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  // No anonymous sign-in and no onUserRecord here: localAdminTests is skipped.
  runAuthTests(
    firebase: FirebaseLocal(),
    authService: firebaseAuthServiceLocal,
    name: 'auth_local',
  );

  group('sign in', () {
    late FirebaseAppLocal app;
    late FirebaseAuthAdmin auth;

    setUp(() {
      app = newFirebaseAppLocal();
      auth = newFirebaseAuthServiceLocal().auth(app) as FirebaseAuthAdmin;
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

### Same suite on an app you already own

```dart
import 'package:tekartik_firebase_auth_local/auth_local.dart';
import 'package:tekartik_firebase_auth_test/auth_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  // An app configured by the caller (options, name, local path...).
  var app = FirebaseLocal().initializeApp(
    name: 'my_app',
    options: AppOptions(projectId: 'my-project'),
  );
  var authService = newFirebaseAuthServiceLocal();

  // runAuthAppTests does not delete the app, do it yourself.
  runAuthAppTests(
    authService: authService,
    auth: authService.auth(app),
    app: app,
  );
  tearDownAll(() => app.delete());
}
```

### Interactive dev menu for a client

```dart
import 'package:tekartik_firebase_auth_local/auth_local.dart';
import 'package:tekartik_firebase_auth_test/menu/firebase_auth_client_menu.dart';

Future<void> main(List<String> args) async {
  var firebaseAuth = newFirebaseAuthLocal();
  await mainMenu(args, () {
    firebaseAuthMainMenu(
      context: FirebaseAuthMainMenuContext(auth: firebaseAuth),
    );
  });
}
```
