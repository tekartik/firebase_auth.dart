## tekartik_firebase_auth_jwt

Firebase JWT idToken validation.

## Reference doc

https://firebase.google.com/docs/auth/admin/verify-id-tokens#verify_id_tokens_using_a_third-party_jwt_library

## Setup

`pubspec.yaml`:

```yaml
dependencies:
  tekartik_firebase_auth_jwt:
    git:
      url: https://github.com/tekartik/firebase_auth.dart
      path: auth_jwt
      ref: dart3a
    version: '>=0.1.1'
```

## Usage

```dart
/// Decode information from [idToken].
var authInfo = FirebaseAuthInfo.fromIdToken(idToken);

/// Verify information, an exception is thrown on error.
await authInfo.verify();

/// Extract information
var userId = authInfo.userId;
var email = authInfo.email;
```