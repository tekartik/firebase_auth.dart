// ignore_for_file:  unused_import

library;

import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_auth_sim/auth_sim.dart';
import 'package:tekartik_firebase_auth_test/auth_local_admin_test.dart';
import 'package:tekartik_firebase_sim/firebase_sim_mixin.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:test/test.dart';

import 'test_common.dart';

void main() {
  // debugRpcServer = devTrue;
  // debugFirebaseSimServer = devTrue;
  // debugFirebaseSimClient = devTrue;
  group('resign_in', () {
    late FirebaseApp app;
    late FirebaseAuthSim auth;
    late FirebaseAuthServiceSim authService;
    late TestContext testContext;
    var databaseFactory = newDatabaseFactoryMemory();

    Future<void> initContext() async {
      testContext = await initTestContextSim(
        databaseFactory: databaseFactory,
        port: 0,
      );
      authService = FirebaseAuthServiceSim(databaseFactory: databaseFactory);
      app = testContext.firebase.initializeApp();
      auth = authService.auth(app);
    }

    setUp(() async {
      await initContext();
    });

    tearDown(() {
      return app.delete();
    });

    test('re-init', () async {
      var email = 'user1';
      var password = 'password1';

      var currentUser = await auth.onCurrentUser.first;
      expect(currentUser, isNull);
      var user = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      var uid = user.user.uid;
      await app.delete();
      await initContext();

      currentUser = await auth.onCurrentUser.first;

      expect(currentUser!.uid, uid);
      await auth.deleteUser(uid);
      await app.delete();
      await initContext();
      currentUser = await auth.onCurrentUser.first;
      expect(currentUser, isNull);
    });
  });
}
