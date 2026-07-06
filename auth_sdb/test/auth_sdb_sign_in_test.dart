// ignore_for_file: avoid_print

library;

import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';
import 'package:tekartik_firebase_auth_sdb/auth_sdb.dart';
import 'package:tekartik_firebase_auth_test/auth_admin_test_runner.dart';
import 'package:tekartik_firebase_auth_test/auth_local_admin_test_runner.dart';
import 'package:tekartik_firebase_auth_test/auth_sign_in_delete_test_runner.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  group('sign in', () {
    late FirebaseLocal firebase;
    late FirebaseAppLocal app;
    late FirebaseAuthSdb auth;
    late FirebaseAuthServiceSdb authService;
    setUp(() async {
      var sdbFactory = sdbFactoryMemory;
      firebase = newFirebaseMemory();
      app = firebase.initializeApp();
      authService = FirebaseAuthServiceSdb(sdbFactory: sdbFactory);
      auth = authService.auth(app) as FirebaseAuthSdb;
    });

    tearDownAll(() {
      return app.delete();
    });

    localAdminTests(
      getAuth: () => auth,
      newApp: () => firebase.initializeApp(name: 'local_admin_test'),
    );
    firebaseAuthAdminTests(
      getAuth: () => auth,
      email: 'sdbemail',
      password: 'sdbpassword',
    );
    firebaseAuthSignInDeleteTests(
      getAuth: () => auth,
      email: 'sembastemail',
      password: 'sembastpassword',
    );
  });
}
