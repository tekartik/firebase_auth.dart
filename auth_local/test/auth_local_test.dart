library tekartik_firebase_sembast.firebase_sembast_memory_test;

import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_auth/utils/json_utils.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_auth_local/auth_local.dart';
import 'package:tekartik_firebase_auth_test/auth_test.dart';
import 'package:test/test.dart';

void main() {
  var firebase = FirebaseLocal();
  run(firebase: firebase, authService: authServiceLocal);

  group('browser', () {
    test('factory', () {
      expect(authService.supportsListUsers, isTrue);
    });
    run(firebase: firebase, authService: authService);

    group('auth', () {
      App app = firebase.initializeApp(name: 'auth');
      var auth = authServiceLocal.auth(app);

      tearDownAll(() {
        return app.delete();
      });

      test('listUsers', () async {
        var user = (await auth.listUsers(maxResults: 1)).users?.first;
        print(userRecordToJson(user));
      });
    });
  });
}
