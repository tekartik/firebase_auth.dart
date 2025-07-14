import 'dart:async';

import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_app_web_socket/web_socket.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_auth_sim/src/auth_sim_plugin.dart';
import 'package:tekartik_firebase_auth_sim/src/auth_sim_service.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';

class TestContext {
  late FirebaseSimServer simServer;
  late Firebase firebase;
}

// memory only
Future<TestContext> initTestContextSim() async {
  var firebaseLocalServer = FirebaseLocal();
  var databaseFactory = newDatabaseFactoryMemory();
  var firebaseAuthService = FirebaseAuthServiceSembast(
    databaseFactory: databaseFactory,
  );
  var testContext = TestContext();
  var firebaseAuthSimService = FirebaseAuthSimService();
  var firebaseAuthSimPlugin = FirebaseAuthSimPlugin(
    firebaseAuthSimService: firebaseAuthSimService,
    firebaseAuthService: firebaseAuthService,
  );
  // The server use firebase io
  var simServer = testContext.simServer = await firebaseSimServe(
    firebaseLocalServer,
    webSocketChannelServerFactory: webSocketChannelServerFactoryMemory,
    plugins: [firebaseAuthSimPlugin],
  );
  testContext.firebase = getFirebaseSim(
    clientFactory: webSocketChannelClientFactoryMemory,
    uri: simServer.uri,
  );

  return testContext;
}

Future close(TestContext testContext) async {
  await testContext.simServer.close();
}
