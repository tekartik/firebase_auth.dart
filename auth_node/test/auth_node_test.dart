@TestOn('node')
library tekartik_firebase_auth_node.test.auth_node_test;

import 'package:tekartik_app_node_utils/node_utils.dart';
import 'package:tekartik_firebase_auth_node/auth_node.dart';
import 'package:tekartik_firebase_auth_test/auth_test.dart';
import 'package:tekartik_firebase_node/firebase_node.dart';
import 'package:test/test.dart';

var _env = platform.environment;

void main() {
  var firebase = firebaseNode;
  var authService = authServiceNode;

  test('app', () {
    print('FIREBASE_CONFIG: ${_env['FIREBASE_CONFIG']}');
    print(
        'GOOGLE_APPLICATION_CREDENTIALS: ${_env['GOOGLE_APPLICATION_CREDENTIALS']}');
  });
  if (_env['FIREBASE_CONFIG'] != null) {
    group('auth_node', () {
      run(firebase: firebase, authService: authService);
    });
  }
}
