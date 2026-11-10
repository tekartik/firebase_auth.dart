// Verifies the Firebase ID token given on the command line:
//
//   dart run example/main.dart <idToken> <projectId>
// ignore_for_file: avoid_print
library;

import 'package:tekartik_firebase_auth_jwt/auth_jwt.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 2) {
    print('usage: dart run example/main.dart <idToken> <projectId>');
    return;
  }
  var idToken = arguments[0];
  var projectId = arguments[1];
  try {
    // Parsing only, throws when the string is not a JWT.
    var authInfo = FirebaseAuthInfo.fromIdToken(idToken);
    // Signature (Google public keys, downloaded) and time claims.
    var verified = await authInfo.verify();
    // A token of another Firebase project is signed by the same keys.
    if (verified && authInfo.projectId == projectId) {
      print('verified: ${authInfo.userId} ${authInfo.email}');
    } else {
      print('not verified: ${authInfo.toDebugMap()}');
    }
  } catch (e) {
    print('not verified: $e');
  }
}
