---
name: tekartik-firebase-auth-jwt-verify-id-token
description: >-
  Use when a Dart server, backend or test must decode and verify a Firebase
  id token (JWT) without the Firebase Admin SDK, with
  tekartik_firebase_auth_jwt: FirebaseAuthInfo.fromIdToken, authInfo.verify
  (currentTime, fetchKey), reading userId/email/emailVerified/name/picture/
  projectId, catching FirebaseAuthValidationException and FirebaseAuthException,
  and checking the token audience against the expected Firebase project id.
---

# Verify Firebase id tokens (tekartik_firebase_auth_jwt)

Pure Dart decoding and validation of a Firebase Authentication id token
(the `RS256` JWT a client gets from `user.getIdToken()`), following
[Verify ID tokens using a third-party JWT library](https://firebase.google.com/docs/auth/admin/verify-id-tokens#verify_id_tokens_using_a_third-party_jwt_library).
The signature is checked against the Google `securetoken` x509 certificates,
which the package fetches over http by default.

## Guidelines

* Git-only package (not on pub.dev):

  ```yaml
  dependencies:
    tekartik_firebase_auth_jwt:
      git:
        url: https://github.com/tekartik/firebase_auth.dart
        path: auth_jwt
      version: '>=0.1.1'
  ```

* One public library: `import 'package:tekartik_firebase_auth_jwt/auth_jwt.dart';`.
  It exports exactly three names: `FirebaseAuthInfo`,
  `FirebaseAuthException` and `FirebaseAuthValidationException`.
* Decode with the factory `FirebaseAuthInfo.fromIdToken(idToken)`. This is
  synchronous and does *not* validate anything: it only parses the JWT. A
  string that is not a JWT (an OAuth2 access token, a truncated header, ...)
  throws a `JWTError` from `package:corsac_jwt` at this point, so wrap the
  parsing in a `try`/`catch` too, not only the `verify()` call.
* Then `await authInfo.verify()` to check the signature and the time claims.
  It returns `Future<bool>`; it returns `false` when the header algorithm is
  not `RS256` or when no public key matches the token `kid`, and it *throws*
  `FirebaseAuthValidationException` (read its `message`, e.g. it contains
  `expired`) when the JWT validator reports errors. Treat "not true" and
  "threw" as the same failure: never trust the claims unless `verify()`
  returned `true`.
* `verify()` takes two optional named parameters:
  * `currentTime` (`DateTime?`) to validate against a fixed instant - use it
    in tests with a recorded token, otherwise every token expires.
  * `fetchKey` (`Future<String?> Function(String keyId)`) to supply the PEM
    certificate yourself. The default implementation does an http `read` of
    `https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com`
    on every call - in a server, pass a `fetchKey` that caches those keys
    (they rotate every few days) instead of hitting Google per request.
    Returning `null` from `fetchKey` makes `verify()` return `false`.
* Claims exposed on `FirebaseAuthInfo`: `userId` (the Firebase uid, from the
  `user_id` claim), `email`, `emailVerified`, `name`, `picture` and
  `projectId` (the `aud` claim). All are nullable. `toDebugMap()` returns a
  map with the header and the decoded payload (times rendered as ISO 8601)
  for logging.
* Verifying the signature is not enough: also check that
  `authInfo.projectId` equals your own Firebase project id, otherwise a valid
  token issued for another project would be accepted.
* `FirebaseAuthValidationException` implements `FirebaseAuthException`
  (itself an `Exception`); catch `FirebaseAuthException` to cover both. Note
  these are this package's own types - they are unrelated to the
  `FirebaseAuthException` of `tekartik_firebase_auth`, so do not import both
  libraries in the same file without a prefix.
* This is a validation-only package: it does not sign in users, has no
  `FirebaseAuth` service and no `User`. For a client side or local auth use
  `tekartik_firebase_auth` and one of its backends
  (`tekartik_firebase_auth_sembast`, `tekartik_firebase_auth_sdb`,
  `tekartik_firebase_auth_flutter`, ...); use `auth_jwt` on the receiving
  side, in a Dart server or a cloud function checking an `Authorization:
  Bearer <idToken>` header.
* It runs on the vm and on the web (it only needs `package:http`), but never
  verify a token in the client you got it from: verification belongs to the
  service that trusts it.

## Examples

### Verify a bearer token in a Dart server

```dart
import 'package:tekartik_firebase_auth_jwt/auth_jwt.dart';

/// Your firebase project id, the expected token audience.
const expectedProjectId = 'my-firebase-project';

/// Decoded and verified caller, or null when the token is not usable.
class AuthUser {
  final String userId;
  final String? email;

  AuthUser({required this.userId, this.email});
}

/// [authorization] is the raw `Authorization: Bearer <idToken>` header.
Future<AuthUser?> authenticate(String? authorization) async {
  const prefix = 'Bearer ';
  if (authorization == null || !authorization.startsWith(prefix)) {
    return null;
  }
  var idToken = authorization.substring(prefix.length);
  try {
    // Parsing only: throws when the string is not a JWT at all.
    var authInfo = FirebaseAuthInfo.fromIdToken(idToken);

    // Signature + exp/iat validation, throws on validation error.
    if (await authInfo.verify() != true) {
      return null;
    }
    // Signature alone is not enough, check the audience.
    if (authInfo.projectId != expectedProjectId) {
      return null;
    }
    var userId = authInfo.userId;
    if (userId == null) {
      return null;
    }
    return AuthUser(userId: userId, email: authInfo.email);
  } on FirebaseAuthException catch (e) {
    // Includes FirebaseAuthValidationException (expired token, bad signature).
    print('invalid token: $e');
    return null;
  } catch (e) {
    print('cannot decode token: $e');
    return null;
  }
}
```

### Cache the Google public keys

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tekartik_firebase_auth_jwt/auth_jwt.dart';

/// Where the Firebase id token signing certificates are published.
final _keysUri = Uri.parse(
  'https://www.googleapis.com/robot/v1/metadata/x509/'
  'securetoken@system.gserviceaccount.com',
);

Map<String, String>? _keys;
DateTime? _keysTime;

/// Fetch the x509 certificates, keeping them for an hour.
Future<String?> cachedFetchKey(String keyId) async {
  var now = DateTime.timestamp();
  var time = _keysTime;
  if (_keys == null ||
      time == null ||
      now.difference(time) > const Duration(hours: 1)) {
    var content = await http.read(_keysUri);
    _keys = (jsonDecode(content) as Map).cast<String, String>();
    _keysTime = now;
  }
  return _keys![keyId];
}

Future<bool> verifyIdToken(String idToken) async {
  var authInfo = FirebaseAuthInfo.fromIdToken(idToken);
  try {
    return await authInfo.verify(fetchKey: cachedFetchKey);
  } on FirebaseAuthValidationException catch (e) {
    print('token rejected: ${e.message}');
    return false;
  }
}
```

### Test a recorded token at a fixed time

```dart
import 'package:tekartik_firebase_auth_jwt/auth_jwt.dart';
import 'package:test/test.dart';

void main() {
  // A token captured once, and the PEM certificate that signed it.
  const idToken = 'eyJhbGciOiJSUzI1NiIsImtpZCI6ImFiYyIsInR5cCI6IkpXVCJ9.e30.x';
  const kid = 'abc';
  const pem = '-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----\n';

  Future<String?> fetchKey(String keyId) async => keyId == kid ? pem : null;

  test('decode', () {
    var authInfo = FirebaseAuthInfo.fromIdToken(idToken);
    // Claims are readable before any verification.
    expect(authInfo.projectId, isNull);
    print(authInfo.toDebugMap());
  });

  test('verify at a fixed time', () async {
    var authInfo = FirebaseAuthInfo.fromIdToken(idToken);
    try {
      // Without currentTime the recorded token is always expired.
      var ok = await authInfo.verify(
        currentTime: DateTime.parse('2020-05-03T07:05:34.000Z'),
        fetchKey: fetchKey,
      );
      expect(ok, isTrue);
    } on FirebaseAuthValidationException catch (e) {
      expect(e.message, contains('expired'));
    }
  });
}
```
