// ignore_for_file: invalid_use_of_visible_for_testing_member
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
      try {
        var fetched = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await fetched.user.delete();
      } catch (e) {
        // ignore: avoid_print
        print('error signing in or deleting user: $e');
      }

      await auth.signOut();
      expect(auth.currentUser?.uid, isNull);
      var userCredentials = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ignore: avoid_print
      print('userCredentials: $userCredentials');
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

        /*
        // Check user exists
        var fetched = await auth.getUser(uid);
        expect(fetched!.uid, uid);
        expect(fetched.email, email);*/

        expect(auth.currentUser?.uid, uid);
        /*
        // Check user exists
        fetched = await auth.getUserByEmail(email);
        expect(fetched!.uid, uid);*/
        // Create with existing email should throw StateError
        /*
        expect(
          () => auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          ),
          throwsA(isA<Object>()),
        );
        expect(auth.currentUser?.uid, uid);*/
        await auth.signOut();
        expect(auth.currentUser, isNull);
        await auth.signInWithEmailAndPassword(email: email, password: password);

        expect(auth.currentUser?.uid, uid);
      } finally {
        await user.delete();
        expect(auth.currentUser, isNull);

        try {
          await auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          fail('should fail');
        } catch (e) {
          expect(e, isNot(isA<TestFailure>()));
        }
      }
    });
  });
}
