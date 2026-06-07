// ignore_for_file: avoid_print, invalid_use_of_visible_for_testing_member
library;

import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_auth/auth_admin.dart';
import 'package:test/test.dart';

void firebaseAuthAdminTests({
  required FirebaseAuthAdmin Function() getAuth,
  required String email,
  required String password,
  FirebaseApp Function()? newApp,
}) {
  group('auth__admin', () {
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
        /*expect(user.phoneNumber, '+1234567890');
        expect(user.photoURL, 'https://example.com/photo.jpg');*/

        // Check user exists
        fetched = await auth.getUser(uid);
        expect(fetched!.uid, uid);
        expect(fetched.email, email);
        expect(fetched.displayName, 'Create User 1');
        expect(fetched.emailVerified, isTrue);
        expect(fetched.disabled, isFalse);
        /*expect(fetched.phoneNumber, '+1234567890');
        expect(fetched.photoURL, 'https://example.com/photo.jpg');*/

        // Check user exists
        fetched = await auth.getUserByEmail(email);
        expect(fetched!.uid, uid);
        // Create with existing email should throw StateError
        expect(
          () => auth.createUser(FirebaseAuthCreateUserRequest(email: email)),
          throwsA(isA<StateError>()),
        );
      } finally {
        await auth.deleteUser(uid);
      }
    });
  });
}
