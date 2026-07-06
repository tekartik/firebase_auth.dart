/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

import 'auth_sdb.dart';

export 'package:tekartik_firebase_auth/auth.dart';
export 'src/auth_sdb_impl.dart' show FirebaseAuthServiceSdb, FirebaseAuthSdb;

/// New service in memory
FirebaseAuthService newFirebaseAuthServiceSdbMemory() =>
    FirebaseAuthServiceSdb(sdbFactory: sdbFactoryMemory);

/// New service in memory
FirebaseAuth newFirebaseAuthSdbMemory() =>
    newFirebaseAuthServiceSdbMemory().auth(newFirebaseAppMemory());
