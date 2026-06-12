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

    test('create user', () async {
      var auth = getAuth();
      var email = 'usercreate1@example.com';
      var user = await auth.createUser(
        FirebaseAuthCreateUserRequest(
          uid: 'uc1',
          email: email,
          displayName: 'Create User 1',
          emailVerified: true,
          disabled: false,
          phoneNumber: '+1234567890',
          photoURL: 'https://example.com/photo.jpg',
        ),
      );
      expect(user.uid, 'uc1');
      expect(user.email, email);
      expect(user.displayName, 'Create User 1');
      expect(user.emailVerified, isTrue);
      expect(user.disabled, isFalse);
      expect(user.phoneNumber, '+1234567890');
      expect(user.photoURL, 'https://example.com/photo.jpg');

      // Check user exists
      var fetched = await auth.getUser('uc1');
      expect(fetched!.uid, 'uc1');
      expect(fetched.email, email);
      expect(fetched.displayName, 'Create User 1');
      expect(fetched.emailVerified, isTrue);
      expect(fetched.disabled, isFalse);
      expect(fetched.phoneNumber, '+1234567890');
      expect(fetched.photoURL, 'https://example.com/photo.jpg');

      // Check user exists
      fetched = await auth.getUserByEmail(email);
      expect(fetched!.uid, 'uc1');
      // Create with existing email should throw StateError
      expect(
        () => auth.createUser(FirebaseAuthCreateUserRequest(email: email)),
        throwsA(isA<StateError>()),
      );

      // Create with existing uid should throw StateError
      expect(
        () => auth.createUser(FirebaseAuthCreateUserRequest(uid: 'uc1')),
        throwsA(isA<StateError>()),
      );

      // Create with auto-generated uid
      var user2 = await auth.createUser(
        FirebaseAuthCreateUserRequest(
          email: 'usercreate2@example.com',
          displayName: 'Create User 2',
        ),
      );
      expect(user2.uid, isNotEmpty);
      expect(user2.displayName, 'Create User 2');
      expect(user2.email, 'usercreate2@example.com');
    });

    test('signIn/signOut email password', () async {
      var auth = getAuth();
      var email = 'user1';
      var password = 'password1';
      await auth.signOut();

      var userInfo = await auth.getOrCreateUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      expect(userInfo.isAnonymous, isFalse);
      var currentUser = await auth.onCurrentUser.first;
      expect(currentUser, isNull);
      var user = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      currentUser = await auth.onCurrentUser.first;
      expect(currentUser!.uid, user.user.uid);
      expect(currentUser.uid, userInfo.uid);
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
      await auth.getOrCreateUserWithEmailAndPassword(
        email: email,
        password: password,
      );
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
