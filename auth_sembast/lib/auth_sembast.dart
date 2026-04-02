/// Support for doing something awesome.
///
/// More dartdocs go here.
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
