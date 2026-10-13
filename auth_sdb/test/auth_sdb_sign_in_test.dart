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

    // Each test has its own app.
    tearDown(() {
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
      email: 'sdbemail',
      password: 'sdbpassword',
    );
    test('getUsers listUsers', () async {
      var user = await auth.createUser(
        FirebaseAuthCreateUserRequest(email: 'sdb_get_users1'),
      );
      var users = await auth.getUsers([user.uid, 'sdb_get_users_missing']);
      expect(users.map((user) => user.uid), [user.uid]);
      // Empty page, no error.
      var result = await auth.listUsers(maxResults: 0);
      expect(result.users, isEmpty);
      expect(result.pageToken, isNull);
    });
  });
}
