// ignore_for_file: avoid_print

library;

import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  group('email_password', () {
    late FirebaseAppLocal app;
    late FirebaseAuthSembast auth;
    late FirebaseAuthServiceSembast authService;
    setUp(() async {
      var databaseFactory = newDatabaseFactoryMemory();
      app = newFirebaseAppLocal();
      authService =
          FirebaseAuthServiceSembast(databaseFactory: databaseFactory);
      auth = authService.auth(app) as FirebaseAuthSembast;
    });

    tearDownAll(() {
      return app.delete();
    });

    test('no user', () async {
      var user = await auth.onCurrentUser.first;
      expect(user, isNull);
    });

    test('signIn/signOut', () async {
      var email = 'user1';
      var password = 'password1';
      var user = await auth.signInWithEmailAndPassword(
          email: email, password: password);
      var currentUser = await auth.onCurrentUser.first;
      expect(currentUser!.uid, user.user.uid);
      await auth.signOut();
      currentUser = await auth.onCurrentUser.first;
      expect(currentUser, isNull);
    });

    test('signIn delete restart', () async {
      var email = 'user1';
      var password = 'password1';
      var user = await auth.signInWithEmailAndPassword(
          email: email, password: password);

      expect(authService.getExistingInstance(app), auth);
      await app.delete();
      expect(authService.getExistingInstance(app), isNull);

      app = newFirebaseAppLocal();
      auth = authService.auth(app) as FirebaseAuthSembast;
      expect(authService.getExistingInstance(app), auth);
      var currentUser = await auth.onCurrentUser.first;
      expect(currentUser!.uid, user.user.uid);
    });
  });
}
