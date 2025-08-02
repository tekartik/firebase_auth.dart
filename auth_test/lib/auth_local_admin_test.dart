// ignore_for_file: avoid_print, invalid_use_of_visible_for_testing_member
library;

import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:test/test.dart';

void localAdminTests({
  required FirebaseAuthLocalAdmin Function() getAuth,
  FirebaseApp Function()? newApp,
}) {
  group('local_admin', () {
    test('no user', () async {
      var auth = getAuth();
      var user = await auth.onCurrentUser.first;
      expect(user, isNull);
    });

    test('set user', () async {
      var auth = getAuth();
      var email = 'userset1';
      await auth.setUser('u1', email: email);
      expect((await auth.getUser('u1'))!.uid, 'u1');
      expect((await auth.getUserByEmail(email))!.uid, 'u1');
      await auth.setUser('u2', email: email);
      expect((await auth.getUserByEmail(email))!.uid, 'u2');
    });

    test('signIn/signOut email password', () async {
      var auth = getAuth();
      var email = 'user1';
      var password = 'password1';
      var userCredential = await auth
          .getSignInWithEmailAndPasswordUserCredential(
            email: email,
            password: password,
          );
      expect(userCredential.user.isAnonymous, isFalse);
      var currentUser = await auth.onCurrentUser.first;
      expect(currentUser, isNull);
      var user = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      currentUser = await auth.onCurrentUser.first;
      expect(currentUser!.uid, user.user.uid);
      expect(currentUser.uid, userCredential.user.uid);
      expect(currentUser.email, email);
      expect(currentUser.emailVerified, isFalse);
      expect(currentUser.isAnonymous, isFalse);
      await auth.signOut();
      currentUser = await auth.onCurrentUser.first;
      expect(currentUser, isNull);
    });

    test('signIn/signOut anonymously', () async {
      var auth = getAuth();
      var userCredential = await auth.getSignInAnonymouslyUserCredential();
      expect(userCredential.user.isAnonymous, isTrue);

      var currentUser = await auth.onCurrentUser.first;
      expect(currentUser, isNull);
      var user = await auth.signInAnonymously();
      currentUser = await auth.onCurrentUser.first;
      expect(currentUser!.uid, user.user.uid);

      /// A new user is created each time!
      expect(currentUser.uid, isNot(userCredential.user.uid));
      expect(currentUser.email, isNull);
      expect(currentUser.isAnonymous, isTrue);
      print('currentUser: $currentUser');
      await auth.signOut();
      currentUser = await auth.onCurrentUser.first;
      expect(currentUser, isNull);
    });

    test('signIn delete restart', () async {
      var auth = getAuth();
      var authService = auth.service;
      var app = auth.app;
      var email = 'user1';
      var password = 'password1';
      var user = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      expect(authService.getExistingInstance(app), auth);
      await app.delete();
      expect(authService.getExistingInstance(app), isNull);

      if (newApp != null) {
        app = newApp();
        auth = authService.auth(app) as FirebaseAuthLocalAdmin;
        expect(authService.getExistingInstance(app), auth);
        var currentUser = await auth.onCurrentUser.first;
        print('currentUser: $currentUser');
        expect(currentUser!.uid, user.user.uid);
        expect(currentUser.email, email);
        expect(currentUser.emailVerified, isFalse);
      }
    });
  });
}
