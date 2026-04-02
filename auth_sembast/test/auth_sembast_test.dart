// ignore_for_file: avoid_print

library;

import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_auth_test/auth_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  var firebase = FirebaseLocal();
  var databaseFactory = newDatabaseFactoryMemory();
  var authService = FirebaseAuthServiceSembast(
    databaseFactory: databaseFactory,
  );

  group('auth', () {
    test('factory', () {
      expect(authService.supportsListUsers, isFalse);
      expect(authService.supportsCurrentUser, isTrue);
    });
    runAuthTests(firebase: firebase, authService: authService);

    test('memory', () async {
      var auth1 = newFirebaseAuthMemory() as FirebaseAuthSembast;
      var auth2 = newFirebaseAuthMemory();
      expect(auth1, isNot(auth2));
      await auth1.setUser('1234');
      expect(await auth1.getUser('1234'), isNotNull);
      expect(await auth2.getUser('1234'), isNull);
      await auth1.app.delete();
      await auth2.app.delete();
    });
  });
}
