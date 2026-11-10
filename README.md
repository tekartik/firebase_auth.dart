# firebase_auth.dart

Platform neutral Firebase Auth API for Dart and Flutter, and its local
implementations. Write the auth code once against `tekartik_firebase_auth`,
run it on Flutter, REST, node, the admin SDK or in memory.

## Packages

| Package | Path | What |
|---|---|---|
| `tekartik_firebase_auth` | [auth](auth) | the API (sign in, current user, ID tokens, admin lookups); start here |
| `tekartik_firebase_auth_sembast` | [auth_sembast](auth_sembast) | local backend on sembast (`newFirebaseAuthMemory()` for tests) |
| `tekartik_firebase_auth_sdb` | [auth_sdb](auth_sdb) | local backend on sdb (memory, IndexedDB) |
| `tekartik_firebase_auth_sim` | [auth_sim](auth_sim) | client and server of a remote simulation (web socket) |
| `tekartik_firebase_auth_local` | [auth_local](auth_local) | in memory backend with two seeded users, for tests and demos |
| `tekartik_firebase_auth_jwt` | [auth_jwt](auth_jwt) | ID token (JWT) validation |
| `tekartik_firebase_auth_test` | [auth_test](auth_test) | the shared tests every backend runs |

The Flutter, REST, node and admin SDK backends are in their own repos
(`firebase_flutter`, `firebase_rest.dart`, `firebase_node.dart`,
`firebase_admin_sdk.dart`, under `https://github.com/tekartik/`).

## Getting started

Git packages, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_auth:
    git:
      url: https://github.com/tekartik/firebase_auth.dart
      path: auth
```

See the [auth package README](auth/README.md) for a first program, the
backends and the common pitfalls.
