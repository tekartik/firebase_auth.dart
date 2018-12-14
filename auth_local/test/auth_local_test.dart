library tekartik_firebase_sembast.firebase_sembast_memory_test;

import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_auth_local/auth_local.dart';
import 'package:tekartik_firebase_auth_test/auth_test.dart';

void main() {
  var firebase = FirebaseLocal();
  run(firebase: firebase, authService: authServiceLocal);
}
