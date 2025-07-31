import 'package:sembast/sembast_io.dart';
import 'package:tekartik_firebase_auth_sim/auth_sim.dart';
import 'package:tekartik_firebase_auth_test/menu/firebase_auth_client_menu.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';

var urlKv = 'firebase_auth_sim_example.url'.kvFromVar(
  defaultValue: 'ws://localhost:${firebaseSimDefaultPort.toString()}',
);

int? get urlKvPort => int.tryParse((urlKv.value ?? '').split(':').last);
Future<void> main(List<String> args) async {
  var firebase = getFirebaseSim(uri: Uri.parse(urlKv.value!));
  var app = firebase.initializeApp();
  var firebaseAuth = FirebaseAuthServiceSim(
    databaseFactory: databaseFactoryIo,
  ).auth(app);

  await mainMenu(args, () {
    firebaseAuthMainMenu(
      context: FirebaseAuthMainMenuContext(auth: firebaseAuth),
    );
    keyValuesMenu('kv', [urlKv]);
  });
}
