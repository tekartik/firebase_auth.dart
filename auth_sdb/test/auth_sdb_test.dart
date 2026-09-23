// ignore_for_file: avoid_print

library;

import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';
import 'package:tekartik_firebase_auth_sdb/auth_sdb.dart';
import 'package:tekartik_firebase_auth_test/auth_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  var firebase = FirebaseLocal();
  var sdbFactory = sdbFactoryMemory;
  var authService = FirebaseAuthServiceSdb(sdbFactory: sdbFactory);

  group('auth', () {
    test('factory', () {
      expect(authService.supportsListUsers, isTrue);
      expect(authService.supportsCurrentUser, isTrue);
    });
    runAuthTests(firebase: firebase, authService: authService);

    test('listUsers', () async {
      var auth = newFirebaseAuthSdbMemory() as FirebaseAuthSdb;
      expect((await auth.listUsers()).users, isEmpty);
      for (var uid in ['c', 'a', 'b']) {
        await auth.createUser(
          FirebaseAuthCreateUserRequest(uid: uid, email: '$uid@example.com'),
        );
      }
      var result = await auth.listUsers();
      expect(result.users.map((user) => user!.uid), ['a', 'b', 'c']);
      expect(result.pageToken, isNull);

      // Page by page.
      result = await auth.listUsers(maxResults: 2);
      expect(result.users.map((user) => user!.uid), ['a', 'b']);
      expect(result.pageToken, 'b');
      result = await auth.listUsers(maxResults: 2, pageToken: 'b');
      expect(result.users.map((user) => user!.uid), ['c']);
      expect(result.pageToken, isNull);
      result = await auth.listUsers(maxResults: 3);
      expect(result.pageToken, isNull);

      expect(
        (await auth.getUsers(['c', 'unknown', 'a'])).map((user) => user.uid),
        ['c', 'a'],
      );
      await auth.app.delete();
    });

    test('memory', () async {
      var auth1 = newFirebaseAuthSdbMemory() as FirebaseAuthSdb;
      var auth2 = newFirebaseAuthSdbMemory();
      expect(auth1, isNot(auth2));
      await auth1.setUser('1234');
      expect(await auth1.getUser('1234'), isNotNull);
      expect(await auth2.getUser('1234'), isNull);
      await auth1.app.delete();
      await auth2.app.delete();
    });
  });
}
