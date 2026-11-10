/// Client side of a firebase auth hosted by a firebase sim server.
///
/// `FirebaseAuthServiceSim(databaseFactory: ...).auth(app)` on a
/// `FirebaseAppSim` (`getFirebaseSim`) gives a [FirebaseAuthSim]: a
/// `FirebaseAuth` and `FirebaseAuthLocalAdmin` whose users live on the
/// server, the local database only keeping the signed in user id.
library;

export 'package:tekartik_firebase_auth/auth.dart';

export 'src/auth_service_sim.dart' show FirebaseAuthServiceSim;
export 'src/auth_sim.dart' show FirebaseAuthSim;
