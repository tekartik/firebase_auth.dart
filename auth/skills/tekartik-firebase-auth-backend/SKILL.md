---
name: tekartik-firebase-auth-backend
description: >-
  Use when implementing a tekartik_firebase_auth backend (a
  FirebaseAuthService/FirebaseAuth pair built with FirebaseAuthMixin,
  FirebaseUserMixin, FirebaseUserRecordDefaultMixin), when managing users
  server side with FirebaseAuthAdmin (createUser, deleteUser,
  FirebaseAuthCreateUserRequest, getOrCreateUser), when seeding an
  in-process test backend through FirebaseAuthLocalAdmin (setUser,
  onUserRecord) or when running the shared tekartik_firebase_auth_test runners.
---

# tekartik_firebase_auth backends and admin API

`FirebaseAuth` is only an interface: `tekartik_firebase_auth_flutter`,
`tekartik_firebase_auth_rest` and `tekartik_firebase_auth_node` talk to real
projects while `tekartik_firebase_auth_sembast`, `tekartik_firebase_auth_sdb`,
`tekartik_firebase_auth_sim` and `tekartik_firebase_auth_local` run in-process
and implement `FirebaseAuthLocalAdmin`. See `tekartik-firebase-auth-api` for
client usage.

## Guidelines

* Import `package:tekartik_firebase_auth/auth_mixin.dart` (re-exports
  `auth.dart`, which provides `FirebaseProductServiceMixin`) and
  `package:tekartik_firebase_auth/auth_admin.dart`. `FirebaseAppProductMixin`
  needs `package:tekartik_firebase/firebase_mixin.dart`.
* Service class: `with FirebaseProductServiceMixin<FirebaseAuth>,
  FirebaseAuthServiceMixin`; implement `supportsCurrentUser`,
  `supportsListUsers` and `auth(App app) => getInstance(app, () => ...)`.
  `getInstance` caches one instance per app, registers it as the app product
  (so `app.auth()` works) and disposes it on `app.delete()`.
* Auth class: `with FirebaseAppProductMixin<FirebaseAuth>, FirebaseAuthMixin`.
  Implement `app`, `service` and `reloadCurrentUser`; every other operation
  throws `UnsupportedError` unless overridden. Publish state with
  `currentUserAdd(user)` (`null` on sign-out): `currentUser` and
  `onCurrentUser` derive from it. Publish the initial value (even `null`) as
  soon as the persisted session is known or `onCurrentUser.first` never
  completes. In `dispose()` call `currentUserClose()` then `super.dispose()`.
* Users: `with FirebaseUserMixin` only requires `uid`; other getters default
  to `null`/`false` and `delete()` throws `UnimplementedError`.
  `FirebaseUserCredentialMixin` only provides `toString`: implement `user` and
  `credential` (a class `with FirebaseAuthCredentialMixin` exposing
  `providerId`, e.g. `'password'`). Admin records
  `with FirebaseUserRecordDefaultMixin` require `uid` and `email`; every other
  getter throws `UnimplementedError` on purpose: override what your store has.
* Admin API: implement `FirebaseAuthAdmin` (`createUser`, `getUser`,
  `getUserByEmail`, `deleteUser`) through `FirebaseAuthAdminDefaultMixin` and
  override what you support. `createUser` must throw `StateError` when the
  uid or email already exists and generate a uid when
  `FirebaseAuthCreateUserRequest.uid` is `null`. `getOrCreateUser(request)`
  (`FirebaseAuthAdminExt`) looks up by uid, then by email, then creates.
* In-process backends implement `FirebaseAuthLocalAdmin` (mix in
  `FirebaseAuthLocalAdminDefaultMixin`): `setUser(uid, email:, isAnonymous:,
  emailVerified:)` upserts a user without any flow, `onUserRecord(uid)`
  streams its record, `getSignInWithEmailAndPasswordUserCredential` and
  `getSignInAnonymouslyUserCredential` compute a `UserCredential` without
  touching `currentUser`. `signInAnonymously` creates a new user each call;
  `sendPasswordResetEmail` succeeds for a known email, throws otherwise.
* Name clash: `getOrCreateUserWithEmailAndPassword` exists on `FirebaseAuth`
  (signs in, signs out, returns `FirebaseUser`) and on
  `FirebaseAuthLocalAdmin` (`FirebaseAuthLocalAdminExt`: `getUserByEmail` or
  `createUser`, returns `UserRecord`, never signs in). The static type of the
  receiver picks the extension: type test variables as `FirebaseAuthLocalAdmin`.
* Validate a backend with `tekartik_firebase_auth_test`: `runAuthTests(
  firebase:, authService:)` (app binding, uniqueness, `currentUser`,
  `listUsers`), `firebaseAuthAdminTests(getAuth:, email:, password:)`,
  `localAdminTests(getAuth:, newApp:)` for `FirebaseAuthLocalAdmin` and
  `firebaseAuthSignInDeleteTests`. Use `newFirebaseMemory()` and
  `newFirebaseAppMemory()` (`tekartik_firebase_local`) as `Firebase` and app.
* For tests reuse `newFirebaseAuthSdbMemory()` (`tekartik_firebase_auth_sdb`)
  or `newFirebaseAuthMemory()` (`tekartik_firebase_auth_sembast`), cast to
  `FirebaseAuthLocalAdmin`, instead of writing a new in-process backend.

## Examples

### Minimal backend

```dart
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_auth/auth_mixin.dart';

class MyAuthService
    with FirebaseProductServiceMixin<FirebaseAuth>, FirebaseAuthServiceMixin {
  @override
  bool get supportsCurrentUser => true;
  @override
  bool get supportsListUsers => false;

  @override
  MyAuth auth(App app) => getInstance(app, () => MyAuth(this, app));
}

class MyUser with FirebaseUserMixin {
  @override
  final String uid;
  MyUser(this.uid);
}

class MyCredential with FirebaseAuthCredentialMixin {
  @override
  String get providerId => 'password';
}

class MyUserCredential with FirebaseUserCredentialMixin {
  @override
  final MyUser user;
  @override
  final MyCredential credential = MyCredential();
  MyUserCredential(this.user);
}

class MyAuth with FirebaseAppProductMixin<FirebaseAuth>, FirebaseAuthMixin {
  @override
  final MyAuthService service;
  @override
  final App app;

  MyAuth(this.service, this.app) {
    currentUserAdd(null); // initial state known: signed out
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    var user = MyUser('uid_$email'); // real credential check goes here
    currentUserAdd(user); // signOut() would publish null the same way
    return MyUserCredential(user);
  }

  @override
  Future<User?> reloadCurrentUser() async => currentUser;

  @override
  void dispose() {
    currentUserClose();
    super.dispose();
  }
}
```

### Admin API and seeding an in-process backend in a test

```dart
import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:tekartik_firebase_auth_sdb/auth_sdb.dart';
import 'package:test/test.dart';

void main() {
  test('seed, sign in, delete', () async {
    var auth = newFirebaseAuthSdbMemory() as FirebaseAuthLocalAdmin;
    await auth.setUser('u1', email: 'u1@example.com', emailVerified: true);
    expect((await auth.getUser('u1'))!.emailVerified, isTrue);

    await auth.getOrCreateUser(
      FirebaseAuthCreateUserRequest(uid: 'bot1', email: 'bot@example.com'),
    );
    var record = await auth.getOrCreateUserWithEmailAndPassword(
      email: 'u2@example.com',
      password: 'secret',
    );
    expect(await auth.onCurrentUser.first, isNull); // admin variant
    var credential = await auth.signInWithEmailAndPassword(
      email: 'u2@example.com',
      password: 'secret',
    );
    expect(credential.user.uid, record.uid);

    await auth.deleteUser(record.uid);
    await auth.app.delete();
  });
}
```

### Running the shared test runners on a backend

```dart
import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:tekartik_firebase_auth_test/auth_local_admin_test_runner.dart';
import 'package:tekartik_firebase_auth_test/auth_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  var firebase = newFirebaseMemory();
  var authService = MyAuthService(); // your FirebaseAuthService
  runAuthTests(firebase: firebase, authService: authService);

  var app = firebase.initializeApp(name: 'admin');
  var auth = authService.auth(app) as FirebaseAuthLocalAdmin;
  tearDownAll(() => app.delete());
  localAdminTests(
    getAuth: () => auth,
    newApp: () => firebase.initializeApp(name: 'local_admin_test'),
  );
}
```
