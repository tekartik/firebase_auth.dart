// ignore_for_file: avoid_print

library;

import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_auth_test/auth_admin_test_runner.dart';
import 'package:tekartik_firebase_auth_test/auth_local_admin_test_runner.dart';
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

    tearDownAll(() {
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
  });
}
