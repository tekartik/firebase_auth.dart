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
  var authService =
      FirebaseAuthServiceSembast(databaseFactory: databaseFactory);
  runAuthTests(firebase: firebase, authService: authService);

  group('auth', () {
    test('factory', () {
      expect(authService.supportsListUsers, isFalse);
      expect(authService.supportsCurrentUser, isTrue);
    });
    runAuthTests(firebase: firebase, authService: authService);
  });
}
