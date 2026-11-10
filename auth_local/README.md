# tekartik_firebase_auth_local

An in memory backend of [tekartik_firebase_auth](../auth/README.md) for
tests, demos and dev builds: two seeded users (an admin, signed in from the
start, and a regular user), no network, nothing persisted.

Runs everywhere (Dart VM, Flutter, web). For a persistent local backend use
`tekartik_firebase_auth_sdb` or `tekartik_firebase_auth_sembast`.

## Getting started

Git package, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_auth_local:
    git:
      url: https://github.com/tekartik/firebase_auth.dart
      path: auth_local
  tekartik_firebase_local:
    git:
      url: https://github.com/tekartik/firebase.dart
      path: firebase_local
```

```dart
import 'package:tekartik_firebase_auth_local/auth_local.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

Future<void> main() async {
  var app = newFirebaseAppLocal();
  var auth = firebaseAuthServiceLocal.auth(app) as FirebaseAuthLocal;

  // The seeded admin is signed in from the start.
  print(auth.currentUser?.email); // admin@example.com

  // Create a user, then sign in with its email and password.
  await auth.createUser(
    FirebaseAuthCreateUserRequest(
      email: 'bob@example.com',
      password: 'password1',
      displayName: 'Bob',
    ),
  );
  var credential = await auth.signInWithEmailAndPassword(
    email: 'bob@example.com',
    password: 'password1',
  );
  print(credential.user.displayName); // Bob

  await auth.signOut();
  print(auth.currentUser); // null
  await app.delete();
}
```

## What to know

* The app must be a local app (`newFirebaseAppLocal()`,
  `FirebaseLocal().initializeApp()`): another app fails a cast.
* `firebaseAuthServiceLocal` is shared by the process (one auth per app);
  `newFirebaseAuthServiceLocal()` gives an isolated service for a test.
* Cast to `FirebaseAuthLocal` for the seeded users (`localAdminUser`, uid
  `1`; `localRegularUser`, uid `2`) and to sign in as one of them:
  `auth.signIn(AuthLocalProvider(), options: AuthLocalSignInOptions(auth.localRegularUser))`.
* The id token is the uid (`verifyIdToken` accepts any existing uid): never
  use this backend where a token is trusted.
* A user without password (the seeded ones) signs in with any password; a
  disabled user signs in too.
* `listUsers` pages: loop while `pageToken` is not null.
* Not implemented (they throw): `signInAnonymously`,
  `sendEmailVerification`, `onUserRecord`.

The [tekartik-firebase-auth-local-setup skill](skills/tekartik-firebase-auth-local-setup/SKILL.md)
has more examples (tests, the shared auth test suites).
