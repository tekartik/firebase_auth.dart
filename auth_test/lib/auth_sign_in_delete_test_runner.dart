// ignore_for_file: avoid_print, invalid_use_of_visible_for_testing_member
library;

import 'package:tekartik_firebase_auth/auth.dart';
import 'package:test/test.dart';

void firebaseAuthSignInDeleteTests({
  required FirebaseAuth Function() getAuth,
  required String email,
  required String password,
}) {
  group('auth_sign_in_delete', () {
    test('create user with email/password', () async {
      var auth = getAuth();

      // Check user exists
      var fetched = await auth.getUserByEmail(email);
      if (fetched != null) {
        await (await auth.signInOrUpWithEmailAndPassword(
          email: email,
          password: password,
        )).user.delete();
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
        //expect(user.displayName, 'Create User 1');
        // expect(user.emailVerified, isTrue);
        // expect(user.disabled, isFalse);
        /*expect(user.phoneNumber, '+1234567890');
        expect(user.photoURL, 'https://example.com/photo.jpg');*/

        // Check user exists
        fetched = await auth.getUser(uid);
        expect(fetched!.uid, uid);
        expect(fetched.email, email);

        expect(auth.currentUser?.uid, uid);
        // Check user exists
        fetched = await auth.getUserByEmail(email);
        expect(fetched!.uid, uid);
        // Create with existing email should throw StateError
        expect(
          () => auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          ),
          throwsA(isA<StateError>()),
        );
      } finally {
        await user.delete();
      }
    });
  });
}
