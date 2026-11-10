/// Local Firebase Auth backend on a sembast database: users and the signed in
/// user stored in memory or in a file.
///
/// Build it with [FirebaseAuthServiceSembast] then `auth(app)` on a local app
/// (`tekartik_firebase_local`), or [newFirebaseAuthMemory] in a test. Local
/// only: passwords are stored in clear and the id token is the uid.
library;

import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

import 'auth_sembast.dart';

export 'package:tekartik_firebase_auth/auth.dart';
export 'src/auth_sembast_impl.dart'
    show FirebaseAuthServiceSembast, FirebaseAuthSembast;

/// New service in memory
FirebaseAuthService newFirebaseAuthServiceMemory() =>
    FirebaseAuthServiceSembast(databaseFactory: newDatabaseFactoryMemory());

/// New service in memory
FirebaseAuth newFirebaseAuthMemory() =>
    newFirebaseAuthServiceMemory().auth(newFirebaseAppMemory());
