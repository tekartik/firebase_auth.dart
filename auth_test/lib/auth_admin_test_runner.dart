// ignore_for_file: avoid_print, invalid_use_of_visible_for_testing_member
library;

import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:test/test.dart';

/// Auth
void firebaseAuthAdminTests({
  required FirebaseAuthAdmin Function() getAuth,
  required String email,
  required String password,
}) {
  group('auth_admin', () {
    test('create user', () async {
      var auth = getAuth();

      // Check user exists
      var fetched = await auth.getUserByEmail(email);
      if (fetched != null) {
        await auth.deleteUser(fetched.uid);
      }
      var user = await auth.createUser(
        FirebaseAuthCreateUserRequest(
          email: email,
          displayName: 'Create User 1',
          emailVerified: true,
          disabled: false,
          phoneNumber: '+1234567890',
          photoURL: 'https://example.com/photo.jpg',
        ),
      );

      var uid = user.uid;
      try {
        expect(user.uid, uid);
        expect(user.email, email);
        expect(user.displayName, 'Create User 1');
        expect(user.emailVerified, isTrue);
        expect(user.disabled, isFalse);
        expect(user.phoneNumber, '+1234567890');
        expect(user.photoURL, 'https://example.com/photo.jpg');

        // Check user exists
        fetched = await auth.getUser(uid);
        expect(fetched!.uid, uid);
        expect(fetched.email, email);
        expect(fetched.displayName, 'Create User 1');
        expect(fetched.phoneNumber, '+1234567890');
        expect(fetched.photoURL, 'https://example.com/photo.jpg');

        // Check user exists
        fetched = await auth.getUserByEmail(email);
        expect(fetched!.uid, uid);
        // Create with existing email should throw StateError
        await expectLater(
          auth.createUser(FirebaseAuthCreateUserRequest(email: email)),
          throwsA(isA<StateError>()),
        );
      } finally {
        await auth.deleteUser(uid);
      }
    });
    test('create user with email/password', () async {
      var auth = getAuth();

      // Check user exists
      var fetched = await auth.getUserByEmail(email);
      if (fetched != null) {
        await auth.deleteUser(fetched.uid);
      }
      await auth.signOut();
      expect(auth.currentUser?.uid, isNull);
      var userCredentials = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      var user = userCredentials.user;
      var uid = user.uid;
      try {
        expect(user.uid, uid);
        expect(user.email, email);
        // Signed in, the user has a provider.
        expect(user.providerId, isNotNull);
        expect(auth.currentUser?.providerId, isNotNull);

        // Check user exists
        fetched = await auth.getUser(uid);
        expect(fetched!.uid, uid);
        expect(fetched.email, email);

        expect(auth.currentUser?.uid, uid);
        // Check user exists
        fetched = await auth.getUserByEmail(email);
        expect(fetched!.uid, uid);
        // Create with existing email should throw StateError
        await expectLater(
          auth.createUser(FirebaseAuthCreateUserRequest(email: email)),
          throwsA(isA<StateError>()),
        );
      } finally {
        await auth.deleteUser(uid);
      }
    });
  });
}
