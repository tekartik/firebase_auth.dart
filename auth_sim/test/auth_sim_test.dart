// ignore_for_file: avoid_print, unused_import

library;

import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_auth_sim/auth_sim.dart';
import 'package:tekartik_firebase_auth_test/auth_local_admin_test.dart';
import 'package:tekartik_firebase_auth_test/auth_test.dart';
import 'package:tekartik_firebase_sim/firebase_sim_mixin.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:test/test.dart';

import 'test_common.dart';

void main() async {
  var testContext = await initTestContextSim(port: 0);

  var databaseFactory = newDatabaseFactoryMemory();
  var authService = FirebaseAuthServiceSim(databaseFactory: databaseFactory);
  group('auth_sim', () {
    // debugRpcServer = devTrue;
    // debugFirebaseSimServer = devTrue;
    // debugFirebaseSimClient = devTrue;
    test('service', () {
      expect(authService.supportsListUsers, isFalse);
      expect(authService.supportsCurrentUser, isTrue);
    });
    runAuthTests(authService: authService, firebase: testContext.firebase);
  });
}
