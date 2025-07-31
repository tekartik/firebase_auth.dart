// ignore_for_file: avoid_print

import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_auth_sim/auth_sim_server.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';

import 'example_io_client.dart';

Future<void> main(List<String> args) async {
  var firebaseSimServer = await firebaseSimServe(
    FirebaseLocal(),
    webSocketChannelServerFactory: webSocketChannelServerFactoryIo,
    port: urlKvPort,
    plugins: [
      FirebaseAuthSimPlugin(
        firebaseAuthSimService: FirebaseAuthSimService(),
        firebaseAuthService: FirebaseAuthServiceSembast(
          databaseFactory: databaseFactoryMemory,
        ),
      ),
    ],
  );
  print('url ${firebaseSimServer.url}');
}
