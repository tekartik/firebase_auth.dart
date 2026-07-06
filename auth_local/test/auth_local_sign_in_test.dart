// ignore_for_file: avoid_print

library;

import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:tekartik_firebase_auth_local/auth_local.dart';
import 'package:tekartik_firebase_auth_test/auth_admin_test_runner.dart';
import 'package:tekartik_firebase_auth_test/auth_sign_in_delete_test_runner.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  group('sign in', () {
    late FirebaseAppLocal app;
    late FirebaseAuthAdmin auth;

    setUp(() async {
      app = newFirebaseAppLocal();
      var authService = firebaseAuthServiceLocal;
      auth = authService.auth(app) as FirebaseAuthAdmin;
    });

    tearDownAll(() {
      return app.delete();
    });

    firebaseAuthAdminTests(
      getAuth: () => auth,
      email: 'testemail',
      password: 'testpwd',
    );
    firebaseAuthSignInDeleteTests(
      getAuth: () => auth,
      email: 'testemail',
      password: 'testpwd',
    );
  });
}
