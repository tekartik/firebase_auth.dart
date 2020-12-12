import 'dart:async';

import 'package:tekartik_firebase_rest/src/test/test_setup.dart';
import 'package:tekartik_firebase_rest/src/test/test_setup.dart' as firebase;

Future<FirebaseRest> setup() async {
  return await firebase.firebaseRestSetup(scopes: firebaseBaseScopes);
}
