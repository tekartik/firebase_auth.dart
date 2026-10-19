// ignore_for_file: avoid_print

library;

import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_auth_test/auth_admin_test_runner.dart';
import 'package:tekartik_firebase_auth_test/auth_link_test_runner.dart';
import 'package:tekartik_firebase_auth_test/auth_local_admin_test_runner.dart';
import 'package:tekartik_firebase_auth_test/auth_sign_in_delete_test_runner.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  group('sign in', () {
    late FirebaseLocal firebase;
    late FirebaseAppLocal app;
    late FirebaseAuthSembast auth;
    late FirebaseAuthServiceSembast authService;
    setUp(() async {
      var databaseFactory = newDatabaseFactoryMemory();
      firebase = newFirebaseMemory();
      app = firebase.initializeApp();
      authService = FirebaseAuthServiceSembast(
        databaseFactory: databaseFactory,
      );
      auth = authService.auth(app) as FirebaseAuthSembast;
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
      email: 'sembastemail',
      password: 'sembastpassword',
    );
    firebaseAuthLinkTests(
      getAuth: () => auth,
      email: 'sembastlinkemail',
      password: 'sembastpassword',
    );
    firebaseAuthSignInDeleteTests(
      getAuth: () => auth,
      email: 'sembastemail',
      password: 'sembastpassword',
    );
    test('getUsers', () async {
      var user = await auth.createUser(
        FirebaseAuthCreateUserRequest(email: 'sembast_get_users1'),
      );
      var users = await auth.getUsers([user.uid, 'sembast_get_users_missing']);
      expect(users.map((user) => user.uid), [user.uid]);
    });
  });
}
