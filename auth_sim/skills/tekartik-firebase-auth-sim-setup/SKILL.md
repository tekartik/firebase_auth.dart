---
name: tekartik-firebase-auth-sim-setup
description: >-
  Use when a Dart or Flutter client must reach a FirebaseAuth backend running
  in a firebase sim (web socket / RPC) server instead of a real Firebase
  project, with tekartik_firebase_auth_sim: FirebaseAuthServiceSim(
  databaseFactory:), FirebaseAuthSim on the client, FirebaseAuthSimPlugin and
  FirebaseAuthSimServerService passed to firebaseSimServe on the server,
  getFirebaseSim, FirebaseAppSim, and running localAdminTests /
  firebaseAuthAdminTests over the simulated link.
---

# Firebase auth over the sim protocol (tekartik_firebase_auth_sim)

Client and server halves of a simulated `tekartik_firebase_auth` backend: a
`FirebaseSimServer` exposes a real local auth service (usually
`tekartik_firebase_auth_sembast`) over a web socket, and clients talk to it
with a `FirebaseAuth` that looks exactly like any other backend. Used to share
one local auth between several processes/tabs, and to test client code against
a controllable server.

## Guidelines

* Git-only package (not on pub.dev):

  ```yaml
  dependencies:
    tekartik_firebase_auth_sim:
      git:
        url: https://github.com/tekartik/firebase_auth.dart
        path: auth_sim
  ```

* Two entry points, do not mix them up:
  * client: `package:tekartik_firebase_auth_sim/auth_sim.dart` exports
    `FirebaseAuthServiceSim`, `FirebaseAuthSim` and re-exports
    `package:tekartik_firebase_auth/auth.dart`.
  * server: `package:tekartik_firebase_auth_sim/auth_sim_server.dart` exports
    only `FirebaseAuthSimPlugin` and `FirebaseAuthSimServerService`.
* Server side: start the sim server with `firebaseSimServe(firebase,
  webSocketChannelServerFactory:, port:, plugins: [...])` from
  `package:tekartik_firebase_sim/firebase_sim_server.dart` (which also exports
  `webSocketChannelServerFactoryIo` and `FirebaseSimServer`). Register
  `FirebaseAuthSimPlugin(firebaseAuthSimServerService:
  FirebaseAuthSimServerService(), firebaseAuthService: <a local auth
  service>)`. The `firebase` is a local one (`FirebaseLocal()`,
  `newFirebaseMemory()`) and the auth service must implement
  `FirebaseAuthLocalAdmin` - in practice
  `FirebaseAuthServiceSembast(databaseFactory: ...)`. Read
  `firebaseSimServer.url` / `.uri` to know where it listens (port `0` picks a
  free one), and `await simServer.close()` when done.
* Client side: get the firebase with `getFirebaseSim(uri: Uri.parse(url))`
  from `package:tekartik_firebase_sim/firebase_sim.dart`, `initializeApp()`,
  then `FirebaseAuthServiceSim(databaseFactory: ...).auth(app)`. The app must
  be a `FirebaseAppSim` (the service asserts it) and `auth(app)` is typed
  `FirebaseAuthSim`, so no cast is needed to reach the admin API.
* The client `databaseFactory` is a sembast factory used **only** to remember
  which user is signed in, in `<localPath>/<appName>/auth.db` (it reuses the
  `firebaseAuthCurrentUserRecord` record of
  `tekartik_firebase_auth_sembast`). Users themselves live on the server. Use
  `databaseFactoryIo` (`package:sembast/sembast_io.dart`) for a real client so
  the session survives a restart, `newDatabaseFactoryMemory()`
  (`package:sembast/sembast_memory.dart`) in tests.
* `FirebaseAuthSim` implements `FirebaseAuth` and `FirebaseAuthLocalAdmin`:
  `createUser(FirebaseAuthCreateUserRequest(...))`, `setUser(uid, email:,
  emailVerified:, isAnonymous:)`, `getUser`, `getUserByEmail`, `deleteUser`,
  `onUserRecord(uid)` (a live subscription over the socket),
  `createUserWithEmailAndPassword`, `signInWithEmailAndPassword`,
  `signInAnonymously`, `sendPasswordResetEmail(email:)`, `signOut()` and the
  `getSignInWithEmailAndPasswordUserCredential` /
  `getSignInAnonymouslyUserCredential` helpers. Errors raised by the server
  (`user-not-found`, `wrong-password`, `email-already-exists`, ...) are
  forwarded to the client.
* `signOut()` deletes the user when it is anonymous, exactly like the sembast
  backend. `supportsCurrentUser` is `true`, `supportsListUsers` is `false`
  (`listUsers` throws).
* `onCurrentUser` only emits once the local database is open, so in tests
  prefer `await auth.onCurrentUser.first` over reading `currentUser`
  synchronously right after creating the auth.
* `await app.delete()` disposes the client auth (closing its local database
  and the server subscriptions); the users stay on the server, so a new app +
  auth on the same `databaseFactory` finds the session again.
* The plugin service name is `firebase_auth`; add the firestore/storage sim
  plugins to the same `firebaseSimServe` call when the app needs them.
* In tests use the memory transport: `webSocketChannelServerFactoryMemory` and
  `webSocketChannelClientFactoryMemory` from
  `package:tekartik_app_web_socket/web_socket.dart`, with `port: 0`. Then run
  the shared suites of `tekartik_firebase_auth_test` (`runAuthTests`,
  `localAdminTests`, `firebaseAuthAdminTests`) against the client auth.
* This is a development tool: the transport is unauthenticated and passwords
  are stored in clear in the server database. Never expose a sim server
  outside a dev machine.

## Examples

### Sim server exposing a sembast auth

```dart
import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_auth_sim/auth_sim_server.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';

Future<void> main(List<String> args) async {
  var simServer = await firebaseSimServe(
    FirebaseLocal(),
    webSocketChannelServerFactory: webSocketChannelServerFactoryIo,
    port: firebaseSimDefaultPort,
    plugins: [
      FirebaseAuthSimPlugin(
        firebaseAuthSimServerService: FirebaseAuthSimServerService(),
        firebaseAuthService: FirebaseAuthServiceSembast(
          databaseFactory: databaseFactoryMemory,
        ),
      ),
    ],
  );
  print('listening on ${simServer.url}');
}
```

### Client connecting to it

```dart
import 'package:sembast/sembast_io.dart';
import 'package:tekartik_firebase_auth_sim/auth_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';

Future<void> main() async {
  var firebase = getFirebaseSim(
    uri: Uri.parse('ws://localhost:$firebaseSimDefaultPort'),
  );
  var app = firebase.initializeApp();
  // The local database only keeps the current user id.
  var auth = FirebaseAuthServiceSim(
    databaseFactory: databaseFactoryIo,
  ).auth(app);

  // Restored from the previous run, or null.
  var user = await auth.onCurrentUser.first;
  user ??= (await auth.createUserWithEmailAndPassword(
    email: 'user@example.com',
    password: 'password1',
  )).user;
  print('signed in as ${user.email} (${user.uid})');

  // Admin operations are executed on the server.
  print(await auth.getUserByEmail('user@example.com'));

  await auth.signOut();
  await app.delete();
}
```

### Test: in-memory server + client, shared suites

```dart
import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_app_web_socket/web_socket.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_auth_sim/auth_sim.dart';
import 'package:tekartik_firebase_auth_sim/auth_sim_server.dart';
import 'package:tekartik_firebase_auth_test/auth_admin_test_runner.dart';
import 'package:tekartik_firebase_auth_test/auth_local_admin_test_runner.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:test/test.dart';

/// Server + client firebase, all in memory.
Future<(FirebaseSimServer, Firebase)> initSimContext() async {
  var simServer = await firebaseSimServe(
    FirebaseLocal(),
    webSocketChannelServerFactory: webSocketChannelServerFactoryMemory,
    port: 0,
    plugins: [
      FirebaseAuthSimPlugin(
        firebaseAuthSimServerService: FirebaseAuthSimServerService(),
        firebaseAuthService: FirebaseAuthServiceSembast(
          databaseFactory: newDatabaseFactoryMemory(),
        ),
      ),
    ],
  );
  var firebase = getFirebaseSim(
    clientFactory: webSocketChannelClientFactoryMemory,
    uri: simServer.uri,
  );
  return (simServer, firebase);
}

void main() {
  group('auth_sim', () {
    late FirebaseSimServer simServer;
    late Firebase firebase;
    late FirebaseApp app;
    late FirebaseAuthSim auth;

    setUp(() async {
      (simServer, firebase) = await initSimContext();
      app = firebase.initializeApp();
      auth = FirebaseAuthServiceSim(
        databaseFactory: newDatabaseFactoryMemory(),
      ).auth(app);
    });
    tearDown(() async {
      await app.delete();
      await simServer.close();
    });

    localAdminTests(
      getAuth: () => auth,
      newApp: () => firebase.initializeApp(name: 'other'),
    );
    firebaseAuthAdminTests(
      getAuth: () => auth,
      email: 'simemail',
      password: 'simpassword',
    );
  });
}
```
