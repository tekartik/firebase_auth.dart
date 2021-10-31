import 'package:tekartik_firebase_auth_rest/src/google_auth_rest.dart';

abstract class GoogleAuthProviderRestWeb implements GoogleRestAuthProvider {
  factory GoogleAuthProviderRestWeb({required GoogleAuthOptions options}) =>
      throw UnsupportedError('web');
}
