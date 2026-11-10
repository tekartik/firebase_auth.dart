// ignore_for_file: avoid_print

library;

import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';
import 'package:tekartik_firebase_auth_sdb/auth_sdb.dart';
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
    firebaseAuthLinkTests(
      getAuth: () => auth,
      email: 'sdblinkemail',
      password: 'sdbpassword',
    );
    firebaseAuthSignInDeleteTests(
      getAuth: () => auth,
      email: 'sdbemail',
      password: 'sdbpassword',
    );
    test('sign in and out are notified once each', () async {
      var email = 'sdb_notify_once';
      var password = 'sdbpassword';
      await auth.createUser(
        FirebaseAuthCreateUserRequest(email: email, password: password),
      );
      var emails = <String?>[];
      var subscription = auth.onCurrentUser.listen(
        (user) => emails.add(user?.email),
      );
      try {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(emails, [null]);
        await auth.signInWithEmailAndPassword(email: email, password: password);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        // Signing in again the same user changes nothing.
        await auth.signInWithEmailAndPassword(email: email, password: password);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await auth.signOut();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(emails, [null, email, null]);
      } finally {
        await subscription.cancel();
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
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
