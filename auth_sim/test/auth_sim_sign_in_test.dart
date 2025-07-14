// ignore_for_file: avoid_print

library;

import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_auth_sim/auth_sim.dart';
import 'package:tekartik_firebase_auth_test/auth_local_admin_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

import 'test_common.dart';

void main() {
  group('sign_in', () {
    late FirebaseApp app;
    late FirebaseAuthSim auth;
    late FirebaseAuthServiceSim authService;
    late TestContext testContext;
    setUp(() async {
      testContext = await initTestContextSim();
      var databaseFactory = newDatabaseFactoryMemory();
      authService = FirebaseAuthServiceSim(databaseFactory: databaseFactory);
      app = testContext.firebase.initializeApp();
      auth = authService.auth(app) as FirebaseAuthSim;
    });

    tearDownAll(() {
      return app.delete();
    });

    localAdminTests(getAuth: () => auth);
  });
}
