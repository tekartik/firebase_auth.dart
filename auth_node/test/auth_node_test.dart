@TestOn('node')
library tekartik_firebase_auth_node.test.auth_node_test;

import 'package:tekartik_firebase_auth_node/auth_node.dart';
import 'package:tekartik_firebase_auth_test/auth_test.dart';
import 'package:tekartik_firebase_node/firebase_node.dart';
import 'package:test/test.dart';

void main() {
  var firebase = firebaseNode;
  var authService = authServiceNode;
  run(firebase: firebase, authService: authService);
}
