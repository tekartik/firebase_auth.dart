/// Local Firebase Auth backend on an sdb database (`idb_shim`): users and the
/// signed in user stored in memory, IndexedDB or a Flutter app database.
///
/// Build it with [FirebaseAuthServiceSdb] then `auth(app)` on a local app
/// (`tekartik_firebase_local`), or [newFirebaseAuthSdbMemory] in a test.
/// Local only: passwords are stored in clear and the id token is the uid.
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
