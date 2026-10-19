library;

import 'package:tekartik_firebase_auth/auth.dart';
import 'package:test/test.dart';

/// Deletes the user of [email], if any, signing out.
Future<void> _deleteUserOfEmail(
  FirebaseAuth auth, {
  required String email,
  required String password,
}) async {
  try {
    var credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user.delete();
  } catch (_) {
    // No such user.
  }
  await auth.signOut();
}

/// Links an email and password to an anonymous user
/// ([FirebaseUser.linkWithCredential]).
void firebaseAuthLinkTests({
  required FirebaseAuth Function() getAuth,
  required String email,
  required String password,
}) {
  group('auth_link', () {
    test('link email/password to an anonymous user', () async {
      var auth = getAuth();
      await _deleteUserOfEmail(auth, email: email, password: password);

      var user = (await auth.signInAnonymously()).user;
      var uid = user.uid;
      try {
        expect(user.isAnonymous, isTrue);
        var linked = await user.linkWithCredential(
          FirebaseAuthEmailPasswordCredential(email: email, password: password),
        );
        expect(linked.user.uid, uid);
        expect(linked.user.isAnonymous, isFalse);
        expect(linked.user.email, email);
        // The current user is the linked one, right away.
        expect(auth.currentUser?.uid, uid);
        expect(auth.currentUser?.isAnonymous, isFalse);

        // Linking again is refused.
        try {
          await linked.user.linkWithCredential(
            FirebaseAuthEmailPasswordCredential(
              email: 'link2.$email',
              password: password,
            ),
          );
          fail('should fail');
        } catch (e) {
          expect(e, isNot(isA<TestFailure>()));
          expect('$e', contains('provider-already-linked'));
        }

        // Signing out keeps the user, signing in finds the same uid.
        await auth.signOut();
        var signedIn = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        expect(signedIn.user.uid, uid);
        expect(signedIn.user.isAnonymous, isFalse);
      } finally {
        await _deleteUserOfEmail(auth, email: email, password: password);
      }
    });

    test('link an email in use', () async {
      var auth = getAuth();
      await _deleteUserOfEmail(auth, email: email, password: password);
      await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await auth.signOut();

      var user = (await auth.signInAnonymously()).user;
      try {
        try {
          await user.linkWithCredential(
            FirebaseAuthEmailPasswordCredential(
              email: email,
              password: password,
            ),
          );
          fail('should fail');
        } catch (e) {
          expect(e, isNot(isA<TestFailure>()));
          expect('$e', contains('email-already-in-use'));
        }
        // Still the anonymous user.
        expect(auth.currentUser?.uid, user.uid);
        expect(auth.currentUser?.isAnonymous, isTrue);
      } finally {
        await user.delete();
        await _deleteUserOfEmail(auth, email: email, password: password);
      }
    });
  });
}
