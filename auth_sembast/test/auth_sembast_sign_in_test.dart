// ignore_for_file: avoid_print

library;

import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_auth_test/auth_local_admin_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  group('sign in', () {
    late FirebaseAppLocal app;
    late FirebaseAuthSembast auth;
    late FirebaseAuthServiceSembast authService;
    setUp(() async {
      var databaseFactory = newDatabaseFactoryMemory();
      app = newFirebaseAppLocal();
      authService = FirebaseAuthServiceSembast(
        databaseFactory: databaseFactory,
      );
      auth = authService.auth(app) as FirebaseAuthSembast;
    });

    tearDownAll(() {
      return app.delete();
    });

    localAdminTests(getAuth: () => auth, newApp: () => newFirebaseAppLocal());
  });
}
