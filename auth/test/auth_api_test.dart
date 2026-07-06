// ignore_for_file: avoid_print

import 'package:tekartik_firebase_auth/auth.dart';
import 'package:test/test.dart';

void main() {
  group('auth_api', () {
    test('auth', () async {
      (null as FirebaseApp?)?.auth();
    });
  });
}
