# tekartik_firebase_auth_test

The shared tests every `tekartik_firebase_auth` backend runs (sembast, sdb,
sim, local, rest, node, admin sdk, flutter), plus a small console dev menu.
Pure Dart on `package:test`: it runs wherever the backend under test runs
(VM, browser, node).

## Getting started

Git package, not on pub.dev, used as a dev dependency of the backend it
tests:

```yaml
dev_dependencies:
  tekartik_firebase_auth_test:
    git:
      url: https://github.com/tekartik/firebase_auth.dart
      path: auth_test
  test: '>=1.31.0'
```

The suites on the sembast backend, in memory (`test/auth_sembast_test.dart`):

```dart
import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_auth_test/auth_admin_test_runner.dart';
import 'package:tekartik_firebase_auth_test/auth_local_admin_test_runner.dart';
import 'package:tekartik_firebase_auth_test/auth_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  // Service level suite: it creates and deletes its own app.
  runAuthTests(
    firebase: newFirebaseMemory(),
    authService: FirebaseAuthServiceSembast(
      databaseFactory: newDatabaseFactoryMemory(),
    ),
  );

  group('sign in', () {
    late FirebaseLocal firebase;
    late FirebaseAppLocal app;
    late FirebaseAuthSembast auth;

    // A fresh app and auth for each test, getAuth() returns the current one.
    setUp(() {
      firebase = newFirebaseMemory();
      app = firebase.initializeApp();
      auth =
          FirebaseAuthServiceSembast(
                databaseFactory: newDatabaseFactoryMemory(),
              ).auth(app)
              as FirebaseAuthSembast;
    });
    tearDown(() => app.delete());

    localAdminTests(getAuth: () => auth);
    firebaseAuthAdminTests(
      getAuth: () => auth,
      email: 'sembast_admin_user',
      password: 'password1',
    );
  });
}
```

Run it with `dart test`.

## Which suite

| Function (library) | Needs | Checks |
|---|---|---|
| `runAuthTests`, `runAuthAppTests` (`auth_test.dart`) | a `FirebaseAuthService` | one auth per app (`app.auth()`), `listUsers` (the pages end), the current user |
| `firebaseAuthAdminTests` (`auth_admin_test_runner.dart`) | a `FirebaseAuthAdmin` | `createUser` with every field, `getUser`, `getUserByEmail`, a duplicate email throws a `StateError`, a signed in user keeps `emailVerified` from its record |
| `firebaseAuthSignInDeleteTests` (`auth_sign_in_delete_test_runner.dart`) | a `FirebaseAuth` | create, sign out, sign in, `user.delete()`, no sign in after the delete |
| `firebaseAuthLinkTests` (`auth_link_test_runner.dart`) | a `FirebaseAuth` | link an email and password to an anonymous user, an email in use is refused |
| `localAdminTests` (`auth_local_admin_test_runner.dart`) | a `FirebaseAuthLocalAdmin` | the local backend contract: `setUser`, sign in and out published once each, a signed out user does not come back, anonymous users, id tokens, `getExistingInstance` after `app.delete()` |

Who runs what: sembast, sdb and sim run all of them; local runs
`runAuthTests`, `firebaseAuthAdminTests` and `firebaseAuthSignInDeleteTests`
(it starts signed in as an admin, without anonymous credentials nor link);
rest runs `runAuthTests`, plus the link and sign in delete suites on the
emulator; node runs `runAuthTests`.

## What to know

* The functions declare tests: call them from `main()` or a `group()`, never
  inside `setUp` or a `test`.
* `getAuth` is called inside each test: build the app and the auth in
  `setUp` and delete the app in `tearDown`, so each test starts clean.
* `localAdminTests` expects no signed in user at the start, and its last
  test (`signIn delete restart`) deletes the app. Pass `newApp` only for a
  persistent backend: it creates a new app and expects the signed in user
  back.
* The `email` you give is created and deleted by the suite: against a real
  project use a test address, a different one per test file.
* `runAuthTests` creates its app and deletes it in `tearDownAll`;
  `runAuthAppTests` leaves your app alone.
* `listUsers` accepts an "insufficient permission" error (a client without
  admin rights).
* The publication tests wait a little (20 microtasks then 100 ms) for late
  `onCurrentUser` events: a backend slower than that misses events there.

## Dev menu

`firebaseAuthMainMenu` (`menu/firebase_auth_client_menu.dart`) is a
[`tekartik_app_dev_menu`](https://github.com/tekartik/app_common_utils.dart)
console menu: current user, `onCurrentUser`, anonymous sign in, sign out.

```dart
import 'package:tekartik_firebase_auth_local/auth_local.dart';
import 'package:tekartik_firebase_auth_test/menu/firebase_auth_client_menu.dart';

Future<void> main(List<String> args) async {
  var auth = newFirebaseAuthLocal();
  await mainMenu(args, () {
    firebaseAuthMainMenu(context: FirebaseAuthMainMenuContext(auth: auth));
  });
}
```

More in the [package skill](skills/tekartik-firebase-auth-test-suites/SKILL.md).
