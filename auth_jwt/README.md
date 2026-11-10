# tekartik_firebase_auth_jwt

Decode and verify a Firebase Authentication ID token (the JWT a client gets
with `user.getIdToken()`) in pure Dart, without the Firebase Admin SDK, as
described in
[Verify ID tokens using a third-party JWT library](https://firebase.google.com/docs/auth/admin/verify-id-tokens#verify_id_tokens_using_a_third-party_jwt_library).

Runs on the Dart VM, Flutter and the web (it only needs `package:http`). Use
it on the server side that trusts the token, not in the client that sent it.

## Getting started

Git package, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_auth_jwt:
    git:
      url: https://github.com/tekartik/firebase_auth.dart
      path: auth_jwt
```

```dart
import 'package:tekartik_firebase_auth_jwt/auth_jwt.dart';

/// Your Firebase project id: the expected token audience.
const projectId = 'my-project';

/// The uid of the caller, null when the token is not valid.
Future<String?> verifiedUserId(String idToken) async {
  try {
    // Parsing only, throws when the string is not a JWT.
    var authInfo = FirebaseAuthInfo.fromIdToken(idToken);
    // Signature (Google public keys, fetched over http) and time claims.
    if (!await authInfo.verify()) {
      return null;
    }
    // A token of another Firebase project is signed by the same keys.
    if (authInfo.projectId != projectId) {
      return null;
    }
    return authInfo.userId;
  } catch (e) {
    // FirebaseAuthValidationException (expired, bad signature), JWT errors.
    return null;
  }
}
```

## Common pitfalls

* `verify()` checks the signature and the `exp`/`iat` claims only: compare
  `projectId` (the `aud` claim) with your own project id, always.
* A failure is either `false` (not an RS256 token, unknown key id) or an
  exception (`FirebaseAuthValidationException`: expired, invalid
  signature; a `TypeError` for a token without key id): treat both as
  "not verified".
* By default `verify()` downloads the Google certificates at each call: in a
  server pass a `fetchKey` that caches them (they rotate every few days).
* `verify(currentTime: ...)` validates at another time, for tests with a
  recorded token.
* A rejected token is logged with `print`.
* `FirebaseAuthException` of this package is not the one of
  `tekartik_firebase_auth`: import one of the libraries with a prefix when you
  use both.

The [tekartik-firebase-auth-jwt-verify-id-token skill](skills/tekartik-firebase-auth-jwt-verify-id-token/SKILL.md)
has more examples (caching the keys, a bearer token in a server, a test with
a recorded token).
