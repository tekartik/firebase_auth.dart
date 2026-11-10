# tekartik_firebase_auth_sim

A `FirebaseAuth` whose users live in another process: a firebase sim server
(`tekartik_firebase_sim`) hosts a local auth (usually
`tekartik_firebase_auth_sembast`) and clients (Dart VM, browser, Flutter)
reach it over a web socket with an auth that looks like any other backend.
Handy to share one local auth between processes or tabs, and to test client
code without a Firebase project.

## Getting started

Git packages, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_auth_sim:
    git:
      url: https://github.com/tekartik/firebase_auth.dart
      path: auth_sim
  tekartik_firebase_sim:
    git:
      url: https://github.com/tekartik/firebase.dart
      path: firebase_sim
  # The server side hosts a local auth on a local firebase.
  tekartik_firebase_auth_sembast:
    git:
      url: https://github.com/tekartik/firebase_auth.dart
      path: auth_sembast
  tekartik_firebase_local:
    git:
      url: https://github.com/tekartik/firebase.dart
      path: firebase_local
  # The in memory transport of the example below.
  tekartik_web_socket:
    git:
      url: https://github.com/tekartik/web_socket.dart
      path: web_socket
```

Server and client in one program, over the in memory transport:

```dart
import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_auth_sim/auth_sim.dart';
import 'package:tekartik_firebase_auth_sim/auth_sim_server.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:tekartik_web_socket/web_socket.dart';

Future<void> main() async {
  // Server: a sembast auth published over the sim protocol.
  var simServer = await firebaseSimServe(
    FirebaseLocal(),
    webSocketChannelServerFactory: webSocketChannelFactoryMemory.server,
    plugins: [
      FirebaseAuthSimPlugin(
        firebaseAuthSimServerService: FirebaseAuthSimServerService(),
        firebaseAuthService: FirebaseAuthServiceSembast(
          databaseFactory: newDatabaseFactoryMemory(),
        ),
      ),
    ],
  );

  // Client: its local database only keeps the signed in user id.
  var firebase = getFirebaseSim(
    clientFactory: webSocketChannelFactoryMemory.client,
    uri: simServer.uri,
  );
  var app = firebase.initializeApp() as FirebaseAppSim;
  var auth = FirebaseAuthServiceSim(
    databaseFactory: newDatabaseFactoryMemory(),
  ).auth(app);

  await auth.createUserWithEmailAndPassword(
    email: 'user@example.com',
    password: 'password1',
  );
  print('signed in: ${auth.currentUser?.email}');
  await auth.signOut();
  print('signed out: ${auth.currentUser}');

  // delete() leaves the connection of the app open: close it.
  var simClient = await app.simClient;
  await app.delete();
  await simClient.close();
  await simServer.close();
}
```

In real use the server runs in a Dart VM process
(`webSocketChannelServerFactoryIo`, `port: firebaseSimDefaultPort`) and the
clients connect with `getFirebaseSim(uri: getFirebaseSimLocalhostUri())` and a
persistent `databaseFactory` (`databaseFactoryIo`, `databaseFactoryWeb`) to
keep the session across restarts.

## Platforms

| Side | Library | Runs on |
|---|---|---|
| client | `auth_sim.dart` | Dart VM, web, Flutter |
| server | `auth_sim_server.dart` | Dart VM only |

## What to know

* Users live on the server; the client `databaseFactory` only stores the
  signed in user id, in `<localPath>/<appName>/auth.db`. Two auths of the
  same app name in one process share that database: deleting one app closes
  it for the other.
* `onCurrentUser` emits once the local database is open, then once per
  change (a sign in, a sign out); a user deleted on the server (by any
  client) signs this client out.
* `app.delete()` ends the listeners but leaves the connection open: close
  `await app.simClient`, as above, or a program does not exit.
* When the connection closes (server gone), `onUserRecord` streams end with
  the error (none once cancelled or the app deleted); the current user stays.
* `signOut()` deletes an anonymous user. `reloadCurrentUser()` and
  `listUsers()` are not supported. Server errors reach the client as RPC
  errors (an existing email as a `StateError`); a disabled user can sign in.
* A development tool: the transport is not authenticated and the server
  stores the passwords in clear.

The [tekartik-firebase-auth-sim-setup skill](skills/tekartik-firebase-auth-sim-setup/SKILL.md)
has more examples (io server and client, shared test suites).
