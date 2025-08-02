// ignore_for_file: avoid_print, unused_import

library;

import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_auth_sim/auth_sim.dart';
import 'package:tekartik_firebase_auth_test/auth_local_admin_test.dart';
import 'package:tekartik_firebase_sim/firebase_sim_client.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:test/test.dart';

import 'test_common.dart';

void main() {
  // debugRpcServer = devTrue;
  // debugFirebaseSimServer = devTrue;
  // debugFirebaseSimClient = devTrue;
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
      auth = authService.auth(app);
    });

    tearDownAll(() {
      return app.delete();
    });

    localAdminTests(
      getAuth: () => auth,
      newApp: () => testContext.firebase.initializeApp(),
    );
  });
}
