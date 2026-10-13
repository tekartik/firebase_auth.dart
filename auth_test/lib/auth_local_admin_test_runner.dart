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
      await expectLater(
        auth.createUser(FirebaseAuthCreateUserRequest(email: email)),
        throwsA(isA<StateError>()),
      );

      // Create with existing uid should throw StateError
      await expectLater(
        auth.createUser(FirebaseAuthCreateUserRequest(uid: 'uc1')),
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

    test('sendPasswordResetEmail', () async {
      var auth = getAuth();
      var email = 'userreset1';
      var password = 'password1';
      await auth.signOut();
      await auth.getOrCreateUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Existing user: succeeds (no email is actually sent locally)
      await auth.sendPasswordResetEmail(email: email);
      // Unknown user: fails
      await expectLater(
        auth.sendPasswordResetEmail(email: 'unknown_user_reset'),
        throwsA(anything),
      );
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

    test('deleteUser only signs out the deleted user', () async {
      var auth = getAuth();
      await auth.signOut();
      var current = await auth.createUserWithEmailAndPassword(
        email: 'deleteuser_current',
        password: 'password1',
      );
      var other = await auth.createUser(
        FirebaseAuthCreateUserRequest(email: 'deleteuser_other'),
      );
      await auth.deleteUser(other.uid);
      expect(await auth.getUser(other.uid), isNull);
      expect(auth.currentUser?.uid, current.user.uid);

      await auth.deleteUser(current.user.uid);
      await auth.onCurrentUser
          .firstWhere((user) => user == null)
          .timeout(const Duration(seconds: 10));
    });

    test('anonymous sign in keeps the other anonymous users', () async {
      var auth = getAuth();
      await auth.signOut();
      var credential1 = await auth.getSignInAnonymouslyUserCredential();
      var credential2 = await auth.getSignInAnonymouslyUserCredential();
      expect(await auth.getUser(credential1.user.uid), isNotNull);

      var signedIn = await auth.signInAnonymously();
      await auth.getSignInAnonymouslyUserCredential();
      expect(auth.currentUser?.uid, signedIn.user.uid);
      expect(await auth.getUser(signedIn.user.uid), isNotNull);
      expect(await auth.getUser(credential2.user.uid), isNotNull);
      await auth.signOut();
    });

    test('sign in credential stores the password', () async {
      var auth = getAuth();
      await auth.signOut();
      var email = 'credential_password1';
      var credential = await auth.getSignInWithEmailAndPasswordUserCredential(
        email: email,
        password: 'password1',
      );
      expect(credential.user.email, email);
      await expectLater(
        auth.signInWithEmailAndPassword(email: email, password: 'wrong'),
        throwsA(anything),
      );
      var userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: 'password1',
      );
      expect(userCredential.user.uid, credential.user.uid);
      await auth.signOut();
    });

    test('setUser keeps the other fields', () async {
      var auth = getAuth();
      var uid = 'setuser_in_place1';
      await auth.createUser(
        FirebaseAuthCreateUserRequest(
          uid: uid,
          email: 'setuser_in_place1',
          displayName: 'Set User',
          phoneNumber: '+33600000001',
        ),
      );
      await auth.setUser(uid, emailVerified: true);
      var user = (await auth.getUser(uid))!;
      expect(user.email, 'setuser_in_place1');
      expect(user.displayName, 'Set User');
      expect(user.phoneNumber, '+33600000001');
      expect(user.emailVerified, isTrue);

      await auth.setUser(uid, email: 'setuser_in_place2');
      user = (await auth.getUser(uid))!;
      expect(user.email, 'setuser_in_place2');
      expect(user.displayName, 'Set User');
      expect(user.emailVerified, isTrue);
    });

    test('signed in user fields', () async {
      var auth = getAuth();
      await auth.signOut();
      var email = 'user_fields1';
      var password = 'password1';
      await auth.createUser(
        FirebaseAuthCreateUserRequest(
          email: email,
          password: password,
          displayName: 'User Fields',
          phoneNumber: '+33600000002',
          photoURL: 'https://example.com/fields.jpg',
        ),
      );
      var credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      for (var user in [credential.user, (await auth.onCurrentUser.first)!]) {
        expect(user.email, email);
        expect(user.displayName, 'User Fields');
        expect(user.phoneNumber, '+33600000002');
        expect(user.photoURL, 'https://example.com/fields.jpg');
        expect(user.providerId, isNotNull);
      }
      await auth.signOut();
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
